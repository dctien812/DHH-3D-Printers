# verify_002_apply - kiem chung scripts\voron\apply-config.ps1 voi Moonraker gia (002:T035)

Lenh chay lai: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\apply-config.mock.ps1` (ma thoat 0 neu moi ca dat; nhat ky o tests\tmp\mock-run.md). Chi dung -BaseUrl http://127.0.0.1:<cong ngau nhien>; harness tu choi moi tham so/lenh chua 192.0.2.x. Chay lai tren ban sao hong: them `-ScriptPath <ban sao> -ReportPath <file>`.

## Luot 1 (ca 1-12, tren ban script ban dau): 17 ca con, 0 hong (2026-11-24 18:05)
Ca 1,1b,2,3 (startup/error/shutdown),4,5,6,6b,7,8a,8b,9,10,11,12 deu DAT; ban hong M1..M6 (bo kiem printing, cong bam, regex BaseUrl, kiem `..`, cong ranh buoc 4, kiem klippy ready) deu bi bat. Luu y: sau sua luot 1 cac ca 11 va 12 van dat; 'a..b.cfg' nay duoc chap nhan (xem ca 18).

## Luot 2 (script sau sua, 36 ca con, 0 hong)

| Ca | Ket qua | Ma thoat | Yeu cau ghi |
|---|---|---|---|
| 13 -Restore khi klippy error / shutdown (13c startup van bi tu choi) | DAT | 0 / 0 (13c: 1) | 3 / 3 (13c: 0) |
| 14 -Restore khi printing / paused / error+printing | DAT | 1 | 0 |
| 15 file bi doi giua buoc 2 va 4 | DAT | 1 | 1 (chi ban sao luu), file dich khong bi ghi |
| 16a save_config_pending khong co | DAT | 1 | 0 |
| 16b co -DiscardPendingSaveConfig | DAT | 0 | 3 |
| 16c -Restore + pending, khong co | DAT | 1 | 0 |
| 17 extruder 245 / heater_bed 85 / idle_timeout Printing | DAT | 1 | 0 |
| 17d -Restore khi extruder 245 | ghi nhan: duoc phep (mien cong nhiet) | 0 | 3 |
| 18 allow-list: 10 duong dan bi tu choi (0 yeu cau); a..b.cfg va moonraker.conf+co duoc ghi | DAT | 1 / 0 | 0 / 2 |
| 19 restart roi klippy -> error; chay dung dong ROLLBACK | DAT | 1 roi 0 | 3 + 3, bam ve ban dau |
| 20a may khong tra configfile/target/idle_timeout | ghi nhan: script cho qua va ghi | 0 | 3 |
| 20b khong tra ca print_stats / 20c query tra 500 | DAT (tu choi) | 1 | 0 |

## Chung minh bo thu bat duoc loi (ban sao hong, 7 ban, moi ban bi it nhat 1 ca bat)
| Ban hong | Ca bi bat |
|---|---|
| N1 bo cong save_config | 16a, 16c |
| N2 bo cong nhiet va idle_timeout | 17a, 17b, 17c |
| N3 bo so bam lai truoc buoc 4 | 15 |
| N4 bo ngoai le -Restore khi error | 13-error, 13-shutdown, 14c |
| N5 bo cam backups/ | 18 |
| N6 bo co -AllowMoonrakerConf | 18 |
| N7 bo kiem printing/paused | 14c |

## Phat hien (luot 2)
- Nghiem trong: khong co. Tinh huong checker neu (restart roi klippy error) da duoc xu ly: ca 19 dong ROLLBACK chay dung va khoi phuc.
- Quan trong: apply-config.ps1:118-134 (+111) - truong vang bi coi la "khong co" va cho qua (ca 20a): neu Moonraker khong tra `configfile.save_config_pending` thi cong save_config bi vo hieu ma khong canh bao. De xuat: khi klippy ready ma thieu `configfile.save_config_pending` thi tu choi; thieu `extruder`/`heater_bed` thi cho qua (may khong co loai do).
- Nho: apply-config.ps1:237 va :230 - ca 15 van in dong ROLLBACK du file dich chua bi ghi (chay no se bi cong bam chan, vo hai nhung gay hieu nham).
- Nho: apply-config.ps1:127 - -Restore mien cong nhiet (17d), restart se tat lo suoi; co the la y dinh.

## Khong kiem duoc voi may gia
Dinh dang that cua /printer/objects/query khi klippy error (gia lap bang 503), multipart/checksum cua Moonraker that, thoi gian restart that, chuoi trang thai that cua idle_timeout.

# Nhat ky chay day du (luot 2)
# apply-config mock run
script: D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1
run: 2026-11-24 21:47:35   cases: 36   failed: 0

### Case 1 - print_stats.state = printing -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c1`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: [step 1] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 1b - print_stats.state = weird (unknown) -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c1b`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'weird' (unknown) - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 2 - print_stats.state = paused -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c2`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'paused' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 3-startup - klippy state = startup -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3startup`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] klippy state is 'startup', not ready - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
```

