# Quy ước tên hồ sơ OrcaSlicer (tiền tố DHH)

Nguồn quy ước: người dùng chốt, ghi ở `specs\003-orca-profiles\tasks.md`. Mọi hồ sơ do `scripts\orca\build-profiles.ps1`
sinh từ `profiles\src\*.csv`; không sửa tay file trong `profiles\bundle\`.

## Ba dạng tên

| Loại | Dạng | Ví dụ |
|---|---|---|
| Máy | `DHH <Máy> 0.4` | `DHH Voron Trident 250 0.4`, `DHH A1 Mini 0.4` |
| Vật liệu | `DHH <Hãng> <Loại> @<Máy>` | `DHH Tinmorry ABS Pro @P1S`, `DHH Bambu PETG Basic @A1` |
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

## Nhựa và cặp hợp lệ (người dùng chốt 2026-11-24, `.office\ledger.md` K15)

| Mã nhựa | `<Hãng> <Loại>` | Máy hợp lệ |
|---|---|---|
| BAMBU-PLA | Bambu PLA | chỉ 4 máy Bambu (H2S, P1S, A1, A1M); không cho TRI, V24 |
| BAMBU-PETG | Bambu PETG Basic | cả 6 |
| TIN-PETGECO | Tinmorry PETG-ECO | cả 6 |
| TIN-ABSPRO | Tinmorry ABS Pro | TRI, V24, H2S, P1S |

Mã nhựa nội bộ vẫn là `BAMBU-PETG`; tên hiển thị là "Bambu PETG Basic". ABS và ASA chỉ cho máy có buồng kín (TRI, V24, H2S, P1S);
không có hồ sơ ABS cho A1 và A1 Mini. Tổng 4 + 6 + 6 + 4 = 20 hồ sơ vật liệu; cộng 6 máy và 6 quy trình là 32 file.
Bộ pilot (`-Set pilot`): 6 máy, 6 quy trình, 4 hồ sơ Bambu PLA = 16 file.

## Chọn hồ sơ cha (`inherits`) cho Bambu PETG Basic

H2S, A1: `Bambu PETG Basic @BBL H2S` / `@BBL A1`. A1 Mini: `Bambu PETG Basic @BBL A1M 0.4 nozzle` (hồ sơ hệ thống của A1M chỉ có
dạng có hậu tố `0.4 nozzle`). P1S: hệ thống không có `@BBL P1S`; dùng `Bambu PETG Basic @BBL X1C` (hồ sơ dòng X1C mà Bambu
dùng chung cho P1S). Đây là lựa chọn của người viết, chưa thử cắt lớp trên Orca. TRI, V24: `Generic PETG @System` (Bambu không có hồ sơ cho Voron).
Mọi tên cha đã đối chiếu có trong `%APPDATA%\OrcaSlicer\system\*.opc`; `-Verify` kiểm lại mỗi lần.

## Nguyên tắc số liệu

- Số của hãng này không gắn cho hãng khác: hồ sơ Bambu PLA và Bambu PETG Basic không kế thừa flow hay lưu lượng từ hồ sơ cũ nhãn Tinmorry; để theo hồ sơ cha và ghi `mặc_định`.
- Bốn trạng thái theo `docs\data-formats.md`: `đo`, `kế_thừa`, `mặc_định`, `chưa_đo`. Số `đo` trong `calibration\voron.csv` hoặc
  `calibration\bambu.csv` (nếu có) thắng số trong `materials.csv`. Ngoại lệ `mvs`: ô mvs trong `materials.csv` có số và trạng thái `đo`
  (mức đặt sau khi trừ biên an toàn) thì được giữ; phiếu ghi giới hạn đo được. Ô trống thì hồ sơ không ghi đè khóa đó.
- Máy Bambu: hồ sơ không đặt `pressure_advance` (K do máy quản lý, `specs\004-bambu-calibration\research.md`). Ngoại lệ P1S (chỉ hiệu
  chuẩn K tay): `pa` có trạng thái `đo` thì đưa vào hồ sơ (chủ máy chốt 2026-11-26).
- Máy Voron: PA lấy từ hồ sơ Orca (`enable_pressure_advance` + `pressure_advance`). V2.4 ABS Pro 0,0256 kế thừa từ hồ sơ cũ.
  Các cặp Voron còn lại 0,02 nhãn `mặc_định` (giá trị đang chạy trên máy, `fleet\precheck\2026-11-24\SUMMARY.md`).
- Khóa phụ của hồ sơ cũ cùng cặp (`default_filament_colour`, `filament_vendor`, `activate_air_filtration`,
  `complete_print_exhaust_fan_speed`...) nằm trong cột `khác` của `materials.csv`; giá trị `a|b|c` là mảng tường minh theo biến thể.

## Khóa và đầu ra

- Chỉ sinh `.json`; không `.info`, không `setting_id`, `user_id`, `base_id` (`specs\003-orca-profiles\research.md`).
- Mọi hồ sơ vật liệu và quy trình có `compatible_printers` trỏ đúng một hồ sơ máy DHH của cặp.
- Số phần tử mảng theo biến thể đầu phun lấy từ cột `biến_thể` của hồ sơ máy: H2S 3, P1S 2 (hồ sơ máy cũ của P1S khai 2; giá trị lặp
  cho cả hai), còn lại 1. Orca có nhận mảng đúng số biến thể này hay không CHƯA KIỂM: cần cắt lớp thử ở Buổi A2.
- Gói nhập: `profiles\bundle\import\DHH_printer.zip`, `DHH_filament.zip`, `DHH_process.zip`, mỗi gói chứa các `.json` cùng loại,
  để nhập bằng File > Import. Định dạng zip này CHƯA thử nhập trên Orca của người dùng; thử ở Buổi A2. Gói sinh lại được bằng script.
- Cài thử an toàn: `-Install`/`-Uninstall`/`-Verify` nhận `-UserDir <thư mục>`; thử trên bản sao `tests\tmp\orca_user_copy\`.
