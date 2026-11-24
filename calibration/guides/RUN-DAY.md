# Lịch ngày hiệu chuẩn đồng loạt (6 máy)

Máy: TRI, V24, H2S (có AMS), P1S, A1, A1M. Nhựa trắng: BAMBU-PLA, BAMBU-PETG, TIN-PETGECO, TIN-ABSPRO (ABS Pro chỉ TRI, V24, H2S, P1S).
Thẻ từng việc: `calibration\guides\voron_<nhựa>.md`, `calibration\guides\bambu_<nhựa>.md`. Bảo trì: `calibration\bambu\MAINTENANCE.md`.
Phiếu số liệu: mẫu `calibration\entry\cal\TEMPLATE_cal.csv` và `calibration\entry\part\TEMPLATE_part.csv` (do vai khác tạo; nếu chưa có thì chưa bắt đầu).

Trạng thái trang này: lịch soạn từ kế hoạch (`specs\003-orca-profiles\plan.md:49-69`), **chưa chạy thử lần nào, mọi thời lượng là ước lượng chưa đo**. Văn phòng **không gửi lệnh nào tới máy Bambu**; mọi lần in do bạn bấm.

## 1. Nói thẳng về thời gian

- Kế hoạch ước lượng "16 giờ có mặt trở lên", chưa đo, chưa tính vòng bù (`plan.md:68`).
- Cộng các dòng thời lượng trong bảng kế hoạch (A1, A2, B1, B2, C, D1, D2, E, F, G2) ra khoảng **19 đến 23 giờ** (phép cộng số học của tôi, cùng độ tin cậy với ước lượng gốc).
- Máy chạy song song giúp giảm giờ máy, nhưng giờ **bạn có mặt** vẫn là nút cổ chai: nạp nhựa, nhìn lớp đầu, đọc mẫu, đo thước cặp 3 lần mỗi hướng trên 6 máy.
- **Kết luận: một ngày có thể không đủ.** Mục 7 đề xuất cách cắt; bạn quyết.

## 2. Điều kiện để ngày làm có thể bắt đầu (trưởng phòng xác nhận trước)

- [ ] Các thẻ đã được `checker` rà (002:T020, 004:T024), không còn lỗi Nghiêm trọng hay Quan trọng.
- [ ] Bộ pilot PLA dựng được, STL mẫu có (003:T006, T007, T011).
- [ ] `scripts\calibration\ingest.ps1` đã có (002:T002); việc thử từ chối entry thiếu nguồn ghi ở 002:T019.
- [ ] Voron: 002:T003/T004 (thử khôi phục), T037 (xác nhận `material_profiles_enabled = False`), T029 (skew nạp một lần) xong. Hai Voron không còn đang in hay tạm dừng (lúc kiểm 2026-11-24: Trident tạm dừng, V24 đang in, `fleet\precheck\2026-11-24\SUMMARY.md:11`).
- [ ] Nếu làm G2 trong ngày: `docs\mcu-reflash-v24.md` có và đã được rà (002:T025, T036).

## 3. Chuẩn bị từ hôm trước (người dùng)

