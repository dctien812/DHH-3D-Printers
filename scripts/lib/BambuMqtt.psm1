# BambuMqtt.psm1 - minimal MQTT 3.1.1 client over TLS (.NET only) + secret filter for Bambu reports (spec 001).
# Rules: this module never decides WHAT to publish; New-MqttPublishPacket only encodes bytes.
# The single caller that may send a PUBLISH is scripts\fleet\bambu-read.ps1, behind -AllowPushAll.
# Nothing here prints the access code or serial. PowerShell 5.1. File saved as UTF-8 with BOM.

Set-StrictMode -Version 2.0

# ---------- pure encoding / decoding (testable without a printer) ----------

function ConvertTo-MqttRemainingLength {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateRange(0, 268435455)][int]$Length)
    $b = New-Object 'System.Collections.Generic.List[byte]'
    $x = $Length
    do {
        $d = $x % 128
        $x = [int][math]::Floor($x / 128)
        if ($x -gt 0) { $d = $d -bor 128 }
        $b.Add([byte]$d)
    } while ($x -gt 0)
    , $b.ToArray()
}

function ConvertFrom-MqttRemainingLength {
    <# Returns @{Value; Size} or $null when the bytes so far are incomplete. Throws when malformed. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.IList]$Bytes, [int]$Offset = 0)
    $value = 0; $mult = 1; $i = 0
    while ($true) {
        if (($Offset + $i) -ge $Bytes.Count) { return $null }
        $d = [int]$Bytes[$Offset + $i]
        $value += ($d -band 127) * $mult
        $i++
        if (($d -band 128) -eq 0) { break }
        if ($i -ge 4) { throw 'MQTT: remaining length malformed (more than 4 bytes).' }
        $mult *= 128
    }
    [pscustomobject]@{ Value = $value; Size = $i }
}

function ConvertTo-MqttString {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $u = [System.Text.Encoding]::UTF8.GetBytes($Text)
    if ($u.Length -gt 65535) { throw 'MQTT: string too long.' }
    $r = New-Object 'System.Collections.Generic.List[byte]'
    $r.Add([byte]($u.Length -shr 8)); $r.Add([byte]($u.Length -band 255))
    $r.AddRange($u)
    , $r.ToArray()
}

function Join-MqttPacket {
    param([byte]$FirstByte, [byte[]]$Body)
    $p = New-Object 'System.Collections.Generic.List[byte]'
    $p.Add($FirstByte)
    $p.AddRange([byte[]](ConvertTo-MqttRemainingLength -Length $Body.Length))
    $p.AddRange($Body)
    , $p.ToArray()
}

function New-MqttConnectPacket {
    <# CONNECT, protocol MQTT 3.1.1, clean session, username + password. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$UserName,
        [Parameter(Mandatory)][string]$Password,
        [ValidateRange(1, 65535)][int]$KeepAliveSec = 60
    )
    $b = New-Object 'System.Collections.Generic.List[byte]'
    $b.AddRange([byte[]](ConvertTo-MqttString 'MQTT'))
    $b.Add(4)              # protocol level 4 = 3.1.1
    $b.Add(0xC2)           # username + password + clean session
    $b.Add([byte]($KeepAliveSec -shr 8)); $b.Add([byte]($KeepAliveSec -band 255))
    $b.AddRange([byte[]](ConvertTo-MqttString $ClientId))
    $b.AddRange([byte[]](ConvertTo-MqttString $UserName))
    $b.AddRange([byte[]](ConvertTo-MqttString $Password))
    , (Join-MqttPacket -FirstByte 0x10 -Body $b.ToArray())
}

function New-MqttSubscribePacket {
    <# SUBSCRIBE to one topic at QoS 0. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateRange(1, 65535)][int]$PacketId, [Parameter(Mandatory)][string]$Topic)
    $b = New-Object 'System.Collections.Generic.List[byte]'
    $b.Add([byte]($PacketId -shr 8)); $b.Add([byte]($PacketId -band 255))
    $b.AddRange([byte[]](ConvertTo-MqttString $Topic))
    $b.Add(0)              # requested QoS 0
    , (Join-MqttPacket -FirstByte 0x82 -Body $b.ToArray())
}

