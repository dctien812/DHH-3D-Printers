# Phep thu cuc bo cho Select-StoreSince / Get-StoreSince trong scripts\voron\measure.ps1. Khong goi mang.
# Chay: powershell -NoProfile -File tests\measure\store-since.tests.ps1
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot '..\..\scripts\voron\measure.ps1'
$errs = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $src).Path, [ref]$null, [ref]$errs)
foreach ($name in 'Select-StoreSince', 'Get-StoreSince') {
    $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
    if (-not $fn) { throw "khong thay ham $name" }
    . ([scriptblock]::Create($fn.Extent.Text))
}

# gia lap Moonraker: ham trung ten che cmdlet, khong co ket noi that
$Ip = '0.0.0.0'
$script:FakeStore = @()
function Invoke-RestMethod { [pscustomobject]@{ result = [pscustomobject]@{ gcode_store = $script:FakeStore } } }

function E($msg, $time, $type) { [pscustomobject]@{ message = $msg; time = [double]$time; type = $type } }
$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Output "PASS  $name" } else { Write-Output "FAIL  $name"; $script:fail++ }
}

# Ca 1: khong co muc khop lenh -> chua toi may
$script:FakeStore = @((E 'G90' 101 'command'), (E 'ok' 102 'response'))
$r = Get-StoreSince 'G28' 100
Check 'ca1 khong khop: Found=false' ($r.Found -eq $false)
Check 'ca1 Messages la mang rong' ($r.Messages -is [array] -and $r.Messages.Count -eq 0)

# Ca 2: G28 da toi, 0 phan hoi -> Found=true, luong G28 di tiep (dieu kien dong throw = false)
$script:FakeStore = @((E 'G28' 101 'command'), (E 'M400' 102 'command'))
$r = Get-StoreSince 'G28' 100
Check 'ca2 G28 khong phan hoi: Found=true' ($r.Found -eq $true)
Check 'ca2 0 phan hoi' (@($r.Messages).Count -eq 0)
$threw = $false
try { if (-not (Get-StoreSince 'G28' 100).Found) { throw 'chua toi may' } } catch { $threw = $true }
Check 'ca2 dieu kien G28 khong throw' (-not $threw)

# Ca 3: 3 phan hoi, xen M400 va mot muc command khac
$g = 'COMPARE_BELTS_RESPONSES FREQ_END=200'
$script:FakeStore = @(
    (E 'old line' 99 'response'),
    (E $g 101 'command'),
    (E 'a: 1' 102 'response'),
    (E 'M400' 103 'command'),
    (E 'b: 2' 104 'response'),
    (E 'G90' 105 'command'),
    (E '' 106 'response'),
    (E 'c: 3' 107 'response'))
$r = Get-StoreSince $g 100
Check 'ca3 Found=true' ($r.Found -eq $true)
Check 'ca3 dung 3 dong' (@($r.Messages).Count -eq 3 -and ($r.Messages -join '|') -eq 'a: 1|b: 2|c: 3')

# Ca 4: lenh xuat hien hai lan -> lay lan cuoi
$script:FakeStore = @(
    (E $g 101 'command'), (E 'first' 102 'response'),
    (E $g 103 'command'), (E 'second' 104 'response'))
$r = Get-StoreSince $g 100
Check 'ca4 lay lan cuoi' ($r.Found -and @($r.Messages).Count -eq 1 -and $r.Messages[0] -eq 'second')

# Ca 5: dung mot phan hoi (mang mot phan tu khong bi bien thanh chuoi)
$script:FakeStore = @((E $g 101 'command'), (E 'only' 102 'response'))
$r = Get-StoreSince $g 100
Check 'ca5 mot phan hoi van la mang' ($r.Messages -is [array] -and $r.Messages.Count -eq 1)

# Ca 6: store rong / null, lenh cu hon $t bi bo
$script:FakeStore = $null
Check 'ca6 store null: Found=false' ((Get-StoreSince 'G28' 100).Found -eq $false)
$script:FakeStore = @((E 'G28' 50 'command'))
Check 'ca6 lenh cu hon t0: Found=false' ((Get-StoreSince 'G28' 100).Found -eq $false)

Write-Output "Tong: $fail that bai"
if ($fail) { exit 1 }
