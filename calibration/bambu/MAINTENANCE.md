# Bảo trì máy Bambu: bảng theo máy

Nguồn: wiki chính thức của Bambu Lab, trưởng phòng đọc ngày 2026-11-24 qua Chrome của người dùng; **chỉ đọc một phần mỗi trang** (`specs\004-bambu-calibration\research.md:3-5,44-60`). Ô để trống nghĩa là research chưa đọc được: tra URL ở cột cuối và điền, đừng đoán. Tên dầu và mỡ cụ thể không có trong research: tra trang hãng.

Cách dùng: tích ô `Làm` khi xong, ghi ngày vào `Lần gần nhất`. Việc đến hạn thì làm ở Buổi B2 (`specs\004-bambu-calibration\tasks.md:29`) và ghi vào `calibration\bambu\health_<máy>.md`. Máy tự ước lượng độ bẩn và nhắc bảo trì (chỉ nêu cho H2S). Văn phòng không điều khiển máy Bambu; mọi việc dưới đây do bạn làm bằng tay.

## H2S (chỉ dùng chức năng in)

URL: https://wiki.bambulab.com/en/h2s/maintenance/period-maintenance

| Làm | Việc | Chu kỳ | Vật tư | Lần gần nhất |
|---|---|---|---|---|
| [ ] | Ray X: lau, tra dầu | mỗi tháng | dầu (loại: tra URL) | |
| [ ] | Trục Y và trục Z (trục trơn): tra dầu | mỗi 3 tháng | dầu (loại: tra URL) | |
| [ ] | Vít me: tra mỡ | mỗi 3 tháng | mỡ (loại: tra URL) | |
| [ ] | Bàn nhiệt | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Đầu in | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Các camera | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Cảm biến lửa | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Quạt phụ | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Lọc than | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Lưới thoát khí | mỗi 3 tháng | (thao tác cụ thể: tra URL) | |
| [ ] | Bánh răng đùn: kiểm | hằng tuần | | |
| [ ] | Dao cắt nhựa: kiểm | sau 3 đến 5 cuộn | | |
| [ ] | Rút nguội hotend | sau 5 cuộn | | |

Research chỉ liệt kê bàn nhiệt, đầu in, camera, cảm biến lửa, quạt phụ, lọc than, lưới thoát khí chung một chu kỳ 3 tháng, không nêu thao tác từng món (`research.md:46-50`).

## P1S

URL: https://wiki.bambulab.com/en/p1/maintenance/p1p-maintenance (trang chung cho dòng P1; chưa xác nhận khác biệt giữa P1P và P1S)

| Làm | Việc | Chu kỳ | Vật tư | Lần gần nhất |
|---|---|---|---|---|
| [ ] | Thanh carbon trục X: lau, **không tra mỡ** | mỗi tháng | IPA | |
| [ ] | Ba vít me Z: lau và tra mỡ | mỗi 3 tháng | mỡ (loại: tra URL), khăn | |
| [ ] | Trục trơn Y và Z: kiểm | mỗi tháng | | |
| [ ] | Phần còn lại của trang (đầu in, bàn, quạt, ...) | | | |

Dòng cuối để trống: research ghi "phần còn lại của trang chưa đọc" (`research.md:51-53`).

## A1

URL: https://wiki.bambulab.com/en/a1/maintenance/basic-maintenance ; căng đai: https://wiki.bambulab.com/en/a1/maintenance/belt_tension

| Làm | Việc | Chu kỳ | Vật tư | Lần gần nhất |
|---|---|---|---|---|
| [ ] | Ray X: tra **dầu**; **cấm tra mỡ lên ray X** | (chưa đọc, tra URL) | dầu (loại: tra URL) | |
| [ ] | Ray Y: tra **dầu** (hãng đã đổi từ mỡ sang dầu cho ray Y) | (chưa đọc, tra URL) | dầu (loại: tra URL) | |
| [ ] | Vít me: tra mỡ | (chưa đọc, tra URL) | mỡ (loại: tra URL) | |
| [ ] | Bánh răng đùn: tra mỡ | (chưa đọc, tra URL) | mỡ (loại: tra URL) | |
| [ ] | Kiểm và căng đai | (chưa đọc, tra URL) | (tra URL belt_tension) | |

Chu kỳ chưa đọc được (`research.md:54-56,60`).

## A1M (A1 Mini)

URL: https://wiki.bambulab.com/en/a1-mini/maintenance/period-maintenance

| Làm | Việc | Chu kỳ | Vật tư | Lần gần nhất |
|---|---|---|---|---|
| [ ] | Ray X: lau và tra dầu | (chưa đọc, tra URL) | dầu (loại: tra URL) | |
| [ ] | Ray Z: lau và tra dầu | (chưa đọc, tra URL) | dầu (loại: tra URL) | |

Chu kỳ chưa đọc được (`research.md:57-58`). Các hạng mục khác của trang chưa đọc.

## Chung cho cả bốn máy

- Hiệu chuẩn có sẵn trên máy: https://wiki.bambulab.com/en/general/printer-calibration (chưa đọc). Danh sách bước hiệu chuẩn theo từng máy: chưa có, điền khi đọc (`research.md:62-65`).
- Firmware: cả bốn máy đang ở bản mới nhất theo trang lịch sử phát hành (`research.md:7-22`); khuyến nghị xem `fleet\firmware\TEMPLATE.md`.

## Vật tư cần có trước ngày làm (tích khi đã có)

- [ ] Dầu cho trục trơn và ray (H2S, A1, A1M); loại: tra URL từng máy
- [ ] Mỡ cho vít me và bánh răng đùn (H2S, P1S, A1); loại: tra URL từng máy
- [ ] IPA và khăn không xơ (P1S: lau thanh carbon X)
- [ ] Dụng cụ theo trang hãng (tua vít, cờ lê lục giác): tra URL; chưa liệt kê vì research chưa đọc
