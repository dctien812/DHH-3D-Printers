import os, struct, subprocess
R = "/mnt/d/TTeccS-3D-Printers-Repo/fleet/reflash/2026-11-25/"
S = "/mnt/d/TTeccS-3D-Printers-Repo/docs-internal/tools/dump-inspect.py"
T = "/mnt/d/TTeccS-3D-Printers-Repo/tests/tmp/dump/"
B = 0x08000000
FILES = {"octopus_off0": "octopus_off0_klipper-0.13.0-822.bin", "octopus_off128k": "octopus_off128k_klipper-0.13.0-822.bin",
         "ebb_off0": "ebb_off0_klipper-0.13.0-822.bin", "ebb_off8k": "ebb_off8k_klipper-0.13.0-822.bin", "trident": "trident_out_klipper.bin"}
CFGS = {"octopus_off0": "octopus_off0.config", "octopus_off128k": "octopus_off128k.config", "ebb_off0": "ebb_off0.config", "ebb_off8k": "ebb_off8k.config", "trident": "trident_klipper.config"}
def cfgaddr(n):
    for l in open(R+CFGS[n]):
        if l.startswith("CONFIG_FLASH_APPLICATION_ADDRESS="): return int(l.strip().split("=")[1], 0) - B
# Doc lap: tu parse 64 muc vector
def fits(b, off, nv):
    e = struct.unpack_from("<%dI" % min(nv, len(b)//4), b, 0); lo = B+off; hi = lo+len(b)
    bad = [x for x in e[1:] if x not in (0, 0xFFFFFFFF) and not lo <= x < hi]
    return 0x20000000 <= e[0] < 0x40000000 and (e[1] & 1) == 1 and not bad
def predict(b, off, board):
    nv = 64 if board == "octopus" else 16
    cands = {"octopus": (0, 0x20000), "ebb36": (0, 0x2000), "auto": (0, 0x2000, 0x20000)}[board]
    if not fits(b, off, nv): return "MISMATCH"
    return "AMBIGUOUS" if any(fits(b, c, nv) for c in cands if c != off) else "OK"
def run(args):
    r = subprocess.run(["python3","-I",S]+args, capture_output=True, text=True); return r.returncode, r.stdout
print("=== (1) bang vector that (tu doc) va ket luan script")
for n in FILES:
    b = open(R+FILES[n],"rb").read(); e = struct.unpack_from("<64I", b, 0)
    nz = [x for x in e if x not in (0, 0xFFFFFFFF)]
    print("%s size=0x%X SP=0x%08X RESET=0x%08X min/max muc != 0/FF: 0x%08X/0x%08X config=0x%X" % (n, len(b), e[0], e[1], min(nz[1:]), max(nz[1:]), cfgaddr(n)))
bad = 0
for n in FILES:
    b = open(R+FILES[n],"rb").read(); truth = cfgaddr(n)
    for board in ("octopus","ebb36","auto"):
        row = []
        for off in (0, 0x2000, 0x20000):
            if board == "octopus" and off == 0x2000: continue
            if board == "ebb36" and off == 0x20000: continue
            rc,out = run(["--board",board,"--app","0x%X"%off,R+FILES[n]])
            got = [l for l in out.splitlines() if l.startswith("KET LUAN APP")][0].split()[-1].replace("APP_OFFSET_","")
            exp = predict(b, off, board)
            flag = "" if got == exp else " <<LECH exp=%s" % exp; bad += (got != exp)
            row.append("0x%X:%s(rc%d)%s" % (off, got, rc, flag))
        print("%-16s truth=0x%-6X board=%-8s %s" % (n, truth, board, "  ".join(row)))
print("so lech voi du doan doc lap:", bad)
print("=== (4) cat cut")
b = open(R+FILES["octopus_off128k"],"rb").read()
for cut in (16, 64, 4096, 0x7000, 0x7C00, 0x8000, 0x9000, len(b)):
    p = T+"t5_trunc_%x.bin" % cut; open(p,"wb").write(b[:cut])
    rc,out = run(["--board","octopus","--app","0x20000",p])
    print("cut=0x%X -> %s rc=%d" % (cut, [l for l in out.splitlines() if l.startswith("KET LUAN APP")], rc))
print("RESET that cua octopus_off128k = 0x%08X" % struct.unpack_from("<I", b, 4))
