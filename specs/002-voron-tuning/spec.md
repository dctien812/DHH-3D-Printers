# Feature Specification: Hoàn tất tinh chỉnh hai Voron

**Feature Branch**: `002-voron-tuning` (dự án không dùng git, tên chỉ để định danh)

**Created**: 2026-11-24

**Status**: Draft

**Input**: User description: "tối ưu các máy in 3D trong mạng LAN" — phần 2/4: Voron Trident 250
và Voron 2.4 300 (Klippain, gantry Monolith 2WD).

## Clarifications

### Session 2026-11-24

- Q: Việc cân lại đai sau phép đo 11-10 đến đâu? → A: Chưa làm, đưa vào kế hoạch.
- Q: Ai khởi động việc chạy máy? → A: Phép đo không đùn nhựa văn phòng tự chạy khi máy rảnh; in
  mẫu chờ người dùng.
- Q: Chính sách cập nhật? → A: Host cập nhật qua Moonraker, Trident thử trước; firmware MCU hỏi riêng.
- Q: Voron test nhựa nào? → A: Không test PLA (PLA in ở máy Bambu); test Bambu PETG Basic, Tinmorry PETG-ECO, Tinmorry ABS Pro.
- Q: PA của Voron lấy từ đâu? → A: Từ hồ sơ Orca trên cả hai máy; bảng vật liệu của Klippain tắt.
- Q: Firmware bo mạch V2.4 (đang là Kalico)? → A: Không chuyển sang Kalico; nạp lại về Klipper chính khi triển khai, trước mọi phép đo trên V2.4.
- Q: SAVE_CONFIG đang treo trên hai máy? → A: Bỏ.

## Đã xong (không làm lại)

Bằng chứng nằm trong bộ nhớ `voron-printers-klippain` và các thư mục `orig`, `recheck`, `skew`,
`shaper`, `pid_*.json`:

- PID đầu nóng và bàn in của cả hai máy (2026-11-09).
- Skew: V2.4 giữ nguyên, Trident đã cộng phần dư (2026-11-10).
- Input shaper theo kiểu "performance" với đai chưa cân; `max_accel` 10000; thử bước ở 400 mm/s.
- Cập nhật Klipper, Moonraker, Klippain, plugin Cartographer, hệ điều hành (2026-11-09).
- Sửa START_PRINT (skew_load trên Trident, bỏ purge trên V2.4) và `update_manager`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cân đai rồi đo lại cộng hưởng (Priority: P1)

Người dùng cân lại hai đai của từng máy; văn phòng đo so sánh đai trước và sau, rồi đo lại và đặt
lại input shaper, kiểm lại giới hạn gia tốc và thử mất bước.

**Why this priority**: Đai lệch (V2.4 giống 74 %, Trident 80,7 %) làm giá trị shaper hiện tại chỉ
là tạm; nó ảnh hưởng cả độ tin cậy lẫn kích thước.

**Independent Test**: Chạy lại phép so sánh đai và phép đo shaper; số sau tốt hơn số trước bằng
cùng một phép đo.

**Acceptance Scenarios**:

1. **Given** người dùng báo đã cân đai một máy, **When** văn phòng đo so sánh đai, **Then** độ
   giống nhau của hai đai tăng so với số ngày 11-10 và được ghi cạnh số cũ.
2. **Given** đai đã đạt, **When** đo lại shaper, **Then** giá trị mới nằm trong `overrides.cfg`,
   có sao lưu, và phép thử mất bước ở gia tốc đang đặt vẫn qua.
3. **Given** số đo sau khi cân không khá hơn, **When** báo kết quả, **Then** văn phòng giữ giá trị
   cũ và nêu nguyên nhân có thể (puly, ổ bi) để người dùng kiểm.

---

### User Story 2 - Hiệu chuẩn đùn nhựa theo vật liệu trên hai Voron (Priority: P2)

Mỗi máy có pressure advance, hệ số lưu lượng và lưu lượng thể tích tối đa đã đo cho từng nhựa trong
phạm vi của Voron (hai loại PETG và ABS; không có PLA), ghi vào nơi mà bộ hồ sơ chung của đặc tả 003 sẽ dùng.

**Why this priority**: Hiện chỉ có một con số PA cho mỗi máy (0,0256 và 0,02) và chỉ ABS có hồ sơ
riêng; đây là phần quyết định bề mặt và kích thước.

**Independent Test**: In mẫu chuẩn của một nhựa trên một máy với số đã đo; mẫu đạt tiêu chí kích
thước của đặc tả 003.

**Acceptance Scenarios**:

1. **Given** người dùng xác nhận đã nạp nhựa và ở cạnh máy, **When** in mẫu hiệu chuẩn, **Then**
   các số PA, lưu lượng, lưu lượng tối đa của cặp máy và nhựa đó được ghi kèm ảnh hoặc số đo.
2. **Given** một nhựa chưa có cuộn để thử, **When** lập hồ sơ, **Then** cặp đó đánh dấu "chưa
   đo", không điền số ước lượng như số đã kiểm.

