<#
.SYNOPSIS
  Gop calibration\entry\cal\*.csv (va tuy chon profiles\old_inventory.csv) vao calibration\voron.csv va bambu.csv
  theo docs\data-formats.md (Bang 2). Chay lai nhieu lan cho cung ket qua.
.PARAMETER Inherit
  Doc them profiles\old_inventory.csv (neu co), them dong ke_thua co nguon.
#>
param(
    [string]$EntryDir,
    [string]$OutDir,
    [switch]$Inherit,
    [string]$InheritFile,
    [string]$MaterialsFile   # bang nguon: ma nhua va cap (may, nhua) hop le
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $EntryDir) { $EntryDir = Join-Path $root 'calibration\entry\cal' }
if (-not $OutDir) { $OutDir = Join-Path $root 'calibration' }
if (-not $MaterialsFile) { $MaterialsFile = Join-Path $root 'profiles\src\materials.csv' }
if (-not $InheritFile) { $InheritFile = Join-Path $root 'profiles\old_inventory.csv' }

$Machines = @('TRI', 'V24', 'H2S', 'P1S', 'A1', 'A1M')
$VoronM = @('TRI', 'V24')
# Ma nhua va cap hop le lay tu bang nguon; khong doc duoc thi dung han (khong quay ve danh sach cu).
if (-not (Test-Path -LiteralPath $MaterialsFile)) { throw "Khong doc duoc bang vat lieu: $MaterialsFile" }
$mat = @(Import-Csv -LiteralPath $MaterialsFile -Encoding UTF8)
if ($mat.Count -eq 0 -or -not ($mat[0].PSObject.Properties.Name -contains 'máy' -and $mat[0].PSObject.Properties.Name -contains 'nhựa')) { throw "Bang vat lieu rong hoac thieu cot 'máy', 'nhựa': $MaterialsFile" }
$Resins = @($mat | ForEach-Object { ([string]$_.'nhựa').Trim().ToUpperInvariant() } | Where-Object { $_ } | Select-Object -Unique)
$Pairs = @{}; foreach ($m in $mat) { $Pairs[(([string]$m.'máy').Trim().ToUpperInvariant()) + '|' + (([string]$m.'nhựa').Trim().ToUpperInvariant())] = $true }$Params = @('pa', 'k', 'flow_ratio', 'mvs', 'shrink_xy', 'temp_nozzle')
$cMay = 'máy'; $cResin = 'nhựa'; $cParam = 'tham_số'; $cVal = 'giá_trị'; $cUnit = 'đơn_vị'
$cStat = 'trạng_thái'; $cSrc = 'nguồn'; $cDate = 'ngày'; $cSpool = 'cuộn'; $cCond = 'điều_kiện'
$Cols = @($cMay, $cResin, $cParam, $cVal, $cUnit, $cStat, $cSrc, $cDate, $cSpool, $cCond)
$sMeasured = 'đo'; $sInherit = 'kế_thừa'; $sDefault = 'mặc_định'; $sNone = 'chưa_đo'
$Rank = @{ $sMeasured = 3; $sInherit = 2; $sDefault = 1; $sNone = 0 }

$errors = New-Object System.Collections.ArrayList
$rows = New-Object System.Collections.ArrayList

function Add-Err([string]$file, [int]$line, [string]$msg) { [void]$errors.Add("${file}:${line}: $msg") }
function Get-Field($r, [string]$c) { $v = $r.$c; if ($null -eq $v) { '' } else { ([string]$v).Trim() } }

