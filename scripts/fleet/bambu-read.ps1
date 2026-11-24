# bambu-read.ps1 - read Bambu Lab printer status over MQTT/TLS (port 8883), spec 001 T009.
# Default: CONNECT + SUBSCRIBE device/<serial>/report only; NO PUBLISH is sent.
# Only with -AllowPushAll: exactly one PUBLISH, the fixed "pushall" status request, logged to publish.log.
# Secrets (access code, serial) come from secrets\bambu.local.json and are never printed or written
# outside secrets\. status.json is filtered before writing. Read-only for the printer.
[CmdletBinding()]
param(
    [ValidateSet('H2S', 'P1S', 'A1', 'A1M')][string[]]$Machine = @('H2S', 'P1S', 'A1', 'A1M'),
    [ValidateRange(5, 300)][int]$Seconds = 20,
    [switch]$AllowPushAll,
    [string]$Date = (Get-Date -Format 'yyyy-MM-dd'),
    [string]$SecretsFile,
    [switch]$RepinCert
)
$ErrorActionPreference = 'Stop'
if ($RepinCert -and @($Machine).Count -ne 1) { throw '-RepinCert chi dung voi dung mot -Machine (vi du -Machine H2S -RepinCert).' }
if ($RepinCert -and -not $PSBoundParameters.ContainsKey('Machine')) { throw '-RepinCert can chi ro -Machine.' }
Import-Module (Join-Path $PSScriptRoot '..\lib\BambuMqtt.psm1') -Force

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $SecretsFile) { $SecretsFile = Join-Path $root 'secrets\bambu.local.json' }

# The only message this script may ever publish (status request, not a control command).
$PushAllPayload = '{"pushing":{"sequence_id":"0","command":"pushall"}}'

# Certificate fingerprints (SHA-256) pinned on first contact, next to the secrets file.
$PinFile = Join-Path (Split-Path -Parent $SecretsFile) 'bambu.certs.local.json'

function Get-Pins {
    $pins = [ordered]@{}
    if (Test-Path -LiteralPath $PinFile) {
        try {
            $o = Get-Content -LiteralPath $PinFile -Raw | ConvertFrom-Json
            foreach ($p in $o.PSObject.Properties) { $pins[$p.Name] = [string]$p.Value }
        } catch { throw 'file ghim chung chi khong phai JSON hop le' }
    }
    $pins
}

function Get-SecretField($cfg, [string]$id, [string]$field) {
    $m = $cfg.PSObject.Properties[$id]
    if ($null -eq $m) { return '' }
    $f = $m.Value.PSObject.Properties[$field]
    if ($null -eq $f -or $null -eq $f.Value) { return '' }
    ([string]$f.Value).Trim()
}

