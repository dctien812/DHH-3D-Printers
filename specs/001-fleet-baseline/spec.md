# Feature Specification: Kiểm kê và đường cơ sở dàn 6 máy in

**Feature Branch**: `001-fleet-baseline` (dự án không dùng git, tên chỉ để định danh)

**Created**: 2026-11-24

**Status**: Draft

**Input**: User description: "Bắt đầu spec-kit cài đặt tối ưu các máy in 3D hiện có trong mạng LAN:
Voron Trident 250, Voron 2.4 300, Bambu H2S, P1S, A1, A1 Mini" — phần 1/4: biết chính xác đang có
gì và mỗi máy đang ở trạng thái nào trước khi chỉnh.

## Clarifications

### Session 2026-11-24

- Q: Chia mục tiêu thành mấy đặc tả? → A: 4 (001 kiểm kê, 002 Voron, 003 hồ sơ Orca, 004 Bambu).
- Q: Máy Bambu nào có AMS? → A: Chỉ H2S.
- Q: Đọc trạng thái Bambu qua LAN bằng cách nào? → A: Người dùng tự điền mã truy cập vào file cục
  bộ không commit; văn phòng chỉ đọc, không gửi lệnh.
- Q: Máy A1 không thấy trên LAN? → A: Người dùng đã bật; quét lại thấy ở 192.0.2.122.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bảng kiểm kê một chỗ cho cả 6 máy (Priority: P1)

Người dùng mở một file và thấy ngay từng máy: địa chỉ, mẫu, phiên bản phần mềm và firmware, đầu
phun, bàn in, phụ kiện (AMS), và cách văn phòng kết nối tới nó.

**Why this priority**: Mọi đặc tả sau đều dựa vào bảng này; sai ở đây thì hồ sơ và hiệu chuẩn sai theo.

**Independent Test**: So từng dòng của bảng với thông tin máy tự báo (Moonraker, gói quảng bá LAN,
màn hình máy); không dòng nào lệch.

**Acceptance Scenarios**:

1. **Given** cả 6 máy đang bật, **When** chạy bước kiểm kê, **Then** bảng có đủ 6 dòng với địa
   chỉ, mẫu máy, phiên bản và nguồn của từng thông tin.
2. **Given** một máy đang tắt, **When** chạy bước kiểm kê, **Then** dòng của máy đó ghi "không
   trả lời" kèm thời điểm, các máy khác vẫn được ghi đủ.

---

### User Story 2 - Đường cơ sở trạng thái và sức khỏe từng máy (Priority: P2)

Với mỗi máy có một bản chụp trạng thái trước khi tối ưu: cấu hình đang chạy, thông số hiệu chuẩn
hiện có, lỗi đang treo, số giờ in, phần nào đã chỉnh trong đợt 11-09 / 11-10.

**Why this priority**: Không có số trước thì không chứng minh được tối ưu có tác dụng, và không
hoàn tác được.

**Independent Test**: Chọn ngẫu nhiên 3 thông số của một máy trong bản chụp, đọc lại trực tiếp
trên máy, khớp cả 3.

**Acceptance Scenarios**:

1. **Given** hai Voron trả lời Moonraker, **When** chụp đường cơ sở, **Then** thư mục dự án có
   bản sao toàn bộ file cấu hình người dùng kèm ngày, và bảng thông số hiệu chuẩn hiện hành.
2. **Given** người dùng đã điền mã truy cập Bambu, **When** chụp đường cơ sở, **Then** mỗi máy
   Bambu có bản ghi firmware, đầu phun, lỗi đang treo và trạng thái AMS; không lệnh nào được gửi
   làm đổi trạng thái máy.
3. **Given** việc Voron đã xong ngày 11-09 / 11-10, **When** viết đường cơ sở, **Then** phần đó
   chỉ ghi trạng thái và trỏ tới bằng chứng sẵn có, không đo lại.

---

### User Story 3 - Danh sách khoảng trống cần tối ưu (Priority: P3)

Từ bảng kiểm kê và đường cơ sở, người dùng có danh sách xếp hạng những chỗ lệch giữa các máy và
những thông số chưa hiệu chuẩn, mỗi mục gắn với đặc tả 002, 003 hoặc 004.

