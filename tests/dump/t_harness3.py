import os, struct, subprocess
D = "/mnt/d/WORK/3D-Printer-Klipper/tests/tmp/dump"
S = "/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py"
B = 0x08000000
def img(n=0x100000): return bytearray(b"\xff" * n)
def vec(a, off, rel, sp=0x24080000):
    rv = B + rel; struct.pack_into("<4I", a, off, sp, rv|1, (rv+2)|1, (rv+4)|1)
def code(a, off, n): a[off:off+n] = bytes(((i*7+3) & 0xFF) for i in range(n))
def txt(a, off, s): a[off:off+len(s)] = s.encode()
T = []
# (a) katapult lap lai trong vung app
a = img(); vec(a,0,0x200); code(a,0x40,0x700); txt(a,0x800,"Katapult"); vec(a,0x20000,0x20100); code(a,0x20040,0x2000); txt(a,0x20400,"Klipper"); txt(a,0x21000,"katapult")
T.append(("a1_octopus_kat_lap_lai_trong_app", a, [], "BOOTLOADER_128K"))
a = img(0x80000); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x2000); txt(a,0x2400,"Klipper"); txt(a,0x3000,"katapult")
T.append(("a2_ebb36_kat_lap_lai_trong_app", a, ["--board","ebb36"], "BOOTLOADER_8K"))
# (b) app lon khong boot, co chuoi canboot trong vung dau + vector gia + klipper sau
a = img(0x80000); code(a,0x40,0x30000); vec(a,0,0x100); vec(a,0x2000,0x2100); txt(a,0x500,"canboot"); txt(a,0x3000,"klipper")
T.append(("b1_app_lon_canboot_dau+vecgia@0x2000 ebb36", a, ["--board","ebb36"], "UNKNOWN (neu BOOTLOADER_8K = tu tin sai)"))
a = img(); code(a,0x40,0x30000); vec(a,0,0x100); vec(a,0x20000,0x20100); txt(a,0x500,"canboot"); txt(a,0x25000,"klipper")
T.append(("b2_app_lon_canboot_dau+vecgia@0x20000 octopus", a, ["--board","octopus"], "UNKNOWN (neu BOOTLOADER_128K = tu tin sai)"))
# (c) hai ung vien deu hop le, auto
a = img(); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); vec(a,0x20000,0x20100); txt(a,0x20400,"Klipper")
T.append(("c_hai_ung_vien_hop_le auto", a, [], "UNKNOWN"))
# (d) RESET @0 tro vao vung >= ung vien
a = img(0x80000); vec(a,0,0x2100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); txt(a,0x2400,"Klipper")
T.append(("d_reset0_trong_vung_app ebb36", a, ["--board","ebb36"], "UNKNOWN"))
# (e) NO_BOOTLOADER hop le
a = img(); vec(a,0,0x100); code(a,0x40,0x600); txt(a,0x400,"Klipper")
T.append(("e1_app_nho auto", a, [], "NO_BOOTLOADER"))
a = img(); code(a,0x40,0x30000); txt(a,0x400,"klipper"); vec(a,0,0x100)
T.append(("e2_app_lon auto", a, [], "NO_BOOTLOADER"))
# (f) app khong boot, 8 byte SP+RESET tinh co o ung vien, NMI rac
a = img(); code(a,0x40,0x30000); txt(a,0x400,"klipper"); vec(a,0,0x100)
struct.pack_into("<4I", a, 0x2000, 0x24080000, B+0x4001, 0xDEADBEEF, 0xDEADBEEF)
T.append(("f1_app_8byte_SP_RESET_tai_0x2000 auto", a, [], "UNKNOWN"))
a = img(); code(a,0x40,0x30000); txt(a,0x400,"klipper"); vec(a,0,0x100)
struct.pack_into("<4I", a, 0x20000, 0x24080000, B+0x4001, 0xDEADBEEF, 0xDEADBEEF)
T.append(("f2_app_8byte_SP_RESET_tai_0x20000 octopus", a, ["--board","octopus"], "UNKNOWN"))
# (g) chi bootloader
a = img(); vec(a,0,0x200); code(a,0x40,0x700); txt(a,0x800,"Katapult")
for bd in ("auto","octopus","ebb36"):
    T.append(("g_chi_boot_board_%s" % bd, a, ["--board",bd], "BOOTLOADER_ONLY_NO_APP"))
def run(args):
    r = subprocess.run(["python3","-I",S]+args, capture_output=True, text=True); return r.returncode, r.stdout
os.makedirs(D, exist_ok=True)
for n,a,args,exp in T:
    p = D+"/t3_"+n.split()[0]+".bin"; open(p,"wb").write(bytes(a))
    rc,out = run([p]+args)
    kl = [l for l in out.splitlines() if l.startswith("KET LUAN")]
    print("%-50s exp=%-42s got=%s rc=%d" % (n,exp,kl,rc))
    if n.startswith("g_"):
        print("\n".join(out.splitlines()[-6:-1]))
