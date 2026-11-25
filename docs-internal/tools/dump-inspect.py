#!/usr/bin/env python3
"""dump-inspect.py: doc anh flash (.bin) cua STM32 va ket luan bo co bootloader hay khong.

Python 3 thuan, khong thu vien ngoai. Chi DOC file (tru --selftest --write).
Nguyen tac thiet ke: THA RA UNKNOWN CON HON DOAN. Moi ket luan khac UNKNOWN/EMPTY
in kem danh sach bang chung da dung.

Dung:
  python3 dump-inspect.py <dump.bin> [--board octopus|ebb36|auto] [--base 0x08000000]
  python3 dump-inspect.py --app <offset> <build.bin> [--board octopus|ebb36|auto] [--base 0x08000000]
  python3 dump-inspect.py --selftest [--write <thu_muc>]
      (them: neu co fleet/reflash/2026-11-25 canh repo thi kiem --app tren cac ban build that)
  python3 dump-inspect.py --help

--board: octopus = ung vien offset 128 KiB (0x20000), can dump >= 0x20010 byte;
         ebb36   = ung vien 8 KiB (0x2000), can dump >= 0x2010 byte;
         auto    = ca hai (mac dinh), can dump >= 0x20010 byte.

Che do dump in bang vector, vi tri chuoi katapult/canboot/klipper/kalico (ASCII va
UTF-16LE), khoi du lieu nhan dang zlib cua Klipper, cac khoang toan 0xFF >= 4 KiB, roi
MOT dong cuoi:  KET LUAN: <GIA_TRI>  voi GIA_TRI thuoc
NO_BOOTLOADER, BOOTLOADER_8K, BOOTLOADER_128K, BOOTLOADER_ONLY_NO_APP, EMPTY, UNKNOWN.
Ma thoat: 0 ket luan chac (NO_BOOTLOADER, BOOTLOADER_*, BOOTLOADER_ONLY_NO_APP),
          2 UNKNOWN, 3 EMPTY, 1 loi dung sai / khong doc duoc file.

Che do --app: kiem PHU file .bin vua build (chi chua ung dung) co bang vector khop offset khong;
can cu chinh cua offset la CONFIG_FLASH_APPLICATION_ADDRESS trong .config da dung de build.
Hop le tai offset: SP trong RAM; RESET le; RESET va moi muc khac 0/0xFFFFFFFF trong N muc dau
nam trong [base+offset, base+offset+kich_thuoc_file) (N = 64 voi --board octopus, 16 voi ebb36/auto).
Dong cuoi  KET LUAN APP: APP_OFFSET_OK (ma 0) | APP_OFFSET_MISMATCH (ma 4)
           | APP_OFFSET_AMBIGUOUS (ma 5: anh cung hop le o offset ung vien khac cua bo
             (0 va cac ung vien cua --board), khong phan biet duoc; dua vao .config).
Voi EBB36 ban build ~47 KiB phu ca 0 lan 0x2000 nen thuong ra AMBIGUOUS.

Quy tac phan loai la suy luan tu cau truc bang vector Cortex-M, CHUA kiem chung tren dump
that cua hai bo. UNKNOWN nghia la KHONG DU CAN CU: khong nap, dung theo D1.
"""
import re
import struct
import sys
import zlib

RAM_LO, RAM_HI = 0x20000000, 0x40000000
BOOT_NAMES = ("katapult", "canboot")
APP_NAMES = ("klipper", "kalico")
BOARDS = {"octopus": (0x20000,), "ebb36": (0x2000,), "auto": (0x2000, 0x20000)}
VIEW_OFFSETS = (0x0, 0x2000, 0x20000)
# --app: so muc vector kiem. 16 = cac ngoai le loi (dung cho ca M0+ va M7). Octopus (H723, M7) dung 64:
# ban build that 0.13.0-822 co 63/63 muc nam trong vung nap (fleet\reflash\2026-11-25).
# EBB36 (G0B1, M0+) chi 16: bang vector ngan hon, cac muc sau la du lieu.
APP_NVEC = {"octopus": 64, "ebb36": 16, "auto": 16}
APP_EXIT = {"APP_OFFSET_OK": 0, "APP_OFFSET_MISMATCH": 4, "APP_OFFSET_AMBIGUOUS": 5}
# Khoang FF toi thieu sat truoc ung vien de coi [0, c) la bootloader da ket thuc.
# 0x2000: 16 byte la GIA DINH "Katapult khong lap kin 8 KiB", chua kiem chung tren ban that.
BOOT_TAIL_FF = {0x2000: 16, 0x20000: 0x1000}
EXIT = {"NO_BOOTLOADER": 0, "BOOTLOADER_8K": 0, "BOOTLOADER_128K": 0,
        "BOOTLOADER_ONLY_NO_APP": 0, "UNKNOWN": 2, "EMPTY": 3}


