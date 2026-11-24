# Thẻ hiệu chuẩn Bambu: Bambu PETG Basic trắng (BAMBU-PETG)

Máy: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày), **P1S**, **A1**, **A1M** (A1 Mini).
Buổi: **Ngày 2, nửa 1 của lượt D1** (004:T012). Chỉ làm sau khi PLA đạt và sau khi đã đọc kết quả bước 2 của thẻ PLA.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Văn phòng **không gửi lệnh điều khiển nào tới máy Bambu** (ngoài `pushall` chỉ-đọc theo hiến chương III): mọi lần in do bạn bấm.
Tên hồ sơ: `<Máy>` là H2S = `H2S`, P1S = `P1S`, A1 = `A1`, A1M = `A1 Mini` (`profiles\NAMING.md`); nhựa `DHH Bambu PETG Basic @<Máy>` (mã nhựa vẫn `BAMBU-PETG`).

## A. Quy tắc K

- K **lưu trên máy**, theo bộ có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca (research.md:39-41).
- H2S, A1, A1M: máy tự đo (H2S là suy ra từ H2D). **P1S: chỉ đo tay**, không có ô Flow Dynamics (research.md:30-32). Ô: Auto / On / Off (research.md:33-35).
- Nếu ở thẻ PLA máy **không** chạy quy trình đo K khi chọn On, **đừng dựa vào ô On**: hỏi trưởng phòng đường đo K khác trước bước 2.
- A1 và A1M không cho hiệu chuẩn khi đang in (research.md:13).

| Máy | Nhựa vào máy | Cách có K | Ghi thêm vào `điều_kiện` |
|---|---|---|---|
| H2S | khe AMS | máy tự đo | khe AMS, loại đầu phun |
| P1S | cuộn ngoài | đo tay, nhập K lên máy | tên bộ K |
| A1 | cuộn ngoài | máy tự đo | nơi nạp nhựa |
| A1M | cuộn ngoài | máy tự đo | nơi nạp nhựa |

## B. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi.
- [ ] Bàn sạch. PETG có thể dính chặt lên bàn nhẵn: nếu bạn thường dùng lớp chống dính mỏng thì dùng, ghi vào `điều_kiện`.
- [ ] Orca có hồ sơ `DHH Bambu PETG Basic @<Máy>`. Không thấy thì dừng, báo trưởng phòng. Dùng hồ sơ DHH, không dùng hồ sơ hệ thống (`specs\003-orca-profiles\research.md:20-21`).
- [ ] Nhựa: cuộn Bambu PETG Basic trắng, nhãn mã cuộn ví dụ `BAMBU-PETG-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`). H2S: ghi thêm thời gian cuộn đã nằm trong AMS.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa như trên, quy trình `DHH 0.20 Sync @<Máy>`. H2S: chọn đúng khe AMS.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"), ô Flow Dynamics **Auto**. In. Tìm **điểm xấu đầu tiên**; **điểm tốt cuối** là vạch ngay dưới. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm; mẫu không in giá trị thì suy ra: giá trị = Start + (chiều cao đo ÷ chiều cao mỗi bậc) × Step, với Start, Step và chiều cao mỗi bậc đọc ở hộp thoại lúc tạo mẫu (cách suy từ tham số hộp thoại, **chưa thử trên máy này**). Dù mẫu có in số hay không, ghi vào `điều_kiện` Start, End, Step và chiều cao đo bằng thước cặp (mm) để trưởng phòng tính lại (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích). **Đặt tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**, giữ tới hết bước 3. Biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S, A1, A1M:** in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; quan sát máy có chạy quy trình đo K trước khi in không. Có: đọc K của khe ở trang Device hoặc màn hình máy (chưa thử đường nào trên máy này). Không: `k` = `chưa_đo`, báo trưởng phòng.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc Pattern), khoảng mặc định (điểm xuất phát; mở rộng nếu vạch đẹp nhất sát mép). Đọc K **in sẵn trên mẫu** (luôn ghi vào `điều_kiện` Start, End, Step của hộp thoại và số thứ tự vạch đã chọn, kèm ảnh, để trưởng phòng tính lại). Nhập thành bộ K có tên (ví dụ `DHH-BAMBU-PETG-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập chưa thử trên máy này.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1** (ô **Auto**), chọn tấm mặt trên mịn nhất; đọc số in trên tấm; áp vào Flow ratio **tạm** theo hướng dẫn hộp thoại Orca (dự án không có công thức), **không Save** hồ sơ DHH. **Pass 2** tương tự. Không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu thì chọn bỏ.

PETG kéo sợi: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt hay thu hồi.

## D. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PETG.csv`, ví dụ `2026-12-06_P1S_BAMBU-PETG.csv` (và `H2S`, `A1`, `A1M`). Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập:** mở bằng Notepad hoặc VS Code (không Excel); lưu **UTF-8**; số thập phân **dấu chấm**; **không dấu phẩy trong ô chữ** (dùng dấu chấm phẩy); **xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có `ĐIỀN_NGUỒN`), script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối; `điều_kiện` ghi cả điểm tốt cuối và điểm xấu đầu. Ví dụ dòng (số **giả**):

```
P1S,BAMBU-PETG,k,XX,-,đo,Orca PA Line đo tay; ảnh 2026-12-06_P1S_BAMBU-PETG_k.jpg,2026-12-06,BAMBU-PETG-01,bộ K DHH-BAMBU-PETG-2026-12-06
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## E. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`.

## F. An toàn

Đầu phun và bàn nóng; gỡ sợi bằng kẹp. Không để tay vào trục khi máy chạy hiệu chuẩn.

## G. Chưa thử trên máy này

Tên menu Orca; việc mẫu Orca có in sẵn giá trị hay không; chỗ đọc K và đường nhập K tay; hiệu lực của ô Flow Dynamics từ Orca; chưa có số sấy từ nguồn.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,40`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
