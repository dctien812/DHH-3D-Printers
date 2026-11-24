# Tasks: Kiểm kê và đường cơ sở dàn 6 máy in

**Input**: `specs\001-fleet-baseline\spec.md`, `plan.md`

**Format**: `- [x] T001 [P] [US1] mô tả kèm đường dẫn — KC: cách kiểm chứng (vai: tên)`. `[P]` là chạy
song song được, không chung file với task cùng đợt. `[Buổi X]` là task chờ người dùng ở cạnh máy
hoặc máy tính. `[CÓ ĐIỀU KIỆN]` ghi rõ điều kiện chạy. Trên panel, id là `001-T001`…

**Tests**: Dự án không có bộ test tự động. Kiểm chứng bằng đầu ra lệnh chạy thật so với máy, do
vai khác vai viết.

## Phase 1: Setup

- [x] T001 [P] Tạo cây thư mục `fleet\`, `fleet\baseline\`, `fleet\firmware\`, `secrets\`, `profiles\`, `calibration\entry\cal\` (số hiệu chuẩn), `calibration\entry\part\` (số đo mẫu chuẩn), `calibration\guides\`, `calibration\bambu\`, `calibration\voron\`, `models\`, `tests\`, `scripts\{lib,fleet,voron,bambu,orca,calibration,models}\`. Viết `docs\data-formats.md` (ba bảng: kiểm kê, số hiệu chuẩn dạng dọc, kết quả mẫu, cùng quy tắc `trạng_thái` đo/kế_thừa/mặc_định/chưa_đo). Viết mẫu `secrets\bambu.local.json` chỉ có khóa trống và `secrets\README.md` — KC: `Get-ChildItem -Recurse` liệt kê đủ cây; mẫu secrets chỉ chứa khóa rỗng; `data-formats.md` có đủ ba bảng với đủ cột (vai: software-engineer)
- [ ] T002 [US2] [Buổi A] Điền mã truy cập và serial của 4 máy Bambu vào `secrets\bambu.local.json` (sau T001). Xác nhận "TTeccS A1 Mini" thuộc phạm vi — KC: `bambu-read.ps1` (T009) đọc được file mà không in nội dung ra màn hình; người dùng trả lời về TTeccS (vai: người dùng)

## Phase 2: Foundational (chặn mọi user story)

- [x] T003 Viết `scripts\lib\Fleet.psm1` (chỉ `GET` tới Moonraker `/printer/info`, `/printer/objects/query`, `/server/files/*`; phân tích gói SSDP udp 2021; hàm kiểm máy idle; hàm SHA256) và `scripts\fleet\backup-orca.ps1` (chép nguyên vẹn `%APPDATA%\OrcaSlicer\user` vào `profiles\orca_backup\2026-11-24\` kèm `manifest.sha256`, chỉ đọc nguồn). Không hàm nào in serial hay mã truy cập — KC: chạy `backup-orca.ps1` thật, ra manifest; T004 kiểm lại (vai: software-engineer)
- [x] T004 Chạy thật và đối chiếu T003: (1) so SHA256 từng file của `profiles\orca_backup\2026-11-24\` với nguồn, đếm đệ quy đúng 6 hồ sơ máy, 25 vật liệu (gồm thư mục con `filament\base\`), 1 quy trình; (2) tìm `-Method Post|Put|Delete` và `PUBLISH` trong `scripts\lib\Fleet.psm1`, phải rỗng; (3) gọi hàm Moonraker thật trên `192.0.2.90`, `.89` lấy `klippy_state` — KC: đầu ra lệnh ghi vào `fleet\verify_001_foundation.md`, 0 file lệch băm, 0 dòng cấm, 2/2 máy báo state (vai: test-engineer)

**Checkpoint**: nền xong, các user story bắt đầu.

## Phase 3: User Story 1 — Bảng kiểm kê một chỗ cho cả 6 máy (P1, MVP)

**Goal**: một file bảng đủ 6 máy. **Independent Test**: so từng dòng với máy tự báo.

- [ ] T005 [US1] Viết `scripts\fleet\inventory.ps1`: gọi Moonraker (2 Voron: địa chỉ, host, phiên bản Klipper, bàn từ `toolhead.axis_maximum`, đầu phun từ `configfile`), nghe SSDP (4 Bambu: địa chỉ, mẫu, firmware, tên), lấy MAC bằng ARP, ghi `fleet\inventory.csv` và `fleet\inventory.md` theo `docs\data-formats.md`, mỗi số có nguồn và ngày; máy không trả lời ghi "không trả lời" kèm giờ và vẫn ghi các máy khác. Không ghi serial — KC: chạy với một IP sai thay một máy, ra 6 dòng với dòng sai ghi "không trả lời"; chạy bình thường ra 6 dòng đủ trường (vai: software-engineer)
- [ ] T006 [US1] Chạy `scripts\fleet\inventory.ps1` thật, ghi sổ một dòng — KC: `fleet\inventory.csv` có 6 dòng đủ cột FR-001 (vai: trưởng phòng)
- [ ] T007 [US1] [Buổi A] Đọc `fleet\inventory.md`, báo dòng sai (đầu phun, bàn, AMS, tên máy) — KC: người dùng trả lời "không sai" hoặc nêu dòng sai (vai: người dùng)
- [ ] T008 [US1] Kiểm ngẫu nhiên 3 trường mỗi máy bằng cách đọc lại trực tiếp (Moonraker GET, SSDP lần hai), đối chiếu `fleet\inventory.csv`; trường chỉ có trên màn hình máy thì hỏi người dùng qua trưởng phòng — KC: `fleet\verify_001_inventory.md`, 18/18 khớp hoặc liệt kê lệch (vai: test-engineer)

**Checkpoint**: US1 dùng được độc lập.

## Phase 4: User Story 2 — Đường cơ sở trạng thái và sức khỏe (P2)

**Goal**: bản chụp từng máy trước khi tối ưu. **Independent Test**: 3 thông số ngẫu nhiên đọc lại khớp.

- [ ] T009 [P] [US2] Viết `scripts\fleet\snapshot-voron.ps1` (tải toàn bộ file cấu hình người dùng qua `/server/files`, ghi `fleet\baseline\<ngày>\<máy>\config\` kèm `manifest.sha256`, và `configfile settings` thành `fleet\baseline\<ngày>\<máy>\calib.json`; không ghi đè bản ngày trước, không đụng `orig`, `recheck`, `v24`, `trident`) và `scripts\fleet\bambu-read.ps1` (kết nối MQTT 8883 bằng mã trong `secrets\`, mặc định CHỈ subscribe topic report, ghi `status.json` vào `fleet\baseline\<ngày>\<máy>\`; tham số `-AllowPushAll` tắt mặc định, khi bật chỉ gửi đúng một gói pushall; không in serial hay mã truy cập; lọc serial, `tag_uid` và tên file in khỏi dữ liệu trước khi ghi `status.json`; ghi mọi gói PUBLISH đã gửi vào `publish.log` cùng thư mục) — KC: T013 rà trước khi chạy với mã thật; T011 chạy thật; T014 kiểm (vai: software-engineer)
- [ ] T010 [US2] [CÓ ĐIỀU KIỆN: chỉ khi chạy chỉ-subscribe ở T011 không đủ dữ liệu; người dùng đã cho phép pushall ngày 2026-11-24] Chạy lại `bambu-read.ps1 -AllowPushAll` cho máy thiếu dữ liệu, ghi sổ rằng đây là yêu cầu trạng thái, không phải lệnh điều khiển — KC: `status.json` có firmware, đầu phun, lỗi treo, AMS; tình trạng máy (nhiệt, in hay không in) không đổi trước và sau (vai: trưởng phòng)
- [ ] T011 [US2] Chạy `snapshot-voron.ps1` thật (Trident rồi V2.4; chạy ngay, không chờ Bambu). Sau khi T002 và T013 xong: chạy `bambu-read.ps1` trên một máy trước, được thì chạy đủ 4 máy; máy đang in thì ghi rõ số lấy lúc đang in. Máy Bambu bị từ chối hoặc thiếu dữ liệu thì sang T010, vẫn thiếu thì T012 — KC: `fleet\baseline\2026-11-24\` có 2 thư mục Voron kèm manifest và 4 thư mục Bambu kèm `status.json` hoặc ghi "chưa đủ" (vai: trưởng phòng)
- [ ] T012 [US2] [Buổi A] [CÓ ĐIỀU KIỆN: chỉ máy Bambu mà T010 và T011 vẫn thiếu] Chụp màn hình máy: firmware, đầu phun, lỗi/HMS đang treo, AMS (H2S), tổng giờ in; lưu vào `fleet\baseline\2026-11-24\<máy>\screens\` — KC: mỗi máy thiếu có ảnh các mục trên (vai: người dùng)
- [ ] T013 [US2] (trước phần Bambu của T011) Rà `bambu-read.ps1` và `Fleet.psm1`: không PUBLISH khi không có `-AllowPushAll`, khi có thì chỉ đúng gói pushall và có ghi `publish.log`; xử lý chứng chỉ TLS tự ký; serial, `tag_uid`, tên file in và mã truy cập không ra màn hình hay file ngoài `secrets\`. Sau T011: quét bí mật trên toàn thư mục dự án (không tính `secrets\`) bằng so khớp im lặng, không in giá trị ra báo cáo — KC: kết quả quét là không có; báo cáo ba mức (vai: security-auditor)
- [ ] T014 [P] [US2] Đối chiếu baseline: so SHA256 file trong `fleet\baseline\2026-11-24\<máy>\config\` với file đang trên máy (SC-002); chọn ngẫu nhiên 3 thông số một máy trong `calib.json` rồi đọc lại trực tiếp; kiểm trạng thái 4 máy Bambu trước và sau lần đọc (SC-003) — KC: `fleet\verify_001_baseline.md`, 0 lệch băm, 3/3 thông số khớp, 0 thay đổi trạng thái (vai: test-engineer)
- [ ] T015 [P] [US2] Viết `fleet\baseline\2026-11-24\done_before.md`: PID, skew, shaper, cập nhật phần mềm đã xong 11-09 và 11-10 (chỉ ghi trạng thái và trỏ tới bộ nhớ `voron-printers-klippain` và các thư mục `orig`, `recheck`, `skew`, `shaper`, `pid_*.json`, không đo lại) — KC: mỗi dòng có đường dẫn bằng chứng tồn tại (vai: software-engineer)

**Checkpoint**: US2 có bản chụp 6 máy; chặn bởi T011.

## Phase 5: User Story 3 — Danh sách khoảng trống (P3)

- [ ] T016 [US3] Viết `fleet\gaps.md` từ `inventory.csv`, `baseline\`, `done_before.md` và `profiles\old_inventory.csv` (nếu đã có từ 003): mỗi mục gồm máy, hiện trạng, mức ảnh hưởng theo thứ tự Tin cậy > Đồng bộ > Chất lượng > Tốc độ, đặc tả xử lý (002, 003 hoặc 004), dòng dẫn tới số liệu — KC: mỗi mục dẫn được tới một dòng của baseline hoặc inventory (vai: software-engineer)

## Phase 6: Polish

- [ ] T017 [P] Rà toàn bộ script và tài liệu của 001 (`Fleet.psm1`, `backup-orca.ps1`, `inventory.ps1`, `snapshot-voron.ps1`, `bambu-read.ps1`, `gaps.md`) và đối chiếu hiến chương I, II, III, IV, VI; lấy 5 mục ngẫu nhiên của `gaps.md` dò ngược về số liệu — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T018 Ghi sổ: kết quả từng SC, việc dùng pushall, các số liệu lấy lúc máy đang in — KC: dòng sổ có bằng chứng `fleet\verify_001_*.md` (vai: trưởng phòng)

## SC → task

| SC | Task |
|---|---|
| SC-001 | T006, T008 |
| SC-002 | T011, T014 |
| SC-003 | T011, T013, T014 |
| SC-004 | T004, T013 |
| SC-005 | T007 |

## Phụ thuộc chéo đặc tả

- 001:T001 (`docs\data-formats.md`, cây thư mục) → mọi task của 002, 003, 004 ghi file theo định dạng đó.
- 001:T003 (`backup-orca.ps1`) → 003 (kiểm băm sao lưu) và mọi task cài hồ sơ vào Orca.
- 001:T002 (mã truy cập) và 001:T011 (baseline Bambu) → 004 (rà lỗi, bảo trì).
- 001:T011 (baseline Voron) → 002:T005 (đo "trước" so với baseline).
- 001:T016 (`gaps.md`) → 002 và 004 đối chiếu danh sách khoảng trống; phần nền của 003 không chờ
  T016.
- 001:T009 (`bambu-read.ps1`) → 004 (đọc lại trạng thái sau hiệu chuẩn hãng).
