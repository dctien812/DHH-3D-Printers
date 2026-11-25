# Nạp lại firmware MCU V2.4 về Klipper chính (task 002:T025)

Soạn 2026-11-25, sửa vòng 1 sau rà của checker. Trạng thái: BẢN NHÁP chờ rà lại (002:T036). Tài liệu NỘI BỘ: không đưa vào `docs\` (thư mục đó công bố công khai). Chưa lệnh nào trong đây đã chạy trên máy.

Hai phần:
- **PHẦN A: làm trước, không đổi máy** (mục 0 đến 3): khảo sát chỉ đọc, sao lưu, build sẵn, kiểm dict.
- **PHẦN B: buổi nạp G2, người dùng đứng cạnh máy** (mục 4 đến 8): dump, DFU, nạp, kiểm, cứu. Mục tiêu khoảng 45 phút, giới hạn cứng 90 phút.

Nhãn từng bước:
- **[NGƯỜI DÙNG]**: người dùng thao tác tay.
- **[TRƯỞNG PHÒNG qua SSH]**: gõ lệnh trên Pi (xem mục "Quyền truy cập Pi").
- **[TỰ ĐỘNG]**: lệnh Moonraker HTTP, trưởng phòng chạy được không cần SSH.

Quy ước: `<pi>` = địa chỉ Pi (không ghi ở đây). `<uuid-octopus>`, `<uuid-ebb>`, `<uuid-cartographer>` lấy từ `fleet\precheck\2026-11-24\V24\config\mcu.cfg` dòng 67, 125, 216 (đuôi `…ee63`, `…233b`, `…2672`); không chép UUID đầy đủ vào tài liệu. Lệnh thay đổi máy kèm `# HOÀN TÁC:` hoặc `# KHÔNG HOÀN TÁC ĐƯỢC`.

---

## Điều kiện DỪNG buổi (không nạp)

Gặp một trong các điều dưới đây: dừng, đưa máy về trạng thái chạy được (Klipper chạy, firmware cũ), ghi sổ, báo trưởng phòng. Không "thử thêm một lần".

| # | Điều kiện | Xử lý |
|---|---|---|
| D1 | Không xác định được offset bo nào bằng dump (4.2) | Không nạp bo đó (và không nạp bo kia nếu chưa xong EBB) |
| D2 | `lsusb` có HƠN MỘT thiết bị `0483:df11`, hoặc `dfu-util -l` liệt kê hơn một bo | Rút bo thừa khỏi DFU (ngắt nguồn bo đó) rồi kiểm lại |
| D3 | Không dump được firmware cũ của bo (đọc lỗi, hai lần đọc băm khác nhau). NGOẠI LỆ DUY NHẤT: EBB ở nhánh E-A khi Katapult đã chứng minh (`-q` thấy) và "Application Start" đã đọc, VÀ người dùng nói rõ bằng lời chấp nhận đường lui bằng build lại (ghi sổ); mọi trường hợp khác không có ngoại lệ (xem 4.1 bước 4, điểm dừng 2(c)) | Không nạp bo đó |
| D4 | EBB không vào được Katapult lẫn DFU | Dừng cả buổi, giữ nguyên cả hai bo (không nạp Octopus riêng) |
| D5 | Nhiệt độ bàn hoặc đầu in ≥ 40 °C, hoặc không cắt được nguồn bàn/heater (4.0) | Không vào DFU |
| D6 | Quá giới hạn thời gian: 90 phút kể từ lúc dừng Klipper. Giờ dừng và giờ hết hạn ghi bằng lệnh `date` ở 4.1 bước 1; trưởng phòng đọc lại `date '+%F %T'` tại mỗi điểm dừng | Đưa về trạng thái chạy được, hẹn lại |
| D7 | Phần A chưa xong (thiếu sao lưu, thiếu file build, dict không khớp, `dump-inspect.py --selftest` trên Pi chưa ra `TU KIEM: DAT` hoặc `--app` trên `.bin` thật chưa đạt (3.4)) | Không bắt đầu Phần B |
| D8 | Cáp USB tới EBB không đủ dài, hoặc phải tháo đầu in mà người dùng chưa đồng ý | Hỏi người dùng (6.1); không tự ý tháo |

## Nói thẳng với người dùng

1. **Không khôi phục được đúng từng byte firmware Kalico đang chạy**, trừ khi dump DFU (4.1) thành công và hai lần đọc khớp băm. Khi đó nạp lại dump ở `0x08000000` là trả bo về nguyên trạng, gồm cả bootloader.
2. Nếu không dump được, đường lui duy nhất là **build lại Kalico `v2026.04.00` (`ab900a01`) cùng thông số**: cùng mã nguồn, không chắc giống từng byte. Cách này chưa được kiểm chứng (URL, tag, `.config`); Phần A kiểm dict của nó với hằng số V24 để giảm rủi ro, nhưng chưa thử nạp.
3. Nạp firmware là bước KHÔNG hoàn tác được theo nghĩa tự động; "hoàn tác" luôn là nạp lại một bản khác.
4. Nếu EBB36 không có Katapult và phải vào DFU, có thể phải chạm tới bo trên đầu in và cáp USB riêng (6.1, D8).

## Quyền truy cập Pi

Hiện trưởng phòng chỉ có Moonraker HTTP, chưa có SSH. Hai phương án, người dùng chọn:
- **P1**: người dùng cấp SSH cho trưởng phòng (khuyến nghị: dừng/khởi động dịch vụ, build, nạp đều cần shell).
- **P2**: người dùng tự gõ theo tài liệu trên Pi và dán kết quả cho trưởng phòng.

Lệnh thay được bằng Moonraker HTTP (**[TỰ ĐỘNG]**, không cần SSH):

| Việc | HTTP | Không thay được |
|---|---|---|
| Trạng thái, phiên bản MCU, nhiệt độ, `last_stats` | `GET /printer/info`, `/printer/objects/query?...` | |
| Host Klipper (phiên bản, dirty, untracked) | `GET /machine/update/status` | `git status` chi tiết |
| `can0` bitrate/qlen, dịch vụ | `GET /machine/system_info` (khóa `canbus`, `service_state`) | `ip -details -statistics link`, `dmesg` |
| Dừng/khởi động Klipper | `POST /machine/services/stop?service=klipper`, `.../start?...` (`klipper` có trong `available_services` của `V24\system_info.json`) | |
| Tải cấu hình, log | `GET /server/files/...`, `klippy.log` qua `/server/files` | |
| G-code thử | `POST /printer/gcode/script` | |
| Không thay được: `ls ~/katapult`, `find`, `lsusb`, `dfu-util`, `make`, `flashtool.py`, `canbus_query.py`, `df`, `sha256sum` | cần SSH hoặc người dùng gõ | |

---

# PHẦN A: LÀM TRƯỚC, KHÔNG ĐỔI MÁY

## 0. Phạm vi, điều kiện, dụng cụ

**Phạm vi**: nạp lại firmware Klipper chính cho 2 MCU của V2.4: bo chính BTT Octopus MAX EZ (STM32H723, `mcu`, cầu USB-CAN) và EBB36 CAN Gen2 (STM32G0B1, `mcu toolhead`, qua CAN). Hiện cả hai chạy Kalico `v2026.04.00-0-gab900a01` dưới host Klipper chính `v0.13.0-822-g282db764` (`fleet\precheck\2026-11-24\V24\objects.json`, khóa `mcu`, `mcu toolhead`; `V24\update_status.json`, mục `klipper`). Cartographer V3 (`mcu cartographer`, firmware 6.1.0) KHÔNG đụng tới.

