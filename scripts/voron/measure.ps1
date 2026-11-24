<#
.SYNOPSIS
  Phep do cong huong lap lai duoc cho Voron (Trident / V2.4). Khong dun nhua, khong gia nhiet, khong SAVE_CONFIG.
.EXAMPLE
  .\measure.ps1 -Printer TRI -Phase before -Condition cold -WhatIf
#>
param(
    [Parameter(Mandatory)][ValidateSet('TRI', 'V24')][string]$Printer,
    [Parameter(Mandatory)][ValidateSet('before', 'after')][string]$Phase,
    [ValidateSet('cold')][string]$Condition = 'cold',
    [ValidateRange(1, 10)][int]$Repeats = 3,
    [double]$ColdMax = 45,
    [switch]$Force,
    [switch]$BedClear,   # xac nhan ban trong, bat buoc moi lan chay that
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $root 'scripts\lib\Fleet.psm1') -Force

$Ips = @{ TRI = '192.0.2.90'; V24 = '192.0.2.89' }
# Danh sach G-code duy nhat duoc phep gui (khai bao mot cho). Send-Gcode tu choi moi lenh ngoai danh sach.
$AllowedGcode = @(
    'G28'
    'M400'
    'COMPARE_BELTS_RESPONSES FREQ_END=200'
    'AXES_SHAPER_CALIBRATION AXIS=X FREQ_END=200'
    'AXES_SHAPER_CALIBRATION AXIS=Y FREQ_END=200'
)
$Ip = $Ips[$Printer]
$outFile = Join-Path $root "calibration\voron\${Phase}_${Printer}.json"

if ($WhatIf) {
    Write-Output "[WhatIf] $Printer ($Ip) phase=$Phase condition=$Condition repeats=$Repeats. Khong gui gi."
    Write-Output "[WhatIf] Truoc khi gui: kiem ready, khong printing/paused, nhiet dau/ban < $ColdMax C. Lenh se gui theo thu tu:"
    Write-Output '[WhatIf]   (chay that can -BedClear) G28 (chi khi chua home xyz), roi M400, kiem nguoi lai'
    1..$Repeats | ForEach-Object { Write-Output "[WhatIf]   COMPARE_BELTS_RESPONSES FREQ_END=200 (lan $_), roi M400" }
    Write-Output '[WhatIf]   AXES_SHAPER_CALIBRATION AXIS=X FREQ_END=200, roi M400'
    Write-Output '[WhatIf]   AXES_SHAPER_CALIBRATION AXIS=Y FREQ_END=200, roi M400'
    Write-Output "[WhatIf] Ghi: $outFile"
    return
}

if ((Test-Path -LiteralPath $outFile) -and -not $Force) { throw "File da co, khong ghi de (dung -Force neu chac): $outFile" }

function Get-State { Get-MoonrakerObjects -Ip $Ip -Objects @{ print_stats = @('state'); toolhead = @('homed_axes'); idle_timeout = @('state'); extruder = @('temperature'); heater_bed = @('temperature') } }

function Assert-Idle {
    $info = Get-MoonrakerInfo -Ip $Ip
    if ($info.state -ne 'ready') { throw "[$Printer] klippy khong ready: $($info.state)" }
    $s = Get-State
    if ($s.print_stats.state -in @('printing', 'paused')) { throw "[$Printer] may dang in/tam dung: $($s.print_stats.state)" }
    if ($s.idle_timeout.state -eq 'Printing') { throw "[$Printer] may dang ban (idle_timeout=Printing)" }
    $s
}

