# Kiem chung 001:T004 (T001 + T003) - 2026-11-24

Vai: test-engineer. Chay that tren PC; chi GET toi Moonraker, nghe SSDP thu dong. Khong in serial, ma truy cap, user_id.

## (1) Sao luu Orca: DAT
- Bang sao: 67 file = 66 file nguon + manifest.sha256. Nguon: 66 file.
- So SHA256 nguon vs ban sao (Get-FileHash, tung file): 0 lech; thieu o ban sao: 0; thua o ban sao: 0.
- So voi manifest.sha256 (66 dong, doc UTF-8): 0 lech, 0 thieu khoa.
- Dem json de quy trong ban sao: machine=6, filament=25 (24 + 1 trong filament\base), process=1. Nguon cung 6/25/1.
- Luu y: manifest la UTF-8 khong BOM; Get-Content mac dinh cua PS 5.1 doc sai 4 ten file co ky tu toan rong (vd dau ngoac rong); doc bang -Encoding UTF8 thi khop 66/66.

## (2) Cam ghi / bi mat: DAT (kem 1 nhan xet)
- Mau `-Method\s+(Post|Put|Delete)`, `PUBLISH`, `gcode/script`, `Write-Host|Write-Output` trong Fleet.psm1 va backup-orca.ps1: 0 dong.
- Mau serial/access_code/user_id: 4 dong, deu la chu thich (Fleet.psm1:3,92,119; backup-orca.ps1:3). Khong co in ra.
- Invoke-MoonrakerGet toi 127.0.0.1: `/printer/gcode/script` va `/printer/emergency_stop` bi tu choi truoc khi gui ("Path not allowed"). Duong dan hop le thi moi gui (het gio vi khong co gi nghe cong 80).
- Nhan xet: Fleet.psm1:25 la regex tien to, khong chan `..` va chuoi query. .NET Uri chuan hoa `/server/files/../printer/gcode/script` thanh `/server/printer/gcode/script` (da do), nen khong toi duoc gcode/script.

## (3) Moonraker that: DAT
| May | /printer/info state | print_stats.state (GET rieng) | Test-PrinterIdle |
|---|---|---|---|
| 192.0.2.90 Trident | ready | paused | False |
| 192.0.2.89 V2.4 | ready | printing | False |
2/2 may bao state; ca hai dung "khong ranh". Truong `klippy_state` khong ton tai trong /printer/info, truong tuong ung la `state`.
Chua kiem: nhanh tra True (may standby), vi khong may nao ranh.

## (4) SSDP 15 giay: DAT
Do 15 s, thay 4 may: .122 model N2S fw 01.09.00.00; .149 N1 01.09.00.00; .199 C12 01.10.00.00; .61 O1S 01.03.00.00; Connect = cloud ca bon. Doi tuong tra ve chi co Model, Name, Version, Connect, Ip. So khop chuoi 15 ky tu chu-so tren JSON ket qua: False (khong co serial).

## (5) Secrets va data-formats: DAT
- secrets\bambu.local.json: khoa H2S, P1S, A1, A1M, moi khoa co ip, access_code, serial; tat ca rong (len=0).
- docs\data-formats.md: du 3 bang, cot khop plan.md "Thiet ke chung": bang 1 = 13 cot, bang 2 = 10 cot, bang 3 = 9 cot.

## Loi
- Nghiem trong: khong.
- Quan trong: khong.
- Nho: Fleet.psm1:25 regex allowlist khong neo cuoi, khong cam `..`/`?`; Fleet.psm1:117 Model la ma noi bo (N2S/N1/C12/O1S), chua anh xa ra H2S/A1/A1M/P1S.
