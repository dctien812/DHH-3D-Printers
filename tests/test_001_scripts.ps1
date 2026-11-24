# test_001_scripts.ps1 - offline checks for spec 001 scripts. Touches NO printer and NO network.
# Usage: powershell -NoProfile -File tests\test_001_scripts.ps1 [-SkipRunBambuRead]
param([switch]$SkipRunBambuRead)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('t001_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory $tmp | Out-Null
$script:fail = 0
function Check($name, $ok) { if ($ok) { "PASS $name" } else { "FAIL $name"; $script:fail++ } }
function RunPs($file, [string[]]$a) { (& powershell -NoProfile -File $file @a 2>&1 | Out-String) }

# (a) syntax
foreach ($f in 'scripts\fleet\inventory.ps1', 'scripts\fleet\snapshot-voron.ps1', 'scripts\fleet\bambu-read.ps1', 'scripts\lib\BambuMqtt.psm1', 'scripts\lib\Fleet.psm1') {
    $e = $null; $t = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root $f), [ref]$t, [ref]$e)
    Check "parse $f" (@($e).Count -eq 0)
}

Import-Module (Join-Path $root 'scripts\lib\BambuMqtt.psm1') -Force
Import-Module (Join-Path $root 'scripts\lib\Fleet.psm1') -Force

# (b) MQTT codec
foreach ($n in 0, 127, 128, 16383, 16384, 2097151, 2097152, 268435455) {
    $e = ConvertTo-MqttRemainingLength -Length $n
    $d = ConvertFrom-MqttRemainingLength -Bytes $e
    Check "remaining length $n" ($d.Value -eq $n -and $d.Size -eq $e.Length)
}
$c = New-MqttConnectPacket -ClientId 'abc' -UserName 'bblp' -Password 'pw123456' -KeepAliveSec 60
$exp = [byte[]](0x10, 0x1F, 0, 4, 0x4D, 0x51, 0x54, 0x54, 4, 0xC2, 0, 60, 0, 3, 0x61, 0x62, 0x63, 0, 4, 0x62, 0x62, 0x6C, 0x70, 0, 8) + [Text.Encoding]::ASCII.GetBytes('pw123456')
Check 'CONNECT bytes' (($c -join ',') -eq ($exp -join ','))
$s = New-MqttSubscribePacket -PacketId 1 -Topic 'device/X/report'
Check 'SUBSCRIBE bytes' (($s -join ',') -eq (([byte[]](0x82, 20, 0, 1, 0, 15) + [Text.Encoding]::ASCII.GetBytes('device/X/report') + [byte[]](0)) -join ','))
foreach ($len in 10, 200, 20000, 300000) {
    $payload = '{"print":{"x":"' + ('a' * $len) + '"}}'
    $pkt = New-MqttPublishPacket -Topic 'device/SER/report' -Payload $payload
    $buf = New-Object 'System.Collections.Generic.List[byte]'
    $half = [int]($pkt.Length / 2)
    $buf.AddRange([byte[]]$pkt[0..($half - 1)])
    $first = Get-MqttPacketFromBuffer -Buffer $buf
    $buf.AddRange([byte[]]$pkt[$half..($pkt.Length - 1)])
    $p = Get-MqttPacketFromBuffer -Buffer $buf
    $dec = ConvertFrom-MqttPublish -Packet $p
    Check "PUBLISH round trip payload=$($payload.Length)" ($null -eq $first -and $dec.Topic -eq 'device/SER/report' -and [Text.Encoding]::UTF8.GetString($dec.Payload) -eq $payload -and $buf.Count -eq 0)
}
# declared length 268 MB (0x30 FF FF FF 7F) must be refused, 1 MB boundary allowed
$big = New-Object 'System.Collections.Generic.List[byte]'; $big.AddRange([byte[]](0x30, 0xFF, 0xFF, 0xFF, 0x7F))
$threw = $false; try { Get-MqttPacketFromBuffer -Buffer $big | Out-Null } catch { $threw = $true }
Check 'packet declaring 268 MB is refused' $threw
$ok1 = New-Object 'System.Collections.Generic.List[byte]'; $ok1.AddRange([byte[]](0x30, 0x80, 0x80, 0x40)) # 1 048 576
$threw2 = $false; try { Get-MqttPacketFromBuffer -Buffer $ok1 | Out-Null } catch { $threw2 = $true }
Check 'packet declaring exactly 1 MB not refused (just incomplete)' (-not $threw2)

