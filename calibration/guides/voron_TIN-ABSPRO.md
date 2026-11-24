# Thẻ hiệu chuẩn Voron: Tinmorry ABS Pro trắng (TIN-ABSPRO)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300), cả hai **buồng đóng**.
Buổi: **Ngày 3, nửa 1** (002:T017). Chỉ làm sau khi PETG ở Ngày 2 đạt. "Trident trước": bắt đầu và đọc kết quả Trident trước; V24 bắt đầu sau, hai máy **được in cùng lúc**.
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Tên hồ sơ: `<Máy>` là TRI = `Voron Trident 250`, V24 = `Voron 2.4 300` (`profiles\NAMING.md`); nhựa `DHH Tinmorry ABS Pro @<Máy>`.

## A. An toàn ABS (đọc trước, bắt buộc)

- [ ] **Buồng đóng** suốt lúc in. ABS chỉ in trên máy có buồng kín (hiến chương, Ràng buộc kỹ thuật).
- [ ] **Phòng thông gió**: mở cửa sổ hoặc bật quạt hút ra ngoài trước khi in; ABS thải hơi khi in. Không ngồi lâu trong phòng đóng kín khi máy in.
- [ ] **Quy trình gỡ mẫu giữa các lần in** (cần 5 đến 6 lần in liên tiếp mỗi máy; không có cách gỡ mẫu khi cửa đóng):
  1. Bấm hủy gia nhiệt khi in xong; **đợi bàn hạ nhiệt theo thói quen của bạn** (dự án không có số nguồn; ghi bạn đợi bao lâu hoặc bàn còn bao nhiêu độ vào `điều_kiện`).
  2. Đeo **găng chịu nhiệt**; mở cửa buồng, gỡ mẫu nhanh, **đóng cửa lại ngay**. Không chạm đầu phun, bàn, thành buồng.
  3. Lau bàn nếu cần, rồi mới bấm in lần sau (buồng cần nóng lại; ABS nứt hoặc cong khi gặp gió lạnh, nên đừng để cửa mở lâu).
- [ ] Có người ở gần suốt các lần in; không để máy in qua đêm cho buổi hiệu chuẩn này.
- [ ] Không thử ABS trên máy hở; thẻ này chỉ cho hai Voron.

## B. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in. Làm nóng buồng theo macro `START_PRINT` hiện có; không đổi macro.
- [ ] Bàn sạch, đúng loại bàn dùng cho ABS.
- [ ] Orca có hồ sơ máy `DHH <Máy> 0.4` và nhựa `DHH Tinmorry ABS Pro @<Máy>`; không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry ABS Pro trắng, nhãn mã cuộn ví dụ `TIN-ABSPRO-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: lưu lượng 22 mm³/s (V24) và 18 (Trident), flow 0,965; co ngót XY 99,39 % (V24), 99,6 % (Trident) (`specs\003-orca-profiles\research.md:27-29`). Đặt "End" của Max flowrate cao hơn số cũ của máy.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa như trên, quy trình `DHH 0.20 Sync @<Máy>`. Đóng buồng, nạp nhựa, chờ đầu in và buồng tới nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**, "End" cao hơn số cũ. In. Tìm **điểm xấu đầu tiên**; **điểm tốt cuối** là vạch ngay dưới. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm; mẫu không in giá trị thì chụp ảnh gửi trưởng phòng (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích).

**Bước 1b. Đặt tạm.** Sửa **tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**, giữ tới hết bước 3. Biên an toàn do trưởng phòng quyết.

**Bước 2. PA.** **Calibration → Pressure Advance → PA Tower**. Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 và 0,0475 nằm trong khoảng). Chọn chỗ góc sắc nhất. Đọc PA **in sẵn trên mẫu**; không in thì chụp ảnh gửi trưởng phòng. PA đến Klipper qua G-code Orca; không SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất; đọc số in trên tấm; áp vào Flow ratio **tạm** theo hướng dẫn hộp thoại Orca (dự án không có công thức), **không Save**. **Pass 2** tương tự. Không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu thì chọn bỏ. Mẫu cong mép hoặc bong bàn: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt.

## D. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-ABSPRO.csv`, ví dụ `2026-12-07_TRI_TIN-ABSPRO.csv`, `2026-12-07_V24_TIN-ABSPRO.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập:** mở bằng Notepad hoặc VS Code (không Excel); lưu **UTF-8**; số thập phân **dấu chấm**; **không dấu phẩy trong ô chữ** (dùng dấu chấm phẩy); **xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có `ĐIỀN_NGUỒN`), script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối; `điều_kiện` ghi cả điểm tốt cuối và điểm xấu đầu. Ví dụ dòng (số **giả**):

```
TRI,TIN-ABSPRO,flow_ratio,XX,tỷ_lệ,đo,Orca Flow Rate Pass 2; ảnh 2026-12-07_TRI_TIN-ABSPRO_flow.jpg,2026-12-07,TIN-ABSPRO-01,buồng đóng; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## E. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`. Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca; việc mẫu Orca có in sẵn giá trị hay không; PA 0 → 0,1 là điểm xuất phát; quy trình gỡ mẫu khi buồng còn ấm; chưa có số sấy; các điều kiện an toàn là khuyến cáo chung, chưa có nguồn riêng của hãng Tinmorry trong dự án.

Nguồn: `specs\002-voron-tuning\tasks.md:61`, `.specify\memory\constitution.md:69-70`, `docs\data-formats.md:30-54`.
