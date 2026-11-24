# verify_003_build (003:T011)

Ngay 2026-11-24, test-engineer. Cong cu kiem: `tests\tmp\v003\check_profiles.ps1`, `check_values.ps1`, `compare_structure.ps1`, `check_stl.ps1`, thu muc `agg\`.

## (2) build-profiles
- `-Set pilot -OutDir tests\tmp\v003\pilot`: 18 file (6/6/6), `-Verify` lech=0. `-Set all`: 34 file (6/6/22), `-Verify` lech=0.
- check_profiles.ps1 doc lap: ten dung quy uoc; `compatible_printers` 1 ten, ton tai trong bo va dung may; khong setting_id/user_id/base_id; khong .info; Bambu khong co PA, TRI/V24 co enable_pressure_advance + pressure_advance; G-code dau 2 Voron khong co SKEW_PROFILE, cuoi co `SET_SKEW CLEAR=1`. 0 loi (pilot va all).
- inherits: tim dang `<loai>/[thu muc con/]<ten>.json` trong chuoi chu cua `%APPDATA%\OrcaSlicer\system\*.opc`; thu muc `resources\profiles` cua Orca khong co JSON may/quy trinh nen khong dung duoc. Du 18/18 (pilot) va 34/34 (all). Vi du `PolyLite ABS @System` nam o `filament/Polymaker/`.
- check_values.ps1: 6 PLA, 52 phep so sanh voi `materials.csv`, 0 lech. Ca 22 vat lieu: 230 phep, 0 lech.
- Doi chung am: ban sao hong (inherits sai, mat compatible_printers, them PA vao Bambu, them setting_id, doi SET_SKEW, them .info, doi flow) -> checker bat 11 loi, check_values 5 loi, `-Verify` lech=11 va exit 1.

## (3) all
34 file; ABS cho A1/A1 Mini = 0 (ABS chi o H2S, P1S, 2 Voron); 22 ten vat lieu khac nhau; 34 ten khac nhau. DAT.

## (4) Cau truc vs ho so cu
Ho so may: khoa, kieu, so phan tu giong het ban cu (sao nguyen). H2S printer_extruder_variant = 3 phan tu, vat lieu H2S co mang 3 phan tu. P1S ho so may cu co 2 bien the (Standard, High Flow), nhung machines.csv ghi 1 bien the nen vat lieu P1S chi 1 phan tu (giong ho so vat lieu P1S cu). Orca co chap nhan lech nay khong: CHUA KIEM. Khac biet khac: them `compatible_printers`; Trident ABS them `pressure_advance`; bo `default_filament_colour`, `filament_vendor` (2 ABS Voron) va `activate_air_filtration`, `complete_print_exhaust_fan_speed` (PETG-ECO H2S).

## (5) -Install/-Uninstall
CHUA THU: script chi nhan -UserId, khong co tham so thu muc dich, nen khong chay duoc tren ban sao ma khong cham `%APPDATA%`. Thu doi bien APPDATA bi he thong chan, khong lam tiep. Doc ma: Install chay Verify, Assert-OrcaClosed (ten tien trinh `orca-slicer`/`OrcaSlicer`), tu choi ghi de file ton tai (tru ten "DHH " kem -Force), chi chep `.json` trong ke hoach; Uninstall chi xoa `DHH *.json/.info` muc tren cung 3 thu muc. Chua chay thu.

## (6) STL (chay `make-cal-models.ps1 -OutDir tests\tmp\v003\models`; ba file giong het bang trong `models\`)
- (a) bbox 100.000 x 100.000 x 20.000, 48 tam giac, canh khong thuoc dung 2 tam giac = 0, the tich 18497.55 mm3 (tinh tay 18497.6).
- (b) 90 x 58.9 x 10, 1068 tam giac, 0 canh loi. Lo tron: 128 dinh, duong kinh dinh-dinh 8.0000, canh-canh 7.9977; chot tron 7.8000 / 7.7977; lo vuong 8.000 x 8.000; chot vuong 7.800 x 7.800.
- (c) 56.581 x 20 x 40, 36 tam giac, 0 canh loi.
- Xoa tam giac thu 10 trong ban sao: 3 canh loi o ca 3 file, bat duoc.

## (7) aggregate.ps1
5 phieu trong `tests\tmp\v003\agg\entry\part` (dat, khong dat X, dung bien dung sai 0.10/0.10/0.10/0.15, X 100.11, vong 2). Ket qua khop bang tay 5/5 hang. Ban sao hong 3 kieu -> 1, 1, 5 hang lech.

## (8) Orca CLI
`OrcaSlicer.dll` chua chuoi "OrcaSlicer 2.5.2" va "release/v2.5.2", file `OrcaSlicer.conf` ghi 2.5.1 (cu, ghi lan chay truoc). `orca-slicer.exe --help` thoat 0 nhung khong lay duoc dong chu nao qua redirect. Bam `user` va kich thuoc/gio sua toan bo `%APPDATA%\OrcaSlicer` truoc/sau khong doi. CHUA THU cat lop. Ket luan "CLI dung duoc": chua co.
