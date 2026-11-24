# Voron Trident 250

Mã máy trong dự án: `TRI`. Địa chỉ trong LAN ngày 2026-11-24: 192.0.2.90.

## Đã biết

- Hành trình 250 × 250 × 210 mm
- Raspberry Pi 4 (4 GB), WiFi
- Bo chính BTT Octopus Max, bo đầu in EBB36 Gen2, CAN 1 Mbit/s
- Driver X/Y TMC5160, 1,2 A; động cơ khai báo LDO-42STH48-2804AH (1,8°)
- Trục Z 3 vít me, cân 3 điểm (Z tilt)
- Đùn: động cơ LDO-36STH20-1004AHG, 0,75 A
- Đầu nóng: cảm biến PT1000, tối đa 300 °C; đầu phun 0,4 mm
- Cartographer V3 (scan + touch), gia tốc kế ADXL345
- Klipper v0.13.0-822; firmware bo chính v0.13.0-787, bo đầu in v0.13.0-541
- Shaper X ei 149,4 Hz, Y mzv 62,2 Hz; max_accel 10000
- Lịch sử: 47 lệnh in, 94 giờ

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

## Dữ liệu của máy này

- Bản chụp cấu hình ngày 2026-11-24: [fleet/precheck/2026-11-24/TRI/](../../fleet/precheck/2026-11-24/TRI/)
- Thẻ hiệu chuẩn: [calibration/guides/](../../calibration/guides/) (các file `voron_*.md`)
- Việc phải làm: [specs/002-voron-tuning/tasks.md](../../specs/002-voron-tuning/tasks.md)
- Hồ sơ OrcaSlicer: tên bắt đầu bằng `DHH` và kết thúc bằng tên máy, nguồn ở [profiles/src/](../../profiles/src/)
- Số hiệu chuẩn và số đo mẫu: [calibration/](../../calibration/) (các dòng có mã `TRI`)
