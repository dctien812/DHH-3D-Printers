# Thêm một hãng hoặc loại nhựa mới

Dành cho người vận hành dàn máy. Làm theo từng bước, không cần hỏi lại. Chạy mọi lệnh trong PowerShell 5.1, từ thư mục gốc của dự án.

**Đã được làm thử độc lập ngày 2026-11-25 với một nhựa giả trên bản sao (xem `fleet\verify_003_addfilament.md`); chưa thử bước nhập vào Orca thật.** Người viết cũng đã chạy bước 3 đến 8 trên bản sao với nhựa giả `ACME-PETG` (dựng 33 file, `-Verify` lệch 0, cài thử vào thư mục giả, ingest và aggregate nhận cặp có trong bảng, từ chối cặp không có).
**Chưa thử trên máy này:** nhập hồ sơ hoặc gói zip vào Orca thật, Orca nhận hồ sơ, cắt lớp và in bằng hồ sơ mới, chiều áp hệ số bù co ngót. Chỗ nào liên quan được ghi rõ bên dưới.

## 1. Chọn mã nhựa và tên

| Thứ | Quy ước | Ví dụ (giả) |
|---|---|---|
| Mã nhựa | `<HÃNG>-<LOẠI>`, chữ hoa, không dấu cách | `ACME-PETG` |
| Tên hiển thị | `<Hãng> <Loại>` | `Acme PETG` |
| Tên hồ sơ | `DHH <Hãng> <Loại> @<Máy>` | `DHH Acme PETG @Voron Trident 250` |

`<Máy>` là cột `tên_ngắn` trong `profiles\src\machines.csv` (bảng đầy đủ ở `profiles\NAMING.md`): `Voron Trident 250`, `Voron 2.4 300`, `H2S`, `P1S`, `A1`, `A1 Mini`. Mã máy dùng trong cột `máy` là `TRI`, `V24`, `H2S`, `P1S`, `A1`, `A1M`.
Tên hồ sơ phải bắt đầu bằng `DHH ` (có dấu cách) và không trùng tên nào khác. Script từ chối nếu sai.
Quy ước viết: mã nhựa dùng chữ hoa, các phần nối bằng dấu gạch ngang, ví dụ `TIN-PETGECO`. Tên hãng và loại trong tên hồ sơ giữ nguyên cách viết của hãng, kể cả chữ hoa và dấu gạch (`Tinmorry PETG-ECO`, không viết thành `Tinmorry PETGECO`). Mã nhựa và tên hồ sơ dùng đúng một cách viết ở mọi nơi (bảng, phiếu, tên file).

## 2. Chọn máy hợp lệ

| Loại nhựa | Máy hợp lệ |
|---|---|
| PLA | chỉ 4 máy Bambu: H2S, P1S, A1, A1M |
| PETG | cả 6 máy |
| ABS, ASA | chỉ máy có buồng kín: TRI, V24, H2S, P1S |

Nguồn: `.specify\memory\constitution.md` (mục Ràng buộc kỹ thuật). Mỗi cặp máy-nhựa là **một dòng** trong `profiles\src\materials.csv`.
Script chỉ chặn cứng hai trường hợp: mã `BAMBU-PLA` trên Voron và mã `TIN-ABSPRO` trên A1, A1M (`scripts\orca\build-profiles.ps1:140-141`). Mã mới không bị chặn, nên **bạn tự giữ quy tắc trên**.

## 3. Thêm dòng vào `profiles\src\materials.csv`

Mở bằng VS Code hoặc Notepad, không dùng Excel. Lưu UTF-8. Số thập phân dùng dấu chấm. Ô có dấu phẩy thì đặt trong dấu nháy kép.
Mỗi dòng có 23 cột:

