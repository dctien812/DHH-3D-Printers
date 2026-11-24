# Thẻ hiệu chuẩn Bambu: Tinmorry ABS Pro trắng (TIN-ABSPRO)

Máy: chỉ hai máy buồng kín: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày) và **P1S**. Thẻ này không dành cho máy hở.
Buổi: **Ngày 3, nửa 1** (004:T017). Chỉ làm sau khi PETG đạt trên các máy Bambu (không cần chờ Voron); nếu lệch thì bù và in lại trước, dời ABS nếu cần (`RUN-DAY.md` mục 6).
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Văn phòng **không gửi lệnh điều khiển nào tới máy Bambu** (ngoài `pushall` chỉ-đọc theo hiến chương III): mọi lần in do bạn bấm.
Tên hồ sơ: `<Máy>` là H2S = `H2S`, P1S = `P1S` (`profiles\NAMING.md`); nhựa `DHH Tinmorry ABS Pro @<Máy>`.

## A. An toàn ABS (đọc trước, bắt buộc)

- [ ] **Buồng đóng** suốt lúc in. ABS chỉ in trên máy có buồng kín (hiến chương, Ràng buộc kỹ thuật).
- [ ] **Phòng thông gió**: mở cửa sổ hoặc bật quạt hút ra ngoài trước khi in; ABS thải hơi khi in. Không ngồi lâu trong phòng đóng kín khi máy in. Lọc than của máy (H2S có lọc than trong lịch bảo trì, `research.md:48`) không thay cho thông gió phòng.
- [ ] **Quy trình gỡ mẫu giữa các lần in** (cần khoảng 5 đến 6 lần in liên tiếp mỗi máy kể cả nửa 2: mvs, K, flow Pass 1 và Pass 2, mẫu (a), mẫu (b); không có cách gỡ mẫu khi cửa đóng):
  1. Khi in xong, **đợi bàn hạ nhiệt theo thói quen của bạn** (dự án không có số nguồn; ghi bạn đợi bao lâu hoặc bàn còn bao nhiêu độ vào `điều_kiện`).
  2. Đeo **găng chịu nhiệt**; mở cửa, gỡ mẫu nhanh, **đóng cửa lại ngay**. Không chạm đầu phun, bàn, thành buồng.
  3. Rồi mới bấm in lần sau (ABS nứt hoặc cong khi gặp gió lạnh, nên đừng để cửa mở lâu).
- [ ] Có người ở gần suốt các lần in dài; không để máy in qua đêm cho buổi hiệu chuẩn này.
- [ ] H2S: ABS qua AMS có thể khác cách bạn dùng hằng ngày; nạp **đúng như bạn vẫn làm** và ghi cách nạp vào `điều_kiện`. Dự án chưa có nguồn nói ABS Pro qua AMS có phù hợp hay không.

## B. Quy tắc K

- K **lưu trên máy**, theo bộ có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca (research.md:39-41).
- H2S: máy tự đo (suy ra từ H2D, research.md:30-32). **P1S: chỉ đo tay**, không có ô Flow Dynamics. Ô: Auto / On / Off (research.md:33-35).
- Nếu ở thẻ PLA máy **không** chạy quy trình đo K khi chọn On, đừng dựa vào ô On: hỏi trưởng phòng đường khác.
- Đổi hãng nhựa thì hiệu chuẩn lại K (research.md:37): đừng mượn K của nhựa khác.

## C. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi; buồng nguội, sạch. Bàn đúng loại dùng cho ABS, sạch.
- [ ] Orca có hồ sơ `DHH Tinmorry ABS Pro @<Máy>` cho H2S và P1S. Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry ABS Pro trắng, nhãn mã cuộn ví dụ `TIN-ABSPRO-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: lưu lượng ABS 22 (V24), 18 (Trident) mm³/s, flow 0,965, trên Voron; chưa có số cho hai máy Bambu (`specs\003-orca-profiles\research.md:27-29`).
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## D. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa như trên, quy trình `DHH 0.20 Sync @<Máy>`. Đóng buồng, chờ nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"), ô Flow Dynamics **Auto**. In. Tìm **điểm xấu đầu tiên**; **điểm tốt cuối** là vạch ngay dưới. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm; mẫu không in giá trị thì suy ra: giá trị = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (cách suy từ tham số hộp thoại, **chưa thử trên máy này**). Dù mẫu có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm), dạng `Start=5; End=20; Step=0.5; cao=23.5mm` (dấu chấm phẩy, thập phân dấu chấm, số mẫu là giả), để trưởng phòng tính lại (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích). **Đặt tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**, giữ tới hết bước 3. Biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S:** in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; quan sát máy có chạy quy trình đo K trước khi in không. Có: đọc K của khe ở trang Device hoặc màn hình máy (chưa thử trên máy này). Không: `k` = `chưa_đo`, báo trưởng phòng.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc Pattern), khoảng mặc định (điểm xuất phát; mở rộng nếu vạch đẹp nhất sát mép). Đọc K **in sẵn trên mẫu** (luôn ghi vào `điều_kiện` Start, End, Step của hộp thoại và số thứ tự vạch đã chọn (dạng `Start=0; End=0.1; Step=0.002; vạch=7`, dấu chấm phẩy, thập phân dấu chấm, số mẫu là giả), kèm ảnh, để trưởng phòng tính lại). Nhập thành bộ K có tên (ví dụ `DHH-TIN-ABSPRO-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập chưa thử trên máy này.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1** (ô **Auto**), chọn tấm mặt trên mịn nhất; đọc số in trên tấm; áp vào Flow ratio **tạm** theo hướng dẫn hộp thoại Orca (dự án không có công thức), **không Save**. **Pass 2** tương tự. Không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu thì chọn bỏ. Mẫu cong mép hoặc bong bàn: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt.

## E. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-ABSPRO.csv`, ví dụ `2026-12-07_H2S_TIN-ABSPRO.csv` và `2026-12-07_P1S_TIN-ABSPRO.csv`. Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập:** mở bằng Notepad hoặc VS Code (không Excel); lưu **UTF-8**; số thập phân **dấu chấm**; **không dấu phẩy trong ô chữ** (dùng dấu chấm phẩy); **xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có `ĐIỀN_NGUỒN`), script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối; `điều_kiện` ghi cả điểm tốt cuối và điểm xấu đầu. Ví dụ dòng (số **giả**):

```
P1S,TIN-ABSPRO,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-07_P1S_TIN-ABSPRO_mvs.jpg,2026-12-07,TIN-ABSPRO-01,tốt_cuối=XX; xấu_đầu=YY; buồng đóng; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## F. Sau khi xong

Chờ buồng nguội rồi mới thu dọn. Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`.

## G. Chưa thử trên máy này

Tên menu Orca; việc mẫu Orca có in sẵn giá trị hay không; chỗ đọc K và đường nhập K tay; hiệu lực của ô Flow Dynamics từ Orca; ABS Pro qua AMS; quy trình gỡ mẫu khi buồng còn ấm; chưa có số sấy; các điều kiện an toàn là khuyến cáo chung, chưa có nguồn riêng của hãng Tinmorry trong dự án.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,45`, `.specify\memory\constitution.md:69-70`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
