# Bambu A1

[Về trang chính](../../README.md) · [Phiếu cần điền](../../docs/phieu.html) · [Các máy khác](../)

## Tóm tắt

| Mục | Giá trị |
|---|---|
| Mã máy trong dự án | `A1` |
| Loại | Bambu Lab A1, không buồng kín, không AMS |
| Nhựa trong phạm vi | Bambu PLA, Bambu PETG Basic, Tinmorry PETG-ECO (không ABS / ASA) |
| Số hồ sơ vật liệu | 3 |
| Đặc tả liên quan | [004 bambu-calibration](../../specs/004-bambu-calibration/tasks.md), [003 orca-profiles](../../specs/003-orca-profiles/tasks.md) |
| Hồ sơ OrcaSlicer | `DHH A1 0.4` (chưa nạp vào Orca) |
| Trạng thái | Chưa có thay đổi nào lên máy. Chưa đọc được bên trong máy (cần mã truy cập). |

## Đã biết

Nguồn: gói quảng bá của máy trên mạng nội bộ ngày 2026-11-24 ([fleet/precheck/2026-11-24/SUMMARY.md](../../fleet/precheck/2026-11-24/SUMMARY.md)); firmware mới nhất theo wiki của hãng, đọc cùng ngày ([specs/004-bambu-calibration/research.md](../../specs/004-bambu-calibration/research.md)).

| Mục | Giá trị |
|---|---|
| Firmware | 01.09.00.00 (bản mới nhất theo trang của hãng) |
| Kết nối | Chế độ cloud, đã gắn tài khoản |
| AMS | Không có |
| Buồng | Không kín: không in ABS / ASA |

Chưa đọc được: lỗi treo, đầu phun, giờ in, bảo trì đã làm. Cần mã truy cập hoặc ảnh chụp màn hình máy.

## Việc sẽ làm trên máy này

Văn phòng chỉ đọc máy Bambu, không gửi lệnh điều khiển; mọi lần in và hiệu chuẩn trên máy do chủ dự án bấm. Máy giữ cloud và firmware gốc, không tự nâng firmware.

| Khi nào | Việc | Đặc tả |
|---|---|---|
| Hôm trước | Bảo trì tay theo bảng, chạy hiệu chuẩn có sẵn của hãng, ghi lại trạng thái | 004 |
| Ngày 1 | In thử Bambu PLA, đo bằng thước cặp | 004, 003 |
| Ngày 2 | Bambu PETG Basic và Tinmorry PETG-ECO | 004, 003 |
| Ngày 3 | In bù nếu lệch, thử lắp chéo (máy không in ABS / ASA) | 003 |
| Khi có bản mới | Tra ghi chú phát hành, trình chủ dự án quyết nâng hay giữ | 004 |

Hệ số K do máy tự quản lý; hồ sơ DHH của máy Bambu không đặt `pressure_advance` để tránh bù hai lần.

## Thẻ hướng dẫn liên quan

- [bambu_BAMBU-PLA.md](../../calibration/guides/bambu_BAMBU-PLA.md)
- [bambu_BAMBU-PETG.md](../../calibration/guides/bambu_BAMBU-PETG.md)
- [bambu_TIN-PETGECO.md](../../calibration/guides/bambu_TIN-PETGECO.md)
- [MAINTENANCE.md](../../calibration/bambu/MAINTENANCE.md): bảng bảo trì Bambu
- [RUN-DAY.md](../../calibration/guides/RUN-DAY.md): lịch ngày làm

Các thẻ đang được rà, nội dung có thể đổi.

## Cần điền

Điền ở nhóm của máy này trong phiếu [docs/phieu.html](../../docs/phieu.html) (xem [PHIEU-DIEN.md](../../PHIEU-DIEN.md)). Gồm: lỗi / HMS đang treo trên màn hình (ghi mã, hoặc "không có"), đầu phun đang lắp (cỡ, loại), tấm in, tổng giờ in nếu máy hiển thị, lần bảo trì gần nhất.

> [!NOTE]
> Link web của phiếu cần bật GitHub Pages cho repo, hiện **chưa bật**. Cách mở: tải file `docs/phieu.html` về máy tính rồi nháy đúp.

> [!WARNING]
> Không ghi mã truy cập, serial hay mật khẩu vào phiếu hay vào repo.

## Dữ liệu của máy này

| Dữ liệu | Nơi để |
|---|---|
| Bảo trì | [calibration/bambu/MAINTENANCE.md](../../calibration/bambu/MAINTENANCE.md) |
| Hồ sơ OrcaSlicer | tên bắt đầu bằng `DHH`; nguồn ở [profiles/src/](../../profiles/src/) |
| Số hiệu chuẩn và số đo mẫu | [calibration/](../../calibration/) (các dòng có mã `A1`) |
| Bí mật của máy | Chỉ nằm trong `secrets/` trên máy tính, không có trong repo |
