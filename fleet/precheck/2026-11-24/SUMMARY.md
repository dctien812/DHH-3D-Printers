# Kiểm tra trước khi triển khai — 2026-11-24

Chỉ đọc (Moonraker GET, nghe SSDP, thử mở cổng TCP). Lấy lúc hai Voron đang có việc in. Dữ liệu thô:
`TRI\`, `V24\` (objects.json, system_info.json, update_status.json, bản sao 333 và 332 file cấu hình).
Đây chưa phải baseline chính thức của 001:T011 (chưa có manifest băm, chưa qua vai kiểm).

## Hai Voron

| Mục | Trident (.90) | V2.4 (.89) |
|---|---|---|
| Trạng thái lúc đọc | **paused** ở 2,5 %, đầu nóng vẫn 245 °C, bàn 85 °C (file PETG 2h55m) | đang in (file PETG 8h6m, vừa bắt đầu) |
| Klipper host | v0.13.0-822 (dirty), có bản v0.14.0 | như Trident |
| Moonraker | v0.11.0-4, không cảnh báo, không thành phần lỗi | như Trident |
| MCU chính | v0.13.0-787 (stm32h723) | **Kalico v2026.04.00** |
| MCU đầu in | v0.13.0-541 (stm32g0b1) | **Kalico v2026.04.00** |
| CAN | 1 000 000 bit/s, 0 retransmit, 0 invalid | như Trident |
| Cartographer | V3 firmware 6.1.0, plugin 1.10.1, model "default" | như Trident |
| Shaper | X ei 149,4 / Y mzv 62,2 | X ei 139,8 / Y mzv 64,2 |
| max_accel cấu hình | 10000 | 10000 |
| PID | 21,23/5,242/21,496; bàn 37,981/2,482/145,279 | 18,541/2,943/29,204; bàn 45,504/3,84/134,805 |
| Skew califlower | -0,0014045 | -0,0003014 |
| Dòng động cơ X/Y | 1,2 A | 0,8 A |
| `material_profiles_enabled` | False | **False** (đã tắt sẵn) |
| Bảng vật liệu Klippain | PLA, PET, PETG, ABS, ASA, TPU | PLA, PET, ABS, TPU, ASA-CF, ASA (không có PETG) |
| PA đang chạy | 0,02 (cấu hình gốc 0,0475) | 0,02 (cấu hình gốc 0,0475) |
| `startprint_actions` | … primeline, skew_load | như Trident |
| SAVE_CONFIG đang treo | có | có |
| Pi | Pi 4 4 GB, Debian 13, 51 °C, không throttled | Pi 4 2 GB, Debian 13, 55 °C, không throttled |
| Nhiệt EBB36 | 71,9 °C (buồng 36 °C) | 64,0 °C (buồng 33 °C) |
| Lịch sử | 47 lệnh in, 94 giờ; 7 lệnh gần nhất hoàn tất | 164 lệnh in, 611 giờ; 2 trong 7 lệnh gần nhất bị hủy |
| Cập nhật đang chờ | Klipper 0.14.0, firmware Cartographer, tmc_autotune, KlipperScreen, 33 gói hệ điều hành | như Trident, 35 gói |

Chưa đọc được: dung lượng đĩa trống của Pi (endpoint trả 404), nội dung `klippy.log`.

## Bốn máy Bambu (gói quảng bá SSDP)

| Máy | Địa chỉ | Firmware | Chế độ | Cổng 8883 / 990 / 6000 | Ping |
|---|---|---|---|---|---|
| H2S | .61 | 01.03.00.00 | cloud, đã gắn tài khoản | mở / mở / mở | 2 ms |
| P1S | .199 | 01.10.00.00 | cloud, đã gắn tài khoản | mở / mở / mở | 2 ms |
| A1 | .122 | 01.09.00.00 | cloud, đã gắn tài khoản | mở / mở / mở | 3 ms |
| A1 Mini | .149 | 01.09.00.00 | cloud, đã gắn tài khoản | mở / mở / mở | 5 ms |

Chưa đọc được gì bên trong máy (lỗi treo, đầu phun, giờ in, AMS): cần mã truy cập.

## Máy tính

- PowerShell 5.1; ổ D còn 141 GB; có `python` (bản của Microsoft Store, chưa kiểm chạy được) và `dotnet`.
- OrcaSlicer: file cấu hình ghi phiên bản 2.5.1, file chạy ngày 2026-11-21; lúc kiểm không chạy.
- Orca đang đặt `"sync_user_preset": false`: tự đồng bộ hồ sơ người dùng đã tắt sẵn.
- Thư mục plugin có `bambu_networking` các bản 02.03.00, 02.08.01, 02.08.04, 02.09.01 (file ngày
  2026-11-20, kèm bản `.bak`).

## Điều kế hoạch phải tính tới

1. 002:T037 đã đạt sẵn: cả hai máy `material_profiles_enabled = False`; chỉ còn xác nhận.
2. PA khi in PETG hiện là 0,02 trên cả hai Voron: chưa phải số đã đo cho PETG.
3. SAVE_CONFIG đang treo trên cả hai máy: không chạy SAVE_CONFIG khi chưa biết nó sẽ ghi gì.
4. Không cập nhật Klipper lên 0.14.0 giữa lần đo đai trước và sau; quyết thời điểm cập nhật riêng.
5. Tốc độ CAN 1 000 000 đã biết, dùng cho hướng dẫn nạp lại MCU V2.4.
6. Tự đồng bộ hồ sơ Orca đã tắt: rủi ro cloud ghi đè hồ sơ DHH thấp hơn dự tính.
