# Khuyến nghị firmware: P1S

Văn phòng chỉ **khuyến nghị**. Nâng hay giữ do chủ máy quyết (hiến chương V, `.specify\memory\constitution.md`). Không máy nào bị nâng trước câu trả lời đó. Khung: `fleet\firmware\TEMPLATE.md`.

## Bảng

| Máy | Bản đang chạy | Bản mới | Thay đổi liên quan | Khuyến nghị | Nguồn | Ngày |
|---|---|---|---|---|---|---|
| P1S | 01.10.00.00 | không biết: bản đứng đầu trang p1p là 01.10.00.00 (2026-03-30), trùng bản đang chạy; trang p1p chưa xác nhận áp dụng cho P1S | xem mục "Thay đổi đáng chú ý"; chưa đọc hết ghi chú, chưa khẳng định có hay không thay đổi ảnh hưởng phần mềm bên thứ ba | Giữ, chưa đủ căn cứ để nâng | https://wiki.bambulab.com/en/p1/manual/p1p-firmware-release-history | 2026-11-24 |

## Bản đang chạy

01.10.00.00, báo trong gói quảng bá của máy ngày 2026-11-24 (`fleet\precheck\2026-11-24\SUMMARY.md:40`). Chưa có file kiểm kê fleet\inventory.csv (chưa tạo) để đối chiếu; đối chiếu lại khi có. Máy ở chế độ cloud, đã gắn tài khoản.

## Bản mới nhất

01.10.00.00, ngày 2026-03-30, theo trang lịch sử phát hành chính thức của Bambu Lab, trưởng phòng đọc ngày 2026-11-24 qua Chrome của người dùng (công cụ tải tự động bị trang trả mã 402). Chưa đọc lại sau ngày đó. Nguồn trong dự án: `specs\004-bambu-calibration\research.md:7-22`.
Lưu ý: tên trang trong URL là `p1p`; research dùng trang này cho P1S nhưng chưa xác nhận trang p1p gộp cả P1S. Ghi nhận bổ sung của trưởng phòng (qua Chrome, ngày 2026-11-24): tiêu đề trang là "P1P/P1S and AMS Firmware Release History", mục đầu ghi "P1 series Version 01.10.00.00 (20260330)". Nếu đúng như vậy thì trang dùng chung cho P1P và P1S. Kiểm lại ở 004:T019.

## Thay đổi đáng chú ý của bản đang chạy

Chỉ những gì research ghi (`specs\004-bambu-calibration\research.md:12`):
- in nhiều màu bằng cuộn ngoài;
- bản vá bảo mật.

## Liên quan tới OrcaSlicer và phần mềm bên thứ ba

**Đã biết**
- Các dòng ghi chú trên không nhắc tới OrcaSlicer, plugin mạng, LAN hay cloud. Research chỉ đọc một phần mỗi trang.
- Spec nêu rủi ro firmware Bambu mới có thể siết kết nối của phần mềm bên thứ ba (`specs\004-bambu-calibration\spec.md`, User Story 3). Research chỉ ghi "bản vá bảo mật" và không nói bản này có siết kết nối hay không.
- Máy PC có plugin `bambu_networking` các bản 02.03.00, 02.08.01, 02.08.04, 02.09.01 (`fleet\precheck\2026-11-24\SUMMARY.md:51`).

**Chưa biết**
- Ghi chú đầy đủ của bản 01.10.00.00 chưa được đọc: chưa khẳng định không có thay đổi liên quan phần mềm bên thứ ba (`specs\004-bambu-calibration\research.md:21-22`).
- Chưa có xác nhận riêng của người dùng hay phép thử cho P1S in từ OrcaSlicer qua plugin trên bản này (sổ chỉ ghi xác nhận cho H2S, `.office\ledger.md:31`).
- K trên P1S: P1 chỉ hiệu chuẩn tay và không có ô "Flow Dynamics Calibration" khi gửi lệnh in (`specs\004-bambu-calibration\research.md`, mục K). Không biết bản firmware này đổi gì ở đó.

## Khuyến nghị

**Giữ 01.10.00.00.** Lý do: chưa đủ căn cứ để nâng (trang p1p chưa xác nhận áp dụng cho P1S).
Khi có bản mới:
1. đọc ghi chú phát hành đầy đủ, nhất là phần kết nối OrcaSlicer, plugin mạng, cloud;
2. trình chủ máy quyết nâng hay giữ;
3. chỉ sau câu trả lời mới nâng, rồi ghi sổ.

## Chưa kiểm

- Ghi chú đầy đủ của từng bản firmware P1S.
- Trang `p1p` có phải là trang lịch sử phát hành của P1S hay không (research dùng làm nguồn cho P1S).
- Máy có bật tự động cập nhật firmware hay không. Hỏi chủ máy hoặc xem cài đặt trên màn hình máy.
- URL và câu trích ở trên chưa kiểm lại (004:T019).
- P1S in qua Orca với bản này: chưa có phép thử.

## Quyết định của người dùng (điền ở Buổi F, 004:T020)

- Quyết định: [ ] giữ  [ ] nâng
- Ngày quyết: ____  Ghi sổ: ____
