<#
.SYNOPSIS
  Sinh bo ho so OrcaSlicer "DHH" (JSON) tu profiles\src\*.csv va profiles\src\base\.
.DESCRIPTION
  Chi sinh file .json (khong .info, khong setting_id/user_id/base_id). Dau ra chia thanh
  <OutDir>\machine\, <OutDir>\filament\, <OutDir>\process\.
  Them goi import: <OutDir>\import\DHH_printer.zip, DHH_filament.zip, DHH_process.zip (moi zip chua cac .json cung loai,
  de nhap bang File > Import). Dinh dang CHUA thu nhap tren Orca that.
  So 'do' trong calibration\voron.csv va calibration\bambu.csv (neu co) thang so trong materials.csv.
  NGOAI LE mvs: neu materials.csv co mvs voi mvs_trang_thai = 'do' thi giu so do (muc dat sau bien an toan), khong lay tu calibration.
.PARAMETER Set       pilot = 6 may + 6 quy trinh + 4 vat lieu BAMBU-PLA (16 file); all = 6 + 6 + 20 (32 file).
.PARAMETER OutDir    Thu muc dau ra (mac dinh profiles\bundle). Duong dan tuong doi tinh tu thu muc goc du an.
.PARAMETER Verify    Doc lai JSON da sinh, so tung gia tri voi bang nguon, in bang lech; thoat 1 neu co lech.
.PARAMETER Install   Chep file MOI vao %APPDATA%\OrcaSlicer\user\<id>. Tu choi neu Orca dang chay hoac file da ton tai
                     (tru file ten bat dau "DHH " khi co -Force). Chay -Verify truoc.
.PARAMETER Uninstall Xoa chi cac file ten bat dau "DHH " (.json/.info) trong machine\, filament\, process\ cua user.
.PARAMETER UserDir   Thu muc user can ghi/xoa/doc (mac dinh: %APPDATA%\OrcaSlicer\user\<id> that). Moi thao tac ghi/xoa chi trong day.
                     Voi -Verify, doc ho so da cai trong UserDir thay vi OutDir. Kiem Orca-dang-chay chi ap dung khi UserDir nam trong %APPDATA%\OrcaSlicer.
.PARAMETER UserId    Thu muc <id> cua Orca khi co nhieu hon mot.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('pilot', 'all')][string]$Set = 'pilot',
    [string]$OutDir,
    [switch]$Verify,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Force,
    [string]$UserId,
    [string]$UserDir
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
$src = Join-Path $root 'profiles\src'
$OrcaVersion = '2.5.1.0'      # khoa "version" cho ho so khong co ban nen (chua kiem: xem bao cao)
$Prefix = 'DHH '
if (-not $OutDir) { $OutDir = Join-Path $root 'profiles\bundle' }
elseif (-not [IO.Path]::IsPathRooted($OutDir)) { $OutDir = Join-Path $root $OutDir }
$Forbidden = 'setting_id', 'user_id', 'base_id'
$PerVariant = 'filament_flow_ratio', 'filament_max_volumetric_speed', 'nozzle_temperature', 'nozzle_temperature_initial_layer',
    'fan_max_speed', 'fan_min_speed', 'filament_retraction_length', 'enable_pressure_advance', 'pressure_advance'
$Params = 'pa', 'flow_ratio', 'mvs', 'shrink_xy', 'temp_nozzle'
$Status = 'đo', 'kế_thừa', 'mặc_định', 'chưa_đo'

