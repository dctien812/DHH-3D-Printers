# Tasks: Hiệu chuẩn và bảo trì 4 máy Bambu

**Input**: `specs\004-bambu-calibration\spec.md`, `plan.md`

**Format**: `- [ ] T001 [P] [US1] mô tả kèm đường dẫn — KC: cách kiểm chứng (vai: tên)`. `[P]` là chạy
song song, không chung file. `[Buổi X]` là task chờ người dùng. Trên panel, id là `004-T001`…

**Tests**: Không có bộ test tự động. Kiểm chứng bằng đầu ra lệnh chạy thật, do vai khác vai viết.

**Giới hạn**: văn phòng không gửi gói nào tới máy Bambu ngoài `pushall`; lệnh làm máy chuyển động,
nóng hoặc in do người dùng khởi động trên máy hoặc từ Orca.

**Pilot trước**: chạy Buổi C (PLA) rồi mới D1, D2, E. Pilot chưa đạt thì dừng để khỏi tốn nhựa.

**Lịch (người dùng chốt 2026-11-24)**: hôm trước = Buổi A1, A2, B2, G1, G2 (nạp bo V2.4 trước mọi phép đo trên V2.4); ngày 1 = B1 và C (C chỉ gồm PLA trên 4 máy Bambu); ngày 2 = D1, D2 (hai loại PETG trên 6 máy); ngày 3 = E, F. Phạm vi nhựa: PLA chỉ 4 máy Bambu; PETG cả 6 máy; ABS trên hai Voron, H2S, P1S.

## Phase 1: Setup

- [ ] T001 [P] Tra web: ghi chú phát hành firmware chính thức và lịch bảo trì chính thức cho H2S, P1S, A1, A1 Mini (wiki.bambulab.com từng trả 402; thử mục support và release notes của bambulab.com); tìm thay đổi liên quan kết nối OrcaSlicer và plugin mạng. Trang nào bị chặn thì trưởng phòng nhờ người dùng mở và dán nội dung ở Buổi A2 — KC: mỗi kết luận kèm URL chính thức và ngày; trang bị chặn ghi "bị chặn", nguồn bên thứ ba phải ghi rõ là bên thứ ba (vai: explorer; gọi `model: sonnet`, không đọc file trên máy trong cùng lượt)
- [ ] T002 [P] Tìm hiểu K: đọc hồ sơ Bambu trong Orca ở `%APPDATA%\OrcaSlicer\user\<id>` (gộp chung lượt với 003:T005), nơi K được lưu (máy hay hồ sơ), cách tránh bù hai lần; đề xuất phép thử A/B cho T011 — KC: báo cáo ghi `đường_dẫn:dòng`, nêu rõ điều chưa có nguồn (vai: explorer; tìm trong dự án, không gọi web)
- [x] T003 [P] Viết khung `calibration\bambu\MAINTENANCE.md` và `fleet\firmware\TEMPLATE.md` (cột: máy, bản đang chạy, bản mới, thay đổi liên quan, khuyến nghị, nguồn, ngày) — KC: đủ cột (vai: software-engineer)

## Phase 2: Foundational

- [ ] T004 Điều kiện bắt đầu: kiểm đã có 001:T002 (mã đã điền) và 001:T011 (baseline 4 máy Bambu); rút danh sách mã lỗi/HMS đang treo từ `fleet\baseline\2026-11-24\<máy>\status.json` hoặc ảnh — KC: danh sách mã, không kèm serial hay mã truy cập (vai: trưởng phòng)
- [ ] T005 Tra mã HMS và lỗi trong danh sách T004 — KC: mỗi mã có nguồn và hướng xử lý, hoặc "chưa có nguồn" (vai: explorer; gọi `model: sonnet`, không đọc file trên máy trong cùng lượt)

## Phase 3: User Story 1 — Máy sạch lỗi và đã qua hiệu chuẩn của hãng (P1, MVP)

