# verify_003_addfilament (003:T022)

Test-engineer, 2026-11-25. Bản sao làm việc: `tests\tmp\addfilament\` (chép `scripts\orca`, `scripts\calibration`, `profiles\`, `calibration\entry\*\TEMPLATE*`, `docs`). Nhựa giả: TEST-BRAND ASA, mã TEST-ASA, trên TRI, V24, H2S, P1S. Bảng thật `profiles\src\materials.csv` vẫn 20 dòng, `profiles\bundle\` không tồn tại, băm `%APPDATA%\OrcaSlicer\user` trước/sau: 66 file, 0 lệch.

## Từng bước của hướng dẫn
| Bước | Kết quả | Chi tiết |
|---|---|---|
| 1 Mã và tên | làm được, có đoán nhỏ | Không nói giữ nguyên chữ hoa/gạch của hãng. Tôi đặt `DHH TEST-BRAND ASA @<Máy>`. |
| 2 Máy hợp lệ | làm được | ASA nằm cùng hàng ABS: TRI, V24, H2S, P1S. |
| 3 Thêm dòng | làm được | 23 cột khớp, ví dụ chạy được. Dòng Bambu theo mô tả ở dòng 41, 60 chạy ngay. Lưu ý dòng mẫu chỉ có bản Voron. |
| 4 Hồ sơ cha | PHẢI ĐOÁN | Bảng cha chỉ có PETG và ABS, không có ASA. Lệnh liệt kê trả 140 tên `*ASA*`. Tôi chọn `Generic ASA @System` (Voron), `Generic ASA @BBL H2S 0.4 nozzle`, `Generic ASA` (P1S) theo kiểu ABS. Chưa biết có hợp máy không. |
| 5 Dựng và kiểm | làm được | Chạy từ gốc, không có tham số thừa. |
| 6 Cài | làm được trên bản sao | Lệnh trong hướng dẫn không có `-UserDir`, tôi thêm. Cảnh báo `-Force` đúng (xem dưới). |
| 7 Hiệu chuẩn | làm được | Tất cả file thẻ được nhắc đều có; chưa đọc kỹ nội dung thẻ. |
| 8 Phiếu, gộp | làm được | Phiếu `cal` và `part` theo mẫu chạy được; thông báo lỗi khớp dòng 194. |
| 9, 10 | làm được | Không sai. |

## (1) Dựng
Nguồn 24 dòng: `-Set all` ra 36 file (6/6/24), `-Verify` lệch = 0. check_profiles.ps1: 4 hồ sơ mới có `compatible_printers` đúng máy DHH, `inherits` có trong `*.opc` (4/4), không PA cho Bambu; chỉ báo "name pattern" vì regex của tôi không biết hãng TEST-BRAND (không phải lỗi script). Zip: 3 file trong `import\`.

## (2) Phiếu
- `cal` TRI TEST-ASA (3 dòng): `ingest.ps1` ghi `voron.csv` 3 dòng, `bambu.csv` 0 dòng. Dựng lại: hồ sơ TRI có `pressure_advance` 0.025 và `filament_flow_ratio` 0.95 (số `đo` thắng bảng), `-Verify` lệch 0.
- `cal` A1 TEST-ASA: `a.csv:2: cap khong hop le: TEST-ASA tren A1`, `TU CHOI: 1 loi. Khong ghi file nao.`, exit 1, không tạo `voron.csv`. Khớp dòng 194.
- `part` TRI: `aggregate.ps1` đọc 1 file, 1 cặp, exit 0. `part` A1: cảnh báo `pair TEST-ASA on A1 is not in ...materials.csv - file skipped`, exit 1. Khớp dòng 194.

## (3) Hồi quy với bảng thật
Bảng thật 20 dòng không có PLA trên Voron, bảng `materials_full.csv` 22 dòng (hai bản trong `tests\ingest` và `tests\aggregate` giống hệt nhau).
- `ingest` với bảng đầy đủ: 14 thư mục ca thử. ok, dup, lower, precedence, upper, pla_tri đạt (exit 0); future, missing_src, nan, fill, template, bad_pair bị từ chối đúng lý do; acme_* bị từ chối vì ACME-PETG không có trong cả hai bảng (muốn chạy phải thêm dòng ACME).
- Với bảng thật: mọi ca có BAMBU-PLA trên Voron bị từ chối `cap khong hop le`, đúng quy tắc mới.
- `aggregate` bộ `entry\part` với bảng đầy đủ: exit 0, file ra GIỐNG HỆT `tests\aggregate\results_out.csv` (cùng băm). Với bảng thật: exit 1 (các file PLA trên Voron bị bỏ).
- Không đọc được bảng (`-MaterialsFile D:\nope\none.csv`): `aggregate.ps1` ném `Cannot read materials table`, gọi qua `-Command` và `-File` đều thoát 1, không ghi file ra. `ingest.ps1` cũng thoát 1. Bảng thiếu cột `máy`/`nhựa`: aggregate thoát 1.

## (4) Cài trên bản sao thư mục user (`-UserDir`)
- `-Install` không `-Force` khi DHH đã có: từ chối (36 file), file sửa tay còn nguyên. Đúng cảnh báo.
- Sửa tay `DHH Bambu PLA @A1.json` rồi `-Install -Force`: bị GHI ĐÈ, mất chỗ sửa. Đúng cảnh báo.
- Cách C (chép riêng 4 file TEST-ASA vào `filament\` của bản sao đã có 32 hồ sơ): `-Verify -UserDir` lệch 0 (36 hồ sơ). Sửa tay một file thì `-Verify` báo lệch = 1.
- File cũ (không phải DHH) khớp bản sao lưu 100%.

## Lỗi
- Quan trọng: không có.
- Nhỏ (tài liệu): bảng cha ở bước 4 thiếu ASA (dòng 76-82); lệnh bước 6 (dòng 107-109) chạy lên thư mục user thật, không nhắc `-UserDir` để thử trên bản sao.
- Nhỏ (mã): `scripts\calibration\ingest.ps1` dòng 40 dính hai lệnh trên một dòng (`}` rồi `$Params = ...`), vẫn chạy được.

## Chưa kiểm được
Orca thật: có nhận hồ sơ chép tay và gói zip không, hồ sơ cha ASA có cắt lớp được không.

## Kết luận SC-006
ĐẠT MỨC MỘT PHẦN: một người chưa biết dự án thêm được nhựa mới, dựng, kiểm, gộp phiếu bằng đúng lệnh trong hướng dẫn, nhưng ở bước 4 phải đoán hồ sơ cha khi loại nhựa không phải PETG/ABS, và bước nhập vào Orca thật chưa kiểm.
