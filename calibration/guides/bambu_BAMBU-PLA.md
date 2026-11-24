# Thẻ hiệu chuẩn Bambu: Bambu PLA trắng (BAMBU-PLA)

Máy: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày), **P1S**, **A1**, **A1M** (A1 Mini). Hai Voron không in PLA trong đợt này.
Buổi: **Ngày 1, nửa 1** (pilot, 004:T011). Pilot chưa đạt thì PETG và ABS không chạy.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio** (theo hướng dẫn hiệu chuẩn của Orca; người dùng chốt, ghi ở `.office\ledger.md`). Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.
Văn phòng **không gửi lệnh điều khiển nào tới máy Bambu** (ngoài `pushall` chỉ-đọc theo hiến chương III): mọi lần in do bạn bấm trong Orca hoặc trên máy.
Tên hồ sơ: `<Máy>` là H2S = `H2S`, P1S = `P1S`, A1 = `A1`, A1M = `A1 Mini` (`profiles\NAMING.md`); nhựa `DHH Bambu PLA @<Máy>`.

## A. Quy tắc K (đọc trước)

- K (tương đương PA) được **lưu trên máy**, theo bộ tham số có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca của máy Bambu, để K chỉ bù ở một nơi là máy (research.md:39-41).
- H2S, A1, A1M: máy tự đo K (H2S là suy ra từ H2D, research.md:30-32). **P1S chỉ đo tay**, không có ô "Flow Dynamics Calibration" (research.md:30-31).
- Ô "Flow Dynamics Calibration" khi gửi in: Auto / On (đo trước mỗi lần in) / Off (dùng K đã đặt cho khe; không có thì mặc định) (research.md:33-35).
- A1 và A1M (firmware 01.09.00.00) không cho hiệu chuẩn khi đang in (research.md:13): chỉ bắt đầu khi máy rảnh.

| Máy | Nhựa vào máy | Cách có K | Ô Flow Dynamics | Ghi thêm vào `điều_kiện` |
|---|---|---|---|---|
| H2S | khe AMS (ghi số khe; gán đúng loại nhựa cho khe) | máy tự đo | có | khe AMS, loại đầu phun |
| P1S | cuộn ngoài | **đo tay**, nhập K lên máy | không có | tên bộ K đã đặt |
| A1 | cuộn ngoài (ghi nếu dùng AMS lite) | máy tự đo | có | nơi nạp nhựa |
| A1M | cuộn ngoài | máy tự đo | có | nơi nạp nhựa |

## B. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi; đã bảo trì và hiệu chuẩn hãng hôm trước (`calibration\bambu\MAINTENANCE.md`).
- [ ] Bàn sạch (nước rửa bát hoặc IPA theo loại bàn của bạn).
- [ ] Orca đã nhập hồ sơ pilot: máy `DHH <Máy> 0.4`, nhựa `DHH Bambu PLA @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Bambu PLA trắng, nhãn mã cuộn ví dụ `BAMBU-PLA-01` (ghi giống hệt vào `cuộn`). Sấy theo nhãn hãng; dự án chưa có số sấy từ nguồn nào: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`). H2S: ghi thêm thời gian cuộn đã nằm trong AMS.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn hồ sơ như trên. In qua kết nối cloud như mọi ngày. H2S: chọn đúng khe AMS chứa cuộn này.

