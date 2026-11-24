<#
.SYNOPSIS
  Kiem ke ho so nguoi dung cu cua OrcaSlicer (chi doc) va ghi profiles\old_inventory.csv.
.DESCRIPTION
  Doc {machine,filament,process} (de quy, gom filament\base\) trong thu muc nguon.
  Mac dinh nguon la ban sao luu moi nhat trong profiles\orca_backup\<ngay>\<id>\ de khong cham thu muc that.
  Khong ghi gi ngoai file CSV dau ra.
.PARAMETER SourceDir  Thu muc chua machine\, filament\, process\ (mac dinh: ban sao luu moi nhat).
.PARAMETER OutCsv     File CSV dau ra (mac dinh profiles\old_inventory.csv).
#>
[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$OutCsv
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
if (-not $OutCsv) { $OutCsv = Join-Path $root 'profiles\old_inventory.csv' }
if (-not $SourceDir) {
    $day = Get-ChildItem (Join-Path $root 'profiles\orca_backup') -Directory | Sort-Object Name | Select-Object -Last 1
    $SourceDir = (Get-ChildItem $day.FullName -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'machine') } | Select-Object -First 1).FullName
}
if (-not (Test-Path (Join-Path $SourceDir 'machine'))) { throw "Khong thay machine\ trong $SourceDir" }

function Read-Json($p) { Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json }
function First-Val($j, $k) {
    $p = $j.PSObject.Properties[$k]
    if (-not $p) { return '' }
    $v = @($p.Value)[0]
    if ($null -eq $v -or "$v" -eq 'nil') { return '' }
    return "$v"
}