**Why this priority**: Đây là đầu vào để ba đặc tả sau không làm thừa hay sót.

**Independent Test**: Mỗi mục trong danh sách trỏ được tới một dòng số liệu trong đường cơ sở.

**Acceptance Scenarios**:

1. **Given** đường cơ sở đã xong, **When** lập danh sách, **Then** mỗi mục có: máy, hiện trạng,
   mức ảnh hưởng theo thứ tự ưu tiên của hiến chương, và đặc tả sẽ xử lý.

### Edge Cases

- Máy đang in lúc kiểm kê: chỉ đọc, không chạm; ghi rõ số liệu lấy lúc máy đang in.
- Địa chỉ máy đổi (DHCP): bảng ghi cả định danh ổn định (tên máy, MAC) để tìm lại.
- Mã truy cập sai hoặc chưa điền: máy đó chỉ có dữ liệu quảng bá, đánh dấu "chưa đủ".
- Máy A1 Mini mang tên khác các máy còn lại ("TTeccS"): xác nhận với người dùng đây đúng là máy
  trong phạm vi.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Bảng kiểm kê PHẢI có đủ 6 máy, mỗi máy ghi địa chỉ, MAC, mẫu, phiên bản phần mềm
  và firmware, đầu phun, kích thước bàn, phụ kiện, cách kết nối, ngày ghi.
- **FR-002**: Mọi thao tác của đặc tả này PHẢI là chỉ đọc đối với máy in.
- **FR-003**: Bản sao cấu hình hai Voron PHẢI lưu trong thư mục dự án theo ngày, không ghi đè bản
  cũ ở `orig`, `recheck`, `v24`, `trident`.
- **FR-004**: Mã truy cập và số serial Bambu PHẢI nằm trong một file cục bộ do người dùng điền;
  không xuất hiện trong spec, sổ ghi, bộ nhớ hay báo cáo.
- **FR-005**: Đường cơ sở PHẢI ghi lại hồ sơ OrcaSlicer hiện có (6 máy, 25 vật liệu, 1 quy trình)
  bằng một bản sao lưu nguyên vẹn trong thư mục dự án.
- **FR-006**: Mỗi số liệu PHẢI ghi nguồn (máy tự báo, đo, người dùng cung cấp) và ngày.
- **FR-007**: Danh sách khoảng trống PHẢI xếp theo thứ tự Tin cậy > Đồng bộ > Chất lượng > Tốc độ.

### Key Entities

- **Máy in**: tên, mẫu, địa chỉ, MAC, phần mềm, firmware, đầu phun, bàn in, phụ kiện, cách kết nối.
- **Bản chụp đường cơ sở**: máy, ngày, bộ file cấu hình hoặc bản ghi trạng thái, thông số hiệu chuẩn.
- **Khoảng trống**: máy, hiện trạng, mức ảnh hưởng, đặc tả xử lý.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 6/6 máy có dòng kiểm kê đủ trường; kiểm ngẫu nhiên 3 trường mỗi máy đều khớp với máy.
- **SC-002**: 2/2 Voron có bản sao cấu hình theo ngày, so băm khớp với file trên máy lúc chụp.
- **SC-003**: 4/4 máy Bambu có bản ghi trạng thái; không máy nào đổi trạng thái do việc đọc.
- **SC-004**: 0 bí mật xuất hiện trong các file ngoài file cục bộ (kiểm bằng tìm chuỗi).
- **SC-005**: Người dùng đọc bảng kiểm kê và xác nhận không có dòng sai.

## Assumptions

- Hai Voron vẫn ở 192.0.2.89 (V2.4) và .90 (Trident), Moonraker không cần xác thực trong LAN.
- Bambu: H2S .61, P1S .199, A1 .122, A1 Mini .149 (theo gói quảng bá ngày 2026-11-24); tất cả
  đang ở chế độ cloud và giữ nguyên như vậy.
- Tất cả máy dùng đầu phun 0,4 mm (theo tên hồ sơ máy trong OrcaSlicer); kiểm lại ở bước kiểm kê.
- Số giờ in và lịch sử bảo trì của máy Bambu chỉ lấy được tới mức máy tự báo.
