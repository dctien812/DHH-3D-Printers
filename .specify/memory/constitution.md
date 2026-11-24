<!--
Sync Impact Report (xóa trước khi commit)
- Phiên bản: mẫu → 1.0.0 (bản đầu, người dùng trả lời từng nguyên tắc ngày 2026-11-24)
  → 1.0.1 (PATCH, cùng ngày: nguyên tắc III nêu rõ cho phép riêng gói pushall, người dùng đồng ý)
- Nguyên tắc: 6 nguyên tắc mới (mẫu có 5 chỗ, thêm 1)
- Mục thêm: Ràng buộc kỹ thuật, Quy trình làm việc
- Mục bỏ: không
- TODO: không
-->
# Hiến chương Dàn máy in 3D

Phạm vi: 6 máy in trong mạng LAN — Voron Trident 250, Voron 2.4 300 (Klipper/Klippain),
Bambu H2S, P1S, A1, A1 Mini.

## Core Principles

### I. Thứ tự ưu tiên: Tin cậy > Đồng bộ > Chất lượng > Tốc độ

Mọi thay đổi PHẢI được cân theo thứ tự này khi các mục tiêu xung đột.
- Tin cậy: in xong không lỗi, lớp đầu bám, không cần trông máy. Thay đổi làm giảm độ ổn định
  thì không áp dụng, dù tăng chất lượng hay tốc độ.
- Đồng bộ: cùng một file in trên máy nào cũng cho kết quả gần như nhau; hồ sơ vật liệu và
  quy trình hiệu chuẩn quản lý chung. Máy nhanh được hãm lại nếu cần để giữ đồng bộ.
- Chất lượng (bề mặt, kích thước) đứng trên tốc độ; tốc độ chỉ đẩy tới mức chất lượng còn đạt.

### II. Thay đổi lên máy: tự áp dụng, luôn có sao lưu

Sau khi kế hoạch được duyệt, văn phòng tự áp dụng thay đổi cấu hình lên máy. Mỗi lần ghi PHẢI:
- chỉ làm khi máy không in;
- tải lại file đang có trên máy và so với bản làm việc trước khi ghi (người dùng cũng sửa
  trong Mainsail);
- sao lưu bản gốc vào `config/backups/<ngày>_<lý do>/` trên máy và chép về thư mục dự án;
- ghi sổ một dòng kèm cách hoàn tác.
Hỏi riêng người dùng trước khi: nạp firmware MCU, việc cần tháo lắp cơ khí, xóa dữ liệu trên máy.

### III. Máy Bambu: giữ cloud, không đổi chế độ

Bốn máy Bambu giữ nguyên firmware gốc và kết nối Bambu Cloud/Handy. KHÔNG bật LAN-only hay
Developer Mode, không dùng firmware bên thứ ba. Văn phòng được: đọc trạng thái qua LAN bằng
mã truy cập, tối ưu hồ sơ slicer, hiệu chuẩn vật liệu, hướng dẫn bảo trì. Gói duy nhất văn phòng
được gửi tới máy Bambu là yêu cầu "pushall" (bảo máy gửi lại toàn bộ trạng thái); mọi lệnh khác
đều cấm.

### IV. OrcaSlicer là slicer chuẩn cho cả 6 máy

Mọi hồ sơ máy, vật liệu và quy trình in nằm trong OrcaSlicer (đang dùng 2.5.2). Máy Bambu kết
nối qua plugin mạng Bambu trong Orca, vẫn dùng cloud. Hồ sơ PHẢI lưu bản sao trong thư mục dự
án, không chỉ nằm trong thư mục cấu hình của Orca.

### V. Cập nhật: Voron chủ động, Bambu hỏi từng lần

- Voron: cập nhật phần mềm host qua Moonraker, từng mục một, Trident làm máy thử trước, kiểm
  máy khởi động lại sạch rồi mới tới V2.4. Firmware MCU hỏi riêng.
- Bambu: KHÔNG tự nâng firmware. Trước mỗi bản mới phải tra ghi chú phát hành (nhất là thay
  đổi ảnh hưởng kết nối Orca), rồi trình người dùng quyết.

### VI. Chạy máy: phép đo không đùn nhựa được tự chạy, in mẫu chờ người dùng

- Văn phòng được tự chạy khi máy rảnh: đo cộng hưởng, PID, bed mesh, thử tốc độ không đùn.
  Trước khi chạy PHẢI kiểm máy ở trạng thái sẵn sàng, không có lệnh in, và ghi sổ.
- Mọi việc đùn nhựa (in mẫu hiệu chuẩn, in thử) chờ người dùng xác nhận vì cần nạp nhựa, dọn
  bàn in và nhìn kết quả.
- Không ghi "đã kiểm chứng" cho thông số chưa đo hoặc chưa in thử; số đo trước và sau dùng
  cùng một phép đo.

## Ràng buộc kỹ thuật

- Vật liệu trong phạm vi: PLA / PLA+, PETG, ABS / ASA. Hãng chính: Bambu PLA, Bambu PETG,
  Tinmorry PETG-ECO, Tinmorry ABS Pro; màu trắng là chủ yếu. Hãng khác thêm sau theo cùng quy
  trình. ABS / ASA chỉ in trên máy có buồng kín (hai Voron, H2S, P1S).
- Voron: giá trị người dùng chỉnh nằm trong `overrides.cfg`; không dùng SAVE_CONFIG cho thông
  số đã đặt ở đó (PID, shaper).
- Bí mật (mã truy cập Bambu, tài khoản cloud) không ghi vào spec, sổ ghi hay bộ nhớ; chỉ nằm
  trong file cục bộ không commit.

## Quy trình làm việc

- Theo quy tắc văn phòng trong `C:\Users\USER\.claude\CLAUDE.md`: người làm không tự kiểm;
  mục tiêu mới đi qua specify → clarify → plan → tasks → `checker` phản biện → người dùng duyệt
  một lần.
- Sổ ghi: `.office\ledger.md`, chỉ ghi thêm. Mỗi thay đổi lên máy có một dòng kèm bằng chứng.
- Việc đã làm ngày 2026-11-09 và 11-10 trên hai Voron (PID, skew, shaper, cập nhật) là nền; đo
  lại chỉ khi phần cứng đổi (ví dụ cân lại đai) hoặc có số liệu cho thấy sai.

## Governance

Hiến chương đứng trên spec, plan và tasks của dự án này; chỗ nào mâu thuẫn thì sửa spec. Sửa
hiến chương cần người dùng đồng ý, ghi một dòng vào sổ ghi, và tăng phiên bản theo semver (bỏ
hoặc định nghĩa lại nguyên tắc: MAJOR; thêm nguyên tắc hoặc mục: MINOR; sửa câu chữ: PATCH).
`checker` đối chiếu kế hoạch với hiến chương khi phản biện.

**Version**: 1.0.1 | **Ratified**: 2026-11-24 | **Last Amended**: 2026-11-24
