# Thẻ hiệu chuẩn Bambu: Bambu PLA trắng (BAMBU-PLA)

Máy: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày), **P1S**, **A1**, **A1M** (A1 Mini).
Buổi: **C, nửa 1** (pilot, 004:T011), kèm **phép thử A/B cho K** (mục E). Pilot chưa đạt thì D1, D2, E không chạy.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`) và kế hoạch, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`. Văn phòng **không gửi lệnh nào tới máy Bambu**: mọi lần in do bạn bấm trong Orca hoặc trên máy.

## A. Quy tắc K (đọc trước)

- K (hệ số dòng chảy, tương đương PA) được **lưu trên máy**, theo bộ tham số có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` cho máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca của máy Bambu, để K chỉ bù ở một nơi là máy (research.md:39-41).
- H2S, A1, A1M: máy tự đo K. H2S nhiều khả năng giống H2D nhưng đó là suy ra, trang của hãng chỉ nêu H2D (research.md:30-32). **P1S chỉ hiệu chuẩn K bằng tay**, không có ô "Flow Dynamics Calibration" (research.md:30-31).
- Ô "Flow Dynamics Calibration" khi gửi in có ba mức: Auto (dùng lại kết quả gần đây nếu nhựa và đầu phun không đổi), On (đo trước mỗi lần in), Off (dùng K bạn đặt cho khe; không có thì dùng mặc định) (research.md:33-35).
- A1 và A1M (firmware 01.09.00.00) không cho hiệu chuẩn khi đang in (research.md:13): chỉ bắt đầu khi máy rảnh.

## B. Mỗi máy khác nhau thế nào

| Máy | Nhựa vào máy | Cách có K | Ô Flow Dynamics | Ghi thêm vào `điều_kiện` |
|---|---|---|---|---|
| H2S | khe AMS (ghi số khe); gán đúng loại nhựa cho khe | máy tự đo | có | khe AMS, loại đầu phun |
| P1S | cuộn ngoài | **đo tay**, nhập K lên máy | không có | tên bộ K đã đặt |
| A1 | cuộn ngoài (ghi nếu dùng AMS lite) | máy tự đo | có | nơi nạp nhựa |
| A1M | cuộn ngoài | máy tự đo | có | nơi nạp nhựa |

## C. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi; đã làm bảo trì và hiệu chuẩn của hãng (Buổi B2, `calibration\bambu\MAINTENANCE.md`).
- [ ] Bàn sạch (nước rửa bát hoặc IPA theo loại bàn của bạn).
- [ ] Orca đã nhập gói pilot: máy `DHH <Máy> 0.4`, nhựa `DHH Bambu PLA @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Bambu PLA trắng, nhãn mã cuộn ví dụ `BAMBU-PLA-01` (ghi giống hệt vào cột `cuộn`). Sấy theo nhãn hãng. Dự án chưa có số sấy từ nguồn nào: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`). Với H2S ghi thêm thời gian cuộn đã nằm trong AMS.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## D. Các bước

**Bước 0.** Chọn hồ sơ như trên. In qua kết nối cloud như mọi ngày. H2S: chọn đúng khe AMS chứa cuộn này.

**Bước 1. mvs.**
1. **Calibration → Max flowrate** trong Orca. Giữ khoảng mặc định (điểm xuất phát, chưa đo); số cũ để tham khảo: PLA 15–18 mm³/s trên A1, A1M, P1S (`specs\003-orca-profiles\research.md:28-29`). Còn đẹp tới đỉnh thì nâng "End".
2. Ô Flow Dynamics để **Auto**, bấm in.
3. Tìm độ cao bắt đầu xấu; đọc lưu lượng tại lớp đó bằng tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S, A1, A1M:** gửi in tấm **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; máy đo K trước khi in. Đọc K của khe đó ở trang Device (Orca hoặc Bambu Studio) hoặc màn hình máy; chưa thử đường nào trên máy này. Không đọc được thì chụp màn hình và ghi `k` là `chưa_đo`. K ghi vào phiếu là số thấy trên máy sau khi đo.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc PA Pattern), khoảng mặc định của hộp thoại (điểm xuất phát; đẹp nhất sát mép thì mở rộng). In, chọn vạch đẹp nhất, đổi sang K theo hộp thoại. Nhập K lên máy thành một bộ K có tên (ví dụ `DHH-BAMBU-PLA-<ngày>`, đề xuất) và gán cho cuộn ngoài. Đường nhập K trên P1S (trang Device hay màn hình) chưa thử trên máy này; làm theo trang hãng `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa` và ghi lại đường đã dùng vào `điều_kiện`.

**Bước 3. Flow ratio.** Nếu chưa in ở bước 2: **Calibration → Flow Rate → Pass 1**, ô Flow Dynamics để **Auto** (hoặc giữ giá trị đã đo K). Chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100 (theo wiki Orca, chưa thử trên máy này). Sửa **tạm** Flow ratio, **không Save** hồ sơ DHH. **Pass 2** tương tự. Bỏ qua các mục YOLO. Orca hỏi lưu thì chọn bỏ.

## E. Phép thử A/B cho K (chỉ thẻ PLA)

Mục đích: xác nhận OrcaSlicer với plugin mạng Bambu gửi lựa chọn "Flow Dynamics Calibration" đúng như Bambu Studio (trang hãng không nói về Orca, research.md:41-43). Trước khi in mẫu A/B, K của khe đã có từ bước 2.

Làm trên **H2S, A1, A1M** (có ô). Cùng cuộn, cùng khe, cùng hồ sơ, cùng file; không đổi gì khác giữa hai mẫu.
1. Mẫu **A**: in STL mẫu (a) (khung rỗng 100 × 100 × 20, trong `models\`, do 003:T007 sinh) với ô = **On**.
2. Ghi tên bộ K đang chọn cho khe. Mẫu **B**: in lại cùng file với ô = **Off** (máy dùng K bạn đặt cho khe, không có thì mặc định). Ghi K nào đã dùng.
3. P1S không có ô: **thử thêm (đề xuất, bỏ qua nếu hết giờ)** in hai mẫu, một với bộ K tay vừa đặt, một với bộ K mặc định của máy.

Cho mỗi mẫu, ghi vào file `calibration\bambu\AB_K_<ngày>_<máy>.md` (ví dụ `AB_K_2026-12-05_A1M.md`; **không** đặt trong `calibration\entry\cal\` vì `ingest.ps1` đọc mọi CSV ở đó):

```
| Mẫu | Ô Flow Dynamics | Máy có chạy quy trình đo K trước khi in? (có/không) | Bộ K của khe | Góc khung (phồng/sắc/hở) | Ảnh |
| A | On | | | | AB_K_..._A.jpg |
| B | Off | | | | AB_K_..._B.jpg |
Kết luận: bật/tắt có đổi hành vi máy không? Hai mẫu khác nhau hay giống nhau? Chưa kết luận được thì ghi "chưa kết luận".
```

Chụp 4 góc cùng ánh sáng, cùng góc máy ảnh. Nếu hai mẫu giống hệt và máy không chạy quy trình đo ở mẫu A, ghi nguyên văn: đó là bằng chứng ô On không có tác dụng từ Orca. Kết quả này vào `docs\bambu-k-rule.md` (004:T016); nếu A/B không phân biệt được thì ghi "chưa kết luận".

## F. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PLA.csv`, ví dụ `2026-12-05_H2S_BAMBU-PLA.csv`, `..._P1S_...`, `..._A1_...`, `..._A1M_...`. Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
H2S,BAMBU-PLA,k,XX,-,đo,máy tự đo (Flow Dynamics On); ảnh 2026-12-05_H2S_BAMBU-PLA_k.jpg,2026-12-05,BAMBU-PLA-01,AMS khe 1; K đọc ở màn hình máy
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo hay không đọc được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`. Đơn vị gợi ý là đề xuất; `TEMPLATE_cal.csv` ghi khác thì theo mẫu.

## G. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T015). Văn phòng không điều khiển máy Bambu: chỉ được đọc trạng thái.

## H. An toàn

Đầu phun và bàn nóng, không chạm khi vừa in. Không để tay vào trục khi máy chạy hiệu chuẩn.

## I. Chưa thử trên máy này

Tên menu Orca, công thức đọc số; chỗ đọc K trên máy; đường nhập K tay trên P1S; việc ô Flow Dynamics từ Orca có tác dụng (chính là mục đích của phép thử A/B); H2S dùng K tự đo (suy ra từ H2D); chưa có số sấy từ nguồn.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,39`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
