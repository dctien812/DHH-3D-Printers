# Khuyến nghị firmware: <MÁY> (mẫu một trang)

Dùng cho 004:T018: sao mẫu này thành `fleet\firmware\{H2S,P1S,A1,A1M}.md` rồi điền. Văn phòng chỉ **khuyến nghị**; nâng hay giữ do người dùng quyết (Buổi F, 004:T020). Không máy nào bị nâng trước câu trả lời đó (hiến chương V).

## Bảng

| Máy | Bản đang chạy | Bản mới | Thay đổi liên quan | Khuyến nghị | Nguồn | Ngày |
|---|---|---|---|---|---|---|
| <mã máy> | <số bản, lấy từ `fleet\inventory.csv`> | <số bản đứng đầu trang lịch sử phát hành, hoặc "không có bản mới"> | <thay đổi ảnh hưởng kết nối OrcaSlicer, plugin mạng Bambu, hiệu chuẩn, in>; chưa đọc thì ghi "chưa đọc ghi chú đầy đủ" | <giữ / nâng / chưa đủ căn cứ> | <URL chính thức; nguồn bên thứ ba ghi rõ "bên thứ ba"> | <YYYY-MM-DD> |

Ví dụ điền (từ `specs\004-bambu-calibration\research.md:9-14`, ngày 2026-11-24, **chưa phải khuyến nghị chính thức**; cột "Khuyến nghị" để người viết 004:T018 quyết):

| Máy | Bản đang chạy | Bản mới | Thay đổi liên quan | Khuyến nghị | Nguồn | Ngày |
|---|---|---|---|---|---|---|
| H2S | 01.03.00.00 | không có (01.03.00.00 đứng đầu trang) | công tắc phát hiện vật lạ, chế độ di chuyển tự do XYZ khi bảo trì, hỗ trợ hotend E3D High-Flow; chưa đọc hết ghi chú, chưa khẳng định có hay không thay đổi ảnh hưởng phần mềm bên thứ ba | | https://wiki.bambulab.com/en/h2s/manual/h2s-firmware-release-history | 2026-11-24 |

## Quy tắc điền

1. Mỗi dòng "Khuyến nghị" phải dẫn được tới ghi chú phát hành chính thức; không có thì ghi "chưa đủ căn cứ".
2. Phải tra riêng thay đổi liên quan kết nối OrcaSlicer và plugin mạng (hiến chương V); chưa tra được thì nói rõ, không để trống.
3. Nguồn bên thứ ba (diễn đàn, GitHub của Orca) ghi "bên thứ ba" và không dùng làm căn cứ duy nhất để khuyến nghị nâng.
4. Bản đang chạy lấy từ `fleet\inventory.csv`, không lấy từ trí nhớ.
5. Không ghi serial hay mã truy cập vào file này.
6. URL và câu trích được kiểm lại ở 004:T019 trước khi trình người dùng.

## Quyết định của người dùng (điền ở Buổi F)

- Quyết định: [ ] giữ  [ ] nâng
- Ngày quyết: ____  Ghi sổ: ____