# ---------- JSON ----------
function ConvertTo-JsonString([string]$s) {
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append('"')
    foreach ($ch in $s.ToCharArray()) {
        $c = [int]$ch
        if ($c -eq 34) { [void]$sb.Append('\"') }
        elseif ($c -eq 92) { [void]$sb.Append('\\') }
        elseif ($c -eq 10) { [void]$sb.Append('\n') }
        elseif ($c -eq 13) { [void]$sb.Append('\r') }
        elseif ($c -eq 9) { [void]$sb.Append('\t') }
        elseif ($c -lt 32) { [void]$sb.AppendFormat('\u{0:x4}', $c) }
        else { [void]$sb.Append($ch) }
    }
    [void]$sb.Append('"')
    $sb.ToString()
}
function ConvertTo-OrcaJson($dict) {
    $keys = [string[]]@($dict.Keys)
    [Array]::Sort($keys, [StringComparer]::Ordinal)
    $parts = foreach ($k in $keys) {
        $v = $dict[$k]
        if ($v -is [array]) {
            if ($v.Count -eq 0) { $vs = '[]' }
            else { $vs = "[`n" + ((@($v) | ForEach-Object { "`t`t" + (ConvertTo-JsonString "$_") }) -join ",`n") + "`n`t]" }
        }
        else { $vs = ConvertTo-JsonString "$v" }
        "`t" + (ConvertTo-JsonString $k) + ': ' + $vs
    }
    "{`n" + ($parts -join ",`n") + "`n}`n"
}
function Read-Base($rel) {
    $p = Join-Path $src "base\$rel"
    if (-not (Test-Path -LiteralPath $p)) { throw "Thieu file nen $p" }
    $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
    $d = [ordered]@{}
    foreach ($pr in $j.PSObject.Properties) {
        if ($Forbidden -contains $pr.Name) { continue }
        if ($pr.Value -is [array]) { $d[$pr.Name] = [string[]]@($pr.Value | ForEach-Object { "$_" }) }
        else { $d[$pr.Name] = "$($pr.Value)" }
    }
    $d
}
function New-Rep([string]$v, [int]$n) { , [string[]]@(1..$n | ForEach-Object { $v }) }
function Get-Csv($name) { @(Import-Csv -LiteralPath (Join-Path $src $name) -Encoding UTF8) }

# ---------- bang hieu chuan: so 'do' thang ----------
function Read-Cal {
    $res = @{}
    foreach ($f in 'voron.csv', 'bambu.csv') {
        $p = Join-Path $root "calibration\$f"
        if (-not (Test-Path $p)) { continue }
        foreach ($row in Import-Csv -LiteralPath $p -Encoding UTF8) {
            if ($row.'trạng_thái' -ne 'đo') { continue }
            if ($Params -notcontains $row.'tham_số') { continue }
            if (-not $row.'giá_trị' -or -not $row.'nguồn' -or -not $row.'ngày' -or -not $row.'cuộn') {
                Write-Warning "$f : dong 'đo' thieu gia_tri/nguon/ngay/cuon, bo qua ($($row.'máy') $($row.'nhựa') $($row.'tham_số'))"
                continue
            }
            $k = "$($row.'máy')|$($row.'nhựa')|$($row.'tham_số')"
            if (-not $res.ContainsKey($k) -or [string]$row.'ngày' -ge [string]$res[$k].'ngày') { $res[$k] = $row }
        }
    }
    $res
}

