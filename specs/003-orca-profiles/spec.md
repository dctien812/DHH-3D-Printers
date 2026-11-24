# Feature Specification: Bộ hồ sơ OrcaSlicer chung cho 6 máy

**Feature Branch**: `003-orca-profiles` (dự án không dùng git, tên chỉ để định danh)

**Created**: 2026-11-24

**Status**: Draft

**Input**: User description: "tối ưu các máy in 3D trong mạng LAN" — phần 3/4: một bộ hồ sơ máy,
vật liệu, quy trình trong OrcaSlicer để cùng một file in trên máy nào cũng ra kết quả gần như nhau.

## Clarifications

### Session 2026-11-24

- Q: Slicer chuẩn? → A: OrcaSlicer cho cả 6 máy (đang có 2.5.2); máy Bambu vẫn dùng cloud qua
  plugin mạng Bambu trong Orca.
- Q: Thứ tự ưu tiên khi xung đột? → A: Tin cậy > Đồng bộ > Chất lượng > Tốc độ.
- Q: Vật liệu? → A: PLA / PLA+, PETG, ABS / ASA; Bambu PLA, Bambu PETG, Tinmorry PETG-ECO,
  Tinmorry ABS Pro; màu trắng là chính; hãng khác thêm sau.
- Q: Tiêu chí đồng bộ? → A: Lệch không quá 0,1 mm trên 100 mm so với danh nghĩa, trên mọi máy.
- Q: Hồ sơ cũ? → A: Sao lưu, làm bộ mới theo một quy ước tên, kế thừa số đã đo; hồ sơ cũ để nguyên.
- Q: Dung sai chiều Z và lỗ? → A: Z ±0,1 mm trên 20 mm; lỗ Ø8 ±0,15 mm; cộng thử lắp chéo.
- Q: ABS / ASA chưa đạt 0,1 mm sau 2 vòng bù? → A: Giữ 0,1 mm, in bù tiếp; không nới dung sai.
- Q: Tiền tố tên hồ sơ? → A: "DHH" (ví dụ "DHH Tinmorry PETG-ECO @P1S").
- Q: Nhựa nào test trên máy nào? → A: PLA chỉ 4 máy Bambu (Voron không in PLA); PETG cả 6 máy; ABS / ASA trên hai Voron, H2S, P1S. Bambu PETG là dòng PETG Basic.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Một quy ước, một bộ hồ sơ (Priority: P1)

Người dùng mở OrcaSlicer, chọn máy rồi chọn nhựa và thấy đúng một hồ sơ cho cặp đó, tên theo một
quy ước, không phải đoán giữa các bản trùng nhau.

**Why this priority**: 25 hồ sơ vật liệu hiện tại đặt tên theo nhiều kiểu, có cặp trùng và cặp
thiếu; chọn nhầm hồ sơ là nguồn lỗi in trực tiếp.

**Independent Test**: Với mỗi cặp (máy, nhựa) trong phạm vi, chọn trong Orca và cắt lớp một mẫu;
đúng một hồ sơ hiện ra và cắt lớp không báo lỗi.

**Acceptance Scenarios**:

1. **Given** bộ hồ sơ mới đã nạp, **When** chọn một máy và một nhựa trong phạm vi, **Then** có
   đúng một hồ sơ theo quy ước tên, ghi rõ số nào đã đo và số nào kế thừa.
2. **Given** hồ sơ cũ còn trong Orca, **When** mở một file in cũ, **Then** file đó vẫn mở được
   với hồ sơ cũ.
3. **Given** một cặp không hợp lệ (ABS / ASA trên A1 hoặc A1 Mini), **When** tìm hồ sơ, **Then**
   không có hồ sơ cho cặp đó.

---

### User Story 2 - Cùng file, cùng kết quả trên mọi máy (Priority: P2)

Người dùng in bộ mẫu chuẩn bằng cùng một nhựa trên các máy và các chi tiết đo ra gần như nhau, lắp
chéo được giữa các máy.

**Why this priority**: Đây là mục tiêu "đồng bộ" của hiến chương, đứng ngay sau độ tin cậy.

**Independent Test**: In mẫu đo kích thước trên từng máy, người dùng đo bằng thước cặp và ghi vào
bảng; mọi máy nằm trong dung sai.

**Acceptance Scenarios**:

1. **Given** hồ sơ đã có số hiệu chuẩn của một nhựa, **When** in mẫu đo trên mỗi máy hợp lệ,
   **Then** kích thước đo được lệch không quá 0,1 mm trên 100 mm so với danh nghĩa ở mọi máy.
2. **Given** một máy lệch quá dung sai, **When** chỉnh bù cho máy đó và in lại, **Then** máy đạt
   và số bù được ghi vào hồ sơ của riêng cặp đó.
3. **Given** mẫu lỗ và chốt in trên hai máy khác nhau, **When** lắp chéo, **Then** lắp được như
   khi in cùng một máy.

---

### User Story 3 - Hồ sơ có nguồn gốc và khôi phục được (Priority: P3)

Bộ hồ sơ nằm trong thư mục dự án, có bảng ghi từng số lấy từ đâu, và có thể nạp lại vào một máy
tính khác hoặc sau khi cài lại Orca.

**Why this priority**: Hồ sơ chỉ nằm trong thư mục cấu hình của Orca thì mất khi cài lại hoặc
đồng bộ cloud ghi đè.

**Independent Test**: Xóa bộ hồ sơ mới khỏi Orca (sau khi sao lưu), nạp lại từ thư mục dự án; danh
sách và nội dung khớp.

