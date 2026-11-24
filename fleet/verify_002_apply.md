# verify_002_apply - kiem chung scripts\voron\apply-config.ps1 voi Moonraker gia (002:T035)

Lenh chay lai: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\apply-config.mock.ps1` (ma thoat 0 neu mọi ca dat; ghi tests\tmp\mock-run.md). Chi dung -BaseUrl http://127.0.0.1:<cong ngau nhien>; harness tu choi moi tham so chua 192.0.2.x.

## Ket qua (lan chay 2026-11-24 18:05, 17 ca con, 0 hong)

| Ca | Ket qua | Ma thoat | Yeu cau ghi |
|---|---|---|---|
| 1 printing (1b: trang thai la "weird") | DAT | 1 | 0 |
| 2 paused | DAT | 1 | 0 |
| 3 klippy startup / error / shutdown | DAT | 1 | 0 |
| 4 bam lech ExpectedSha256 | DAT | 1 | 0 |
| 5 -WhatIf | DAT | 0 | 0 |
| 6 thanh cong day du (6b: file trong thu muc con) | DAT | 0 | 3 (upload sao luu, upload moi, restart) |
| 7 upload file moi tra 500 | DAT | 1 | 2 (chi sao luu + lan 500), khong restart, co ROLLBACK |
| 8a printing sau cong dau | DAT | 1 | 0 |
| 8b printing sau sao luu, truoc ghi | DAT | 1 | 1 (chi ban sao luu), file dich nguyen ven |
| 9 khong bao gio ready, timeout 10s | DAT | 1 | 3, co ROLLBACK, khong in LEDGER |
| 10 -Restore tu sao luu ca 6 | DAT | 0 | 3, bam ttro ve bam goc |
| 11 RemotePath `..`, tuyet doi, `\`, `%2e%2e`, thu muc, `-x` | DAT (8/8 bi tu choi, 0 yeu cau) | 1 | 0 |
| 12 BaseUrl 127.0.0.2, localhost, https, co duong dan, thieu cong, ftp | DAT (7/7, 0 yeu cau) | 1 | 0 |

## Chung minh test bat duoc loi (ban sao co y lam hong, chay bang -ScriptPath)
| Ban sao hong | Ca bi bat |
|---|---|
| M1 bo kiem printing/paused/la | 1, 1b, 2, 8a, 8b (script ghi 3 yeu cau) |
| M2 bo cong bam | 4 |
| M3 noi long regex BaseUrl | 12 |
| M4 bo kiem `..` | 11 |
| M5 bo cong rảnh o buoc 4 | 8b |
| M6 bo kiem klippy ready | 3-startup, 3-error, 3-shutdown |
Chua chung minh bang ban sao hong: ca 5, 6, 6b, 7, 9, 10.

## Phat hien
- Nghiem trong: khong co. Quan trong: khong co.
- Nho 1: apply-config.ps1:136 thong bao "curl upload failed (exit 22) for /overrides.cfg" co dau `/` thua khi SubDir rong (ca 7).
- Nho 2: apply-config.ps1:59 tu choi nham ten hop le `a..b.cfg`; chap nhan `a/./b.cfg` va `a//b.cfg` (chi gui GET, khong ghi duoc vi file phai ton tai; khong thoat khoi root).
- Nho 3: ca 9 va moi loi: file moi da nam tren may khi het thoi gian cho (dung nhu thiet ke, co lenh ROLLBACK).

## Khong kiem duoc voi may gia (can may that)
Dinh dang multipart/truong `path`,`checksum` cua Moonraker that; thoi diem Klipper that sap ket noi khi firmware_restart; chuoi trang thai that cua print_stats; ma thoat cua curl.exe tren may khac; nhanh Wait-Ready khi klippy ve `error` sau restart (khong co ca rieng); don dep ban sao luu tren may that.

# Nhat ky chay day du
# apply-config mock run
script: D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1
run: 2026-11-24 18:05:29   cases: 17   failed: 0

### Case 1 - print_stats.state = printing -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c1`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: [step 1] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
```

### Case 1b - print_stats.state = weird (unknown) -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c1b`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'weird' (unknown) - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
```

### Case 2 - print_stats.state = paused -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c2`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
ERROR: [step 1] print_stats.state is 'paused' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
```

### Case 3-startup - klippy state = startup -> refuse - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3startup`
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

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3error`
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

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c3shutdown`
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

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff -Reason mocktest-c4`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: hash mismatch on machine for config/overrides.cfg: machine=1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 expected=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
```