def positions(data_lower, name, limit=5):
    res = []
    for needle in (name.encode("ascii"), name.encode("utf-16-le")):
        i = data_lower.find(needle)
        while i != -1 and len(res) < limit:
            res.append(i)
            i = data_lower.find(needle, i + 1)
    return sorted(set(res))


def read_vec(d, off, base):
    if off + 16 > len(d):
        return None
    sp, rv, nmi, hf = struct.unpack_from("<4I", d, off)
    lo = base + off

    def flash_ok(x):
        return (x & 1) == 1 and lo <= x < base + 0x400000

    ok = (RAM_LO <= sp < RAM_HI and flash_ok(rv)
          and all(x == 0 or flash_ok(x) for x in (nmi, hf)))
    return {"off": off, "sp": sp, "reset": rv, "nmi": nmi, "hf": hf, "ok": ok}


def looks_like_vec(d, off, base):
    """8 byte dau co dang SP trong RAM + RESET le trong flash (bo qua cac vector sau)."""
    if off + 8 > len(d):
        return False
    sp, rv = struct.unpack_from("<2I", d, off)
    return RAM_LO <= sp < RAM_HI and (rv & 1) == 1 and base <= rv < base + 0x400000


def ff_runs(d, min_len=4096):
    return [(m.start(), m.end()) for m in re.finditer(b"\xff{%d,}" % min_len, d)]


def find_zlib_dict(d, max_tries=3000):
    """Tim khoi du lieu nhan dang Klipper (zlib, JSON co "commands" va "config")."""
    tries = 0
    for m in re.finditer(b"\x78[\x01\x5e\x9c\xda]", d):
        tries += 1
        if tries > max_tries:
            break
        try:
            out = zlib.decompressobj().decompress(d[m.start():m.start() + 0x20000], 1 << 20)
        except Exception:
            continue
        if b'"commands"' in out and b'"config"' in out:
            ver = re.search(rb'"version":\s*"([^"]*)"', out)
            return m.start(), (ver.group(1).decode("ascii", "replace") if ver else "?")
    return None


