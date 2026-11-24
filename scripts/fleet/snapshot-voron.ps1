# snapshot-voron.ps1 - read-only baseline of a Voron (Moonraker GET only), spec 001 T009.
# Writes fleet\baseline\<date>\<id>\config\ (every user .cfg/.conf under root "config", without
# backups\ and ShakeTune results) + manifest.sha256, and calib.json (configfile.settings + main objects).
# Refuses to overwrite an existing <date>\<id> folder unless -Force. Never touches orig, recheck, v24, trident.
[CmdletBinding()]
param(
    [ValidateSet('TRI', 'V24')][string[]]$Machine = @('TRI', 'V24'),
    [hashtable]$Ips = @{},
    [string]$Date = (Get-Date -Format 'yyyy-MM-dd'),
    [switch]$Force,
    [int]$TimeoutSec = 20
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\lib\Fleet.psm1') -Force

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$defaultIps = @{ TRI = '192.0.2.90'; V24 = '192.0.2.89' }
$skipDir = '(^|/)(backups|K-ShakeTune_results|ShakeTune[^/]*|shaketune[^/]*)(/|$)'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Hide-ConfigSecrets([string]$Path) {
    <# Masks the value of "key: value" / "key = value" lines whose key name contains token, api_key,
       password or secret. Rewrites the file only when something matched. Returns the count. #>
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $re = '(?im)^([ \t]*[\w.\-]*(?:token|api_key|password|secret)[\w.\-]*[ \t]*[:=][ \t]*)(?!\*\*\*)([^\r\n]*\S)'
    $count = [regex]::Matches($text, $re).Count
    if ($count -gt 0) {
        $new = [regex]::Replace($text, $re, '${1}***')
        [System.IO.File]::WriteAllText($Path, $new, (New-Object System.Text.UTF8Encoding($bom)))
    }
    $count
}

function Save-VoronSnapshot([string]$id, [string]$ip) {
    $dest = Join-Path $root "fleet\baseline\$Date\$id"
    if ((Test-Path -LiteralPath $dest) -and -not $Force) {
        throw "Da co $dest - khong ghi de (dung -Force neu that su can)."
    }
    $cfgDir = Join-Path $dest 'config'
    New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    $cfgFull = (Resolve-Path -LiteralPath $cfgDir).Path.TrimEnd('\')

    # 1. file list (GET /server/files/list?root=config)
    $list = @(Get-MoonrakerFiles -Ip $ip -Root 'config' -TimeoutSec $TimeoutSec)
    $wanted = @($list | Where-Object {
            $p = [string]$_.path
            $p -match '\.(cfg|conf)$' -and $p -notmatch $skipDir
        })
    "{0}: {1} file trong root config, {2} file cau hinh se tai" -f $id, $list.Count, $wanted.Count

    # 2. download each file as raw bytes (GET), verify size, hash
    $lines = New-Object System.Collections.Generic.List[string]
    $masked = New-Object System.Collections.Generic.List[string]
    foreach ($f in $wanted) {
        $rel = ([string]$f.path) -replace '\\', '/'
        if ($rel.StartsWith('/') -or $rel -match '(^|/)\.\.(/|$)' -or $rel -match '[:*?"<>|]') { throw "Duong dan la, bo qua ca lan chay: $rel" }
        $target = Join-Path $cfgFull ($rel -replace '/', '\')
        if (-not $target.StartsWith($cfgFull + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Duong dan ra ngoai thu muc dich: $rel" }
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        $enc = ($rel -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
        Invoke-WebRequest -Method Get -Uri "http://$ip/server/files/config/$enc" -OutFile $target -TimeoutSec $TimeoutSec -UseBasicParsing | Out-Null
        if ($null -ne $f.PSObject.Properties['size'] -and (Get-Item -LiteralPath $target).Length -ne [int64]$f.size) {
            throw "Lech kich thuoc sau khi tai: $rel"
        }
        $origHash = Get-FleetSha256 $target
        $n = Hide-ConfigSecrets $target
        if ($n -gt 0) { $masked.Add(('{0}  {1}  values_masked={2}  sha256_on_printer={3}' -f 'MASKED', $rel, $n, $origHash)) }
        $lines.Add(('{0}  {1}' -f (Get-FleetSha256 $target), $rel))
    }
    [System.IO.File]::WriteAllLines((Join-Path $dest 'manifest.sha256'), [string[]]$lines, $utf8)
    # Masked files differ from the printer copy by design; listed apart so manifest.sha256 stays sha256sum-format.
    if ($masked.Count -gt 0) {
        [System.IO.File]::WriteAllLines((Join-Path $dest 'masked.txt'), [string[]]$masked, $utf8)
        "{0}: CHU Y - {1} file co gia tri bi che (token/api_key/password/secret), xem masked.txt; bang bam cua file do se lech file tren may" -f $id, $masked.Count
    }

    # 3. calib.json = /printer/info + configfile.settings + main objects
    $info = Get-MoonrakerInfo -Ip $ip -TimeoutSec $TimeoutSec
    $st = Get-MoonrakerObjects -Ip $ip -TimeoutSec $TimeoutSec -Objects @{
        configfile = @('settings', 'save_config_pending', 'save_config_pending_items', 'warnings')
    }
    $mcuNames = @($st.configfile.settings.PSObject.Properties.Name | Where-Object { $_ -match '^mcu( |$)' })
    $objs = [ordered]@{}
    foreach ($n in @('toolhead', 'extruder', 'heater_bed', 'print_stats', 'skew_correction', 'input_shaper', 'resonance_tester', 'bed_mesh', 'probe', 'cartographer', 'gcode_macro _USER_VARIABLES', 'canbus_stats cartographer', 'system_stats') + $mcuNames) { $objs[$n] = @() }
    $main = Get-MoonrakerObjects -Ip $ip -TimeoutSec $TimeoutSec -Objects $objs
    $calib = [ordered]@{
        _meta = [ordered]@{ machine = $id; read_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); source = 'Moonraker GET /printer/info, /printer/objects/query'; print_state = $main.print_stats.state }
        info = $info
        configfile = $st.configfile
        objects = $main
    }
    [System.IO.File]::WriteAllText((Join-Path $dest 'calib.json'), ($calib | ConvertTo-Json -Depth 30), $utf8)
    "{0}: da ghi {1} file config + manifest.sha256 + calib.json trong {2} (trang thai in: {3})" -f $id, $lines.Count, $dest, $main.print_stats.state
}

foreach ($id in $Machine) {
    $ip = if ($Ips.ContainsKey($id)) { [string]$Ips[$id] } else { $defaultIps[$id] }
    try { Save-VoronSnapshot $id $ip } catch { "{0}: loi - {1}" -f $id, $_.Exception.Message }
}