function Read-Rows([string]$path, [bool]$inherited) {
    $name = Split-Path $path -Leaf
    $data = @(Import-Csv -LiteralPath $path -Encoding UTF8)
    if ($data.Count -eq 0) { return }
    $have = @($data[0].PSObject.Properties.Name)
    $need = if ($inherited) { @($cMay, $cResin, $cParam, $cVal) } else { $Cols }
    $missing = @($need | Where-Object { $have -notcontains $_ })
    if ($missing.Count -gt 0) { Add-Err $name 1 "thieu cot: $($missing -join ', ')"; return }
    $n = 1
    foreach ($r in $data) {
        $n++   # dong 1 la tieu de
        $f = @{}; foreach ($c in $Cols) { $f[$c] = Get-Field $r $c }
        $f[$cMay] = $f[$cMay].ToUpperInvariant(); $f[$cResin] = $f[$cResin].ToUpperInvariant(); $f[$cParam] = $f[$cParam].ToLowerInvariant(); $f[$cStat] = $f[$cStat].ToLowerInvariant()
        if ($inherited) {
            $f[$cStat] = $sInherit
            if (-not $f[$cSrc]) { $f[$cSrc] = 'profiles\old_inventory.csv' }
        }
        $bad = $false
        foreach ($c in $Cols) { if ($f[$c] -like 'ĐIỀN*') { Add-Err $name $n "cot $c con gia tri mau '$($f[$c])'"; $bad = $true } }
        if ($Machines -notcontains $f[$cMay]) { Add-Err $name $n "ma may la: '$($f[$cMay])'"; $bad = $true }
        if ($Resins -notcontains $f[$cResin]) { Add-Err $name $n "ma nhua la: '$($f[$cResin])'"; $bad = $true }
        if ($Params -notcontains $f[$cParam]) { Add-Err $name $n "tham so la: '$($f[$cParam])'"; $bad = $true }
        if (-not $Rank.ContainsKey($f[$cStat])) { Add-Err $name $n "trang thai khong hop le: '$($f[$cStat])'"; $bad = $true }
        if ($bad) { continue }
        if (-not $Pairs.ContainsKey($f[$cMay] + '|' + $f[$cResin])) {
            Add-Err $name $n "cap khong hop le: $($f[$cResin]) tren $($f[$cMay])"; continue
        }
        if ($f[$cStat] -eq $sMeasured) {
            foreach ($c in @($cSrc, $cDate, $cSpool)) { if (-not $f[$c]) { Add-Err $name $n "dong 'do' thieu cot $c"; $bad = $true } }
        }
        if ($f[$cStat] -eq $sInherit -and -not $f[$cSrc]) { Add-Err $name $n "dong 'ke_thua' thieu nguon (cap goc)"; $bad = $true }
        if ($f[$cDate]) {
            $d = [datetime]::MinValue
            if (-not [datetime]::TryParseExact($f[$cDate], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$d)) {
                Add-Err $name $n "ngay sai dang YYYY-MM-DD: '$($f[$cDate])'"; $bad = $true
            } elseif ($d.Date -gt (Get-Date).Date) { Add-Err $name $n "ngay o tuong lai: '$($f[$cDate])'"; $bad = $true }
        }
        if ($f[$cStat] -eq $sNone) {
            if ($f[$cVal]) { Add-Err $name $n "dong 'chua_do' phai de trong gia tri"; $bad = $true }
        } else {
            $x = 0.0
            if (-not [double]::TryParse($f[$cVal], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$x) -or [double]::IsNaN($x) -or [double]::IsInfinity($x)) {
                Add-Err $name $n "gia tri khong phai so (dau cham thap phan): '$($f[$cVal])'"; $bad = $true
            }
        }
        if ($bad) { continue }
        [void]$rows.Add([pscustomobject]@{ F = $f; Order = $rows.Count })
    }
}

# --- doc dau vao ---
if (-not (Test-Path -LiteralPath $EntryDir)) { throw "Khong co thu muc entry: $EntryDir" }
$files = @(Get-ChildItem -LiteralPath $EntryDir -Filter '*.csv' -File | Where-Object { $_.Name -notlike 'TEMPLATE*' } | Sort-Object Name)
foreach ($fi in $files) { Read-Rows $fi.FullName $false }
if ($Inherit) {
    if (Test-Path -LiteralPath $InheritFile) { Read-Rows $InheritFile $true }
    else { Write-Output "Khong co $InheritFile, bo qua -Inherit." }
}
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    [Console]::Error.WriteLine("TU CHOI: $($errors.Count) loi. Khong ghi file nao.")
    exit 1
}

