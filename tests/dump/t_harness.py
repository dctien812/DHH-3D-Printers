import hashlib, os, struct, subprocess, sys
D = "/mnt/d/WORK/3D-Printer-Klipper/tests/tmp/dump"
S = "/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py"
B = 0x08000000
def img(n=0x100000): return bytearray(b"\xff" * n)
def vec(a, off, rel, sp=0x24080000, odd=True, absolute=None):
    rv = absolute if absolute is not None else B + rel
    if odd and absolute is None: rv |= 1
    struct.pack_into("<4I", a, off, sp, rv, (B + rel + 2) | 1, (B + rel + 4) | 1)
def code(a, off, n): a[off:off+n] = bytes(((i*7+3) & 0xFF) for i in range(n))
def txt(a, off, s): a[off:off+len(s)] = s.encode()
C = {}  # name -> (bytes, expected, note)
a = img(); vec(a,0,0x100); code(a,0x40,0x600); txt(a,0x400,"Klipper"); C["c1_app0_nho"] = (a,"NO_BOOTLOADER","")
a = img(); code(a,0x40,0x30000); txt(a,0x400,"klipper"); vec(a,0,0x100); vec(a,0x20000,0x20100)  # fake vector mid-code
C["c2_app0_lon_vector_gia_0x20000"] = (a,"UNKNOWN (khong duoc BOOTLOADER_128K)","")
a = img(); code(a,0x40,0x30000); txt(a,0x400,"klipper"); vec(a,0,0x100); vec(a,0x2000,0x2100)
C["c2b_app0_lon_vector_gia_0x2000"] = (a,"UNKNOWN (khong duoc BOOTLOADER_8K)","")
a = img(); vec(a,0,0x200); code(a,0x40,0x700); txt(a,0x800,"Katapult"); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"kalico")
C["c3_kat128K_kalico"] = (a,"BOOTLOADER_128K","")
a = img(0x80000); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x600); txt(a,0x2400,"Klipper")
C["c4_ebb36_kat8K"] = (a,"BOOTLOADER_8K","")
a = img(); vec(a,0,0x200); code(a,0x40,0x700); txt(a,0x800,"Katapult")
C["c5_chi_bootloader128K"] = (a,"BOOTLOADER_ONLY_NO_APP","")
C["c6a_toan_FF"] = (img(),"EMPTY","")
C["c6b_toan_00"] = (bytearray(0x100000),"EMPTY","")
C["c6c_rong"] = (bytearray(),"EMPTY hoac UNKNOWN (khong NO_/BOOTLOADER_)","")
C["c6d_3byte"] = (bytearray(b"\x01\x02\x03"),"UNKNOWN","")
C["c6e_7byte_FF_00"] = (bytearray(b"\xff\x00\xff\x00\xff\x00\xff"),"UNKNOWN","")
a = bytearray(0x1000); a[:] = b"\xff"*0x1000; vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Klipper")
C["c6f_chi_4KiB_ung_dung"] = (a,"UNKNOWN (dump cut khong thay 0x2000/0x20000)","")
a = img(0x20000); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult");
C["c6g_dump_dung_128KiB_chi_boot"] = (a,"UNKNOWN hoac ONLY_NO_APP (khong thay vung app)","")
a = img(); vec(a,0,0x100,odd=False); code(a,0x40,0x300); txt(a,0x400,"klipper")
C["c7a_reset_chan"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100,absolute=0x20001001); code(a,0x40,0x300); txt(a,0x400,"klipper")
C["c7b_reset_ngoai_flash_RAM"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100,absolute=0x08500001); code(a,0x40,0x300); txt(a,0x400,"klipper")
C["c7c_reset_ngoai_flash_0x08500001"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100,sp=0x08001000); code(a,0x40,0x300); txt(a,0x400,"klipper")
C["c7d_sp_trong_flash"] = (a,"UNKNOWN","")
a = img(0x80000); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100,sp=0x20004000); code(a,0x2040,0x600)
C["c8_ebb36_CAN_only_khong_chuoi"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"app"); txt(a,0x5000,"katapult")
C["c9a_katapult_chi_o_vung_app_khong_klipper"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"klipper"); txt(a,0x5000,"katapult")
C["c9b_katapult_o_vung_app_co_klipper"] = (a,"UNKNOWN","")
a = img(); vec(a,0,0x100); code(a,0x40,0x300); txt(a,0x400,"k\0l\0i\0p\0p\0e\0r\0")
C["c9c_klipper_utf16"] = (a,"NO_BOOTLOADER","")
os.makedirs(D, exist_ok=True)
def sh(p):
    return hashlib.sha256(open(p,"rb").read()).hexdigest()[:12]
def run(args):
    r = subprocess.run(["python3","-I",S]+args, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr
print("=== DUMP MODE")
for n,(a,exp,_) in C.items():
    p = D+"/t_"+n+".bin"
    open(p,"wb").write(bytes(a)); h1 = sh(p)
    rc,out,err = run([p])
    kl = [l for l in out.splitlines() if l.startswith("KET LUAN")]
    verdict = kl[-1] if kl else ("(khong co) "+err.strip().splitlines()[-1:][0] if err.strip() else "(khong co)")
    print("%-45s exp=%-45s got=[%s] n_dong=%d rc=%d hash_giu=%s" % (n,exp,verdict,len(kl),rc,sh(p)==h1))
print("=== APP MODE")
def appf(name, size, reloff, sp=0x24080000):
    a = img(size); struct.pack_into("<4I", a, 0, sp, B+reloff+0x101, B+reloff+0x103, B+reloff+0x105); code(a,0x40,min(0x300,size-0x40))
    p = D+"/t_"+name+".bin"; open(p,"wb").write(bytes(a)); return p
tests = []
for sz in (0x4000, 0x30000):
    p128 = appf("app128_%x"%sz, sz, 0x20000); p0 = appf("app0_%x"%sz, sz, 0)
    p8 = appf("app8k_%x"%sz, sz, 0x2000)
    for f,off,exp in ((p128,"0x20000","OK"),(p128,"0x0","MISMATCH"),(p0,"0x0","OK"),(p0,"0x20000","MISMATCH"),(p8,"0x2000","OK"),(p8,"0x0","MISMATCH"),(p8,"0x20000","MISMATCH"),(p128,"0x2000","MISMATCH")):
        rc,out,err = run(["--app",off,f])
        kl = [l for l in out.splitlines() if l.startswith("KET LUAN")]
        print("%-22s --app %-8s exp=%-8s got=%s rc=%d" % (os.path.basename(f),off,exp,kl,rc))
print("=== LOI DAU VAO / EXIT")
for args in (["/nonexistent"],["--app"],["--app","0x0"],["--app","zz",D+"/t_c1_app0_nho.bin"],[],["--selftest"]):
    rc,out,err = run(args)
    print(args, "rc=",rc, "| stderr cuoi:", (err.strip().splitlines() or [""])[-1], "| stdout dong cuoi:", (out.strip().splitlines() or [""])[-1])