def analyse(d, base, board="auto"):
    """Tra ve (ket_luan, [dong bang chung/ly do])."""
    n = len(d)
    cands = BOARDS[board]
    if n == 0 or d.count(b"\xff") == n or d.count(b"\x00") == n:
        return "EMPTY", ["anh rong hoac toan 0xFF/0x00"]
    v0 = read_vec(d, 0, base)
    if v0 is None or not v0["ok"]:
        return "UNKNOWN", ["bang vector tai 0x0 khong hop le hoac file < 16 byte"]
    need = max(cands) + 16
    if n < need:
        return "UNKNOWN", ["dump qua ngan: can >= 0x%X byte cho --board %s, co 0x%X" % (need, board, n)]
    low = d.lower()
    runs = ff_runs(d)
    boot = [(nm, p) for nm in BOOT_NAMES for p in positions(low, nm)]
    app = [(nm, p) for nm in APP_NAMES for p in positions(low, nm)]
    zd = find_zlib_dict(d)
    block0_end = runs[0][0] if runs else n  # khoi lien tuc bat dau tu 0 (chua vector)
    boot_in = [x for x in boot if x[1] < block0_end]
    boot_out = [x for x in boot if x[1] >= block0_end]
    valid = []
    for c in cands:
        v = read_vec(d, c, base)
        if v and v["ok"]:
            valid.append(c)
    if len(valid) > 1:
        return "UNKNOWN", ["bang vector hop le o nhieu ung vien: %s" % ", ".join("0x%X" % c for c in valid)]
    if len(valid) == 1:
        c = valid[0]
        why = []
        boot_ev = [x for x in boot_in if x[1] < c]
        if not boot_ev:
            return "UNKNOWN", ["co vector o 0x%X nhung khong nhan dien duoc bootloader (khong co chuoi katapult/canboot "
                               "trong khoi bat dau tu 0, duoi 0x%X): co the la bang con tro trong ma ung dung, "
                               "hoac bootloader cua hang; khoang FF mot minh khong du" % (c, c)]
        if not v0["reset"] < base + c:
            return "UNKNOWN", ["RESET cua vector 0x0 (0x%08X) khong nam duoi 0x%X" % (v0["reset"], c)]
        # Cau truc: [0, c) phai la mot anh bootloader doc lap, khong phai ung dung lien mach di qua c.
        # (i) 16 muc dau cua bang vector 0x0: moi muc khac 0 (va khac 0xFFFFFFFF = o chua ghi) tro vao [base, base+c)
        ents = struct.unpack_from("<16I", d, 0) if n >= 64 else ()
        out_vec = [(i, x) for i, x in enumerate(ents) if i > 0 and x not in (0, 0xFFFFFFFF) and not base <= x < base + c]
        if len(ents) < 16 or out_vec:
            return "UNKNOWN", ["bang vector 0x0 co muc tro ra ngoai [0x%08X, 0x%08X): %s: khong phai anh bootloader doc lap"
                               % (base, base + c, ", ".join("#%d=0x%08X" % e for e in out_vec) or "file < 64 byte")]
        # (ii) du lieu bootloader ket thuc truoc c: khoang toan FF sat ngay truoc c
        data_end = len(d[:c].rstrip(b"\xff"))
        min_gap = BOOT_TAIL_FF[c]
        if c - data_end < min_gap:
            return "UNKNOWN", ["khong co khoang FF >= 0x%X byte sat truoc 0x%X (du lieu toi 0x%X): co the la mot ung dung "
                               "lien mach di qua 0x%X, khong phai bootloader roi toi ung dung" % (min_gap, c, data_end, c)]
        # (iii) chu ky nam trong khoi bat dau tu 0 (boot_in: truoc khoang FF >= 4 KiB dau tien) va duoi c,
        # nen tu dong nam truoc data_end (chuoi khong the la byte FF).
        app_ev = [x for x in app if x[1] >= c]
        zdict_ev = zd is not None and zd[0] >= c
        if not (app_ev or zdict_ev):
            return "UNKNOWN", ["co bootloader/vector o 0x%X nhung khong co bang chung ung dung "
                               "(chuoi klipper/kalico hoac khoi zlib) o vung >= 0x%X" % (c, c)]
        why.append("vector 0x0 hop le, RESET=0x%08X < base+0x%X" % (v0["reset"], c))
        why.append("vector tai 0x%X hop le (SP=0x%08X RESET=0x%08X)" % (c, read_vec(d, c, base)["sp"], read_vec(d, c, base)["reset"]))
        why.append("16 muc vector 0x0 deu = 0/FFFFFFFF hoac tro vao [0x%08X, 0x%08X)" % (base, base + c))
        why.append("du lieu bootloader ket thuc tai 0x%X, khoang FF 0x%X-0x%X (>= 0x%X byte) sat truoc ung vien"
                   % (data_end, data_end, c, min_gap))
        for nm, p in boot_ev:
            why.append("chuoi %s tai 0x%X (trong vung bootloader)" % (nm, p))
        for nm, p in app_ev:
            why.append("chuoi %s tai 0x%X (vung ung dung)" % (nm, p))
        if zdict_ev:
            why.append("khoi zlib nhan dang Klipper tai 0x%X, version %s" % (zd[0], zd[1]))
        return ("BOOTLOADER_128K" if c == 0x20000 else "BOOTLOADER_8K"), why
    # khong co bang vector ung dung o ung vien nao
    if boot_in and not app and not zd and not boot_out:
        return "BOOTLOADER_ONLY_NO_APP", ["vector 0x0 hop le", "khong co vector ung dung o %s" % ", ".join("0x%X" % c for c in cands)]\
            + ["chuoi %s tai 0x%X (trong khoi bat dau tu 0)" % x for x in boot_in] + ["khong co chuoi/khoi ung dung"]
    interior = [(s, e) for s, e in runs if e <= len(d.rstrip(b"\xff"))]
    partial = [c for c in cands if looks_like_vec(d, c, base)]
    if (app or zd) and not boot and not interior and not partial:
        why = ["vector 0x0 hop le (SP=0x%08X RESET=0x%08X)" % (v0["sp"], v0["reset"]),
               "khong co vector ung dung hop le o %s (dump du dai)" % ", ".join("0x%X" % c for c in cands),
               "8 byte dau tai %s KHONG co dang SP trong RAM + RESET le trong flash"
               % ", ".join("0x%X" % c for c in cands),
               "khong co chuoi katapult/canboot o bat ky dau",
               "du lieu lien tuc tu 0 den byte khong-FF cuoi (0x%X), khong co khoang FF >= 4 KiB o giua" % len(d.rstrip(b"\xff"))]
        for nm, p in app:
            why.append("chuoi %s tai 0x%X" % (nm, p))
        if zd:
            why.append("khoi zlib nhan dang Klipper tai 0x%X, version %s" % (zd[0], zd[1]))
        return "NO_BOOTLOADER", why
    reasons = ["khong du can cu de ket luan"]
    if boot_out:
        reasons.append("co chuoi bootloader nam NGOAI khoi bat dau tu 0: %s" % boot_out)
    if interior:
        reasons.append("co khoang FF >= 4 KiB nam giua du lieu: %s" % interior)
    for c in partial:
        reasons.append("8 byte dau tai 0x%X co dang SP+RESET cua bang vector (cac vector sau khong hop le): "
                       "co the co ung dung/bootloader o day" % c)
    if not (app or zd):
        reasons.append("khong co chuoi klipper/kalico va khong co khoi zlib nhan dang (ban CAN-only co the khong co chuoi)")
    if boot and (app or zd):
        reasons.append("vua co bang chung bootloader vua co ung dung nhung khong thay vector ung dung o ung vien")
    return "UNKNOWN", reasons


