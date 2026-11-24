# Thẻ hiệu chuẩn Voron: Bambu PETG Basic trắng (BAMBU-PETG)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300). Hai Voron không in PLA trong đợt này; PETG là phép thử kích thước đầu tiên của hai máy.
Buổi: **Ngày 2, nửa 1** (002:T015). Chỉ làm sau khi PLA trên 4 máy Bambu đạt và sau khi hai Voron qua B1 (đai, shaper) ở Ngày 1.
"Trident trước": bắt đầu và đọc kết quả Trident trước; V24 bắt đầu sau, hai máy **được in cùng lúc**, chỉ cần một người nhìn.
Trạng thái thẻ: soạn theo tài liệu, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Tên hồ sơ trong Orca: `<Máy>` là TRI = `Voron Trident 250`, V24 = `Voron 2.4 300` (`profiles\NAMING.md`). Nhựa là `DHH Bambu PETG Basic @<Máy>` (mã nhựa vẫn `BAMBU-PETG`).

## A. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không lệnh in, đầu in nguội, bàn trống.
- [ ] V24: bảng vật liệu Klippain không có PETG nhưng `material_profiles_enabled = False` nên không chặn (`fleet\precheck\2026-11-24\SUMMARY.md:23-24`). Trưởng phòng xác nhận 002:T037 xong.
- [ ] Bàn sạch. PETG có thể dính chặt lên bàn nhẵn: nếu bạn thường dùng lớp chống dính mỏng cho PETG thì dùng, ghi vào `điều_kiện`.
- [ ] Orca có hồ sơ máy `DHH <Máy> 0.4` và nhựa `DHH Bambu PETG Basic @<Máy>`; không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Bambu PETG Basic trắng, nhãn mã cuộn ví dụ `BAMBU-PETG-01` (ghi giống hệt vào `cuộn`). Sấy theo nhãn hãng; dự án chưa có số sấy từ nguồn nào, ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## B. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa như trên, quy trình `DHH 0.20 Sync @<Máy>`. Nạp nhựa, chờ đầu in tới nhiệt mặc định.

**Bước 1. mvs.** Menu **Calibration → Max flowrate**. Khoảng quét giữ mặc định hộp thoại (điểm xuất phát, chưa đo); còn đẹp tới đỉnh thì nâng "End" và in lại. In. Nhìn: tìm **điểm xấu đầu tiên** (thiếu nhựa, hở, thô). **Điểm tốt cuối** là vạch ngay dưới nó. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm đó; nếu mẫu không in giá trị thì suy ra: giá trị = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (cách suy từ tham số hộp thoại, **chưa thử trên máy này**). Dù mẫu có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm) để trưởng phòng tính lại (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích). Dự án không có công thức nào khác.

**Bước 1b. Đặt tạm.** Trong Orca sửa **tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**; giữ nguyên cho tới hết bước 3 để PA và flow không bị đo với số cũ cao hơn thực tế. Biên an toàn trừ bớt do trưởng phòng quyết khi đưa vào hồ sơ.

**Bước 2. PA.** **Calibration → Pressure Advance → PA Tower** (hoặc PA Pattern; ghi cách đã dùng). Khoảng quét điểm xuất phát **0 → 0,1** (chưa đo; 0,02 đang chạy và 0,0475 cấu hình gốc nằm trong khoảng, `SUMMARY.md:25`; 0,02 chưa phải số đo cho PETG, `SUMMARY.md:57`). In. Nhìn góc: chọn chỗ góc sắc nhất, không phồng. Đọc giá trị PA **in sẵn trên mẫu**; nếu không in thì suy ra: PA = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (chưa thử trên máy này). Dù có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm). PA đến Klipper qua G-code Orca; không chạy SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg`.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1**, chọn tấm mặt trên mịn nhất (sờ và nhìn nghiêng dưới đèn). Đọc số in trên tấm đó; áp vào Flow ratio **tạm** theo hướng dẫn trong hộp thoại Orca (dự án không có công thức), **không Save**. Làm **Pass 2** tương tự. Bỏ qua các mục YOLO. Ghi Flow ratio sau Pass 2; không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu hồ sơ thì chọn bỏ.

PETG hay kéo sợi: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt hay thu hồi.

## C. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PETG.csv`, ví dụ `2026-12-06_TRI_BAMBU-PETG.csv` và `2026-12-06_V24_BAMBU-PETG.csv`. Bốn dòng: `mvs`, `pa`, `flow_ratio`, `temp_nozzle` (`mặc_định`, giá trị đọc từ hồ sơ). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập (dễ hỏng nếu làm khác):**
- Mở bằng Notepad hoặc VS Code, **không dùng Excel** (Excel đổi dấu thập phân và mã hóa).
- Lưu **UTF-8**. Số thập phân dùng **dấu chấm** (`0.040`, không phải `0,040`).
- **Không dùng dấu phẩy trong ô chữ** (nhất là `nguồn`, `điều_kiện`); dùng dấu chấm phẩy để ngăn ý.
- **Xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có chữ `ĐIỀN_NGUỒN`, `ĐIỀN_CUỘN`); script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối (số đã đặt tạm); `điều_kiện` ghi cả hai điểm. Ví dụ dòng (số **giả**):

```
TRI,BAMBU-PETG,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-06_TRI_BAMBU-PETG_mvs.jpg,2026-12-06,BAMBU-PETG-01,tốt_cuối=XX; xấu_đầu=YY; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`, thiếu thì bị từ chối. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## D. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`. Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## E. An toàn

Đầu phun và bàn nóng. Gỡ sợi PETG bằng kẹp, không bằng tay trần khi đầu còn nóng. Không bỏ máy trong lớp đầu.

## F. Chưa thử trên máy này

Toàn bộ đường đi Orca; việc mẫu Orca có in sẵn giá trị hay không; PA 0 → 0,1 là điểm xuất phát; việc Orca đưa PA vào Klipper (suy từ `SUMMARY.md:23-25`); chưa có số sấy từ nguồn.

Nguồn: `specs\002-voron-tuning\tasks.md:56-59`, `docs\data-formats.md:30-54`, `calibration\entry\cal\TEMPLATE_cal.csv`.
