# Định dạng dữ liệu dùng chung

Tất cả file CSV là UTF-8, dòng đầu là tên cột, dấu phân cách là dấu phẩy, số thập phân dùng dấu chấm. Ngày theo dạng `YYYY-MM-DD`.

Mã máy: `TRI` (Voron Trident 250), `V24` (Voron 2.4 300), `H2S`, `P1S`, `A1`, `A1M` (Bambu A1 Mini).
Mã nhựa: `BAMBU-PLA`, `BAMBU-PETG`, `TIN-PETGECO`, `TIN-ABSPRO`.

Không file nào ngoài `secrets\` được chứa serial hay mã truy cập.

## Bảng 1. Kiểm kê (`fleet\inventory.csv`)

| Cột | Ý nghĩa |
|---|---|
| id | mã máy (TRI, V24, H2S, P1S, A1, A1M) |
| tên | tên máy do máy tự báo |
| mẫu | mẫu máy |
| ip | địa chỉ IP |
| mac | địa chỉ MAC (lấy bằng ARP) |
| phần_mềm_firmware | phiên bản Klipper (Voron) hoặc firmware (Bambu) |
| đầu_phun | đường kính và loại đầu phun |
| bàn | kích thước bàn in |
| phụ_kiện | AMS, camera, v.v. |
| kết_nối | cách kết nối (Moonraker, Bambu Cloud, ...) |
| buồng_kín | có / không |
| nguồn | nguồn của từng số (Moonraker, SSDP, màn hình máy, ...) |
| ngày | ngày lấy số liệu |

Máy không trả lời: ghi "không trả lời" kèm giờ vào các cột số liệu, vẫn ghi các máy khác.

## Bảng 2. Số hiệu chuẩn, dạng dọc (`calibration\voron.csv`, `calibration\bambu.csv`; số đo nhập tay ở `calibration\entry\cal\`)

Mỗi lần đo một file CSV trong `calibration\entry\cal\`. Mỗi dòng là một tham số của một cặp máy-nhựa.

| Cột | Ý nghĩa |
|---|---|
| máy | mã máy |
| nhựa | mã nhựa |
| tham_số | một trong `pa`, `k`, `flow_ratio`, `mvs`, `shrink_xy`, `temp_nozzle` |
| giá_trị | số |
| đơn_vị | đơn vị của giá trị |
| trạng_thái | `đo`, `kế_thừa`, `mặc_định`, `chưa_đo` |
| nguồn | file hoặc phép đo sinh ra giá trị |
| ngày | ngày đo |
| cuộn | định danh cuộn nhựa đã dùng |
| điều_kiện | nhiệt độ, tốc độ, ghi chú điều kiện đo |

### Quy tắc `trạng_thái`

- `đo`: đã đo thật cho đúng cặp máy-nhựa này. Bắt buộc có `nguồn`, `ngày`, `cuộn`; script nạp từ chối dòng `đo` thiếu một trong ba.
- `kế_thừa`: lấy từ cặp khác đã đo (ghi cặp gốc trong `nguồn`).
- `mặc_định`: lấy từ mặc định của nhà sản xuất, chưa đo.
- `chưa_đo`: chưa có giá trị; để trống `giá_trị`.

Không ghi "đã kiểm chứng" cho thông số có trạng thái khác `đo`.

## Bảng 3. Kết quả mẫu chuẩn (`calibration\results.csv`; số đo nhập tay ở `calibration\entry\part\`)

Mỗi lần đo một file CSV trong `calibration\entry\part\`, sau đó gộp vào `results.csv`.

| Cột | Ý nghĩa |
|---|---|
| máy | mã máy |
| nhựa | mã nhựa |
| cuộn | định danh cuộn |
| X | kích thước X, mm, trung bình 3 lần đo |
| Y | kích thước Y, mm, trung bình 3 lần đo |
| Z | chiều cao Z, mm |
| lỗ | đường kính lỗ, mm |
| đạt | `đạt` hoặc `không` theo dung sai bên dưới |
| ngày | ngày đo |

### Dung sai

- X/Y: ±0,1 mm trên 100 mm.
- Z: ±0,1 mm trên 20 mm.
- Lỗ Ø8: ±0,15 mm.

Mẫu chuẩn: (a) khung rỗng 100 × 100 × 20 mm, đo X/Y ở giữa chiều cao; (b) tấm lỗ và chốt Ø8; (c) tháp bề mặt và nhô.
