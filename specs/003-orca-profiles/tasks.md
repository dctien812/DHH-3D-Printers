# Tasks: Bộ hồ sơ OrcaSlicer chung cho 6 máy

**Input**: `specs\003-orca-profiles\spec.md`, `plan.md`

**Format**: `- [ ] T001 [P] [US1] mô tả kèm đường dẫn — KC: cách kiểm chứng (vai: tên)`. `[P]` là chạy
song song, không chung file. `[Buổi X]` là task chờ người dùng. `[CÓ ĐIỀU KIỆN]` ghi rõ điều kiện
chạy. Trên panel, id là `003-T001`…

**Tests**: Không có bộ test tự động. Kiểm chứng bằng đầu ra lệnh chạy thật, do vai khác vai viết.

**Quy ước tên (người dùng chốt)**: máy `DHH <Máy> 0.4`; vật liệu `DHH <Hãng> <Loại> @<Máy>`; quy
trình `DHH 0.20 Sync @<Máy>`. "Nhựa" là hãng + loại. Số hồ sơ vật liệu: 20 (PLA 4 máy Bambu, hai loại
PETG trên 6 máy, ABS Pro trên 4 máy buồng kín).

**Lịch (người dùng chốt 2026-11-24)**: hôm trước = Buổi A1, A2, B2, G1, G2 (nạp bo V2.4 trước mọi phép đo trên V2.4); ngày 1 = B1 và C (C chỉ gồm PLA trên 4 máy Bambu); ngày 2 = D1, D2 (hai loại PETG trên 6 máy); ngày 3 = E, F. Phạm vi nhựa: PLA chỉ 4 máy Bambu; PETG cả 6 máy; ABS trên hai Voron, H2S, P1S.

**Dung sai (người dùng chốt)**: X/Y ±0,1 mm trên 100 mm; Z ±0,1 mm trên 20 mm; lỗ Ø8 ±0,15 mm;
thử lắp chéo phải lắp được.

**Quy tắc bù (người dùng chốt)**: không nới dung sai. Mẫu không đạt thì bù và in lại, không giới
hạn số vòng. Sau mỗi vòng ghi số đo vào sổ. Từ vòng thứ 3 của một cặp, trưởng phòng báo người dùng
số đo và lượng nhựa đã dùng trước khi in tiếp.

**Pilot trước**: `build-profiles.ps1 -Set pilot` chỉ dựng bộ PLA cho 4 máy Bambu cùng 6 hồ sơ máy và 6 quy
trình (16 file). Bộ đủ 20 chỉ dựng sau khi pilot đạt (T024). T024 và T025 nằm ở Phase 3 nhưng chạy sau T016;
số task giữ nguyên để khớp tham chiếu chéo.

**Vòng bù của pilot**: nếu pilot PLA chưa đạt, các vòng bù (T017, T018) chạy ngay sau Buổi C, trước
D1; Buổi D1 chỉ bắt đầu khi pilot đạt.

**Mỗi buổi in có hai nửa**: nửa 1 người dùng in mẫu hiệu chuẩn và điền số (002, 004); trưởng phòng
chạy T028 để đưa số vào hồ sơ; nửa 2 người dùng in và đo mẫu chuẩn bằng hồ sơ đã có số.

## Phase 1: Setup