| Cột | Điền gì |
|---|---|
| `máy` | mã máy (`TRI`, `V24`, `H2S`, `P1S`, `A1`, `A1M`); phải có trong `profiles\src\machines.csv` |
| `nhựa` | mã nhựa ở bước 1 |
| `tên_hồ_sơ` | tên hồ sơ ở bước 1 |
| `cha` | tên hồ sơ hệ thống của Orca, xem bước 4 |
| `pa`, `pa_trạng_thái`, `pa_nguồn` | Voron: PA lấy từ hồ sơ Orca (số, ví dụ `0.02`). Bambu: để trống `pa`, trạng thái `chưa_đo`, nguồn ghi `K do máy in quản lý`; script bỏ qua `pa` của máy Bambu |
| `flow_ratio`, `flow_ratio_trạng_thái`, `flow_ratio_nguồn` | hệ số flow |
| `mvs`, `mvs_trạng_thái`, `mvs_nguồn` | lưu lượng thể tích tối đa (mm³/s) |
| `shrink_xy`, `shrink_xy_trạng_thái`, `shrink_xy_nguồn` | co ngót XY, đơn vị %, ví dụ `99.6` |
| `temp_nozzle`, `temp_nozzle_trạng_thái`, `temp_nozzle_nguồn` | nhiệt đầu phun (°C) |
| `khác`, `khác_trạng_thái`, `khác_nguồn` | khóa phụ dạng `khóa=giá trị;khóa=giá trị`. Giá trị `a\|b\|c` là mảng theo biến thể đầu phun (H2S 3 phần tử, P1S 2, máy còn lại 1). Không dùng khóa đã có ở cột khác, không dùng `setting_id`, `user_id`, `base_id` |
| `ngày` | `YYYY-MM-DD`, ngày thêm dòng |

Bốn trạng thái (`docs\data-formats.md`): `đo`, `kế_thừa`, `mặc_định`, `chưa_đo`.
- Ô có số thì phải có trạng thái khác `chưa_đo` và có nguồn. Thiếu thì dựng báo lỗi.
- **Số của hãng này không gắn cho hãng khác.** Hãng mới chưa đo thì để trống số và ghi `chưa_đo`. Nhiệt in để theo hồ sơ cha thì ghi `mặc_định`.
- Số `đo` trong `calibration\voron.csv` hoặc `calibration\bambu.csv` (hai file này do `scripts\calibration\ingest.ps1` tạo ở bước 8; chưa có cho tới khi chạy lần đầu) tự thắng số trong `profiles\src\materials.csv` khi dựng.

**Ví dụ một dòng hoàn chỉnh. Đây là hãng giả `ACME-PETG`, KHÔNG phải nhựa thật, đừng chép vào bảng thật:**

```
TRI,ACME-PETG,DHH Acme PETG @Voron Trident 250,Generic PETG @System,0.02,mặc_định,"Orca mặc định 0.02 (ví dụ giả)",,chưa_đo,"chưa đo, theo hồ sơ cha",,chưa_đo,"chưa đo, theo hồ sơ cha",,chưa_đo,"chưa đo, theo hồ sơ cha",,mặc_định,"nhiệt mặc định của hồ sơ cha",,chưa_đo,"không có khóa phụ",2026-11-25
```

Thêm một dòng cho mỗi máy hợp lệ (mỗi nhựa tối đa 6 dòng). Dòng máy Bambu khác dòng trên ở hai chỗ: `pa` để trống kèm `chưa_đo`, và `cha` theo bước 4.

## 4. Chọn hồ sơ cha (`cha`)

Hồ sơ cha là hồ sơ hệ thống có sẵn trong Orca. Liệt kê tên có chữ `PETG` (đổi chuỗi lọc cho loại khác):

```powershell
$n = foreach ($f in Get-ChildItem "$env:APPDATA\OrcaSlicer\system\*.opc") {
  $t = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($f.FullName))
  [regex]::Matches($t, 'filament/([\x20-\x7e]{3,120}?)\.json') | ForEach-Object { ($_.Groups[1].Value -split '/')[-1] }
}
$n | Sort-Object -Unique | Where-Object { $_ -like '*PETG*' }
```

Chỉ đọc file, không ghi. Cách chọn (theo các dòng đang có trong `profiles\src\materials.csv`):

| Máy | Cha đang dùng cho PETG | Cho ABS |
|---|---|---|
| TRI, V24 | `Generic PETG @System` | `PolyLite ABS @System` |
| H2S | `Generic PETG @BBL H2S` | `Bambu ABS @BBL H2S` |
| A1 | `Generic PETG @BBL A1` | không có ABS |
| A1M | `Generic PETG @BBL A1M` | không có ABS |
| P1S | `Generic PETG` (hệ thống không có bản riêng cho P1S) | `Generic ABS` |

