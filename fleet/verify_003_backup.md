# verify_003_backup (003:T003)

Ngay 2026-11-24, test-engineer. Chi doc `%APPDATA%\OrcaSlicer\user`.

## (1) SHA256 ban sao luu vs thu muc that
Lenh: Get-FileHash SHA256 tung file cua `profiles\orca_backup\2026-11-24\` (tru `manifest.sha256`) va `%APPDATA%\OrcaSlicer\user`, khop theo duong dan tuong doi.
Ket qua: that = 66 file, sao luu = 66 file (67 gom manifest), 0 lech, 0 thieu, 0 thua. DAT.
Bang bam luc dau/cuoi phien: `tests\tmp\v003\user_before.txt`, `user_final.txt`, cung SHA256 0A0121E4...D3411.

## (2) Dem old_inventory.csv vs thu muc that (de quy, gom filament\base\)
Thu muc that: machine 6 .json, filament 25 .json, process 1 .json (moi file co .info). CSV: may=6, vat_lieu=25, quy_trinh=1. Duong dan trong CSV trung 100% voi file that (0 thieu, 0 thua). DAT.
Chay lai `inventory-old.ps1 -OutCsv tests\tmp\v003\inv_rerun.csv`: file giong het `profiles\old_inventory.csv` (cung hash). DAT.
Ghi chu Nho: script danh dau "ngoai pham vi" 12 ho so, gom ca ASA, PETG-CF, P1P, R3D, rong hon danh sach cua T002 (TPU, ASA-CF, SUNLU, HUTI).