**Điều kiện bắt đầu Phần B** (thiếu một điều: dừng):
1. Buổi G2, người dùng đứng cạnh máy; máy nguội qua đêm, không in, không lệnh in chờ.
2. Phần A xong: khảo sát, sao lưu `fleet\backups\`, 4 file build đã kiểm dict (mục 3), Kalico dựng sẵn đã kiểm dict (2.2).
3. 002:T021 đã đọc log; 002:T036 đã rà (không còn Nghiêm trọng/Quan trọng).
4. Người dùng đã đọc "Nói thẳng", mục 6, và đồng ý các bước không hoàn tác.
5. Có đường vào Pi (P1 hoặc P2).

**Dụng cụ**: cáp USB-C dữ liệu (không phải cáp chỉ sạc) từ Pi tới Octopus (đang là cầu) VÀ một cáp USB-C dữ liệu thứ hai đủ dài từ Pi tới EBB36 trên đầu in (độ dài chưa kiểm: **thử với tới bo trước buổi nạp**); que bấm nút BOOT/RESET; đèn pin; điện thoại chụp nhãn; nhiệt kế hồng ngoại (nếu có); quyền sudo trên Pi; Pi có mạng.

## 1. KHẢO SÁT (chỉ đọc)

### 1.1 Lệnh

**[TỰ ĐỘNG]** (Moonraker GET):
```
GET /printer/info                                  -> state "ready"
GET /printer/objects/query?print_stats             -> state standby/complete/cancelled
GET /printer/objects/query?mcu&mcu%20toolhead&mcu%20cartographer
GET /printer/objects/query?heater_bed&extruder&temperature_sensor   -> GHI nhiệt độ mọi cảm biến làm MỐC TRƯỚC NẠP (dùng ở mục 5.2)
GET /machine/update/status ; GET /machine/system_info
```

**[TRƯỞNG PHÒNG qua SSH]** (trên Pi, chỉ đọc):
```
# S1 Host
git -C ~/klipper describe --tags --long --dirty
git -C ~/klipper rev-parse HEAD                    # kỳ vọng bắt đầu 282db764
git -C ~/klipper status --short
# S2 Katapult (công cụ trên Pi; CHƯA chứng tỏ bo có Katapult)
ls -la ~/katapult 2>&1 ; git -C ~/katapult log -1 --oneline 2>&1
# S3 Dấu vết build cũ (chỉ là GỢI Ý, không chắc là thứ đang nằm trên chip)
ls -la ~/klipper/.config ~/klipper/out 2>&1
find ~ -maxdepth 3 -type f ( -name .config -o -name 'klipper*.bin' -o -name 'katapult*.bin' -o -name 'deployer*.bin' ) -printf '%TY-%Tm-%Td %s %p\n' 2>/dev/null
ls -d ~/kalico* ~/danger* 2>&1
grep -E 'CONFIG_(MACH_|STM32_|CANBUS|USBCANBUS|CLOCK_REF|FLASH_|LOW_LEVEL|BOARD)' ~/klipper/.config 2>&1
grep -n -E 'katapult|flashtool|dfu-util|make flash|menuconfig' ~/.bash_history 2>&1 | tail -30
# S4 USB
ls -l /dev/serial/by-id/ 2>&1 ; lsusb
# S5 CAN
ip -details -statistics link show can0
grep -rn -i can /etc/network/interfaces.d /etc/systemd/network 2>/dev/null
# S6 Log
grep -E 'Git version|Build versions|Loaded MCU|MCU .*version' ~/printer_data/logs/klippy.log | tail -20
# S7 Tài nguyên
df -h / ; free -m ; vcgencmd get_throttled
# S8 Công cụ và Python
which dfu-util arm-none-eabi-gcc python3 xxd strings ; ls -d ~/klippy-env
arm-none-eabi-gcc --version | head -1 ; dfu-util --version | head -1
# S9 THỬ TRƯỚC công cụ CAN: dùng Python của Klipper, không dùng python3 hệ thống (Debian 13, Python 3.13)
python3 -c "import can" 2>&1 ; ~/klippy-env/bin/python -c "import can; print(can.__version__)" 2>&1
~/klippy-env/bin/python -c "import serial; print(serial.__version__)" 2>&1
~/klippy-env/bin/python ~/katapult/scripts/flashtool.py -h 2>&1 | head -5
~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py -h 2>&1 | head -5     # chỉ xem trợ giúp, chưa gửi gì lên bus
```
S9 quyết định interpreter cho mọi lệnh CAN ở Phần B. Nếu `~/klippy-env/bin/python` không import được `can`/`serial`: ghi lại, báo trưởng phòng; không cài gói (thay đổi hệ thống) khi chưa hỏi người dùng. Mọi lệnh CAN dưới đây viết là `<py>`: thay bằng `~/klippy-env/bin/python` (hoặc cái chạy được ở S9).
Không chạy `flashtool.py -q`/`canbus_query.py` ở giai đoạn này (chỉ an toàn khi Klipper đã dừng).

**[NGƯỜI DÙNG]** (nhìn, không chạm): chụp ảnh bo Octopus và EBB36, ghi chữ in cạnh nút BOOT/RESET. Wiki hãng có nút BOOT cho Octopus nhưng không ghi vị trí; EBB36 Gen2 không rõ (nguồn: tra web 2026-11-25). Kiểm cáp USB thứ hai với tới EBB.

### 1.2 Bảng "nếu thấy X thì đi nhánh Y" (dữ liệu khảo sát chỉ là gợi ý; offset thật quyết bằng dump ở 4.2)

| Thấy gì | Nghĩa là | Nhánh |
|---|---|---|
| `~/katapult` có + `.config`/history nhắc Katapult cho EBB | EBB có thể có Katapult | EBB **E-A** (thử ở 4.3) |
| Không dấu vết về Katapult/EBB | Chưa biết | Thử E-A (4.3); không ra thì **E-B** (DFU) |
| `.config` cũ H723 có `CONFIG_STM32_FLASH_START_20000` | GỢI Ý bo có bootloader 128 KiB | Ưu tiên kiểm bằng dump |
| `.config` cũ H723 có `FLASH_START_0`/No bootloader | GỢI Ý không bootloader | Ưu tiên kiểm bằng dump |
| Không có `.config` cũ | Thiếu dữ liệu | Dump quyết (4.2) |
| `lsusb` có `1d50:606f`, `/dev/serial/by-id/` không có Octopus | Đang là cầu (`V24\system_info.json`: `can0` driver `gs_usb`) | Bình thường |
| `lsusb` có `0483:df11` lúc này | Bất thường | DỪNG, hỏi người dùng |
| `can0` không có / `qlen` ≠ 128 / bitrate ≠ 1000000 | CAN không đúng | DỪNG, xem 6.4 |
| `git status` có file đã theo dõi bị sửa | Host dirty thật | Build bằng clone sạch (3.1) |
| `df` còn < 2 GB | Thiếu chỗ build | DỪNG, dọn chỗ (ngoài tài liệu) |
| S9 import `can` lỗi cả hai Python | Công cụ CAN không chạy | DỪNG, báo trưởng phòng |
| Bất kỳ `bytes_invalid`/lỗi bus > 0 từ trước | CAN đã có lỗi | Ghi mốc, báo checker |

**Điểm dừng 1**: chỉ sang mục 2 khi S1 đến S9 đã có kết quả, `can0` 1000000 qlen 128, S9 chạy được.

## 2. SAO LƯU VÀ GIỮ ĐƯỜNG LUI

### 2.1 Cấu hình và UUID
**[TỰ ĐỘNG]** Tải về `fleet\backups\<ngày>_V24_pre-reflash\`: `printer.cfg`, `mcu.cfg`, `overrides.cfg`, `moonraker.conf`, `save_variables.cfg`, cây `config\`, `objects.json` mới (có nhiệt độ mốc). So với bản chụp `fleet\precheck\2026-11-24\V24\config\`; mọi khác biệt ghi sổ. Hoàn tác: không cần (file mới trong thư mục dự án).
UUID: bo chính `…ee63` (`mcu.cfg:67`), EBB36 `…233b` (`:125`), Cartographer `…2672` (`:216`). Không có `canbus_interface` trong cấu hình (mặc định `can0`).

### 2.2 Giữ firmware Kalico đang chạy
Firmware trên chip không đọc ngược được bằng Katapult hay Klipper. Ba mức; **mức 3 (dump DFU) là cách DUY NHẤT khôi phục đúng từng byte, nên là bước bắt buộc ở Phần B (4.1)**, không phải tùy chọn. Mức 1 và 2 làm ở Phần A như lưới an toàn.

1. **File cũ còn trên Pi** (S3), **[TRƯỞNG PHÒNG qua SSH]**:
   ```
   mkdir -p ~/mcu-build/backup-kalico
   cp -a <file tìm được> ~/mcu-build/backup-kalico/
   sha256sum ~/mcu-build/backup-kalico/* <file gốc>      # băm phải khớp
   ```
   Hoàn tác: `rm -r ~/mcu-build/backup-kalico`. Tải về `fleet\backups\`. Lưu ý: `.config` cũ có thể không phải thứ đang trên chip.
2. **Build lại Kalico `v2026.04.00`** (băm `ab900a01`, từ `mcu_version` `v2026.04.00-0-gab900a01`), **[TRƯỞNG PHÒNG qua SSH]**:
   ```
   mkdir -p ~/mcu-build && cd ~/mcu-build
   git clone https://github.com/KalicoCrew/kalico kalico-rescue         # URL suy ra, chưa kiểm chứng
   git -C kalico-rescue checkout v2026.04.00                            # tag suy ra, chưa kiểm chứng
   git -C kalico-rescue rev-parse --short=8 HEAD                        # PHẢI ra ab900a01, khác thì DỪNG
   ```
   Build bốn biến thể như 3.1 (cùng 4 bảng menuconfig; `.config` cũ ở mức 1 nếu có thì dùng thay), kết quả `kalico_octopus_off128k.bin`, `kalico_octopus_off0.bin`, `kalico_ebb_off8k.bin`, `kalico_ebb_off0.bin`.
   **Kiểm dict Kalico với hằng số V24** (cùng lệnh 3.1): `MCU`, `CLOCK_FREQ`, `CANBUS_BRIDGE`/`CANBUS_FREQUENCY`, `RESERVE_PINS_*` phải bằng cột V2.4 ở 3.1b, `PWM_MAX` = 256, version `v2026.04.00-0-gab900a01`. Khác là build không dùng làm đường lui.
   Hoàn tác: `rm -r ~/mcu-build/kalico-rescue`.
3. **Dump flash bằng DFU**: xem 4.1 (Phần B).

**Điểm dừng 2 (cuối Phần A)**: chỉ cho phép Phần B khi (a) 2.1 đã nằm trong `fleet\backups\`, (b) mức 2 đã có 4 file Kalico với dict khớp V24 (hoặc mức 1 có file cũ khớp băm), (c) người dùng biết điều "Nói thẳng" số 1 và 2, và nếu muốn dùng ngoại lệ dump EBB (D3, 4.1 bước 4) thì đã nói rõ bằng lời là chấp nhận đường lui bằng build lại cho EBB (ghi sổ; không có lời nói đó thì dump EBB là bắt buộc), (d) 3.4 đã đạt trên Pi: `--selftest` ra `TU KIEM: DAT`, `CONFIG_FLASH_APPLICATION_ADDRESS` của từng `.config` khớp tên file, và `--app` trên đúng các `.bin` vừa build không ra `APP_OFFSET_MISMATCH` (Octopus phải `APP_OFFSET_OK`; bước 2 của 3.4; ghi đầu ra vào sổ).

## 3. BUILD FIRMWARE KLIPPER CHÍNH (Phần A, không đụng máy)

### 3.1 Nguồn, cách build, thời gian
Mục tiêu: MCU cùng dòng host `v0.13.0-822-g282db764`. Offset thật chỉ biết sau dump (4.2), nên **build sẵn cả hai biến thể offset cho mỗi bo** (4 file), chọn ở Phần B. **[TRƯỞNG PHÒNG qua SSH]**:
```
cd ~/mcu-build
git clone ~/klipper klipper-282db764          # clone cục bộ; hoàn tác: rm -r klipper-282db764
git -C klipper-282db764 checkout 282db764dc568841837f68af3964762189d2baee
git -C klipper-282db764 describe --tags --long --dirty    # PHẢI ra v0.13.0-822-g282db764, không -dirty
cd klipper-282db764
# Lặp cho từng biến thể (cfg: octopus_off128k, octopus_off0, ebb_off8k, ebb_off0)
nice -n 19 make menuconfig KCONFIG_CONFIG=$HOME/mcu-build/<cfg>.config   # nhập bảng 3.2/3.3 với offset tương ứng
nice -n 19 make -j2 KCONFIG_CONFIG=$HOME/mcu-build/<cfg>.config
# Băm NGAY lúc build, từ out/ (trước khi chép), vào ~/mcu-build/SHA256SUMS; gate.sh đòi đúng 1 dòng mỗi file. HOÀN TÁC: rm ~/mcu-build/SHA256SUMS
touch ~/mcu-build/SHA256SUMS; sed -i '/  <cfg>_klipper-0\.13\.0-822\.bin$/d; /  <cfg>\.config$/d' ~/mcu-build/SHA256SUMS   # build lại: bỏ dòng cũ
echo "$(sha256sum < out/klipper.bin | cut -d' ' -f1)  <cfg>_klipper-0.13.0-822.bin" >> ~/mcu-build/SHA256SUMS
echo "$(sha256sum < $HOME/mcu-build/<cfg>.config | cut -d' ' -f1)  <cfg>.config" >> ~/mcu-build/SHA256SUMS
cp out/klipper.bin ~/mcu-build/<cfg>_klipper-0.13.0-822.bin ; cp out/klipper.dict ~/mcu-build/<cfg>.dict
(cd ~/mcu-build && sha256sum -c SHA256SUMS)     # phải OK hết (bắt file chép cụt), khác: DỪNG
make clean KCONFIG_CONFIG=$HOME/mcu-build/<cfg>.config
```
Thời gian: ước 2 đến 5 phút mỗi bản trên Pi 4 2 GB với `nice` (ước lượng, chưa đo); làm Phần A khi máy rảnh hoặc dùng `nice` nếu máy đang bận. Tổng dự trù cho 4 bản + 4 bản Kalico: dưới 45 phút, không tính vào buổi nạp. (`KCONFIG_CONFIG=` chưa kiểm chứng ở bản này; nếu không chạy, copy `.config` thủ công và ghi lại.) Không dùng `make flash`.

**Kiểm dict từng file** (so với 3.1b):
```
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); c=d['config']; print(d['version']); [print(k,c.get(k)) for k in ('MCU','CLOCK_FREQ','CANBUS_BRIDGE','CANBUS_FREQUENCY','RESERVE_PINS_CAN','RESERVE_PINS_USB','RESERVE_PINS_crystal','PWM_MAX')]" ~/mcu-build/<cfg>.dict
```
(cấu trúc `klipper.dict` suy ra.) Khác bảng 3.1b (trừ `PWM_MAX`=32768) là DỪNG.

**Kiểm offset của từng `.bin`** (dict KHÔNG chứa offset nên menuconfig gõ sai offset không bị dict bắt):
```
grep -E 'CONFIG_FLASH_APPLICATION_ADDRESS|CONFIG_STM32_FLASH_START' ~/mcu-build/<cfg>.config
python3 ~/mcu-build/dump-inspect.py --board <bo> --app <offset> ~/mcu-build/<cfg>_klipper-0.13.0-822.bin      ; echo "rc=$?"
```
**Căn cứ chính của offset là `CONFIG_FLASH_APPLICATION_ADDRESS` trong `.config` đã dùng để build** (tên biến đã xác nhận trên bản build thật 2026-11-25). Phải khớp: `0x8020000` (octopus_off128k), `0x8002000` (ebb_off8k), `0x8000000` (octopus_off0, ebb_off0). `--app` chỉ là kiểm tra phụ: `<bo>` = `octopus` hoặc `ebb36`; `<offset>`: `0x20000` (octopus_off128k), `0x0` (octopus_off0, ebb_off0), `0x2000` (ebb_off8k). Quy tắc `--app`: SP trong RAM, RESET lẻ, RESET và mọi mục vector khác 0/`0xFFFFFFFF` trong 64 mục đầu (octopus) hoặc 16 mục đầu (ebb36) nằm trong `[địa chỉ nạp, địa chỉ nạp + kích thước file)`. Kết quả: Octopus phải `APP_OFFSET_OK` (rc 0); EBB ra `APP_OFFSET_AMBIGUOUS` (rc 5) là bình thường vì ảnh ~47 KiB hợp lệ ở cả 0 lẫn 0x2000, nên **với EBB, `.config` là căn cứ duy nhất phân biệt 0/8K**; `APP_OFFSET_MISMATCH` (rc 4) ở bất kỳ bo nào: DỪNG, build lại file đó. Đã chạy thật trên 4 bản build và `trident_out_klipper.bin` (`fleet\reflash\2026-11-25\`): Octopus 0 và 128K tách hoàn toàn; EBB ra AMBIGUOUS ở cả 0 và 0x2000. Tải `.bin`, `.config`, `.dict`, `SHA256SUMS` về `fleet\backups\`.

**Manifest và cổng nạp** (làm ngay sau khi 4 file qua bước kiểm trên). **[TRƯỞNG PHÒNG qua SSH]** tạo `~/reflash-work/MANIFEST`, mỗi dòng: `<biến thể> <SHA256 .bin> <đường dẫn .bin> <đường dẫn .config> <CONFIG_FLASH_APPLICATION_ADDRESS>`; tên biến thể: `octopus_off0`, `octopus_off128k`, `ebb36_off0`, `ebb36_off8k`. Mọi lệnh nạp ở 4.3/4.4 lấy đường dẫn từ đây, không gõ tay.
```
mkdir -p ~/reflash-work                      # HOÀN TÁC: rm -r ~/reflash-work
(cd ~/mcu-build && sha256sum -c SHA256SUMS)  # băm ghi lúc build; phải OK hết, khác: DỪNG. KHÔNG lập lại SHA256SUMS từ file đã chép
M=~/reflash-work/MANIFEST; : > "$M"
for p in octopus_off0:octopus_off0 octopus_off128k:octopus_off128k ebb36_off0:ebb_off0 ebb36_off8k:ebb_off8k; do
  v=${p%%:*}; c=${p#*:}; bin=$HOME/mcu-build/${c}_klipper-0.13.0-822.bin; cfg=$HOME/mcu-build/$c.config
  addr=$(sed -n 's/^CONFIG_FLASH_APPLICATION_ADDRESS=//p' "$cfg")
  echo "$v $(sha256sum "$bin" | cut -d' ' -f1) $bin $cfg $addr" >> "$M"
done
cat "$M"; awk 'NF!=5{b=1} END{exit b || NR!=4}' "$M" && echo MANIFEST_OK      # không in MANIFEST_OK: DỪNG
```
Đọc lại: cột 5 phải là `0x8000000` cho `*_off0`, `0x8002000` cho `ebb36_off8k`, `0x8020000` cho `octopus_off128k`; SHA256 trùng `SHA256SUMS`. Chép về máy tính: `scp <pi>:reflash-work/MANIFEST fleet\reflash\<ngày>\MANIFEST` (chỉ đọc trên Pi).

Tạo script cổng `~/reflash-work/gate.sh` (file mới; HOÀN TÁC: xóa cùng thư mục ở trên). Cách gọi: `bash ~/reflash-work/gate.sh <ebb36|octopus> <VARIANT> <OFF>`. Đạt thì in đường dẫn `.bin` ra stdout, mã 0; sai bất kỳ điều kiện nào thì in `CONG: DUNG: <lý do>`, mã 1, stdout rỗng. Script kiểm theo thứ tự: biến thể thuộc đúng bo; `OFF` khớp offset của biến thể; manifest có đúng một dòng cho biến thể; địa chỉ trong manifest khớp tên biến thể; SHA256 của `.bin` trùng manifest (bắt file bị đổi sau khi lập manifest); `.bin` và `.config` (sau khi theo symlink) trùng đúng một dòng trong `SHA256SUMS` ghi lúc build nằm cùng thư mục với file (bắt file cắt cụt/sửa sau build kể cả khi manifest lập trên chính file hỏng); `.config` có đúng dòng `CONFIG_FLASH_APPLICATION_ADDRESS=<địa chỉ>`; `--app` ra rc 0 (Octopus) hoặc rc 0/5 (EBB); với EBB thêm: SP = 0x20024000, RESET có bit Thumb, mọi vector nằm trong `[địa chỉ, địa chỉ+cỡ file)`, và `.bin` chứa literal VTOR = địa chỉ được một lệnh Thumb `LDR Rt,[PC,#imm]` trong file nạp (literal ghép đuôi không có lệnh nạp nên bị chặn); manifest có CRLF thì dừng; `OFF` kiểm ở dạng chuỗi (`0x` + tối đa 8 chữ số hex sau khi bỏ số 0 đầu).
```
cat > ~/reflash-work/gate.sh <<'EOF'
#!/bin/bash
# Cong truoc moi lenh nap. Dung: bash ~/reflash-work/gate.sh <ebb36|octopus> <VARIANT> <OFF>
# Dat: in duong dan .bin ra stdout, ma 0. Sai bat ky dieu kien: ly do ra stderr, ma 1, stdout rong.
MANIFEST=${MANIFEST:-$HOME/reflash-work/MANIFEST}
INSPECT=${INSPECT:-$HOME/mcu-build/dump-inspect.py}
BO=$1; VARIANT=$2; OFF=$3
die() { echo "CONG: DUNG: $*" >&2; exit 1; }
[ $# -eq 3 ] && [ -n "$BO" ] && [ -n "$VARIANT" ] && [ -n "$OFF" ] || die "thieu BO/VARIANT/OFF"
case "$BO:$VARIANT" in
  ebb36:ebb36_off0|octopus:octopus_off0) WANT=0x8000000 ;;
  ebb36:ebb36_off8k) WANT=0x8002000 ;;
  octopus:octopus_off128k) WANT=0x8020000 ;;
  *) die "bien the '$VARIANT' khong thuoc bo '$BO'" ;;
esac
[[ $OFF =~ ^0x0*([0-9a-fA-F]{1,8})$ ]] && [ $((16#${BASH_REMATCH[1]})) -eq $((WANT)) ] || die "OFF=$OFF khong khop bien the $VARIANT ($WANT)"
[ -f "$MANIFEST" ] || die "khong co $MANIFEST"
grep -q $'\r' "$MANIFEST" && die "manifest co CRLF (doi sang LF: sed -i 's/\\r\$//' $MANIFEST)"
N=$(awk -v v="$VARIANT" '$1==v' "$MANIFEST" | wc -l)
[ "$N" -eq 1 ] || die "manifest co $N dong cho $VARIANT (phai dung 1)"
read -r NAME SHA BIN CFG ADDR REST < <(awk -v v="$VARIANT" '$1==v' "$MANIFEST")
[ -n "$ADDR" ] && [ -z "$REST" ] || die "dong manifest cua $VARIANT sai dinh dang"
[ "$ADDR" = "$WANT" ] || die "manifest ghi dia chi $ADDR, bien the $VARIANT doi $WANT"
[ -f "$BIN" ] && [ -f "$CFG" ] || die "thieu file $BIN hoac $CFG"
echo "$SHA  $BIN" | sha256sum -c --status - || die "SHA256 cua $BIN khong khop manifest"
for f in "$BIN" "$CFG"; do # bam ghi luc build (3.1) trong SHA256SUMS canh file that: bat file cat cut/sua sau build du manifest lap tren file hong
  r=$(readlink -f "$f"); S=${r%/*}/SHA256SUMS; [ -f "$S" ] || die "khong co $S (ghi luc build, 3.1)"
  H=$(awk -v a="${r##*/}" -v b="$r" '{n=$2; sub(/^\*/, "", n)} n==a || n==b {print $1}' "$S")
  [ "$H" = "$(sha256sum < "$r" | cut -d' ' -f1)" ] || die "$f khong khop dung 1 dong trong $S (cat cut/sua sau build?)"