function Read-OneBambu([string]$id, $cfg) {
    $ip = Get-SecretField $cfg $id 'ip'
    $code = Get-SecretField $cfg $id 'access_code'
    $serial = Get-SecretField $cfg $id 'serial'
    $missing = @()
    if (-not $ip) { $missing += 'ip' }
    if (-not $code) { $missing += 'access_code' }
    if (-not $serial) { $missing += 'serial' }
    if ($missing.Count -gt 0) {
        "{0}: chua dien ({1}) - bo qua" -f $id, ($missing -join ', ')
        return
    }
    $secrets = @($code, $serial, $ip)
    $outDir = Join-Path $root "fleet\baseline\$Date\$id"
    $topicReport = "device/$serial/report"
    $session = $null
    try {
        $session = Open-BambuMqtt -Ip $ip
        "{0}: TLS ok, cert SHA-256 {1} (tu ky, chap nhan)" -f $id, $session.CertSha256
        # Pin check BEFORE CONNECT: the access code is only ever sent to a certificate already pinned.
        $pins = Get-Pins
        $known = if ($pins.Contains($id)) { $pins[$id] } else { $null }
        if ($known -and $known -ne $session.CertSha256 -and -not $RepinCert) {
            "{0}: DUNG - chung chi khac chung chi da ghim (co the do cap nhat firmware, hoac day khong phai may that). Chua gui ma truy cap. Neu da xac nhan dung may, chay lai voi -RepinCert." -f $id
            return
        }
        if ($known -ne $session.CertSha256) {
            $pins[$id] = $session.CertSha256
            [System.IO.File]::WriteAllText($PinFile, ($pins | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
            if ($known) { "{0}: da ghim lai chung chi" -f $id } else { "{0}: lan dau: da ghim chung chi cua {0}" -f $id }
        }
        $clientId = 'fleet-read-' + ([guid]::NewGuid().ToString('N').Substring(0, 8))
        Send-MqttBytes -Session $session -Bytes (New-MqttConnectPacket -ClientId $clientId -UserName 'bblp' -Password $code)
        $ack = Read-MqttPacketTimed -Session $session -TimeoutMs 10000
        if ($null -eq $ack -or $ack.Type -ne 2 -or $ack.Body.Length -lt 2) { throw 'Khong nhan duoc CONNACK.' }
        if ($ack.Body[1] -ne 0) { throw ("May tu choi ket noi MQTT (ma tra ve {0}; 4/5 = sai ten/ma hoac khong duoc phep)." -f $ack.Body[1]) }
        Send-MqttBytes -Session $session -Bytes (New-MqttSubscribePacket -PacketId 1 -Topic $topicReport)

        $print = [ordered]@{}
        $info = $null
        $msgs = 0
        $pushed = $false
        $lastPing = Get-Date
        $end = (Get-Date).AddSeconds($Seconds)
        while ((Get-Date) -lt $end) {
            $left = [int][math]::Max(100, ($end - (Get-Date)).TotalMilliseconds)
            $pkt = Read-MqttPacketTimed -Session $session -TimeoutMs ([math]::Min($left, 1000))
            if (((Get-Date) - $lastPing).TotalSeconds -ge 30) {
                Send-MqttBytes -Session $session -Bytes ([byte[]](0xC0, 0x00))   # PINGREQ (keep-alive, not a PUBLISH)
                $lastPing = Get-Date
            }
            if ($null -eq $pkt) { continue }
            if ($pkt.Type -eq 9) {                                  # SUBACK
                if ($pkt.Body.Length -ge 3 -and $pkt.Body[2] -eq 0x80) { throw 'May tu choi SUBSCRIBE topic report.' }
                if ($AllowPushAll -and -not $pushed) {
                    $pushed = $true
                    $logLine = "{0}`t{1}`t{2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $id, 'pushall'
                    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
                    # log first: if the log cannot be written, nothing is sent
                    [System.IO.File]::AppendAllText((Join-Path $outDir 'publish.log'), $logLine + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
                    Send-MqttBytes -Session $session -Bytes (New-MqttPublishPacket -Topic "device/$serial/request" -Payload $PushAllPayload)
                }
                continue
            }
            if ($pkt.Type -ne 3) { continue }                       # only PUBLISH from the printer matters
            $pub = ConvertFrom-MqttPublish -Packet $pkt
            if ($pub.Topic -ne $topicReport) { continue }
            try { $j = [System.Text.Encoding]::UTF8.GetString($pub.Payload) | ConvertFrom-Json } catch { continue }
            $msgs++
            $jp = $j.PSObject.Properties
            if ($jp['print'] -and $jp['print'].Value -is [pscustomobject]) {
                foreach ($p in $jp['print'].Value.PSObject.Properties) { $print[$p.Name] = $p.Value }
            }
            if ($jp['info'] -and $jp['info'].Value -is [pscustomobject]) { $info = $jp['info'].Value }
        }
        try { Send-MqttBytes -Session $session -Bytes ([byte[]](0xE0, 0x00)) } catch { }   # DISCONNECT

        if ($print.Count -eq 0) {
            "{0}: chua du - nhan {1} goi, khong co khoi print{2}" -f $id, $msgs, $(if ($AllowPushAll) { '' } else { ' (che do chi-subscribe; can -AllowPushAll neu duoc phep)' })
            return
        }
        $stats = @{ Rule = 0; Unknown = 0 }
        $result = [ordered]@{
            _meta = [ordered]@{
                machine = $id; read_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); source = 'MQTT 8883 report'
                mode = $(if ($AllowPushAll) { 'subscribe+pushall' } else { 'subscribe-only' })
                messages = $msgs; cert_sha256 = $session.CertSha256
            }
            print = (Select-BambuReport -Print ([pscustomobject]$print) -SecretStrings $secrets -Stats $stats)
        }
        if ($info) { $result['info'] = Select-BambuInfo -Info $info -SecretStrings $secrets -Stats $stats }
        $result._meta['dropped_unknown_keys'] = $stats.Unknown
        $result._meta['dropped_secret_rule_keys'] = $stats.Rule
        "{0}: bo {1} khoa khong nam trong danh sach cho phep, {2} khoa theo luat bi mat" -f $id, $stats.Unknown, $stats.Rule
        $text = $result | ConvertTo-Json -Depth 20
        foreach ($s in $secrets) { if ($text.IndexOf($s, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw 'Bi mat con sot lai sau khi loc - khong ghi file.' } }
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        $name = 'status.json'
        if (Test-Path -LiteralPath (Join-Path $outDir $name)) { $name = 'status_{0}.json' -f (Get-Date -Format 'HHmmss') }
        [System.IO.File]::WriteAllText((Join-Path $outDir $name), $text, (New-Object System.Text.UTF8Encoding($false)))
        "{0}: da ghi {1} ({2} goi, {3} truong print, che do {4})" -f $id, (Join-Path $outDir $name), $msgs, $print.Count, $result._meta.mode
    } catch {
        "{0}: loi - {1}" -f $id, (Protect-SecretText -Text $_.Exception.Message -Secrets $secrets)
    } finally {
        if ($session) { Close-BambuMqtt -Session $session }
    }
}

if (-not (Test-Path -LiteralPath $SecretsFile)) { throw "Khong thay file bi mat: $SecretsFile" }
# Parse errors from ConvertFrom-Json echo the offending text (it may be the access code): fixed message only.
try { $cfg = Get-Content -LiteralPath $SecretsFile -Raw | ConvertFrom-Json }
catch { throw 'file bí mật không phải JSON hợp lệ' }
foreach ($id in $Machine) { Read-OneBambu $id $cfg }