function Send-Gcode([string]$g) {
    if ($AllowedGcode -notcontains $g) { throw "G-code khong nam trong danh sach cho phep: $g" }
    Write-Output "[$Printer] $(Get-Date -Format HH:mm:ss) gui: $g"
    try {
        Invoke-RestMethod -Method Post "http://${Ip}:7125/printer/gcode/script" -Body (@{ script = $g } | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec 1500 | Out-Null
    } catch {
        # chi bo qua khi het gio phia client (lenh dai); loi ket noi/reset/tu choi deu dung
        if ($_.Exception.Status -ne [Net.WebExceptionStatus]::Timeout) { throw "[$Printer] lenh khong toi may hoac bi tu choi: $g : $($_.Exception.Message)" }
        Write-Output "[$Printer] yeu cau ket thuc: $($_.Exception.Message)"
    }
}

function Wait-Done {
    # cach cua shake_run.ps1: cho toi khi idle_timeout khong con Printing
    $idle = $false
    for ($i = 0; $i -lt 120; $i++) {
        Start-Sleep 10
        try { if ((Get-State).idle_timeout.state -ne 'Printing') { $idle = $true; break } } catch {}
    }
    if (-not $idle) { throw "[$Printer] het gio cho: may van ban sau 20 phut" }
    $info = Get-MoonrakerInfo -Ip $Ip
    if ($info.state -ne 'ready') { throw "[$Printer] klippy khong ready sau lenh: $($info.state)" }
}

function Get-StoreLastTime {
    $r = Invoke-RestMethod "http://${Ip}:7125/server/gcode_store?count=1" -TimeoutSec 20
    $a = @($r.result.gcode_store)
    if ($a.Count -gt 0) { [double]$a[-1].time } else { 0.0 }
}

# Tach hai tin hieu: Found = lenh $g co trong store (moi hon $t); Messages = phan hoi sau lan xuat hien CUOI (luon la mang, co the rong).
# Ham thuan (khong goi mang) de tests\measure\ doc rieng qua AST.
function Select-StoreSince($entries, [string]$g, [double]$t) {
    $e = @($entries | Where-Object { $null -ne $_ -and [double]$_.time -gt $t })
    $m = @($e | ForEach-Object { ([string]$_.message).Trim() })
    $idx = [array]::LastIndexOf($m, $g)
    if ($idx -lt 0) { return [pscustomobject]@{ Found = $false; Messages = @() } }
    # chi giu phan hoi: bo muc type=command va cac dong lenh $g, M400
    $msgs = @($e[$idx..($e.Count - 1)] | Where-Object { $_.type -ne 'command' -and ([string]$_.message).Trim() -notin @($g, 'M400', '') } | ForEach-Object { ([string]$_.message).Trim() })
    [pscustomobject]@{ Found = $true; Messages = $msgs }
}

function Get-StoreSince([string]$g, [double]$t) {
    $r = Invoke-RestMethod "http://${Ip}:7125/server/gcode_store?count=2000" -TimeoutSec 20
    Select-StoreSince $r.result.gcode_store $g $t
}

function Get-ResultFiles {
    @(Get-MoonrakerFiles -Ip $Ip -Root 'config' | Where-Object { $_.path -like 'ShakeTune_results/*' } |
        ForEach-Object { [pscustomobject]@{ path = $_.path; modified = $_.modified; size = $_.size } })
}

# Chay mot lenh do: gui, M400, cho, doc phan hoi + file ket qua moi.
function Invoke-Measure([string]$g) {
    Assert-Idle | Out-Null
    $t0 = Get-StoreLastTime
    $before = @{}; foreach ($f in (Get-ResultFiles)) { $before[$f.path] = "$($f.modified)/$($f.size)" }
    Send-Gcode $g
    Send-Gcode 'M400'
    Wait-Done
    Start-Sleep 5   # Shake&Tune ve bieu do sau khi lenh tra ve
    $st = Get-StoreSince $g $t0
    if (-not $st.Found) { throw "[$Printer] gcode_store khong co lenh '$g': lenh co the chua toi may" }
    $msgs = @($st.Messages)
    $new = @(Get-ResultFiles | Where-Object { -not $before.ContainsKey($_.path) -or $before[$_.path] -ne "$($_.modified)/$($_.size)" } | ForEach-Object { $_.path })
    if ($msgs.Count -eq 0 -and $new.Count -eq 0) { throw "[$Printer] khong doc duoc phan hoi hay file ket qua nao cho: $g" }
    [pscustomobject]@{ messages = $msgs; files = $new; raw = @($msgs | Select-Object -Last 20) }
}

function Get-SimilarityPct($m) {
    foreach ($line in $m.messages) {
        if ($line -match '(?i)similarit\w*\D{0,40}?(\d+(?:\.\d+)?)\s*%') { return [double]$Matches[1] }
    }
    foreach ($f in $m.files) {   # du phong: ten file ket qua (chua kiem chung dinh dang)
        if ($f -match '(?i)simil\w*[_-]?(\d+(?:[._]\d+)?)') { return [double](($Matches[1]) -replace '_', '.') }
    }
    $null
}

function Get-Recommendation($m) {
    foreach ($line in $m.messages) {
        if ($line -match '(?i)recommended\s+shaper') {
            $o = [ordered]@{ dong = $line.Trim(); loai = $null; tan_so_hz = $null }
            if ($line -match '(?i)recommended\s+shaper(?:_type_[xy])?\s*(?:is|=)\s*(\w+)\s*(?:@|,\s*shaper_freq_[xy]\s*=)\s*([\d.]+)') {
                $o.loai = $Matches[1]; $o.tan_so_hz = [double]$Matches[2]
            }
            return $o
        }
    }
    $null
}

function Get-Median([double[]]$v) {
    if ($v.Count -eq 0) { return $null }
    $s = @($v | Sort-Object); $n = $s.Count
    if ($n % 2 -eq 1) { $s[($n - 1) / 2] } else { ($s[$n / 2 - 1] + $s[$n / 2]) / 2 }
}

# --- kiem tien quyet ---
$s = Assert-Idle
Write-Output "[$Printer] ready, khong in. extruder=$($s.extruder.temperature) bed=$($s.heater_bed.temperature) homed='$($s.toolhead.homed_axes)'"
function Assert-Cold($st) {
    $e = $st.extruder.temperature; $b = $st.heater_bed.temperature
    if ($Condition -eq 'cold' -and ($null -eq $e -or $null -eq $b -or $e -ge $ColdMax -or $b -ge $ColdMax)) {
        throw "[$Printer] chua nguoi hoac khong doc duoc nhiet (dau $e, ban $b; nguong $ColdMax C)"
    }
}
Assert-Cold $s
$needHome = ($s.toolhead.homed_axes -ne 'xyz')
if (-not $BedClear) { throw "[$Printer] can -BedClear: phep do dua dau in xuong Z=20 mm o giua ban (resonance_tester probe_points: TRI 125,125,20; V24 150,128,20). Ban phai trong, roi chay lai voi -BedClear" }
$version = (Get-MoonrakerInfo -Ip $Ip).software_version
$temps = [ordered]@{ dau_phun_c = $s.extruder.temperature; ban_c = $s.heater_bed.temperature }

$result = [ordered]@{
    thoi_diem = (Get-Date).ToString('o'); may = $Printer; phase = $Phase; dieu_kien = $Condition
    phien_ban_klipper = $version; nhiet_luc_do = $temps
    so_lan = $Repeats; lan_so_dai = @(); trung_vi_pct = $null
    shaper_x = $null; shaper_y = $null; ghi_chu = @(); hoan_tat = $false
}
try {
    if ($needHome) {
        $t0 = Get-StoreLastTime
        Send-Gcode 'G28'; Send-Gcode 'M400'; Wait-Done
        if (-not (Get-StoreSince 'G28' $t0).Found) { throw "[$Printer] gcode_store khong co G28: lenh co the chua toi may" }
        Assert-Cold (Assert-Idle)
    }

    $runs = @()
    for ($i = 1; $i -le $Repeats; $i++) {
        $m = Invoke-Measure 'COMPARE_BELTS_RESPONSES FREQ_END=200'
        $p = Get-SimilarityPct $m
        $runs += [ordered]@{ lan = $i; do_giong_pct = $p; tep_ket_qua = $m.files; phan_hoi_tho = $m.raw }
        Write-Output "[$Printer] lan $i : do giong = $p ; $($m.files.Count) file moi"
    }
    $result.lan_so_dai = $runs
    $vals = @($runs | Where-Object { $null -ne $_.do_giong_pct } | ForEach-Object { [double]$_.do_giong_pct })
    $result.trung_vi_pct = Get-Median $vals
    if ($vals.Count -lt $Repeats) { $result.ghi_chu += 'Khong doc duoc so % cho moi lan: doc bieu do bang tay.' }

    foreach ($ax in 'X', 'Y') {
        $m = Invoke-Measure "AXES_SHAPER_CALIBRATION AXIS=$ax FREQ_END=200"
        $o = [ordered]@{ tep_ket_qua = $m.files; phan_hoi_tho = $m.raw; khuyen_nghi = (Get-Recommendation $m) }
        if ($ax -eq 'X') { $result.shaper_x = $o } else { $result.shaper_y = $o }
        if ($null -eq $o.khuyen_nghi) { $result.ghi_chu += "Khong thay khuyen nghi shaper $ax trong phan hoi: doc bieu do bang tay." }
    }
    $result.hoan_tat = $true
    $target = $outFile
} catch {
    $result.ghi_chu += "LOI: $($_.Exception.Message)"
    $target = $outFile -replace '\.json$', ('.incomplete-' + (Get-Date -Format yyyyMMddHHmmss) + '.json')
    Write-Output "[$Printer] LOI giua chung, ghi ket qua do dang: $target"
}
New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
[IO.File]::WriteAllText($target, ((ConvertTo-Json -InputObject $result -Depth 8) + "`n"), (New-Object Text.UTF8Encoding($false)))
Write-Output "[$Printer] da ghi $target ; trung vi = $($result.trung_vi_pct)"
if (-not $result.hoan_tat) { exit 1 }
