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

**Scale/Scope**: 2 máy, 4 nhựa (8 cặp), 37 task trong đó 8 task có điều kiện (T010, T023,
T025–T028, T030, T036).

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

## Rủi ro

- Cân đai không cải thiện độ giống (puly, ổ bi): giữ shaper cũ, báo người dùng (T010).
- Mục tiêu đai 110 Hz trên nhịp 150 mm là của tài liệu Voron; chưa có nguồn riêng cho gantry
  Monolith 2WD, nên so sánh trước và sau là tiêu chí chính.
- MCU Kalico dưới host Klipper chính: chưa có nguồn về tương thích; T021 điều tra trên log thật.
- Người dùng sửa cấu hình trong Mainsail giữa chừng: `apply-config.ps1` dừng khi băm lệch.
- Nạp firmware hỏng làm máy không lên: có cách cứu qua DFU và Katapult, ghi UUID trước (T025).

## Việc khó hoàn tác

- Nạp firmware MCU V2.4 (T026, T027): người dùng đã đồng ý (2026-11-24);
  sau khi chụp cấu hình MCU hiện tại, `checker` rà hướng dẫn (T036), và người dùng ở cạnh máy (G2).
- Hiệu chuẩn lại Cartographer dùng SAVE_CONFIG (T023): chỉ khi cần, có người dùng ở cạnh, sao lưu
  `printer.cfg` trước.
- Ghi `overrides.cfg` (T009): hoàn tác được bằng bản sao lưu, đã thử ở T003.

## Phần không đụng tới

PID, skew, `max_accel` và các sửa START_PRINT của đợt 11-09 / 11-10; phần mềm host; firmware
Trident; mọi thứ của máy Bambu.

## Project Structure

Tạo `scripts\voron\`, `scripts\calibration\ingest.ps1`, `calibration\voron\`,
`calibration\guides\voron_*.md`, `fleet\backups\`, `tests\`, và `docs\mcu-reflash-v24.md` nếu có.