# --- gop: moi (may, nhua, tham so) giu dong ngay moi nhat; hoa thi trang thai cao hon, roi file/dong sau ---
$best = @{}
foreach ($r in $rows) {
    $k = "$($r.F[$cMay])|$($r.F[$cResin])|$($r.F[$cParam])"
    if (-not $best.ContainsKey($k)) { $best[$k] = $r; continue }
    $o = $best[$k]
    # dong 'do' luon thang dong khac trang thai; giua hai dong cung loai thi ngay moi nhat thang
    $cmp = [int]($r.F[$cStat] -eq $sMeasured) - [int]($o.F[$cStat] -eq $sMeasured)
    if ($cmp -eq 0) { $cmp = [string]::CompareOrdinal($r.F[$cDate], $o.F[$cDate]) }
    if ($cmp -eq 0) { $cmp = $Rank[$r.F[$cStat]] - $Rank[$o.F[$cStat]] }
    if ($r.F[$cStat] -eq $sMeasured -and $o.F[$cStat] -eq $sMeasured -and $r.F[$cDate] -eq $o.F[$cDate] -and $r.F[$cVal] -ne $o.F[$cVal]) {
        Write-Warning "2 dong 'do' cung khoa $k, cung ngay $($r.F[$cDate]), khac gia tri ($($o.F[$cVal]) vs $($r.F[$cVal])): lay dong sau"
    }
    if ($cmp -eq 0) { $cmp = $r.Order - $o.Order }
    if ($cmp -gt 0) { $best[$k] = $r }
}
$final = @($best.Values | Sort-Object { [array]::IndexOf($Machines, $_.F[$cMay]) }, { [array]::IndexOf($Resins, $_.F[$cResin]) }, { [array]::IndexOf($Params, $_.F[$cParam]) })

function ConvertTo-CsvLine($f) {
    ($Cols | ForEach-Object { $v = $f[$_]; if ($v -match '[",\r\n]') { '"' + ($v -replace '"', '""') + '"' } else { $v } }) -join ','
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$enc = New-Object Text.UTF8Encoding($false)
$pending = @()
foreach ($t in @(@{ N = 'voron.csv'; M = $VoronM }, @{ N = 'bambu.csv'; M = @('H2S', 'P1S', 'A1', 'A1M') })) {
    $lines = @($Cols -join ',') + @($final | Where-Object { $t.M -contains $_.F[$cMay] } | ForEach-Object { ConvertTo-CsvLine $_.F })
    $tmp = (Join-Path $OutDir $t.N) + '.tmp'
    try { [IO.File]::WriteAllText($tmp, (($lines -join "`n") + "`n"), $enc) } catch { $pending | ForEach-Object { Remove-Item -LiteralPath $_.Tmp -ErrorAction SilentlyContinue }; Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue; throw }   # ghi tam ca hai file roi moi doi ten
    $pending += @{ Tmp = $tmp; Dst = (Join-Path $OutDir $t.N); Count = $lines.Count - 1 }
}
foreach ($x in $pending) { Move-Item -LiteralPath $x.Tmp -Destination $x.Dst -Force; Write-Output "Ghi $($x.Dst): $($x.Count) dong" }

# --- tong ket ---
Write-Output ("{0,-5} {1,5} {2,8} {3,9} {4,7}" -f 'may', $sMeasured, $sInherit, $sDefault, $sNone)
foreach ($m in $Machines) {
    $mine = @($final | Where-Object { $_.F[$cMay] -eq $m })
    $c = { param($s) @($mine | Where-Object { $_.F[$cStat] -eq $s }).Count }
    Write-Output ("{0,-5} {1,5} {2,8} {3,9} {4,7}" -f $m, (& $c $sMeasured), (& $c $sInherit), (& $c $sDefault), (& $c $sNone))
}
