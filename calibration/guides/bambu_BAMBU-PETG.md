# Thẻ hiệu chuẩn Bambu: Bambu PETG trắng (BAMBU-PETG)

Máy: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày), **P1S**, **A1**, **A1M** (A1 Mini).
Buổi: **D1, nửa 1** (004:T012). **Chỉ làm sau khi pilot PLA đạt** và sau khi đã đọc kết quả A/B ở thẻ PLA.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`. Văn phòng **không gửi lệnh nào tới máy Bambu**: mọi lần in do bạn bấm.

## A. Quy tắc K

- K **lưu trên máy**, theo bộ có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca của máy Bambu (research.md:39-41).
- H2S, A1, A1M: máy tự đo (H2S là suy ra từ H2D). **P1S: chỉ đo tay**, không có ô Flow Dynamics (research.md:30-32).
- Ô Flow Dynamics: Auto / On (đo trước mỗi lần in) / Off (dùng K đã đặt cho khe) (research.md:33-35).
- Nếu kết luận A/B ở thẻ PLA là "ô On không có tác dụng từ Orca" hoặc "chưa kết luận", **đừng dựa vào ô On**: hỏi trưởng phòng đường đo K khác (màn hình máy) trước khi làm bước 2.
- A1 và A1M không cho hiệu chuẩn khi đang in (research.md:13).

| Máy | Nhựa vào máy | Cách có K | Ghi thêm vào `điều_kiện` |
|---|---|---|---|
| H2S | khe AMS | máy tự đo | khe AMS, loại đầu phun |
| P1S | cuộn ngoài | đo tay, nhập K lên máy | tên bộ K |
| A1 | cuộn ngoài | máy tự đo | nơi nạp nhựa |
| A1M | cuộn ngoài | máy tự đo | nơi nạp nhựa |

## B. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi.
- [ ] Bàn sạch. PETG có thể dính chặt lên bàn nhẵn: dùng lớp chống dính mỏng nếu bạn vẫn dùng cho PETG, ghi vào `điều_kiện` (kinh nghiệm chung, chưa có nguồn trong dự án).
- [ ] Orca có hồ sơ `DHH Bambu PETG @<Máy>` (gói đủ 22 hồ sơ, 003:T024). Không thấy thì dừng, báo trưởng phòng. Hồ sơ hệ thống "Bambu PETG HF" khác với Basic; dùng hồ sơ DHH, không dùng hồ sơ hệ thống (`specs\003-orca-profiles\research.md:20-21`).
- [ ] Nhựa: cuộn Bambu PETG trắng, nhãn mã cuộn ví dụ `BAMBU-PETG-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn trong dự án: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`). H2S: ghi thêm thời gian cuộn đã nằm trong AMS.
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## C. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Bambu PETG @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. H2S: chọn đúng khe AMS và gán đúng loại nhựa.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"), ô Flow Dynamics **Auto**. Tìm độ cao bắt đầu xấu, đọc lưu lượng ở tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S, A1, A1M:** in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; máy đo K trước khi in. Đọc K của khe ở trang Device hoặc màn hình máy (chưa thử đường nào trên máy này). Không đọc được thì chụp màn hình, `k` = `chưa_đo`.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc Pattern), khoảng mặc định (điểm xuất phát; mở rộng nếu vạch đẹp nhất sát mép). Chọn vạch đẹp nhất, đổi sang K theo hộp thoại, nhập thành bộ K có tên (ví dụ `DHH-BAMBU-PETG-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập chưa thử trên máy này.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1** (ô **Auto**), chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100 (wiki Orca, chưa thử trên máy này); sửa tạm Flow ratio, **không Save** hồ sơ DHH. **Pass 2** tương tự. Orca hỏi lưu thì chọn bỏ.

PETG kéo sợi: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt hay thu hồi.

## D. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PETG.csv`, ví dụ `2026-12-05_P1S_BAMBU-PETG.csv` (và cho `H2S`, `A1`, `A1M`). Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
P1S,BAMBU-PETG,k,XX,-,đo,Orca PA Line đo tay; ảnh 2026-12-05_P1S_BAMBU-PETG_k.jpg,2026-12-05,BAMBU-PETG-01,bộ K DHH-BAMBU-PETG-2026-12-05
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## E. Sau khi xong

Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018).

## F. An toàn

Đầu phun và bàn nóng; gỡ sợi bằng kẹp. Không để tay vào trục khi máy chạy hiệu chuẩn.

## G. Chưa thử trên máy này

Tên menu Orca, công thức đọc số; chỗ đọc K và đường nhập K tay; hiệu lực của ô Flow Dynamics từ Orca (chờ kết quả A/B); chưa có số sấy từ nguồn.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,40`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