**Bước 1. mvs.**
1. **Calibration → Max flowrate**. Khoảng mặc định (điểm xuất phát, chưa đo); số cũ tham khảo: PLA 15–18 mm³/s trên A1, A1M, P1S (`specs\003-orca-profiles\research.md:28-29`). Còn đẹp tới đỉnh thì nâng "End". Ô Flow Dynamics để **Auto**, bấm in.
2. Tìm **điểm xấu đầu tiên** (thiếu nhựa, hở, thô). **Điểm tốt cuối** là vạch ngay dưới. Đọc giá trị lưu lượng **in sẵn trên mẫu** tại hai điểm; mẫu không in giá trị thì chụp ảnh gửi trưởng phòng (hoặc đọc ở tab Preview, kiểu màu lưu lượng thể tích).
3. **Đặt tạm:** sửa **tạm** Max volumetric speed của nhựa = điểm tốt cuối, **không Save**, giữ tới hết bước 3. Biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S, A1, A1M:** gửi in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**. **Quan sát và ghi:** máy có chạy quy trình đo K trước khi in không (đùn thử, vẽ vạch, tiếng và màn hình báo)? Có thì đọc K của khe ở trang Device (Orca hoặc Bambu Studio) hoặc màn hình máy (chưa thử đường nào trên máy này); K ghi vào phiếu là số thấy trên máy. **Không chạy** thì ô On có thể không có tác dụng từ Orca: ghi `k` = `chưa_đo`, ghi quan sát vào `điều_kiện`, báo trưởng phòng; không dựa vào ô On cho các nhựa sau.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc PA Pattern), khoảng mặc định hộp thoại (điểm xuất phát; mở rộng nếu vạch đẹp nhất sát mép). Đọc K **in sẵn trên mẫu** (không in thì chụp ảnh gửi trưởng phòng). Nhập K lên máy thành một bộ K có tên (ví dụ `DHH-BAMBU-PLA-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập K trên P1S chưa thử trên máy này; ghi đường đã dùng vào `điều_kiện`.

**Bước 3. Flow ratio.** **Calibration → Flow Rate → Pass 1** (ô **Auto**). Chọn tấm mặt trên mịn nhất (sờ và nhìn nghiêng dưới đèn). Đọc số in trên tấm; áp vào Flow ratio **tạm** theo hướng dẫn trong hộp thoại Orca (dự án không có công thức), **không Save** hồ sơ DHH. **Pass 2** tương tự. Bỏ qua các mục YOLO. Không rõ cách áp thì ghi số in trên tấm vào `điều_kiện` và gửi ảnh cho trưởng phòng. Orca hỏi lưu thì chọn bỏ.

## D. Phép thử A/B cho K (chỉ thẻ PLA, chỉ khi bước 2 thấy máy có chạy quy trình đo K)

Mục đích: xác nhận Orca với plugin mạng Bambu gửi ô "Flow Dynamics Calibration" đúng như Bambu Studio (research.md:41-43). Điều kiện: ở bước 2 máy **có** chạy quy trình đo K khi chọn On; nếu không, bỏ mục này và báo trưởng phòng. Làm trên **H2S, A1, A1M**, **sau khi xong nửa 2**, ngoài thời gian ước lượng của Ngày 1 (mỗi máy thêm hai khung). Cùng cuộn, khe, hồ sơ, file; không đổi gì khác giữa hai mẫu.
1. Mẫu **A**: in `models\cal-a-frame-100x100x20.stl` với ô = **On**.
2. Ghi tên bộ K đang chọn cho khe. Mẫu **B**: in lại cùng file với ô = **Off**; ghi K nào đã dùng.
3. P1S không có ô: bỏ qua.

Ghi vào `calibration\bambu\AB_K_<ngày>_<máy>.md` (ví dụ `AB_K_2026-12-05_A1M.md`; **không** đặt trong `calibration\entry\cal\` vì `ingest.ps1` đọc mọi CSV ở đó):

```
| Mẫu | Ô Flow Dynamics | Máy có chạy quy trình đo K trước khi in? | Bộ K của khe | Góc khung (phồng/sắc/hở) | Ảnh |
| A | On | | | | AB_K_..._A.jpg |
| B | Off | | | | AB_K_..._B.jpg |
Kết luận: bật/tắt có đổi hành vi máy không? Hai mẫu khác nhau hay giống nhau? Chưa rõ thì ghi "chưa kết luận".
```

Chụp 4 góc cùng ánh sáng, cùng góc máy ảnh. Kết quả vào `docs\bambu-k-rule.md` (004:T016).

## E. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PLA.csv`, ví dụ `2026-12-05_H2S_BAMBU-PLA.csv` (và `P1S`, `A1`, `A1M`). Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2.

**Cách nhập (dễ hỏng nếu làm khác):** mở bằng Notepad hoặc VS Code, **không dùng Excel**; lưu **UTF-8**; số thập phân **dấu chấm** (`0.040`); **không dấu phẩy trong ô chữ** (`nguồn`, `điều_kiện`: dùng dấu chấm phẩy); **xóa dòng mẫu** của `TEMPLATE_cal.csv` (dòng có `ĐIỀN_NGUỒN`), script từ chối dòng mẫu.

`mvs`: `giá_trị` = điểm tốt cuối; `điều_kiện` ghi cả điểm tốt cuối và điểm xấu đầu. Ví dụ dòng (số **giả**):

```
H2S,BAMBU-PLA,k,XX,-,đo,máy tự đo (Flow Dynamics On); ảnh 2026-12-05_H2S_BAMBU-PLA_k.jpg,2026-12-05,BAMBU-PLA-01,AMS khe 1; máy có chạy quy trình đo K; K đọc ở màn hình máy
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo hay không đọc được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`. Đơn vị gợi ý là đề xuất.

## F. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md`.

## G. An toàn

Đầu phun và bàn nóng, không chạm khi vừa in. Không để tay vào trục khi máy chạy hiệu chuẩn.

## H. Chưa thử trên máy này

Tên menu Orca; việc mẫu Orca có in sẵn giá trị hay không; chỗ đọc K trên máy; đường nhập K tay trên P1S; việc ô Flow Dynamics từ Orca có tác dụng; H2S dùng K tự đo (suy ra từ H2D); chưa có số sấy từ nguồn.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,39`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