def report(d, base, board):
    print("kich thuoc: %d byte (0x%X), base 0x%08X, board %s" % (len(d), len(d), base, board))
    for o in VIEW_OFFSETS:
        v = read_vec(d, o, base)
        if v is None:
            print("vector @0x%X: (file qua ngan)" % o)
        else:
            print("vector @0x%X: SP=0x%08X RESET=0x%08X NMI=0x%08X HARDFAULT=0x%08X -> %s"
                  % (o, v["sp"], v["reset"], v["nmi"], v["hf"], "HOP LE" if v["ok"] else "khong hop le"))
    low = d.lower()
    for nm in BOOT_NAMES + APP_NAMES:
        p = positions(low, nm)
        print("chuoi %-8s: %s" % (nm, ", ".join("0x%X" % x for x in p) if p else "khong co"))
    zd = find_zlib_dict(d)
    print("khoi zlib nhan dang Klipper: %s" % ("tai 0x%X, version %s" % zd if zd else "khong thay"))
    runs = ff_runs(d)
    print("khoang toan FF (>= 4 KiB): %s" % (", ".join("0x%X-0x%X" % r for r in runs) if runs else "khong co"))
    print("byte khong-FF cuoi cung: 0x%X" % len(d.rstrip(b"\xff")))
    verdict, why = analyse(d, base, board)
    print("bang chung/ly do:" if verdict not in ("UNKNOWN", "EMPTY") else "ly do:")
    for w in why:
        print("  - %s" % w)
    print("KET LUAN: %s" % verdict)
    return verdict