### Case 5 - -WhatIf on idle machine, hash matches -> only GETs, steps and rollback printed - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c5 -WhatIf`
Exit code: 0   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
WHATIF target=http://127.0.0.1:51159 machine=MOCK file=config/overrides.cfg (read-only gates passed, no write sent)
  step 3: backup on machine -> config/backups/2026-11-24_mocktest-c5/overrides.cfg ; local -> D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c5\MOCK\overrides.cfg
  step 4: upload D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg (17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7) to config/overrides.cfg, download and compare
  step 5: POST /printer/firmware_restart, wait ready up to 120s
  rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c5\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c5
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
```

### Case 6 - full success path: backup first, write second, restart last, ledger line - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c6`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | machine:config/backups/2026-11-24_mocktest-c6/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c6
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c6/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c6/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 10 - -Restore from the backup of case 6 puts original hash back on the machine - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6\MOCK\overrides.cfg -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason mocktest-c10`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/overrides.cfg | 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 | 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 | machine:config/backups/2026-11-24_mocktest-c10/overrides.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c10\MOCK\overrides.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c10\MOCK\overrides.cfg" -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Restore -Reason rollback-mocktest-c10
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c10/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c10/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 6b - success with RemotePath in a sub-directory (macros/m.cfg) - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath macros/m.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_m.cfg -ExpectedSha256 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 -Reason mocktest-c6b`
Exit code: 0   write requests (non-GET) seen by mock: 3   seconds: 6.5
Output:
```
LEDGER | 2026-11-24 | MOCK | config/macros/m.cfg | 074c37ac62ebc2aeba81263be57188c08698b994c960e1658229232cf9e39891 | c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 | machine:config/backups/2026-11-24_mocktest-c6b/macros/m.cfg local:D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6b\MOCK\macros\m.cfg | rollback: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath macros/m.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c6b\MOCK\macros\m.cfg" -ExpectedSha256 c015aa31bdb96a3f0d672a76a9f19cf3615677e0c82a55178c50d523e67cf2a8 -Restore -Reason rollback-mocktest-c6b
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/macros/m.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c6b/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c6b/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/macros/m.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
```

### Case 7 - upload of the new file returns 500 -> error, no restart, rollback command - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c7`
Exit code: 1   write requests (non-GET) seen by mock: 2   seconds: 0.4
Output:
```
powershell.exe : curl: (22) The requested URL returned error: 500
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (curl: (22) The ...rned error: 500:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
ERROR: curl upload failed (exit 22) for /overrides.cfg
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c7\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c7
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c7/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c7/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
```

### Case 8a - machine turns printing right after the first gate -> no write at all - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c8a`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: [step 3] print_stats.state is 'printing' - refusing, nothing written
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c8a/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
```

### Case 8b - machine turns printing after the backup, before the new file -> new file not written - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c8b`
Exit code: 1   write requests (non-GET) seen by mock: 1   seconds: 0.4
Output:
```
ERROR: [step 4] print_stats.state is 'printing' - refusing, nothing written
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c8b\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c8b
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c8b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c8b/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
```
Note: one write (the backup copy under backups/) is expected here; the config file itself is untouched

### Case 9 - after firmware_restart the machine never returns to ready, -RestartTimeoutSec 10 - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c9 -RestartTimeoutSec 10`
Exit code: 1   write requests (non-GET) seen by mock: 3   seconds: 12.5
Output:
```
ERROR: klippy not ready within 10s
ROLLBACK: powershell -NoProfile -File "D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1" -BaseUrl http://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile "D:\WORK\3D-Printer-Klipper\fleet\backups\2026-11-24_mocktest-c9\MOCK\overrides.cfg" -ExpectedSha256 17d471f85d688b03279168395e900f2bf4bd583274cf738626240268b6377df7 -Restore -Reason rollback-mocktest-c9
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/overrides.cfg
GET /server/files/config/backups/2026-11-24_mocktest-c9/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/backups/2026-11-24_mocktest-c9/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /server/files/upload
GET /server/files/config/overrides.cfg
GET /printer/info
GET /printer/objects/query?print_stats=state
POST /printer/firmware_restart
GET /printer/info
GET /printer/info
GET /printer/info
GET /printer/info
```
Note: file on machine was already replaced (hash = new): True