**Acceptance Scenarios**:

1. **Given** bộ hồ sơ trong thư mục dự án, **When** nạp vào Orca, **Then** số hồ sơ và giá trị
   khớp với bảng.
2. **Given** người dùng thêm một hãng nhựa mới, **When** theo quy trình ghi sẵn, **Then** hồ sơ
   mới ra đời theo cùng quy ước và cùng các bước đo.

### Edge Cases

- Orca đồng bộ hồ sơ qua tài khoản Bambu: bản trên cloud có thể ghi đè bản vừa nạp.
- H2S là máy đời mới: bản Orca đang dùng có thể thiếu hồ sơ gốc hoặc tính năng; phải kiểm trước.
- Cùng tên nhựa nhưng lô khác nhau cho kết quả khác: hồ sơ ghi cuộn nào đã dùng để đo.
- Nhựa ẩm làm sai phép đo lưu lượng: quy trình ghi điều kiện sấy.
- Hồ sơ hiện có ngoài phạm vi (TPU, ASA-CF, SUNLU, HUTI): giữ nguyên, không đổi tên, không xóa.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Toàn bộ hồ sơ người dùng hiện có trong Orca PHẢI được sao lưu nguyên vẹn trước mọi
  thay đổi, và không hồ sơ cũ nào bị sửa hay xóa.
- **FR-002**: Bộ mới PHẢI theo một quy ước tên duy nhất cho hồ sơ máy, vật liệu và quy trình.
- **FR-003**: Mỗi cặp (máy, nhựa) hợp lệ trong phạm vi PHẢI có đúng một hồ sơ vật liệu. "Nhựa" ở
  đây là hãng cộng loại (Bambu PLA, Bambu PETG Basic, Tinmorry PETG-ECO, Tinmorry ABS Pro).
- **FR-004**: ABS / ASA chỉ có hồ sơ cho máy buồng kín (hai Voron, H2S, P1S); PLA chỉ có hồ sơ cho 4
  máy Bambu.
- **FR-005**: Mỗi giá trị trong hồ sơ PHẢI có nguồn: đo trong đợt này, kế thừa từ hồ sơ cũ (ví dụ
  hệ số co ngót XY), mặc định của nhà sản xuất, hoặc chưa đo.
- **FR-006**: Hồ sơ quy trình PHẢI cho kích thước chi tiết như nhau giữa các máy; chỗ tốc độ xung
  đột với đồng bộ thì đồng bộ thắng.
- **FR-007**: Bộ hồ sơ PHẢI lưu trong thư mục dự án và nạp lại được vào Orca.
- **FR-008**: PHẢI có bộ mẫu chuẩn dùng chung (đo kích thước, lỗ và chốt, bề mặt) và bảng ghi kết
  quả đo theo máy và nhựa.
- **FR-009**: Mã G-code khởi đầu và kết thúc của hai Voron trong hồ sơ máy PHẢI khớp với macro
  hiện hành trên máy (không nạp skew hai lần).
- **FR-010**: PHẢI có hướng dẫn ngắn để thêm một hãng nhựa mới theo cùng quy trình.

### Key Entities

- **Hồ sơ máy**: máy, đầu phun, giới hạn chuyển động, G-code khởi đầu và kết thúc.
- **Hồ sơ vật liệu**: hãng, loại, máy, nhiệt, PA, hệ số lưu lượng, lưu lượng tối đa, co ngót,
  nguồn của từng số.
- **Hồ sơ quy trình**: chiều cao lớp, tốc độ, gia tốc, bù kích thước.
- **Kết quả mẫu chuẩn**: máy, nhựa, cuộn, kích thước đo được, đạt hay không, ngày.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100 % cặp (máy, nhựa) hợp lệ trong phạm vi có đúng một hồ sơ theo quy ước; 0 cặp
  trùng trong bộ mới.
- **SC-002**: Mẫu đo kích thước lệch không quá 0,1 mm trên 100 mm (X, Y), 0,1 mm trên 20 mm (Z)
  và 0,15 mm ở lỗ Ø8 so với danh nghĩa trên mọi máy đã in thử, theo số đo thước cặp của người
  dùng. Mức này áp cho cả ABS / ASA; chưa đạt thì in bù tiếp, không nới.
- **SC-003**: Mẫu lỗ và chốt in trên hai máy khác nhau lắp chéo được.
- **SC-004**: Sao lưu hồ sơ cũ khớp từng file với bản gốc (so băm); 0 hồ sơ cũ bị đổi.
- **SC-005**: Nạp lại bộ hồ sơ từ thư mục dự án cho ra danh sách và giá trị khớp 100 %.
- **SC-006**: Người dùng thêm được một nhựa mới chỉ bằng hướng dẫn, không cần hỏi lại.

## Assumptions

- Cặp hợp lệ: PLA trên 4 máy Bambu; Bambu PETG Basic và Tinmorry PETG-ECO trên cả 6 máy; ABS Pro
  trên 4 máy buồng kín: 4 + 6 + 6 + 4 = 20 hồ sơ vật liệu.
- Quy ước tên: máy "DHH <Máy> 0.4", vật liệu "DHH <Hãng> <Loại> @<Máy>", quy trình
  "DHH 0.20 Sync @<Máy>".
- Số hiệu chuẩn của Voron đến từ đặc tả 002, của Bambu từ đặc tả 004; đặc tả này gom và kiểm chéo.
- Người dùng có thước cặp độ phân giải 0,01 mm và tự đo, tự chụp ảnh mẫu.
- Mọi máy dùng đầu phun 0,4 mm.