def app_fits(d, off, base, nvec):
    """File ung dung (bang vector o byte 0) co hop voi dia chi nap base+off khong.
    Tra ve (hop, ly_do). Dieu kien: SP trong RAM; RESET le; RESET va moi muc khac 0/0xFFFFFFFF
    trong nvec muc dau nam trong [base+off, base+off+len)."""
    lo, hi = base + off, base + off + len(d)
    ents = struct.unpack_from("<%dI" % min(nvec, len(d) // 4), d, 0)
    if not RAM_LO <= ents[0] < RAM_HI:
        return False, "SP=0x%08X khong nam trong RAM" % ents[0]
    if not ents[1] & 1:
        return False, "RESET=0x%08X chan" % ents[1]
    bad = [(i, x) for i, x in enumerate(ents) if i > 0 and x not in (0, 0xFFFFFFFF) and not lo <= x < hi]
    if bad:
        return False, "%d muc vector ngoai [0x%08X, 0x%08X), dau tien #%d=0x%08X" % ((len(bad), lo, hi) + bad[0])
    return True, "%d muc dau: moi muc khac 0/FFFFFFFF nam trong [0x%08X, 0x%08X)" % (len(ents), lo, hi)


def check_app(d, off, base, board="auto"):
    """Tra ve APP_OFFSET_OK | APP_OFFSET_MISMATCH | APP_OFFSET_AMBIGUOUS (va in ra)."""
    nvec = APP_NVEC.get(board, 16)
    print("offset kiem: 0x%X, board %s, so muc vector kiem: %d, kich thuoc file 0x%X" % (off, board, nvec, len(d)))
    if len(d) < 16:
        print("file qua ngan (< 16 byte)")
        print("KET LUAN APP: APP_OFFSET_MISMATCH")
        return "APP_OFFSET_MISMATCH"
    sp, rv, nmi, hf = struct.unpack_from("<4I", d, 0)
    print("SP=0x%08X RESET=0x%08X NMI=0x%08X HARDFAULT=0x%08X" % (sp, rv, nmi, hf))
    ok, why = app_fits(d, off, base, nvec)
    print("tai 0x%X: %s" % (off, why))
    if not ok:
        res = "APP_OFFSET_MISMATCH"
    else:
        others = [c for c in sorted({0} | set(BOARDS[board])) if c != off and app_fits(d, c, base, nvec)[0]]
        if others:
            print("anh cung hop le o offset ung vien khac: %s; anh KHONG du de phan biet, "
                  "dua vao CONFIG_FLASH_APPLICATION_ADDRESS trong .config da dung de build" % ", ".join("0x%X" % c for c in others))
            res = "APP_OFFSET_AMBIGUOUS"
        else:
            res = "APP_OFFSET_OK"
    print("KET LUAN APP: %s" % res)
    return res


# ---------------------------------------------------------------- tu kiem
def _img(size=0x100000):
    return bytearray(b"\xff" * size)


def _vec(img, off, base, rel, sp=0x24080000, nmi=None):
    rv = base + rel
    struct.pack_into("<4I", img, off, sp, rv | 1, (rv + 2) | 1 if nmi is None else nmi, (rv + 4) | 1)


def _code(img, off, n):
    img[off:off + n] = bytes(((i * 7 + 3) & 0xFF) for i in range(n))


def _text(img, off, s, utf16=False):
    b = s.encode("utf-16-le") if utf16 else s.encode("ascii")
    img[off:off + len(b)] = b


def _dict_blob():
    import json
    return zlib.compress(json.dumps({"commands": {}, "config": {"MCU": "x"}, "version": "v0.13.0-822-gtest"}).encode(), 9)


def build_cases(base=0x08000000):
    c = {}

    def add(name, img, want, board="auto"):
        c[name] = (img, want, board)

    a = _img(); _code(a, 0x40, 0x600); _text(a, 0x400, "Klipper"); _vec(a, 0, base, 0x100)
    add("c1_app0_nho_co_chuoi", a, "NO_BOOTLOADER")
    a = _img(); _code(a, 0x40, 0x30000); _text(a, 0x400, "klipper"); _vec(a, 0, base, 0x100); _vec(a, 0x20000, base, 0x20100)
    add("c2_app_lon_vector_gia_0x20000", a, "UNKNOWN")
    a = _img(); _code(a, 0x40, 0x30000); _text(a, 0x400, "klipper"); _vec(a, 0, base, 0x100); _vec(a, 0x2000, base, 0x2100)
    add("c2b_app_lon_vector_gia_0x2000", a, "UNKNOWN")
    a = _img(); _code(a, 0x40, 0x30000); _text(a, 0x400, "kalico"); _vec(a, 0, base, 0x100)
    a[0x1F000:0x20000] = b"\xff" * 0x1000  # co khoang FF sat truoc 0x20000 NHUNG van la app lon voi bang con tro gia
    _vec(a, 0x20000, base, 0x20100)
    add("c2c_app_lon_bang_con_tro_gia_co_khoang_FF_nhung_khong_chuoi_boot", a, "UNKNOWN")
    a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x700); _text(a, 0x800, "Katapult")
    _vec(a, 0x20000, base, 0x20100); _code(a, 0x20040, 0x600); _text(a, 0x20400, "kalico")
    add("c3_katapult_128K_kalico", a, "BOOTLOADER_128K")
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x600); _text(a, 0x2400, "Klipper")
    add("c4_ebb36_katapult_8K", a, "BOOTLOADER_8K")
    a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x700); _text(a, 0x800, "Katapult")
    add("c5_chi_bootloader", a, "BOOTLOADER_ONLY_NO_APP")
    add("c6a_toan_FF", _img(), "EMPTY")
    add("c6b_toan_00", bytearray(0x100000), "EMPTY")
    add("c6c_rong", bytearray(), "EMPTY")
    add("c6d_3_byte", bytearray(b"\x01\x02\x03"), "UNKNOWN")
    a = _img(0x1000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Klipper")
    add("c6f_chi_4KiB_ung_dung", a, "UNKNOWN")
    a = _img(0x20000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    add("c6g_dump_dung_128KiB", a, "UNKNOWN")
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100, sp=0x20004000); _code(a, 0x2040, 0x600)
    add("c8_ebb36_CAN_only_khong_chuoi", a, "UNKNOWN")
    a = _img(); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "app"); _text(a, 0x5000, "katapult")
    add("c9a_katapult_o_vung_app_khong_klipper", a, "UNKNOWN")
    a = _img(); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "klipper"); _text(a, 0x5000, "katapult")
    add("c9b_katapult_o_vung_app_co_klipper", a, "UNKNOWN")
    a = _img(); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "klipper", utf16=True)
    add("c9c_klipper_utf16", a, "NO_BOOTLOADER")
    # bootloader cua hang: khong co chuoi katapult, co khoang FF sat truoc 0x20000 va app hop le.
    # Thiet ke luot 4: khong nhan dien duoc bootloader -> UNKNOWN (truoc day BOOTLOADER_128K).
    def mk_c():
        a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x1000); _vec(a, 0x20000, base, 0x20100)
        _code(a, 0x20040, 0x600); _text(a, 0x20400, "Klipper"); return a
    add("c_hang128K_khong_chuoi_FF --board octopus", mk_c(), "UNKNOWN", "octopus")
    add("c_hang128K_khong_chuoi_FF auto", mk_c(), "UNKNOWN")
    add("f3_hang128K_FF --board ebb36", mk_c(), "UNKNOWN", "ebb36")

    def mk_d(nmi=None):
        a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x20000 - 0x40); _vec(a, 0x20000, base, 0x20100, nmi=nmi)
        _code(a, 0x20040, 0x600); _text(a, 0x20400, "Klipper"); return a
    add("d_hang128K_lap_day_khong_FF --board octopus", mk_d(), "UNKNOWN", "octopus")
    add("d_hang128K_lap_day_khong_FF auto", mk_d(), "UNKNOWN")
    add("j_hang_lap_day_app_NMI_ngoai_flash", mk_d(0x08500001), "UNKNOWN")
    add("j_hang_lap_day_app_NMI_ngoai_flash --board octopus", mk_d(0x08500001), "UNKNOWN", "octopus")

    # app lon khong bootloader, vector gia + khoang FF 4 KiB sat truoc ung vien, chuoi o truoc/sau ung vien
    def mk_a(sp):
        a = _img(); _code(a, 0x40, 0x30000); _vec(a, 0, base, 0x100); a[0x1F000:0x20000] = b"\xff" * 0x1000
        _vec(a, 0x20000, base, 0x20100); _text(a, sp, "klipper"); return a
    add("a1_FFgap_vecgia_klipper@0x400", mk_a(0x400), "UNKNOWN")
    add("a2_FFgap_vecgia_klipper@0x25000", mk_a(0x25000), "UNKNOWN")
    add("a2_FFgap_vecgia_klipper@0x25000 --board octopus", mk_a(0x25000), "UNKNOWN", "octopus")

    def mk_b(sp):
        a = _img(0x80000); _code(a, 0x40, 0x8000); _vec(a, 0, base, 0x100); a[0x1000:0x2000] = b"\xff" * 0x1000
        _vec(a, 0x2000, base, 0x2100); _text(a, sp, "klipper"); return a
    add("b1_ebb36_FFgap_vecgia_klipper@0x400", mk_b(0x400), "UNKNOWN", "ebb36")
    add("b2_ebb36_FFgap_vecgia_klipper@0x3000", mk_b(0x3000), "UNKNOWN", "ebb36")
    add("b2_ebb36_FFgap_vecgia_klipper@0x3000 auto", mk_b(0x3000), "UNKNOWN")

    # Katapult 8K + app khong chuoi + khoi zlib (that / ngau nhien / zlib khong phai dict)
    def mk_e(blob):
        a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
        _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x300); a[0x3000:0x3000 + len(blob)] = blob; return a
    add("e1_kat8K_zlib_that --board ebb36", mk_e(_dict_blob()), "BOOTLOADER_8K", "ebb36")
    add("e1b_kat8K_zlib_that auto", mk_e(_dict_blob()), "BOOTLOADER_8K")
    add("e2_kat8K_78_9c_rac", mk_e(b"\x78\x9c" + bytes(((i * 131 + 17) * 29) & 0xFF for i in range(300))), "UNKNOWN", "ebb36")
    add("e3_kat8K_zlib_khong_phai_dict", mk_e(zlib.compress(b'{"foo": 1}', 9)), "UNKNOWN", "ebb36")

    # sai --board
    a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x700); _text(a, 0x800, "Katapult")
    _vec(a, 0x20000, base, 0x20100); _code(a, 0x20040, 0x600); _text(a, 0x20400, "kalico")
    add("f1_dump_octopus_katapult --board ebb36", a, "UNKNOWN", "ebb36")
    add("f1b_dump_octopus_katapult --board octopus", a, "BOOTLOADER_128K", "octopus")
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x600); _text(a, 0x2400, "Klipper")
    add("f2_dump_ebb36_katapult --board octopus", a, "UNKNOWN", "octopus")
    a = _img(); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x600); _text(a, 0x400, "Klipper")
    add("f4_app0 --board ebb36", a, "NO_BOOTLOADER", "ebb36")

    # luot 5: ung dung lien mach qua ung vien, co chuoi canboot o dau + vector gia + klipper sau (t_harness3 b1, b2)
    a = _img(0x80000); _code(a, 0x40, 0x30000); _vec(a, 0, base, 0x100); _vec(a, 0x2000, base, 0x2100)
    _text(a, 0x500, "canboot"); _text(a, 0x3000, "klipper")
    add("h3b1_app_lien_mach_canboot_vecgia@0x2000 --board ebb36", a, "UNKNOWN", "ebb36")
    a = _img(); _code(a, 0x40, 0x30000); _vec(a, 0, base, 0x100); _vec(a, 0x20000, base, 0x20100)
    _text(a, 0x500, "canboot"); _text(a, 0x25000, "klipper")
    add("h3b2_app_lien_mach_canboot_vecgia@0x20000 --board octopus", a, "UNKNOWN", "octopus")
    # (i) Katapult hop le nhung muc vector #5 tro vao vung ung dung
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    struct.pack_into("<I", a, 0x14, base + 0x2101)
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x600); _text(a, 0x2400, "Klipper")
    add("r5i_vector0_muc5_tro_vao_app --board ebb36", a, "UNKNOWN", "ebb36")
    # (ii) Katapult nhung du lieu lap kin toi ung vien (khong co khoang FF sat truoc)
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x2000 - 0x40); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x600); _text(a, 0x2400, "Klipper")
    add("r5ii_8K_khong_FF_sat_truoc --board ebb36", a, "UNKNOWN", "ebb36")
    a = _img(); _vec(a, 0, base, 0x200); _code(a, 0x40, 0x1F800 - 0x40); _text(a, 0x800, "Katapult")
    _vec(a, 0x20000, base, 0x20100); _code(a, 0x20040, 0x600); _text(a, 0x20400, "kalico")
    add("r5ii_128K_FF_sat_truoc_chi_2KiB --board octopus", a, "UNKNOWN", "octopus")
    # bien: 8K voi dung 16 byte FF sat truoc -> van BOOTLOADER_8K
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x2000 - 0x10 - 0x40); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x600); _text(a, 0x2400, "Klipper")
    add("r5ii_8K_dung_16_byte_FF --board ebb36", a, "BOOTLOADER_8K", "ebb36")
    # ung dung CAN-only khong chuoi nhung co khoi zlib nhan dang
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300); _text(a, 0x400, "Katapult")
    _vec(a, 0x2000, base, 0x2100); _code(a, 0x2040, 0x300)
    blob = _dict_blob(); a[0x3000:0x3000 + len(blob)] = blob
    add("k2_ebb36_zlib_dict", a, "BOOTLOADER_8K")
    a = _img(0x80000); _vec(a, 0, base, 0x100); _code(a, 0x40, 0x300)
    blob = _dict_blob(); a[0x400:0x400 + len(blob)] = blob
    add("k3_ebb36_khong_bootloader_zlib_dict", a, "NO_BOOTLOADER")
    return c