done
grep -qx "CONFIG_FLASH_APPLICATION_ADDRESS=$ADDR" "$CFG" || die "$CFG khong co dong CONFIG_FLASH_APPLICATION_ADDRESS=$ADDR"
APPOFF=$(printf '0x%X' $((ADDR - 0x8000000)))
python3 "$INSPECT" --board "$BO" --app "$APPOFF" "$BIN" >&2; R=$?
if [ "$BO" = octopus ]; then OK="0"; else OK="0 5"; fi
case " $OK " in *" $R "*) ;; *) die "--app rc=$R (chap nhan: $OK)" ;; esac
if [ "$BO" = ebb36 ]; then # STM32G0B1: flash 512K tai 0x08000000, RAM 144K (SP = 0x20024000). Bang vector + literal VTOR
  SZ=$(stat -L -c %s "$BIN"); [ "$SZ" -ge 64 ] || die "$BIN qua ngan ($SZ byte)"
  A=$((ADDR)); LIM=$((A + SZ)); [ "$LIM" -le $((0x8080000)) ] || die "$BIN vuot flash G0B1 (512K)"
  mapfile -t V < <(od -An -v -tx4 -w4 -N64 "$BIN" | tr -d ' ')
  [ "$((16#${V[0]}))" -eq $((0x20024000)) ] || die "EBB: SP=0x${V[0]} khac 0x20024000 (khong phai G0B1?)"
  [ $((16#${V[1]} & 1)) -eq 1 ] || die "EBB: RESET=0x${V[1]} khong co bit Thumb"
  for w in "${V[@]:1}"; do
    x=$((16#$w)); [ $x -eq 0 ] || [ $x -eq $((0xFFFFFFFF)) ] && continue
    [ $x -ge $A ] && [ $x -lt $LIM ] || die "EBB: vector 0x$w ngoai [$ADDR, $(printf 0x%X $LIM)) (sai offset hoac sai MCU)"
  done
  # literal VTOR phai duoc ma that nap: co lenh Thumb LDR Rt,[PC,#imm8*4] (0x48xx, M0+ chi co dang 16-bit) cach <=1024 byte tro dung vao no
  od -An -v -tu2 -w2 "$BIN" | awk -v a=$A '{h[NR-1]=$1} END{for(i=0;i+1<NR;i+=2) if(h[i]+65536*h[i+1]==a){L=2*i
    for(p=L-2;p>=0 && p>=L-1024;p-=2){x=h[p/2]; if(int(x/2048)==9 && p+4-(p+4)%4+(x%256)*4==L) f=1}} exit !f}' ||
    die "EBB: bin khong co literal VTOR $ADDR duoc lenh LDR nap (build cho offset khac?)"
fi
echo "CONG: DAT: $VARIANT $BIN nap tai $OFF" >&2
echo "$BIN"
EOF
bash ~/reflash-work/gate.sh ebb36 ebb36_off8k 0x08002000 >/dev/null; echo "rc=$?"     # thử khô: rc=0 và dòng CONG: DAT
```
Đã thử ở máy soạn (WSL; manifest giả lập trỏ vào `fleet\reflash\2026-11-25\`, lệnh nạp thay bằng `echo`; `tests\gate\run_gate_tests.sh`, vòng sửa lượt 4 của 002:T025b): 41/41 tổ hợp đúng cộng 1 phép kiểm thông báo CRLF. 9 tổ hợp đúng được cho nạp (4 bản build thật, `OFF` không số 0 đầu, bản sao và symlink tới bin thật). Bị chặn: đảo off0/off8k của EBB (qua `OFF` hoặc qua đường dẫn trong manifest), file Octopus ở cổng EBB và ngược lại, file cắt cụt (0x9000 byte; bớt 1/4/64/4096 byte cuối hoặc thêm 1 byte, manifest lập trên chính file hỏng), thư mục không có `SHA256SUMS`, `.config` sửa sau build, literal VTOR ghép đuôi vào bin sai offset (kể cả khi `SHA256SUMS` lập lại trên file đã ghép), `.config` sai, manifest thiếu dòng hoặc có dòng trùng hoặc CRLF, `VARIANT`/`OFF` rỗng hoặc dị dạng, không có manifest.

**Điểm dừng 3 (cuối build)**: cả 4 file (và 4 file Kalico, 2.2) đều có: dict khớp 3.1b, `grep` `CONFIG_FLASH_APPLICATION_ADDRESS` khớp, `--app` không ra `APP_OFFSET_MISMATCH` (Octopus phải `APP_OFFSET_OK`), băm ghi vào `SHA256SUMS`, `MANIFEST_OK`, `gate.sh` thử khô ra rc 0. Thiếu một mục: không sang Phần B.

### 3.4 Thử công cụ phân tích dump TRƯỚC khi tin bảng quyết ở 4.2
Công cụ: `docs-internal\tools\dump-inspect.py` (Python 3 thuần, không thư viện ngoài). **[TRƯỞNG PHÒNG qua SSH]** hoặc người dùng chép nó vào `~/mcu-build/` trên Pi (tạo file mới; HOÀN TÁC: `rm ~/mcu-build/dump-inspect.py`) rồi chạy:
1. Tự kiểm: `python3 ~/mcu-build/dump-inspect.py --selftest`. Gồm 46 ca ảnh giả (lượt 5 thêm: ứng dụng liền mạch có chuỗi canboot ở đầu và vector giả ở ứng viên, bảng vector `0x0` trỏ vào vùng ứng dụng, thiếu khoảng FF sát trước ứng viên, ca biên đúng 16 byte FF) (app không bootloader nhỏ và lớn hơn 128 KiB, app lớn có vector giả ở `0x20000`/`0x2000` kể cả khi có khoảng FF 4 KiB sát trước và chuỗi klipper nằm sau ứng viên (a1, a2, b1, b2), bảng con trỏ giả, bootloader 128 KiB và 8 KiB cộng app, bootloader của hãng không chuỗi katapult có/không FF (c, d: ra `UNKNOWN`), bootloader hãng cộng app có vector hỏng (j), chỉ bootloader, toàn FF/00, rỗng, dump quá ngắn, app không chuỗi, chuỗi katapult nằm trong vùng app, chuỗi UTF-16, khối zlib nhận dạng thật/rác/không phải từ điển (e1 đến e3), gọi sai `--board` (f1 đến f4)) và 17 ca `--app` dựng giống bản build thật (RESET cách đầu ảnh ~31 KiB); khi có thư mục `fleet\reflash\2026-11-25\` cạnh công cụ (máy soạn) thì chạy thêm 10 phép `--app` trên bản build thật, trên Pi in "bo qua". Kỳ vọng: mọi dòng `OK`, cuối `TU KIEM: DAT`. Có `SAI`: không dùng bảng 4.2, báo checker.
2. `grep` và `--app` trên đúng các `.bin` vừa build cho hai bo (lệnh ở 3.1, "Kiểm offset của từng `.bin`"): `CONFIG_FLASH_APPLICATION_ADDRESS` khớp tên file; Octopus ra `APP_OFFSET_OK`; EBB ra `APP_OFFSET_OK` hoặc `APP_OFFSET_AMBIGUOUS`. Có `APP_OFFSET_MISMATCH` trên một bản build mà `.config` đúng: DỪNG và báo checker, KHÔNG tự sửa quy tắc.
3. (i) Chính các `.bin` vừa build: ảnh dump giả dựng từ chúng (chép `off0` vào đầu một ảnh 1 MiB toàn FF): kỳ vọng `NO_BOOTLOADER` nếu bản build có chuỗi klipper/kalico hoặc khối zlib nhận dạng; nếu không có thì `UNKNOWN` (xem 4.2, 8).
4. (ii) Ghép giả "bootloader + app 128 KiB": đệm 128 KiB có bảng vector hợp lệ (reset ~`0x08000201`) cộng chuỗi `Katapult`, nối `octopus_off128k` ở byte `0x20000`. Kỳ vọng `BOOTLOADER_128K` nếu bản build có chuỗi/khối zlib, nếu không thì `UNKNOWN`.
5. (iii) Ảnh toàn FF: kỳ vọng `EMPTY` (mã 3).
Kết quả đã chạy thật ở máy soạn (WSL `Ubuntu-24.04`, Python 3.12, vòng sửa lượt 5): `--selftest` 46 ca + 18 tổ hợp `--app` đạt, `TU KIEM: DAT`; bộ thử độc lập của test-engineer `tests\dump\t_harness.py` (21 ca dump, 16 ca `--app`, 6 ca lỗi đầu vào), `t_harness2.py` (20 ca dump; kỳ vọng ca `c`, `g_c` đã đổi sang `UNKNOWN` ở lượt 4) và `t_harness3.py` (14 ca) đều khớp kỳ vọng. Bằng chứng: `fleet\verify_002_dumpinspect.md` (do test-engineer) và đầu ra các lệnh chạy ở lượt 5. Chưa chạy trên Pi và chưa chạy trên dump hay `.bin` thật nào: làm bước 1 và 2 ở Phần A trên Pi, ghi kết quả vào sổ.
Kết quả việc 002:T025b (máy soạn, WSL): `--selftest` 46 ca dump + 17 ca `--app` + 10 phép `--app` trên bản build thật đạt; `t_harness.py`: 21 ca dump và 6 ca lỗi giữ nguyên, 7/16 ca `--app` dựng cũ đổi từ OK/MISMATCH sang `APP_OFFSET_AMBIGUOUS` (ảnh dựng dài 16 KiB/192 KiB phủ cả hai offset; đúng theo quy tắc mới); `t_harness2.py` mục (h): 2 ca RESET ở `lo+0x1000`/`lo+0x3000` (file 16 KiB) đổi MISMATCH thành OK do bỏ ngưỡng 0x1000; kết luận dump của mọi ảnh trong bốn harness không đổi.
Điểm dừng 3.4 (thuộc Điểm dừng 2(d)): bảng 4.2 chỉ được dùng khi bước 1 đạt `TU KIEM: DAT` và bước 2 đạt (grep khớp, không có `APP_OFFSET_MISMATCH`, Octopus `APP_OFFSET_OK`).

### 3.1b Hằng số MCU đang chạy, trích nguyên văn
Nguồn: `fleet\precheck\2026-11-24\V24\objects.json` và `...\TRI\objects.json` (khóa `mcu`, `mcu toolhead`; `mcu_constants`, `mcu_version`).

| Hằng số | V2.4 `mcu` | Trident `mcu` | V2.4 `mcu toolhead` | Trident `mcu toolhead` |
|---|---|---|---|---|
| `mcu_version` | `v2026.04.00-0-gab900a01` | `v0.13.0-787-ge2b99a91` | `v2026.04.00-0-gab900a01` | `v0.13.0-541-g187481e2` |
| `MCU` | `stm32h723xx` | `stm32h723xx` | `stm32g0b1xx` | `stm32g0b1xx` |
| `CLOCK_FREQ` | 520000000 | 520000000 | 64000000 | 64000000 |
| `CANBUS_BRIDGE` | 1 | 1 | (không có) | (không có) |
| `CANBUS_FREQUENCY` | (không có) | (không có) | 1000000 | 1000000 |
| `RESERVE_PINS_CAN` | `PD0,PD1` | `PD0,PD1` | `PB12,PB13` | `PB12,PB13` |
| `RESERVE_PINS_USB` | `PA11,PA12` | `PA11,PA12` | (không có) | (không có) |
| `RESERVE_PINS_crystal` | `PH0,PH1` | `PH0,PH1` | `PF0,PF1` | `PF0,PF1` |
| `PWM_MAX` | **256** | **32768** | **256** | **32768** |
| `STEPPER_OPTIMIZED_EDGE` | (không có) | (không có) | 8 | 8 |

Khác biệt V2.4 so với Trident (so từng khóa bằng PowerShell; chỉ các khóa này khác): `PWM_MAX` 256 (Kalico) so với 32768 (Klipper chính); Trident `mcu` có thêm `BUS_PINS_spi2b`; Trident `mcu toolhead` có thêm tên bus kiểu `spi1_PA6_PA7_PA5`, `spi1_PB4_PB5_PB3`, `spi2_PB14_PB15_PB13`, `spi2_PB6_PB7_PB8`, `spi2_PC2_PC3_PB10`, `spi3_PB4_PB5_PB3`, `spi3_PC11_PC12_PC10`. Cấu hình V2.4 dùng `spi_bus: spi2_PB2_PB11_PB10` (`V24\config\config\hardware\accelerometers\lis2dw_ebb_gen2.cfg:6`), tên này có ở cả hai máy. `mcu_build_versions` hai máy cùng ghi trình biên dịch `gcc: (15:14.2.rel1-1) 14.2.1 20241119 binutils: (2.44-3+23+b2) 2.44`. Cartographer hai máy giống nhau. Hằng số KHÔNG cho biết offset bootloader hay Katapult. `CLOCK_FREQ` là tần số SAU PLL nên KHÔNG chứng minh thạch anh 25 MHz hay 8 MHz.

### 3.2 Octopus MAX EZ

| Mục | Giá trị | Nguồn | Chắc chắn |
|---|---|---|---|
| Architecture / Processor | STM32 / STM32H723 | `MCU=stm32h723xx`; Trident giống | Cao |
| Bootloader offset | 128 KiB **hoặc** No bootloader (build cả hai, chọn ở 4.2) | Hãng: 128 KiB "khi có bootloader"; hằng số không cho biết | Chưa biết; dump quyết |
| Clock Reference | 25 MHz crystal | CHỈ hãng (cfg mẫu). `RESERVE_PINS_crystal=PH0,PH1` cho biết có dùng thạch anh ngoài, không cho biết tần số | Vừa (một nguồn) |
| Communication interface | USB to CAN bus bridge (PA11/PA12) | `CANBUS_BRIDGE=1`, `RESERVE_PINS_USB=PA11,PA12` (V2.4, Trident); hãng | Cao |
| CAN bus interface | CAN bus (PD0/PD1) | `RESERVE_PINS_CAN=PD0,PD1` (V2.4, Trident); hãng | Cao |
| CAN bus speed | 1000000 | `CANBUS_FREQUENCY` của EBB; `can0` bitrate 1000000 (`V24\system_info.json`, `canbus`); hãng. Cầu không báo hằng số này nên giá trị của chính Octopus là suy ra | Vừa đến cao |
| GPIO pins to set at startup | để trống | không có `INITIAL_PINS` ở `mcu` (cả hai máy) | Vừa |
| Tùy chọn khác | mặc định | | Vừa |

### 3.3 EBB36 CAN Gen2

| Mục | Giá trị | Nguồn | Chắc chắn |
|---|---|---|---|
| Architecture / Processor | STM32 / STM32G0B1 | `MCU=stm32g0b1xx`; wiki BTT | Cao |
| Bootloader offset | 8 KiB **hoặc** No bootloader (build cả hai, chọn ở 4.2/4.3) | Wiki BTT; README Katapult: offset Klipper phải khớp "Application start offset" | Chưa biết; dump hoặc Katapult quyết |
| Clock Reference | 8 MHz crystal | CHỈ wiki BTT. `RESERVE_PINS_crystal=PF0,PF1` cho biết có thạch anh | Vừa (một nguồn) |
| Communication interface | CAN bus (PB12/PB13) | `RESERVE_PINS_CAN=PB12,PB13` (V2.4, Trident); wiki Gen2 | Cao |
| CAN bus speed | 1000000 | `CANBUS_FREQUENCY=1000000` (V2.4, Trident) | Cao |
| GPIO at startup | để trống | không có `INITIAL_PINS` ở `mcu toolhead` | Vừa |

**Cách kiểm hai giá trị clock reference** (vì chỉ một nguồn):
1. `.config` cũ trên Pi nếu còn (S3): tìm `CONFIG_STM32_CLOCK_REF_*`.
2. Trident dùng cùng loại bo: nếu `.config` của Trident còn trên Pi của Trident, so (cần quyền vào Pi đó, việc riêng).
3. Sai clock lộ ra thế nào (suy ra, chưa kiểm chứng): Octopus sai clock thường không enumerate USB (mất `gs_usb`, bo "im lặng"); EBB sai clock không lên CAN (không xuất hiện trong `canbus_query`). Nếu lên mà lệch nhẹ, log `Stats` có tần số MCU ước lượng lệch xa `CLOCK_FREQ`. Hậu quả không vĩnh viễn: DFU/Katapult cứu được (6.1, 6.2).

Lưu ý: `V24\config\mcu.cfg:119` ghi "BTT EBB36 GEN2 v1.0". Build USB (PA11/PA12) chỉ dùng cứu DFU nếu cần.

---

# PHẦN B: BUỔI NẠP G2 (NGƯỜI DÙNG ĐỨNG CẠNH MÁY)

Ngân sách thời gian mục tiêu (nhánh E-A, O-B): chuẩn bị/an toàn 8 phút; dừng Klipper + dump 2 bo 12; quyết offset 3; nạp EBB 6; CP1 3; nạp Octopus 8; kiểm 10; tổng khoảng 50. Nhánh E-B thêm 15 đến 25. **Hết 90 phút kể từ lúc dừng Klipper: DỪNG (D6).**

## 4. NẠP

**Thứ tự: EBB36 trước, Octopus sau.** Lý do: EBB chỉ với tới qua cầu CAN; để Octopus (đang chạy, cầu quen thuộc) làm công cụ tới khi EBB xong. Đây là phán đoán, không có nguồn chính thức. EBB có nhiều ẩn số nhất (Katapult, nút DFU, vị trí vật lý) nên **tiêu chí chuyển nhánh** (không phải ép nạp):
- `-r` ra Katapult trong `-q` → E-A.
- `-r` thất bại, thử double-tap RESET (nếu có) vẫn không → E-B.
- E-B mà phải tháo đầu in/nắp để chạm bo: **DỪNG, hỏi người dùng** (D8). Người dùng không đồng ý → D4: không nạp bo nào.

### 4.0 An toàn nhiệt và nguồn (BẮT BUỘC trước MỌI lần vào DFU)
Trạng thái chân heater khi bo ở DFU chưa kiểm chứng (hãng cảnh báo chân hotend có thể bị kích ở EBB36 v1.1), và bàn Keenovo chạy qua SSR. Vì vậy:
1. **[TỰ ĐỘNG]** `GET /printer/objects/query?heater_bed&extruder&temperature_sensor`: nhiệt độ bàn và đầu phun đều dưới 40 °C (từ 40 °C trở lên: D5). **Ghi lại mọi cảm biến ngay lúc này làm MỐC TRƯỚC NẠP cho 5.2** (mốc ở 1.1 đã cũ nhiều ngày, chỉ để tham khảo).
2. **[NGƯỜI DÙNG]** Cắt nguồn bàn: cắt phía AC của Keenovo/SSR (rút phích hoặc công tắc riêng). Không có cách cắt riêng thì D5. Ngắt đầu nối heater đầu phun khỏi bo đang vào DFU (cartridge nối vào EBB; với Octopus chỉ cần ngắt đầu ra heater nếu có thể). Ghi sổ đã cắt.
3. **[NGƯỜI DÙNG]** Cách cấp nguồn cho bo khi vào DFU:
   - **EBB36**: chỉ USB 5V từ Pi. Rút đầu nối CAN VÀ nguồn 24V khỏi EBB (hãng cấm CAN và USB cùng lúc).
   - **Octopus**: thử cấp bằng USB từ Pi với 24V TẮT (bo sáng đèn thì dùng cách này; có sáng không là chưa kiểm chứng). Bo không lên bằng USB: bật 24V, nhưng chỉ khi bàn đã cắt AC (bước 2) và heater đã ngắt; người dùng đứng sát nút tắt nguồn.
4. Sau khi xong và trước khi bật lại bàn: chỉ nối lại nguồn bàn ở bước 5.3 (khi Klipper `ready`).
Điểm dừng 4.0: chỉ đi tiếp khi 1, 2 đã xác nhận bằng lời người dùng.

### 4.1 Dừng Klipper và dump firmware cũ (bắt buộc, gồm cả khi đã có `.config` cũ)
Bắt đầu đếm 90 phút.
1. **[TRƯỞNG PHÒNG qua SSH]** Ghi giờ rồi dừng: `date '+BAT DAU %F %T' ; date -d '+90 min' '+HET HAN %F %T'` (chép cả hai dòng vào sổ). Sau đó `sudo systemctl stop klipper` (hoặc `POST /machine/services/stop?service=klipper` [TỰ ĐỘNG]); `systemctl is-active klipper` phải `inactive`. HOÀN TÁC: `sudo systemctl start klipper`.
2. **[TRƯỞNG PHÒNG qua SSH]** CAN khi Klipper dừng (chỉ đọc): `<py> ~/katapult/scripts/flashtool.py -i can0 -q` và `<py> ~/klipper/scripts/canbus_query.py can0`. Ghi UUID thấy (đuôi 4 ký tự).
3. **Octopus vào DFU** (4.0 đã xong): **[NGƯỜI DÙNG]** giữ BOOT, nhấn rồi thả RESET (hoặc cấp nguồn khi giữ BOOT), thả BOOT. **[TRƯỞNG PHÒNG qua SSH]**:
   ```
   lsusb | grep -c 0483:df11                  # PHẢI ra đúng 1, khác: D2
   dfu-util -l                                # PHẢI chỉ một bo (một serial/path); ghi serial -> <dfu-serial>; dòng "Internal Flash" cho dung lượng, kỳ vọng H723 1 MiB (suy ra)
   dfu-util -d 0483:df11 -S <dfu-serial> -a 0 -s 0x08000000:0x100000 -U ~/mcu-build/OCTOPUS_dump_a.bin
   dfu-util -d 0483:df11 -S <dfu-serial> -a 0 -s 0x08000000:0x100000 -U ~/mcu-build/OCTOPUS_dump_b.bin
   sha256sum ~/mcu-build/OCTOPUS_dump_a.bin ~/mcu-build/OCTOPUS_dump_b.bin ; ls -l ~/mcu-build/OCTOPUS_dump_*.bin
   ```
   Điều kiện đi tiếp: kích thước đúng 1048576 byte, hai băng giống nhau, không phải toàn `ff`/`00`. Không thỏa: D3. (Đọc ngược có thể bị khóa RDP: chưa kiểm chứng; không thử phá khóa.) Tải dump về `fleet\backups\` kèm băm.
   Đây là thao tác chỉ đọc; thoát DFU: **[NGƯỜI DÙNG]** ngắt nguồn bo rồi cấp lại không giữ BOOT. Bo trở lại chạy Kalico.
   **Trở về trạng thái CAN đầy đủ trước khi làm EBB (nhánh E-A cần EBB có nguồn và CAN):** nếu 24V đã tắt ở 4.0 (Octopus chạy bằng USB), **[NGƯỜI DÙNG]** BẬT LẠI 24V (bàn vẫn cắt AC, heater đầu phun vẫn ngắt, đầu nối CAN của EBB cắm). **[TRƯỞNG PHÒNG qua SSH]** chờ `can0` lên: `ip -details link show can0` (state UP, 1000000) và `<py> ~/klipper/scripts/canbus_query.py can0` phải thấy `…233b`; chưa thấy sau 30 giây: kiểm nguồn/CAN, không đi tiếp.
4. **EBB**: dump bắt buộc nếu nhánh E-B hoặc khi cần xác định offset; nếu nhánh E-A đã chứng minh Katapult và đọc được "Application Start" (4.3) thì dump EBB là khuyến nghị: bỏ được CHỈ khi người dùng nói rõ chấp nhận đường lui bằng build lại, trưởng phòng ghi sổ. Cách dump: như bước 3 nhưng EBB theo 4.0 (CAN và 24V ngắt, USB), dung lượng kỳ vọng 512 KiB (suy ra): `-s 0x08000000:0x80000`, tên `EBB_dump_a/b.bin`. Hai bo KHÔNG vào DFU cùng lúc.

### 4.2 Quyết offset từ dump (không đoán)
Dùng công cụ `~/mcu-build/dump-inspect.py` (đã thử ở 3.4; Python 3 thuần, chỉ đọc) trên từng dump, KHÔNG phán đoán bằng mắt. Nguyên tắc của công cụ: thà `UNKNOWN` còn hơn đoán; mọi kết luận khác `UNKNOWN`/`EMPTY` đều in kèm danh sách bằng chứng, chép nguyên vào sổ.
```
python3 ~/mcu-build/dump-inspect.py --board octopus ~/mcu-build/OCTOPUS_dump_a.bin ; echo "rc=$?"
python3 ~/mcu-build/dump-inspect.py --board ebb36   ~/mcu-build/EBB_dump_a.bin ; echo "rc=$?"
```
`--board` chọn ứng viên offset (octopus: 128 KiB, cần dump từ 0x20010 byte; ebb36: 8 KiB, cần từ 0x2010 byte); dump ngắn hơn ra `UNKNOWN`. Mã thoát: 0 kết luận chắc, 2 `UNKNOWN`, 3 `EMPTY`, 1 dùng sai/không đọc được file. Bảng quyết (chỉ tin khi 3.4 đã đạt):

| `KET LUAN` (mã) | Nghĩa và điều kiện công cụ đã đòi | Build dùng, địa chỉ nạp DFU |
|---|---|---|
| `BOOTLOADER_128K` (0) | Vector hợp lệ ở `0x0` và chỉ ở một ứng viên `0x20000`; bootloader NHẬN DIỆN ĐƯỢC bằng chữ ký: chuỗi katapult/canboot trong khối bắt đầu từ 0 và nằm dưới `0x20000` (khoảng FF một mình KHÔNG đủ; bootloader của hãng không chuỗi ra `UNKNOWN`); RESET của `0x0` nằm dưới `0x20000`; `[0, 0x20000)` có dạng một ảnh bootloader độc lập: 16 mục đầu bảng vector `0x0` mục nào khác 0 (và khác `0xFFFFFFFF`) đều trỏ vào `[0x08000000, 0x08020000)`, và dữ liệu kết thúc trước ứng viên bằng một khoảng toàn FF sát ngay trước `0x20000` dài ≥ 4 KiB (ứng dụng liền mạch đi qua ứng viên ra `UNKNOWN`); có chuỗi klipper/kalico hoặc khối zlib nhận dạng ở vùng ≥ `0x20000` | `octopus_off128k`; `0x08020000` |
| `BOOTLOADER_8K` (0) | Như trên với `0x2000`; khoảng FF sát trước `0x2000` chỉ cần ≥ 16 byte (giả định "Katapult không lấp kín 8 KiB", chưa kiểm chứng, mục 8; Katapult thật lấp kín thì ra `UNKNOWN`, dùng "Application Start" ở 4.3) | `ebb_off8k`; `0x08002000` |
| `NO_BOOTLOADER` (0) | Vector hợp lệ ở `0x0`; KHÔNG có vector ứng dụng hợp lệ ở ứng viên, và 8 byte đầu tại MỌI ứng viên cũng không có dạng "SP trong RAM + RESET lẻ trong flash"; có chuỗi klipper/kalico hoặc khối zlib nhận dạng; KHÔNG có chuỗi katapult/canboot ở đâu cả; dữ liệu liên tục từ 0 tới byte không-FF cuối, không có khoảng FF ≥ 4 KiB ở giữa | `off0`; `0x08000000` |
| `BOOTLOADER_ONLY_NO_APP` (0) | Có bootloader, không có ứng dụng | D1 (không thể xảy ra khi bo đang chạy Kalico) |
| `EMPTY` (3) | Ảnh toàn FF/00 | D1 (dump hỏng, kiểm lại; D3) |
| `UNKNOWN` (2) | Không đủ căn cứ | **D1: KHÔNG nạp bo đó**, không đoán bằng `.config` |

Kết luận không khớp bo (ví dụ `BOOTLOADER_128K` cho EBB) cũng là D1.

**Mã thoát 0 KHÔNG đủ để nạp.** Script là một trong hai nguồn bằng chứng; mọi quy tắc nhận dạng đều có thể bị một ảnh bất thường đánh lừa, nên không bao giờ nạp chỉ dựa vào script. Trưởng phòng và người dùng cùng đọc dòng `KET LUAN` và danh sách bằng chứng (kèm offset), và kết luận của công cụ phải khớp với ít nhất một nguồn độc lập: offset trong `.config` cũ nếu còn (1.2), hoặc "Application Start" do Katapult tự báo (4.3). Không khớp, hoặc không có nguồn thứ hai: DỪNG (D1), không nạp bo đó. Ghi cả hai nguồn vào sổ.

Sau buổi: chép dump thật của hai bo (`OCTOPUS_dump_a.bin`, `EBB_dump_a.bin` từ `fleet\backups\`) vào `tests\dump\real\` làm dữ liệu thử về sau (file không chứa bí mật nhưng chứa firmware; để trong repo riêng tư được).

**Xử lý `UNKNOWN` (nói thẳng):**
- Octopus: chuỗi klipper/kalico có thể lấy từ chuỗi mô tả USB (UTF-16LE; công cụ tìm cả ASCII lẫn UTF-16LE); đây là suy ra, chưa kiểm trên dump thật.
- EBB36 chạy CAN, không có USB, nhiều khả năng bản build không chứa chuỗi nào, nên có thể LUÔN `UNKNOWN`. Công cụ quét thêm khối dữ liệu nhận dạng nén zlib của Klipper (suy ra Klipper nhúng từ điển zlib vào firmware; chưa kiểm trên bin thật). Còn `UNKNOWN`:
  - Nhánh E-A (có Katapult): offset lấy từ dòng "Application Start" mà Katapult tự khai (4.3 bước 2), đủ căn cứ; không cần dump làm căn cứ offset.
  - Nhánh E-B (không Katapult, chỉ DFU): **không có căn cứ để nạp EBB**. Phương án thay thế duy nhất đã dự trù: so dump với bản Kalico build lại ở Phần A: `cmp -n $(stat -c%s ~/mcu-build/kalico_ebb_off0.bin) ~/mcu-build/EBB_dump_a.bin ~/mcu-build/kalico_ebb_off0.bin` (offset 0) hoặc `cmp -i 8192:0 -n $(stat -c%s ~/mcu-build/kalico_ebb_off8k.bin) ~/mcu-build/EBB_dump_a.bin ~/mcu-build/kalico_ebb_off8k.bin` (offset 8 KiB); khớp hoàn toàn là bằng chứng mạnh, không khớp thì KHÔNG kết luận gì (build của tôi có thể khác byte so với bản đang chạy). Cũng không có thì đây là **điều kiện DỪNG D1: hỏi người dùng**, không nạp EBB (và theo D4 không nạp Octopus riêng).

`.config` cũ (nếu còn) chỉ để đối chiếu với kết luận, không thay dump. Địa chỉ nạp = `0x08000000` + offset (128 KiB = `0x20000`); suy ra, chưa có nguồn nói rõ cho Octopus MAX EZ.

### 4.3 EBB36 (`mcu toolhead`, `…233b`)

**Nhánh E-A: Katapult qua CAN (người dùng không phải chạm bo).**
1. **[TRƯỞNG PHÒNG qua SSH]** Yêu cầu bootloader rồi liệt kê:
   ```
   <py> ~/katapult/scripts/flashtool.py -i can0 -u <uuid-ebb> -r
   <py> ~/katapult/scripts/flashtool.py -i can0 -q
   ```
   Chỉ đi tiếp khi `-q` liệt kê `<uuid-ebb>` (đuôi `…233b`) ở Katapult. Chưa kiểm chứng: `-r` hoạt động khi node vẫn đang được phiên Klipper cũ gán, hay với firmware Kalico. Không ra: thử double-tap RESET (nếu có nút, chưa kiểm chứng ở Gen2), vẫn không thì E-B.
2. **BẮT BUỘC đọc "Application Start" mà Katapult báo lúc kết nối** (chạy `flashtool.py ... -f` hoặc đầu ra `-q`/`-v`; trích nguyên dòng vào sổ). Khớp: 0x08002000 → build `ebb_off8k`. Không khớp hoặc không in ra: DỪNG nạp EBB (D4 nếu không còn đường DFU).
3. Nạp qua cổng `gate.sh` (3.1): chọn biến thể theo TÊN; đường dẫn `.bin` lấy từ MANIFEST. Với EBB `--app` ra rc 5 `APP_OFFSET_AMBIGUOUS` là bình thường (ảnh không phân biệt được 0/8K); căn cứ là `.config` cộng băm trong manifest.
   ```
   VARIANT=                     # PHẢI điền: ebb36_off8k (Application Start 0x08002000). Rỗng thì cổng dừng
   OFF=                         # PHẢI điền: đúng địa chỉ "Application Start" vừa trích, ví dụ 0x08002000
   BIN=$(bash ~/reflash-work/gate.sh ebb36 "$VARIANT" "$OFF") && <py> ~/katapult/scripts/flashtool.py -i can0 -u <uuid-ebb> -f "$BIN"
   ```
   KHÔNG HOÀN TÁC TỰ ĐỘNG; đường lui = nạp lại `kalico_ebb_off8k.bin` (hoặc dump) bằng cùng lệnh sau `-r`. Offset không khớp Katapult là hỏng khởi động.
4. Kiểm: `<py> ~/klipper/scripts/canbus_query.py can0` thấy lại `…233b`, trong 30 giây; không: 6.1. (UUID suy từ ID chip nên thường giữ nguyên: suy ra; đổi thì DỪNG, ghi sổ.)

**Nhánh E-B: DFU qua USB** (bo trên đầu in; xem D8, 6.1). Thời gian 20 đến 30 phút.
1. **[NGƯỜI DÙNG]** Theo 4.0 (nguồn bàn cắt, CAN và 24V ngắt khỏi EBB), cắm cáp USB thứ hai tới Pi. Vào DFU (BOOT + cấp USB/RESET; không rõ vị trí nút Gen2, xem ảnh 1.1; không tìm được nút: DỪNG, không mò chân).
2. **[TRƯỞNG PHÒNG qua SSH]** Kiểm đúng một thiết bị: `lsusb | grep -c 0483:df11` = 1 (khác: D2), `dfu-util -l` một bo, dung lượng khớp 512 KiB (suy ra) để chắc đây là EBB chứ không phải Octopus.
3. Dump EBB (4.1 bước 4) rồi quyết offset (4.2, `--board ebb36`; có thể `UNKNOWN`, xem 4.2). Chỉ khi có kết luận rõ mới nạp. GHI TÊN BO TRÊN LỆNH và dùng `-S`. Điền `OFF` (để TRỐNG cho tới khi có kết luận; trống hoặc giá trị khác thì không nạp):
   ```
   VARIANT=                     # PHẢI điền: BOOTLOADER_8K -> ebb36_off8k (giữ Katapult, chỉ ghi ứng dụng) ; NO_BOOTLOADER -> ebb36_off0
   OFF=                         # PHẢI điền: BOOTLOADER_8K -> 0x08002000 ; NO_BOOTLOADER -> 0x08000000
   echo "VARIANT=$VARIANT OFF=$OFF"; grep "^$VARIANT " ~/reflash-work/MANIFEST     # đọc lại, khớp 4.2 rồi mới chạy dòng dưới
   BIN=$(bash ~/reflash-work/gate.sh ebb36 "$VARIANT" "$OFF") && dfu-util -d 0483:df11 -S <dfu-serial> -a 0 -s "$OFF:leave" -D "$BIN"
   ```
   (Cổng `gate.sh` (3.1) dừng khi biến thể không phải `ebb36_*`, `OFF` không khớp biến thể, thiếu dòng manifest, băm `.bin` khác manifest, `.config` không khớp, hoặc `--app` ra rc 4. Với EBB `--app` không phân biệt được 0/8K (rc 5 là bình thường), nên `.config` cộng băm trong manifest là căn cứ duy nhất của bản build.)
   Giữ offset đang chạy: KHÔNG ghi đè Katapult. Đường lui: nạp dump (`-s 0x08000000`) hoặc `kalico_ebb_*.bin` cùng offset.
4. **[NGƯỜI DÙNG]** Rút USB, nối lại CAN và 24V (bàn vẫn cắt). `canbus_query.py can0` phải thấy `…233b`.

**CP1 (khuyến nghị, 3 phút)**: bàn vẫn cắt. `sudo systemctl start klipper` (HOÀN TÁC: `stop`), `GET /printer/info` phải `ready` (heater đầu phun chưa nối thì Klipper có thể báo lỗi cảm biến/ADC: nối lại cartridge/thermistor theo trạng thái thường dùng trước, nhưng chưa bật nhiệt), `mcu toolhead` `mcu_version` `v0.13.0-822-g282db764`. Lỗi: không nạp Octopus, sang 6. Xong: `sudo systemctl stop klipper`.

### 4.4 Octopus MAX EZ (`mcu`, `…ee63`)
Thời gian 8 đến 15 phút. Khi nạp `can0` biến mất rồi trở lại: bình thường.

**Nhánh O-A: có Katapult** (chỉ khi dump/chuỗi Katapult ở 4.2 cho thấy):
1. **[TRƯỞNG PHÒNG qua SSH]** README Katapult: bo ở chế độ cầu không nạp qua CAN.
   ```
   ls -l /dev/serial/by-id/                          # ở chế độ cầu thường KHÔNG có serial (suy ra)
   <py> ~/katapult/scripts/flashtool.py -i can0 -u <uuid-octopus> -r      # yêu cầu qua CAN tới chính cầu: suy ra, chưa kiểm chứng
   ls -l /dev/serial/by-id/                          # phải thấy usb-katapult_stm32h723xx_...
   ```
   Hoặc nếu có serial của Klipper: `flashtool.py -r -d /dev/serial/by-id/<tên>` (README). 20 giây không thấy: sang O-B.
2. Đọc "Application Start" (như 4.3 bước 2; khớp 0x08020000 thì dùng `off128k`), rồi:
   ```
   VARIANT=                     # PHẢI điền: octopus_off128k (Application Start 0x08020000)
   OFF=                         # PHẢI điền: đúng địa chỉ "Application Start" vừa trích, ví dụ 0x08020000
   BIN=$(bash ~/reflash-work/gate.sh octopus "$VARIANT" "$OFF") && <py> ~/katapult/scripts/flashtool.py -d /dev/serial/by-id/<usb-katapult_...> -f "$BIN"
   ```
   Đường lui: nạp `kalico_octopus_off128k.bin` cùng lệnh.

**Nhánh O-B: DFU** (không Katapult, hoặc O-A thất bại):
1. **[NGƯỜI DÙNG]** Theo 4.0; vào DFU như 4.1 bước 3 (nhớ: EBB đã nối lại CAN, không ở DFU; chỉ một bo ở DFU).
2. **[TRƯỞNG PHÒNG qua SSH]** `lsusb | grep -c 0483:df11` = 1 (khác: D2); `dfu-util -l` một bo, flash 1 MiB; ghi serial. Điền `OFF` theo `KET LUAN` ở 4.2 (để TRỐNG cho tới khi có kết luận; trống hoặc giá trị khác thì không nạp):
   ```
   VARIANT=                     # PHẢI điền: BOOTLOADER_128K -> octopus_off128k ; NO_BOOTLOADER -> octopus_off0
   OFF=                         # PHẢI điền: BOOTLOADER_128K -> 0x08020000 ; NO_BOOTLOADER -> 0x08000000
   echo "VARIANT=$VARIANT OFF=$OFF"; grep "^$VARIANT " ~/reflash-work/MANIFEST     # trưởng phòng và người dùng cùng đọc lại, khớp 4.2 rồi mới chạy dòng dưới
   BIN=$(bash ~/reflash-work/gate.sh octopus "$VARIANT" "$OFF") && dfu-util -d 0483:df11 -S <dfu-serial> -a 0 -s "$OFF:leave" -D "$BIN"
   ```
   (Cổng `gate.sh` (3.1) dừng khi biến thể không phải `octopus_*`, `OFF` không khớp biến thể, thiếu dòng manifest, băm khác, `.config` không khớp, hoặc `--app` khác rc 0. Ảnh Octopus tách được 0/128K nên đòi đúng `APP_OFFSET_OK`.)
   Sai địa chỉ không làm hỏng ROM DFU (vào lại được) nhưng bo không chạy cho tới khi nạp lại. Đường lui: nạp `OCTOPUS_dump_a.bin` ở `0x08000000` (đúng byte) hoặc `kalico_octopus_*.bin` cùng offset. `make flash` không dùng (địa chỉ mặc định chưa kiểm với offset 128 KiB).
3. **[NGƯỜI DÙNG]** Ngắt nguồn bo rồi cấp lại không giữ BOOT; chờ 10 giây.
4. Thẻ SD của hãng (FAT32, `firmware.bin` ở gốc, thành `FIRMWARE.CUR`): chỉ nếu bo còn bootloader SD của hãng (chưa kiểm); không dùng trừ khi DFU hỏng.

Kiểm sau: `ip -details -statistics link show can0` có lại `can0` (1000000, qlen 128); `<py> ~/klipper/scripts/canbus_query.py can0` thấy `…233b`; Octopus là cầu nên có thể hiện hoặc không `…ee63` (ghi lại).

### 4.5 Khởi động lại
`sudo systemctl start klipper` (HOÀN TÁC: `stop`). Sang mục 5. Chỉ SAU khi Klipper `ready` mới nối lại nguồn bàn (5.3).

## 5. KIỂM SAU NẠP (dán đầu ra vào `fleet\verify_002_mcu.md`, T028)

**5.1 [TỰ ĐỘNG]** `GET /printer/info` `ready` (đợi tới 60 giây). `GET /printer/objects/query?mcu&mcu%20toolhead&mcu%20cartographer`: `mcu_version` của `mcu` và `mcu toolhead` bắt đầu `v0.13.0-822-g282db764` (Trident chạy MCU cũ hơn host mà vẫn ổn nên cùng dòng v0.13.0 là tối thiểu, 822 là đích); `mcu_constants` khớp cột Trident của 3.1b (`PWM_MAX`=32768); `mcu cartographer` `CARTOGRAPHER V3 6.1.0`.

**5.2 Cảm biến nhiệt (nguội, bàn vẫn cắt nguồn):** **[TỰ ĐỘNG]** `GET /printer/objects/query?heater_bed&extruder&temperature_sensor` so với MỐC ĐO LẠI Ở 4.0 bước 1 (cùng buổi, không dùng mốc 1.1 của nhiều ngày trước): mọi cảm biến (bàn, đầu in, MCU, EBB, buồng) trong khoảng ±3 °C so với mốc (ngưỡng chọn tạm, máy nguội nên phải gần nhiệt phòng; lệch lớn: dừng, kiểm dây). Không cảm biến nào báo `0`, `-273`, hoặc "ADC out of range".

**5.3 Heater có giám sát (PWM_MAX đổi 256 → 32768):** Chỉ làm khi 5.1, 5.2 đạt và Klipper `ready`.
1. **[NGƯỜI DÙNG]** Nối lại nguồn AC của bàn và đầu nối heater đầu phun, đứng sát nút tắt. Với `TARGET=0` cả hai, **[TỰ ĐỘNG]** thăm dò nhiệt bàn và đầu phun mỗi 5 giây trong 2 phút: không được tăng quá +2 °C so với lúc nối lại (heater/SSR không tự nóng). Tăng quá: người dùng cắt nguồn bàn NGAY, dừng.
2. Thử heater có cơ chế cắt tự động (PowerShell chạy trên máy dự án; `<pi>` là địa chỉ Pi). Hàm thăm dò mỗi 5 giây, thoát vòng khi nhiệt từ ngưỡng cắt trở lên hoặc hết giờ, và `try/finally` luôn gửi `TARGET=0` (kể cả khi vòng lặp hoặc `Invoke-RestMethod` lỗi, hoặc bấm Ctrl-C). Nếu mất kết nối tới Pi thì `TARGET=0` cũng không gửi được: người dùng cắt nguồn bàn ngay.
   ```
   function Test-Heater($name,$target,$limit,$seconds){
     $base="http://<pi>/printer"
     try {
       Invoke-RestMethod -Method Post "$base/gcode/script?script=SET_HEATER_TEMPERATURE%20HEATER=$name%20TARGET=$target" | Out-Null
       $end=(Get-Date).AddSeconds($seconds)
       while((Get-Date) -lt $end){
         $t=(Invoke-RestMethod "$base/objects/query?$name").result.status.$name.temperature
         "{0:HH:mm:ss} {1} {2}" -f (Get-Date),$name,$t
         if($t -ge $limit){ break }
         Start-Sleep 5
       }
     } finally {
       Invoke-RestMethod -Method Post "$base/gcode/script?script=SET_HEATER_TEMPERATURE%20HEATER=$name%20TARGET=0" | Out-Null   # HOÀN TÁC của lệnh gia nhiệt
     }
   }
   Test-Heater extruder   50 55 180      # đầu phun: mục tiêu 50, cắt từ 55 °C, tối đa 180 giây
   Test-Heater heater_bed 40 50 480      # bàn: mục tiêu 40, cắt từ 50 °C, tối đa 480 giây
   ```
   Đạt: nhiệt tăng đều đúng chiều, không dao động lạ, không lỗi nhiệt của Klipper, dưới ngưỡng cắt khi kết thúc. Bàn Keenovo có thể chưa tới 40 °C trong 5 phút: không phải lỗi, tiêu chí là nhiệt tăng đều, không cần đạt mục tiêu. Nhiệt không tăng sau 2 phút, tăng quá nhanh, hoặc Klipper báo lỗi nhiệt: dừng, người dùng cắt nguồn bàn. Không in, không đùn.

**5.4 CAN và log:** **[TRƯỞNG PHÒNG qua SSH]** `ip -details -statistics link show can0`: `qlen 128`, bitrate 1000000, lỗi/bus-off/restarts = 0. `last_stats` mỗi MCU `bytes_retransmit`, `bytes_invalid` (trước nạp đều 0 theo `SUMMARY.md`), theo dõi 10 phút. `grep -E 'shutdown|Timer too close|bytes_invalid|Lost communication' ~/printer_data/logs/klippy.log | tail` không dòng mới.

**5.5 Chuyển động, tăng dần** (người dùng cạnh máy, tay gần nút nguồn): **[TỰ ĐỘNG]** `QUERY_ENDSTOPS` (kết quả hợp lý, thử bấm tay endstop nếu cần); `STEPPER_BUZZ STEPPER=stepper_x`, `stepper_y`, `stepper_z` (dịch nhỏ, quan sát/nghe; tên stepper theo cấu hình, kiểm trước); `QUERY_PROBE`; quạt part/hotend ~30 % rồi tắt (PWM_MAX đổi). RỒI mới `G28`, `QUAD_GANTRY_LEVEL`. `ACCELEROMETER_QUERY` (tên chip theo cấu hình).

**5.6** Không `SAVE_CONFIG`, không đo cộng hưởng/PID ở buổi này. Đạt khi 5.1 đến 5.5 đạt; không đạt: mục 6.

---

## 6. ĐƯỜNG CỨU

Nguyên tắc: ROM DFU của STM32 không bị nạp ứng dụng xóa, nên bo còn cứu được nếu vào được DFU và với tới được (6.1). Dừng Klipper trước khi cứu (`sudo systemctl stop klipper`). Lệnh nạp luôn có `-S <dfu-serial>` và kiểm đúng một thiết bị DFU (D2). Nhắc lại: chỉ dump DFU thành công mới khôi phục đúng byte; còn lại là build lại.

### 6.1 EBB36 không còn trên CAN
**Cảnh báo trước buổi nạp**: cứu EBB bằng DFU phải chạm tới bo trên đầu in (có thể phải tháo nắp/đầu in), và cáp USB thứ hai có thể không đủ dài; kiểm trước (mục 0, 1.1). Nếu phải tháo đầu in: hỏi người dùng, không tự ý (D8).

| Dấu hiệu | Việc | Lệnh |
|---|---|---|
| `canbus_query` không thấy, `-q` thấy `…233b` ở Katapult | Nạp lại | `<py> ~/katapult/scripts/flashtool.py -i can0 -u <uuid-ebb> -f <.bin Kalico hoặc Klipper chính, offset khớp Application Start>` |
| Cả hai không thấy, `can0` còn, Octopus còn chạy | **[NGƯỜI DÙNG]** kiểm đầu nối lỏng, điện trở cuối 120 Ω; thử double-tap RESET (chưa kiểm ở Gen2); rồi `-q` | `<py> ... flashtool.py -i can0 -q` |
| Vẫn không | DFU (4.3 E-B) nạp dump hoặc `kalico_ebb_*` cùng offset | `dfu-util -d 0483:df11 -S <dfu-serial> -a 0 -s <đúng địa chỉ>:leave -D <file>` |
| Sau cứu vẫn không CAN | Nghi tốc độ CAN hoặc clock sai: so lại 3.3 và `.dict` (lệnh 3.1) | |
Hoàn tác mỗi lệnh: nạp lại bản trước.

### 6.2 Bo chính (Octopus) không lên
| Dấu hiệu | Việc |
|---|---|
| Không `1d50:606f`, không `0483:df11` | **[NGƯỜI DÙNG]** kiểm nguồn, cáp USB, cổng USB khác; vào DFU lại (4.4 O-B) |
| Vào được DFU | Nạp `OCTOPUS_dump_a.bin` ở `0x08000000` (đúng byte) hoặc `kalico_octopus_*` đúng offset; nghi đoán sai offset thì thử địa chỉ còn lại theo 4.2 |
| Không vào được DFU | Báo người dùng, dừng; không còn đường từ xa |

### 6.3 Klipper báo lệch phiên bản / "Unknown command" / shutdown khi khởi động
`grep -E 'Version|mismatch|Unknown|Protocol error' ~/printer_data/logs/klippy.log | tail -20` (chỉ đọc). Thường do MCU khác dòng host: nạp lại MCU đó từ build `282db764` (3.1), hoặc đưa MCU về Kalico (2.2) nếu cần máy chạy ngay. Không cập nhật host để khớp (mục 7).

### 6.4 Mất `can0`
| Việc | Lệnh | Hoàn tác |
|---|---|---|
| Xem | `ip -details link show can0` ; `lsusb` ; `dmesg \| tail -30` | |
| Octopus chưa thành cầu | 6.2 | |
| Cầu lên, `can0` down | `sudo ip link set can0 up type can bitrate 1000000` ; `sudo ip link set can0 txqueuelen 128` | `sudo ip link set can0 down` |
| Bitrate khác 1000000 | DỪNG; so lại 3.2 | |
Lệnh `ip link` là tạm thời nếu `can0` do file cấu hình mạng quản lý.

### 6.5 Hỏng không xác định
Dừng Klipper, ghi sổ, không thử thêm; để người dùng quyết quay về Kalico (2.2) hay sửa tiếp.

---

## 7. KHÔNG LÀM
- KHÔNG nạp Cartographer (đang có thông báo cập nhật chờ, `update_status.json`).
- KHÔNG cập nhật host Klipper (v0.14.0 chờ), Moonraker, plugin, `apt upgrade` (kernel/driver có thể ảnh hưởng `gs_usb`/`can0`); hiến pháp nguyên tắc V.
- KHÔNG `SAVE_CONFIG` (đang treo, `SUMMARY.md`); KHÔNG sửa `printer.cfg`/`mcu.cfg`.
- KHÔNG cắm CAN và USB cùng lúc vào EBB36; KHÔNG để hai bo vào DFU cùng lúc.
- KHÔNG chạy `flashtool.py -q`/`canbus_query.py` khi Klipper đang chạy.
- KHÔNG nạp hai bo cùng lúc; KHÔNG rút nguồn/USB khi đang nạp.
- KHÔNG ghi đè `~/klipper` hoặc `~/klipper/.config`; KHÔNG `make flash`.
- KHÔNG vào DFU khi chưa hoàn tất 4.0; KHÔNG đo (PROBE_ACCURACY, cộng hưởng, PID) trước khi mục 5 đạt.

## 8. CHƯA KIỂM CHỨNG (điều suy ra)
1. Offset bootloader của Octopus và EBB; địa chỉ `0x08020000`/`0x08002000`; `dump-inspect.py` (đã chạy trên ảnh giả ở máy soạn, WSL Python 3.12, xem 3.4; chưa chạy trên Pi, chưa thử trên dump hay `.bin` thật; phân loại là suy luận từ cấu trúc bảng vector; bản build CAN-only của EBB có thể không chứa chuỗi nào nên ra `UNKNOWN`).
2. EBB36 Gen2 có Katapult sẵn không; tùy chọn "8 KiB bootloader" có trong menuconfig G0B1 của bản 822 không (wiki BTT nêu, bản này chưa kiểm); `-r` có chạy khi node vừa được Klipper gán hoặc đang chạy Kalico; flashtool in "Application Start" thế nào.
3. Nút/cách vào DFU của EBB36 Gen2; vị trí nút BOOT Octopus; Octopus có lên bằng USB khi 24V tắt.
4. Octopus ở chế độ cầu: `-r` qua CAN tới chính cầu; không có `/dev/serial/by-id` ở chế độ cầu (suy từ `gs_usb`).
5. Dump DFU (`-U`) đọc được (RDP), kích thước flash H723 1 MiB, G0B1 512 KiB.
6. URL/tag Kalico (`github.com/KalicoCrew/kalico`, `v2026.04.00`); `KCONFIG_CONFIG=`; cấu trúc `klipper.dict`; thời gian build 2 đến 5 phút (ước).
7. Clock reference 25 MHz và 8 MHz chỉ dựa vào hãng; hậu quả sai clock (3.3) là suy ra.
8. Chân heater khi DFU (Octopus, EBB36 Gen2) vẫn chưa biết; tài liệu xử lý bằng cách cắt nguồn, không bằng kiểm chứng.
9. Python của Klipper (`~/klippy-env`) có `can`/`serial` (S9 sẽ cho biết).
10. `PWM_MAX` đổi không ảnh hưởng cấu hình quạt/heater (chưa soát hết cấu hình); ngưỡng ±3 °C và 55 °C ở 5.2/5.3 là chọn tạm; tên stepper cho `STEPPER_BUZZ`.
11. Không có nguồn về lưu ý riêng khi đưa MCU từ Kalico về Klipper chính, cũng không có thứ tự nạp chính thức.
12. `~/klipper`: `is_dirty` false, `pristine` false, 3 file untracked (`V24\update_status.json`, mục `klipper`, `anomalies`); chưa rõ có file đã theo dõi bị sửa không (S1 cho biết).
13. dump-inspect.py: ngưỡng --app 0x1000 [ĐÃ BỊ BẢN BUILD THẬT BÁC BỎ VÀ XÓA ở việc 002:T025b: RESET cách đầu ảnh ~0x7A00–0x7B00; quy tắc `--app` mới (mọi mục vector khác 0/`0xFFFFFFFF` nằm trong `[địa chỉ nạp, +kích thước file)`, 64 mục cho Octopus, 16 mục cho EBB) đã chạy trên 4 bản build 0.13.0-822 và `trident_out_klipper.bin`: Octopus tách được 0/128K, EBB không tách được 0/8K (AMBIGUOUS) nên với EBB `.config` là căn cứ duy nhất; chưa kiểm `--app` trên bản build Kalico (2.2)]; `--app` KHÔNG kiểm độ dài ảnh (ảnh cắt cụt sau RESET vẫn có thể ra OK): độ toàn vẹn của `.bin` dựa vào SHA256 trong `~/reflash-work/MANIFEST` và trong `~/mcu-build/SHA256SUMS` ghi từ `out/klipper.bin` ngay lúc build, cả hai do `gate.sh` kiểm (3.1); nếu `SHA256SUMS` bị lập lại từ file đã hỏng, hoặc chính `out/klipper.bin` đã hỏng, thì cắt cụt ở đuôi không còn gì bắt (literal VTOR, vector, SP đều nằm ở đầu file); luật literal VTOR của `gate.sh` chỉ đòi có một lệnh `LDR` PC-relative trỏ vào literal, chặn được literal ghép đuôi nhưng không chặn file bị sửa có chủ ý (chèn cả lệnh lẫn literal); manifest chỉ đúng nếu file được đặt đúng tên ngay khi build: file bị đổi tên hoặc đảo TRƯỚC khi lập manifest thì với EBB không gì bắt được ngoài `.config` đi cùng; các lệnh nạp đường lui (Kalico, dump, bảng 6) chưa đi qua `gate.sh`; quy tắc lượt 4 (bootloader chỉ được kết luận khi có chữ ký katapult/canboot, nên bootloader của hãng luôn ra `UNKNOWN`) chưa đối chiếu với bootloader thật của Octopus MAX EZ; quy tắc lượt 5 (bảng vector `0x0` chỉ trỏ vào `[0, ứng viên)`, khoảng FF sát trước ứng viên ≥ 4 KiB cho 128 KiB và ≥ 16 byte cho 8 KiB) dựa trên giả định Katapult 8 KiB không lấp kín 8 KiB và bootloader 128 KiB chừa ≥ 4 KiB FF ở cuối, chưa kiểm trên ảnh thật; ô vector chưa ghi (`0xFFFFFFFF`) được bỏ qua như ô 0; các mã thoát và quy tắc UNKNOWN/bằng chứng của chế độ dump đã chạy trên ảnh giả (WSL Python 3.12), chưa chạy trên dump thật nào; việc firmware Klipper nhúng từ điển nhận dạng zlib (commands, config) chỉ là suy ra; chưa chạy trên Pi (Python 3.13).
14. EBB36 ở nhánh E-B không có Katapult có thể không có căn cứ nạp (4.2): phụ thuộc kết quả so cmp với bản Kalico build lại, chưa thử.
