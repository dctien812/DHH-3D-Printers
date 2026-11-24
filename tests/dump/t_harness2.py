import json, os, random, struct, subprocess, zlib
D = "/mnt/d/WORK/3D-Printer-Klipper/tests/tmp/dump"
S = "/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py"
B = 0x08000000
def img(n=0x100000): return bytearray(b"\xff" * n)
def vec(a, off, rel, sp=0x24080000, nmi=None):
    rv = B + rel
    struct.pack_into("<4I", a, off, sp, rv | 1, (B+rel+2)|1 if nmi is None else nmi, (B+rel+4)|1)
def code(a, off, n): a[off:off+n] = bytes(((i*7+3) & 0xFF) for i in range(n))
def txt(a, off, s): a[off:off+len(s)] = s.encode()
def blob(ok=True):
    o = {"commands": {}, "config": {"MCU": "x"}, "version": "v1"} if ok else {"foo": 1}
    return zlib.compress(json.dumps(o).encode(), 9)
def put(a, off, b): a[off:off+len(b)] = b
T = []  # (name, bytes, args, expected)
# (a) app lon khong boot, vector gia @0x20000, FF 4KiB ngay truoc 0x20000
def mk_a(strpos):
    a = img(); code(a,0x40,0x30000); vec(a,0,0x100); a[0x1F000:0x20000] = b"\xff"*0x1000; vec(a,0x20000,0x20100); txt(a,strpos,"klipper"); return a
T.append(("a1_FFgap+vecgia, klipper@0x400", mk_a(0x400), [], "UNKNOWN"))
T.append(("a2_FFgap+vecgia, klipper@0x25000 (sau 0x20000)", mk_a(0x25000), [], "UNKNOWN (neu BOOTLOADER_128K = nguy hiem)"))
# (b) ebb36
def mk_b(strpos):
    a = img(0x80000); code(a,0x40,0x8000); vec(a,0,0x100); a[0x1000:0x2000] = b"\xff"*0x1000; vec(a,0x2000,0x2100); txt(a,strpos,"klipper"); return a
T.append(("b1_ebb36 FFgap+vecgia, klipper@0x400", mk_b(0x400), ["--board","ebb36"], "UNKNOWN"))
T.append(("b2_ebb36 FFgap+vecgia, klipper@0x3000", mk_b(0x3000), ["--board","ebb36"], "UNKNOWN (neu BOOTLOADER_8K = nguy hiem)"))
# (c) bootloader hang 128K khong chuoi, ket thuc FF, app klipper
a = img(); vec(a,0,0x200); code(a,0x40,0x1000); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
# luot 3: ky vong doi thanh UNKNOWN theo quyet dinh thiet ke (khoang FF khong con la bang chung; bootloader hang khong nhan dien duoc -> UNKNOWN)
T.append(("c_hang128K_khong_chuoi_FF", a, ["--board","octopus"], "UNKNOWN"))
# (d) bootloader hang lap day khong FF
a = img(); vec(a,0,0x200); code(a,0x40,0x20000-0x40); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("d_hang128K_lap_day_khong_FF", a, ["--board","octopus"], "UNKNOWN"))
# (e) Katapult 8K + app khong chuoi + zlib
def mk_e(b):
    a = img(0x80000); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); put(a,0x3000,b); return a
