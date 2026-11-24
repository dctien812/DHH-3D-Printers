# aggregate.ps1 - merges calibration\entry\part\*.csv (hand-entered caliper measurements of the
# standard parts) into calibration\results.csv (docs\data-formats.md, table 3) and prints a summary
# of the pairs (machine, filament) that are out of tolerance, with an XY scale suggestion.
#
# One entry file = one print of the part for one pair. Columns of an entry file (see TEMPLATE_part.csv):
#   máy, nhựa, cuộn, ngày, vòng, X1,X2,X3, Y1,Y2,Y3, Z1[,Z2,Z3], lỗ1[,lỗ2,lỗ3], lắp_chéo, lắp_chéo_với, ghi_chú
# vòng = print round of the pair, 1 = first print (before any compensation).
# Files whose name starts with TEMPLATE are skipped.
# Tolerance: X/Y +-0.1 mm on 100; Z +-0.1 mm on 20; hole +-0.15 mm on 8.
# Writes the file as UTF-8 with BOM (Excel-friendly); Import-Csv -Encoding UTF8 reads it either way.
# PowerShell 5.1. Source file is UTF-8 with BOM (Vietnamese column names).
[CmdletBinding()]
param(
    [string]$EntryDir = '',   # default: <repo>\calibration\entry\part
    [string]$OutFile = '',    # default: <repo>\calibration\results.csv
    [string]$MaterialsFile = ''   # default: <repo>\profiles\src\materials.csv (valid filament codes and pairs)
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
if (-not $EntryDir) { $EntryDir = Join-Path $repo 'calibration\entry\part' }
if (-not $OutFile) { $OutFile = Join-Path $repo 'calibration\results.csv' }
if (-not (Test-Path -LiteralPath $EntryDir)) { throw "EntryDir not found: $EntryDir" }

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$machines = 'TRI', 'V24', 'H2S', 'P1S', 'A1', 'A1M'
if (-not $MaterialsFile) { $MaterialsFile = Join-Path $repo 'profiles\src\materials.csv' }
if (-not (Test-Path -LiteralPath $MaterialsFile)) { throw "Cannot read materials table: $MaterialsFile" }
$mat = @(Import-Csv -LiteralPath $MaterialsFile -Encoding UTF8)
if ($mat.Count -eq 0 -or $null -eq $mat[0].PSObject.Properties['máy'] -or $null -eq $mat[0].PSObject.Properties['nhựa']) { throw "Materials table is empty or lacks columns 'máy', 'nhựa': $MaterialsFile" }
$filaments = @($mat | ForEach-Object { ([string]$_.'nhựa').Trim().ToUpperInvariant() } | Where-Object { $_ } | Select-Object -Unique)
$pairs = @{}; foreach ($m in $mat) { $pairs[(([string]$m.'máy').Trim().ToUpperInvariant()) + '|' + (([string]$m.'nhựa').Trim().ToUpperInvariant())] = $true }$dims = @(
    @{ Name = 'X'; Nominal = 100.0; Tol = 0.1; Keys = 'X1', 'X2', 'X3'; Min = 3 },
    @{ Name = 'Y'; Nominal = 100.0; Tol = 0.1; Keys = 'Y1', 'Y2', 'Y3'; Min = 3 },
    @{ Name = 'Z'; Nominal = 20.0; Tol = 0.1; Keys = 'Z1', 'Z2', 'Z3'; Min = 1 },
    @{ Name = 'lỗ'; Nominal = 8.0; Tol = 0.15; Keys = 'lỗ1', 'lỗ2', 'lỗ3'; Min = 1 }
)

function Format-Num($v) {
    if ($null -eq $v) { return '' }
    return ([double]$v + 0.0).ToString('0.####', $inv)
}
function Format-CsvField([string]$s) {
    if ($s -match '[",\r\n]') { return '"' + $s.Replace('"', '""') + '"' }
    return $s
}
function Get-Cell($row, [string]$name) {
    $prop = $row.PSObject.Properties[$name]
    if ($null -eq $prop -or $null -eq $prop.Value) { return '' }
    return ([string]$prop.Value).Trim()
}

$columns = 'máy', 'nhựa', 'cuộn', 'X', 'Y', 'Z', 'lỗ', 'đạt', 'ngày',
    'vòng', 'mới_nhất', 'lệch_X', 'lệch_Y', 'lệch_Z', 'lệch_lỗ', 'đạt_X', 'đạt_Y', 'đạt_Z', 'đạt_lỗ',
    'bù_X_pct', 'bù_Y_pct', 'lắp_chéo', 'lắp_chéo_với', 'file'

$rows = New-Object System.Collections.ArrayList
$errors = 0
$files = @(Get-ChildItem -LiteralPath $EntryDir -Filter '*.csv' -File | Where-Object { $_.Name -notlike 'TEMPLATE*' } | Sort-Object Name)
foreach ($f in $files) {
    try {
        $in = @(Import-Csv -LiteralPath $f.FullName -Encoding UTF8)
        if ($in.Count -ne 1) { throw "expected exactly 1 data row, found $($in.Count)" }
        $r = $in[0]
        $machine = Get-Cell $r 'máy'; $fil = Get-Cell $r 'nhựa'; $spool = Get-Cell $r 'cuộn'; $date = Get-Cell $r 'ngày'
        if ($machines -notcontains $machine) { throw "bad machine code '$machine'" }
        if ($filaments -notcontains $fil) { throw "bad filament code '$fil'" }
        if (-not $pairs.ContainsKey($machine + '|' + $fil)) { throw "pair $fil on $machine is not in $MaterialsFile" }
        if (-not $spool) { throw 'missing cuộn' }
        if ($date -notmatch '^\d{4}-\d{2}-\d{2}$') { throw "date '$date' is not YYYY-MM-DD" }
        $round = 0
        if (-not [int]::TryParse((Get-Cell $r 'vòng'), [ref]$round) -or $round -lt 1) { throw 'vòng must be an integer >= 1' }
        $out = @{ 'máy' = $machine; 'nhựa' = $fil; 'cuộn' = $spool; 'ngày' = $date; 'vòng' = $round; 'file' = $f.Name }
        $allPass = $true
        foreach ($d in $dims) {
            $vals = @()
            foreach ($k in $d.Keys) {
                $s = Get-Cell $r $k
                if ($s -eq '') { continue }
                $v = 0.0
                if (-not [double]::TryParse($s, [System.Globalization.NumberStyles]::Float, $inv, [ref]$v)) { throw "$k '$s' is not a number" }
                $vals += $v
            }
            if ($vals.Count -lt $d.Min) { throw "$($d.Name): need at least $($d.Min) measurements, got $($vals.Count)" }
            if ($vals.Count -ne 1 -and $vals.Count -ne 3) { throw "$($d.Name): need 1 or 3 measurements, got $($vals.Count)" }
            $mean = ($vals | Measure-Object -Average).Average
            $dev = $mean - $d.Nominal
            $ok = ([math]::Round([math]::Abs($dev), 6) -le $d.Tol)
            if (-not $ok) { $allPass = $false }
            $out[$d.Name] = [math]::Round($mean, 3)
            $out['lệch_' + $d.Name] = [math]::Round($dev, 3)
            $out['đạt_' + $d.Name] = $(if ($ok) { 'đạt' } else { 'không' })
        }
        $out['đạt'] = $(if ($allPass) { 'đạt' } else { 'không' })
        $out['bù_X_pct'] = [math]::Round(100.0 * 100.0 / $out['X'], 2)
        $out['bù_Y_pct'] = [math]::Round(100.0 * 100.0 / $out['Y'], 2)
        $out['lắp_chéo'] = Get-Cell $r 'lắp_chéo'
        $out['lắp_chéo_với'] = Get-Cell $r 'lắp_chéo_với'
        $rows.Add($out) | Out-Null
    } catch {
        $errors++
        Write-Warning "$($f.Name): $($_.Exception.Message) - file skipped"
    }
}

# newest round per pair: highest vòng, then latest ngày, then file name
foreach ($grp in ($rows | Group-Object { $_['máy'] + '|' + $_['nhựa'] })) {
    $newest = @($grp.Group | Sort-Object { $_['vòng'] }, { $_['ngày'] }, { $_['file'] })[-1]
    foreach ($row in $grp.Group) { $row['mới_nhất'] = $(if ([object]::ReferenceEquals($row, $newest)) { 'có' } else { 'không' }) }
}

$sorted = @($rows | Sort-Object { $_['máy'] }, { $_['nhựa'] }, { $_['vòng'] }, { $_['ngày'] })
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add(($columns -join ','))
foreach ($row in $sorted) {
    $cells = foreach ($c in $columns) {
        $v = $row[$c]
        if ($v -is [double] -or $v -is [int]) { Format-Num $v } else { Format-CsvField ([string]$v) }
    }
    $lines.Add(($cells -join ','))
}
$outDir = Split-Path -Parent $OutFile
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
[System.IO.File]::WriteAllText($OutFile, (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding($true)))

# summary
$newestRows = @($sorted | Where-Object { $_['mới_nhất'] -eq 'có' })
$bad = @($newestRows | Where-Object { $_['đạt'] -eq 'không' })
"Entries read: $($rows.Count) from $($files.Count) file(s), skipped with errors: $errors. Pairs: $($newestRows.Count), out of tolerance (newest round): $($bad.Count). Written: $OutFile"
foreach ($row in $bad) {
    $parts = @()
    foreach ($d in $dims) {
        if ($row['đạt_' + $d.Name] -eq 'không') {
            $parts += ('{0} mean {1} (dev {2:+0.000;-0.000} mm, tol +-{3})' -f $d.Name, (Format-Num $row[$d.Name]), $row['lệch_' + $d.Name], $d.Tol)
        }
    }
    '{0} / {1} round {2}: {3}' -f $row['máy'], $row['nhựa'], $row['vòng'], ($parts -join '; ')
    $sug = @()
    if ($row['đạt_X'] -eq 'không') { $sug += ('X scale {0:0.00}% (100 / {1})' -f $row['bù_X_pct'], (Format-Num $row['X'])) }
    if ($row['đạt_Y'] -eq 'không') { $sug += ('Y scale {0:0.00}% (100 / {1})' -f $row['bù_Y_pct'], (Format-Num $row['Y'])) }
    if ($sug.Count -gt 0) { '    suggested XY compensation (apply on top of the current profile value): ' + ($sug -join ', ') }
}
if ($errors -gt 0) { exit 1 }