### Case 11 - -RemotePath with .. or absolute path - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath ../x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': ../x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus... '..': ../x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus... '..': ../x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': ../x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath /etc/passwd -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': /etc/passwd
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus....': /etc/passwd:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus....': /etc/passwd:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': /etc/passwd
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath C:\x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': C:\x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus... '..': C:\x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus... '..': C:\x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': C:\x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath a/../b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': a/../b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus.....': a/../b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus.....': a/../b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': a/../b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath ..\x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': ..\x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus... '..': ..\x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus... '..': ..\x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': ..\x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath %2e%2e/x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': %2e%2e/x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...': %2e%2e/x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...': %2e%2e/x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': %2e%2e/x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath macros/ -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': macros/
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...o '..': macros/:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...o '..': macros/:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': macros/
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath -x.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.3
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': -x.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...no '..': -x.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...no '..': -x.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': -x.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath a/./b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: config/a/./b.cfg does not exist on the machine - refusing (this script only replaces existing files)
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/a/b.cfg
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath a//b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.4
Output:
```
ERROR: config/a//b.cfg does not exist on the machine - refusing (this script only replaces existing files)
```
Requests received by mock:
```
GET /printer/info
GET /printer/objects/query?print_stats=state
GET /server/files/config/a//b.cfg
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath a..b.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': a..b.cfg
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus... '..': a..b.cfg:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus... '..': a..b.cfg:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': a..b.cfg
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159 -RemotePath x.cfg?y=1 -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c11`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -RemotePath must be a relative path inside the config root, no '..': x.cfg?y=1
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-RemotePath mus...'..': x.cfg?y=1:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:60 char:5
+     throw "-RemotePath must be a relative path inside the config root ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-RemotePath mus...'..': x.cfg?y=1:String) [], RuntimeException
    + FullyQualifiedErrorId : -RemotePath must be a relative path inside the config root, no '..': x.cfg?y=1
```
Requests received by mock:
```
(none)
```
Note: RemotePath 'a/./b.cfg' -> exit 1, writes 0, requests: GET /printer/info ; GET /printer/objects/query?print_stats=state ; GET /server/files/config/a/b.cfg
Note: RemotePath 'a//b.cfg' -> exit 1, writes 0, requests: GET /printer/info ; GET /printer/objects/query?print_stats=state ; GET /server/files/config/a//b.cfg
Note: RemotePath 'a..b.cfg' -> exit 1, writes 0, requests: 
Note: RemotePath 'x.cfg?y=1' -> exit 1, writes 0, requests: 

### Case 12 - -BaseUrl not http://127.0.0.1:<port> -> rejected - PASS

Command: `apply-config.ps1 -BaseUrl http://127.0.0.2:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://localhost:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl https://127.0.0.1:51159 -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159/x -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

Command: `apply-config.ps1 -BaseUrl http://127.0.0.1:51159/ -RemotePath overrides.cfg -LocalFile D:\WORK\3D-Printer-Klipper\tests\tmp\new_overrides.cfg -ExpectedSha256 1c108d3b15a5e9cbbddc648903f49745f24ab53c6228d50ade7136002b675bd5 -Reason mocktest-c12`
Exit code: 1   write requests (non-GET) seen by mock: 0   seconds: 0.2
Output:
```
powershell.exe : -BaseUrl must look like http://127.0.0.1:<port>
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
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
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
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
At D:\WORK\3D-Printer-Klipper\tests\apply-config.mock.ps1:163 char:10
+     $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S ...
+          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (-BaseUrl must l...27.0.0.1:<port>:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
At D:\WORK\3D-Printer-Klipper\scripts\voron\apply-config.ps1:41 char:63
+ ... d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" } ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (-BaseUrl must l...27.0.0.1:<port>:String) [], RuntimeException
    + FullyQualifiedErrorId : -BaseUrl must look like http://127.0.0.1:<port>
```
Requests received by mock:
```
(none)
```