# ---------- ke hoach ----------
function Get-Plan {
    $machines = Get-Csv 'machines.csv'
    $procs = Get-Csv 'process.csv'
    $mats = Get-Csv 'materials.csv'
    $cal = Read-Cal
    $byCode = @{}
    foreach ($mr in $machines) { $byCode[$mr.'máy'] = $mr }
    $names = @($machines + $procs + $mats | ForEach-Object { $_.'tên_hồ_sơ' })
    if (($names | Select-Object -Unique).Count -ne $names.Count) { throw 'Ten ho so bi trung trong bang nguon' }
    foreach ($n in $names) { if (-not $n.StartsWith($Prefix)) { throw "Ten khong bat dau bang '$Prefix': $n" } }
    $plan = New-Object System.Collections.Generic.List[object]

    foreach ($mr in $machines) {
        $d = Read-Base $mr.'tệp_nền'
        $d['from'] = 'User'; $d['name'] = $mr.'tên_hồ_sơ'; $d['inherits'] = $mr.'cha'
        $d['printer_settings_id'] = $mr.'tên_hồ_sơ'
        $plan.Add([pscustomobject]@{ Type = 'machine'; Name = $mr.'tên_hồ_sơ'; Code = $mr.'máy'; Class = $mr.'loại'; Pilot = $true; Data = $d })
    }
    foreach ($pr in $procs) {
        $mr = $byCode[$pr.'máy']
        if ($pr.'tệp_nền') { $d = Read-Base $pr.'tệp_nền' } else { $d = [ordered]@{ version = $OrcaVersion } }
        $d['from'] = 'User'; $d['name'] = $pr.'tên_hồ_sơ'; $d['inherits'] = $pr.'cha'
        $d['print_settings_id'] = $pr.'tên_hồ_sơ'
        $d['compatible_printers'] = [string[]]@($mr.'tên_hồ_sơ')
        $plan.Add([pscustomobject]@{ Type = 'process'; Name = $pr.'tên_hồ_sơ'; Code = $pr.'máy'; Class = $mr.'loại'; Pilot = $true; Data = $d })
    }
    foreach ($row in $mats) {
        $mr = $byCode[$row.'máy']
        if (-not $mr) { throw "May khong co trong machines.csv: $($row.'máy')" }
        if ($row.'nhựa' -eq 'TIN-ABSPRO' -and $row.'máy' -in 'A1', 'A1M') { throw "Khong duoc co ABS cho $($row.'máy')" }
        if ($row.'nhựa' -eq 'BAMBU-PLA' -and $mr.'loại' -eq 'voron') { throw "PLA chi cho may Bambu: $($row.'tên_hồ_sơ')" }
        $n = @($mr.'biến_thể' -split '\|').Count
        $v = @{}
        foreach ($p in $Params) {
            $val = $row.$p; $st = $row."${p}_trạng_thái"; $so = $row."${p}_nguồn"
            if ($Status -notcontains $st) { throw "$($row.'tên_hồ_sơ'): $p trang_thai khong hop le '$st'" }
            if ($val -and ($st -eq 'chưa_đo' -or -not $so)) { throw "$($row.'tên_hồ_sơ'): $p co so nhung thieu trang_thai/nguon" }
            $ck = "$($row.'máy')|$($row.'nhựa')|$p"
            # mvs: phieu ghi gioi han do duoc, materials.csv ghi muc dat sau bien an toan; co 'đo' + so thi giu materials.csv
            $keepMvs = ($p -eq 'mvs' -and $val -and $st -eq 'đo')
            if ($cal.ContainsKey($ck) -and -not $keepMvs) { $val = $cal[$ck].'giá_trị' }
            $v[$p] = $val
        }
        # Bambu: K do may quan ly, khong dat pressure_advance. Ngoai le: P1S (chi hieu chuan K tay) khi pa co trang thai 'đo' (chu may chot 2026-11-26)
        if ($mr.'loại' -ne 'voron' -and -not ($row.'máy' -eq 'P1S' -and $row.'pa_trạng_thái' -eq 'đo')) { $v['pa'] = '' }
        $d = [ordered]@{
            from = 'User'; name = $row.'tên_hồ_sơ'; inherits = $row.'cha'; version = $OrcaVersion
            filament_settings_id = [string[]]@($row.'tên_hồ_sơ')
            compatible_printers = [string[]]@($mr.'tên_hồ_sơ')
            filament_extruder_variant = [string[]]@($mr.'biến_thể' -split '\|')
        }
        if ($v['flow_ratio']) { $d['filament_flow_ratio'] = New-Rep $v['flow_ratio'] $n }
        if ($v['mvs']) { $d['filament_max_volumetric_speed'] = New-Rep $v['mvs'] $n }
        if ($v['temp_nozzle']) { $d['nozzle_temperature'] = New-Rep $v['temp_nozzle'] $n }
        if ($v['shrink_xy']) { $d['filament_shrink'] = [string[]]@("$($v['shrink_xy'])%") }
        if ($v['pa']) {
            $d['enable_pressure_advance'] = New-Rep '1' $n
            $d['pressure_advance'] = New-Rep $v['pa'] $n
        }
        if ($row.'khác') {
            foreach ($kv in ($row.'khác' -split ';')) {
                $i = $kv.IndexOf('=')
                if ($i -lt 1) { throw "$($row.'tên_hồ_sơ'): khac sai dang '$kv'" }
                $k = $kv.Substring(0, $i); $val = $kv.Substring($i + 1)
                if ($d.Contains($k)) { throw "$($row.'tên_hồ_sơ'): khoa '$k' bi dat hai lan" }
                if ($Forbidden -contains $k) { throw "Khoa cam: $k" }
                if ($val.Contains('|')) {
                    $arr = [string[]]@($val -split '\|')
                    if ($arr.Count -ne $n) { throw "$($row.'tên_hồ_sơ'): khoa '$k' co $($arr.Count) gia tri, can $n" }
                    $d[$k] = $arr
                }
                elseif ($PerVariant -contains $k) { $d[$k] = New-Rep $val $n } else { $d[$k] = [string[]]@($val) }
            }
        }
        $plan.Add([pscustomobject]@{ Type = 'filament'; Name = $row.'tên_hồ_sơ'; Code = "$($row.'máy')|$($row.'nhựa')"; Class = $mr.'loại'; Pilot = ($row.'nhựa' -eq 'BAMBU-PLA'); Data = $d })
    }
    if ($Set -eq 'pilot') { return @($plan | Where-Object { $_.Pilot }) }
    return $plan.ToArray()
}

