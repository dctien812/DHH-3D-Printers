# Research: firmware, bảo trì và hệ số K của máy Bambu (004:T001, phần web của 004:T002)

Ngày 2026-11-24. Nguồn: wiki chính thức của Bambu Lab, trưởng phòng đọc trực tiếp qua Chrome của
người dùng (người dùng cho phép; công cụ tải tự động bị trang trả mã 402). Chỉ đọc một phần mỗi
trang; chỗ chưa đọc được ghi rõ.

## Firmware — cả 4 máy đang ở bản mới nhất (nguồn chính thức)

| Máy | Đang chạy | Bản đứng đầu trang lịch sử phát hành | Ghi chú của bản đó |
|---|---|---|---|
| H2S | 01.03.00.00 | 01.03.00.00 | thêm công tắc phát hiện vật lạ, chế độ di chuyển tự do XYZ khi bảo trì, hỗ trợ hotend E3D High-Flow, cải thiện ước lượng nhựa còn lại (cần firmware AMS mới) |
| P1S | 01.10.00.00 | 01.10.00.00 (2026-03-30) | in nhiều màu bằng cuộn ngoài, bản vá bảo mật |
| A1 | 01.09.00.00 | 01.09.00.00 (2026-11-09) | cập nhật bảo mật, không cho hiệu chuẩn khi đang in, sửa lỗi màn hình và nạp nhựa |
| A1 Mini | 01.09.00.00 | 01.09.00.00 (2026-11-09) | như A1 |

- https://wiki.bambulab.com/en/h2s/manual/h2s-firmware-release-history
- https://wiki.bambulab.com/en/p1/manual/p1p-firmware-release-history
- https://wiki.bambulab.com/en/a1/manual/a1-firmware-release-history
- https://wiki.bambulab.com/en/a1-mini/manual/a1-mini-firmware-release-history

**Decision**: đợt này không có gì để nâng; 004:T020 chỉ còn là ghi nhận "giữ". Chưa đọc hết ghi chú
từng bản (trang dài), nên chưa khẳng định được không có thay đổi nào liên quan phần mềm bên thứ ba.

## Hệ số K (Flow Dynamics) — nguồn chính thức

https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa

- Kết quả hiệu chuẩn K được **lưu trên máy in**, theo từng bộ tham số có tên; ở trang Device chọn K
  cho từng khe nhựa.
- Tự hiệu chuẩn: dòng X1 (lidar), dòng A1 và H2D (cảm biến dòng xoáy ở đầu in đo lực đùn tại chỗ
  xả nhựa). **P1 chỉ hiệu chuẩn tay** và không có ô "Flow Dynamics Calibration" khi gửi lệnh in.
  Trang chỉ nêu H2D; H2S cùng dòng nên nhiều khả năng giống, nhưng đó là suy ra.
- Ô "Flow Dynamics Calibration" khi gửi lệnh in có ba mức: Auto (dùng lại kết quả gần đây nếu nhựa
  và đầu phun không đổi, có đổi thì đo lại), On (đo trước mỗi lần in), Off (dùng K người dùng đặt
  tay cho khe đó; không có thì dùng giá trị mặc định).
- Đầu phun 0,2 mm tự hiệu chuẩn hay sai (không liên quan, cả dàn dùng 0,4).
- Nên hiệu chuẩn lại khi đổi hãng nhựa, đổi hoặc mòn đầu phun, đổi lưu lượng tối đa hay nhiệt in.

**Decision cho kế hoạch**: với máy Bambu, nguồn K là máy in, không phải hồ sơ Orca. Hồ sơ DHH cho
máy Bambu KHÔNG đặt `pressure_advance`; P1S đặt K tay trên máy sau khi hiệu chuẩn tay; H2S, A1, A1
Mini dùng mức Auto. Phép thử A/B ở 004:T011 vẫn giữ để xác nhận OrcaSlicer với plugin OpenBambu
gửi lựa chọn này đúng như Bambu Studio (trang của hãng không nói về Orca).

## Bảo trì — nguồn chính thức

- **H2S** (https://wiki.bambulab.com/en/h2s/maintenance/period-maintenance), chỉ dùng chức năng in:
  ray X mỗi tháng (lau, tra dầu); trục Y, trục Z và vít me mỗi 3 tháng (dầu cho trục trơn, mỡ cho
  vít me); bàn nhiệt, đầu in, các camera, cảm biến lửa, quạt phụ, lọc than, lưới thoát khí mỗi 3
  tháng; bánh răng đùn kiểm hằng tuần; dao cắt nhựa kiểm sau 3–5 cuộn; rút nguội hotend sau 5 cuộn.
  Máy tự ước lượng độ bẩn và nhắc bảo trì.
- **P1S** (https://wiki.bambulab.com/en/p1/maintenance/p1p-maintenance): thanh carbon trục X lau
  bằng IPA mỗi tháng, KHÔNG tra mỡ; ba vít me Z lau và tra mỡ mỗi 3 tháng; trục trơn Y và Z kiểm mỗi
  tháng. Phần còn lại của trang chưa đọc.
- **A1** (https://wiki.bambulab.com/en/a1/maintenance/basic-maintenance): dầu cho ray X và ray Y
  (hãng đã đổi từ mỡ sang dầu cho ray Y), mỡ cho vít me và bánh răng đùn; cấm tra mỡ lên ray X.
  Chu kỳ cụ thể chưa đọc được.
- **A1 Mini** (https://wiki.bambulab.com/en/a1-mini/maintenance/period-maintenance): lau và tra dầu
  ray X, ray Z. Chu kỳ cụ thể chưa đọc được.
- Trang chung về hiệu chuẩn trên máy: https://wiki.bambulab.com/en/general/printer-calibration
  (chưa đọc). Hướng dẫn căng đai A1: https://wiki.bambulab.com/en/a1/maintenance/belt_tension.

## Còn thiếu (đọc tiếp qua Chrome khi viết phiếu sức khỏe, 004:T006)

Chu kỳ bảo trì của A1 và A1 Mini; danh sách bước hiệu chuẩn có sẵn trên từng máy; giới hạn số hồ
sơ K lưu trên máy; ghi chú đầy đủ của các bản firmware.