def selftest(write_dir=None):
    import os
    base = 0x08000000
    bad = 0
    for name, (img, want, board) in build_cases(base).items():
        got, _ = analyse(bytes(img), base, board)
        good = got == want
        if not good:
            bad += 1
        print("%s %-62s mong doi %-22s duoc %s" % ("OK " if good else "SAI", name, want, got))
        if write_dir:
            os.makedirs(write_dir, exist_ok=True)
            with open(os.path.join(write_dir, "s_" + re.sub(r"[^A-Za-z0-9_.]+", "_", name) + ".bin"), "wb") as f:
                f.write(bytes(img))
    import io
    import contextlib

    def app_check(app, off, board):
        with contextlib.redirect_stdout(io.StringIO()):
            return check_app(bytes(app), off, base, board)

    n_app = 0
    for name, app, off, board, want in _app_cases(base):
        got = app_check(app, off, board)
        n_app += 1
        if got not in want:
            bad += 1
        print("%s --app %-46s mong doi %-42s duoc %s" % ("OK " if got in want else "SAI", name, "/".join(want), got))
    print("kiem --app (%d ca dung giong ban build that): %s" % (n_app, "OK" if bad == 0 else "co SAI o tren"))
    # tuy chon: ban build that, neu co mat canh repo (khong co tren Pi thi bo qua)
    real = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "fleet", "reflash", "2026-11-25")
    ok_amb = ("APP_OFFSET_OK", "APP_OFFSET_AMBIGUOUS")
    real_cases = (("octopus_off0_klipper-0.13.0-822.bin", "octopus", {0x0: ("APP_OFFSET_OK",), 0x20000: ("APP_OFFSET_MISMATCH",)}),
                  ("octopus_off128k_klipper-0.13.0-822.bin", "octopus", {0x20000: ("APP_OFFSET_OK",), 0x0: ("APP_OFFSET_MISMATCH",)}),
                  ("trident_out_klipper.bin", "octopus", {0x20000: ("APP_OFFSET_OK",), 0x0: ("APP_OFFSET_MISMATCH",)}),
                  ("ebb_off0_klipper-0.13.0-822.bin", "ebb36", {0x0: ok_amb, 0x2000: ok_amb}),
                  ("ebb_off8k_klipper-0.13.0-822.bin", "ebb36", {0x2000: ok_amb, 0x0: ok_amb}))
    for fn, board, offs in real_cases:
        p = os.path.join(real, fn)
        if not os.path.isfile(p):
            print("(bo qua ban build that: khong co %s)" % fn)
            continue
        with open(p, "rb") as f:
            data = f.read()
        for off, want in offs.items():
            got = app_check(data, off, board)
            if got not in want:
                bad += 1
            print("%s --app that %-40s 0x%-6X %-8s mong doi %-42s duoc %s"
                  % ("OK " if got in want else "SAI", fn, off, board, "/".join(want), got))
    print("TU KIEM: %s" % ("DAT" if bad == 0 else "%d LOI" % bad))
    return bad == 0


