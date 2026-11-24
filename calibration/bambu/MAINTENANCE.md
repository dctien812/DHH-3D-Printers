# Bảo trì máy Bambu: bảng theo máy

Nguồn: wiki chính thức của Bambu Lab, trưởng phòng đọc ngày 2026-11-24 qua Chrome của người dùng; **chỉ đọc một phần mỗi trang** (`specs\004-bambu-calibration\research.md:3-5,44-60`). Ô để trống nghĩa là research chưa đọc được: tra URL ở cột cuối và điền, đừng đoán. Tên dầu và mỡ cụ thể không có trong research: tra trang hãng.

**Trước mọi việc dưới đây: tắt máy, rút điện nếu trang hãng dặn, đợi đầu in và bàn nguội.**

Cách dùng: tích ô `Làm` khi xong, ghi ngày vào `Lần gần nhất`. **Cột `Lần gần nhất` để trống nghĩa là chưa biết việc nào đến hạn**: ghi ngày lần cuối bạn nhớ trước khi làm (không nhớ thì ghi `không_rõ` và coi là đến hạn). Việc đến hạn thì làm ở lượt B2 hôm trước ngày hiệu chuẩn (`specs\004-bambu-calibration\tasks.md:31`) và ghi vào `calibration\bambu\health_<máy>.md`. Máy tự ước lượng độ bẩn và nhắc bảo trì (chỉ nêu cho H2S). Văn phòng không điều khiển máy Bambu; mọi việc dưới đây do bạn làm bằng tay.

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
| [ ] | Ray X: lau, tra **dầu**; **cấm tra mỡ lên ray X** | mỗi tháng | dầu (loại: tra URL) | |
| [ ] | Ray Y: lau, tra **dầu** (hãng đã đổi từ mỡ sang dầu cho ray Y) | mỗi tháng | dầu (loại: tra URL) | |
| [ ] | Vít me Z: tra mỡ | mỗi 3 tháng | mỡ (loại: tra URL) | |
| [ ] | Puly dẫn hướng X, Y | mỗi 3 tháng | (thao tác: tra URL) | |
| [ ] | Quạt làm mát chi tiết, quạt đầu nóng: kiểm, gỡ vật lạ | mỗi tuần | | |
| [ ] | Cụm gia nhiệt đầu nóng | mỗi tháng | (thao tác: tra URL) | |
| [ ] | Dao cắt nhựa: kiểm lưỡi | sau mỗi 3 cuộn PLA / ABS / PETG | | |
| [ ] | Ống PTFE: thay khi mòn | nhựa thường khoảng mỗi 6 cuộn; nhựa có sợi hoặc ma sát cao mỗi 2 cuộn | ống PTFE (loại: tra URL) | |
| [ ] | Bánh răng đùn: tra mỡ | (chu kỳ chưa đọc, tra URL) | mỡ (loại: tra URL) | |

Nguồn chu kỳ: `research.md:64-74` (đọc 2026-11-25), URL basic-maintenance ở trên. **Độ căng đai**: không có chu kỳ; máy tự kiểm khi chạy hiệu chuẩn tần số rung, đai lỏng thì HMS báo dùng bộ căng đai tự động (`research.md:76`); hướng dẫn ở URL `belt_tension`. Ô còn trống: bánh răng đùn (chu kỳ) và các cột "thao tác" ghi "tra URL".

## A1M (A1 Mini)

URL: https://wiki.bambulab.com/en/a1-mini/maintenance/period-maintenance

| Làm | Việc | Chu kỳ | Vật tư | Lần gần nhất |
|---|---|---|---|---|
| [ ] | Ray X, ray Y: lau, tra dầu (theo "như A1") | mỗi tháng | dầu (loại: tra URL) | |
| [ ] | Ray Z: lau, tra dầu | mỗi tháng | dầu (loại: tra URL) | |
| [ ] | Vít me Z: tra mỡ (theo "như A1") | mỗi 3 tháng | mỡ (loại: tra URL) | |
| [ ] | Puly dẫn hướng trục X (chỉ một puly) | mỗi 3 tháng | (thao tác: tra URL) | |
| [ ] | Quạt làm mát chi tiết, quạt đầu nóng: kiểm, gỡ vật lạ | mỗi tuần | | |
| [ ] | Quạt bo mạch (quạt thứ ba) | (trang chỉ nêu chu kỳ tuần cho hai quạt kia; để trống, tra URL) | | |
| [ ] | Cụm gia nhiệt đầu nóng | mỗi tháng | (thao tác: tra URL) | |
| [ ] | Dao cắt nhựa: kiểm lưỡi | sau mỗi 3 cuộn PLA / ABS / PETG | | |
| [ ] | Ống PTFE: thay khi mòn | nhựa thường khoảng mỗi 6 cuộn; nhựa có sợi hoặc ma sát cao mỗi 2 cuộn | ống PTFE (loại: tra URL) | |
| [ ] | Bánh răng đùn: tra mỡ (theo "như A1") | (chu kỳ chưa đọc, tra URL) | mỡ (loại: tra URL) | |

Nguồn: `research.md:78-80` ("như A1, khác ở chỗ ..."), đọc 2026-11-25. Độ căng đai: như A1, không có chu kỳ; máy tự kiểm khi hiệu chuẩn rung, đai lỏng thì HMS báo dùng bộ căng đai tự động. Ô còn trống: chu kỳ quạt bo mạch.

## Chung cho cả bốn máy

- Hiệu chuẩn có sẵn trên máy: xem mục "Sau khi bảo trì" bên dưới.
- Firmware: cả bốn máy đang ở bản mới nhất theo trang lịch sử phát hành (`research.md:7-22`); khuyến nghị xem `fleet\firmware\TEMPLATE.md`.

## Sau khi bảo trì: chạy hiệu chuẩn của máy

Nguồn: https://wiki.bambulab.com/en/general/printer-calibration (`research.md:82-90`, đọc 2026-11-25). **Làm bảo trì (tra dầu, mỡ, căng đai) trước, rồi mới chạy hiệu chuẩn.**
- Auto Calibration gồm cân bàn, độ cao đầu phun, bù rung (vibration compensation) và khử ồn động cơ (motor noise cancellation).
- Lối vào: màn hình máy (Settings → Calibration, tên mục khác nhau theo dòng máy), Bambu Studio (Devices → Calibrate), hoặc Bambu Handy. Bạn bấm; văn phòng không điều khiển máy.
- Hãng khuyên chạy lại: sau khi chuyển chỗ máy; sau cập nhật firmware hoặc bảo trì (căng đai); khi thay linh kiện; khi chất lượng in giảm.
- Trang nguồn **không liệt kê riêng cho H2S và P1S**: danh sách hiệu chuẩn của hai máy này chưa có nguồn, xem màn hình máy.

## Vật tư cần có trước ngày làm (tích khi đã có)

- [ ] Dầu cho trục trơn và ray (H2S, A1, A1M); loại: tra URL từng máy
- [ ] Mỡ cho vít me và bánh răng đùn (H2S, P1S, A1); loại: tra URL từng máy
- [ ] IPA và khăn không xơ (P1S: lau thanh carbon X)
- Dụng cụ (tua vít, cờ lê lục giác, ...): research không nêu; xem trang hãng của từng việc
