# inventory.ps1 - fleet inventory of 6 printers -> fleet\inventory.csv + fleet\inventory.md (spec 001 T005).
# Read-only: Moonraker GET (2 Voron), passive SSDP listen on udp 2021 (4 Bambu), local ARP table (MAC).
# No serial is read or written. A printer that does not answer gets "khong tra loi HH:mm:ss" in its data
# columns and the other printers are still written.
#   -Ips        override addresses, e.g. -Ips @{ V24 = '192.0.2.250' } (to test the "no answer" row)
# Default addresses come from fleet.local.json (see Get-FleetConfig; FLEET_CONFIG overrides the path).
#   -SampleDir  offline: read <dir>\<id>\objects.json (+ optional info.json) instead of Moonraker
#   -SsdpSampleFile  offline: text file with SSDP datagrams separated by a line "----"
#   -OutDir     output folder (default fleet\); required with the offline switches
#   -WarmArp    send one ICMP echo to printers whose MAC is not in the ARP table yet
[CmdletBinding()]
param(
    [hashtable]$Ips = @{},
    [int]$SsdpSeconds = 15,
    [string]$OutDir,
    [string]$SampleDir,
    [string]$SsdpSampleFile,
    [switch]$WarmArp,
    [int]$TimeoutSec = 8
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\lib\Fleet.psm1') -Force

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$offline = [bool]($SampleDir -or $SsdpSampleFile)
if ($offline -and -not $OutDir) { throw 'Che do offline phai co -OutDir (de khong ghi de fleet\inventory.* that).' }
if (-not $OutDir) { $OutDir = Join-Path $root 'fleet' }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$today = Get-Date -Format 'yyyy-MM-dd'
$noAns = { 'không trả lời ' + (Get-Date -Format 'HH:mm:ss') }

# id -> kind, default ip, catalogue facts (not read from the machine; labelled as such in "nguồn")
$cfg = Get-FleetConfig
$fleet = [ordered]@{
    TRI = @{ Kind = 'Voron'; Ip = $cfg.ips.TRI; Model = 'Voron Trident 250' }
    V24 = @{ Kind = 'Voron'; Ip = $cfg.ips.V24; Model = 'Voron 2.4 300' }
    H2S = @{ Kind = 'Bambu'; Ip = $cfg.ips.H2S; Model = 'Bambu Lab H2S'; Code = 'O1S'; Bed = '340x320x340 mm'; Enclosed = 'có'; Acc = 'AMS' }
    P1S = @{ Kind = 'Bambu'; Ip = $cfg.ips.P1S; Model = 'Bambu Lab P1S'; Code = 'C12'; Bed = '256x256x256 mm'; Enclosed = 'có'; Acc = 'không có AMS' }
    A1 = @{ Kind = 'Bambu'; Ip = $cfg.ips.A1; Model = 'Bambu Lab A1'; Code = 'N2S'; Bed = '256x256x256 mm'; Enclosed = 'không'; Acc = 'không có AMS' }
    A1M = @{ Kind = 'Bambu'; Ip = $cfg.ips.A1M; Model = 'Bambu Lab A1 Mini'; Code = 'N1'; Bed = '180x180x180 mm'; Enclosed = 'không'; Acc = 'không có AMS' }
}

function Get-MacFromArp([string]$ip) {
    $find = {
        Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue |
            Where-Object { $_.LinkLayerAddress -and $_.LinkLayerAddress -notmatch '^(00-)+00$' } |
            Select-Object -First 1
    }
    $n = & $find
    if (-not $n -and $WarmArp -and -not $offline) {
        Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null
        $n = & $find
    }
    if ($n) { return ($n.LinkLayerAddress -replace '-', ':').ToLower() }
    'chưa có trong bảng ARP'
}

function Format-Num($v) { ([double]$v).ToString('0.###', $inv) }

function New-Row([string]$id, [string]$ip) {
    [ordered]@{
        'id' = $id; 'tên' = ''; 'mẫu' = ''; 'ip' = $ip; 'mac' = ''; 'phần_mềm_firmware' = ''
        'đầu_phun' = ''; 'bàn' = ''; 'phụ_kiện' = ''; 'kết_nối' = ''; 'buồng_kín' = ''; 'nguồn' = ''; 'ngày' = $today
    }
}

function Set-NoAnswer($row, [string]$why) {
    $t = & $noAns
    foreach ($c in 'tên', 'mẫu', 'phần_mềm_firmware', 'đầu_phun', 'bàn', 'phụ_kiện', 'kết_nối', 'buồng_kín') { $row[$c] = $t }
    $row['mac'] = Get-MacFromArp $row['ip']
    $row['nguồn'] = "$why $t"
}

function Get-VoronRow([string]$id, [hashtable]$d) {
    $row = New-Row $id $d.Ip
    try {
        if ($SampleDir) {
            $sf = Join-Path $SampleDir "$id\objects.json"
            $infoF = Join-Path $SampleDir "$id\info.json"
            $st = Get-Content -LiteralPath $sf -Raw | ConvertFrom-Json
            $info = if (Test-Path -LiteralPath $infoF) { Get-Content -LiteralPath $infoF -Raw | ConvertFrom-Json } else { $null }
            $mst = $st
        } else {
            $info = Get-MoonrakerInfo -Ip $d.Ip -TimeoutSec $TimeoutSec
            $st = Get-MoonrakerObjects -Ip $d.Ip -TimeoutSec $TimeoutSec -Objects @{ toolhead = @('axis_maximum'); configfile = @('settings') }
            $mcuNames = @($st.configfile.settings.PSObject.Properties.Name | Where-Object { $_ -match '^mcu( |$)' })
            $q = @{}; foreach ($n in $mcuNames) { $q[$n] = @('mcu_version') }
            $mst = if ($q.Count) { Get-MoonrakerObjects -Ip $d.Ip -TimeoutSec $TimeoutSec -Objects $q } else { $null }
        }
        $hostName = if ($info -and $info.PSObject.Properties['hostname']) { [string]$info.hostname } else { 'n/a (mẫu không có info)' }
        $kver = if ($info -and $info.PSObject.Properties['software_version']) { [string]$info.software_version } else { 'n/a' }
        $mcus = @()
        $mcuNames2 = @($st.configfile.settings.PSObject.Properties.Name | Where-Object { $_ -match '^mcu( |$)' })
        foreach ($n in $mcuNames2) {
            $p = if ($mst) { $mst.PSObject.Properties[$n] } else { $null }
            $mcus += ('{0}: {1}' -f $n, $(if ($p) { $p.Value.mcu_version } else { 'n/a' }))
        }
        $am = $st.toolhead.axis_maximum
        $nz = $st.configfile.settings.extruder.nozzle_diameter
        $row['tên'] = $hostName
        $row['mẫu'] = $d.Model
        $row['mac'] = Get-MacFromArp $d.Ip
        $row['phần_mềm_firmware'] = (@("Klipper $kver") + $mcus) -join '; '
        $row['đầu_phun'] = if ($null -ne $nz) { (Format-Num $nz) + ' mm (đường kính)' } else { 'n/a' }
        $row['bàn'] = if ($am) { '{0}x{1}x{2} mm' -f (Format-Num $am[0]), (Format-Num $am[1]), (Format-Num $am[2]) } else { 'n/a' }
        $row['phụ_kiện'] = if ($mcuNames2 -contains 'mcu cartographer') { 'Cartographer (có mcu cartographer)' } else { 'chưa ghi nhận phụ kiện qua Moonraker' }
        $row['kết_nối'] = 'Moonraker http :7125'
        $row['buồng_kín'] = 'có'
        $row['nguồn'] = 'tên, Klipper: Moonraker /printer/info; mcu: objects mcu_version; bàn: toolhead.axis_maximum; đầu phun: configfile.settings.extruder.nozzle_diameter; mac: ARP; mẫu, buồng: danh mục dự án'
        if ($SampleDir) { $row['nguồn'] += " [MẪU OFFLINE: $SampleDir]" }
    } catch {
        Set-NoAnswer $row 'Moonraker'
    }
    $row
}

function Get-BambuRow([string]$id, [hashtable]$d, $ssdp) {
    $row = New-Row $id $d.Ip
    if (-not $ssdp) { Set-NoAnswer $row 'SSDP'; return $row }
    $model = if ($ssdp.Model -eq $d.Code) { $d.Model } else { "{0} (SSDP báo mã {1}, dự kiến {2})" -f $d.Model, $ssdp.Model, $d.Code }
    $row['tên'] = [string]$ssdp.Name
    $row['mẫu'] = $model
    $row['mac'] = Get-MacFromArp $d.Ip
    $row['phần_mềm_firmware'] = [string]$ssdp.Version
    $row['đầu_phun'] = 'chưa đọc (cần MQTT hoặc màn hình máy)'
    $row['bàn'] = $d.Bed
    $row['phụ_kiện'] = $d.Acc
    $row['kết_nối'] = 'Bambu ' + [string]$ssdp.Connect + ' (SSDP)'
    $row['buồng_kín'] = $d.Enclosed
    $row['nguồn'] = 'tên, mẫu, firmware, kết nối: SSDP udp 2021; mac: ARP; bàn, buồng: thông số hãng (không đọc từ máy); phụ kiện: người dùng cho biết'
    if ($SsdpSampleFile) { $row['nguồn'] += " [MẪU OFFLINE: $SsdpSampleFile]" }
    $row
}

# --- SSDP (Bambu) ---
$ssdpByIp = @{}
if ($SsdpSampleFile) {
    $txt = Get-Content -LiteralPath $SsdpSampleFile -Raw
    foreach ($chunk in ($txt -split '(?m)^----\s*$')) {
        $p = $chunk | ConvertFrom-BambuSsdp
        if ($p -and $p.Ip) { $ssdpByIp[$p.Ip] = $p }
    }
} elseif (-not $SampleDir) {
    foreach ($p in @(Receive-BambuSsdp -ListenSec $SsdpSeconds)) { if ($p.Ip) { $ssdpByIp[$p.Ip] = $p } }
}

$rows = foreach ($id in $fleet.Keys) {
    $d = $fleet[$id].Clone()
    if ($Ips.ContainsKey($id)) { $d.Ip = [string]$Ips[$id] }
    if ($d.Kind -eq 'Voron') { [pscustomobject](Get-VoronRow $id $d) }
    else { [pscustomobject](Get-BambuRow $id $d $ssdpByIp[$d.Ip]) }
}

# Values come from the network (SSDP name, hostname...): neutralise spreadsheet formulas.
function Protect-CsvCell($v) {
    $s = [string]$v
    if ($s -match '^[=+\-@\t\r]') { return "'" + $s }
    $s
}
foreach ($r in $rows) { foreach ($p in @($r.PSObject.Properties)) { $p.Value = Protect-CsvCell $p.Value } }

$csv = Join-Path $OutDir 'inventory.csv'
$rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

$cols = @($rows[0].PSObject.Properties.Name)
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Kiểm kê dàn máy in - $today")
$md.Add('')
$md.Add('Sinh bởi `scripts\fleet\inventory.ps1` (chỉ đọc). Không có serial. Cột `nguồn` ghi nguồn của từng số.')
$md.Add('')
$md.Add('| ' + ($cols -join ' | ') + ' |')
$md.Add('|' + (($cols | ForEach-Object { '---' }) -join '|') + '|')
foreach ($r in $rows) {
    $md.Add('| ' + (($cols | ForEach-Object { ([string]$r.$_) -replace '\|', '/' }) -join ' | ') + ' |')
}
[System.IO.File]::WriteAllLines((Join-Path $OutDir 'inventory.md'), [string[]]$md, (New-Object System.Text.UTF8Encoding($true)))

"Đã ghi $csv và inventory.md ($(@($rows).Count) dòng)"
$rows | ForEach-Object { '{0}: {1}' -f $_.id, $(if ($_.'tên' -like 'không trả lời*') { $_.'tên' } else { 'có dữ liệu' }) }