def _app_build(base, rel, size, sp, n_handlers):
    """Anh ung dung dung giong ban build Klipper that: RESET cach dau ~31 KiB, n_handlers muc vector
    tro vao ma trong anh, cac muc sau (neu co) la du lieu (vd M0+), phan con lai la ma."""
    lo = base + rel
    a = bytearray(size)
    _code(a, 0, size)
    words = [sp, (lo + 0x7A45) | 1] + [(lo + 0x7B00 + 2 * i) | 1 for i in range(2, n_handlers)]
    words += [0x4B072200 + i for i in range(64 - len(words))]
    struct.pack_into("<64I", a, 0, *words)
    return a


def _app_cases(base):
    O, M, A = ("APP_OFFSET_OK",), ("APP_OFFSET_MISMATCH",), ("APP_OFFSET_AMBIGUOUS",)
    o0 = _app_build(base, 0x0, 0xBEF0, 0x20020000, 64)
    o128 = _app_build(base, 0x20000, 0xBF80, 0x20020000, 64)
    e0 = _app_build(base, 0x0, 0xB7B0, 0x20024000, 38)
    e8 = _app_build(base, 0x2000, 0xB838, 0x20024000, 38)
    o0_bad40 = bytearray(o0); struct.pack_into("<I", o0_bad40, 40 * 4, (base + 0x30001) | 1)
    sp_flash = bytearray(o0); struct.pack_into("<I", sp_flash, 0, base + 0x1000)
    rst_even = bytearray(o0); struct.pack_into("<I", rst_even, 4, base + 0x7A44)
    e8_small = _app_build(base, 0x2000, 0x1800, 0x20024000, 16)
    struct.pack_into("<I", e8_small, 4, (base + 0x2000 + 0x101) | 1)
    for i in range(2, 16):
        struct.pack_into("<I", e8_small, 4 * i, (base + 0x2000 + 0x200 + 2 * i) | 1)
    return (("octopus_off0 tai 0x0 --board octopus", o0, 0x0, "octopus", O),
            ("octopus_off0 tai 0x20000 --board octopus", o0, 0x20000, "octopus", M),
            ("octopus_off0 tai 0x0 auto (0x2000 cung hop)", o0, 0x0, "auto", A),
            ("octopus_off128k tai 0x20000 --board octopus", o128, 0x20000, "octopus", O),
            ("octopus_off128k tai 0x0 --board octopus", o128, 0x0, "octopus", M),
            ("octopus_off128k tai 0x20000 auto", o128, 0x20000, "auto", O),
            ("ebb_off0 tai 0x0 --board ebb36", e0, 0x0, "ebb36", A),
            ("ebb_off0 tai 0x2000 --board ebb36", e0, 0x2000, "ebb36", A),
            ("ebb_off8k tai 0x2000 --board ebb36", e8, 0x2000, "ebb36", A),
            ("ebb_off8k tai 0x0 --board ebb36", e8, 0x0, "ebb36", A),
            ("ebb_off8k tai 0x20000 --board ebb36", e8, 0x20000, "ebb36", M),
            ("ebb_off8k nho 6 KiB tai 0x2000 --board ebb36", e8_small, 0x2000, "ebb36", O),
            ("ebb_off8k nho 6 KiB tai 0x0 --board ebb36", e8_small, 0x0, "ebb36", M),
            ("octopus_off0 muc #40 ra ngoai --board octopus", o0_bad40, 0x0, "octopus", M),
            ("octopus_off0 SP trong flash", sp_flash, 0x0, "octopus", M),
            ("octopus_off0 RESET chan", rst_even, 0x0, "octopus", M),
            ("file 3 byte", bytearray(b"\x01\x02\x03"), 0x0, "auto", M))


