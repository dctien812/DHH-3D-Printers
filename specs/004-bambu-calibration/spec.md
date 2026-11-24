# Feature Specification: Hiệu chuẩn và bảo trì 4 máy Bambu

**Feature Branch**: `004-bambu-calibration` (dự án không dùng git, tên chỉ để định danh)

**Created**: 2026-11-24

**Status**: Draft

**Input**: User description: "tối ưu các máy in 3D trong mạng LAN" — phần 4/4: Bambu H2S, P1S,
A1, A1 Mini.

## Clarifications

### Session 2026-11-24

- Q: Mức can thiệp vào máy Bambu? → A: Giữ cloud và firmware gốc; không bật LAN-only hay
  Developer Mode; chỉ đọc trạng thái qua LAN, tối ưu hồ sơ, hiệu chuẩn vật liệu, bảo trì.
- Q: Cập nhật firmware Bambu? → A: Không tự nâng; tra ghi chú phát hành rồi hỏi người dùng từng lần.
- Q: AMS? → A: Chỉ H2S có.
- Q: Mã truy cập? → A: Người dùng điền vào file cục bộ; văn phòng chỉ đọc.
- Q: Có cho gửi yêu cầu trạng thái "pushall" không? → A: Cho phép riêng gói này; lệnh khác cấm.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Máy sạch lỗi và đã qua hiệu chuẩn của hãng (Priority: P1)

Mỗi máy Bambu không còn lỗi treo, đã chạy các bước hiệu chuẩn có sẵn của máy (cân bàn, bù rung,
hiệu chuẩn động cơ tùy mẫu), và có danh sách bảo trì đến hạn.

**Why this priority**: Độ tin cậy đứng đầu; hiệu chuẩn vật liệu trên một máy đang có lỗi cơ khí
là vô nghĩa.

**Independent Test**: Đọc trạng thái máy sau khi làm: không lỗi treo, ngày hiệu chuẩn mới.

**Acceptance Scenarios**:

1. **Given** bản chụp đường cơ sở của đặc tả 001, **When** rà từng máy, **Then** mỗi lỗi treo có
   hướng xử lý, và danh sách bảo trì ghi việc nào người dùng cần làm bằng tay.
2. **Given** người dùng chạy hiệu chuẩn của hãng trên máy, **When** văn phòng đọc lại trạng thái,
   **Then** kết quả được ghi kèm ngày; văn phòng không tự gửi lệnh tới máy.

---

### User Story 2 - Hiệu chuẩn vật liệu trên từng máy Bambu (Priority: P2)

Mỗi máy Bambu có hệ số lưu lượng, hệ số động lực dòng chảy (K) và lưu lượng tối đa đã đo cho từng
nhựa hợp lệ, để đặc tả 003 đưa vào hồ sơ.

**Why this priority**: Đây là phần cho phép bốn máy Bambu khớp kích thước với nhau và với hai Voron.

**Independent Test**: In mẫu chuẩn của một nhựa trên một máy với số đã đo; đạt tiêu chí 0,1 mm
trên 100 mm của đặc tả 003.

**Acceptance Scenarios**:

1. **Given** người dùng đã nạp nhựa và xác nhận, **When** in mẫu hiệu chuẩn từ OrcaSlicer,
   **Then** số đo của cặp (máy, nhựa) được ghi kèm ảnh hoặc số đo của người dùng.
2. **Given** hồ sơ cũ đã có số đo (ví dụ co ngót XY), **When** lập bảng, **Then** số đó được kế
   thừa và ghi rõ là kế thừa, chỉ đo lại nếu mẫu chuẩn không đạt.
3. **Given** H2S có AMS, **When** hiệu chuẩn, **Then** số được ghi theo đường nạp thực tế dùng
   hằng ngày (qua AMS).

---

### User Story 3 - Quyết định firmware có căn cứ (Priority: P3)

Với mỗi máy, người dùng có một trang ngắn: firmware đang chạy, bản mới nhất, thay đổi nào ảnh hưởng
việc in qua OrcaSlicer, khuyến nghị nâng hay giữ.

**Why this priority**: Bản firmware Bambu mới có thể siết kết nối của phần mềm bên thứ ba; nâng
nhầm là mất luồng làm việc Orca mà hiến chương đã chọn.

**Independent Test**: Mỗi khuyến nghị dẫn được tới ghi chú phát hành chính thức kèm ngày.

**Acceptance Scenarios**:

