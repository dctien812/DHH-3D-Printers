# Thẻ hiệu chuẩn Bambu: Tinmorry PETG-ECO trắng (TIN-PETGECO)

Máy: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày), **P1S**, **A1**, **A1M** (A1 Mini).
Buổi: **D2, nửa 1** (004:T013). Chỉ làm sau khi pilot PLA đạt và sau khi đã đọc kết quả A/B ở thẻ PLA.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`. Văn phòng **không gửi lệnh nào tới máy Bambu**: mọi lần in do bạn bấm.

## A. Quy tắc K

- K **lưu trên máy**, theo bộ có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca của máy Bambu (research.md:39-41).
- H2S, A1, A1M: máy tự đo (H2S là suy ra từ H2D). **P1S: chỉ đo tay**, không có ô Flow Dynamics (research.md:30-32).
- Ô Flow Dynamics: Auto / On (đo trước mỗi lần in) / Off (dùng K đã đặt) (research.md:33-35).
- Nếu kết luận A/B ở thẻ PLA là "ô On không có tác dụng từ Orca" hoặc "chưa kết luận", **đừng dựa vào ô On**: hỏi trưởng phòng đường đo K khác trước khi làm bước 2.
- **Hãng nhựa mới với máy**: nên hiệu chuẩn lại khi đổi hãng nhựa (research.md:37) nên đây là buổi bắt buộc cho Tinmorry, đừng mượn K của Bambu PETG.
- A1 và A1M không cho hiệu chuẩn khi đang in (research.md:13).

| Máy | Nhựa vào máy | Cách có K | Ghi thêm vào `điều_kiện` |
|---|---|---|---|
| H2S | khe AMS (gán loại nhựa PETG cho khe, hãng ngoài RFID thì gán tay) | máy tự đo | khe AMS, loại đầu phun |
| P1S | cuộn ngoài | đo tay, nhập K lên máy | tên bộ K |
| A1 | cuộn ngoài | máy tự đo | nơi nạp nhựa |
| A1M | cuộn ngoài | máy tự đo | nơi nạp nhựa |

## B. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi. Nếu D1 vừa in PETG: gỡ sợi và cặn nhựa cũ khỏi đầu phun và bàn trước khi đổi nhựa.
- [ ] Bàn sạch.
- [ ] Orca có hồ sơ `DHH Tinmorry PETG-ECO @<Máy>`. Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry PETG-ECO trắng, nhãn mã cuộn ví dụ `TIN-PETGECO-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn trong dự án: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`). H2S: ghi thêm thời gian cuộn đã nằm trong AMS.
- [ ] Số cũ để tham khảo, không phải số đo: lưu lượng PETG-ECO 12–13 mm³/s trên A1 và A1M (`specs\003-orca-profiles\research.md:28-29`).
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Tinmorry PETG-ECO @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. H2S: chọn đúng khe AMS.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"), ô Flow Dynamics **Auto**. Tìm độ cao bắt đầu xấu, đọc lưu lượng ở tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S, A1, A1M:** in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; máy đo K trước khi in. Đọc K của khe ở trang Device hoặc màn hình máy (chưa thử đường nào trên máy này). Không đọc được thì chụp màn hình, `k` = `chưa_đo`.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc Pattern), khoảng mặc định (điểm xuất phát; mở rộng nếu vạch đẹp nhất sát mép). Chọn vạch đẹp nhất, đổi sang K theo hộp thoại, nhập thành bộ K có tên (ví dụ `DHH-TIN-PETGECO-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập chưa thử trên máy này.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1** (ô **Auto**), chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100 (wiki Orca, chưa thử trên máy này); sửa tạm Flow ratio, **không Save** hồ sơ DHH. **Pass 2** tương tự. Orca hỏi lưu thì chọn bỏ.

## D. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-PETGECO.csv`, ví dụ `2026-12-05_A1_TIN-PETGECO.csv` (và cho `H2S`, `P1S`, `A1M`). Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
A1,TIN-PETGECO,flow_ratio,XX,tỷ_lệ,đo,Orca Flow Rate Pass 2; ảnh 2026-12-05_A1_TIN-PETGECO_flow.jpg,2026-12-05,TIN-PETGECO-01,cuộn ngoài
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## E. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018).

## F. An toàn

Đầu phun và bàn nóng; gỡ sợi bằng kẹp. Không để tay vào trục khi máy chạy hiệu chuẩn.

## G. Chưa thử trên máy này

Tên menu Orca, công thức đọc số; chỗ đọc K và đường nhập K tay; hiệu lực của ô Flow Dynamics từ Orca (chờ kết quả A/B); chưa có số sấy từ nguồn.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,41`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