def parse_int(s, what):
    try:
        return int(s, 0)
    except ValueError:
        raise SystemExit_(1, "gia tri %s khong hop le: %r" % (what, s))


class SystemExit_(Exception):
    def __init__(self, code, msg):
        super().__init__(msg)
        self.code = code
        self.msg = msg


def main(argv):
    import argparse

    class P(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write("loi dung sai: %s\n" % message)
            sys.exit(1)

    p = P(add_help=False)
    p.add_argument("file", nargs="?")
    p.add_argument("--app")
    p.add_argument("--selftest", action="store_true")
    p.add_argument("--write")
    p.add_argument("--board", default="auto", choices=sorted(BOARDS))
    p.add_argument("--base", default="0x08000000")
    p.add_argument("-h", "--help", action="store_true")
    a = p.parse_args(argv)
    try:
        if a.help:
            print(__doc__)
            return 0
        base = parse_int(a.base, "--base")
        if a.selftest:
            return 0 if selftest(a.write) else 1
        if a.file is None:
            sys.stderr.write("loi dung sai: thieu ten file\n")
            return 1
        try:
            with open(a.file, "rb") as f:
                d = f.read()
        except OSError as e:
            sys.stderr.write("khong doc duoc file: %s\n" % e)
            return 1
        if a.app is not None:
            off = parse_int(a.app, "--app")
            return APP_EXIT[check_app(d, off, base, a.board)]
        return EXIT[report(d, base, a.board)]
    except SystemExit_ as e:
        sys.stderr.write("loi dung sai: %s\n" % e.msg)
        return e.code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