### Case 3-error - klippy state = error -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3error`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] klippy state is 'error', not ready - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
```

### Case 3-shutdown - klippy state = shutdown -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3shutdown`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] klippy state is 'shutdown', not ready - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
```

### Case 4 - machine idle but hash on machine differs from -ExpectedSha256 -> stop - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff -Reason mocktest-c4`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: hash mismatch on machine for config/overrides.cfg: machine=1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 expected=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
```

### Case 5 - -WhatIf on idle machine, hash matches -> only GETs, steps and rollback printed - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c5 -WhatIf`
Exit code: 0   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
WHATIF target=http://127.0.0.1:49736 machine=MOCK file=config/overrides.cfg (read-only gates passed, no write sent)
  step 3: backup on machine -> config/backups/2026-11-24_mocktest-c5/overrides.cfg ; local -> D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c5\MOCK\overrides.cfg
  step 4: upload D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg (17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7) to config/overrides.cfg, download and compare
  step 5: POST /printer/firmware_restart, wait ready up to 120s
  rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c5\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c5
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
```

### Case 6 - full success path: backup first, write second, restart last, ledger line - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c6`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | machine:config/backups/2026-11-24_mocktest-c6/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c6
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c6/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c6/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 10 - -Restore from the backup of case 6 puts original hash back on the machine - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c10`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_mocktest-c10/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c10\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c10\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-mocktest-c10
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c10/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c10/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 6b - success with RemotePath in a sub-directory (macros/m.cfg) - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath macros/m.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c6b`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/macros/m.cfg | 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 | c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 | machine:config/backups/2026-11-24_mocktest-c6b/macros/m.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6b\MOCK\macros\m.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath macros/m.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6b\MOCK\macros\m.cfg" -ExpectedSha256 c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 -Restore -Reason rollback-mocktest-c6b
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/macros/m.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c6b/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c6b/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/macros/m.cfg
POST /server/files/upload
GET /server/files/config/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 7 - upload of the new file returns 500 -> error, no restart, rollback command - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c7`
Exit code: 1   write requests (non-GET) seen by mock: 2   seconds: 0.5
Output:
```
powershell.exe : curl: (22) The requested URL returned error: 500
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (curl: (22) The ...rned error: 500:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
ERROR: curl upload failed (exit 22) for overrides.cfg
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c7\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c7
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c7/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c7/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
```

### Case 8a - machine turns printing right after the first gate -> no write at all - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c8a`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: [step 3] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c8a/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 8b - machine turns printing after the backup, before the new file -> new file not written - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c8b`
Exit code: 1   write requests (non-GET) seen by mock: 1   seconds: 0.4
Output:
```
ERROR: [step 4] print_stats.state is 'printing' - refusing, nothing written
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c8b\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c8b
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c8b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c8b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```
Note: one write (the backup copy under backups/) is expected here; the config file itself is untouched

### Case 9 - after firmware_restart the machine never returns to ready, -RestartTimeoutSec 10 - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c9 -RestartTimeoutSec 10`
Exit code: 1   write requests (non-GET) seen by mock: 3   seconds: 12.5
Output:
```
ERROR: klippy not ready within 10s
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c9\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c9
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c9/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c9/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
GET /printer/info
GET /printer/info
```
Note: file on machine was already replaced (hash = new): True

### Case 11 - -RemotePath with .. or absolute path - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath ../x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): ../x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ups/): ../x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ups/): ../x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): ../x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath /etc/passwd -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): /etc/passwd
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus.../): /etc/passwd:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus.../): /etc/passwd:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): /etc/passwd
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath C:\x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): C:\x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ups/): C:\x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ups/): C:\x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): C:\x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a/../b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): a/../b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...s/): a/../b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...s/): a/../b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): a/../b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath ..\x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): ..\x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ups/): ..\x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ups/): ..\x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): ..\x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath %2e%2e/x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): %2e%2e/x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...): %2e%2e/x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...): %2e%2e/x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): %2e%2e/x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath macros/ -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): macros/
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...kups/): macros/:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...kups/): macros/:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): macros/
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath -x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): -x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ckups/): -x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ckups/): -x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): -x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a/./b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): a/./b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ps/): a/./b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ps/): a/./b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): a/./b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a//b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): a//b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ups/): a//b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ups/): a//b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): a//b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a..b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: hash mismatch on machine for config/a..b.cfg: machine=074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 expected=1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 - nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/a..b.cfg
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath x.cfg?y=1 -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): x.cfg?y=1
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ps/): x.cfg?y=1:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ps/): x.cfg?y=1:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): x.cfg?y=1
```
Requests received by mock:
```
(none)
```
Note: RemotePath 'a/./b.cfg' -> exit 1, writes 0, requests: 
Note: RemotePath 'a//b.cfg' -> exit 1, writes 0, requests: 
Note: RemotePath 'a..b.cfg' -> exit 1, writes 0, requests: GET /printer/info ; GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state ; GET /server/files/config/a..b.cfg
Note: RemotePath 'x.cfg?y=1' -> exit 1, writes 0, requests: 

### Case 12 - -BaseUrl not http://127.0.0.1:<port> -> rejected - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.2:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://localhost:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl https://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736/x -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736/ -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl ftp://127.0.0.1:21 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:43 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

### Case 13-error - -Restore while klippy = error -> allowed, original hash back, restart, ready - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c13error`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_mocktest-c13error/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c13error\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c13error\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-mocktest-c13error
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c13error/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c13error/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```
Note: mock answered the print_stats query with 503 while klippy was down: True

### Case 13-shutdown - -Restore while klippy = shutdown -> allowed, original hash back, restart, ready - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c13shutdown`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_mocktest-c13shutdown/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c13shutdown\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c13shutdown\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-mocktest-c13shutdown
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c13shutdown/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c13shutdown/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```
Note: mock answered the print_stats query with 503 while klippy was down: False

### Case 13c - -Restore while klippy = startup -> still refused - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c13c`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] klippy state is 'startup', not ready - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
```

### Case 14 - -Restore while print_stats = printing (klippy ready) -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c14`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 14b - -Restore while print_stats = paused -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c14b`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'paused' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 14c - -Restore with klippy = error but print_stats still answers printing -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c14c`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 15 - file on machine edited after the hash gate (during backup) -> target never written, backup kept - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c15`
Exit code: 1   write requests (non-GET) seen by mock: 1   seconds: 0.5
Output:
```
ERROR: file on machine changed since the hash gate (edited elsewhere?) - new file not written; backup kept at config/backups/2026-11-24_mocktest-c15/overrides.cfg
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c15\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c15
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c15/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c15/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
```

### Case 16a - configfile.save_config_pending = true, no flag -> refuse before any write - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c16a`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] a save-config change is pending; a restart will lose it - nothing written. Use -DiscardPendingSaveConfig to accept
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 16b - save_config_pending = true with -DiscardPendingSaveConfig -> runs - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c16b -DiscardPendingSaveConfig`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | machine:config/backups/2026-11-24_mocktest-c16b/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c16b\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c16b\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c16b
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c16b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c16b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 16c - -Restore with klippy ready and save_config_pending = true, no flag -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c16c`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] a save-config change is pending; a restart will lose it - nothing written. Use -DiscardPendingSaveConfig to accept
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 17a - extruder.target = 245 -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c17a`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: [step 1] extruder target is 245 - the machine is being heated, refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 17b - heater_bed.target = 85 -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c17b`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] heater_bed target is 85 - the machine is being heated, refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 17c - idle_timeout.state = Printing -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c17c`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] idle_timeout is Printing - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 17d - info: -Restore with extruder.target = 245 is exempt from the heater gate (design) - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\orig_overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c17d`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_mocktest-c17d/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c17d\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c17d\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-mocktest-c17d
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c17d/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c17d/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```
Note: documents behavior: -Restore proceeds (and restarts) while a heater target is set

### Case 18 - -RemotePath allow-list - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath backups/x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): backups/x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...: backups/x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...: backups/x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): backups/x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath backups/2026-01-01_x/overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): 
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...der backups/): :String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
backups/2026-01-01_x/overrides.cfg
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...x/overrides.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): backups/2026-01-01_x/overrides.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a//b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): a//b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ups/): a//b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ups/): a//b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): a//b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath ./a.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): ./a.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...kups/): ./a.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...kups/): ./a.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): ./a.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath x.txt -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): x.txt
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ackups/): x.txt:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ackups/): x.txt:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): x.txt
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath x.cfg.bak -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): x.cfg.bak
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...ps/): x.cfg.bak:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...ps/): x.cfg.bak:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): x.cfg.bak
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath dir.d/x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under 
backups/): dir.d/x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus.../): dir.d/x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:63 char:5
+     throw "-RemotePath must be a relative path to a .cfg or .conf fil ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus.../): dir.d/x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path to a .cfg or .conf file inside the config root (not  
   under backups/): dir.d/x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath moonraker.conf -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : writing moonraker.conf needs -AllowMoonrakerConf
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (writing moonrak...owMoonrakerConf:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:66 char:5
+     throw "writing moonraker.conf needs -AllowMoonrakerConf"
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (writing moonrak...owMoonrakerConf:String) [], RuntimeException
    + FullyQualifiedErrorId : writing moonraker.conf needs -AllowMoonrakerConf
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath sub/moonraker.conf -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : writing moonraker.conf needs -AllowMoonrakerConf
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (writing moonrak...owMoonrakerConf:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:66 char:5
+     throw "writing moonraker.conf needs -AllowMoonrakerConf"
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (writing moonrak...owMoonrakerConf:String) [], RuntimeException
    + FullyQualifiedErrorId : writing moonraker.conf needs -AllowMoonrakerConf
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath MOONRAKER.CONF -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : writing moonraker.conf needs -AllowMoonrakerConf
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:184 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (writing moonrak...owMoonrakerConf:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:66 char:5
+     throw "writing moonraker.conf needs -AllowMoonrakerConf"
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (writing moonrak...owMoonrakerConf:String) [], RuntimeException
    + FullyQualifiedErrorId : writing moonraker.conf needs -AllowMoonrakerConf
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath a..b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18p1 -NoRestart`
Exit code: 0   write requests (non-GET) seen by mock: 2   seconds: 0.5
Output:
```
NOTE: -NoRestart, Klipper still runs the old config
LEDGER | 2026-11-24 | MOCK | config/a..b.cfg | 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 | c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 | machine:config/backups/2026-11-24_mocktest-c18p1/a..b.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c18p1\MOCK\a..b.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath a..b.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c18p1\MOCK\a..b.cfg" -ExpectedSha256 c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 -Restore -Reason rollback-mocktest-c18p1
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/a..b.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c18p1/a..b.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c18p1/a..b.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/a..b.cfg
POST /server/files/upload
GET /server/files/config/a..b.cfg
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath moonraker.conf -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c18p2 -AllowMoonrakerConf -NoRestart`
Exit code: 0   write requests (non-GET) seen by mock: 2   seconds: 0.5
Output:
```
NOTE: -NoRestart, Klipper still runs the old config
LEDGER | 2026-11-24 | MOCK | config/moonraker.conf | 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 | c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 | machine:config/backups/2026-11-24_mocktest-c18p2/moonraker.conf local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c18p2\MOCK\moonraker.conf | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath moonraker.conf -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c18p2\MOCK\moonraker.conf" -ExpectedSha256 c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 -Restore -Reason rollback-mocktest-c18p2
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/moonraker.conf
GET /server/files/config/backups/2026-11-24_mocktest-c18p2/moonraker.conf
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c18p2/moonraker.conf
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/moonraker.conf
POST /server/files/upload
GET /server/files/config/moonraker.conf
```

