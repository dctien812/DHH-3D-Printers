# Voron 2.4 300

Mã máy trong dự án: `V24`. Địa chỉ trong LAN ngày 2026-11-24: 192.0.2.89.

## Đã biết

- Hành trình 300 × 300 × 245 mm
- Raspberry Pi 4 (2 GB), WiFi
- Bo chính BTT Octopus Max, bo đầu in EBB36 Gen2, CAN 1 Mbit/s
- Driver X/Y TMC2209, 0,8 A; động cơ khai báo LDO-42STH48-2004MAH (0,9°)
- Trục Z 4 đai, quad gantry level
- Đùn: động cơ LDO-36STH20-1004AHG, 0,65 A
- Đầu nóng: cảm biến PT1000, tối đa 300 °C; đầu phun 0,4 mm
- Cartographer V3 (scan + touch), gia tốc kế ADXL345
- Klipper v0.13.0-822; firmware bo chính và bo đầu in đang là Kalico v2026.04.00 (sẽ nạp lại về Klipper chính)
- Shaper X ei 139,8 Hz, Y mzv 64,2 Hz; max_accel 10000
- Lịch sử: 164 lệnh in, 611 giờ

Nguồn: đọc từ cấu hình Klipper ngày 2026-11-24. Cấu hình cho biết máy được khai báo thế nào, chưa chắc là linh kiện đang lắp thật.

## Cần điền

Mục in đậm là cần trước ngày làm. **Không ghi mã truy cập, serial hay mật khẩu vào đây.**

| # | Mục | Trả lời |
|---|---|---|
| 1 | **Động cơ X/Y đang lắp thật (mã in trên thân)** | |
| 2 | **Điện áp cấp cho driver X/Y: 24 V hay 48 V** | |
| 3 | Nguồn: hãng, công suất | |
| 4 | **Đai X/Y: hãng, rộng 6 hay 9 mm, đã chạy bao lâu** | |
| 5 | Ray trượt X/Y: hãng, cỡ (MGN9 / MGN12) | |
| 6 | **Đầu nóng: Rapido đời nào (1 / 2, HF / UHF), công suất** | |
| 7 | **Đầu phun: hãng, vật liệu (đồng / thép tôi / mạ), đã dùng bao lâu** | |
| 8 | Kiểu đầu in (Stealthburner, Xol, khác) và loại quạt làm mát chi tiết | |
| 9 | Đùn: đúng Orbiter 2.5 không | |
| 10 | Bàn nhiệt: công suất, AC hay DC, độ dày nhôm | |
| 11 | **Tấm in đang dùng (PEI nhám / trơn / khác), tấm nào cho nhựa nào** | |
| 12 | Buồng: vật liệu vách, có cách nhiệt không, có sưởi buồng không | |
| 13 | Lọc khí: Nevermore hay loại khác, có than hoạt tính không | |
| 14 | Bộ đệm nhựa và đường nạp đang lắp | |
| 15 | Vị trí cuộn nhựa, có hộp sấy khi in không | |
| 16 | Mod khác ảnh hưởng chuyển động hoặc nhiệt | |
| 17 | Lần bảo trì gần nhất (tra dầu ray, thay đai, thay đầu phun) | |
| 18 | **Cáp USB để nạp bo Octopus Max, và có tới được nút BOOT không** | |

## Dữ liệu của máy này

- Bản chụp cấu hình ngày 2026-11-24: [fleet/precheck/2026-11-24/V24/](../../fleet/precheck/2026-11-24/V24/)
- Thẻ hiệu chuẩn: [calibration/guides/](../../calibration/guides/) (các file `voron_*.md`)
- Việc phải làm: [specs/002-voron-tuning/tasks.md](../../specs/002-voron-tuning/tasks.md)
- Hồ sơ OrcaSlicer: tên bắt đầu bằng `DHH` và kết thúc bằng tên máy, nguồn ở [profiles/src/](../../profiles/src/)
- Số hiệu chuẩn và số đo mẫu: [calibration/](../../calibration/) (các dòng có mã `V24`)