- [ ] T001 [P] Tra web: (1) đồng bộ cloud của Orca có ghi đè hồ sơ cục bộ không; (2) H2S có hồ sơ gốc trong Orca 2.5.2 không; (3) cách nhập/xuất Preset Bundle, nhập khi Orca đang mở có đè được không — KC: mỗi kết luận kèm URL; mục nào không có nguồn thì ghi "chưa có nguồn" (vai: explorer; gọi `model: sonnet`, không đọc file trên máy trong cùng lượt)
- [x] T002 [P] Viết `scripts\orca\inventory-old.ps1` đọc `%APPDATA%\OrcaSlicer\user\<id>\{machine,filament,process}` (chỉ đọc) và sinh `profiles\old_inventory.csv`: tên, loại, hãng suy ra, máy, trong hay ngoài phạm vi (TPU, ASA-CF, SUNLU, HUTI là ngoài), trùng, thiếu cặp, hệ số co ngót XY và các số có sẵn để kế thừa — KC: 6 máy, 25 vật liệu, 1 quy trình (đếm đệ quy, gồm thư mục con `filament\base\`); T003 đếm lại (vai: software-engineer)
- [x] T003 Đối chiếu độc lập: (1) so SHA256 từng file của `profiles\orca_backup\2026-11-24\` với `%APPDATA%\OrcaSlicer\user` (SC-004); (2) đếm dòng `profiles\old_inventory.csv` so với thư mục thật — KC: đầu ra lệnh vào `fleet\verify_003_backup.md`, 0 file lệch, đúng 6/25/1 khi đếm đệ quy (vai: test-engineer)

## Phase 2: Foundational (chặn mọi user story)

- [x] T004 [P] Viết `profiles\src\machines.csv` (6 máy), `profiles\src\process.csv`, `profiles\src\materials.csv` (20 dòng, mỗi số kèm `trạng_thái` và nguồn theo `docs\data-formats.md`; số kế thừa lấy từ `old_inventory.csv`, số chưa đo ghi `chưa_đo`) và `profiles\NAMING.md` (quy ước tên DHH, cặp hợp lệ, ABS/ASA chỉ cho TRI, V24, H2S, P1S) — KC: 20 dòng, không trùng tên, không dòng ABS cho A1 và A1M, không dòng PLA cho TRI và V24 (vai: software-engineer)
- [ ] T005 [P] Đọc cấu trúc hồ sơ người dùng của Orca trong `%APPDATA%\OrcaSlicer\user\<id>` (trường `inherits`, `compatible_printers`, file `.info`, nơi lưu PA/K, co ngót, G-code đầu/cuối, trường liên quan đồng bộ) và mô tả cách tạo hồ sơ mới an toàn — KC: báo cáo ghi `đường_dẫn:dòng` (vai: explorer; tìm trong dự án, không gọi web)
- [x] T006 Viết `scripts\orca\build-profiles.ps1`: sinh JSON từ `profiles\src\*.csv` và `profiles\src\base\` ra `profiles\bundle\`, tham số `-Set pilot|all`, `-OutDir`, `-Verify` (đọc lại so với bảng), `-Install` (chỉ tạo file mới, từ chối nếu Orca đang chạy, không sửa hay xóa file cũ), tạo thêm gói Preset Bundle để người dùng nhập. Phụ thuộc T004, T005, T010 — KC: T011 chạy thật (vai: software-engineer)
- [x] T007 [P] Viết `scripts\models\make-cal-models.ps1` sinh 3 STL vào `models\`: (a) khung rỗng 100 × 100 × 20 mm, thành 2,4 mm, đo X/Y giữa chiều cao và Z; (b) tấm lỗ Ø8 và chốt (khe hở ghi trong `models\README.md`) để đo lỗ và lắp chéo; (c) tháp bề mặt và nhô. Mỗi tấm tối đa khoảng 120 mm mỗi chiều, vừa bàn A1 Mini 180 mm — KC: script in bounding box từng STL, (a) = 100 × 100 × 20, mọi tấm ≤ 120 mm; T011 kiểm (vai: software-engineer)
- [x] T008 [P] Viết `calibration\results_template.csv` và `scripts\calibration\aggregate.ps1`: gộp `calibration\entry\part\*.csv` thành `calibration\results.csv`, tính trung bình 3 lần đo mỗi hướng, độ lệch trên 100 mm (X, Y), trên 20 mm (Z), lỗ Ø8, và cờ `đạt` theo dung sai trên — KC: một entry mẫu tính tay ra đúng số (kiểm ở T020) (vai: software-engineer)
- [ ] T009 Đọc G-code đầu và cuối trong hồ sơ máy Voron của Orca (`%APPDATA%\OrcaSlicer\user\<id>\machine`) và macro `START_PRINT`, `END_PRINT` cùng chuỗi `startprint_actions` trong bản chụp `fleet\baseline\`; nêu dòng nào nạp skew lần hai — KC: báo cáo ghi `đường_dẫn:dòng` (vai: explorer; tìm trong dự án, không gọi web)
- [x] T010 Tạo `profiles\src\base\` (bản sao hồ sơ máy, vật liệu, quy trình cũ cần làm nền; bản gốc trong Orca giữ nguyên) và sửa trong bản sao G-code đầu/cuối của hai Voron khớp macro hiện hành, không nạp skew hai lần (FR-009) — KC: diff giữa bản sao và bản gốc chỉ ở G-code đầu/cuối Voron; T011 kiểm (vai: software-engineer)
- [ ] T011 Kiểm T006, T007, T010 bằng chạy thật, trước Buổi C: (1) `build-profiles.ps1 -Set pilot -OutDir <thư mục tạm>` rồi `-Verify`; kiểm đúng 4 hồ sơ PLA (máy Bambu), 6 hồ sơ máy, 6 quy trình, tên theo quy ước, không ABS cho A1 và A1 Mini, băm các file cũ không đổi; (2) chạy `make-cal-models.ps1`, kiểm bounding box; (3) thử ngắn Orca CLI: tìm `orca-slicer.exe`, chạy `--help` và cắt lớp STL (a) với một bộ JSON trong thư mục tạm, ghi "CLI dùng được" hay "người dùng cắt lớp tay" — KC: `fleet\verify_003_build.md` kèm đầu ra lệnh (vai: test-engineer)

**Checkpoint**: công cụ dựng hồ sơ xong và đã được kiểm.

## Phase 3: User Story 1 — Một quy ước, một bộ hồ sơ (P1, MVP)

**Goal**: một hồ sơ cho mỗi cặp (máy, nhựa), tên theo quy ước, hồ sơ cũ nguyên vẹn.

- [ ] T012 [US1] Chạy lại `backup-orca.ps1` ngay trước khi cài (bản sao lưu mới theo ngày), dựng bộ pilot (`-Set pilot`), rồi cài vào thư mục user của Orca bằng `-Install` khi Orca đang đóng — KC: băm toàn bộ file cũ không đổi, đúng 16 file mới (6 máy, 4 PLA, 6 quy trình), `-Verify` khớp (SC-004) (vai: trưởng phòng)
- [ ] T013 [US1] [Buổi A2] Đóng Orca và báo trưởng phòng để chạy T012; sau đó mở Orca, đăng nhập tài khoản, chờ đồng bộ, báo 16 hồ sơ mới có hiện không và một file in cũ vẫn mở được. Lưu ý: khi đăng nhập, Orca có thể đẩy 16 hồ sơ mới lên tài khoản cloud của người dùng — KC: người dùng trả lời hiện hoặc không; file in cũ mở được (vai: người dùng)
- [ ] T014 [US1] Thử trực tiếp đồng bộ cloud: so băm 16 file mới và các file cũ trong thư mục user trước và sau lần mở Orca ở T013 (và sau một lần đóng mở thứ hai); nếu cloud ghi đè hoặc xóa thì ghi lại và báo — KC: `fleet\verify_003_sync.md` kèm băm trước và sau (vai: test-engineer)
- [ ] T024 [US1] [CÓ ĐIỀU KIỆN: chỉ sau khi T016 báo pilot PLA đạt] Dựng bộ đủ (`-Set all`, 20 hồ sơ vật liệu; cặp chưa hiệu chuẩn mang số kế thừa hoặc mặc định kèm nhãn, số đo sẽ được T028 đưa vào giữa hai nửa mỗi buổi), tạo gói Preset Bundle cho người dùng nhập vào Orca — KC: `-Verify` khớp bảng, 20 hồ sơ vật liệu đúng cặp (vai: trưởng phòng)
- [ ] T025 [US1] Cắt lớp mẫu (a) cho cả 20 cặp: nếu T011 cho "CLI dùng được" thì chạy CLI, không thì người dùng mở Orca cắt lớp từng cặp ở Buổi F (khoảng 20 phút); kiểm hồ sơ cũ vẫn mở được file in cũ — KC: 20/20 cặp cắt lớp không lỗi; mỗi cặp có đúng một hồ sơ; không hồ sơ ABS cho A1 hoặc A1 Mini, không hồ sơ PLA cho hai Voron (SC-001) (vai: test-engineer)

**Checkpoint**: US1 dùng được độc lập.

## Phase 4: User Story 2 — Cùng file, cùng kết quả trên mọi máy (P2)

**Goal**: mọi máy đạt dung sai. **Independent Test**: người dùng đo bằng thước cặp, bảng kết quả
tính ra đạt.

- [ ] T028 [US2] Giữa hai nửa của mỗi buổi C, D1, D2, E: chạy `ingest.ps1` (002:T018, 004:T014) với entry hiệu chuẩn vừa điền, dựng lại bộ (`build-profiles.ps1 -Set pilot` ở Buổi C, `-Set all` từ D1) với số mới, `-Verify`, xuất gói Preset Bundle cho người dùng nhập — KC: `-Verify` khớp; số PA/K, flow, lưu lượng tối đa trong hồ sơ của nhựa buổi đó bằng số trong `voron.csv` và `bambu.csv` (vai: trưởng phòng)
- [ ] T015 [US2] [Buổi C, nửa 2] (sau T028) Pilot Bambu PLA trắng trên 4 máy Bambu: nhập gói bundle pilot đã có số hiệu chuẩn vào Orca, in mẫu (a) và (b) trên từng máy; đo thước cặp 3 lần mỗi hướng (X, Y), Z, lỗ Ø8; chụp ảnh; điền `calibration\entry\part\<ngày>_<máy>_BAMBU-PLA.csv` — KC: 4 entry đủ trường (vai: người dùng)
- [ ] T016 [US2] Chạy `aggregate.ps1` và lập danh sách cặp lệch quá dung sai; ghi vòng bù thứ mấy và lượng nhựa đã dùng của mỗi cặp vào sổ; từ vòng thứ 3 của một cặp, báo người dùng số đo và lượng nhựa trước khi cho in tiếp — KC: `calibration\results.csv` có đủ cột, sổ có số vòng (vai: trưởng phòng)
- [ ] T017 [US2] Bù cho cặp lệch trong `profiles\src\materials.csv` (hệ số co ngót XY, bù lỗ/kích thước, flow), dựng lại bộ tương ứng, ghi số bù vào hồ sơ riêng của cặp đó với nguồn "đo, vòng N"; không đổi dung sai, không giới hạn số vòng — KC: `-Verify` khớp, bảng có dòng bù ghi ngày (vai: software-engineer)
- [ ] T018 [US2] [Buổi D1, D2, E nửa 2] [Buổi F] (mỗi lần sau T028 hoặc T017) In và đo mẫu (a)(b) cho nhựa của buổi đó và các cặp vừa bù; nhập gói bundle mới vào Orca trước khi in (khoảng 5 phút); điền entry vào `calibration\entry\part\` như T015 — KC: entry đủ trường mỗi cặp đã in (vai: người dùng)
- [ ] T019 [US2] [Buổi F] Thử lắp chéo mẫu (b): in lỗ trên một máy, chốt trên máy khác (ba cặp máy khác nhau), ghi lắp được hay không — KC: entry ghi 3 cặp lắp chéo, kết quả lắp được (SC-003) (vai: người dùng)
- [ ] T020 [US2] Tính lại độ lệch từ entry thô bằng phép tính độc lập, không dùng `aggregate.ps1`, cho ít nhất 5 cặp ngẫu nhiên và mọi cặp báo "đạt" ở cuối; so với `results.csv` — KC: `fleet\verify_003_results.md` khớp, và mọi cặp trong phạm vi đạt thật theo số thô (SC-002) (vai: test-engineer)

**Checkpoint**: US2 xong khi mọi cặp trong phạm vi đạt dung sai.

## Phase 5: User Story 3 — Hồ sơ có nguồn gốc và khôi phục được (P3)

- [ ] T021 [P] [US3] Viết `profiles\ADD-FILAMENT.md`: quy trình thêm một hãng nhựa mới (tên theo DHH, thứ tự hiệu chuẩn nhiệt, lưu lượng thể tích tối đa, PA/K, flow, co ngót, nhập vào bảng, dựng lại bằng script, kiểm mẫu); nhắc ghi điều kiện sấy và cuộn — KC: người ngoài dự án đọc làm theo được (kiểm ở T022) (vai: software-engineer)
- [ ] T022 [US3] Làm thử theo `profiles\ADD-FILAMENT.md` với hãng giả "TEST-BRAND" trong thư mục tạm (không cài vào Orca): thêm 1 dòng materials, dựng, `-Verify`; ghi mọi chỗ phải đoán — KC: `fleet\verify_003_addfilament.md`, 0 chỗ phải đoán hoặc liệt kê chỗ thiếu để sửa (SC-006) (vai: test-engineer)
- [ ] T023 [US3] Thử khôi phục: sao lưu thư mục user của Orca, bỏ các hồ sơ DHH khỏi Orca (chỉ file DHH, đã sao lưu), nạp lại từ `profiles\bundle\` bằng `-Install` khi Orca đóng; `test-engineer` chạy `-Verify` độc lập ghi `fleet\verify_003_restore.md` — KC: danh sách và giá trị khớp bảng 100 % (SC-005) (vai: trưởng phòng)

## Phase 6: Polish

- [ ] T026 [P] Rà `inventory-old.ps1`, `build-profiles.ps1`, `make-cal-models.ps1`, `aggregate.ps1`, `profiles\src\*.csv`, `ADD-FILAMENT.md`, đối chiếu hiến chương I, IV, VI — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T027 Ghi sổ: kết quả từng SC, số vòng bù và nhựa đã dùng mỗi cặp, mọi số "chưa đo" còn lại — KC: dòng sổ có bằng chứng `fleet\verify_003_*.md` (vai: trưởng phòng)

## SC → task

| SC | Task |
|---|---|
| SC-001 | T011, T024, T025 |
| SC-002 | T015..T020, T028 |
| SC-003 | T019 |
| SC-004 | T003, T012, T014 |
| SC-005 | T023 |
| SC-006 | T022 |

## Phụ thuộc chéo đặc tả

- 001:T001 (`docs\data-formats.md`) → 003:T004, T008.
- 001:T003, T004 (sao lưu Orca và kiểm) → 003:T003, T012.
- 001:T011 phần Voron (baseline) → 003:T009. Phần nền của 003 không chờ `gaps.md`.
- 003:T028 (giữa hai nửa mỗi buổi) gồm 002:T018 và 004:T014, và phải xong trước 003:T015, T018.
- 003:T002 (`old_inventory.csv`) → 001:T016 và `ingest.ps1` (002:T002) cho số kế thừa.
- 002:T018 (`voron.csv`) và 004:T014 (`bambu.csv`) → 003:T015, T024.
- 003:T006 (`-Set pilot`) và T007 (STL) → 002:T014 và 004:T011 (Buổi C).
- 003:T010 và T012 → 002:T029, T030 (kiểm skew nạp một lần).
- 003:T017 (bù) có thể đòi in lại trên Voron → Buổi F.
- Buổi C chung với 002:T014 và 004:T011; Buổi D1/D2/E chung với 002:T015..T017 và 004:T012, T013, T017.