function New-MqttPublishPacket {
    <# PUBLISH, QoS 0, no retain. Encoder only; callers decide whether anything is sent. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Topic, [Parameter(Mandatory)][string]$Payload)
    $b = New-Object 'System.Collections.Generic.List[byte]'
    $b.AddRange([byte[]](ConvertTo-MqttString $Topic))
    $b.AddRange([System.Text.Encoding]::UTF8.GetBytes($Payload))
    , (Join-MqttPacket -FirstByte 0x30 -Body $b.ToArray())
}

function Get-MqttPacketFromBuffer {
    <# Removes one complete packet from the front of a List[byte]; $null if not complete yet.
       Returns Type (1..14), Flags, Body. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.Generic.List[byte]]$Buffer)
    if ($Buffer.Count -lt 2) { return $null }
    $rl = ConvertFrom-MqttRemainingLength -Bytes $Buffer -Offset 1
    if ($null -eq $rl) { return $null }
    if ($rl.Value -gt 1048576) { throw 'MQTT: goi khai do dai qua 1 MB - bo.' }
    $total = 1 + $rl.Size + $rl.Value
    if ($Buffer.Count -lt $total) { return $null }
    $first = [int]$Buffer[0]
    $body = $Buffer.GetRange(1 + $rl.Size, $rl.Value).ToArray()
    $Buffer.RemoveRange(0, $total)
    [pscustomobject]@{ Type = ($first -shr 4); Flags = ($first -band 15); Body = $body }
}

function ConvertFrom-MqttPublish {
    <# Decode a PUBLISH packet (from Get-MqttPacketFromBuffer). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Packet)
    if ($Packet.Type -ne 3) { throw 'MQTT: not a PUBLISH packet.' }
    $body = [byte[]]$Packet.Body
    if ($body.Length -lt 2) { throw 'MQTT: PUBLISH too short.' }
    $tl = ([int]$body[0] -shl 8) + [int]$body[1]
    $idx = 2 + $tl
    if ($body.Length -lt $idx) { throw 'MQTT: PUBLISH topic length out of range.' }
    $topic = [System.Text.Encoding]::UTF8.GetString($body, 2, $tl)
    $qos = ($Packet.Flags -shr 1) -band 3
    $pktId = 0
    if ($qos -gt 0) {
        if ($body.Length -lt ($idx + 2)) { throw 'MQTT: PUBLISH packet id missing.' }
        $pktId = ([int]$body[$idx] -shl 8) + [int]$body[$idx + 1]
        $idx += 2
    }
    $payload = New-Object byte[] ($body.Length - $idx)
    [System.Array]::Copy($body, $idx, $payload, 0, $payload.Length)
    [pscustomobject]@{ Topic = $topic; Qos = $qos; Retain = [bool]($Packet.Flags -band 1); PacketId = $pktId; Payload = $payload }
}

# ---------- secret handling ----------

# Key-name rule applied at every depth (case-insensitive): serial numbers (sn, hw_sn, module_sn),
# file / job / project names, uid / uuid / rfid, ip, wifi, account, urls and ids.
$script:BambuDropKeyRegex = '(?i)(^|_)(sn|serial|file|name|uid|uuid|rfid|ip|ssid|bssid|mac|token|account|email|user|url|id|password|access_code)($|_)|^(subtask|project|task|profile)'
# Top-level keys of the "print" block that are kept (everything else is dropped and counted).
$script:BambuPrintAllow = @(
    'gcode_state', 'mc_percent', 'mc_remaining_time', 'layer_num', 'total_layer_num', 'print_type',
    'nozzle_temper', 'nozzle_target_temper', 'bed_temper', 'bed_target_temper', 'chamber_temper',
    'nozzle_diameter', 'nozzle_type', 'hms', 'print_error', 'fail_reason', 'stg_cur', 'wifi_signal',
    'cooling_fan_speed', 'big_fan1_speed', 'big_fan2_speed', 'heatbreak_fan_speed', 'spd_lvl', 'spd_mag',
    'lifecycle', 'ams_status', 'lights_report', 'home_flag', 'sdcard', 'ams', 'device', 'upgrade_state'
)
$script:BambuHidden = '[an]'

