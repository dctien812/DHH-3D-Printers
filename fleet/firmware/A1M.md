# Khuyến nghị firmware: A1 Mini

Văn phòng chỉ **khuyến nghị**. Nâng hay giữ do chủ máy quyết (hiến chương V, `.specify\memory\constitution.md`). Không máy nào bị nâng trước câu trả lời đó. Khung: `fleet\firmware\TEMPLATE.md`.

## Bảng

| Máy | Bản đang chạy | Bản mới | Thay đổi liên quan | Khuyến nghị | Nguồn | Ngày |
|---|---|---|---|---|---|---|
| A1M | 01.09.00.00 | không có (01.09.00.00, ngày 2026-11-09, đứng đầu trang lịch sử phát hành) | xem mục "Thay đổi đáng chú ý"; chưa đọc hết ghi chú, chưa khẳng định có hay không thay đổi ảnh hưởng phần mềm bên thứ ba | Giữ | https://wiki.bambulab.com/en/a1-mini/manual/a1-mini-firmware-release-history | 2026-11-24 |

## Bản đang chạy

01.09.00.00, báo trong gói quảng bá của máy ngày 2026-11-24 (`fleet\precheck\2026-11-24\SUMMARY.md:42`). Chưa có file kiểm kê fleet\inventory.csv (chưa tạo) để đối chiếu; đối chiếu lại khi có. Máy ở chế độ cloud, đã gắn tài khoản.

## Bản mới nhất

01.09.00.00, ngày 2026-11-09, theo trang lịch sử phát hành chính thức của Bambu Lab, trưởng phòng đọc ngày 2026-11-24 qua Chrome của người dùng (công cụ tải tự động bị trang trả mã 402). Chưa đọc lại sau ngày đó. Nguồn trong dự án: `specs\004-bambu-calibration\research.md:7-22`.

## Thay đổi đáng chú ý của bản đang chạy

Chỉ những gì research ghi (`specs\004-bambu-calibration\research.md:14`, ghi "như A1"):
- cập nhật bảo mật;
- không cho hiệu chuẩn khi đang in;
- sửa lỗi màn hình và nạp nhựa.

Dòng "không cho hiệu chuẩn khi đang in" chưa rõ có tác động tới ô Flow Dynamics Calibration khi gửi lệnh in từ Orca hay không. Chưa biết.

## Liên quan tới OrcaSlicer và phần mềm bên thứ ba

**Đã biết**
- Các dòng ghi chú trên không nhắc tới OrcaSlicer, plugin mạng, LAN hay cloud. Research chỉ đọc một phần mỗi trang.
- Spec nêu rủi ro firmware Bambu mới có thể siết kết nối của phần mềm bên thứ ba (`specs\004-bambu-calibration\spec.md`, User Story 3). Research chỉ ghi "cập nhật bảo mật" và không nói bản này có siết kết nối hay không.
- Máy PC có plugin `bambu_networking` các bản 02.03.00, 02.08.01, 02.08.04, 02.09.01 (`fleet\precheck\2026-11-24\SUMMARY.md:51`).

**Chưa biết**
- Ghi chú đầy đủ của bản 01.09.00.00 chưa được đọc: chưa khẳng định không có thay đổi liên quan phần mềm bên thứ ba (`specs\004-bambu-calibration\research.md:21-22`).
- Chưa có xác nhận riêng của người dùng hay phép thử cho A1 Mini in từ OrcaSlicer qua plugin trên bản này (sổ chỉ ghi xác nhận cho H2S, `.office\ledger.md:31`).
- Phép thử A/B cho K (004:T011) sẽ cho biết Orca và plugin gửi lựa chọn Flow Dynamics đúng như Bambu Studio hay không; chưa chạy.

## Khuyến nghị

**Giữ 01.09.00.00.** Lý do: đang ở bản đứng đầu trang lịch sử phát hành, không có bản mới để nâng.
Khi có bản mới:
1. đọc ghi chú phát hành đầy đủ, nhất là phần kết nối OrcaSlicer, plugin mạng, cloud;
2. trình chủ máy quyết nâng hay giữ;
3. chỉ sau câu trả lời mới nâng, rồi ghi sổ.

## Chưa kiểm

- Ghi chú đầy đủ của từng bản firmware A1 Mini; cột ghi chú của research cho A1 Mini chỉ ghi "như A1", chưa đọc riêng.
- Máy có bật tự động cập nhật firmware hay không. Hỏi chủ máy hoặc xem cài đặt trên màn hình máy.
- URL và câu trích ở trên chưa kiểm lại (004:T019).
- A1 Mini in qua Orca với bản này: chưa có phép thử.

## Quyết định của người dùng (điền ở Buổi F, 004:T020)

- Quyết định: [ ] giữ  [ ] nâng
- Ngày quyết: ____  Ghi sổ: ____
