# Research: hồ sơ OrcaSlicer (003:T001, T005; phần Orca của 003:T009, 002:T012, 004:T002)

Ngày 2026-11-24. Nguồn: hai báo cáo của 04 Trinh sát (đọc file trên máy; tra web), trưởng phòng
kiểm lại các dòng đánh dấu "đã kiểm". Bản chụp cấu hình Voron dùng ở đây là bản ngày 11-09 trong
`v24\` và `trident\`; phải đối chiếu lại với bản chụp mới của 001:T011.

## Cấu trúc hồ sơ người dùng (đọc trên máy)

- **Decision**: script chỉ sinh file `.json`, không sinh `.info`, không ghi `setting_id`, `user_id`,
  `base_id`. Mỗi hồ sơ có `from: "User"`, `name`, `inherits` trỏ đúng tên hồ sơ hệ thống, khóa id
  theo loại (`printer_settings_id`, `filament_settings_id`, `print_settings_id`), `version`, và chỉ
  các khóa cần ghi đè.
- **Rationale**: hồ sơ hiện có đều là JSON vài chục dòng chỉ ghi đè khóa. Theo nguồn web, hồ sơ
  không có `.info` được Orca coi là mới và tự tạo `.info`; wiki khuyên không tự ghi `setting_id`.
- **Alternatives considered**: sinh cả `.info` theo mẫu "create" (đề xuất của lượt đọc file) — để
  dự phòng nếu phép thử ở Buổi A2 cho thấy hồ sơ không `.info` không được nhận.
- Hồ sơ máy của người dùng kế thừa "Voron 2.4 300 0.4 nozzle", "Bambu Lab H2S 0.4 nozzle",
  "Bambu Lab P1S 0.4 nozzle", "Bambu Lab A1 0.4 nozzle", "Bambu Lab A1 mini 0.4 nozzle". Orca có
  hồ sơ hệ thống cho cả 4 máy Bambu (tên có trong `system\BBL.opc`).
- Hồ sơ vật liệu hệ thống có sẵn: "Bambu PLA Basic @BBL H2S", "… @BBL P1S 0.4 nozzle", "… @BBL A1",
  "… @BBL A1M"; "Bambu PETG HF" cho cả 4 máy; "Bambu PETG Basic" cho H2S, A1, A1M (P1S không thấy).
  Hồ sơ cũ của người dùng kế thừa "Generic …".
- `compatible_printers` chỉ có ở 5 hồ sơ cũ; bộ mới PHẢI ghi khóa này cho mọi hồ sơ vật liệu và
  quy trình để mỗi cặp chỉ hiện một hồ sơ.
- Trường số: `pressure_advance` + `enable_pressure_advance`, `filament_flow_ratio`,
  `filament_max_volumetric_speed`, `filament_shrink`.
- Số có sẵn để kế thừa: co ngót XY Tinmorry ABS Pro 99,39 % (V2.4) và 99,6 % (Trident); flow 0,965
  và lưu lượng tối đa 22 (V2.4), 18 (Trident) cho ABS; PLA flow 0,96–0,97 và lưu lượng 15–18 trên
  A1, A1 Mini, P1S; PETG-ECO lưu lượng 12–13 trên A1, A1 Mini.
- Orca có file chạy `C:\Program Files\OrcaSlicer\orca-slicer.exe`; thử CLI ở T011. File cấu hình ghi
  phiên bản "2.5.1" trong khi người dùng nói 2.5.2: kiểm lại ở T011 (About trong Orca).

## Đồng bộ cloud và cách cài (tra web, mức chắc chắn vừa)

- **Decision**: ở Buổi A2, người dùng tắt Preferences → "Auto sync user presets" trước khi cài 18
  hồ sơ pilot, mở Orca hai lần để so băm (T014), rồi quyết bật lại hay không.
- **Rationale**: PR #16811 của OrcaSlicer (chưa merge tính đến 2026-11-14) mô tả lỗi làm file chép
  tay bị xóa cục bộ ở lần mở đầu; chưa rõ 2.5.2 có dính không. Bản nguồn luôn nằm trong
  `profiles\bundle\` nên mất thì cài lại được.
- Định dạng bundle: `.orca_printer`, `.orca_filaments`, `.zip`. Chưa có nguồn: nhập trùng tên ghi
  đè hay hỏi; nhập khi Orca đang mở. Thử ở Buổi A2.
- H2S: một nguồn (PR #10780) nói in qua Orca cần LAN + Developer Mode; người dùng xác nhận ngày
  2026-11-24 rằng với plugin OpenBambu vẫn in H2S qua cloud bình thường, nên giữ nguyên kế hoạch.
- H2S có đầu phun high flow thì Orca có thể dùng thông số high flow khi cắt lớp (issue #11711):
  kiểm loại đầu phun H2S ở bảng kiểm kê.

## Phát hiện về hai Voron (bản chụp 11-09, phải kiểm lại)

- G-code đầu của hồ sơ máy Voron chỉ gọi `START_PRINT …`; không còn `SKEW_PROFILE`. Skew được nạp
  một lần qua `startprint_actions` trong `overrides.cfg`. Nếu bản chụp mới xác nhận, điểm "nạp skew
  hai lần" của 002:US3 đã hết và 002:T029 chỉ còn là ghi nhận.
- **Nguồn PA trên Voron đang không thống nhất** (đã kiểm): `start_print.cfg:81–90,146–150` đặt PA
  từ bảng `material_parameters` khi `material_profiles_enabled` bật. Trident đặt
  `material_profiles_enabled: False` (`trident\variables.cfg:192`); V2.4 không đặt nên mặc định là
  bật, đồng thời hồ sơ Orca của V2.4 cũng có `pressure_advance 0.0256`. Cần một nguồn PA duy nhất
  cho mỗi máy, giống quy tắc K của Bambu.
- **PETG trên V2.4 có thể bị START_PRINT chặn**: khi `MATERIAL` không có trong bảng, macro báo lỗi
  (`start_print.cfg:85–87`). Theo lượt đọc file, bảng của V2.4 có PLA, PET, ABS, TPU, ASA, ASA-CF
  nhưng không có PETG; bảng của Trident có PETG. Trưởng phòng chưa tự kiểm được danh sách khóa.

**Cập nhật 2026-11-24 (đọc máy thật, `fleet\precheck\2026-11-24\SUMMARY.md`)**: cả hai máy đang đặt
`material_profiles_enabled = False`, nên nhận định "V2.4 mặc định bật" ở trên là sai; PA hiện đã chỉ
đến từ G-code của Orca (đang là 0,02 khi in PETG). Bảng vật liệu của V2.4 đúng là không có PETG
nhưng không còn chặn vì bảng đã tắt. 002:T037 chỉ còn là bước xác nhận.

## Việc phải đưa vào tasks

1. 002:T037 — người dùng chốt ngày 2026-11-24: PA lấy từ hồ sơ Orca trên cả hai máy; tắt bảng vật
   liệu của Klippain trên V2.4 khi máy rảnh.
2. 002: bảo đảm V2.4 in được PETG trước Buổi D1 (hết ngay nếu chọn tắt bảng vật liệu).
3. 003:T004/T006: ghi `compatible_printers` cho mọi hồ sơ; không sinh `.info`.
4. 003:T013: thêm bước tắt "Auto sync user presets" trước khi cài; thử nhập bundle trùng tên.
