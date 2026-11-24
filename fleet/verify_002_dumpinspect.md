# verify_002: kiem doc lap dump-inspect.py

Chay: `wsl -d Ubuntu-24.04 -- python3 -I /mnt/d/WORK/3D-Printer-Klipper/tests/tmp/dump/t_harness.py` (Python 3.12, WSL). Ky vong ghi san trong t_harness.py truoc khi chay.

- `--help`: KHONG co, bi coi la ten file -> FileNotFoundError, rc=1 (dump-inspect.py:217).
- `--selftest`: 8 ca OK + "kiem --app: OK", "TU KIEM: DAT", rc=0.
- 3 anh san co: app0_nho=NO_BOOTLOADER, bootloader128K_cong_app=BOOTLOADER_128K, toan_FF=EMPTY, rc=0; bam SHA256 truoc/sau khong doi (cung voi moi file t_*, hash_giu=True).
- Moi lan chay dump in dung 1 dong `KET LUAN:`.

## Bang ca (dump)
| Ca | Ky vong | Ket qua | |
|---|---|---|---|
| c1 app0 nho + klipper | NO_BOOTLOADER | NO_BOOTLOADER | DAT |
| c2 app0 >128K, vector gia @0x20000 | UNKNOWN | BOOTLOADER_128K | KHONG DAT |
| c2b app0 >8K, vector gia @0x2000 | UNKNOWN | BOOTLOADER_8K | KHONG DAT |
| c3 Katapult128K+kalico | BOOTLOADER_128K | BOOTLOADER_128K | DAT |
| c4 Katapult8K+app@0x2000 | BOOTLOADER_8K | BOOTLOADER_8K | DAT |
| c5 chi bootloader | ONLY_NO_APP | ONLY_NO_APP | DAT |
| c6 FF / 00 / rong | EMPTY | EMPTY (ca 3) | DAT |
| c6 3 byte, 7 byte | UNKNOWN | UNKNOWN | DAT |
| c6f chi 4 KiB, app tai 0 | UNKNOWN | NO_BOOTLOADER | KHONG DAT |
| c6g 128 KiB dung, chi boot | UNKNOWN/ONLY | ONLY_NO_APP | DAT (nho) |
| c7a reset chan, c7b/c7c reset ngoai flash, c7d SP trong flash | UNKNOWN | UNKNOWN (4) | DAT |
| c8 EBB36 khong chuoi, co vector @0x2000 | UNKNOWN (ky vong cua toi sai) | BOOTLOADER_8K | DAT: ket luan theo cau truc, hop ly; khong co vector -> UNKNOWN (selftest app0_khong_chuoi) |
| c9a "katapult" chi trong vung app, khong klipper | UNKNOWN | BOOTLOADER_ONLY_NO_APP | KHONG DAT |
| c9b katapult + klipper, vector chi @0 | UNKNOWN | UNKNOWN | DAT |
| c9c klipper UTF-16 | NO_BOOTLOADER | NO_BOOTLOADER | DAT |

## --app
Dung offset: DAT. Sai offset: file 16 KiB bao MISMATCH dung. File >128 KiB build cho 0x20000 kiem `--app 0x0` -> APP_OFFSET_OK (SAI); file 0x2000 kiem `--app 0x0` -> OK (SAI, ca file 16 KiB); file >128K build 0x20000 kiem `--app 0x2000` -> OK (SAI). Nguyen nhan dump-inspect.py:124-125: chi kiem reset nam trong [lo, lo+len(file)), khong kiem reset >= lo + 0 voi can tren hep.

## Ma thoat
Dump mode luon rc=0 ke ca UNKNOWN (dump-inspect.py:218-219). `--app` MISMATCH rc=1 trung rc=1 cua traceback (thieu doi so, offset xau, file khong ton tai: IndexError/ValueError/FileNotFoundError).

---
# Luot 2 (script viet lai)
Harness: tests\dump\t_harness.py (ban sao nguyen van, SHA256 71B878D1...C9C3, trung ban goc) va tests\dump\t_harness2.py (ca moi). Chay: `wsl -d Ubuntu-24.04 -- python3 -I /mnt/d/WORK/3D-Printer-Klipper/tests/dump/t_harness2.py` (tuong tu t_harness.py). File anh ghi vao tests\tmp\dump\ (t_*, t2_*).
- `--selftest`: 20 ca dump OK + 18 to hop --app OK, "TU KIEM: DAT", rc=0.
- t_harness.py: 22 ca dump (rc 0/2/3 dung), 16 --app (rc 0/4), 6 ca loi (rc 1, --selftest 0): moi ca dung ky vong, ke ca c2, c2b, c6f, c9a; c8=UNKNOWN. Hash dau vao khong doi.
- --help rc=0; file khong ton tai rc=1; --board zzz rc=1; thieu doi so rc=1; EMPTY rc=3; UNKNOWN rc=2.