- [ ] T006 [US1] Viết `calibration\bambu\health_<máy>.md` (4 file: lỗi treo, hướng xử lý từ T005, việc bảo trì đến hạn theo T001 và `MAINTENANCE.md`, việc nào người dùng làm bằng tay) — KC: mỗi lỗi có một hướng xử lý; mỗi việc có ai làm (vai: software-engineer)
- [ ] T007 [US1] [Buổi B2] Làm các việc bảo trì bằng tay theo `health_<máy>.md`, và chạy hiệu chuẩn có sẵn của máy (cân bàn, bù rung, hiệu chuẩn động cơ tùy mẫu) trên 4 máy; chụp màn hình kết quả nếu máy không báo ra ngoài — KC: người dùng báo xong từng máy (vai: người dùng)
- [ ] T008 [US1] Đọc lại trạng thái bằng `bambu-read.ps1` (chỉ subscribe; `-AllowPushAll` khi thiếu dữ liệu), ghi `calibration\bambu\health_after_<máy>.md` kèm ngày hiệu chuẩn mới — KC: trạng thái từng máy ghi đủ; không gói nào khác ngoài `pushall` được gửi (vai: trưởng phòng)
- [ ] T009 [US1] Kiểm: (1) mỗi lỗi treo trong baseline có hướng xử lý ở `health_<máy>.md` và trạng thái sau T008 không còn lỗi chưa xử lý (SC-001); (2) so trạng thái máy trước và sau lần đọc (nhiệt, đang in hay không) — KC: `fleet\verify_004_health.md` kèm đầu ra lệnh (vai: test-engineer)

**Checkpoint**: máy sạch lỗi và đã qua hiệu chuẩn hãng trước khi hiệu chuẩn nhựa.

## Phase 4: User Story 2 — Hiệu chuẩn vật liệu trên từng máy Bambu (P2)

- [x] T010 [P] [US2] Viết `calibration\guides\bambu_<nhựa>.md` cho 4 nhựa (H2S ghi theo đường AMS dùng hằng ngày; ABS chỉ H2S và P1S, buồng đóng, thông gió): lưu lượng thể tích tối đa, PA/K, flow theo thứ tự hiệu chuẩn của Orca (nhiệt dùng mặc định, ghi `mặc_định`), điền `calibration\entry\cal\<ngày>_<máy>_<nhựa>.csv` kèm cuộn và điều kiện sấy; lưu ý bù K chỉ ở một nơi — KC: người chưa biết dự án làm theo được; T024 rà trước Buổi C (vai: software-engineer)
- [x] T024 [US2] (trước T011) Rà `calibration\guides\bambu_*.md`: làm theo được, không bước nào đòi văn phòng gửi lệnh tới máy, phần an toàn ABS đủ — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T011 [US2] [Buổi C, nửa 1] Pilot Bambu PLA trắng trên H2S (qua AMS), P1S, A1, A1 Mini: chạy hiệu chuẩn theo thẻ, kèm thử A/B cho K (một mẫu với hiệu chuẩn động lực dòng chảy tự động của máy bật, một mẫu tắt, cùng nhựa, cùng hồ sơ) theo đề xuất T002; điền entry; sau đó trưởng phòng chạy 003:T028 rồi mới in mẫu chuẩn (003:T015) — KC: 4 entry BAMBU-PLA, mỗi tham số là số đo hoặc `chưa_đo` (vai: người dùng)
- [ ] T012 [US2] [Buổi D1, nửa 1] Bambu PETG Basic trắng trên 4 máy Bambu (chỉ sau khi pilot đạt) — KC: 4 entry BAMBU-PETG (vai: người dùng)
- [ ] T013 [US2] [Buổi D2, nửa 1] Tinmorry PETG-ECO trắng trên 4 máy Bambu — KC: 4 entry TIN-PETGECO (vai: người dùng)
- [ ] T014 [US2] Giữa hai nửa của mỗi buổi C, D1, D2, E (trong cùng lượt với 002:T018 và 003:T028): chạy `scripts\calibration\ingest.ps1` (của 002:T002) để cập nhật `calibration\bambu.csv`; số kế thừa (co ngót XY) lấy từ `profiles\old_inventory.csv` và ghi `kế_thừa` — KC: dòng `đo` tăng đúng số entry nhận; dòng `kế_thừa` có nguồn (vai: trưởng phòng)
- [ ] T015 [US2] Kiểm `calibration\bambu.csv`: đủ 14 cặp (PLA 4, Bambu PETG 4, Tinmorry PETG-ECO 4, ABS Pro 2: H2S và P1S), mỗi cặp có số đo hoặc `chưa_đo`; thử `ingest.ps1` với entry thiếu nguồn phải bị từ chối (SC-002) — KC: `fleet\verify_004_calib.md` kèm đầu ra lệnh (vai: test-engineer)
- [ ] T016 [US2] Từ kết quả thử A/B ở T011 và entry, viết `docs\bambu-k-rule.md`: với từng máy, K lấy ở đâu (máy hay hồ sơ slicer), cách đặt hộp thoại in của Orca để không bù hai lần (FR-006); A/B không phân biệt được thì ghi "chưa kết luận" và đề xuất thử thêm — KC: mỗi máy một quy tắc kèm bằng chứng A/B; T022 rà (vai: software-engineer)
- [ ] T017 [US2] [Buổi E, nửa 1] Tinmorry ABS Pro trắng trên H2S và P1S (buồng đóng, thông gió); không thử ABS trên A1 và A1 Mini — KC: 2 entry TIN-ABSPRO (vai: người dùng)