# ---------- ten ho so he thong (de kiem inherits) ----------
function Get-SystemNames {
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    $dir = Join-Path $env:APPDATA 'OrcaSlicer\system'
    if (-not (Test-Path $dir)) { return $set }
    foreach ($f in Get-ChildItem $dir -File -Filter *.opc) {
        $t = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($f.FullName))
        foreach ($m in [regex]::Matches($t, '(machine|filament|process)/([\x20-\x7e]{3,120}?)\.json')) {
            [void]$set.Add($m.Groups[1].Value + '/' + ($m.Groups[2].Value -split '/')[-1])
        }
    }
    $set
}

function Format-Val($v) {
    if ($v -is [array]) { return 'A:' + (($v | ForEach-Object { "$_" }) -join '|') }
    return 'S:' + "$v"
}

function Test-Plan($plan, [string]$Root, [switch]$UserMode) {
    $sys = Get-SystemNames
    $diff = New-Object System.Collections.Generic.List[object]
    $add = { param($f, $k, $e, $a) $diff.Add([pscustomobject]@{ File = $f; Khoa = $k; MongDoi = $e; ThucTe = $a }) }
    $want = @{}
    foreach ($it in $plan) {
        $rel = "$($it.Type)\$($it.Name).json"
        $want[$rel.ToLowerInvariant()] = $true
        $p = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $p)) { & $add $rel '(file)' 'co' 'thieu'; continue }
        try { $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch { & $add $rel '(file)' 'JSON hop le' $_.Exception.Message; continue }
        $actual = @{}
        foreach ($pr in $j.PSObject.Properties) { $actual[$pr.Name] = $pr.Value }
        foreach ($k in $it.Data.Keys) {
            if (-not $actual.ContainsKey($k)) { & $add $rel $k (Format-Val $it.Data[$k]) '(thieu khoa)'; continue }
            $e = Format-Val $it.Data[$k]; $a = Format-Val $actual[$k]
            if ($e -ne $a) { & $add $rel $k $e $a }
        }
        foreach ($k in $actual.Keys) {
            if (-not $it.Data.Contains($k)) { & $add $rel $k '(khong co)' (Format-Val $actual[$k]) }
            if ($Forbidden -contains $k) { & $add $rel $k '(cam)' 'co' }
            if ($it.Class -eq 'bambu' -and $it.Type -eq 'filament' -and $k -match '^(enable_)?pressure_advance$' -and -not $it.Data.Contains($k)) { & $add $rel $k '(Bambu khong dat PA)' (Format-Val $actual[$k]) }
        }
        if ($sys.Count -gt 0 -and -not $sys.Contains("$($it.Type)/$($actual['inherits'])")) { & $add $rel 'inherits' 'ten ho so he thong co that' "$($actual['inherits'])" }
    }
    if ($UserMode) {
        foreach ($ty in 'machine', 'filament', 'process') {
            $dd = Join-Path $Root $ty
            if (-not (Test-Path $dd)) { continue }
            foreach ($f in Get-ChildItem $dd -File | Where-Object { $_.Name -like "$Prefix*" }) {
                if (-not $want.ContainsKey("$ty\$($f.Name)".ToLowerInvariant())) { & $add "$ty\$($f.Name)" '(file)' 'khong co trong bo' 'file DHH thua' }
            }
        }
    }
    elseif (Test-Path $OutDir) {
        $imp = Join-Path $OutDir 'import'
        foreach ($f in Get-ChildItem $OutDir -Recurse -File | Where-Object { -not $_.FullName.StartsWith($imp + '\') }) {
            $rel = $f.FullName.Substring($OutDir.Length).TrimStart('\')
            if ($f.Extension -ne '.json') { & $add $rel '(file)' 'khong co' 'file khong phai .json (vd .info)' }
            elseif (-not $want.ContainsKey($rel.ToLowerInvariant())) { & $add $rel '(file)' 'khong co trong bo' 'file thua' }
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        foreach ($ty in @{ machine = 'printer'; filament = 'filament'; process = 'process' }.GetEnumerator()) {
            $zp = Join-Path $imp "DHH_$($ty.Value).zip"
            $exp = @($plan | Where-Object { $_.Type -eq $ty.Key } | ForEach-Object { "$($_.Name).json" } | Sort-Object)
            if (-not (Test-Path $zp)) { & $add "import\DHH_$($ty.Value).zip" '(file)' 'co' 'thieu'; continue }
            $za = [IO.Compression.ZipFile]::OpenRead($zp)
            try { $got = @($za.Entries | ForEach-Object { $_.Name } | Sort-Object) } finally { $za.Dispose() }
            if (($exp -join '|') -ne ($got -join '|')) { & $add "import\DHH_$($ty.Value).zip" 'noi_dung' ($exp -join '; ') ($got -join '; ') }
        }
    }
    , $diff
}

function Get-UserDir {
    if ($UserDir) {
        $ud0 = if ([IO.Path]::IsPathRooted($UserDir)) { $UserDir } else { Join-Path $root $UserDir }
        if (-not (Test-Path $ud0)) { throw "Khong thay -UserDir $ud0" }
        return (Resolve-Path $ud0).Path
    }
    $base = Join-Path $env:APPDATA 'OrcaSlicer\user'
    if ($UserId) { $d = Join-Path $base $UserId }
    else {
        $c = @(Get-ChildItem $base -Directory | Where-Object { $_.Name -ne 'default' })
        if ($c.Count -ne 1) { throw "Can chi dinh -UserId (tim thay $($c.Count) thu muc trong $base)" }
        $d = $c[0].FullName
    }
    if (-not (Test-Path $d)) { throw "Khong thay $d" }
    $d
}
function Assert-OrcaClosed {
    if ($UserDir) {
        $real = (Join-Path $env:APPDATA 'OrcaSlicer').TrimEnd('\') + '\'
        if (-not ((Get-UserDir) + '\').StartsWith($real, [StringComparison]::OrdinalIgnoreCase)) { return }
    }
    $pr = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -in 'orca-slicer', 'OrcaSlicer' })
    if ($pr.Count) { throw 'Orca dang chay (orca-slicer). Dong Orca roi chay lai.' }
}

# ---------- chay ----------
if ($Uninstall) {
    Assert-OrcaClosed
    $ud = Get-UserDir
    $n = 0
    foreach ($t in 'machine', 'filament', 'process') {
        $d = Join-Path $ud $t
        if (-not (Test-Path $d)) { continue }
        foreach ($f in Get-ChildItem $d -File | Where-Object { $_.Name -like "$Prefix*" -and $_.Extension -in '.json', '.info' }) {
            if ($PSCmdlet.ShouldProcess($f.FullName, 'Xoa')) { Remove-Item -LiteralPath $f.FullName; $n++ }
        }
    }
    Write-Output "Da xoa $n file '$Prefix*' trong $ud"
    return
}

$plan = Get-Plan
if ($Verify -or $Install) {
    if ($Verify -and $UserDir) { $diff = Test-Plan $plan (Get-UserDir) -UserMode; $where = Get-UserDir } else { $diff = Test-Plan $plan $OutDir; $where = $OutDir }
    $cnt = ($plan | Group-Object Type | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
    Write-Output "Verify -Set $Set tai ${where}: $($plan.Count) ho so ($cnt), lech = $($diff.Count)"
    if ($diff.Count) { $diff | Format-Table -AutoSize -Wrap | Out-String -Width 250 | Write-Output; if ($Verify) { exit 1 } else { throw 'Verify lech, khong cai.' } }
    if ($Verify) { return }
}
else {
    foreach ($it in $plan) {
        $dir = Join-Path $OutDir $it.Type
        New-Item -ItemType Directory -Force $dir | Out-Null
        [IO.File]::WriteAllText((Join-Path $dir "$($it.Name).json"), (ConvertTo-OrcaJson $it.Data), (New-Object Text.UTF8Encoding $false))
    }
    $imp = Join-Path $OutDir 'import'
    New-Item -ItemType Directory -Force $imp | Out-Null
    foreach ($ty in @{ machine = 'printer'; filament = 'filament'; process = 'process' }.GetEnumerator()) {
        $zp = Join-Path $imp "DHH_$($ty.Value).zip"
        if (Test-Path $zp) { Remove-Item -LiteralPath $zp }
        $files = @($plan | Where-Object { $_.Type -eq $ty.Key } | ForEach-Object { Join-Path $OutDir "$($_.Type)\$($_.Name).json" })
        Compress-Archive -LiteralPath $files -DestinationPath $zp
    }
    $cnt = ($plan | Group-Object Type | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
    Write-Output "Da sinh $($plan.Count) file .json vao $OutDir ($cnt)"
    return
}

if ($Install) {
    Assert-OrcaClosed
    $ud = Get-UserDir
    $todo = @(); $refuse = @()
    foreach ($it in $plan) {
        $dst = Join-Path $ud "$($it.Type)\$($it.Name).json"
        if (Test-Path -LiteralPath $dst) {
            if ($it.Name.StartsWith($Prefix) -and $Force) { $todo += , @($it, $dst) } else { $refuse += $dst }
        }
        else { $todo += , @($it, $dst) }
    }
    if ($refuse.Count) { throw ("Tu choi ghi de $($refuse.Count) file da ton tai (can ten 'DHH ' va -Force):`n" + ($refuse -join "`n")) }
    foreach ($t in $todo) {
        $it = $t[0]; $dst = $t[1]
        if ($PSCmdlet.ShouldProcess($dst, 'Chep file moi')) {
            New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
            Copy-Item -LiteralPath (Join-Path $OutDir "$($it.Type)\$($it.Name).json") -Destination $dst
        }
    }
    Write-Output "Da chep $($todo.Count) file vao $ud"
}