**Loại không có trong bảng (ví dụ ASA, PLA):** chọn theo thứ tự này.
1. Hồ sơ của đúng hãng, cho đúng máy (ví dụ `Bambu ABS @BBL H2S`). P1S thường không có bản riêng: dùng bản `@BBL X1C`. Tên của A1M có thể kèm hậu tố `0.4 nozzle`.
2. Không có thì hồ sơ `Generic <loại>` của đúng máy (hậu tố `@BBL H2S`, `@BBL A1`, `@BBL A1M`; P1S dùng `Generic <loại>` không hậu tố hoặc bản `@BBL X1C`).
3. Máy Voron (TRI, V24) dùng hồ sơ `@System`, ví dụ `Generic <loại> @System`; không có thì một hồ sơ hệ thống cùng loại như `PolyLite ABS @System`.

Danh sách theo loại rất dài (lọc `*ASA*` trả hàng trăm tên). Lọc thêm theo máy cho ngắn lại, chạy sau đoạn lệnh liệt kê ở trên (đổi `ASA` và `H2S` cho phù hợp):

```powershell
$n | Sort-Object -Unique | Where-Object { $_ -like '*ASA*' -and $_ -like '*H2S*' }
$n | Sort-Object -Unique | Where-Object { $_ -like 'Generic ASA*' }
```

Dòng ABS của bảng trên theo quy tắc này; riêng TRI và V24 đang dùng `PolyLite ABS @System`.

Nhựa hãng Bambu thì ưu tiên hồ sơ Bambu cùng loại (ví dụ `Bambu PETG Basic @BBL H2S`). Tên cha sai chính tả thì `-Verify` báo (bước 5). Tên có thật nhưng không hợp máy thì script **không** biết: chọn đúng máy. Hồ sơ cha của P1S chưa thử cắt lớp trên Orca.

## 5. Dựng và kiểm

```powershell
.\scripts\orca\build-profiles.ps1 -Set all
.\scripts\orca\build-profiles.ps1 -Set all -Verify
```

