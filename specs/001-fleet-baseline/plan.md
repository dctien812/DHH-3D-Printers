# Implementation Plan: Kiểm kê và đường cơ sở dàn 6 máy in

**Branch**: `001-fleet-baseline` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: `specs\001-fleet-baseline\spec.md`. File này cũng chứa **thiết kế chung** cho cả 4 đặc
tả; plan của 002, 003, 004 trỏ về đây.

## Summary

Dựng bảng kiểm kê 6 máy và bản chụp trạng thái từng máy bằng các script PowerShell chỉ đọc, sao
lưu nguyên vẹn hồ sơ OrcaSlicer, rồi lập danh sách khoảng trống làm đầu vào cho 002, 003, 004.

## Thiết kế chung cho 4 đặc tả

**Bố cục thư mục** (thêm cạnh thư mục cũ; không đụng `orig`, `recheck`, `v24`, `trident`,
`shaper`, `skew`, `scripts\shake_run.ps1`, `scripts\test_speed.ps1`):

```text
docs\data-formats.md            định dạng ba bảng dùng chung
fleet\inventory.csv|.md         bảng kiểm kê
fleet\baseline\<ngày>\<máy>\    bản chụp cấu hình / trạng thái
fleet\backups\<ngày>_<lý do>\   bản sao lưu trước mỗi lần ghi lên Voron
fleet\gaps.md                   danh sách khoảng trống
fleet\firmware\<máy>.md         khuyến nghị firmware Bambu (004)
fleet\verify_*.md               bằng chứng kiểm chứng của test-engineer
secrets\bambu.local.json        mã truy cập, serial; người dùng điền; không sao chép đi đâu
profiles\orca_backup\<ngày>\    sao lưu hồ sơ Orca cũ + manifest.sha256
profiles\src\  profiles\bundle\ nguồn và bộ hồ sơ mới (003)
calibration\voron.csv           số hiệu chuẩn Voron (002 ghi)
calibration\bambu.csv           số hiệu chuẩn Bambu (004 ghi)
calibration\entry\cal\          số hiệu chuẩn, mỗi lần đo một file CSV do người dùng điền
calibration\entry\part\         số đo mẫu chuẩn, mỗi lần đo một file CSV
calibration\results.csv         kết quả mẫu chuẩn gộp lại (003)
calibration\guides\             thẻ hướng dẫn từng buổi
models\                         STL mẫu chuẩn
scripts\{lib,fleet,voron,bambu,orca,calibration,models}\
tests\                          script kiểm giả lập
```

**Ba bảng CSV UTF-8** (chi tiết ở `docs\data-formats.md`):
- Kiểm kê: id, tên, mẫu, ip, mac, phần mềm/firmware, đầu phun, bàn, phụ kiện, kết nối, buồng kín,
  nguồn, ngày. Mã máy: TRI, V24, H2S, P1S, A1, A1M. Không có serial.
- Số hiệu chuẩn (dạng dọc): máy, nhựa, tham số (pa | k | flow_ratio | mvs | shrink_xy |
  temp_nozzle), giá trị, đơn vị, trạng thái (đo | kế_thừa | mặc_định | chưa_đo), nguồn, ngày, cuộn,
  điều kiện. Script nạp từ chối dòng "đo" thiếu nguồn, ngày hoặc cuộn. Mã nhựa: BAMBU-PLA,
  BAMBU-PETG, TIN-PETGECO, TIN-ABSPRO.
- Kết quả mẫu chuẩn: máy, nhựa, cuộn, X, Y (trung bình 3 lần đo), Z, lỗ, đạt hay không, ngày.

**Mẫu chuẩn** (script sinh STL, vừa bàn 180 mm của A1 Mini): (a) khung rỗng 100 × 100 × 20 mm, đo
X/Y ở giữa chiều cao; (b) tấm lỗ và chốt Ø8; (c) tháp bề mặt và nhô.

**Thứ tự giữa 4 đặc tả**: 001 trước. Phần nền của 003 chạy song song với 001 và với phần đo không
đùn nhựa của 002. 002:US1 và 004:US1 song song. Pilot PLA trên 6 máy (Buổi C) chạy trước khi dựng
đủ 20 hồ sơ; hiệu chuẩn nhựa của 002, 004 và in mẫu của 003 dùng chung các buổi.

**Lượt có mặt của người dùng**: xem [../003-orca-profiles/plan.md](../003-orca-profiles/plan.md).

**Phương án đã loại**: sửa tay JSON hồ sơ Orca (khó kiểm, dễ lệch giữa các máy); một file CSV
hiệu chuẩn chung cho cả hai hãng (hai đặc tả ghi đè nhau); hiệu chuẩn nhiệt cho cả 20 cặp (dùng
mặc định của nhà sản xuất, ghi "mặc_định").

## Technical Context

**Language/Version**: PowerShell 5.1 (Windows 11), không thêm ngôn ngữ khác nếu không cần.

**Primary Dependencies**: Moonraker HTTP (chỉ GET) cho hai Voron; SSDP udp 2021 và MQTT/TLS cổng
8883 cho Bambu. Thư viện MQTT trên PC: NEEDS CLARIFICATION, giải ở T009 (chọn thư viện có sẵn
hoặc viết gói MQTT tối thiểu trên `SslStream`); không tìm được cách thì lùi về ảnh màn hình (T012).

**Storage**: file CSV, JSON, Markdown trong thư mục dự án.

**Testing**: không có bộ test tự động; `test-engineer` chạy thật và đối chiếu với máy.

**Target Platform**: PC Windows trong cùng LAN với 6 máy.

**Constraints**: chỉ đọc đối với máy in; bí mật chỉ nằm trong `secrets\`.

**Scale/Scope**: 6 máy, 5 script, 18 task.

## Constitution Check

| Nguyên tắc | Đánh giá |
|---|---|
| I. Thứ tự ưu tiên | `gaps.md` xếp theo Tin cậy > Đồng bộ > Chất lượng > Tốc độ. Đạt. |
| II. Thay đổi lên máy | Không ghi gì lên máy. Đạt. |
| III. Bambu giữ cloud | Chỉ nghe; gói duy nhất được gửi là pushall (v1.0.1), có công tắc tắt mặc định và 09 rà. Đạt. |
| IV. OrcaSlicer | Chỉ sao lưu hồ sơ, không sửa. Đạt. |
| V. Cập nhật | Không cập nhật gì. Đạt. |
| VI. Chạy máy | Không làm máy chuyển động hay nóng lên. Đạt. |

## Tiêu chí nghiệm thu

SC-001 đến SC-005 của spec; bảng SC → task ở cuối [tasks.md](tasks.md).

## Rủi ro

- Đọc MQTT nội bộ ở chế độ cloud có thể bị từ chối trên một số mẫu (chưa có nguồn xác nhận): lùi
  về dữ liệu quảng bá và ảnh màn hình, không đổi chế độ máy.
- Gói SSDP chứa serial: script không được in hay ghi ra ngoài `secrets\`.
- Địa chỉ máy đổi do DHCP: bảng ghi cả MAC và tên máy.

## Việc khó hoàn tác

Không có. Mọi thao tác là đọc và ghi file mới trong thư mục dự án.

## Phần không đụng tới

Cấu hình và trạng thái của cả 6 máy; hồ sơ trong `%APPDATA%\OrcaSlicer`; các thư mục và script
của đợt 11-09 / 11-10.

## Project Structure

Theo "Thiết kế chung" ở trên. Đặc tả này tạo `docs\`, `fleet\`, `secrets\`, `scripts\lib\`,
`scripts\fleet\`, `profiles\orca_backup\`.
