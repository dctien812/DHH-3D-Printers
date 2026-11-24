# Thẻ nửa 2: in và đo mẫu chuẩn (dùng cho mọi máy và mọi nhựa)

Khi nào: sau nửa 1 của buổi, sau khi trưởng phòng đã đưa số hiệu chuẩn vào hồ sơ (003:T028) và bạn đã **nhập gói hồ sơ mới vào Orca** (khoảng 5 phút). Dùng cho 6 máy (ABS: TRI, V24, H2S, P1S). Nguồn: `specs\003-orca-profiles\tasks.md:68,71`, `models\README.md`.
Trạng thái: soạn theo tài liệu, **chưa thử trên máy này**. Hướng đặt mẫu và vị trí đo lấy từ `models\README.md`; đọc file đó nếu nghi ngờ.

## A. Chuẩn bị

- [ ] Gói hồ sơ mới đã nhập; tên hồ sơ nhựa đúng buổi (ví dụ `DHH Bambu PETG Basic @<Máy>`); trưởng phòng báo xong 003:T028.
- [ ] Hai file mẫu: `models\cal-a-frame-100x100x20.stl` (a) và `models\cal-b-hole-pin.stl` (b). Không xoay, không đổi kích thước.
- [ ] Thước cặp về 0 khi khép; mở sẵn `calibration\entry\part\TEMPLATE_part.csv` (do vai khác tạo).

## B. In

1. Chọn máy `DHH <Máy> 0.4`, nhựa của buổi, quy trình `DHH 0.20 Sync @<Máy>`. Bambu: in từ Orca như mọi ngày, bạn bấm in.
2. **(a) Khung rỗng**: đặt sao cho đầu có **hai góc vát (5 × 5 mm) nằm ở phía +X** của bàn in, tức bên phải khi nhìn từ phía trước máy. Hai góc vát là dấu nhận trục X; sai hướng sẽ lẫn trục X và Y khi bù.
3. **(b) Tấm lỗ và chốt**: in đúng hướng trong file (chốt in đứng).

## C. Đo (thước cặp, mỗi số 3 lần)

- **X**: khoảng cách hai mặt phẳng ngoài của hai thành dọc trục X, đo ở giữa chiều cao (khoảng Z = 10 mm), ở giữa cạnh, **tránh góc vát**. Ba lần ở ba vị trí khác nhau.
- **Y**: tương tự trên hai thành còn lại. Ba lần ở ba vị trí.
- **Z**: chiều cao thành. 1 hoặc 3 số.
- **Lỗ Ø8** (lỗ tròn): đo đường kính bằng **hai hàm trong** của thước, 3 lần ở các hướng khác nhau. 1 hoặc 3 số.
- Chụp ảnh mẫu đã đo, có thước, tên ảnh bắt đầu bằng tên phiếu (đề xuất).

## D. Điền phiếu

Sao chép `TEMPLATE_part.csv` thành `calibration\entry\part\<ngày>_<máy>_<nhựa>.csv`, ví dụ `2026-12-05_P1S_BAMBU-PLA.csv`. Cột: máy, nhựa, cuộn, ngày, vòng, X1 X2 X3, Y1 Y2 Y3, Z1 Z2 Z3, lỗ1 lỗ2 lỗ3, lắp_chéo, lắp_chéo_với, ghi_chú.

- `máy`, `nhựa`: mã (TRI, V24, H2S, P1S, A1, A1M; BAMBU-PLA, BAMBU-PETG, TIN-PETGECO, TIN-ABSPRO). `cuộn`: cùng mã cuộn đã ghi ở phiếu `cal`.
- `vòng`: **1 = lần in đầu, chưa bù**. Mỗi lần in lại sau khi trưởng phòng bù tăng 1 (2, 3, ...). Trong cùng ngày thêm **một dòng mới** vào cùng file; khác ngày dùng file mới (đề xuất, chưa kiểm với `aggregate.ps1`).
- `Z`, `lỗ`: 1 hoặc 3 số; ô không dùng để trống.
- `lắp_chéo`: chỉ điền ở lượt thử lắp chéo (Ngày 3, 003:T019). Ghi `được` hoặc `không` **ở dòng của máy in lỗ**; `lắp_chéo_với` = mã máy in chốt. Các lượt khác để trống.
- `ghi_chú`: điều bất thường (cong mép, sợi, in lại vì hỏng).

**Cách nhập:** mở bằng Notepad hoặc VS Code (không Excel); lưu **UTF-8**; số thập phân **dấu chấm** (`100.05`); **không dấu phẩy trong ô chữ**; **xóa dòng ví dụ** của `TEMPLATE_part.csv` (dòng có `VÍ DỤ`). Không đo được thì để trống, không điền số ước.

## E. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `aggregate.ps1` và lập danh sách cặp lệch (003:T016). Dung sai: X/Y ±0,1 mm trên 100 mm; Z ±0,1 mm trên 20 mm; lỗ ±0,15 mm (`docs\data-formats.md:72-76`).

## F. Chưa thử trên máy này

Cả quy trình đo; cách `aggregate.ps1` xử lý nhiều dòng `vòng` trong một file; mẫu (b) chưa in thử, khe hở chốt 0,2 mm chưa thử trên máy thật (`models\README.md`).