## Ca moi (ky vong ghi truoc trong t_harness2.py)
| Ca | Ky vong | Ket qua |
|---|---|---|
| a1 app lon, vector gia @0x20000, FF 4K truoc do, "klipper"@0x400 | UNKNOWN | UNKNOWN |
| a2 nhu a1, "klipper"@0x25000 | UNKNOWN | BOOTLOADER_128K (SAI, nguy hiem) |
| b1 / b2 tuong tu cho ebb36 @0x2000 (chuoi @0x400 / @0x3000) | UNKNOWN | UNKNOWN / BOOTLOADER_8K (SAI) |
| c bootloader hang 128K khong chuoi, ket thuc FF, app klipper | BOOTLOADER_128K | dung |
| d hang lap day khong FF + app | UNKNOWN | UNKNOWN |
| e1 Katapult 8K + zlib that (ebb36 va auto) | BOOTLOADER_8K | dung |
| e2 78 9c ngau nhien; e3 zlib hop le khong phai dict | UNKNOWN | UNKNOWN |
| f1/f2/f3 sai --board | UNKNOWN | UNKNOWN (khong tu tin sai); f4 app0 --board ebb36 NO_BOOTLOADER dung |
| g auto: a2, b2 | UNKNOWN | BOOTLOADER_128K / BOOTLOADER_8K (SAI); c dung; d UNKNOWN |
| j hang lap day, app co chuoi nhung NMI ngoai flash | UNKNOWN | NO_BOOTLOADER (SAI) |
| h --app RESET lo+0x0FFC / 0x1000 / 0x3000 (file 16K) | | OK / MISMATCH / MISMATCH; lo+0x100 OK; file 0x800 thi cua so thu hep theo do dai |
Lan 0x1000 tu choi: moi build co reset handler xa hon 4 KiB dau (chua biet that).

## Loi
Nghiem trong (contrived, can app co vector gia + FF >=4K sat truoc + chuoi app o sau): analyse :124-134 va :145 (gap + app_ev chi can chuoi o bat ky dau >= c; vector 16 byte la bang con tro gia van duoc chap nhan); :147-160 NO_BOOTLOADER khong yeu cau vector app o ung vien phai hop le khi du lieu lien tuc (ca j).
Quan trong: khong co. Nho: gioi han 0x1000 chua kiem chung.

---
# Luot 3 (sau sua luot 4: bo bang chung khoang FF, them looks_like_vec)
Chay tu tests\dump\: t_harness.py (21 ca dump + 16 --app + 6 ca loi: tat ca dung ky vong, rc 0/2/3/4/1), t_harness2.py (20 ca: dung het sau khi doi ky vong c va g_c tu BOOTLOADER_128K sang UNKNOWN: theo quyet dinh thiet ke khoang FF khong con la bang chung, bootloader hang khong chuoi -> UNKNOWN), t_harness3.py (ca moi). `--selftest`: 40 OK, 0 SAI + 18 to hop --app OK, rc=0. a2, b2, g_a2, g_b2, j nay deu UNKNOWN.

| Ca moi | Ky vong | Ket qua |
|---|---|---|
| a1/a2 Katapult that, chuoi katapult lap lai trong vung app (128K, 8K) | BOOTLOADER_* | dung |
| b1 app lon, "canboot" @0x500, vector gia @0x2000, klipper @0x3000 (ebb36) | UNKNOWN | BOOTLOADER_8K (SAI tu tin) |
| b2 nhu b1 cho 0x20000 (octopus) | UNKNOWN | BOOTLOADER_128K (SAI tu tin) |
| c hai ung vien hop le, auto | UNKNOWN | UNKNOWN |
| d RESET@0 >= ung vien | UNKNOWN | UNKNOWN |
| e1/e2 app nho / lon hop le | NO_BOOTLOADER | dung |
| f1/f2 8 byte SP+RESET tinh co o ung vien | UNKNOWN | UNKNOWN |
| g ONLY_NO_APP auto/octopus/ebb36 | ONLY_NO_APP | dung; ly do liet ke ung vien da kiem (auto: 0x2000, 0x20000) |

Duong sai con lai: dump-inspect.py:131-151 (can chuoi katapult/canboot trong vung dau + vector gia + chuoi app sau). Firmware Klipper that co chua chuoi do khong: CHUA BIET (repo khong co ma nguon Klipper; chua kiem). f: xac suat tinh co thô theo du lieu ngau nhien ~ (1/8)*(1/2)*(1/1024) ~ 6e-5 moi vi tri; ma Thumb that chua do.

---
# Luot 4 (xac nhan lan cuoi)
selftest 46 OK + 18 --app, rc=0. t_harness.py 21/21 dump + 16/16 --app + 6/6 loi; t_harness2.py 20/20; t_harness3.py 14/14. Ba harness khong bi sua (t_harness.py SHA256 71B878D151E5 nhu cu; harness2/3 mtime 00:41 = lan ghi cuoi cua toi). Ca moi trong t_harness4.py:
- a (o vector FF/hop le, ebb36 + octopus): BOOTLOADER_8K / BOOTLOADER_128K, dung.
- b (mot o tro vao vung >= ung vien, 2 bo): UNKNOWN, dung.
- c (Katapult 8K lap kin den 0x2000): UNKNOWN (dung oan, ghi nhan).
- d (anh danh lua: app chay tu 0, "katapult" o dau, FF sat truoc ung vien, 16 byte vector, klipper sau): ebb36 -> BOOTLOADER_8K, octopus -> BOOTLOADER_128K (SAI tu tin, rui ro con lai da biet; d1b: anh octopus voi --board auto cung BOOTLOADER_128K).
Danh gia: firmware Klipper that dong thoi co chuoi katapult o phan dau, FF >= 4 KiB lien truoc 0x20000 (hoac >=16 byte truoc 0x2000), dung 16 byte giong vector o ung vien, chuoi klipper sau: kho xay ra tinh co (bon dac diem doc lap); khong the khang dinh chua tung gap vi chua kiem firmware that.
