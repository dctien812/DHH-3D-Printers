# Voron 2.4 300

[Về trang chính](../../README.md) · [Phiếu cần điền](../../docs/phieu.html) · [Các máy khác](../)

## Tóm tắt

| Mục | Giá trị |
|---|---|
| Mã máy trong dự án | `V24` |
| Loại | Voron 2.4, Klipper (Klippain), buồng kín |
| Nhựa trong phạm vi | Bambu PETG Basic, Tinmorry PETG-ECO, Tinmorry ABS Pro (không thử PLA) |
| Số hồ sơ vật liệu | 3 |
| Đặc tả liên quan | [002 voron-tuning](../../specs/002-voron-tuning/tasks.md), [003 orca-profiles](../../specs/003-orca-profiles/tasks.md) |
| Hồ sơ OrcaSlicer | `DHH Voron 2.4 300 0.4` (chưa nạp vào Orca) |
| Trạng thái | Chưa có thay đổi nào lên máy. Chưa script nào chạy với máy thật. |

## Đã biết

Nguồn: đọc từ cấu hình Klipper và Moonraker ngày 2026-11-24, ghi trong [SUMMARY.md](../../fleet/precheck/2026-11-24/SUMMARY.md) và bản sao cấu hình trong `fleet/precheck/2026-11-24/<máy>/`.

> [!NOTE]
> Cấu hình cho biết máy được khai báo thế nào, chưa chắc là linh kiện đang lắp thật. Phần "Cần điền" bên dưới để xác nhận.

| Mục | Giá trị |
|---|---|
| Hành trình | 300 x 300 x 245 mm |
| Máy tính nhúng | Raspberry Pi 4 (2 GB), WiFi |
| Bo mạch | Bo chính BTT Octopus Max, bo đầu in EBB36 Gen2, CAN 1 Mbit/s |
| Driver và động cơ X/Y | TMC2209, 0,8 A; động cơ khai báo LDO-42STH48-2004MAH (0,9°) |
| Trục Z | 4 đai, quad gantry level |
| Đùn | Động cơ LDO-36STH20-1004AHG, 0,65 A |
| Đầu nóng | Cảm biến PT1000, tối đa 300 °C; đầu phun 0,4 mm |
| Cảm biến | Cartographer V3 (scan + touch), gia tốc kế ADXL345 |
| Phần mềm | Klipper v0.13.0-822 (dirty: có file đã sửa cục bộ so với bản gốc) |
| Firmware MCU | Bo chính và bo đầu in đang là **Kalico v2026.04.00**; sẽ nạp lại về Klipper chính |
| Input shaper | X ei 139,8 Hz, Y mzv 64,2 Hz; `max_accel` 10000 |
| Pressure advance đang chạy | 0,02 (chưa phải số đã đo cho PETG) |
| Bảng vật liệu Klippain | `material_profiles_enabled` đang là False (đã tắt sẵn) |
| Lịch sử | 164 lệnh in, 611 giờ |
| Cập nhật đang chờ | Klipper 0.14.0 và một số thành phần khác; không cập nhật giữa lần đo đai trước và sau |

Chưa đọc được: dung lượng đĩa trống của Pi, nội dung `klippy.log`.

## Việc sẽ làm trên máy này

| Khi nào | Việc | Đặc tả |
|---|---|---|
| Hôm trước | Nạp lại firmware MCU về Klipper chính: bo EBB36 qua CAN (Katapult), bo Octopus Max qua USB/DFU. Chủ dự án ở cạnh máy; hỏi riêng trước khi nạp | 002 (T024 đến T028) |
| Ngày 1 | Chủ dự án cân lại hai đai và kiểm puly, ổ bi; văn phòng đo cộng hưởng trước và sau, đặt lại input shaper, thử mất bước | 002 |
| Trước khi in nhựa | Xác nhận `material_profiles_enabled = False` để PA chỉ lấy từ hồ sơ Orca | 002 (T037) |
| Ngày 2 | Hiệu chuẩn và in mẫu Bambu PETG Basic, Tinmorry PETG-ECO | 002, 003 |
| Ngày 3 | Tinmorry ABS Pro (buồng đóng, thông gió), in bù nếu lệch, thử lắp chéo | 003 |

Mọi thay đổi cấu hình lên máy theo hiến chương: máy không in, so bản trên máy, sao lưu, ghi sổ. Việc làm trên Trident trước, kiểm xong mới tới máy này. Mọi việc đùn nhựa chờ chủ dự án xác nhận.

> [!NOTE]
> Việc nạp lại MCU là quyết định ngày 2026-11-24: không chuyển sang Kalico, đưa V2.4 về Klipper chính. Cách nạp (hướng dẫn riêng) chưa viết xong và chưa thử trên máy.

## Thẻ hướng dẫn liên quan

- [voron_BAMBU-PETG.md](../../calibration/guides/voron_BAMBU-PETG.md)
- [voron_TIN-PETGECO.md](../../calibration/guides/voron_TIN-PETGECO.md)
- [voron_TIN-ABSPRO.md](../../calibration/guides/voron_TIN-ABSPRO.md)
- [RUN-DAY.md](../../calibration/guides/RUN-DAY.md): lịch ngày làm

Các thẻ đang được rà, nội dung có thể đổi.

## Cần điền

Điền ở nhóm của máy này trong phiếu [docs/phieu.html](../../docs/phieu.html) (xem [PHIEU-DIEN.md](../../PHIEU-DIEN.md)). Cần trước ngày làm: động cơ X/Y đang lắp thật và điện áp driver (24 V hay 48 V), đai X/Y (hãng, bề rộng, thời gian chạy), đầu nóng Rapido đời nào, đầu phun (hãng, vật liệu, thời gian dùng), tấm in cho từng nhựa, và cáp USB để nạp bo Octopus Max kèm việc có tới được nút BOOT không. Các mục còn lại: nguồn, ray trượt, kiểu đầu in, Orbiter 2.5, bàn nhiệt, buồng, lọc khí, đường nạp nhựa, hộp sấy, mod khác, lần bảo trì gần nhất.

> [!NOTE]
> Mở phiếu trên web: <https://dctien812.github.io/DHH-3D-Printers/phieu.html> (điền được trên điện thoại; câu trả lời lưu trên trình duyệt đang dùng).

> [!WARNING]
> Không ghi mã truy cập, serial hay mật khẩu vào phiếu hay vào repo.

## Dữ liệu của máy này

| Dữ liệu | Nơi để |
|---|---|
| Bản chụp cấu hình ngày 2026-11-24 | [fleet/precheck/2026-11-24/V24/](../../fleet/precheck/2026-11-24/V24/) |
| Cấu hình, macro, Moonraker (bản làm việc) | [v24/](../../v24/) |
| Bản gốc và các bước của đợt 2026-11-09, 11-10 | [orig/v24/](../../orig/v24/), [recheck/](../../recheck/), [skew/v24/](../../skew/v24/), [shaper/v24/](../../shaper/v24/) |
| Kết quả PID ngày 2026-11-09 | [pid_v24.json](../../pid_v24.json) |
| Hồ sơ OrcaSlicer | tên bắt đầu bằng `DHH`; nguồn ở [profiles/src/](../../profiles/src/) |
| Số hiệu chuẩn và số đo mẫu | [calibration/](../../calibration/) (các dòng có mã `V24`) |