T.append(("e1_kat8K+zlib_that", mk_e(blob()), ["--board","ebb36"], "BOOTLOADER_8K"))
T.append(("e1b_kat8K+zlib_that, auto", mk_e(blob()), [], "BOOTLOADER_8K"))
rnd = random.Random(1)
T.append(("e2_kat8K+78_9c_ngau_nhien", mk_e(b"\x78\x9c"+bytes(rnd.randrange(256) for _ in range(300))), ["--board","ebb36"], "UNKNOWN"))
T.append(("e3_kat8K+zlib_hop_le_khong_phai_dict", mk_e(blob(False)), ["--board","ebb36"], "UNKNOWN"))
# (f) sai board
a = img(); vec(a,0,0x200); code(a,0x40,0x700); txt(a,0x800,"Katapult"); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"kalico")
T.append(("f1_octopus_kat_dump --board ebb36", a, ["--board","ebb36"], "UNKNOWN"))
T.append(("f1b_octopus_kat_dump --board octopus", a, ["--board","octopus"], "BOOTLOADER_128K"))
b = img(0x80000); vec(b,0,0x100); code(b,0x40,0x300); txt(b,0x400,"Katapult"); vec(b,0x2000,0x2100); code(b,0x2040,0x600); txt(b,0x2400,"Klipper")
T.append(("f2_ebb36_dump --board octopus", b, ["--board","octopus"], "UNKNOWN"))
a = img(); vec(a,0,0x200); code(a,0x40,0x1000); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("f3_hang128K_FF dump --board ebb36", a, ["--board","ebb36"], "UNKNOWN"))
a = img(); vec(a,0,0x100); code(a,0x40,0x600); txt(a,0x400,"Klipper")
T.append(("f4_app0 --board ebb36", a, ["--board","ebb36"], "NO_BOOTLOADER"))
# (g) auto tren (a1,a2,b1,b2,c,d)
T.append(("g_a2 auto", mk_a(0x25000), [], "UNKNOWN"))
T.append(("g_b2 auto", mk_b(0x3000), [], "UNKNOWN"))
a = img(); vec(a,0,0x200); code(a,0x40,0x1000); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("g_c auto", a, [], "UNKNOWN"))  # luot 3: nhu c
a = img(); vec(a,0,0x200); code(a,0x40,0x20000-0x40); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("g_d auto", a, [], "UNKNOWN"))
# (j) hang lap day + app co chuoi nhung vector app khong hop le (NMI ngoai flash)
a = img(); vec(a,0,0x200); code(a,0x40,0x20000-0x40); vec(a,0x20000,0x20100,nmi=0x08500001); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("j_hang_lap_day+app_vector_hong", a, [], "UNKNOWN (neu NO_BOOTLOADER = nguy hiem)"))
def sh(p):
    import hashlib; return hashlib.sha256(open(p,"rb").read()).hexdigest()[:12]
def run(args):
    r = subprocess.run(["python3","-I",S]+args, capture_output=True, text=True); return r.returncode, r.stdout, r.stderr
os.makedirs(D, exist_ok=True)
print("=== CA MOI DUMP")
for n,a,args,exp in T:
    p = D+"/t2_"+n.split()[0].replace("+","_").replace(",","")+".bin"; open(p,"wb").write(bytes(a)); h=sh(p)
    rc,out,err = run([p]+args)
    kl = [l for l in out.splitlines() if l.startswith("KET LUAN")]
    print("%-52s exp=%-40s got=%s rc=%d n=%d hash_giu=%s" % (n,exp,kl,rc,len(kl),sh(p)==h))
print("=== (h) --app cua so RESET")
for rel in (0x0FFC, 0x1000, 0x3000, 0x0100):
    for sz in (0x4000, 0x800):
        a = img(sz); struct.pack_into("<4I", a, 0, 0x24080000, (B+0x20000+rel)|1, 0, 0)
        p = D+"/t2_app_%x_%x.bin"%(rel,sz); open(p,"wb").write(bytes(a))
        rc,out,err = run(["--app","0x20000",p])
        print("RESET=lo+0x%04X size=0x%X -> %s rc=%d" % (rel,sz,[l for l in out.splitlines() if l.startswith("KET")],rc))
print("=== (i) ma thoat")
for args in (["--help"],["/nonexistent"],["--board","zzz",D+"/t2_c_hang128K_khong_chuoi_FF.bin"],["--app"],["--app","0x20000"],["--app","zz",D+"/t2_c_hang128K_khong_chuoi_FF.bin"],[],[D+"/t_c6a_toan_FF.bin"],[D+"/t_c6d_3byte.bin"]):
    rc,out,err = run(args)
    print(args[:3] if args else [], "rc=",rc,"| stderr:", (err.strip().splitlines() or [""])[-1][:80], "| stdout cuoi:", (out.strip().splitlines() or [""])[-1][:60])
