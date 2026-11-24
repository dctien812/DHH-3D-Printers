# Thẻ hiệu chuẩn Voron: Bambu PLA trắng (BAMBU-PLA)

Máy: **TRI** (Trident 250) và **V24** (Voron 2.4 300). Làm Trident trước, V24 sau; hai máy in cùng lúc được, chỉ cần một người nhìn.
Buổi: **C, nửa 1** (pilot, 002:T014). Đây là nhựa chạy đầu tiên; pilot chưa đạt thì D1, D2, E không chạy.
Trạng thái thẻ: soạn theo tài liệu và kế hoạch, **chưa thử trên máy này**. Tên menu Orca theo bản 2.x, chưa đối chiếu với bản đang cài (file cấu hình ghi 2.5.1, `fleet\precheck\2026-11-24\SUMMARY.md:49`). Chỗ nào hộp thoại Orca khác thẻ thì theo hộp thoại và ghi vào cột `điều_kiện`.

Thứ tự bắt buộc: **1 lưu lượng thể tích tối đa (mvs) → 2 pressure advance (PA) → 3 flow ratio**. Nhiệt in: **để mặc định của hồ sơ, không chỉnh**, ghi `mặc_định`.

## A. Trước khi bắt đầu (tích hết mới làm)

- [ ] Máy rảnh: Mainsail báo Ready, không có lệnh in nào, đầu in không còn nóng từ lần trước. (Lúc kiểm 2026-11-24 Trident đang tạm dừng ở 2,5 % và V24 đang in, `SUMMARY.md:11`: phải xử lý xong trước ngày làm.)
- [ ] Bàn in sạch, cùng loại bàn trên cả hai máy.
- [ ] Orca đã nhập gói hồ sơ pilot: có hồ sơ máy `DHH <Máy> 0.4` và nhựa `DHH Bambu PLA @<Máy>` (tên đầy đủ xem `profiles\NAMING.md` khi có). Không thấy thì dừng, báo trưởng phòng; không dùng hồ sơ cũ.
- [ ] Nhựa: lấy cuộn Bambu PLA trắng, dán nhãn mã cuộn (ví dụ `BAMBU-PLA-01`; ghi giống hệt vào cột `cuộn`). Điều kiện sấy: theo nhãn cuộn của hãng. Dự án chưa có số sấy từ nguồn nào, nên ghi nhiệt độ và số giờ bạn **thực tế** đã sấy (hoặc `không_sấy`) vào `điều_kiện`; không điền số ước.
- [ ] Thước cặp, điện thoại để chụp ảnh mẫu in, bút dán nhãn.
- [ ] Máy tính: mở sẵn thư mục `calibration\entry\cal\` và file mẫu `TEMPLATE_cal.csv` (do vai khác tạo).

## B. Các bước

**Bước 0. Chọn hồ sơ.** Trong Orca chọn máy `DHH <Máy> 0.4`, nhựa `DHH Bambu PLA @<Máy>`, quy trình `DHH 0.20 Sync @<Máy>`. Nạp nhựa, chờ đầu in tới nhiệt mặc định của hồ sơ.

**Bước 1. Lưu lượng thể tích tối đa.**
1. Menu **Calibration → Max flowrate** (Orca có thể ghi "Max volumetric speed").
2. Khoảng quét: giữ mặc định của hộp thoại (điểm xuất phát, chưa đo). Nếu cả tháp còn đẹp tới đỉnh thì nâng giá trị "End" và in lại.
3. Bấm Slice, gửi file lên máy từ Orca như mọi lần in, rồi bấm in.
4. Nhìn: tìm độ cao đầu tiên mà thành tháp bắt đầu xấu (thiếu nhựa, hở, thô, tiếng kêu bước nhảy). Lấy số lưu lượng tại đó. Cách chắc nhất: mở cùng file ở tab Preview của Orca, đổi kiểu màu sang lưu lượng thể tích, kéo thanh lớp tới đúng lớp đó và đọc số. Công thức wiki Orca (bắt đầu + độ cao × bước) là cách phụ, chưa thử trên máy này.
5. Ghi **số thô** tại điểm bắt đầu xấu vào phiếu (tham số `mvs`). Biên an toàn trừ bớt do trưởng phòng quyết khi đưa vào hồ sơ, bạn không tự trừ.

**Bước 2. Pressure advance (PA).**
1. Menu **Calibration → Pressure Advance → PA Tower** (hoặc PA Pattern nếu bạn quen hơn; ghi cách đã dùng vào `điều_kiện`).
2. Khoảng quét điểm xuất phát: **0 → 0,1** (chưa đo; số đang chạy là 0,02 và cấu hình gốc là 0,0475, `SUMMARY.md:25`, đều nằm trong khoảng). Nếu số đẹp nhất sát mép khoảng thì mở rộng và in lại.
3. In. PA đến Klipper qua G-code do Orca sinh ra; cả hai Voron đang đặt `material_profiles_enabled = False` (`SUMMARY.md:23`). Không chạy SAVE_CONFIG, không sửa `overrides.cfg` hay `variables.cfg` (đang có SAVE_CONFIG treo, `SUMMARY.md:27`).
4. Nhìn: góc tháp. Chọn độ cao có góc sắc nhất, không phồng, không tròn. Đổi độ cao thành PA bằng công thức trong hộp thoại Orca (chưa thử trên máy này), ghi số vào phiếu (`pa`).

**Bước 3. Flow ratio.**
1. Menu **Calibration → Flow Rate → Pass 1**. In, chọn tấm có mặt trên mịn nhất (sờ bằng ngón tay và nhìn nghiêng dưới đèn).
2. Số mới = flow cũ × (100 + số ghi trên tấm) / 100 (công thức theo wiki Orca, chưa thử trên máy này). Sửa **tạm** ô Flow ratio của nhựa trong Orca, **không bấm Save** hồ sơ DHH.
3. **Calibration → Flow Rate → Pass 2**, làm lại tương tự. Bỏ qua các mục YOLO để khớp quy trình.
4. Ghi flow cuối cùng vào phiếu (`flow_ratio`). Khi Orca hỏi lưu thay đổi hồ sơ thì chọn bỏ; trưởng phòng sẽ đưa số vào hồ sơ.

## C. Ghi phiếu

Sao chép `calibration\entry\cal\TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_BAMBU-PLA.csv`, ví dụ `2026-12-05_TRI_BAMBU-PLA.csv` và `2026-12-05_V24_BAMBU-PLA.csv`. Cột theo `docs\data-formats.md` Bảng 2: máy, nhựa, tham_số, giá_trị, đơn_vị, trạng_thái, nguồn, ngày, cuộn, điều_kiện. Số liệu mẫu (số trong ví dụ là **giả**, chỉ để minh họa):

```
máy,nhựa,tham_số,giá_trị,đơn_vị,trạng_thái,nguồn,ngày,cuộn,điều_kiện
TRI,BAMBU-PLA,mvs,XX,mm3/s,đo,Orca Max flowrate; ảnh 2026-12-05_TRI_BAMBU-PLA_mvs.jpg,2026-12-05,BAMBU-PLA-01,số thô tại điểm bắt đầu xấu; sấy <nhiệt/giờ thực tế>
TRI,BAMBU-PLA,pa,XX,s,đo,Orca PA Tower; ảnh ...,2026-12-05,BAMBU-PLA-01,quét 0-0.1
TRI,BAMBU-PLA,flow_ratio,XX,tỷ_lệ,đo,Orca Flow Rate Pass 2; ảnh ...,2026-12-05,BAMBU-PLA-01,
TRI,BAMBU-PLA,temp_nozzle,<đọc từ hồ sơ>,°C,mặc_định,hồ sơ DHH Bambu PLA @TRI,2026-12-05,BAMBU-PLA-01,không chỉnh
```

Quy tắc: dòng `đo` bắt buộc đủ `nguồn`, `ngày`, `cuộn`, nếu thiếu thì script nạp từ chối. Không đo được tham số nào thì đặt `chưa_đo` và để trống `giá_trị`; **không điền số ước lượng với nhãn `đo`**. Đơn vị gợi ý trên là đề xuất; nếu `TEMPLATE_cal.csv` ghi khác thì theo mẫu. Ảnh đặt cùng thư mục với phiếu, tên bắt đầu bằng tên phiếu (đề xuất, chưa có quy ước chính thức).

## D. Sau khi xong

Báo trưởng phòng "xong nửa 1 máy <mã>". Trưởng phòng chạy `ingest.ps1` và dựng lại hồ sơ (002:T018, 003:T028); bạn nhập gói hồ sơ mới vào Orca rồi mới in mẫu chuẩn (nửa 2, 003:T015). Văn phòng không điều khiển máy: mọi lần in do bạn bấm.

## E. An toàn

Đầu phun và bàn nóng: đợi nguội hoặc dùng găng khi gỡ. Không bỏ máy khi đang in lớp đầu. Không dùng tay vào máy khi đang chạy.

## F. Chưa thử trên máy này

Toàn bộ đường đi trong Orca (tên menu, khoảng quét, công thức đọc số); việc Orca đưa PA vào Klipper (nhận định dựa trên `SUMMARY.md:23-25`, chưa in thử); khoảng quét 0 → 0,1 là điểm xuất phát.

Nguồn: `specs\002-voron-tuning\tasks.md:57-58`, `specs\003-orca-profiles\plan.md:60`, `docs\data-formats.md:30-54`.
