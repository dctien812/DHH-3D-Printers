# Khuyến nghị firmware: H2S

Văn phòng chỉ **khuyến nghị**. Nâng hay giữ do chủ máy quyết (hiến chương V, `.specify\memory\constitution.md`). Không máy nào bị nâng trước câu trả lời đó. Khung: `fleet\firmware\TEMPLATE.md`.

## Bảng

| Máy | Bản đang chạy | Bản mới | Thay đổi liên quan | Khuyến nghị | Nguồn | Ngày |
|---|---|---|---|---|---|---|
| H2S | 01.03.00.00 | không có (01.03.00.00 đứng đầu trang lịch sử phát hành) | xem mục "Thay đổi đáng chú ý"; chưa đọc hết ghi chú, chưa khẳng định có hay không thay đổi ảnh hưởng phần mềm bên thứ ba | Giữ | https://wiki.bambulab.com/en/h2s/manual/h2s-firmware-release-history | 2026-11-24 |

## Bản đang chạy

01.03.00.00, báo trong gói quảng bá của máy ngày 2026-11-24 (`fleet\precheck\2026-11-24\SUMMARY.md:39`). Chưa có file kiểm kê fleet\inventory.csv (chưa tạo) để đối chiếu; đối chiếu lại khi có. Máy ở chế độ cloud, đã gắn tài khoản.

## Bản mới nhất

01.03.00.00 theo trang lịch sử phát hành chính thức của Bambu Lab, trưởng phòng đọc ngày 2026-11-24 qua Chrome của người dùng (công cụ tải tự động bị trang trả mã 402). Chưa đọc lại sau ngày đó. Nguồn trong dự án: `specs\004-bambu-calibration\research.md:7-22`.

## Thay đổi đáng chú ý của bản đang chạy

Chỉ những gì research ghi (`specs\004-bambu-calibration\research.md:11`):
- thêm công tắc phát hiện vật lạ;
- chế độ di chuyển tự do XYZ khi bảo trì;
- hỗ trợ hotend E3D High-Flow;
- cải thiện ước lượng nhựa còn lại (cần firmware AMS mới).

Ngày phát hành của bản này: chưa ghi trong research.

## Liên quan tới OrcaSlicer và phần mềm bên thứ ba

**Đã biết**
- Các dòng ghi chú trên không nhắc tới OrcaSlicer, plugin mạng, LAN hay cloud. Research chỉ đọc một phần mỗi trang.
- Người dùng xác nhận ngày 2026-11-24: in H2S từ OrcaSlicer qua cloud bằng plugin OpenBambu vẫn chạy bình thường (`.office\ledger.md:31`). Đây là xác nhận của người dùng, chưa có phép thử của văn phòng.
- Máy PC có plugin `bambu_networking` các bản 02.03.00, 02.08.01, 02.08.04, 02.09.01 (`fleet\precheck\2026-11-24\SUMMARY.md:51`).

**Chưa biết**
- Ghi chú đầy đủ của bản 01.03.00.00 và các bản trước chưa được đọc hết: chưa khẳng định không có thay đổi liên quan phần mềm bên thứ ba (`specs\004-bambu-calibration\research.md:21-22`).

**Bên thứ ba, chưa kiểm lại, không dùng làm căn cứ** (báo cáo tra web trong `.office\ledger.md:30`): PR #10780 của OrcaSlicer nói in H2S qua Orca cần LAN và Developer Mode (người dùng đã bác bỏ cho trường hợp của mình, dòng sổ 31); issue #11711 về đầu phun high flow trên H2S. Bản 01.03.00.00 thêm hỗ trợ E3D High-Flow, nên khi dùng đầu phun high flow thì kiểm hồ sơ máy `DHH H2S 0.4` (có biến thể `Direct Drive E3D High Flow`, `profiles\src\machines.csv`).

## Khuyến nghị

**Giữ 01.03.00.00.** Lý do: đang ở bản đứng đầu trang lịch sử phát hành, không có bản mới để nâng.
Khi có bản mới:
1. đọc ghi chú phát hành đầy đủ, nhất là phần kết nối OrcaSlicer, plugin mạng, cloud;
2. trình chủ máy quyết nâng hay giữ;
3. chỉ sau câu trả lời mới nâng, rồi ghi sổ.

## Chưa kiểm

- Ghi chú đầy đủ của từng bản firmware H2S.
- Ngày phát hành bản 01.03.00.00.
- Máy có bật tự động cập nhật firmware hay không (nếu bật, bản mới có thể được cài trước khi văn phòng trình). Hỏi chủ máy hoặc xem cài đặt trên màn hình máy.
- URL và câu trích ở trên chưa kiểm lại (004:T019).
- Tình trạng của plugin mạng Bambu với bản firmware này ngoài lời xác nhận của người dùng.

## Quyết định của người dùng (điền ở Buổi F, 004:T020)

- Quyết định: [ ] giữ  [ ] nâng
- Ngày quyết: ____  Ghi sổ: ____