- Phải có `-Set all`. Mặc định là `pilot` (chỉ gồm `BAMBU-PLA`), hồ sơ mới sẽ không được dựng.
- Dựng xong có dòng `Da sinh N file .json vao ...profiles\bundle (machine=6, process=6, filament=...)`. Số `filament` = 20 + số dòng bạn thêm.
- `-Verify` phải in `lech = 0` và thoát mã 0. Lệch thì in bảng file, khóa, giá trị mong đợi và thực tế, thoát mã 1. Sửa bảng nguồn rồi dựng lại.
- Kết quả ở `profiles\bundle\machine\`, `filament\`, `process\` và ba gói `profiles\bundle\import\DHH_printer.zip`, `DHH_filament.zip`, `DHH_process.zip`. Không sửa tay file trong `profiles\bundle\`; dựng lại là ghi đè.
- Muốn thử mà không đụng `profiles\bundle\`: thêm `-OutDir <thư mục tạm>` vào cả hai lệnh.

## 6. Cài vào Orca

> **Cảnh báo `-Install`:** hiện chưa có cách cài riêng một hồ sơ mới bằng script. `-Install` không `-Force` sẽ từ chối khi các hồ sơ DHH khác đã có trong Orca. `-Force` ghi đè **mọi** hồ sơ DHH, kể cả hồ sơ bạn đã sửa tay trong Orca. Cách an toàn hiện có là cách C bên dưới (chỉ file hồ sơ mới). Chọn cách C, trừ khi mọi chỉnh sửa tay đã được đưa vào bảng nguồn.

**Cách A, bằng script (Orca phải đóng; script từ chối nếu thấy Orca đang chạy):**

```powershell
# thử trước trên bản sao (chép thư mục user của Orca ra tests\tmp\orca_user_copy\<id>), chưa đụng Orca thật
.\scripts\orca\build-profiles.ps1 -Set all -Install -Force -UserDir "tests\tmp\orca_user_copy\<id>"
.\scripts\orca\build-profiles.ps1 -Set all -Verify -UserDir "tests\tmp\orca_user_copy\<id>"
# rồi mới cài thật
.\scripts\fleet\backup-orca.ps1 -Date 2026-12-01
.\scripts\orca\build-profiles.ps1 -Set all -Install -WhatIf
.\scripts\orca\build-profiles.ps1 -Set all -Install -Force
.\scripts\orca\build-profiles.ps1 -Set all -Verify -UserDir "$env:APPDATA\OrcaSlicer\user\<id>"
```

1. Ba dòng đầu thử trên bản sao (`-UserDir` tương đối tính từ gốc dự án; chép thư mục user của Orca sang bản sao trước, chỉ đọc từ Orca). Dòng sao lưu thư mục user của Orca vào `profiles\orca_backup\<ngày>\`. Đổi `-Date` thành ngày hôm nay; script từ chối ghi đè bản sao lưu cùng ngày.
2. `-WhatIf` chỉ in những file sẽ chép, không ghi.
3. `-Install` không ghi đè file đã có. Các hồ sơ DHH cũ đã nằm trong Orca nên **phải thêm `-Force`**. `-Force` chỉ ghi đè file tên bắt đầu `DHH ` và **thay cả những hồ sơ DHH bạn đã sửa trong Orca** bằng bản trong `profiles\bundle\`. Đã sửa tay trong Orca thì đưa số đó vào bảng nguồn trước.
4. Dòng cuối kiểm hồ sơ đã cài. Thay `<id>` bằng tên thư mục con của `%APPDATA%\OrcaSlicer\user\` (ngoài `default`); chỉ có một thư mục thì có thể bỏ `-UserDir` ở `-Install`.
5. Gỡ bộ DHH: `-Uninstall` (chỉ xóa file tên bắt đầu `DHH `).

**Cách B, nhập gói zip:** mở Orca, dùng menu File, Import, chọn `profiles\bundle\import\DHH_filament.zip`. Tên menu chưa đối chiếu với bản đang cài. Chưa thử trên máy này: Orca có nhận gói zip này không, và nhập trùng tên ghi đè hay hỏi.

**Cách C, chỉ hồ sơ mới (an toàn nhất, không đụng hồ sơ DHH khác):** nhập riêng từng file json của hồ sơ mới trong `profiles\bundle\filament\` bằng File, Import trong Orca (chưa thử trên máy này), hoặc đóng Orca rồi chép riêng file đó vào `%APPDATA%\OrcaSlicer\user\<id>\filament\` (Orca có nhận file chép tay hay không: chưa thử trên máy này).

Giữ Preferences, "Auto sync user presets" ở trạng thái tắt như hiện tại (`fleet\precheck\2026-11-24\SUMMARY.md`, mục Máy tính). Mở Orca, chọn máy `DHH <Máy> 0.4`: nhựa mới chỉ hiện ở đúng máy đã khai.

## 7. Hiệu chuẩn

Không chép lại các thẻ. Mở thẻ gần nhất rồi làm theo:

| Nhựa mới giống | Máy Voron (PA) | Máy Bambu (K do máy quản lý) |
|---|---|---|
| PETG | `calibration\guides\voron_TIN-PETGECO.md` | `calibration\guides\bambu_TIN-PETGECO.md` |
| ABS | `calibration\guides\voron_TIN-ABSPRO.md` | `calibration\guides\bambu_TIN-ABSPRO.md` |
| PLA | không in PLA trên Voron | `calibration\guides\bambu_BAMBU-PLA.md` |

Chưa có thẻ riêng cho mã mới: chép thẻ gần nhất sang tên mới, thay mã nhựa và tên hồ sơ, chỉ làm phần "Các bước" và "Ghi phiếu". Thứ tự: lưu lượng thể tích tối đa, rồi PA (Voron) hoặc K (Bambu), rồi flow. Nhiệt in dùng mặc định, ghi `mặc_định`. Ghi **mã cuộn** và **điều kiện sấy** (nhiệt độ và số giờ thực tế, hoặc `không_sấy`) vào phiếu.
Sau khi số vào hồ sơ (bước 8 và dựng lại, cài lại), làm nửa 2 theo `calibration\guides\NUA-2_mau-chuan.md` (in và đo mẫu `models\cal-a-frame-100x100x20.stl`, `models\cal-b-hole-pin.stl`; mô tả mẫu ở `models\README.md`).

## 8. Điền phiếu và gộp số

**Phiếu số hiệu chuẩn:** chép `calibration\entry\cal\TEMPLATE_cal.csv` thành `calibration\entry\cal\<ngày>_<máy>_<mã nhựa>.csv`, ví dụ `2026-12-06_TRI_ACME-PETG.csv`. Mỗi dòng một tham số: `pa`, `k`, `flow_ratio`, `mvs`, `shrink_xy`, `temp_nozzle`. Quy tắc (`docs\data-formats.md`, Bảng 2):
- Dòng `đo` phải có `nguồn`, `ngày`, `cuộn`. Thiếu một thì script từ chối.
- `chưa_đo` thì để trống `giá_trị`. Không điền số ước lượng với nhãn `đo`.
- Ngày dạng `YYYY-MM-DD`, không ở tương lai. Xóa dòng mẫu (có chữ `ĐIỀN`).
- Dòng `k` chỉ để ghi nhận; `scripts\orca\build-profiles.ps1` không đưa K vào hồ sơ (máy Bambu tự quản lý K).

**Phiếu mẫu chuẩn:** chép `calibration\entry\part\TEMPLATE_part.csv` thành `calibration\entry\part\<ngày>_<máy>_<mã nhựa>.csv`. `vòng` = 1 cho lần in đầu chưa bù; mỗi lần in lại sau khi bù tăng thêm 1.

**Mã nhựa mới:** thêm dòng vào `profiles\src\materials.csv` (bước 3) là đủ để `scripts\calibration\ingest.ps1` và `scripts\calibration\aggregate.ps1` nhận nhựa mới. Hai script đọc mã nhựa và cặp (máy, nhựa) hợp lệ từ bảng đó (tham số `-MaterialsFile`, mặc định chính bảng này); không đọc được bảng thì dừng và báo lỗi. Cập nhật dòng "Mã nhựa" ở `docs\data-formats.md` và bảng ở `profiles\NAMING.md` cho khớp tài liệu.

**Gộp phiếu hiệu chuẩn rồi dựng lại:**

```powershell
.\scripts\calibration\ingest.ps1
.\scripts\orca\build-profiles.ps1 -Set all
.\scripts\orca\build-profiles.ps1 -Set all -Verify
```

`scripts\calibration\ingest.ps1` ghi `calibration\voron.csv` và `calibration\bambu.csv` (in `Ghi ...: N dong`), rồi in bảng đếm theo máy. Có lỗi thì in lỗi từng dòng, thoát mã 1 và không ghi file nào. Đừng dùng `-Inherit` cho hãng mới (nó chỉ nạp số từ hồ sơ cũ `profiles\old_inventory.csv`). Sau đó cài lại như bước 6.

**Gộp số đo mẫu:**

```powershell
.\scripts\calibration\aggregate.ps1
```

Ghi `calibration\results.csv` (file tạo ra khi chạy; chưa có cho tới lần chạy đầu). Dòng cuối của bản tóm tắt cho biết số cặp ngoài dung sai ở vòng mới nhất, kèm gợi ý bù XY (ví dụ `X scale 99.86%`). Lệnh thoát mã 0 cả khi có cặp lệch; chỉ thoát mã 1 khi có file lỗi, nên **đọc dòng tóm tắt**.

## 9. Khi nào coi là xong

Cho **từng cặp máy-nhựa**, ở vòng mới nhất (`mới_nhất` = `có` trong `calibration\results.csv`), cột `đạt` = `đạt`:

| Kích thước | Dung sai |
|---|---|
| X, Y | ±0,1 mm trên 100 mm |
| Z | ±0,1 mm trên 20 mm |
| Lỗ Ø8 | ±0,15 mm |

Và mỗi tham số của cặp có số `đo` hoặc ghi `chưa_đo`, không để trống không nhãn.
Chưa đạt thì bù co ngót rồi in lại: ghi `shrink_xy` mới vào phiếu `cal` với nhãn `đo`, gộp, dựng, cài, in vòng kế tiếp. Script gợi ý áp hệ số lên giá trị hiện có của hồ sơ; **chiều áp trong Orca chưa kiểm**, nên sau vòng đầu phải đo lại để xác nhận. Từ vòng 3 của một cặp, báo người phụ trách văn phòng agent số đo và lượng nhựa đã dùng trước khi in tiếp (`specs\003-orca-profiles\tasks.md`, T016). ABS chưa đạt 0,1 mm thì giữ mức hiện có và in bù tiếp (`.office\ledger.md`, dòng K4).

## 10. Sai thường gặp

| Triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|
| Hồ sơ mới không được dựng | quên `-Set all` (mặc định `pilot`) | thêm `-Set all` |
| `Ten khong bat dau bang 'DHH '` | tên hồ sơ thiếu `DHH ` | sửa cột `tên_hồ_sơ` |
| `Ten ho so bi trung` | hai dòng cùng tên | đổi tên một dòng |
| `...co so nhung thieu trang_thai/nguon` | có số mà trạng thái `chưa_đo` hoặc thiếu nguồn | đổi trạng thái, thêm nguồn, hoặc xóa số |
| `trang_thai khong hop le` | trạng thái viết sai | dùng đúng 4 giá trị, có dấu |
| `khac sai dang`, `khoa bi dat hai lan`, `co N gia tri, can n` | cột `khác` sai dạng, trùng khóa, hoặc sai số phần tử mảng | sửa theo bước 3 |
| `-Verify` báo `inherits ... ten ho so he thong co that` | tên `cha` không có trong Orca | liệt kê lại tên (bước 4) |
| May khong co trong machines.csv | mã máy sai | dùng `TRI`, `V24`, `H2S`, `P1S`, `A1`, `A1M` |
| `Orca dang chay (orca-slicer)` | Orca còn mở | đóng Orca rồi chạy lại |
| `Tu choi ghi de N file da ton tai` | file DHH đã có trong Orca | thêm `-Force` (đọc cảnh báo ở bước 6) |
| `ma nhua la: '<mã>'`, `cap khong hop le: <nhựa> tren <máy>` (ingest) hoặc `pair <nhựa> on <máy> is not in ...materials.csv` (aggregate) | phiếu của cặp (máy, nhựa) không có trong `profiles\src\materials.csv` | thêm dòng của cặp đó vào bảng (bước 3), hoặc sửa mã máy/nhựa trong phiếu |
| `dong 'do' thieu cot ...` | dòng `đo` thiếu nguồn, ngày hoặc cuộn | điền đủ ba cột |
| Hồ sơ không hiện trong Orca | chưa chọn máy `DHH <Máy> 0.4`, hoặc dòng của máy đó chưa thêm | chọn đúng máy; thêm dòng |
| Số hiệu chuẩn không vào hồ sơ | quên chạy `scripts\calibration\ingest.ps1` (bước 8) hoặc quên dựng lại | chạy lại bước 8 |
| Số đo của hãng này bị gán cho hãng khác | chép dòng cũ không đổi số | để trống số, ghi `chưa_đo` |
| Sửa tay file trong `profiles\bundle\` rồi mất | dựng lại ghi đè | sửa ở `profiles\src\materials.csv` |
| Số không đọc được, script báo `khong phai so` | số viết bằng dấu phẩy thập phân hoặc có chữ lẫn vào | dùng dấu chấm (`0.03`); nên sửa CSV bằng VS Code |

## 11. Còn chưa kiểm

- Orca nhận hồ sơ không có `.info`, nhận gói zip, nhận mảng nhiều phần tử (H2S 3, P1S 2): chưa thử (`profiles\NAMING.md`).
- Chiều áp hệ số bù co ngót trong Orca; cách cắt lớp bằng hồ sơ cha của P1S.
- Menu và tên hộp thoại của Orca trong các thẻ hiệu chuẩn theo bản 2.x, chưa đối chiếu với bản đang cài.
- Orca nhận file json hồ sơ mới nhập riêng hoặc chép riêng (cách C ở bước 6): chưa thử.
