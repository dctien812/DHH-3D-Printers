# Thẻ hiệu chuẩn Voron: Tinmorry PETG-ECO trắng (TIN-PETGECO)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300).
Buổi: **Ngày 2, nửa 1 của lượt D2** (002:T016), sau lượt Bambu PETG Basic. Chỉ làm sau khi PLA trên 4 máy Bambu đạt.
"Trident trước": bắt đầu và đọc kết quả Trident trước; V24 bắt đầu sau, hai máy **được in cùng lúc**, chỉ cần một người nhìn.
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Tên hồ sơ: `<Máy>` là TRI = `Voron Trident 250`, V24 = `Voron 2.4 300` (`profiles\NAMING.md`); nhựa `DHH Tinmorry PETG-ECO @<Máy>`.

## A. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in, đầu in nguội, bàn trống.
- [ ] Gỡ sợi và cặn của lượt PETG Basic khỏi bàn và đầu phun trước khi đổi nhựa.
- [ ] Orca có hồ sơ máy `DHH <Máy> 0.4` và nhựa `DHH Tinmorry PETG-ECO @<Máy>`; không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry PETG-ECO trắng, nhãn mã cuộn ví dụ `TIN-PETGECO-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: PETG-ECO lưu lượng 12–13 mm³/s trên A1 và A1 Mini (`specs\003-orca-profiles\research.md:28-29`); chưa có số cho hai Voron.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## B. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa như trên, quy trình `DHH 0.20 Sync @<Máy>`. Nạp nhựa, chờ nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"). In. Tìm **điểm xấu đầu tiên**; **điểm tốt cuối** là vạch ngay dưới. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm; mẫu không in giá trị thì suy ra: giá trị = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (cách suy từ tham số hộp thoại, **chưa thử trên máy này**). Dù mẫu có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm), dạng `Start=0; End=0.1; Step=0.002; cao=23.5mm` (dấu chấm phẩy, thập phân dấu chấm, số mẫu là giả), để trưởng phòng tính lại (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích).

**Bước 1b. Đặt tạm.** Sửa **tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**, giữ tới hết bước 3. Biên an toàn do trưởng phòng quyết.

**Bước 2. PA.** **Calibration → Pressure Advance → PA Tower**. Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 và 0,0475 nằm trong khoảng, `SUMMARY.md:25`). Chọn chỗ góc sắc nhất. Đọc PA **in sẵn trên mẫu**; không in thì suy ra (nếu dùng PA Pattern thì ghi Start, End, Step và số thứ tự vạch như P1S; công thức sau chỉ cho Tower): PA = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (chưa thử trên máy này). Dù có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm), dạng `Start=0; End=0.1; Step=0.002; cao=23.5mm` (số mẫu là giả). PA đến Klipper qua G-code Orca; không SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất; đọc số in trên tấm; áp vào Flow ratio **tạm** theo hướng dẫn hộp thoại Orca (dự án không có công thức), **không Save**. **Pass 2** tương tự. Không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu thì chọn bỏ.

## C. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-PETGECO.csv`, ví dụ `2026-12-06_TRI_TIN-PETGECO.csv`, `2026-12-06_V24_TIN-PETGECO.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập:** mở bằng Notepad hoặc VS Code (không Excel); lưu **UTF-8**; số thập phân **dấu chấm**; **không dấu phẩy trong ô chữ** (dùng dấu chấm phẩy); **xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có `ĐIỀN_NGUỒN`), script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối (giới hạn đo được, chưa trừ biên); mức đặt sau biên ghi ở `profiles\src\materials.csv` với trạng thái `đo` và được giữ khi dựng; `điều_kiện` ghi cả điểm tốt cuối và điểm xấu đầu. Ví dụ dòng (số **giả**):

```
V24,TIN-PETGECO,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-06_V24_TIN-PETGECO_mvs.jpg,2026-12-06,TIN-PETGECO-01,tốt_cuối=XX; xấu_đầu=YY; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## D. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`. Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## E. An toàn

Đầu phun và bàn nóng; gỡ sợi bằng kẹp. Không bỏ máy trong lớp đầu.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca; việc mẫu Orca có in sẵn giá trị hay không; PA 0 → 0,1 là điểm xuất phát; chưa có số sấy từ nguồn.

Nguồn: `specs\002-voron-tuning\tasks.md:60`, `docs\data-formats.md:30-54`.
