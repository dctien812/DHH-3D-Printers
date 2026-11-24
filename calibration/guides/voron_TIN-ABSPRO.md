# Thẻ hiệu chuẩn Voron: Tinmorry ABS Pro trắng (TIN-ABSPRO)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300), cả hai **buồng đóng**. Làm Trident trước, V24 sau.
Buổi: **E, nửa 1** (002:T017). Chỉ làm sau khi pilot PLA đạt.
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.

## A. An toàn ABS (đọc trước, bắt buộc)

- [ ] **Buồng đóng**: cửa và nắp đóng kín suốt lúc in và lúc nguội. ABS chỉ in trên máy có buồng kín (hiến chương, Ràng buộc kỹ thuật).
- [ ] **Phòng thông gió**: mở cửa sổ hoặc bật quạt hút ra ngoài trước khi in; ABS thải hơi khi in. Không ngồi lâu trong phòng đóng kín khi máy in. Bộ lọc của máy (nếu có) không thay cho thông gió phòng.
- [ ] Không mở cửa buồng để gỡ mẫu khi buồng còn nóng; chờ nguội (ABS nứt và cong khi gặp gió lạnh, đầu và bàn còn nóng).
- [ ] Có người ở gần suốt các lần in dài (cháy nổ hiếm nhưng máy đang nóng); không để máy in qua đêm cho buổi hiệu chuẩn này.
- [ ] Không chạm đầu phun, bàn, thành buồng khi vừa in xong.
- [ ] Không thử ABS trên máy hở; thẻ này chỉ cho hai Voron.

## B. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in. Làm nóng buồng theo macro `START_PRINT` hiện có của máy; không đổi macro.
- [ ] Bàn sạch, đúng loại bàn dùng cho ABS.
- [ ] Orca có hồ sơ `DHH Tinmorry ABS Pro @<Máy>` (tên đủ xem `profiles\NAMING.md` khi có). Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry ABS Pro trắng, nhãn mã cuộn ví dụ `TIN-ABSPRO-01`. ABS cũng cần khô: sấy theo nhãn hãng. Dự án chưa có số sấy từ nguồn nào: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: lưu lượng 22 mm³/s (V24) và 18 (Trident), flow 0,965; co ngót XY 99,39 % (V24), 99,6 % (Trident) (`specs\003-orca-profiles\research.md:27-29`). Đặt "End" của Max flowrate cao hơn số cũ của máy.
- [ ] Thước cặp, điện thoại chụp ảnh, `TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Tinmorry ABS Pro @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Đóng buồng, nạp nhựa, chờ đầu in và buồng tới nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**. Khoảng "Start/End" ở điểm xuất phát: mặc định hộp thoại, nhưng "End" phải cao hơn số cũ. Tìm độ cao bắt đầu xấu, đọc lưu lượng ở tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. PA.** **Calibration → Pressure Advance → PA Tower**. Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 và 0,0475 nằm trong khoảng). Chọn độ cao có góc sắc nhất, đổi sang PA theo hộp thoại. Ghi `pa`. PA đến Klipper qua G-code Orca; không SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100; sửa tạm Flow ratio, **không Save**. **Pass 2** tương tự. Ghi `flow_ratio`. Orca hỏi lưu thì chọn bỏ. Nếu mẫu cong mép hoặc bong bàn thì ghi vào `điều_kiện` và chụp ảnh, không tự chỉnh nhiệt.

## D. Ghi phiếu

Sao chép `calibration\entry\cal\TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-ABSPRO.csv`, ví dụ `2026-12-05_TRI_TIN-ABSPRO.csv`, `2026-12-05_V24_TIN-ABSPRO.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
TRI,TIN-ABSPRO,flow_ratio,XX,tỷ_lệ,đo,Orca Flow Rate Pass 2; ảnh 2026-12-05_TRI_TIN-ABSPRO_flow.jpg,2026-12-05,TIN-ABSPRO-01,buồng đóng; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## E. Sau khi xong

Chờ buồng nguội rồi mới mở. Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018). Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca và công thức đọc số; PA 0 → 0,1 là điểm xuất phát; chưa có số sấy; các điều kiện an toàn là khuyến cáo chung, chưa có nguồn riêng của hãng Tinmorry trong dự án.

Nguồn: `specs\002-voron-tuning\tasks.md:61`, `.specify\memory\constitution.md:69-70`, `specs\003-orca-profiles\plan.md:63`, `docs\data-formats.md:30-54`.