- [ ] **Sấy nhựa** cho các buổi sẽ làm trong ngày: sấy theo nhãn hãng; dự án chưa có số sấy từ nguồn nào, ghi nhiệt độ và giờ thực tế để điền `điều_kiện`. PLA hôm trước; PETG, ABS chỉ sấy sát ngày dùng (nếu chúng dời sang ngày sau thì sấy lại sát ngày đó).
- [ ] **Nhãn cuộn**: dán mã cuộn lên từng cuộn (ví dụ `BAMBU-PLA-01`) và ghi giống hệt vào cột `cuộn`. Dùng chung một cuộn cho nhiều máy thì ghi cùng mã; nạp tuần tự từng máy.
- [ ] **Vật tư**: dầu, mỡ, IPA, khăn không xơ theo `MAINTENANCE.md` (loại cụ thể tra URL trong đó); kẹp, dao gỡ mẫu, găng chịu nhiệt.
- [ ] **Dọn bàn in** cả 6 máy; gỡ nhựa cũ khỏi đầu phun nếu đang đổi nhựa.
- [ ] **Thước cặp**: pin còn, khép kín về 0, kẹp thử trên một vật bạn biết kích thước; để sẵn chỗ đo.
- [ ] Điện thoại sạc đầy để chụp ảnh mẫu; bút, giấy.
- [ ] Phòng: nếu có ABS trong ngày, chuẩn bị thông gió (cửa sổ, quạt hút ra ngoài).
- [ ] Máy tính: Orca mở được; thư mục `calibration\entry\cal\` và `calibration\entry\part\` sẵn; chép trước các file phiếu của PLA cho 6 máy từ hai file mẫu (chỉ PLA, các nhựa khác làm khi tới buổi đó).
- [ ] Voron: đã in xong hoặc huỷ việc cũ, để máy nguội qua đêm (trưởng phòng cần máy nguội để đo đai, 002:T005).

## 4. Thứ tự các buổi

| Buổi | Người dùng làm | Trưởng phòng làm xen giữa | Chạy song song | Phải chờ | Ước lượng kế hoạch |
|---|---|---|---|---|---|
| A1 | điền mã truy cập và serial vào file cục bộ, xác nhận máy "TTeccS", đọc bảng kiểm kê (001:T002, T007); làm rồi thì bỏ qua | không | không | không | 15 phút |
| A2 | đóng Orca, báo trưởng phòng; mở lại, báo 18 hồ sơ có hiện không và file cũ mở được (003:T013) | cài 18 hồ sơ pilot khi Orca đóng (003:T012); so băm (003:T014) | có thể làm B2 trong lúc chờ | Orca phải đóng khi trưởng phòng cài | 20 đến 30 phút |
| B1 | cân đai, kiểm puly, ổ bi: Trident rồi V24 (002:T006) | trước: đo cộng hưởng "trước" khi máy nguội (002:T005); sau mỗi máy: đo "sau" (T007), soạn và chạy shaper mới, thử tốc độ (T008, T009) | chạy B2 xen kẽ; đo một Voron khi bạn làm máy kia, giữ yên máy đang đo | Voron phải nguội trước khi đo; Trident qua T009 trước khi chạm V24; xong B1 mới in nhựa trên Voron | 90 phút |
| B2 | bảo trì tay 4 Bambu theo `MAINTENANCE.md`, chạy hiệu chuẩn có sẵn của hãng, chụp màn hình nếu máy không báo ra (004:T007) | đọc lại trạng thái chỉ-đọc, ghi `health_after_<máy>.md` (004:T008) | 4 máy Bambu chạy hiệu chuẩn hãng cùng lúc; xen với B1 | bảo trì tay xong mới bấm hiệu chuẩn; A1 và A1M không hiệu chuẩn khi đang in | 60 phút |
| C | nửa 1: pilot Bambu PLA trên 6 máy; nửa 2: in mẫu chuẩn, đo, điền phiếu `part` | giữa hai nửa: `ingest.ps1` rồi 003:T028 (002:T018, 004:T014); sau nửa 2: `aggregate.ps1` và danh sách cặp lệch (003:T016) | 6 máy in cùng lúc, bấm so le | nửa 2 chỉ bắt đầu sau khi bạn nhập gói hồ sơ mới; kết quả pilot quyết D1 | 4 đến 5 giờ máy chạy; 0,5 kg |
| D1 | như C với Bambu PETG | như C (003:T028 dùng `-Set all`) | 6 máy cùng lúc | pilot PLA đạt; sấy PETG | 3 đến 4 giờ; 0,5 kg |
| D2 | như C với Tinmorry PETG-ECO | như C | 6 máy cùng lúc | D1 xong; đổi nhựa | 3 đến 4 giờ; 0,5 kg |
| E | như C với Tinmorry ABS Pro, chỉ TRI, V24, H2S, P1S, buồng đóng, thông gió | như C | 4 máy cùng lúc; A1 và A1M rảnh, dùng cho in bù của F | buồng nguội mới mở; thông gió | 3 giờ; 0,3 kg |
| F | in bù cặp lệch, thử lắp chéo 3 cặp máy, cắt lớp tay nếu không có CLI, quyết firmware Bambu (003:T018, T019, T025; 004:T020) | tính lại bù (003:T017), báo số đo và nhựa đã dùng từ vòng bù thứ 3 | các cặp lệch in cùng lúc | `aggregate.ps1` có danh sách cặp lệch; nếu pilot chưa đạt, F đầu tiên nằm giữa C và D1 | 2 giờ, lặp lại nếu còn lệch |
| G2 | nạp Octopus Max qua USB/DFU, ở cạnh V24 (002:T027) | nạp EBB36 qua Katapult trước (002:T026), kiểm sau nạp (002:T028) | không | V24 rảnh; có `docs\mcu-reflash-v24.md` đã rà; bạn ở cạnh máy | 60 đến 90 phút |

Nguồn thời lượng: `plan.md:54-66` (ước lượng chưa đo).

## 5. Mỗi buổi in (C, D1, D2, E) diễn ra thế nào

1. Nạp nhựa vào các máy của buổi, chọn đúng hồ sơ `DHH …` trong Orca.
2. **Nửa 1**: làm theo thẻ từng máy. Mỗi bước (lưu lượng tối đa, rồi PA hoặc K, rồi flow) cần đọc kết quả trước khi sang bước sau, nên làm theo **vòng**: bấm in bước 1 trên các máy (so le vài phút để kịp nhìn lớp đầu từng máy), đọc, ghi, rồi sang bước 2. Điền phiếu `cal`.
3. **Chờ trưởng phòng** (vài phút theo kế hoạch): chạy `ingest.ps1`, dựng lại hồ sơ, xuất gói Preset Bundle. Trong lúc chờ: dọn bàn, ghi ảnh, chuẩn bị nhựa buổi sau.
4. Bạn **nhập gói hồ sơ mới vào Orca** (khoảng 5 phút), kiểm tên hồ sơ đúng nhựa.
5. **Nửa 2**: in mẫu chuẩn (a) khung 100 × 100 × 20 và (b) lỗ-chốt Ø8 trên các máy; đo thước cặp **3 lần mỗi hướng** (X, Y), Z, lỗ Ø8; chụp ảnh; điền `calibration\entry\part\<ngày>_<máy>_<nhựa>.csv`.
6. Trưởng phòng chạy `aggregate.ps1`, lập danh sách cặp lệch (003:T016).

## 6. Cổng dừng

- **Sau C**: pilot PLA có cặp lệch quá dung sai (X/Y ±0,1 mm trên 100 mm; Z ±0,1 mm trên 20 mm; lỗ Ø8 ±0,15 mm) thì **dừng**, làm vòng bù (003:T017) rồi F ngay, rồi mới tới D1. Từ vòng thứ 3 của một cặp trưởng phòng báo bạn số đo và nhựa đã dùng trước khi in tiếp (`specs\003-orca-profiles\tasks.md:19`).
- **Voron sau B1**: số đai sau không khá hơn số trước trên một máy thì máy đó giữ shaper cũ (002:T010); các nhựa trên máy đó vẫn in được, chỉ ghi chú.
- Bất kỳ lúc nào máy báo lỗi hay mẫu hỏng liên tục: dừng máy đó, ghi lại, các máy khác vẫn tiếp tục.

## 7. Đề xuất cách cắt

**Ngày 1: bắt buộc** (khoảng 7 đến 8,25 giờ theo cộng ước lượng kế hoạch; thêm khoảng 2 giờ nếu pilot cần vòng bù):
chuẩn bị hôm trước, A1 (nếu chưa), A2, B1 (trọn, vì Voron phải qua đai và shaper mới trước khi in mẫu), B2, C đủ hai nửa, kết quả pilot. Lý do: pilot là cổng của mọi nhựa sau; dừng ở đây thì chưa tốn PETG và ABS.

**Dời được sang ngày sau:**
- **Ngày 2**: D1 và D2 (6 đến 8 giờ theo kế hoạch).
- **Ngày 3**: E, F, G2 (khoảng 6 đến 6,5 giờ). G2 (nạp MCU V2.4) có thể làm bất cứ lúc nào V24 rảnh, độc lập với hiệu chuẩn nhựa; nên làm sau khi V24 xong hết các nhựa.
- Nếu **bắt buộc** nhồi thêm vào ngày 1, dời theo thứ tự: G2 trước, rồi E, rồi D2, rồi D1. Không dời A2, B2, C.
- Nhựa dời ngày thì sấy lại sát ngày dùng; số liệu hiệu chuẩn vẫn gắn đúng `ngày`, `cuộn`.
- Số V24 đo trước khi nạp lại MCU: chưa có nguồn nói MCU mới có đổi PA hay không; trưởng phòng ghi trong sổ khi G2 làm sau.

## 8. Cuối mỗi ngày

- [ ] Mọi file `cal` và `part` của ngày đã lưu; nhãn cuộn khớp.
- [ ] Báo trưởng phòng buổi nào xong, buổi nào dở, buổi nào chưa làm.
- [ ] Tắt máy, dọn bàn, nhựa cất lại (PETG, ABS đậy kín).
- [ ] Ghi chỗ khác thẻ (menu Orca khác tên, bước không làm được) để sửa thẻ cho lần sau.

## 9. Chưa kiểm chứng

Toàn bộ thời lượng; khả năng chạy song song 6 máy với một người; việc đo Voron khi máy kia đang được cân (có nhiễu rung hay không); tên menu Orca trong các thẻ.