# (b) secret filter with allow-list
$serial = '01P00A381700123'
$json = @"
{"print":{"command":"push_status","sn":"$serial","gcode_file":"secret model.3mf","file":"f.gcode","job_name":"my job","subtask_name":"s","subtask_id":"1","project_id":"2","task_id":"3","profile_id":"4",
"hw_sn":"HWSN1234567890","module_sn":"MODSN1234567890AB","rfid":"R1","unknown_block":{"a":1},"gcode_state":"RUNNING",
"nozzle_temper":210.5,"mc_percent":42,"hms":[{"attr":1,"code":2}],"print_error":0,"nozzle_diameter":"0.4","ip":"192.0.2.199","rtsp_url":"rtsp://192.0.2.199/x",
"upgrade_state":{"status":"IDLE","note":"unit $($serial.ToLower()) here"},
"ams":{"ams":[{"id":"0","humidity":"3","sn":"AMSSN123456789","tray":[{"id":"0","tag_uid":"AABBCCDD11223344","tray_uuid":"0123456789ABCDEF0123456789ABCDEF","tray_type":"PLA","tray_color":"FF0000FF"}]}]}},
"info":{"command":"get_version","module":[{"name":"ota","sw_ver":"01.10.00.00","hw_ver":"OTA","sn":"$serial","product_name":"X"}]}}
"@
$o = $json | ConvertFrom-Json
$stats = @{ Rule = 0; Unknown = 0 }
$res = [ordered]@{
    print = Select-BambuReport -Print $o.print -SecretStrings @($serial, 'ACCESS99', '192.0.2.199') -Stats $stats
    info  = Select-BambuInfo -Info $o.info -SecretStrings @($serial) -Stats $stats
}
$out = $res | ConvertTo-Json -Depth 20
foreach ($bad in $serial, $serial.ToLower(), 'tag_uid', 'tray_uuid', 'gcode_file', '"file"', 'job_name', 'subtask', 'project_id', 'task_id', 'profile_id', 'hw_sn', 'module_sn', 'HWSN1234', 'MODSN1234', 'AMSSN', 'rfid', '"sn"', '"ip"', 'rtsp', '192.0.2.199', 'secret model', 'AABBCCDD', 'unknown_block', 'product_name') {
    Check "filter removed '$bad'" ($out.IndexOf($bad, [StringComparison]::OrdinalIgnoreCase) -lt 0)
}
foreach ($keep in 'nozzle_temper', '210.5', 'mc_percent', 'gcode_state', '"hms"', 'print_error', 'nozzle_diameter', 'humidity', 'tray_type', 'PLA', 'tray_color', '01.10.00.00', '"name"', '"ota"', 'IDLE') {
    Check "filter kept '$keep'" ($out.IndexOf($keep) -ge 0)
}
Check "filter counted unknown keys ($($stats.Unknown)) and rule keys ($($stats.Rule))" ($stats.Unknown -ge 3 -and $stats.Rule -ge 8)

# Fleet.psm1: path allow-list and SSDP source check (module-private functions)
$fm = Get-Module Fleet
$allowed = '/printer/info', '/printer/objects/query?toolhead', '/server/files/list?root=config', '/server/files/config/printer.cfg', '/server/gcode_store', '/machine/system_info', '/machine/proc_stats', '/machine/update/status', '/server/history/list?limit=5'
$denied = '/printer/info/../../printer/gcode/script', '/printer/gcode/script', '/printer/info/x', '/server/files/config/../x', '/server/files/%2e%2e/x', '/printer/emergency_stop', '/machine/reboot', '/server/files/config/a\b'
foreach ($p in $allowed) { Check "path allowed $p" (& $fm { param($x) Test-MoonrakerPathAllowed $x } $p) }
foreach ($p in $denied) { Check "path denied $p" (-not (& $fm { param($x) Test-MoonrakerPathAllowed $x } $p)) }
$threwRel = $false; try { Get-MoonrakerFiles -Ip '203.0.113.1' -RelPath '../secret' } catch { $threwRel = $true }
Check 'RelPath with .. refused before any request' $threwRel
$spoof = [pscustomobject]@{ Model = 'X'; Name = 'n'; Ip = '192.0.2.61' }
Check 'SSDP Location == sender accepted' (& $fm { param($p, $s) Test-SsdpSource -Parsed $p -SenderIp $s } $spoof '192.0.2.61')
Check 'SSDP Location != sender rejected' (-not (& $fm { param($p, $s) Test-SsdpSource -Parsed $p -SenderIp $s } $spoof '192.0.2.77'))

