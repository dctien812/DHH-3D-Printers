# Tasks: Hoàn tất tinh chỉnh hai Voron

**Input**: `specs\002-voron-tuning\spec.md`, `plan.md`

**Format**: `- [ ] T001 [P] [US1] mô tả kèm đường dẫn — KC: cách kiểm chứng (vai: tên)`. `[P]` là chạy
song song, không chung file. `[Buổi X]` là task chờ người dùng. `[CÓ ĐIỀU KIỆN]` ghi rõ điều kiện
chạy. Trên panel, id là `002-T001`…

**Tests**: Không có bộ test tự động; kiểm chứng bằng đầu ra lệnh chạy thật trên máy, do vai khác
vai viết.

**Lịch (người dùng chốt 2026-11-24)**: hôm trước = Buổi A1, A2, B2, G1, G2 (nạp bo V2.4 trước mọi phép đo trên V2.4); ngày 1 = B1 và C (C chỉ gồm PLA trên 4 máy Bambu); ngày 2 = D1, D2 (hai loại PETG trên 6 máy); ngày 3 = E, F. Phạm vi nhựa: PLA chỉ 4 máy Bambu; PETG cả 6 máy; ABS trên hai Voron, H2S, P1S.

**Quy ước chung**: Trident trước, kiểm xong mới tới V2.4 (FR-008). Mọi ghi lên máy qua
`apply-config.ps1`: `infrastructure-engineer` soạn lệnh kèm hoàn tác, trưởng phòng chạy,
`test-engineer` đối chiếu. Phép đo tự chạy chỉ khi máy báo sẵn sàng và không in (FR-004). Mọi việc
đùn nhựa chờ người dùng. Giá trị chỉnh nằm trong `overrides.cfg`, không SAVE_CONFIG cho PID hay
shaper.

## Phase 1: Setup