**Checkpoint**: US2 xong khi T015 qua; 003 đọc số từ `bambu.csv`.

## Phase 5: User Story 3 — Quyết định firmware có căn cứ (P3)

- [x] T018 [P] [US3] Viết `fleet\firmware\{H2S,P1S,A1,A1M}.md` từ `TEMPLATE.md` và kết quả T001: bản đang chạy (H2S 01.03.00.00, P1S 01.10.00.00, A1 01.09.00.00, A1 Mini 01.09.00.00), bản mới, thay đổi liên quan Orca và plugin mạng, khuyến nghị nâng hay giữ, nguồn, ngày — KC: mỗi khuyến nghị dẫn được tới ghi chú phát hành chính thức; nguồn bên thứ ba ghi rõ là bên thứ ba (vai: software-engineer)
- [ ] T019 [US3] Kiểm lại từng URL và trích dẫn trong 4 file firmware (trưởng phòng chép URL và câu trích vào bản giao việc) — KC: URL truy cập được và nội dung khớp trích dẫn, hoặc nêu rõ cái nào không (vai: explorer; gọi `model: sonnet`, không đọc file trên máy trong cùng lượt)
- [ ] T020 [US3] [Buổi F] Quyết định nâng hay giữ từng máy; không máy nào bị nâng trước câu trả lời này — KC: câu trả lời ghi sổ; firmware máy vẫn như `fleet\inventory.csv` trừ khi người dùng chọn nâng (vai: người dùng)

## Phase 6: Polish

- [ ] T021 [P] Kiểm cuối về gói gửi đi và bí mật: đọc `publish.log` của mọi lần chạy `bambu-read.ps1` (chỉ được có pushall); rà lại script nếu đã sửa sau 001:T013; quét bí mật toàn dự án ngoài `secrets\` bằng so khớp im lặng, không in giá trị (SC-005, FR-008) — KC: 0 gói ngoài pushall; kết quả quét là không có; báo cáo ba mức (vai: security-auditor)
- [ ] T022 [P] Rà cuối `docs\bambu-k-rule.md`, `fleet\firmware\*.md`, `health_*.md`, `calibration\bambu.csv`; đối chiếu hiến chương III, V, VI — KC: báo cáo ba mức, không còn Nghiêm trọng hay Quan trọng (vai: checker)
- [ ] T023 Ghi sổ: kết quả từng SC, quyết định firmware, các cặp còn `chưa_đo` — KC: dòng sổ có bằng chứng `fleet\verify_004_*.md` (vai: trưởng phòng)

## SC → task

| SC | Task |
|---|---|
| SC-001 | T004..T009 |
| SC-002 | T011..T015, T017, T024 |
| SC-003 | T011..T013, T017 và 003:T020 |
| SC-004 | T018..T020 |
| SC-005 | T008, T021 |

## Phụ thuộc chéo đặc tả

- 001:T001, T002 (mã truy cập), T009 (`bambu-read.ps1`), T011 (baseline Bambu) → 004:T004..T009.
- 001:T016 (`gaps.md`) → 004:T004.
- 002:T002 (`ingest.ps1`) → 004:T014 (dùng chung, không sửa).
- 003:T002 (`old_inventory.csv`) → 004:T014 (số kế thừa).
- 003:T006 (`-Set pilot`) và T007 (STL) → 004:T011 (Buổi C).
- 004:T014 (`bambu.csv`) → 003:T015, T024.
- Buổi C chung với 002:T014 và 003:T015; D1/D2/E chung với 002:T015..T017 và 003:T018; Buổi F
  chung với 003:T019, T025.
