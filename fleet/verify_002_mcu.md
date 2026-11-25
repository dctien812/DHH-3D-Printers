# Kiểm sau nạp MCU V2.4 (002:T025, T028), 2026-11-25

Người làm: trưởng phòng qua SSH và Moonraker. Chủ máy đứng cạnh máy. Nhánh E-A + O-A (Katapult, chỉ qua CAN/USB nội bộ), không DFU; chủ máy chọn bỏ dump DFU (sổ ghi 2026-11-25).

## Diễn biến
| Giờ | Việc | Kết quả |
|---|---|---|
| 09:18:00 | Dừng Klipper (hạn 90 phút: 10:48:00) | `inactive` |
| | `flashtool -q`, `canbus_query` khi bo còn được gán | 0 node (đúng: node đã gán không trả lời truy vấn) |
| | EBB36 `…233b`: `-r` rồi `-q` | `Application: Katapult` |
| | EBB36 `-s` (chỉ đọc) | `Application Start: 0x8002000`, `MCU type: stm32g0b1xx`, Katapult `v0.0.1-113-gec59b9b` |
| | Cổng `gate.sh ebb36 ebb36_off8k 0x08002000` | `CONG: DAT` (`--app` AMBIGUOUS, căn cứ .config + Katapult) |
| | Nạp `ebb_off8k_klipper-0.13.0-822.bin` | `Verification Complete: SHA = B327A1A5…`, `Programming Complete` |
| | `canbus_query` | `57cb6fdc233b, Application: Klipper` (UUID giữ nguyên) |
| | CP1: start Klipper | `ready`; `mcu toolhead` `v0.13.0-822-g282db764` |
| 09:20:10 | Dừng Klipper; Octopus `…ee63` `-r` qua CAN | thành USB `1d50:6177 katapult stm32h723xx` |
| | Octopus `-s` (chỉ đọc) | `Application Start: 0x8020000`, `MCU type: stm32h723xx` |
| | Cổng `gate.sh octopus octopus_off128k 0x08020000` | `APP_OFFSET_OK`, `CONG: DAT` |
| | Nạp `octopus_off128k_klipper-0.13.0-822.bin` | `Verification Complete: SHA = 635CF942…`, `Programming Complete` |
| | Sau nạp | USB `1d50:606f` (cầu), `can0` UP 1000000 qlen 128, `9cf7e480ee63 Application: Klipper` |

## 5.1 Phiên bản (sau start Klipper, `ready`)
- `mcu`: `v0.13.0-822-g282db764`, `PWM_MAX=32768`, `stm32h723xx`
- `mcu toolhead`: `v0.13.0-822-g282db764`, `PWM_MAX=32768`, `stm32g0b1xx`
- `mcu cartographer`: `CARTOGRAPHER V3 6.1.0` (không đụng)
- klippy.log phiên mới: `Loaded MCU 'mcu' 148 commands (v0.13.0-822-g282db764 …)`, `Loaded MCU 'toolhead' 147 commands (v0.13.0-822-g282db764 …)`

## 5.2 Nhiệt (nguội), mốc trước nạp → sau nạp
bàn 20,6 → 20,7; đầu 20,6 → 20,8; cartographer_coil 21,8 → 22,0; Pi 47,2 → 47,2; mcu 34,7 → 34,2; toolhead_mcu 26,4 → 26,8; Chamber 20,0 → 20,0; ebb36_gen2_temp 26,4 → 26,3. Tất cả lệch < 0,5 °C.

## Chạy thật
- `G28`: xong 10 s, `homed_axes=xyz`.
- `QUAD_GANTRY_LEVEL`: 70 s; range 1,258533 → 0,048016 → 0,007215 (dung sai 0,009), Retries 2/8.
- Nhiệt: M140 S50 + M104 S150; bàn 50 ± 0,3 °C, đầu 150 ± 0,2 °C trong 50 s giữ nhiệt; TURN_OFF_HEATERS.
- Lỗi sau toàn bộ: can0 RX/TX errors 0; Stats cuối `bytes_retransmit=0 bytes_invalid=0` cả 3 MCU; `rx_error=0 tx_error=0`; không có shutdown/lost communication trong phiên mới.

## Chưa kiểm
- Đùn nhựa (cần nhựa và nhiệt in) và in thử: làm ở buổi in đầu tiên.
- Quạt, đèn LED, cảm biến OSS, accelerometer (ADXL/LIS2DW trên EBB).
- PID: `PWM_MAX` đổi 256 → 32768; giữ nhiệt ổn ở 50/150 °C, chưa kiểm ở nhiệt in.

## Đường lui
`~/mcu-build/kalico-rescue/kalico_{ebb_off8k,octopus_off128k}.bin`, nạp bằng cùng lệnh Katapult.
