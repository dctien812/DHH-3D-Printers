# Lịch hiệu chuẩn đồng loạt: hôm trước và 3 ngày

Máy: TRI, V24, H2S (có AMS), P1S, A1, A1M. Nhựa trắng: BAMBU-PLA (chỉ 4 máy Bambu), BAMBU-PETG (Bambu PETG Basic) và TIN-PETGECO (cả 6 máy), TIN-ABSPRO (TRI, V24, H2S, P1S).
Thẻ: `calibration\guides\voron_<nhựa>.md`, `bambu_<nhựa>.md`, nửa 2 `NUA-2_mau-chuan.md`. Bảo trì: `calibration\bambu\MAINTENANCE.md`.
Phiếu mẫu: `calibration\entry\cal\TEMPLATE_cal.csv`, `calibration\entry\part\TEMPLATE_part.csv` (vai khác tạo).

Trạng thái trang này: lịch soạn theo quyết định của người dùng ngày 2026-11-24 (`.office\ledger.md`, dòng K15) và kế hoạch (`specs\003-orca-profiles\plan.md:49-69`); **chưa chạy thử lần nào, mọi thời lượng là ước lượng chưa đo**. Văn phòng **không gửi lệnh điều khiển nào tới máy Bambu** (ngoài `pushall` chỉ-đọc theo hiến chương III); mọi lần in do bạn bấm.

## 1. Thời gian: tách "máy chạy" và "bạn có mặt"

Ước lượng của kế hoạch (`plan.md:54-68`) chưa đo và lẫn hai loại giờ. Tôi tách theo cách ghi của kế hoạch, không thêm số mới:
- **Máy chạy** (kế hoạch ghi cho 6 máy; 4 máy PLA chưa có số riêng): C 4–5 h, D1 3–4 h, D2 3–4 h, E 3 h. **Tổng 13 đến 16 giờ.** Thời gian nguội giữa các lần in ABS chưa tính.
- **Bạn có mặt, việc tay có số riêng**: A1 15 phút, A2 20–30 phút, B1 90 phút, B2 60 phút, F 2 giờ, G2 60–90 phút. **Tổng 6,1 đến 6,8 giờ.**
- Bạn cũng phải có mặt trong các buổi in (nạp nhựa, nhìn lớp đầu, đọc mẫu, đo thước cặp 3 lần mỗi hướng trên 6 máy); kế hoạch **chưa ước lượng riêng** phần này, nên tổng có mặt thực tế **cao hơn 6,1–6,8 giờ**. Nếu coi cả giờ máy chạy là có mặt thì ra 19 đến 23 giờ, gần với "16 giờ trở lên" của kế hoạch (`plan.md:68`).
- Kết luận: không thể đủ trong một ngày; người dùng đã chọn chia như dưới.

## 2. Điều kiện để bắt đầu (trưởng phòng xác nhận)

- [ ] Thẻ đã được `checker` rà (002:T020, 004:T024), không còn lỗi Nghiêm trọng hay Quan trọng.
- [ ] Script đo và ghi đã rà xong: 002:T034 và T035 (`measure.ps1`, `apply-config.ps1`); `ingest.ps1` có (002:T002).
- [ ] Bộ pilot PLA dựng được; STL mẫu có (003:T006, T007, T011).
- [ ] Máy Bambu đọc được: mã truy cập đã điền **trước hôm trước** (001:T002; 004:T004–T006 cần mã và baseline Bambu để viết `health_<máy>.md`).
- [ ] Voron: 002:T003/T004 (thử khôi phục), T037 (xác nhận `material_profiles_enabled = False`), T029 (skew nạp một lần) xong. Hai Voron không đang in hay tạm dừng (lúc kiểm: Trident tạm dừng, V24 đang in, `fleet\precheck\2026-11-24\SUMMARY.md:11`). SAVE_CONFIG treo: người dùng quyết bỏ (ledger K15).
- [ ] `docs\mcu-reflash-v24.md` có và đã rà (002:T025, T036) trước khi nạp bo V2.4 hôm trước.

## 3. Chuẩn bị từ ngày trước đó (không in nhựa)

