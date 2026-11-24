import os, struct, subprocess
D = "/mnt/d/WORK/3D-Printer-Klipper/tests/tmp/dump"
S = "/mnt/d/WORK/3D-Printer-Klipper/docs-internal/tools/dump-inspect.py"
B = 0x08000000
def img(n=0x100000): return bytearray(b"\xff" * n)
def vec(a, off, rel, sp=0x24080000):
    rv = B + rel; struct.pack_into("<4I", a, off, sp, rv|1, (rv+2)|1, (rv+4)|1)
def word(a, idx, v): struct.pack_into("<I", a, idx*4, v)
def code(a, off, n): a[off:off+n] = bytes(((i*7+3) & 0xFF) for i in range(n))
def txt(a, off, s): a[off:off+len(s)] = s.encode()
T = []
# (a) Katapult hop le, mot so o FF (mac dinh) va mot so o hop le
a = img(0x80000); vec(a,0,0x100); word(a,4,B+0x300|1); word(a,5,B+0x302|1); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); txt(a,0x2400,"Klipper")
T.append(("a1_ebb36_o_FF_va_hop_le", a, ["--board","ebb36"], "BOOTLOADER_8K"))
a = img(); vec(a,0,0x200); word(a,4,B+0x300|1); code(a,0x40,0x700); txt(a,0x800,"Katapult"); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("a2_octopus_o_FF_va_hop_le", a, ["--board","octopus"], "BOOTLOADER_128K"))
# (b) mot o tro vao vung >= ung vien
a = img(0x80000); vec(a,0,0x100); word(a,7,(B+0x2200)|1); code(a,0x40,0x300); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); txt(a,0x2400,"Klipper")
T.append(("b1_ebb36_o_tro_vao_vung_app", a, ["--board","ebb36"], "UNKNOWN"))
a = img(); vec(a,0,0x200); word(a,7,(B+0x20200)|1); code(a,0x40,0x700); txt(a,0x800,"Katapult"); vec(a,0x20000,0x20100); code(a,0x20040,0x600); txt(a,0x20400,"Klipper")
T.append(("b2_octopus_o_tro_vao_vung_app", a, ["--board","octopus"], "UNKNOWN"))
# (c) Katapult 8K lap kin den sat 0x2000
a = img(0x80000); vec(a,0,0x100); code(a,0x40,0x2000-0x40); txt(a,0x400,"Katapult"); vec(a,0x2000,0x2100); code(a,0x2040,0x300); txt(a,0x2400,"Klipper")
T.append(("c_ebb36_kat8K_lap_kin", a, ["--board","ebb36"], "UNKNOWN (dung oan)"))
# (d) anh danh lua: app chay tu 0, "katapult" o phan dau, handler duoi ung vien, FF du dai sat truoc ung vien, 16 byte giong vector, klipper sau
a = img(0x80000); vec(a,0,0x100); code(a,0x40,0xFC0); txt(a,0x400,"katapult"); vec(a,0x2000,0x2100); txt(a,0x3000,"klipper")
T.append(("d1_danh_lua_ebb36", a, ["--board","ebb36"], "UNKNOWN (neu BOOTLOADER_8K = sai tu tin)"))
a = img(); vec(a,0,0x100); code(a,0x40,0x1EFC0); txt(a,0x400,"katapult"); vec(a,0x20000,0x20100); txt(a,0x20400,"klipper")
T.append(("d2_danh_lua_octopus", a, ["--board","octopus"], "UNKNOWN (neu BOOTLOADER_128K = sai tu tin)"))
T.append(("d1b_danh_lua_ebb36_auto", a, [], "UNKNOWN (neu BOOTLOADER_128K = sai tu tin)"))
def run(args):
    r = subprocess.run(["python3","-I",S]+args, capture_output=True, text=True); return r.returncode, r.stdout
os.makedirs(D, exist_ok=True)
for n,a,args,exp in T:
    p = D+"/t4_"+n.split()[0]+".bin"; open(p,"wb").write(bytes(a))
    rc,out = run([p]+args)
    print("%-34s exp=%-42s got=%s rc=%d" % (n,exp,[l for l in out.splitlines() if l.startswith("KET LUAN")],rc))
