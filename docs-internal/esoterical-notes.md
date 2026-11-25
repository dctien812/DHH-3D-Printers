# Ghi chú từ hướng dẫn CAN của Esoterical (đọc ngày 2026-11-25)

Nguồn cộng đồng, chủ máy dùng hướng dẫn này khi dựng và cập nhật firmware các bo. Trưởng phòng đọc qua
Chrome của chủ máy; cấu hình menuconfig trên trang là ảnh chụp màn hình, chép lại dưới đây.

## Octopus MAX EZ (bo chính, cầu USB-CAN)

https://canbus.esoterical.online/mainboard_flashing/common_hardware/BigTreeTech%20Octopus%20Max%20EZ/README.html

| Mục | Katapult | Klipper (USB-CAN bridge) |
|---|---|---|
| Kiến trúc / chip | STM32 / STM32H723 | STM32 / STM32H723 |
| Bootloader | Build deployment application: 128KiB bootloader (SKR SE BX v2.0) | Bootloader offset: 128KiB bootloader (SKR SE BX v2.0) |
| Clock reference | 25 MHz crystal | 25 MHz crystal |
| Giao diện | USB (on PA11/PA12) | USB to CAN bus bridge (USB on PA11/PA12); CAN bus interface: CAN bus (on PD0/PD1) |
| Application start offset | 128KiB offset | — |
| Tốc độ CAN | — | 1000000 |
| Khác | Support bootloader entry on rapid double click of reset button: bật; Enable Status LED: bật, chân PA14 | Enable extra low-level configuration options: bật |

Vào DFU: giữ nút BOOT0 (xanh dương), nhấn rồi thả RESET (xanh lá), đếm tới 5 rồi thả BOOT0. Trang có
ảnh vị trí nút và jumper điện trở đầu cuối 120 Ω.

## EBB36 Gen2 (bo đầu in, CAN)

https://canbus.esoterical.online/toolhead_flashing/common_hardware/BigTreeTech%20EBB36%20Gen2/README.html

| Mục | Katapult | Klipper |
|---|---|---|
| Chip | STM32G0B1 | STM32G0B1 |
| Bootloader | Build deployment application (8KiB bootloader) | Bootloader offset (8KiB bootloader) |
| Clock reference | 8 MHz crystal | 8 MHz crystal |
| Giao diện | CAN bus (on PB12/PB13) | CAN bus (on PB12/PB13) |
| Application start offset | 8KiB offset | — |
| Tốc độ CAN | 1000000 | 1000000 |
| Khác | double-click reset: bật; Status LED: bật, chân PA2 | Optimize stepper code for 'step on both edges': bật |

- EBB36 Gen2 có **bo nối (breakout board) đặt trong khoang điện**. Nạp DFU qua cổng USB-C của bo nối
  này, **không cần với tới đầu in**. Phải tháo jumper USB/CAN để vào chế độ USB, nạp xong lắp lại.
- Vào DFU: giữ BOOT, nhấn rồi thả RST, đếm tới 5 rồi thả BOOT.
- Bo nối không tự là bộ chuyển USB-CAN.

## Quy trình cập nhật (bo đã có Katapult)

https://canbus.esoterical.online/Updating.html, `mainboard_klipper_updating.html`, `toolhead_klipper_updating.html`

- Trước tiên cập nhật Katapult trên Pi (`git pull` trong `~/katapult`) để có công cụ mới nhất.
- **Bo chính:** build `klipper.bin` theo cấu hình trên; dừng dịch vụ Klipper; đưa bo vào Katapult bằng
  `python3 ~/katapult/scripts/flashtool.py -i can0 -r -u <uuid bo chính>` (trang nhấn mạnh: thông báo
  "Flash success" ở bước này KHÔNG phải đã nạp) hoặc nhấn đúp nút RESET; kiểm `ls /dev/serial/by-id/*`
  thấy `usb-katapult_…`; nạp bằng `flashtool.py -f <bin> -d /dev/serial/by-id/usb-katapult_…`; kiểm
  `lsusb` và `ip a` thấy can0; khởi động lại dịch vụ Klipper.
- **Bo đầu in:** build; dừng Klipper; `flashtool.py -i can0 -r -u <uuid đầu in>` để vào Katapult (hoặc
  nhấn đúp RESET trên bo); `flashtool.py -q` thấy "Application: Katapult"; nạp
  `flashtool.py -i can0 -f <bin> -u <uuid đầu in>`; `-q` lại thấy "Application: Klipper".
- Nếu sau khi nạp mất can0 hay không thấy đầu in: thường do cấu hình build sai; sửa, build lại, nhấn đúp
  RESET để về Katapult rồi nạp lại.

## Hệ quả cho hướng dẫn nạp bo V2.4

1. Chủ máy dựng V2.4 theo hướng dẫn này và Pi có `~/katapult`, nên **nhiều khả năng cả hai bo đã có
   Katapult** (128 KiB trên Octopus, 8 KiB trên EBB36). Đây là suy ra, phải xác nhận ở khảo sát; nếu
   đúng thì nhánh nạp là E-A và O-A (qua Katapult, không cần DFU).
2. Cấu hình của Esoterical là **nguồn độc lập thứ hai** cho offset, clock và chân, khớp với tài liệu hãng
   và hằng số MCU đang chạy.
3. Nếu phải cứu EBB36 bằng DFU thì làm qua bo nối trong khoang điện, không phải tháo đầu in.
4. Quy trình của Esoterical build trong `~/klipper` và chạy `make clean`. Hướng dẫn của dự án build
   trong thư mục riêng `~/reflash-work/` để không đụng `~/klipper` (đang có file sửa cục bộ).