---

### User Story 3 - Gỡ các điểm lệch chuẩn còn lại (Priority: P3)

Xử lý những điểm làm hai máy khác nhau mà không có lý do: firmware MCU của V2.4 đang chạy bản
Kalico dưới host Klipper chính, cảm biến Cartographer chưa hiệu chuẩn lại sau bản 1.10.1, mã
G-code khởi đầu trong slicer nạp skew hai lần.

**Why this priority**: Không gây lỗi ngay nhưng là nguồn rủi ro khi cập nhật và làm hai máy khó
đồng bộ.

**Independent Test**: Sau khi xử lý, hai máy báo cùng dòng firmware, và nhật ký một lần in cho
thấy skew chỉ được nạp một lần.

**Acceptance Scenarios**:

1. **Given** người dùng đồng ý riêng việc nạp firmware MCU, **When** nạp lại V2.4, **Then** bo
   chính và đầu in báo phiên bản cùng dòng với host, CAN không lỗi truyền lại, máy về trạng thái
   sẵn sàng.
2. **Given** người dùng không đồng ý nạp firmware, **When** kết thúc đặc tả, **Then** mục này ghi
   "hoãn" kèm rủi ro, các mục khác vẫn hoàn tất.

### Edge Cases

- Người dùng sửa cấu hình trong Mainsail giữa chừng: tải lại và so trước mỗi lần ghi.
- Phép đo cộng hưởng bị cắt bởi `max_freq`: đã đặt 200 Hz, kiểm lại sau cập nhật Klippain.
- Cập nhật host làm hỏng macro Klippain: Trident thử trước, có sao lưu để quay lại.
- Máy đang in khi tới lượt đo: bỏ qua, ghi sổ, thử lại sau.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Mọi phép đo trước và sau PHẢI dùng cùng một lệnh và cùng điều kiện (nguội hay nóng).
- **FR-002**: Mỗi lần ghi cấu hình lên máy PHẢI theo nguyên tắc II của hiến chương (máy không in,
  so bản trên máy, sao lưu, ghi sổ kèm cách hoàn tác).
- **FR-003**: Giá trị chỉnh PHẢI nằm trong `overrides.cfg`; không dùng SAVE_CONFIG cho thông số
  đã đặt ở đó.
- **FR-004**: Phép đo không đùn nhựa chỉ được tự chạy khi máy báo sẵn sàng và không có lệnh in.
- **FR-005**: In mẫu và mọi việc đùn nhựa PHẢI chờ người dùng xác nhận.
- **FR-006**: Nạp firmware MCU và việc cần tháo lắp PHẢI được người dùng đồng ý riêng.
- **FR-007**: Số hiệu chuẩn theo vật liệu PHẢI được ghi theo cặp (máy, nhựa) kèm ngày và điều
  kiện đo, ở dạng mà đặc tả 003 đọc được.
- **FR-008**: Thay đổi áp dụng cho cả hai máy PHẢI làm trên Trident trước, kiểm xong mới tới V2.4.

### Key Entities

- **Phép đo**: máy, loại (so đai, shaper, thử bước, PA, lưu lượng), điều kiện, kết quả, ngày.
- **Thay đổi cấu hình**: máy, file, giá trị cũ và mới, bản sao lưu, lý do.
- **Số hiệu chuẩn vật liệu**: máy, nhựa, PA, hệ số lưu lượng, lưu lượng tối đa, trạng thái đã đo
  hay chưa.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Độ giống nhau của hai đai trên mỗi máy cao hơn số ngày 11-10 (74 % và 80,7 %), đo
  bằng cùng phép so sánh. Từ 90 % trở lên là mục tiêu phấn đấu do văn phòng đặt (công cụ đo không
  có ngưỡng chính thức), không phải điều kiện đạt.
- **SC-002**: Sau khi đặt shaper mới, phép thử mất bước ở tốc độ và gia tốc đang đặt qua 2/2 máy.
- **SC-003**: Mỗi cặp (máy Voron, nhựa trong phạm vi) có số đo hoặc nhãn "chưa đo"; 0 số ước
  lượng bị ghi là đã đo.
- **SC-004**: Mỗi thay đổi lên máy có bản sao lưu khôi phục được; thử khôi phục 1 file trên mỗi máy.
- **SC-005**: Hai máy không còn điểm lệch chuẩn nào chưa được xử lý hoặc chưa được ghi "hoãn" kèm
  lý do.

## Assumptions

- Phần cứng không đổi so với 11-10 ngoài việc cân đai.
- Người dùng tự cân đai và kiểm puly; văn phòng chỉ đo và hướng dẫn.
- Kiểu shaper "performance" người dùng đã chọn vẫn giữ, trừ khi nó làm hỏng tiêu chí đồng bộ kích
  thước của đặc tả 003; khi đó trình người dùng quyết.
- Nhựa dùng để đo trên Voron: Bambu PETG Basic, Tinmorry PETG-ECO, Tinmorry ABS Pro (không có PLA),
  màu trắng.
