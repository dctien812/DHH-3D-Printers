# Voron Trident 250

[Về trang chính](../../README.md) · [Phiếu cần điền](../../docs/phieu.html) · [Các máy khác](../)

## Tóm tắt

| Mục | Giá trị |
|---|---|
| Mã máy trong dự án | `TRI` |
| Loại | Voron Trident, Klipper (Klippain), buồng kín |
| Nhựa trong phạm vi | Bambu PETG Basic, Tinmorry PETG-ECO, Tinmorry ABS Pro (không thử PLA) |
| Số hồ sơ vật liệu | 3 |
| Đặc tả liên quan | [002 voron-tuning](../../specs/002-voron-tuning/tasks.md), [003 orca-profiles](../../specs/003-orca-profiles/tasks.md) |
| Hồ sơ OrcaSlicer | `DHH Voron Trident 250 0.4` (chưa nạp vào Orca) |
| Trạng thái | Chưa có thay đổi nào lên máy. Chưa script nào chạy với máy thật. |

## Đã biết

Nguồn của mọi dòng: đọc từ cấu hình Klipper và Moonraker ngày 2026-11-24 ([fleet/precheck/2026-11-24/SUMMARY.md](../../fleet/precheck/2026-11-24/SUMMARY.md)).

> [!NOTE]
> Cấu hình cho biết máy được khai báo thế nào, chưa chắc là linh kiện đang lắp thật. Phần "Cần điền" bên dưới để xác nhận.

| Mục | Giá trị |
|---|---|
| Hành trình | 250 x 250 x 210 mm |
| Máy tính nhúng | Raspberry Pi 4 (4 GB), WiFi |
| Bo mạch | Bo chính BTT Octopus Max, bo đầu in EBB36 Gen2, CAN 1 Mbit/s |
| Driver và động cơ X/Y | TMC5160, 1,2 A; động cơ khai báo LDO-42STH48-2804AH (1,8°) |
| Trục Z | 3 vít me, cân 3 điểm (Z tilt) |
| Đùn | Động cơ LDO-36STH20-1004AHG, 0,75 A |
| Đầu nóng | Cảm biến PT1000, tối đa 300 °C; đầu phun 0,4 mm |
| Cảm biến | Cartographer V3 (scan + touch), gia tốc kế ADXL345 |
| Phần mềm | Klipper v0.13.0-822; firmware bo chính v0.13.0-787, bo đầu in v0.13.0-541 |
| Input shaper | X ei 149,4 Hz, Y mzv 62,2 Hz; `max_accel` 10000 |
| Pressure advance đang chạy | 0,02 (chưa phải số đã đo cho PETG) |
| Bảng vật liệu Klippain | `material_profiles_enabled` đang là False (đã tắt sẵn) |
| Lịch sử | 47 lệnh in, 94 giờ |
| Cập nhật đang chờ | Klipper 0.14.0 và một số thành phần khác; không cập nhật giữa lần đo đai trước và sau |

Chưa đọc được: dung lượng đĩa trống của Pi, nội dung `klippy.log`.

## Việc sẽ làm trên máy này

| Khi nào | Việc | Đặc tả |
|---|---|---|
| Ngày 1 | Chủ dự án cân lại hai đai và kiểm puly, ổ bi; văn phòng đo cộng hưởng trước và sau, đặt lại input shaper, thử mất bước | 002 |
| Trước khi in nhựa | Xác nhận `material_profiles_enabled = False` để PA chỉ lấy từ hồ sơ Orca | 002 (T037) |
| Ngày 2 | Hiệu chuẩn và in mẫu Bambu PETG Basic, Tinmorry PETG-ECO | 002, 003 |
| Ngày 3 | Tinmorry ABS Pro (buồng đóng, thông gió), in bù nếu lệch, thử lắp chéo | 003 |

Mọi thay đổi cấu hình lên máy theo hiến chương: máy không in, so bản trên máy, sao lưu, ghi sổ. Trident làm trước, kiểm xong mới tới V2.4. Mọi việc đùn nhựa chờ chủ dự án xác nhận.

## Thẻ hướng dẫn liên quan

- [voron_BAMBU-PETG.md](../../calibration/guides/voron_BAMBU-PETG.md)
- [voron_TIN-PETGECO.md](../../calibration/guides/voron_TIN-PETGECO.md)
- [voron_TIN-ABSPRO.md](../../calibration/guides/voron_TIN-ABSPRO.md)
- [RUN-DAY.md](../../calibration/guides/RUN-DAY.md): lịch ngày làm (bản cũ, đang sửa)

Các thẻ đang được rà, nội dung có thể đổi.

## Cần điền

Điền ở nhóm của máy này trong phiếu [docs/phieu.html](../../docs/phieu.html) (xem [PHIEU-DIEN.md](../../PHIEU-DIEN.md)). Cần trước ngày làm: động cơ X/Y đang lắp thật và điện áp driver (24 V hay 48 V), đai X/Y (hãng, bề rộng, thời gian chạy), đầu nóng Rapido đời nào, đầu phun (hãng, vật liệu, thời gian dùng), tấm in cho từng nhựa. Các mục còn lại: nguồn, ray trượt, kiểu đầu in, Orbiter 2.5, bàn nhiệt, buồng, lọc khí, đường nạp nhựa, hộp sấy, mod khác, lần bảo trì gần nhất.

> [!NOTE]
> Link web của phiếu cần bật GitHub Pages cho repo, hiện **chưa bật**. Cách mở: tải file `docs/phieu.html` về máy tính rồi nháy đúp.

> [!WARNING]
> Không ghi mã truy cập, serial hay mật khẩu vào phiếu hay vào repo.

## Dữ liệu của máy này

| Dữ liệu | Nơi để |
|---|---|
| Bản chụp cấu hình ngày 2026-11-24 | [fleet/precheck/2026-11-24/TRI/](../../fleet/precheck/2026-11-24/TRI/) |
| Cấu hình, macro, Moonraker (bản làm việc) | [trident/](../../trident/) |
| Bản gốc và các bước của đợt 2026-11-09, 11-10 | [orig/trident/](../../orig/trident/), [recheck/](../../recheck/), [skew/trident/](../../skew/trident/), [shaper/trident/](../../shaper/trident/) |
| Kết quả PID ngày 2026-11-09 | [pid_trident.json](../../pid_trident.json) |
| Hồ sơ OrcaSlicer | tên bắt đầu bằng `DHH`; nguồn ở [profiles/src/](../../profiles/src/) |
| Số hiệu chuẩn và số đo mẫu | [calibration/](../../calibration/) (các dòng có mã `TRI`) |
