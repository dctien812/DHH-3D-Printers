# Thẻ hiệu chuẩn Voron: Tinmorry PETG-ECO trắng (TIN-PETGECO)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300). Làm Trident trước, V24 sau; in cùng lúc được.
Buổi: **D2, nửa 1** (002:T016). Chỉ làm sau khi pilot PLA đạt.
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.

## A. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in, đầu in nguội.
- [ ] Bàn sạch (nếu D1 vừa in PETG: gỡ hết sợi và cặn nhựa cũ trên bàn và đầu phun trước khi đổi nhựa, vì hai nhựa cùng họ nhưng khác hãng).
- [ ] Orca có hồ sơ `DHH Tinmorry PETG-ECO @<Máy>` (tên đủ xem `profiles\NAMING.md` khi có). Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry PETG-ECO trắng, nhãn mã cuộn ví dụ `TIN-PETGECO-01`. Sấy theo nhãn hãng. Dự án chưa có số sấy từ nguồn nào: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: PETG-ECO lưu lượng 12–13 mm³/s trên A1 và A1 Mini (`specs\003-orca-profiles\research.md:28-29`); chưa có số cho hai Voron.
- [ ] Thước cặp, điện thoại chụp ảnh, `TEMPLATE_cal.csv`.

## B. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Tinmorry PETG-ECO @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Nạp nhựa, chờ đầu in tới nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**. Giữ khoảng mặc định của hộp thoại (điểm xuất phát, chưa đo); còn đẹp tới đỉnh thì nâng "End". Tìm độ cao bắt đầu xấu, đọc lưu lượng ở tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. PA.** **Calibration → Pressure Advance → PA Tower**. Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 và 0,0475 nằm trong khoảng, `SUMMARY.md:25`). Chọn độ cao có góc sắc nhất, đổi sang PA theo hộp thoại. Ghi `pa`. PA đến Klipper qua G-code Orca; không SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100; sửa tạm Flow ratio, **không Save**. **Pass 2** tương tự. Ghi `flow_ratio`. Orca hỏi lưu thì chọn bỏ.

## C. Ghi phiếu

Sao chép `calibration\entry\cal\TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-PETGECO.csv`, ví dụ `2026-12-05_TRI_TIN-PETGECO.csv`, `2026-12-05_V24_TIN-PETGECO.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
V24,TIN-PETGECO,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-05_V24_TIN-PETGECO_mvs.jpg,2026-12-05,TIN-PETGECO-01,số thô; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## D. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018). Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## E. An toàn

Đầu phun và bàn nóng; gỡ sợi bằng kẹp. Không bỏ máy trong lớp đầu.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca và công thức đọc số; PA 0 → 0,1 là điểm xuất phát; chưa có số sấy từ nguồn.

Nguồn: `specs\002-voron-tuning\tasks.md:60`, `specs\003-orca-profiles\plan.md:62`, `docs\data-formats.md:30-54`.