function Protect-SecretText {
    <# Replace every occurrence of the given secrets in a text (used for error messages). #>
    [CmdletBinding()]
    param([AllowNull()][AllowEmptyString()][string]$Text, [string[]]$Secrets = @())
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    foreach ($s in $Secrets) {
        if ([string]::IsNullOrWhiteSpace($s) -or $s.Length -lt 4) { continue }
        $Text = [regex]::Replace($Text, [regex]::Escape($s), $script:BambuHidden, 'IgnoreCase')
    }
    $Text
}

function Remove-BambuSecrets {
    <# Returns a scrubbed copy of a parsed JSON tree (ConvertFrom-Json output):
       - drops every key matching $script:BambuDropKeyRegex (or containing a secret string);
       - in every string value replaces the given secrets (serial, ip, any case) and any 15-char
         letter+digit token shaped like a Bambu serial.
       -Stats (hashtable with Rule) counts dropped keys. #>
    [CmdletBinding()]
    param([AllowNull()]$Node, [string[]]$SecretStrings = @(), [hashtable]$Stats = @{ Rule = 0; Unknown = 0 })
    $sec = @($SecretStrings | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_.Length -ge 4 })
    $serialLike = '(?i)\b(?=[0-9A-Z]*\d)(?=[0-9A-Z]*[A-Z])[0-9A-Z]{15}\b'
    function Scrub($n) {
        if ($null -eq $n) { return $null }
        if ($n -is [string]) {
            $t = $n
            foreach ($s in $sec) { $t = [regex]::Replace($t, [regex]::Escape($s), $script:BambuHidden, 'IgnoreCase') }
            return [regex]::Replace($t, $serialLike, $script:BambuHidden)
        }
        if ($n -is [System.Collections.IDictionary] -or $n -is [System.Management.Automation.PSCustomObject]) {
            $out = [ordered]@{}
            $pairs = if ($n -is [System.Collections.IDictionary]) {
                foreach ($k in $n.Keys) { [pscustomobject]@{ Name = [string]$k; Value = $n[$k] } }
            } else { $n.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } } }
            foreach ($p in $pairs) {
                $hit = $p.Name -match $script:BambuDropKeyRegex
                foreach ($s in $sec) { if ($p.Name.IndexOf($s, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $hit = $true } }
                if ($hit) { $Stats.Rule++; continue }
                $out[$p.Name] = Scrub $p.Value
            }
            return $out
        }
        if ($n -is [System.Collections.IEnumerable]) {
            $list = New-Object 'System.Collections.Generic.List[object]'
            foreach ($e in $n) { $list.Add((Scrub $e)) }
            return , $list.ToArray()
        }
        return $n
    }
    Scrub $Node
}

function Select-BambuReport {
    <# Allow-list for the merged "print" block: keeps only keys in $script:BambuPrintAllow
       (each kept value goes through Remove-BambuSecrets); other keys are dropped and counted
       in Stats.Unknown. Returns an ordered dictionary. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Print, [string[]]$SecretStrings = @(), [hashtable]$Stats = @{ Rule = 0; Unknown = 0 })
    $out = [ordered]@{}
    foreach ($p in $Print.PSObject.Properties) {
        if ($script:BambuPrintAllow -contains $p.Name) {
            $out[$p.Name] = Remove-BambuSecrets -Node $p.Value -SecretStrings $SecretStrings -Stats $Stats
        } else { $Stats.Unknown++ }
    }
    $out
}

function Select-BambuInfo {
    <# Module versions only: name, sw_ver, hw_ver per module; serials and every other key dropped. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Info, [string[]]$SecretStrings = @(), [hashtable]$Stats = @{ Rule = 0; Unknown = 0 })
    $mods = New-Object 'System.Collections.Generic.List[object]'
    $mp = $Info.PSObject.Properties['module']
    if ($mp) {
        foreach ($m in @($mp.Value)) {
            $o = [ordered]@{}
            foreach ($k in 'name', 'sw_ver', 'hw_ver') {
                $q = $m.PSObject.Properties[$k]
                if ($q) { $o[$k] = Remove-BambuSecrets -Node ([string]$q.Value) -SecretStrings $SecretStrings -Stats $Stats }
            }
            $Stats.Unknown += @($m.PSObject.Properties | Where-Object { $_.Name -notin 'name', 'sw_ver', 'hw_ver' }).Count
            $mods.Add($o)
        }
    }
    $Stats.Unknown += @($Info.PSObject.Properties | Where-Object { $_.Name -ne 'module' }).Count
    [ordered]@{ module = $mods.ToArray() }
}


