# Thẻ hiệu chuẩn Bambu: Tinmorry ABS Pro trắng (TIN-ABSPRO)

Máy: chỉ hai máy buồng kín: **H2S** (có AMS, nạp qua AMS như dùng hằng ngày) và **P1S**. Thẻ này không dành cho máy hở.
Buổi: **E, nửa 1** (004:T017). Chỉ làm sau khi pilot PLA đạt và sau khi đã đọc kết quả A/B ở thẻ PLA.
Trạng thái thẻ: soạn theo tài liệu hãng (`specs\004-bambu-calibration\research.md`), **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài; hộp thoại khác thẻ thì theo hộp thoại và ghi vào `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 K → 3 flow ratio**. Nhiệt in: **mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`. Văn phòng **không gửi lệnh nào tới máy Bambu**: mọi lần in do bạn bấm.

## A. An toàn ABS (đọc trước, bắt buộc)

- [ ] **Buồng đóng**: cửa và nắp đóng kín suốt lúc in và lúc nguội. ABS chỉ in trên máy có buồng kín (hiến chương, Ràng buộc kỹ thuật).
- [ ] **Phòng thông gió**: mở cửa sổ hoặc bật quạt hút ra ngoài trước khi in; ABS thải hơi khi in. Không ngồi lâu trong phòng đóng kín khi máy in. Lọc than của máy (H2S có lọc than trong lịch bảo trì, `research.md:48`) không thay cho thông gió phòng.
- [ ] Không mở cửa buồng để gỡ mẫu khi buồng còn nóng; chờ nguội.
- [ ] Có người ở gần suốt các lần in dài; không để máy in qua đêm cho buổi hiệu chuẩn này.
- [ ] Không chạm đầu phun, bàn, thành buồng khi vừa in xong.
- [ ] H2S: ABS qua AMS có thể khác cách bạn dùng hằng ngày; nạp **đúng như bạn vẫn làm** và ghi cách nạp vào `điều_kiện`. Dự án chưa có nguồn nói ABS Pro qua AMS có phù hợp hay không.

## B. Quy tắc K

- K **lưu trên máy**, theo bộ có tên, chọn cho từng khe nhựa (research.md:28-29). Hồ sơ `DHH` máy Bambu **không đặt** `pressure_advance`; **không bật** "Enable pressure advance" trong hồ sơ nhựa Orca (research.md:39-41).
- H2S: máy tự đo (suy ra từ H2D, research.md:30-32). **P1S: chỉ đo tay**, không có ô Flow Dynamics.
- Ô Flow Dynamics: Auto / On (đo trước mỗi lần in) / Off (research.md:33-35). Nếu kết luận A/B ở thẻ PLA là "ô On không có tác dụng từ Orca" hoặc "chưa kết luận", đừng dựa vào ô On: hỏi trưởng phòng đường khác.
- Đổi hãng nhựa thì hiệu chuẩn lại K (research.md:37): đừng mượn K của nhựa khác.

## C. Trước khi bắt đầu (tích hết mới làm, mỗi máy)

- [ ] Máy rảnh, không in, không báo lỗi; buồng nguội, sạch.
- [ ] Bàn đúng loại dùng cho ABS, sạch.
- [ ] Orca có hồ sơ `DHH Tinmorry ABS Pro @<Máy>` cho H2S và P1S. Không thấy thì dừng, báo trưởng phòng.
- [ ] Nhựa: cuộn Tinmorry ABS Pro trắng, nhãn mã cuộn ví dụ `TIN-ABSPRO-01`. Sấy theo nhãn hãng; chưa có số sấy từ nguồn trong dự án: ghi nhiệt độ và giờ **thực tế** vào `điều_kiện` (hoặc `không_sấy`).
- [ ] Số cũ để tham khảo, không phải số đo: lưu lượng ABS 22 (V24), 18 (Trident) mm³/s, flow 0,965, trên Voron; chưa có số cho hai máy Bambu (`specs\003-orca-profiles\research.md:27-29`).
- [ ] Thước cặp, điện thoại chụp ảnh, `calibration\entry\cal\TEMPLATE_cal.csv`.

## D. Các bước

**Bước 0.** Chọn máy `DHH <Máy> 0.4`, nhựa `DHH Tinmorry ABS Pro @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Đóng buồng, chờ nhiệt mặc định.

**Bước 1. mvs.** **Calibration → Max flowrate**, khoảng mặc định (điểm xuất phát; còn đẹp tới đỉnh thì nâng "End"), ô Flow Dynamics **Auto**. Tìm độ cao bắt đầu xấu, đọc lưu lượng ở tab Preview (kiểu màu lưu lượng thể tích). Ghi **số thô** (`mvs`); biên an toàn do trưởng phòng quyết.

**Bước 2. K.**
- **H2S:** in **Calibration → Flow Rate → Pass 1** với ô Flow Dynamics = **On**; máy đo K trước khi in. Đọc K của khe ở trang Device hoặc màn hình máy (chưa thử trên máy này). Không đọc được thì chụp màn hình, `k` = `chưa_đo`.
- **P1S:** **Calibration → Pressure Advance** (PA Line hoặc Pattern), khoảng mặc định (điểm xuất phát; mở rộng nếu đẹp nhất sát mép). Chọn vạch đẹp nhất, đổi sang K theo hộp thoại, nhập thành bộ K có tên (ví dụ `DHH-TIN-ABSPRO-<ngày>`, đề xuất), gán cho cuộn ngoài, theo `https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa`. Đường nhập chưa thử trên máy này.

**Bước 3. Flow.** **Calibration → Flow Rate → Pass 1** (ô **Auto**), chọn tấm mặt trên mịn nhất; số mới = flow cũ × (100 + số trên tấm) / 100 (wiki Orca, chưa thử trên máy này); sửa tạm Flow ratio, **không Save** hồ sơ DHH. **Pass 2** tương tự. Orca hỏi lưu thì chọn bỏ. Mẫu cong mép hoặc bong bàn: chụp ảnh, ghi `điều_kiện`, không tự chỉnh nhiệt.

## E. Ghi phiếu

Sao chép `TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_TIN-ABSPRO.csv`, ví dụ `2026-12-05_H2S_TIN-ABSPRO.csv` và `2026-12-05_P1S_TIN-ABSPRO.csv`. Bốn dòng: `mvs`, `k`, `flow_ratio`, `temp_nozzle` (`mặc_định`). Cột theo `docs\data-formats.md` Bảng 2. Ví dụ dòng (số **giả**):

```
P1S,TIN-ABSPRO,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-05_P1S_TIN-ABSPRO_mvs.jpg,2026-12-05,TIN-ABSPRO-01,buồng đóng; sấy <nhiệt/giờ thực tế>
```

Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Không đo được thì `chưa_đo`, để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.

## F. Sau khi xong

Chờ buồng nguội rồi mới mở. Báo trưởng phòng; trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (004:T014, 003:T028). Nhập gói mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T018).

## G. Chưa thử trên máy này

Tên menu Orca, công thức đọc số; chỗ đọc K và đường nhập K tay; hiệu lực của ô Flow Dynamics từ Orca (chờ kết quả A/B); ABS Pro qua AMS; chưa có số sấy; các điều kiện an toàn là khuyến cáo chung, chưa có nguồn riêng của hãng Tinmorry trong dự án.

Nguồn: `specs\004-bambu-calibration\tasks.md:37,45`, `.specify\memory\constitution.md:69-70`, `specs\004-bambu-calibration\research.md:24-43`, `docs\data-formats.md:30-54`.