- [ ] T001 [P] Viết `scripts\voron\apply-config.ps1`: (1) từ chối khi `print_stats.state` là printing hoặc paused hay klippy khác ready; (2) tải lại file đang có trên máy, so SHA256 với bản làm việc, lệch thì dừng; (3) sao lưu bản gốc vào `config/backups/<ngày>_<lý do>/` trên máy (qua Moonraker) và chép về `fleet\backups\<ngày>_<lý do>\<máy>\`; (4) tham số `-WhatIf` in lệnh dự định và lệnh hoàn tác; (5) in một dòng sổ (ngày, máy, file, băm cũ, băm mới, cách hoàn tác); (6) khởi động lại Klipper và chờ ready. Không dùng SAVE_CONFIG — KC: `-WhatIf` in đủ lệnh và hoàn tác trên cả hai máy (không ghi); T035 và T003 chạy thật (vai: infrastructure-engineer)
- [ ] T002 [P] Viết `scripts\voron\measure.ps1` (từ `scripts\shake_run.ps1`: kiểm idle, G28 nếu cần, `COMPARE_BELTS_RESPONSES FREQ_END=200`, `AXES_SHAPER_CALIBRATION AXIS=X FREQ_END=200`, `AXIS=Y FREQ_END=200`; tham số `-Phase before|after` và `-Condition cold`; mỗi phép so đai chạy 3 lần và lấy trung vị; ghi tên file `ShakeTune_results`, phiên bản Klipper và độ giống đai vào `calibration\voron\<phase>_<máy>.json`; nếu phản hồi G-code không có số % thì lấy từ file kết quả của Shake&Tune, vẫn không được thì trưởng phòng đọc biểu đồ và ghi tay kèm ảnh) và `scripts\calibration\ingest.ps1` (gộp `calibration\entry\cal\*.csv` và, nếu có, `profiles\old_inventory.csv` vào `calibration\voron.csv` và `calibration\bambu.csv` theo `docs\data-formats.md`; từ chối dòng `đo` thiếu nguồn, ngày hoặc cuộn). Không sửa `shake_run.ps1` và `test_speed.ps1` cũ — KC: chạy `measure.ps1` thật ở T005; chạy `ingest.ps1` với entry thiếu nguồn phải báo lỗi, ở T019 (vai: software-engineer)

## Phase 2: Foundational (chặn mọi user story)

- [ ] T034 (sau T001, T002) Rà `scripts\voron\apply-config.ps1` và `scripts\voron\measure.ps1` trước mọi lần chạy lên máy: cổng máy rảnh, so băm, sao lưu hai nơi, hoàn tác, không SAVE_CONFIG, G-code gửi đi chỉ là phép đo không đùn nhựa — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [x] T035 Viết và chạy `tests\apply-config.mock.ps1` dùng `HttpListener` cục bộ giả Moonraker: (1) trạng thái printing, kiểm `apply-config.ps1` từ chối và không gửi lệnh ghi; (2) băm lệch, kiểm script dừng — KC: đầu ra lệnh ghi vào `fleet\verify_002_apply.md`, 2/2 từ chối đúng (vai: test-engineer)
- [ ] T003 (sau T034, T035 và phần Voron của 001:T011) Thử khôi phục trên Trident rồi V2.4: chạy `apply-config.ps1` ghi lại `overrides.cfg` với nội dung y hệt hiện có (không đổi giá trị), rồi hoàn tác từ bản sao lưu vừa tạo; chỉ khi máy rảnh — KC: băm `overrides.cfg` sau hoàn tác bằng băm ban đầu và bằng băm trong bản chụp 001; có bản sao lưu cả trên máy và trong `fleet\backups\`; dòng sổ cho mỗi máy (SC-004) (vai: trưởng phòng)
- [ ] T004 Đối chiếu T003 độc lập: tải `overrides.cfg` hai máy, so với bản trong `fleet\backups\` và với bản chụp 001 — KC: đầu ra lệnh ghi thêm vào `fleet\verify_002_apply.md`, 2/2 băm khớp (vai: test-engineer)
- [ ] T005 Ghi sổ trước, rồi đo "trước" bằng đúng lệnh sẽ dùng sau: `scripts\voron\measure.ps1 -Phase before -Condition cold` trên Trident rồi V2.4, máy nguội, rảnh, 3 lần lấy trung vị; từ đây tới T007 không cập nhật phần mềm host — KC: `calibration\voron\before_TRI.json` và `before_V24.json` có độ giống đai (3 số và trung vị), phiên bản Klipper và tên file shaper X, Y; ghi sổ cạnh số cũ 80,7 % (Trident) và 74 % (V2.4) (vai: trưởng phòng)

**Checkpoint**: công cụ ghi và đo đã được kiểm.

## Phase 3: User Story 1 — Cân đai rồi đo lại cộng hưởng (P1, MVP)

**Goal**: độ giống hai đai tăng, shaper mới an toàn. **Independent Test**: cùng một phép đo, số sau
tốt hơn số trước.

- [ ] T006 [US1] [Buổi B1] Cân lại hai đai và kiểm puly, ổ bi của Trident rồi V2.4, báo "xong" từng máy — KC: người dùng báo xong; trưởng phòng kiểm máy ở trạng thái ready trước khi đo (vai: người dùng)
- [ ] T007 [US1] Ghi sổ trước, rồi đo "sau" bằng `measure.ps1 -Phase after -Condition cold`, Trident rồi V2.4, 3 lần lấy trung vị, cùng phiên bản Klipper với T005 — KC: trung vị độ giống đai sau cao hơn trung vị T005 (tiêu chí cứng, SC-001); từ 90 % trở lên là mục tiêu phấn đấu, không đạt thì ghi rõ chứ không coi là lỗi; số ghi cạnh số cũ (vai: trưởng phòng)
- [ ] T008 [US1] Soạn lệnh đặt shaper mới (tần số và kiểu theo kết quả `after`, giữ kiểu "performance" người dùng đã chọn, `max_freq 200` đã có) vào `overrides.cfg` mỗi máy qua `apply-config.ps1`, kèm hoàn tác; chỉ soạn khi đã có `after_*.json`; phần V2.4 chỉ chạy sau khi Trident qua T009. Nếu kiểu "performance" làm hỏng tiêu chí đồng bộ kích thước của 003 thì ghi vào đề xuất để trình người dùng, không tự đổi kiểu — KC: `-WhatIf` in đúng giá trị; đọc lại sau ghi (vai: infrastructure-engineer)
- [ ] T009 [US1] Chạy lệnh T008 trên Trident, rồi `scripts\test_speed.ps1 -Ip 192.0.2.90 -Name Trident -Accels 10000` (400 mm/s, đúng gia tốc đang đặt); qua, và `test-engineer` đã đối chiếu `overrides.cfg` của Trident (phần Trident của T011), thì làm lại với V2.4 (`-Ip 192.0.2.89`) — KC: đầu ra `PASS` ở 10000 mm/s² cho 2/2 máy (SC-002), `klippy=ready`; mỗi lần ghi có dòng sổ và bản sao lưu (SC-004) (vai: trưởng phòng)
- [ ] T010 [US1] [CÓ ĐIỀU KIỆN: chỉ khi T007 cho số sau không khá hơn số trước trên một máy] Giữ nguyên shaper cũ trên máy đó; ghi nguyên nhân có thể (puly, ổ bi, độ căng chưa đều) để người dùng kiểm; không chạy T008 và T009 cho máy đó — KC: `overrides.cfg` máy đó trùng băm trước đo; dòng sổ nêu lý do (vai: trưởng phòng)
- [ ] T011 [US1] Đối chiếu độc lập: tải `overrides.cfg` hai máy, so giá trị với lệnh T008 và với `after_*.json`; lập bảng trước/sau độ giống đai (T005 và T007) — KC: `fleet\verify_002_shaper.md`, giá trị khớp, số sau tốt hơn số trước hoặc nêu rõ máy không (vai: test-engineer)

**Checkpoint**: US1 xong riêng được.

## Phase 4: User Story 2 — Hiệu chuẩn đùn nhựa theo vật liệu (P2)

**Goal**: mỗi cặp (Voron, nhựa) có số đo hoặc nhãn "chưa đo". **Independent Test**: mẫu chuẩn đạt
tiêu chí 003.

**Thứ tự**: pilot PLA (Buổi C) trước, rồi mới D1, D2, E. Pilot chưa đạt thì không chạy tiếp để
khỏi tốn nhựa.

- [ ] T012 [P] [US2] Tìm cách Orca đưa PA vào Klipper trên hai Voron: `%APPDATA%\OrcaSlicer\user\<id>` (G-code đầu/cuối, hồ sơ vật liệu), `variables.cfg` và macro `START_PRINT` trong bản chụp `fleet\baseline\` (`material_profiles_enabled`) — KC: báo cáo ghi `đường_dẫn:dòng` cho mỗi kết luận (vai: explorer)
- [ ] T037 [US2] (khi V2.4 rảnh, sau T003/T004 và trước Buổi D1; kiểm tra ngày 2026-11-24 cho thấy cả hai máy ĐÃ đặt False, nên task này chỉ còn xác nhận trên bản chụp mới) Thống nhất nguồn PA theo quyết định của người dùng ngày 2026-11-24: PA lấy từ hồ sơ Orca trên cả hai máy. Soạn lệnh qua `apply-config.ps1` đặt `variable_material_profiles_enabled: False` trong `variables.cfg` của V2.4 (như `trident\variables.cfg:192`), kèm hoàn tác; trước đó đối chiếu bản chụp mới của 001:T011 xem V2.4 và Trident đang đặt gì — KC: `-WhatIf` in đúng thay đổi; sau khi trưởng phòng chạy, đọc lại `gcode_macro _USER_VARIABLES` trên hai máy đều cho `material_profiles_enabled = False`; `START_PRINT` không còn gọi `SET_PRESSURE_ADVANCE` từ bảng vật liệu và không còn chặn `MATERIAL=PETG`; có sao lưu và dòng sổ (vai: infrastructure-engineer)
- [ ] T013 [US2] Viết `calibration\guides\voron_<nhựa>.md` cho 3 nhựa (BAMBU-PETG, TIN-PETGECO, TIN-ABSPRO; Voron không test PLA) và `calibration\entry\cal\TEMPLATE_voron.csv`: thứ tự lưu lượng thể tích tối đa, PA, hệ số lưu lượng (nhiệt dùng mặc định, ghi `mặc_định`); mỗi bước ghi số vào `calibration\entry\cal\<ngày>_<máy>_<nhựa>.csv`; ghi điều kiện sấy và cuộn; ABS chỉ buồng đóng, thông gió; cách PA đến Klipper theo T012 — KC: người chưa biết dự án đọc xong làm theo được (checker đọc ở T020) (vai: software-engineer)
- [x] T014 [US2] BỎ theo quyết định của người dùng ngày 2026-11-24 (hai Voron không test PLA; phép thử đầu của Voron là PETG ở T015). Nội dung cũ: Pilot Bambu PLA trắng trên Trident rồi V2.4: nạp nhựa, dọn bàn, in mẫu hiệu chuẩn theo thẻ T013 qua Orca, điền `calibration\entry\cal\<ngày>_<máy>_BAMBU-PLA.csv` kèm ảnh hoặc số đo; sau đó trưởng phòng chạy 003:T028 rồi mới in mẫu chuẩn (003:T015) — KC: có entry cho BAMBU-PLA trên 2 máy, mỗi tham số là số đo hoặc `chưa_đo` (vai: người dùng)
- [ ] T015 [US2] [Buổi D1, nửa 1] Bambu PETG trắng trên hai Voron theo thẻ T013 (lần in thử đầu tiên của hai Voron; pilot PLA trên máy Bambu không chặn bước này) — KC: entry BAMBU-PETG trên 2 máy (vai: người dùng)
- [ ] T016 [US2] [Buổi D2, nửa 1] Tinmorry PETG-ECO trắng trên hai Voron — KC: entry TIN-PETGECO trên 2 máy (vai: người dùng)
- [ ] T017 [US2] [Buổi E, nửa 1] Tinmorry ABS Pro trắng trên hai Voron, buồng đóng, thông gió — KC: entry TIN-ABSPRO trên 2 máy (vai: người dùng)
- [ ] T018 [US2] Giữa hai nửa của mỗi buổi C, D1, D2, E (trong cùng lượt với 003:T028): chạy `scripts\calibration\ingest.ps1` để cập nhật `calibration\voron.csv`; ghi sổ — KC: số dòng `đo` tăng đúng số entry nhận (vai: trưởng phòng)
- [ ] T019 [US2] Kiểm `calibration\voron.csv`: đủ 6 cặp (2 máy × 3 nhựa), mỗi cặp có số đo hoặc `chưa_đo`; thử `ingest.ps1` với entry thiếu nguồn phải bị từ chối; không giá trị ước lượng nào gắn nhãn `đo` (SC-003) — KC: `fleet\verify_002_calib.md` kèm đầu ra lệnh (vai: test-engineer)
- [ ] T020 [US2] (trước T015) Đọc `calibration\guides\voron_*.md` và `scripts\calibration\ingest.ps1`; thẻ ABS phải có phần buồng đóng và thông gió — KC: báo cáo ba mức; thẻ làm theo được, không mâu thuẫn hiến chương VI (vai: checker)

**Checkpoint**: US2 xong riêng được; 004 dùng chung `ingest.ps1`.

## Phase 5: User Story 3 — Gỡ điểm lệch chuẩn còn lại (P3)

**Goal**: không còn điểm lệch chưa xử lý hoặc chưa ghi "hoãn".

- [ ] T021 [P] [US3] Điều tra firmware MCU V2.4 đang chạy Kalico (v2026.04.00) dưới host Klipper chính: đọc phiên bản MCU từ `/printer/objects/query`, `klippy.log` qua `/server/files` (shutdown, CAN retransmit), đối chiếu bộ nhớ `voron-printers-klippain` — KC: kết luận ghi rõ rủi ro đã thấy hay chưa, kèm trích dòng log; nêu nếu chưa có nguồn về tương thích (vai: investigator)
- [ ] T022 [P] [US3] (trước Buổi B1) Đo độ lặp đầu dò Cartographer bằng `PROBE_ACCURACY` trên Trident rồi V2.4 (máy rảnh, không đùn nhựa) — KC: số đo ghi vào sổ; không có ngưỡng chính thức, so giữa hai máy và với lần đo sau (vai: trưởng phòng)
- [ ] T023 [US3] [Buổi B1] [CÓ ĐIỀU KIỆN: chỉ khi T022 cho độ lặp xấu hoặc người dùng yêu cầu; tài liệu không bắt buộc hiệu chuẩn lại] Hiệu chuẩn lại Cartographer Trident trước rồi V2.4 khi người dùng ở cạnh máy; trước đó tải `printer.cfg` về `fleet\backups\` vì lệnh dùng SAVE_CONFIG — KC: `PROBE_ACCURACY` sau không xấu hơn trước; bản sao lưu khôi phục được (vai: trưởng phòng)
- [x] T024 [US3] [Buổi G1] Quyết định việc nạp lại firmware MCU V2.4 bản chính — ĐÃ QUYẾT ngày 2026-11-24: người dùng đồng ý đưa V2.4 về Klipper chính khi triển khai kế hoạch (thay cho mặc định hoãn). Việc nạp vẫn làm ở Buổi G2, có người dùng ở cạnh máy — KC: quyết định ghi sổ (vai: người dùng)
- [ ] T025 [US3] (T024 đã đồng ý) Soạn `docs\mcu-reflash-v24.md`: trước hết chụp cấu hình MCU hiện tại từ máy (tốc độ bus CAN, chế độ cầu CAN, clock, offset bootloader, UUID từng thiết bị); nạp EBB36 qua CAN bằng Katapult trước, Octopus Max qua USB/DFU sau (người dùng cắm USB, vào DFU); mỗi bước kèm lệnh, kiểm trước/sau, cách cứu, và sao lưu `printer.cfg` — KC: mỗi bước có lệnh kiểm; T036 rà trước khi chạy (vai: infrastructure-engineer)
- [ ] T036 [US3] (sau T025) Rà `docs\mcu-reflash-v24.md` trước khi nạp: thứ tự, tham số build khớp cấu hình đã chụp, cách cứu từng bước — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T026 [US3] [Buổi G2] (sau T036) Chạy phần Katapult/CAN theo `docs\mcu-reflash-v24.md` cho EBB36, khi người dùng ở cạnh máy — KC: nhật ký Katapult báo nạp xong; đọc lại phiên bản MCU (vai: trưởng phòng)
- [ ] T027 [US3] [Buổi G2] (sau T026) Nạp Octopus Max qua USB/DFU theo `docs\mcu-reflash-v24.md` — KC: người dùng báo xong và máy lên (vai: người dùng)
- [ ] T028 [US3] (sau T027) Kiểm sau nạp: bo chính và đầu in báo phiên bản cùng dòng với host, CAN 0 retransmit mới, klippy ready (SC-005) — KC: `fleet\verify_002_mcu.md` kèm đầu ra lệnh (vai: test-engineer)
- [ ] T029 [US3] (trước T015) Kiểm tĩnh skew chỉ nạp một lần: đếm `SKEW_PROFILE LOAD` trong macro `START_PRINT` cùng `startprint_actions` (bản chụp 001) và trong G-code đầu của hồ sơ máy DHH Voron ở `profiles\bundle\` (003:T010, T012); tổng phải là 1 cho mỗi máy, và G-code cuối vẫn có `SET_SKEW CLEAR=1` — KC: `fleet\verify_002_skew.md` ghi `đường_dẫn:dòng` từng lần xuất hiện, tổng 1 mỗi máy (vai: test-engineer)
- [ ] T030 [US3] [CÓ ĐIỀU KIỆN: chỉ khi T029 không kết luận được bằng đọc tĩnh] Sau lần in đầu ở Buổi C, đếm `SKEW_PROFILE LOAD` trong `gcode_store` của mỗi Voron — KC: đúng 1 lần nạp mỗi máy, ghi thêm vào `fleet\verify_002_skew.md` (vai: trưởng phòng)
- [ ] T031 [US3] Tổng hợp trạng thái các điểm lệch chuẩn: firmware MCU (đã nạp, hoặc hoãn kèm lý do), Cartographer (số đo), skew (T029) — KC: mỗi điểm có trạng thái và bằng chứng trong sổ (SC-005) (vai: trưởng phòng)

## Phase 6: Polish

- [ ] T032 [P] Rà cuối toàn bộ 002: mọi thay đổi `overrides.cfg` so với bản sao lưu, `calibration\voron.csv`, các file `fleet\verify_002_*.md`; đối chiếu hiến chương II, V, VI — KC: ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T033 Ghi sổ kết quả từng SC, danh sách mục "hoãn" kèm lý do, đề xuất đã phát sinh — KC: dòng sổ có bằng chứng `fleet\verify_002_*.md` (vai: trưởng phòng)

## SC → task

| SC | Task |
|---|---|
| SC-001 | T005, T007, T011 |
| SC-002 | T009, T011 |
| SC-003 | T014..T019, T037 |
| SC-004 | T034, T035, T003, T004, T009 |
| SC-005 | T021..T031, T036 |

## Phụ thuộc chéo đặc tả

- 001:T001 (cây thư mục, `docs\data-formats.md`) → 002:T001, T002.
- 001:T011 (baseline Voron) → 002:T005, T012.
- 001:T016 (`gaps.md`) → 002:T012, T021 để xác nhận phạm vi.
- 003 (STL mẫu chuẩn và bộ hồ sơ PLA tối thiểu cho pilot) → 002:T014 (Buổi C). 003 chỉ dựng đủ 22
  hồ sơ sau khi Buổi C đạt.
- 002:T014 (Buổi C) dùng chung buổi với pilot của 003 và 004.
- 002:T002 (`ingest.ps1`) → 004 chạy cùng script này, không sửa nó.
- 002:T018 (`voron.csv`) → 003 đọc, không sửa.
- 003:T010, T012 (sửa G-code đầu/cuối Voron, cài hồ sơ mới) → 002:T029, chạy trước Buổi C.
- 003:T028 chạy giữa hai nửa mỗi buổi, gồm cả 002:T018.
- 003 (bù cho máy lệch) có thể đòi in lại trên Voron → Buổi F.
