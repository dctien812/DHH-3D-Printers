# Thẻ hiệu chuẩn Voron: Bambu PETG trắng (BAMBU-PETG)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300). Làm Trident trước, V24 sau; in cùng lúc được.
Buổi: **D1, nửa 1** (002:T015). **Chỉ làm sau khi pilot PLA đạt**, kể cả các vòng bù của pilot (`specs\002-voron-tuning\tasks.md:59`).
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.

## A. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in, đầu in nguội. Lúc kiểm 2026-11-24 cả hai máy đang in file PETG (`fleet\precheck\2026-11-24\SUMMARY.md:11`), PA khi đó là 0,02, **chưa phải số đã đo cho PETG** (`SUMMARY.md:57`).
- [ ] V24: bảng vật liệu Klippain của V24 không có PETG, nhưng `material_profiles_enabled = False` nên không chặn (`SUMMARY.md:23-24`). Trưởng phòng xác nhận xong 002:T037 trước buổi này.
- [ ] Bàn sạch. PETG có thể dính rất chặt lên bàn nhẵn, dễ làm hỏng mặt bàn khi gỡ: nếu bạn thường dùng lớp chống dính mỏng cho PETG thì dùng và ghi vào `điều_kiện` (kinh nghiệm chung, chưa có nguồn trong dự án).
- [ ] Orca có hồ sơ `DHH Bambu PETG @<Máy>` (gói đủ 22 hồ sơ, 003:T024). Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Bambu PETG trắng, nhãn mã cuộn ví dụ `BAMBU-PETG-01`. PETG hút ẩm: sấy theo nhãn hãng. Dự án chưa có số sấy từ nguồn nào, ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Thước cặp, điện thoại chụp ảnh, `TEMPLATE_cal.csv`.

## B. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Bambu PETG @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Nạp nhựa, chờ đầu in tới nhiệt mặc định.

**Bước 1. mvs.** Menu **Calibration → Max flowrate**. Khoảng quét giữ mặc định hộp thoại (điểm xuất phát, chưa đo); còn đẹp tới đỉnh thì nâng "End". In, tìm độ cao bắt đầu xấu, đọc lưu lượng tại lớp đó bằng tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. PA.** Menu **Calibration → Pressure Advance → PA Tower**. Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 và 0,0475 nằm trong khoảng). Chọn độ cao có góc sắc nhất, đổi sang PA bằng công thức hộp thoại. Ghi `pa`. PA đến Klipper qua G-code Orca (`SUMMARY.md:23-25`); không SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100; sửa tạm Flow ratio, **không Save** hồ sơ DHH. **Pass 2** tương tự. Ghi `flow_ratio`. Orca hỏi lưu thì chọn bỏ.

PETG hay kéo sợi: có sợi trên mẫu thì chụp ảnh, ghi vào `điều_kiện`, không tự chỉnh nhiệt hay thu hồi.

## C. Ghi phiếu

Sao chép `calibration\entry\cal\TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PETG.csv`, ví dụ `2026-12-05_TRI_BAMBU-PETG.csv`, `2026-12-05_V24_BAMBU-PETG.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (trạng thái `mặc_định`, giá trị đọc từ hồ sơ). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
TRI,BAMBU-PETG,pa,XX,s,đo,Orca PA Tower; ảnh 2026-12-05_TRI_BAMBU-PETG_pa.jpg,2026-12-05,BAMBU-PETG-01,quét 0-0.1; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`, thiếu thì bị từ chối. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## D. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018). Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## E. An toàn

Đầu phun và bàn nóng. Gỡ sợi PETG bằng kẹp, không bằng tay trần khi đầu còn nóng. Không bỏ máy trong lớp đầu.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca và công thức đọc số; PA 0 → 0,1 là điểm xuất phát; chưa có số sấy từ nguồn.

Nguồn: `specs\002-voron-tuning\tasks.md:56-59`, `specs\003-orca-profiles\plan.md:61`, `docs\data-formats.md:30-54`.
