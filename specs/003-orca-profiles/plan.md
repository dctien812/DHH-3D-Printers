# Implementation Plan: Bộ hồ sơ OrcaSlicer chung cho 6 máy

**Branch**: `003-orca-profiles` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: `specs\003-orca-profiles\spec.md`. Thiết kế chung: [../001-fleet-baseline/plan.md](../001-fleet-baseline/plan.md).

## Summary

Hồ sơ mới được sinh bằng script từ ba bảng CSV (máy, quy trình, vật liệu) trên nền bản sao hồ sơ
cũ, chỉ tạo file mới mang tiền tố "DHH". Chạy pilot PLA trên 6 máy trước để thử tiêu chí 0,1 mm,
đạt rồi mới dựng đủ 22 hồ sơ vật liệu; cặp lệch thì bù riêng và in lại cho tới khi đạt.

## Technical Context

**Language/Version**: PowerShell 5.1; hồ sơ Orca là JSON.

**Primary Dependencies**: OrcaSlicer 2.5.2 (thư mục `%APPDATA%\OrcaSlicer\user\<id>`), cơ chế
`inherits` và `compatible_printers`; Orca CLI nếu chạy được (thử ở T011), không thì cắt lớp tay.

**Storage**: `profiles\src\*.csv` là nguồn; `profiles\bundle\` là sản phẩm; `calibration\entry\part\`
và `calibration\results.csv` là kết quả đo.

**Testing**: `test-engineer` dựng ra thư mục tạm và `-Verify`, tính lại độ lệch độc lập từ số thô.

**Constraints**: không sửa, không xóa hồ sơ cũ; cài chỉ khi Orca đóng; dung sai X/Y ±0,1 mm trên
100 mm, Z ±0,1 mm trên 20 mm, lỗ Ø8 ±0,15 mm, áp cho cả ABS.

**Scale/Scope**: 6 hồ sơ máy, 6 quy trình, 22 vật liệu; 28 task.

**Chưa kiểm (giải trong task)**: cấu trúc JSON hồ sơ người dùng của Orca 2.5.2 (T005); đồng bộ
cloud có ghi đè hồ sơ cục bộ không (T001, T014); Orca CLI (T011); nhập Preset Bundle khi Orca
đang mở (T001).

## Constitution Check

| Nguyên tắc | Đánh giá |
|---|---|
| I. Thứ tự ưu tiên | Quy trình "Sync" đặt đồng bộ kích thước trên tốc độ; bù riêng từng cặp. Đạt. |
| II. Thay đổi lên máy | Không ghi lên máy in; chỉ thêm file vào thư mục Orca sau khi đã sao lưu và so băm. Đạt. |
| III. Bambu giữ cloud | Máy Bambu in qua Orca như hiện nay. Đạt. |
| IV. OrcaSlicer | Bộ hồ sơ lưu trong thư mục dự án, nạp lại được (T023). Đạt. |
| V. Cập nhật | Không cập nhật gì. Đạt. |
| VI. Chạy máy | Mọi lần in mẫu do người dùng làm ở các buổi. Đạt. |

## Tiêu chí nghiệm thu

SC-001 đến SC-006 của spec; bảng SC → task ở cuối [tasks.md](tasks.md).

## Lượt có mặt của người dùng (cả 4 đặc tả)

Mỗi buổi in (C, D1, D2, E) có hai nửa: nửa 1 in mẫu hiệu chuẩn và điền số; trưởng phòng đưa số vào
hồ sơ (003:T028, vài phút); nửa 2 in và đo mẫu chuẩn bằng hồ sơ đã có số.

| Buổi | Task | Việc | Thời gian | Nhựa |
|---|---|---|---|---|
| A1 | 001:T002, T007 | Điền mã truy cập và serial vào file cục bộ, xác nhận máy "TTeccS", đọc bảng kiểm kê | 15 phút | 0 |
| A2 | 003:T013; 001:T012 và 004:T001 nếu cần | Đóng rồi mở Orca để thử đồng bộ sau khi cài 18 hồ sơ pilot; chụp màn hình máy nếu đọc qua LAN thiếu; dán ghi chú phát hành của hãng nếu trang bị chặn | 20–30 phút | 0 |
| B1 | 002:T006; T023 nếu cần | Cân đai và kiểm puly Trident rồi V2.4 | 90 phút | 0 |
| B2 | 004:T007 | Bảo trì tay và hiệu chuẩn hãng 4 máy Bambu | 60 phút | 0 |
| C | nửa 1: 002:T014, 004:T011; nửa 2: 003:T015 | Pilot Bambu PLA trắng trên 6 máy, kèm thử A/B cho K | khoảng 4–5 giờ máy chạy | khoảng 0,5 kg |
| D1 | nửa 1: 002:T015, 004:T012; nửa 2: 003:T018 | Bambu PETG trên 6 máy | khoảng 3–4 giờ | khoảng 0,5 kg |
| D2 | nửa 1: 002:T016, 004:T013; nửa 2: 003:T018 | Tinmorry PETG-ECO trên 6 máy | khoảng 3–4 giờ | khoảng 0,5 kg |
| E | nửa 1: 002:T017, 004:T017; nửa 2: 003:T018 | Tinmorry ABS Pro trên 4 máy buồng kín | khoảng 3 giờ | khoảng 0,3 kg |
| F | 003:T018, T019, T025 nếu không có CLI; 004:T020 | In bù, lắp chéo, cắt lớp tay nếu cần, quyết firmware Bambu. Nếu pilot PLA chưa đạt thì buổi F đầu tiên nằm giữa C và D1 | 2 giờ, lặp lại nếu còn cặp chưa đạt | khoảng 0,3 kg, cộng 20–30 g mỗi vòng bù mỗi cặp |
| G1 | 002:T024 | Đã quyết ngày 2026-11-24: đưa V2.4 về Klipper chính | xong | 0 |
| G2 | 002:T026, T027 | Nạp EBB36 rồi Octopus Max, người dùng ở cạnh máy | 60–90 phút | 0 |

Thời gian và lượng nhựa là ước lượng, chưa đo; nên coi 16 giờ có mặt và 2 kg nhựa là mức thấp,
chưa tính các vòng bù thêm.

## Rủi ro

- Mức 0,1 mm trên 100 mm chưa có nguồn nào xác nhận đạt được trên cả 6 máy, nhất là ABS; người
  dùng đã chốt giữ mức và in bù tiếp, nên số vòng bù và lượng nhựa của ABS không có trần. Từ vòng
  thứ 3 của một cặp, trưởng phòng báo số đo và nhựa đã dùng trước khi in tiếp.
- Đồng bộ cloud của Orca có thể ghi đè hoặc xóa hồ sơ cục bộ: thử trực tiếp bằng so băm (T014)
  trước khi dựng đủ bộ; bản nguồn luôn nằm trong thư mục dự án.
- Bản Orca đang dùng có thể thiếu tính năng cho H2S: dựa trên hồ sơ "Bambu Lab H2S 0.4" người
  dùng đang in được.
- Kiểu shaper "performance" trên Voron có thể làm lệch kích thước: nếu vậy trình người dùng.

## Việc khó hoàn tác

- Thử đồng bộ cloud (T013): khi người dùng đăng nhập, Orca có thể đẩy các hồ sơ DHH lên tài khoản
  cloud của họ; đây là dữ liệu đi ra ngoài, người dùng tự làm ở Buổi A2 và có thể xóa trong Orca.
- Thêm file vào thư mục user của Orca (T012, T024): gỡ được bằng cách xóa đúng các file DHH; bản
  sao lưu toàn bộ có từ 001:T003.
- Thử khôi phục (T023) có bước bỏ hồ sơ DHH khỏi Orca: chỉ file DHH, sau khi sao lưu.

## Phần không đụng tới

25 hồ sơ vật liệu, 6 hồ sơ máy và 1 quy trình cũ trong Orca (kể cả TPU, ASA-CF, SUNLU, HUTI); cài
đặt tài khoản và đồng bộ của Orca; cấu hình máy in.

## Project Structure

Tạo `scripts\orca\`, `scripts\models\`, `scripts\calibration\aggregate.ps1`, `profiles\`, `models\`,
`calibration\results.csv`.
