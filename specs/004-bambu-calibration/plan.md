# Implementation Plan: Hiệu chuẩn và bảo trì 4 máy Bambu

**Branch**: `004-bambu-calibration` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: `specs\004-bambu-calibration\spec.md`. Thiết kế chung: [../001-fleet-baseline/plan.md](../001-fleet-baseline/plan.md).
Bảng các buổi cần người dùng: [../003-orca-profiles/plan.md](../003-orca-profiles/plan.md).

## Summary

Từ bản chụp trạng thái của 001, lập phiếu sức khỏe từng máy, người dùng bảo trì và chạy hiệu chuẩn
của hãng, văn phòng đọc lại. Sau đó người dùng hiệu chuẩn 14 cặp (máy, nhựa) qua OrcaSlicer theo
thẻ hướng dẫn, kèm phép thử A/B để biết hệ số K nên lấy ở máy hay ở slicer. Cuối cùng là trang
khuyến nghị firmware có nguồn cho từng máy.

## Technical Context

**Language/Version**: PowerShell 5.1.

**Primary Dependencies**: `bambu-read.ps1` (001), `ingest.ps1` (002), bộ pilot và STL (003);
OrcaSlicer 2.5.2 với plugin mạng Bambu ở phía người dùng.

**Storage**: `calibration\bambu.csv`, `calibration\bambu\health_*.md`, `fleet\firmware\*.md`,
`docs\bambu-k-rule.md`.

**Testing**: `test-engineer` đối chiếu trạng thái đọc lại và bảng số; `security-auditor` rà gói
gửi đi.

**Constraints**: không đổi chế độ kết nối, firmware hay cài đặt mạng; gói duy nhất gửi tới máy là
pushall; mọi việc làm máy chuyển động do người dùng khởi động.

**Scale/Scope**: 4 máy, 14 cặp (máy, nhựa), 24 task.

**Chưa kiểm (giải trong task)**: K lưu ở máy hay slicer và cách tránh bù hai lần (T002, T011,
T016); nguồn chính thức về firmware và bảo trì (T001; wiki của hãng chặn truy cập tự động); đọc
trạng thái qua LAN ở chế độ cloud (thử ở 001:T011).

## Constitution Check

| Nguyên tắc | Đánh giá |
|---|---|
| I. Thứ tự ưu tiên | Sạch lỗi và bảo trì trước, hiệu chuẩn nhựa sau. Đạt. |
| II. Thay đổi lên máy | Văn phòng không ghi gì lên máy Bambu. Đạt. |
| III. Bambu giữ cloud | Không đổi chế độ; chỉ đọc cộng pushall; 09 rà ở T021. Đạt. |
| IV. OrcaSlicer | Người dùng in mẫu qua Orca; số đo vào bảng để 003 dựng hồ sơ. Đạt. |
| V. Cập nhật | Chỉ khuyến nghị; người dùng quyết từng máy (T020). Đạt. |
| VI. Chạy máy | Mọi việc chạy máy và đùn nhựa do người dùng làm. Đạt. |

## Tiêu chí nghiệm thu

SC-001 đến SC-005 của spec; bảng SC → task ở cuối [tasks.md](tasks.md).

## Rủi ro

- Không lấy được nguồn chính thức về bảo trì và firmware: phiếu ghi rõ nguồn bên thứ ba, hoặc
  người dùng mở trang của hãng và gửi nội dung.
- Phép thử A/B cho K không phân biệt được: ghi "chưa kết luận", giữ cách người dùng đang in.
- Máy tự lưu K theo cuộn (A1, A1 Mini có giới hạn số hồ sơ lưu trên máy, theo diễn đàn; chưa có
  nguồn chính thức).
- Đọc qua LAN bị từ chối ở chế độ cloud: dùng ảnh màn hình, không đổi chế độ máy.

## Việc khó hoàn tác

- Nâng firmware Bambu (thường không hạ lại được): văn phòng không làm; chỉ người dùng tự nâng sau
  T020. Theo nguồn bên thứ ba, cả 4 máy hiện đã ở bản mới nhất.
- Việc bảo trì bằng tay (tra dầu, vệ sinh) do người dùng làm theo phiếu.

## Phần không đụng tới

Chế độ kết nối, tài khoản cloud, cài đặt mạng, firmware của 4 máy; hệ số K đang lưu trên máy (chỉ
quan sát cho tới khi có quy tắc ở T016).

## Project Structure

Tạo `calibration\bambu\`, `calibration\guides\bambu_*.md`, `fleet\firmware\`,
`docs\bambu-k-rule.md`.