1. **Given** phiên bản đang chạy (H2S 01.03.00.00, P1S 01.10.00.00, A1 01.09.00.00, A1 Mini
   01.09.00.00 theo gói quảng bá ngày 2026-11-24), **When** tra bản mới, **Then** mỗi máy có khuyến
   nghị kèm nguồn, và không máy nào bị nâng khi chưa có câu trả lời của người dùng.

### Edge Cases

- Máy đang in khi đọc trạng thái: chỉ đọc, ghi rõ số lấy lúc đang in.
- Kết nối đọc trạng thái qua LAN bị từ chối ở chế độ cloud trên một mẫu máy: chuyển sang dữ liệu
  quảng bá và ảnh chụp màn hình người dùng gửi; không đổi chế độ máy.
- A1 và A1 Mini không có buồng kín: không hiệu chuẩn ABS / ASA.
- Máy tự lưu hệ số K theo cuộn nhựa: tránh hai nơi (máy và hồ sơ slicer) cùng bù một thứ.
- A1 Mini bàn 180 mm: mẫu chuẩn 100 mm phải vừa bàn; kiểm ở bước kế hoạch.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Không thao tác nào được đổi chế độ kết nối, firmware hay cài đặt mạng của máy Bambu.
- **FR-002**: Văn phòng chỉ đọc trạng thái máy Bambu; gói duy nhất được gửi tới máy là yêu cầu
  trạng thái "pushall". Lệnh làm máy chuyển động, nóng lên hoặc in do người dùng khởi động trên
  máy hoặc từ OrcaSlicer.
- **FR-003**: Mỗi máy PHẢI có danh sách lỗi treo đã xử lý và danh sách bảo trì đến hạn.
- **FR-004**: Mỗi cặp (máy Bambu, nhựa hợp lệ) PHẢI có số hiệu chuẩn đã đo hoặc nhãn "chưa đo".
- **FR-005**: Số hiệu chuẩn PHẢI ghi ở dạng mà đặc tả 003 đọc được, kèm ngày, cuộn nhựa, điều kiện.
- **FR-006**: PHẢI nêu rõ với từng máy hệ số K lấy ở đâu (máy tự lưu hay hồ sơ slicer) để không
  bù hai lần.
- **FR-007**: Khuyến nghị firmware PHẢI dẫn nguồn chính thức; trang chính thức chặn truy cập tự
  động thì người dùng mở và dán nội dung, hoặc khuyến nghị ghi rõ là dựa trên nguồn bên thứ ba.
  Quyết định nâng thuộc về người dùng.
- **FR-008**: Bí mật của máy (mã truy cập, serial, tài khoản) chỉ nằm trong file cục bộ.

### Key Entities

- **Trạng thái máy Bambu**: máy, firmware, đầu phun, lỗi treo, AMS, ngày hiệu chuẩn của hãng.
- **Việc bảo trì**: máy, việc, lý do, ai làm, xong hay chưa.
- **Số hiệu chuẩn vật liệu**: máy, nhựa, cuộn, hệ số lưu lượng, K, lưu lượng tối đa, nguồn.
- **Khuyến nghị firmware**: máy, bản đang chạy, bản mới, thay đổi liên quan, khuyến nghị, nguồn.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 4/4 máy không còn lỗi treo chưa có hướng xử lý.
- **SC-002**: 100 % cặp (máy Bambu, nhựa hợp lệ) có số đo hoặc nhãn "chưa đo"; 0 số ước lượng bị
  ghi là đã đo.
- **SC-003**: Mẫu chuẩn trên mỗi máy Bambu đã thử đạt 0,1 mm trên 100 mm (cùng tiêu chí đặc tả 003).
- **SC-004**: 4/4 máy có khuyến nghị firmware kèm nguồn; 0 máy bị đổi firmware hay chế độ kết nối
  mà không có quyết định của người dùng.
- **SC-005**: 0 lệnh điều khiển được văn phòng gửi tới máy Bambu (yêu cầu trạng thái "pushall"
  không tính là lệnh điều khiển).

## Assumptions

- Cặp hợp lệ: PLA và PETG trên cả 4 máy; ABS / ASA trên H2S và P1S.
- Người dùng in mẫu qua OrcaSlicer với plugin mạng Bambu, máy ở chế độ cloud.
- Chế độ cloud vẫn cho đọc trạng thái qua LAN bằng mã truy cập; nếu không, dùng phương án ở Edge
  Cases.
- Máy A1 Mini tên "TTeccS A1 Mini" là máy trong phạm vi.
- Người dùng tự làm việc bảo trì bằng tay theo danh sách.