# Suy ra ma may tu ten (A1mini phai kiem truoc A1; P1S truoc P1P)
function Get-Machine($n) {
    if ($n -match 'Trident') { return 'TRI' }
    if ($n -match '^2\.4\b|Voron 2\.4') { return 'V24' }
    if ($n -match 'H2S') { return 'H2S' }
    if ($n -match '(?i)A1\s*mini') { return 'A1M' }
    if ($n -match '\bA1\b') { return 'A1' }
    if ($n -match 'P1S') { return 'P1S' }
    if ($n -match 'P1P') { return 'P1P' }
    return ''
}
function Get-Brand($n) {
    if ($n -match '(?i)sunlu') { return 'SUNLU' }
    if ($n -match '(?i)huti') { return 'HUTI' }
    if ($n -match '(?i)fiberon') { return 'Fiberon' }
    if ($n -match '^R3D') { return 'R3D' }
    if ($n -match '(?i)tinmorry') { return 'Tinmorry' }
    return ''
}
function Get-Kind($n) {
    if ($n -match 'ASA-CF') { return 'ASA-CF' }
    if ($n -match 'PETG\s+CF') { return 'PETG-CF' }
    if ($n -match 'TPU') { return 'TPU' }
    if ($n -match 'ASA') { return 'ASA' }
    if ($n -match 'ABS') { return 'ABS' }
    if ($n -match 'PETG\s*-?ECO') { return 'PETG-ECO' }
    if ($n -match 'PETG') { return 'PETG' }
    if ($n -match 'PLA') { return 'PLA' }
    return ''
}
# ma nhua gan nhat trong 22 cap (de tinh thieu cap); chi cho ho so trong pham vi
function Get-ResinCode($kind, $brand) {
    switch ($kind) {
        'PLA'      { return 'BAMBU-PLA' }
        'PETG-ECO' { return 'TIN-PETGECO' }
        'ABS'      { if ($brand -eq 'Tinmorry') { return 'TIN-ABSPRO' } }
    }
    return ''
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($type in 'machine', 'filament', 'process') {
    $dir = Join-Path $SourceDir $type
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in Get-ChildItem $dir -Recurse -File -Filter *.json) {
        $j = Read-Json $f.FullName
        $name = "$($j.name)"
        $rel = $f.FullName.Substring($SourceDir.Length).TrimStart('\')
        $r = [ordered]@{
            'tên' = $name; 'loại' = ''; 'tệp' = $rel; 'hãng' = ''; 'loại_nhựa' = ''; 'máy' = ''; 'mã_nhựa' = ''
            'phạm_vi' = 'trong'; 'lý_do' = ''; 'trùng' = ''; 'thiếu_cặp' = ''
            'shrink_xy' = ''; 'flow_ratio' = ''; 'mvs' = ''; 'pa' = ''; 'inherits' = "$($j.inherits)"
        }
        switch ($type) {
            'machine' {
                $r['loại'] = 'máy'; $r['máy'] = Get-Machine $name
            }
            'process' {
                $r['loại'] = 'quy_trình'; $r['máy'] = if ($name -match 'Voron') { 'TRI;V24' } else { Get-Machine $name }
            }
            'filament' {
                $r['loại'] = 'vật_liệu'
                $r['hãng'] = Get-Brand $name
                $r['loại_nhựa'] = Get-Kind $name
                $r['máy'] = Get-Machine $name
                $r['mã_nhựa'] = Get-ResinCode $r['loại_nhựa'] $r['hãng']
                $s = First-Val $j 'filament_shrink'
                $r['shrink_xy'] = $s.TrimEnd('%')
                $r['flow_ratio'] = First-Val $j 'filament_flow_ratio'
                $r['mvs'] = First-Val $j 'filament_max_volumetric_speed'
                $r['pa'] = First-Val $j 'pressure_advance'
                $why = @()
                if ($r['hãng'] -in 'SUNLU', 'HUTI', 'R3D') { $why += "hãng $($r['hãng'])" }
                if ($r['loại_nhựa'] -in 'TPU', 'ASA-CF') { $why += "loại $($r['loại_nhựa'])" }
                if ($r['loại_nhựa'] -in 'ASA', 'PETG-CF') { $why += "loại $($r['loại_nhựa']) không thuộc 4 nhựa" }
                if ($r['máy'] -eq 'P1P') { $why += 'máy P1P không thuộc 6 máy' }
                if ($why.Count) { $r['phạm_vi'] = 'ngoài'; $r['lý_do'] = $why -join '; ' }
            }
        }
        $rows.Add([pscustomobject]$r)
    }
}

# trung: cung (hang, loai_nhua, may), chi xet ho so vat lieu trong pham vi
$fil = $rows | Where-Object { $_.'loại' -eq 'vật_liệu' -and $_.'phạm_vi' -eq 'trong' }
foreach ($g in ($fil | Group-Object { "$($_.'hãng')|$($_.'loại_nhựa')|$($_.'máy')" } | Where-Object Count -gt 1)) {
    foreach ($x in $g.Group) { $x.'trùng' = (($g.Group | Where-Object { $_ -ne $x } | ForEach-Object { $_.'tên' }) -join '; ') }
}
# thieu cap: voi moi may, ma nhua (trong 22 cap hop le) chua co ho so cu
$valid = @{
    TRI = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO', 'TIN-ABSPRO'; V24 = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO', 'TIN-ABSPRO'
    H2S = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO', 'TIN-ABSPRO'; P1S = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO', 'TIN-ABSPRO'
    A1 = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO'; A1M = 'BAMBU-PLA', 'BAMBU-PETG', 'TIN-PETGECO'
}
foreach ($m in $rows | Where-Object { $_.'loại' -eq 'máy' }) {
    if ($valid.ContainsKey($m.'máy')) {
        $have = @($fil | Where-Object { $_.'máy' -eq $m.'máy' } | ForEach-Object { $_.'mã_nhựa' })
        $m.'thiếu_cặp' = (@($valid[$m.'máy'] | Where-Object { $_ -notin $have }) -join ';')
    }
}

# ghi CSV UTF-8 khong BOM
function Q($v) { $s = "$v"; if ($s -match '[",\r\n]') { '"' + $s.Replace('"', '""') + '"' } else { $s } }
$cols = $rows[0].PSObject.Properties.Name
$lines = @(($cols | ForEach-Object { Q $_ }) -join ',')
foreach ($r in $rows | Sort-Object { @('máy', 'vật_liệu', 'quy_trình').IndexOf($_.'loại') }, 'tên') {
    $lines += (($cols | ForEach-Object { Q $r.$_ }) -join ',')
}
[IO.File]::WriteAllLines($OutCsv, $lines, (New-Object Text.UTF8Encoding $false))

$cnt = $rows | Group-Object 'loại' | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Output ("Ghi {0}: {1}" -f $OutCsv, ($cnt -join ', '))
Write-Output ("Ngoai pham vi: {0}" -f (@($rows | Where-Object { $_.'phạm_vi' -eq 'ngoài' }).Count))