### Case 19 - after firmware_restart klippy goes to error -> error + rollback; running that exact rollback line succeeds - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c19`
Exit code: 1   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
ERROR: klippy went to 'error': mock error
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c19\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c19
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c19/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c19/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

Command: `apply-config.ps1 (rollback line as printed by the script) powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c19\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c19`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_rollback-mocktest-c19/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_rollback-mocktest-c19\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_rollback-mocktest-c19\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-rollback-mocktest-c19
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_rollback-mocktest-c19/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_rollback-mocktest-c19/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 20a - machine omits configfile/extruder/heater_bed/idle_timeout (print_stats present) -> behavior recorded - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c20a`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | machine:config/backups/2026-11-24_mocktest-c20a/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c20a\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c20a\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c20a
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c20a/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c20a/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
GET /server/files/config/overrides.cfg
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```
Note: script treats missing save_config_pending and heater targets as absent and writes; see report for recommendation

### Case 20b - machine omits print_stats too (empty status) -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c20b`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: The property 'print_stats' cannot be found on this object. Verify that the property exists.
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

### Case 20c - objects/query answers HTTP 500 while klippy ready -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:49736 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c20c`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: Cannot get /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state from Moonraker at http://127.0.0.1:49736: The remote server returned an error: (500) Internal Server Error.
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state
```

