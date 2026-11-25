# Implementation Plan: Hoàn tất tinh chỉnh hai Voron

**Branch**: `002-voron-tuning` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: `specs\002-voron-tuning\spec.md`. Thiết kế chung: [../001-fleet-baseline/plan.md](../001-fleet-baseline/plan.md).

## Summary

Dựng một cổng ghi cấu hình duy nhất có sao lưu (`apply-config.ps1`) và một phép đo lặp lại được
(`measure.ps1`), đo trước, người dùng cân đai, đo sau và đặt lại shaper; hiệu chuẩn PA, hệ số lưu
lượng, lưu lượng tối đa cho 4 nhựa trên hai máy; xử lý các điểm lệch chuẩn (firmware MCU Kalico
trên V2.4, Cartographer, skew nạp hai lần).

## Technical Context

**Language/Version**: PowerShell 5.1; G-code và macro Klippain/Shake&Tune trên máy.

**Primary Dependencies**: Moonraker HTTP :7125 (không xác thực trong LAN); `scripts\shake_run.ps1`
và `scripts\test_speed.ps1` của đợt trước (dùng lại, không sửa); Katapult nếu nạp firmware.

**Storage**: `calibration\voron\*.json`, `calibration\voron.csv`, `fleet\backups\`.

**Testing**: `test-engineer` đối chiếu trên máy thật; `tests\apply-config.mock.ps1` giả Moonraker
để chứng minh cổng "đang in thì từ chối".

**Constraints**: Trident trước, V2.4 sau; chỉ chạm máy khi rảnh; giá trị nằm trong `overrides.cfg`.

**Scale/Scope**: 2 máy, 3 nhựa (6 cặp; Voron không test PLA), 54 task (37 ở bản đầu, thêm T038–T054 ngày 2026-11-25), trong đó 11 task có điều kiện (T010, T023,
T025–T028, T030, T036, T047, T053; T048–T050 chờ điều kiện chủ máy xác nhận trần và in zeroing tool).

**Firmware MCU V2.4**: người dùng quyết ngày 2026-11-24 sẽ đưa V2.4 về Klipper chính khi triển khai
kế hoạch (không tìm được nguồn nào nói MCU Kalico dưới host Klipper chính là được hỗ trợ). Trình tự:
T021 đọc log, T025 soạn hướng dẫn và chụp cấu hình MCU, T036 rà, rồi nạp ở Buổi G2 có người dùng ở
cạnh máy (EBB36 qua CAN, Octopus Max qua USB/DFU).

**Chưa kiểm (giải trong task)**: endpoint sao chép file của Moonraker để sao lưu trên máy (T001);
định dạng phản hồi độ giống đai của Shake&Tune trong `gcode_store` (T002); cú pháp shaper trong
`overrides.cfg` hiện tại (T008); START_PRINT có đùn nhựa không (T029).

## Constitution Check

| Nguyên tắc | Đánh giá |
|---|---|
| I. Thứ tự ưu tiên | Shaper mới chỉ áp khi phép thử mất bước qua; không khá hơn thì giữ cũ. Đạt. |
| II. Thay đổi lên máy | Mọi lần ghi qua `apply-config.ps1`: máy rảnh, so băm, sao lưu hai nơi, dòng sổ, hoàn tác. Đạt. |
| III, IV | Không liên quan máy Bambu; hồ sơ Orca do 003 xử lý. Đạt. |
| V. Cập nhật | Không cập nhật host trong đặc tả này; firmware MCU hỏi riêng (T024). Đạt. |
| VI. Chạy máy | Đo cộng hưởng, thử tốc độ, PROBE_ACCURACY tự chạy khi rảnh; mọi việc đùn nhựa ở các buổi của người dùng. Đạt. |

## Tiêu chí nghiệm thu

SC-001 đến SC-005 của spec; bảng SC → task ở cuối [tasks.md](tasks.md).

Bổ sung 2026-11-25 (T038–T054, điều chỉnh trong phạm vi đã duyệt; tasks.md nay có 54 task, Scale/Scope
đã cập nhật), mỗi bước có phép đo riêng:
- QGL V2.4 (T038–T040): range đầu và retries trước/sau vuông giàn; lần QGL cuối ≤ 0,009 mm sau heat-soak.
- rotation_distance (T041–T043): sai số trung vị ≤ 0,5 % trên 100 mm, hai máy.
- Lớp đầu (T044–T045): độ dày 5 điểm cho 6 cặp máy × nhựa, ngưỡng ±0,03 mm là đề xuất chưa có nguồn.
- Dòng và nhiệt (T046–T047): % dòng định mức so dải 40–70 %, cờ ot/otpw, nhiệt vỏ động cơ.
- Căng đai Monolith (T048–T051): chênh A/B ≤ 10 % bằng Belter đã hiệu chuẩn; độ giống đai Shake&Tune
  không giảm qua từng bước; mức tuyệt đối chỉ là số đo nội bộ.
- TEST_SPEED (T052–T053): giới hạn bằng 0,85 lần nấc cao nhất PASS 5/5; chỉ hạ, không nâng.
- Đối chiếu độc lập: T054.

## Rủi ro

- Cân đai không cải thiện độ giống (puly, ổ bi): giữ shaper cũ, báo người dùng (T010).
- Mục tiêu đai 110 Hz trên nhịp 150 mm là của tài liệu Voron; chưa có nguồn riêng cho gantry
  Monolith 2WD, nên so sánh trước và sau là tiêu chí chính.
- MCU Kalico dưới host Klipper chính: chưa có nguồn về tương thích; T021 điều tra trên log thật.
- Người dùng sửa cấu hình trong Mainsail giữa chừng: `apply-config.ps1` dừng khi băm lệch.
- Nạp firmware hỏng làm máy không lên: có cách cứu qua DFU và Katapult, ghi UUID trước (T025).
- Căng đai quá mức tạo tải trước lên ray Y MGN9 (FAQ Monolith), làm mòn và rít; chưa có số tuyệt đối
  chính thức của Monolith cho đai GT2 9 mm. Số tham khảo (Voron 110 Hz/150 mm với đai 6 mm; Luke's
  Lab factor 1,0 → 158,5 Hz / 26,7 N, 1,5 → 194 Hz / 40 N) không phải chỉ tiêu; đi từ mốc hiện tại
  tăng từng bước, trần đề xuất factor 1,5 (≈ 40 N / ≈ 194 Hz) chờ chủ máy xác nhận trước T050, và
  dừng theo MỘT điều kiện dừng duy nhất ở T050 (T051 dùng lại, không có tiêu chí chốt thứ hai). Shake&Tune chỉ so A với B (T050, T051).
- N đo bằng Belter (công thức T = 23,51 / (dmax − d)^1,2283) và N của máy tính Luke's Lab là hai phép
  khác nhau, chưa kiểm chứng tương quan; mốc 2026-11-25 đo theo gốc zero chưa hiệu chuẩn nên không đổi
  ra N. Chưa in zeroing tool thì T049 không chạy (T048).
- Dòng động cơ: V2.4 0,8 A; dòng định mức chưa biết; `autotune_tmc` có thể đang tự đặt dòng, và
  TMC2209 không báo nhiệt độ, nên nhiệt chỉ có từ nhiệt kế (T046). Không nâng dòng khi chưa có số nhiệt.
- Hạ giới hạn tốc độ sau TEST_SPEED làm hai máy lệch nhau (Đồng bộ); chủ máy quyết dùng chung giá
  trị thấp hơn hay không (T053).
- Vuông giàn và đo đai chồng lên T006; thứ tự V2.4 là T039 trước T050 để không phải căng đai hai lần.

## Việc khó hoàn tác

- Nạp firmware MCU V2.4 (T026, T027): người dùng đã đồng ý (2026-11-24);
  sau khi chụp cấu hình MCU hiện tại, `checker` rà hướng dẫn (T036), và người dùng ở cạnh máy (G2).
- Hiệu chuẩn lại Cartographer dùng SAVE_CONFIG (T023): chỉ khi cần, có người dùng ở cạnh, sao lưu
  `printer.cfg` trước.
- Ghi `overrides.cfg` (T009): hoàn tác được bằng bản sao lưu, đã thử ở T003.
- Vuông giàn V2.4 (T039) và căn đai (T050): tháo lắp cơ khí, hỏi riêng người dùng (hiến chương II);
  hoàn tác bằng cách trả về nấc và số đo đã ghi, không có bản sao lưu tự động.
- Đổi `rotation_distance` (T042), `run_current` (T047), `max_velocity`/`max_accel` (T053): ghi qua
  `apply-config.ps1`, hoàn tác bằng bản sao lưu. `max_accel` là giá trị của đợt
  11-09 / 11-10 (mục "Phần không đụng tới" đã ghi ngoại lệ này): T053 chỉ hạ và cần chủ máy duyệt trước khi áp.

## Phần không đụng tới

PID, skew và các sửa START_PRINT của đợt 11-09 / 11-10 (`max_accel` đã đặt ở đợt đó chỉ được HẠ
bởi T053 sau khi chủ máy duyệt, không nâng); phần mềm host; firmware
Trident; mọi thứ của máy Bambu.

## Project Structure

Tạo `scripts\voron\`, `scripts\calibration\ingest.ps1`, `calibration\voron\`,
`calibration\guides\voron_*.md`, `fleet\backups\`, `tests\`, và `docs-internal\mcu-reflash-v24.md` nếu có.