- [ ] **Sấy nhựa** cho ngày kế tiếp: theo nhãn hãng; dự án chưa có số sấy từ nguồn, ghi nhiệt độ và giờ thực tế vào `điều_kiện`. PLA cho Ngày 1; PETG cho Ngày 2; ABS Pro sát Ngày 3 (sấy lại nếu dời).
- [ ] **Nhãn cuộn** (ví dụ `BAMBU-PLA-01`), ghi giống hệt vào cột `cuộn`; dùng chung một cuộn cho nhiều máy thì ghi cùng mã, nạp tuần tự.
- [ ] **Vật tư**: dầu, mỡ, IPA, khăn không xơ theo `MAINTENANCE.md`; kẹp, dao gỡ mẫu, găng chịu nhiệt.
- [ ] **Dọn bàn in** cả 6 máy; gỡ nhựa cũ khỏi đầu phun nếu đổi nhựa.
- [ ] **Thước cặp**: pin còn, khép về 0, kẹp thử vật đã biết kích thước.
- [ ] Điện thoại sạc đầy, bút giấy. Thông gió phòng sẵn cho Ngày 3.
- [ ] Máy tính: Orca mở được; `calibration\entry\cal\` và `calibration\entry\part\` sẵn; chép trước phiếu `cal` và `part` của PLA cho 4 máy Bambu từ file mẫu.

## 4. Lịch

| Giai đoạn | Người dùng | Trưởng phòng xen giữa | Chạy song song | Phải chờ |
|---|---|---|---|---|
| **Hôm trước** (không in nhựa) | A1: điền mã truy cập, serial, xác nhận máy "TTeccS", đọc bảng kiểm kê (001:T002, T007), 15 phút. B2: bảo trì tay và hiệu chuẩn hãng 4 Bambu theo `MAINTENANCE.md`, 60 phút. A2: thử đồng bộ Orca (đóng Orca, mở lại, báo 18 hồ sơ có hiện không, 003:T013), 20–30 phút. G2: nạp bo mạch V2.4 về Klipper chính, ở cạnh máy, 60–90 phút (002:T027); rồi **để V24 nguội qua đêm** | A1: không. B2: đọc lại trạng thái chỉ-đọc (004:T008). A2: cài hồ sơ pilot khi Orca đóng (003:T012), so băm (003:T014). G2: nạp EBB36 qua Katapult trước (002:T026), kiểm sau nạp (T028) | hiệu chuẩn hãng chạy cùng lúc trên 4 Bambu | bảo trì tay xong mới bấm hiệu chuẩn; Orca đóng khi cài; **nạp V24 phải xong trước mọi phép đo trên V24** |
| **Ngày 1** | **B1**: cân đai, kiểm puly, ổ bi, Trident rồi V24 (002:T006), 90 phút. Cùng lúc **PLA nửa 1 rồi nửa 2 trên 4 Bambu** (thẻ `bambu_BAMBU-PLA.md`, `NUA-2_mau-chuan.md`) | sáng: đo "trước" khi máy nguội, 3 lần (002:T005) và `PROBE_ACCURACY` (T022). Sau mỗi Voron: đo "sau" (T007), soạn và chạy shaper, thử tốc độ 400 mm/s (T008, T009), V24 chỉ sau khi Trident qua. Giữa hai nửa PLA: `ingest.ps1`, 003:T028; sau nửa 2: `aggregate.ps1` (003:T016) | B1 song song với PLA trên Bambu; đo Voron này trong lúc bạn cân Voron kia (giữ yên máy đang đo) | **Cổng trước MỌI lần trưởng phòng chạy `measure.ps1` (đo "trước", đo "sau") và trước `test_speed`, `PROBE_ACCURACY`: bàn trống, dụng cụ và tay ra khỏi máy, nắp lắp lại; bạn báo bằng một câu** (`measure.ps1:14,158` đòi `-BedClear` mọi lần chạy thật vì đầu in xuống Z = 20 mm giữa bàn); máy nguội trước khi đo; PLA nửa 2 chờ gói hồ sơ mới |
| **Ngày 2** | PETG nửa 1 rồi nửa 2 trên cả 6 máy: lượt **Bambu PETG Basic (D1)**, rồi **Tinmorry PETG-ECO (D2)**. Đây là phép thử kích thước đầu tiên của hai Voron | giữa hai nửa mỗi lượt: `ingest.ps1`, 003:T028 (`-Set all`, 003:T024); sau nửa 2: `aggregate.ps1` | 6 máy in cùng lúc, bấm so le | **Cổng**: pilot PLA 4 Bambu đạt và Voron qua B1; sấy PETG; đổi nhựa giữa D1 và D2 |
| **Ngày 3** | **ABS Pro** nửa 1 rồi nửa 2 trên TRI, V24, H2S, P1S (E, thông gió, gỡ mẫu theo thẻ); **in bù** cặp lệch; **lắp chéo** 3 cặp máy (003:T019); cắt lớp tay nếu không có CLI (003:T025); **quyết firmware Bambu** (004:T020) | `ingest.ps1`, 003:T028; tính bù (003:T017); từ vòng bù thứ 3 của một cặp báo số đo và nhựa đã dùng | 4 máy ABS cùng lúc; A1 và A1M rảnh dùng cho in bù | **Cổng tách đôi (mục 6): ABS trên TRI, V24 chờ PETG đạt trên hai Voron; ABS trên H2S, P1S chỉ chờ PETG đạt trên các máy Bambu**; buồng nguội và đợi bàn hạ nhiệt giữa các lần in; `aggregate.ps1` có danh sách cặp lệch |

## 5. Mỗi buổi in diễn ra thế nào

1. Nạp nhựa vào các máy của buổi, chọn hồ sơ `DHH …` trong Orca.
2. **Nửa 1**: theo thẻ từng máy; mỗi bước (mvs, PA hoặc K, flow) cần đọc kết quả trước khi sang bước sau, nên làm theo **vòng**: bấm in bước 1 trên các máy so le để kịp nhìn lớp đầu, đọc, ghi, rồi sang bước 2. Điền phiếu `cal` (đúng cách nhập trong thẻ: Notepad hoặc VS Code, UTF-8, dấu chấm).
3. **Chờ trưởng phòng** (vài phút theo kế hoạch): `ingest.ps1`, dựng lại hồ sơ, xuất gói Preset Bundle. Trong lúc chờ dọn bàn, ghi ảnh, chuẩn bị nhựa buổi sau.
4. **Nhập gói hồ sơ mới vào Orca** (khoảng 5 phút).
5. **Nửa 2** theo `NUA-2_mau-chuan.md`: mẫu (a) và (b), đo, điền phiếu `part`.
6. Trưởng phòng chạy `aggregate.ps1`, lập danh sách cặp lệch.

## 6. Cổng dừng

- **Sau PLA (Ngày 1)**: có cặp lệch quá dung sai (X/Y ±0,1 mm trên 100 mm; Z ±0,1 mm trên 20 mm; lỗ ±0,15 mm) thì dừng, làm vòng bù (003:T017) rồi in lại trước khi sang PETG. Từ vòng bù thứ 3 của một cặp, trưởng phòng báo bạn số đo và nhựa đã dùng trước khi in tiếp (`specs\003-orca-profiles\tasks.md:18-19`).
- **Voron lệch sau PETG (Ngày 2)**: nếu TRI hoặc V24 có cặp lệch quá dung sai, trưởng phòng bù (003:T017) và bạn in lại **trước khi sang ABS**; dời ABS sang ngày sau nếu cần. ABS trên Voron chỉ bắt đầu khi cả hai Voron đã đạt PETG; ABS trên H2S, P1S không chờ Voron, chỉ chờ PETG đạt trên các máy Bambu; in bù ABS tính riêng.
- **Voron sau B1**: số đai sau không khá hơn số trước trên một máy thì máy đó giữ shaper cũ (002:T010); ghi chú, vẫn in PETG.
- Máy báo lỗi hay mẫu hỏng liên tục: dừng máy đó, ghi lại, các máy khác tiếp tục.

## 7. Nếu một ngày vẫn quá dài

Cắt theo thứ tự này (từ ngoài vào): bỏ phép thử A/B của K (đã nằm ngoài giờ Ngày 1); dời D2 (PETG-ECO) sang một ngày riêng; dời lắp chéo và quyết firmware khỏi Ngày 3. Không cắt: B2 và A2 hôm trước, nạp V24 trước mọi phép đo, PLA 4 Bambu (là cổng của PETG và ABS). Nhựa dời ngày thì sấy lại sát ngày dùng.

## 8. Cuối mỗi ngày

- [ ] Mọi file `cal` và `part` của ngày đã lưu; nhãn cuộn khớp.
- [ ] Báo trưởng phòng buổi nào xong, dở, chưa làm.
- [ ] Tắt máy, dọn bàn, nhựa cất lại (PETG, ABS đậy kín).
- [ ] Ghi chỗ khác thẻ (menu Orca khác tên, bước không làm được) để sửa thẻ.

## 9. Chưa kiểm chứng

Mọi thời lượng; việc 4 máy Bambu chạy PLA song song với cân đai Voron cho một người; việc đo Voron khi máy kia đang được cân (nhiễu rung); tên menu Orca; số giờ nguội ABS.