# ---------- TLS transport ----------

function Open-BambuMqtt {
    <# TCP + TLS 1.2 to ip:8883. Self-signed certificate is accepted; its SHA-256 is returned in
       CertSha256 (hash only, subject is not read). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Ip, [int]$Port = 8883, [int]$ConnectTimeoutMs = 8000)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $ar = $tcp.BeginConnect($Ip, $Port, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne($ConnectTimeoutMs)) { throw "Khong ket noi duoc cong $Port (het thoi gian)." }
        $tcp.EndConnect($ar)
        # time limit for the (synchronous) TLS handshake; lifted afterwards because reads are async
        $tcp.ReceiveTimeout = 10000; $tcp.SendTimeout = 10000
        # Certificate is accepted here on purpose; the caller compares CertSha256 with the pinned
        # value BEFORE any CONNECT (access code) is sent.
        $cb = [System.Net.Security.RemoteCertificateValidationCallback] { param($s, $c, $ch, $e) return $true }
        $ssl = New-Object System.Net.Security.SslStream ($tcp.GetStream(), $false, $cb)
        $ssl.ReadTimeout = 10000; $ssl.WriteTimeout = 10000
        $ssl.AuthenticateAsClient($Ip, $null, [System.Security.Authentication.SslProtocols]::Tls12, $false)
        $tcp.ReceiveTimeout = 0; $tcp.SendTimeout = 10000
        $ssl.ReadTimeout = [System.Threading.Timeout]::Infinite
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $fp = ($sha.ComputeHash($ssl.RemoteCertificate.GetRawCertData()) | ForEach-Object { $_.ToString('x2') }) -join ''
        [pscustomobject]@{
            Tcp = $tcp; Ssl = $ssl; CertSha256 = $fp
            Buffer = (New-Object 'System.Collections.Generic.List[byte]')
            ReadBuf = (New-Object byte[] 8192); Task = $null
        }
    } catch { $tcp.Close(); throw }
}

function Send-MqttBytes {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)][byte[]]$Bytes)
    $Session.Ssl.Write($Bytes, 0, $Bytes.Length)
    $Session.Ssl.Flush()
}

function Read-MqttPacketTimed {
    <# Next complete packet, or $null when TimeoutMs passes first. A timed-out read stays pending
       inside the session (SslStream is not read again until it completes). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)][int]$TimeoutMs)
    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMs)
    while ($true) {
        $p = Get-MqttPacketFromBuffer -Buffer $Session.Buffer
        if ($p) { return $p }
        if ($null -eq $Session.Task) {
            $Session.Task = $Session.Ssl.ReadAsync($Session.ReadBuf, 0, $Session.ReadBuf.Length)
        }
        $left = [int][math]::Max(0, ($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        if (-not $Session.Task.Wait($left)) { return $null }
        $t = $Session.Task
        $Session.Task = $null
        $n = $t.Result
        if ($n -le 0) { throw 'May dong ket noi.' }
        $chunk = New-Object byte[] $n
        [System.Array]::Copy($Session.ReadBuf, 0, $chunk, 0, $n)
        $Session.Buffer.AddRange($chunk)
    }
}

function Close-BambuMqtt {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Session)
    try { $Session.Tcp.Close() } catch { }
}

Export-ModuleMember -Function ConvertTo-MqttRemainingLength, ConvertFrom-MqttRemainingLength, New-MqttConnectPacket, New-MqttSubscribePacket, New-MqttPublishPacket, Get-MqttPacketFromBuffer, ConvertFrom-MqttPublish, Protect-SecretText, Remove-BambuSecrets, Select-BambuReport, Select-BambuInfo, Open-BambuMqtt, Send-MqttBytes, Read-MqttPacketTimed, Close-BambuMqtt