if (-not $SkipRunBambuRead) {
# bambu-read.ps1: invalid secrets JSON must not echo the value; empty secrets -> "chua dien"
$bad = Join-Path $tmp 'bad.json'
'{"H2S":{"ip":"1.2.3.4","access_code":ab12cd34,"serial":"x"}}' | Set-Content -LiteralPath $bad
$o1 = RunPs (Join-Path $root 'scripts\fleet\bambu-read.ps1') @('-SecretsFile', $bad, '-Machine', 'H2S')
Check 'invalid JSON: fixed message' ($o1 -match 'không phải JSON hợp lệ')
Check 'invalid JSON: value not echoed' ($o1 -notmatch 'ab12cd34')
$emptyF = Join-Path $tmp 'empty.json'
$empty = @{}; foreach ($m in 'H2S', 'P1S', 'A1', 'A1M') { $empty[$m] = @{ ip = ''; access_code = ''; serial = '' } }
($empty | ConvertTo-Json) | Set-Content -LiteralPath $emptyF
$o2 = RunPs (Join-Path $root 'scripts\fleet\bambu-read.ps1') @('-SecretsFile', $emptyF)
Check 'empty secrets: 4 machines reported chua dien' ((@([regex]::Matches($o2, 'chua dien')).Count) -eq 4)
Check 'empty secrets: no pin file created' (-not (Test-Path (Join-Path $tmp 'bambu.certs.local.json')))

}

# inventory.ps1 offline: formula injection from SSDP name
$ssdp = Join-Path $tmp 'ssdp.txt'
"NOTIFY * HTTP/1.1`r`nLocation: 192.0.2.61`r`nDevModel.bambu.com: O1S`r`nDevName.bambu.com: =HYPERLINK(""http://x"",""y"")`r`nDevVersion.bambu.com: +1`r`nDevConnect.bambu.com: cloud" | Set-Content -LiteralPath $ssdp
$outDir = Join-Path $tmp 'out'
RunPs (Join-Path $root 'scripts\fleet\inventory.ps1') @('-SsdpSampleFile', $ssdp, '-OutDir', $outDir) | Out-Null
$rows = Import-Csv (Join-Path $outDir 'inventory.csv') -Encoding UTF8
Check 'inventory: 6 rows' ($rows.Count -eq 6)
$h = $rows | Where-Object id -eq 'H2S'
Check 'inventory: name starting with = is prefixed with apostrophe' ($h.'tên'.StartsWith("'="))
Check 'inventory: no cell starts with = + - @' (-not ($rows | ForEach-Object { $_.PSObject.Properties.Value } | Where-Object { $_ -match '^[=+\-@]' }))

# snapshot-voron.ps1: Hide-ConfigSecrets (extracted from the script, not executed as a whole)
$sv = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'scripts\fleet\snapshot-voron.ps1'), [ref]$null, [ref]$null)
$fn = $sv.Find({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq 'Hide-ConfigSecrets' }, $true)
Invoke-Expression $fn.Extent.Text
$cfg = Join-Path $tmp 'x.conf'
[IO.File]::WriteAllText($cfg, "[notifier a]`r`nurl: tgram://x`r`napi_key: SECRETVALUE1`r`n[b]`r`nPassword = hunter2`r`nmax_velocity: 300`r`n", (New-Object Text.UTF8Encoding($false)))
$n = Hide-ConfigSecrets $cfg
$txt = [IO.File]::ReadAllText($cfg)
Check 'config masking: 2 values masked' ($n -eq 2)
Check 'config masking: secrets gone, other lines intact' ($txt -notmatch 'SECRETVALUE1|hunter2' -and $txt -match 'max_velocity: 300' -and $txt -match 'api_key: \*\*\*')

# (c) forbidden patterns
$hits = Select-String -Path (Join-Path $root 'scripts\fleet\inventory.ps1'), (Join-Path $root 'scripts\fleet\snapshot-voron.ps1'), (Join-Path $root 'scripts\fleet\bambu-read.ps1'), (Join-Path $root 'scripts\lib\BambuMqtt.psm1'), (Join-Path $root 'scripts\lib\Fleet.psm1') -Pattern '-Method\s+(Post|Put|Delete)|gcode/script'
Check 'no Post/Put/Delete or gcode/script in code' (@($hits | Where-Object { $_.Line -notmatch '^\s*#' }).Count -eq 0)
$pubCalls = @(Select-String -Path (Join-Path $root 'scripts\fleet\bambu-read.ps1') -Pattern 'New-MqttPublishPacket')
Check 'bambu-read: exactly one New-MqttPublishPacket' ($pubCalls.Count -eq 1)

Remove-Item -LiteralPath $tmp -Recurse -Force
"FAILURES: $script:fail"
exit $script:fail
