# Quy ước tên hồ sơ OrcaSlicer (tiền tố DHH)

Nguồn quy ước: người dùng chốt, ghi ở `specs\003-orca-profiles\tasks.md`. Mọi hồ sơ do `scripts\orca\build-profiles.ps1`
sinh từ `profiles\src\*.csv`; không sửa tay file trong `profiles\bundle\`.

## Ba dạng tên

| Loại | Dạng | Ví dụ |
|---|---|---|
| Máy | `DHH <Máy> 0.4` | `DHH Voron Trident 250 0.4`, `DHH A1 Mini 0.4` |
| Vật liệu | `DHH <Hãng> <Loại> @<Máy>` | `DHH Tinmorry ABS Pro @P1S` |
| Quy trình | `DHH 0.20 Sync @<Máy>` | `DHH 0.20 Sync @H2S` |

`<Máy>` (cột `tên_ngắn` trong `profiles\src\machines.csv`):

| Mã | `<Máy>` | Hồ sơ hệ thống làm cha |
|---|---|---|
| TRI | Voron Trident 250 | Voron Trident 250 0.4 nozzle |
| V24 | Voron 2.4 300 | Voron 2.4 300 0.4 nozzle |
| H2S | H2S | Bambu Lab H2S 0.4 nozzle |
| P1S | P1S | Bambu Lab P1S 0.4 nozzle |
| A1 | A1 | Bambu Lab A1 0.4 nozzle |
| A1M | A1 Mini | Bambu Lab A1 mini 0.4 nozzle |

Đầu phun luôn 0,4. Tiền tố `DHH ` (có dấu cách) là dấu hiệu duy nhất để `-Install` và `-Uninstall` biết file nào của bộ này.

## Nhựa và cặp hợp lệ

| Mã nhựa | `<Hãng> <Loại>` | Máy hợp lệ |
|---|---|---|
| BAMBU-PLA | Bambu PLA | cả 6 |
| BAMBU-PETG | Bambu PETG | cả 6 |
| TIN-PETGECO | Tinmorry PETG-ECO | cả 6 |
| TIN-ABSPRO | Tinmorry ABS Pro | TRI, V24, H2S, P1S |

ABS và ASA chỉ cho máy có buồng kín: TRI, V24, H2S, P1S. Không có hồ sơ ABS cho A1 và A1 Mini.
Tổng 6 + 6 + 6 + 4 = 22 hồ sơ vật liệu; cộng 6 hồ sơ máy và 6 quy trình là 34 file.

## Khóa hồ sơ

- Mỗi hồ sơ vật liệu và quy trình có `compatible_printers` trỏ đúng một hồ sơ máy DHH của cặp, nên mỗi cặp chỉ hiện một hồ sơ.
- Chỉ sinh `.json`; không `.info`, không `setting_id`, `user_id`, `base_id` (`specs\003-orca-profiles\research.md`).
- Máy Bambu: hồ sơ không đặt `pressure_advance` (K do máy quản lý, `specs\004-bambu-calibration\research.md`).
- Máy Voron: PA lấy từ hồ sơ Orca (`enable_pressure_advance` + `pressure_advance`).

## Trạng thái của số trong bảng nguồn

Dùng đúng bốn giá trị của `docs\data-formats.md`: `đo`, `kế_thừa`, `mặc_định`, `chưa_đo`. Số `đo` trong `calibration\voron.csv`
hoặc `calibration\bambu.csv` (nếu có) thắng số trong `materials.csv`. Ô `chưa_đo` để trống và hồ sơ không ghi đè khóa đó (theo hồ sơ cha).
