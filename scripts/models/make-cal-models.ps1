# make-cal-models.ps1 - generates the 3 calibration STL models (spec 003 T007) into models\.
# (a) hollow frame 100x100x20, wall 2.4, +X end marked by two 5 mm corner chamfers
# (b) plate with a round hole D8 and a square hole 8x8, plus a loose round pin and square pin
# (c) overhang tower with 45/55/65 degree overhangs (angle from vertical)
# Binary STL, millimetres, Z up. After writing, each file is read back and checked:
# bounding box, triangle count, closed mesh (every edge in exactly two triangles, opposite
# directions), outward orientation (positive signed volume), frame volume vs closed formula.
# PowerShell 5.1. File is ASCII on purpose.
[CmdletBinding()]
param(
    [string]$OutDir = '',          # default: <repo>\models
    [double]$PinClearance = 0.2,   # pin diameter = 8 - PinClearance
    [int]$Segments = 128           # sides of every round feature, multiple of 4, >= 96
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($Segments -lt 96 -or ($Segments % 4) -ne 0) { throw "Segments must be a multiple of 4 and >= 96 (got $Segments)." }
if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))) 'models' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$OutDir = (Resolve-Path -LiteralPath $OutDir).Path

function New-Mesh {
    @{ V = (New-Object 'System.Collections.Generic.List[double[]]'); T = (New-Object 'System.Collections.Generic.List[int[]]') }
}

function Add-Vertex($M, [double]$x, [double]$y, [double]$z) {
    $M.V.Add([double[]]@($x, $y, $z))
    return ($M.V.Count - 1)
}

# 2D cross product of (b-a) x (p-a)
function Get-Cross2($px, $py, [int]$a, [int]$b, [double]$qx, [double]$qy) {
    return (($px[$b] - $px[$a]) * ($qy - $py[$a]) - ($py[$b] - $py[$a]) * ($qx - $px[$a]))
}

# Extrudes a CCW polygon (with optional CCW holes) from Z0 to Z1.
# Holes: array of @{P=points; Bh=index of hole vertex to bridge from; Bo=index of outer vertex to bridge to}.
function Add-Extrusion {
    param($M, $Outer, $Holes, [double]$Z0, [double]$Z1)
    $pl = New-Object System.Collections.ArrayList
    $loops = New-Object System.Collections.ArrayList
    $oi = New-Object 'System.Collections.Generic.List[int]'
    foreach ($pt in $Outer) { $oi.Add([int]$pl.Add($pt)) }
    $loops.Add($oi.ToArray()) | Out-Null
    $holeIdx = @()
    foreach ($h in $Holes) {
        $hi = New-Object 'System.Collections.Generic.List[int]'
        foreach ($pt in $h.P) { $hi.Add([int]$pl.Add($pt)) }
        $holeIdx += , $hi.ToArray()
    }
    $n = $pl.Count
    $px = New-Object 'double[]' $n; $py = New-Object 'double[]' $n
    $bid = New-Object 'int[]' $n; $tid = New-Object 'int[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $px[$i] = [double]$pl[$i][0]; $py[$i] = [double]$pl[$i][1]
        $bid[$i] = Add-Vertex $M $px[$i] $py[$i] $Z0
        $tid[$i] = Add-Vertex $M $px[$i] $py[$i] $Z1
    }
    # side walls: outer outward, holes reversed (material is outside the hole)
    $o = $oi.ToArray()
    for ($k = 0; $k -lt $o.Length; $k++) {
        $i = $o[$k]; $j = $o[($k + 1) % $o.Length]
        $M.T.Add([int[]]@($bid[$i], $bid[$j], $tid[$j])); $M.T.Add([int[]]@($bid[$i], $tid[$j], $tid[$i]))
    }
    foreach ($hi in $holeIdx) {
        for ($k = 0; $k -lt $hi.Length; $k++) {
            $i = $hi[$k]; $j = $hi[($k + 1) % $hi.Length]
            $M.T.Add([int[]]@($bid[$j], $bid[$i], $tid[$i])); $M.T.Add([int[]]@($bid[$j], $tid[$i], $tid[$j]))
        }
    }
    # ring with bridges, then ear clipping
    $ring = New-Object 'System.Collections.Generic.List[int]'
    $ring.AddRange([int[]]$o)
    for ($h = 0; $h -lt $holeIdx.Count; $h++) {
        $hi = [int[]]$holeIdx[$h]
        $rev = [int[]]$hi.Clone(); [array]::Reverse($rev)
        $hh = $hi[$Holes[$h].Bh]
        $s = [array]::IndexOf($rev, $hh)
        $seq = New-Object 'System.Collections.Generic.List[int]'
        for ($k = 0; $k -lt $rev.Length; $k++) { $seq.Add($rev[($s + $k) % $rev.Length]) }
        $seq.Add($hh)
        $bo = $o[$Holes[$h].Bo]
        $seq.Add($bo)
        $pos = $ring.IndexOf($bo)
        $ring.InsertRange($pos + 1, $seq)
    }
    $eps = 1e-9
    while ($ring.Count -gt 3) {
        $cnt = $ring.Count
        $found = $false
        for ($i = 0; $i -lt $cnt; $i++) {
            $a = $ring[($i + $cnt - 1) % $cnt]; $b = $ring[$i]; $c = $ring[($i + 1) % $cnt]
            if ((Get-Cross2 $px $py $a $b $px[$c] $py[$c]) -le $eps) { continue }
            $ok = $true
            for ($k = 0; $k -lt $cnt; $k++) {
                $q = $ring[$k]
                if ($q -eq $a -or $q -eq $b -or $q -eq $c) { continue }
                $same = $false
                foreach ($v in @($a, $b, $c)) { if ([math]::Abs($px[$q] - $px[$v]) -lt $eps -and [math]::Abs($py[$q] - $py[$v]) -lt $eps) { $same = $true } }
                if ($same) { continue }
                if ((Get-Cross2 $px $py $a $b $px[$q] $py[$q]) -ge -$eps -and (Get-Cross2 $px $py $b $c $px[$q] $py[$q]) -ge -$eps -and (Get-Cross2 $px $py $c $a $px[$q] $py[$q]) -ge -$eps) { $ok = $false; break }
            }
            if (-not $ok) { continue }
            $M.T.Add([int[]]@($tid[$a], $tid[$b], $tid[$c]))
            $M.T.Add([int[]]@($bid[$a], $bid[$c], $bid[$b]))
            $ring.RemoveAt($i)
            $found = $true
            break
        }
        if (-not $found) { throw 'Ear clipping failed (no ear found).' }
    }
    if ($ring.Count -eq 3) {
        $a = $ring[0]; $b = $ring[1]; $c = $ring[2]
        $M.T.Add([int[]]@($tid[$a], $tid[$b], $tid[$c]))
        $M.T.Add([int[]]@($bid[$a], $bid[$c], $bid[$b]))
    }
}

function Get-Circle([double]$cx, [double]$cy, [double]$r, [int]$n) {
    $pts = New-Object System.Collections.ArrayList
    for ($k = 0; $k -lt $n; $k++) {
        $ang = 2.0 * [math]::PI * $k / $n
        $pts.Add([double[]]@(($cx + $r * [math]::Cos($ang)), ($cy + $r * [math]::Sin($ang)))) | Out-Null
    }
    return , $pts.ToArray()
}

function Get-Box([double]$x0, [double]$y0, [double]$x1, [double]$y1) {
    return , @([double[]]@($x0, $y0), [double[]]@($x1, $y0), [double[]]@($x1, $y1), [double[]]@($x0, $y1))
}

function Write-Stl($M, [string]$Path) {
    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    try {
        $hdr = New-Object 'byte[]' 80
        $txt = [System.Text.Encoding]::ASCII.GetBytes('3D-Printer-Klipper calibration model (mm)')
        [array]::Copy($txt, $hdr, $txt.Length)
        $bw.Write($hdr)
        $bw.Write([uint32]$M.T.Count)
        foreach ($t in $M.T) {
            $a = $M.V[$t[0]]; $b = $M.V[$t[1]]; $c = $M.V[$t[2]]
            $ux = $b[0] - $a[0]; $uy = $b[1] - $a[1]; $uz = $b[2] - $a[2]
            $vx = $c[0] - $a[0]; $vy = $c[1] - $a[1]; $vz = $c[2] - $a[2]
            $nx = $uy * $vz - $uz * $vy; $ny = $uz * $vx - $ux * $vz; $nz = $ux * $vy - $uy * $vx
            $len = [math]::Sqrt($nx * $nx + $ny * $ny + $nz * $nz)
            if ($len -gt 0) { $nx /= $len; $ny /= $len; $nz /= $len }
            $bw.Write([single]$nx); $bw.Write([single]$ny); $bw.Write([single]$nz)
            foreach ($p in @($a, $b, $c)) { $bw.Write([single]$p[0]); $bw.Write([single]$p[1]); $bw.Write([single]$p[2]) }
            $bw.Write([uint16]0)
        }
    } finally { $bw.Close(); $fs.Close() }
}

# Reads the written file back and checks it (independent of the in-memory mesh).
function Test-StlFile([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $nTri = [int][BitConverter]::ToUInt32($bytes, 80)
    if ($bytes.Length -ne 84 + 50 * $nTri) { throw "$Path : size does not match triangle count." }
    $ids = New-Object 'System.Collections.Generic.Dictionary[string,int]'
    $pos = New-Object 'System.Collections.Generic.List[double[]]'
    $edges = New-Object 'System.Collections.Generic.Dictionary[string,int]'
    $min = @([double]::MaxValue, [double]::MaxValue, [double]::MaxValue); $max = @(-[double]::MaxValue, -[double]::MaxValue, -[double]::MaxValue)
    $vol = 0.0; $degenerate = 0
    for ($t = 0; $t -lt $nTri; $t++) {
        $o = 84 + 50 * $t + 12
        $tri = @(); $co = @()
        for ($v = 0; $v -lt 3; $v++) {
            $x = [double][BitConverter]::ToSingle($bytes, $o + 12 * $v)
            $y = [double][BitConverter]::ToSingle($bytes, $o + 12 * $v + 4)
            $z = [double][BitConverter]::ToSingle($bytes, $o + 12 * $v + 8)
            $key = '{0},{1},{2}' -f [long][math]::Round($x * 10000), [long][math]::Round($y * 10000), [long][math]::Round($z * 10000)
            if (-not $ids.ContainsKey($key)) { $ids[$key] = $pos.Count; $pos.Add([double[]]@($x, $y, $z)) }
            $tri += $ids[$key]; $co += , @($x, $y, $z)
            $c3 = @($x, $y, $z)
            for ($d = 0; $d -lt 3; $d++) { if ($c3[$d] -lt $min[$d]) { $min[$d] = $c3[$d] }; if ($c3[$d] -gt $max[$d]) { $max[$d] = $c3[$d] } }
        }
        if ($tri[0] -eq $tri[1] -or $tri[1] -eq $tri[2] -or $tri[0] -eq $tri[2]) { $degenerate++; continue }
        for ($e = 0; $e -lt 3; $e++) {
            $k = '{0}>{1}' -f $tri[$e], $tri[($e + 1) % 3]
            if ($edges.ContainsKey($k)) { $edges[$k]++ } else { $edges[$k] = 1 }
        }
        $a = $co[0]; $b = $co[1]; $c = $co[2]
        $vol += ($a[0] * ($b[1] * $c[2] - $b[2] * $c[1]) - $a[1] * ($b[0] * $c[2] - $b[2] * $c[0]) + $a[2] * ($b[0] * $c[1] - $b[1] * $c[0])) / 6.0
    }
    $bad = 0; $seen = @{}
    foreach ($k in $edges.Keys) {
        $p = $k.Split('>'); $rk = $p[1] + '>' + $p[0]
        $und = if ([int]$p[0] -lt [int]$p[1]) { $k } else { $rk }
        if ($seen.ContainsKey($und)) { continue }
        $seen[$und] = 1
        $f = $edges[$k]; $r = 0; if ($edges.ContainsKey($rk)) { $r = $edges[$rk] }
        if ($f -ne 1 -or $r -ne 1) { $bad++ }
    }
    [pscustomobject]@{
        Triangles = $nTri; Degenerate = $degenerate; BadEdges = $bad; Volume = $vol
        Size = @(($max[0] - $min[0]), ($max[1] - $min[1]), ($max[2] - $min[2]))
    }
}

$fail = $false

# ---- (a) frame -----------------------------------------------------------
$t = 2.4; $ch = 5.0; $H = 20.0
$cc = 95.0 - $t * [math]::Sqrt(2.0)      # chamfer line x -/+ y = cc of the inner offset
$ia = 50.0 - $t
$outerA = @([double[]]@(-50, -50), [double[]]@(45, -50), [double[]]@(50, -45), [double[]]@(50, 45), [double[]]@(45, 50), [double[]]@(-50, 50))
$innerA = @([double[]]@(-$ia, -$ia), [double[]]@(($cc - $ia), -$ia), [double[]]@($ia, ($ia - $cc)), [double[]]@($ia, ($cc - $ia)), [double[]]@(($cc - $ia), $ia), [double[]]@(-$ia, $ia))
$mA = New-Mesh
Add-Extrusion $mA $outerA @(@{ P = $innerA; Bh = 0; Bo = 0 }) 0 $H
$fA = Join-Path $OutDir 'cal-a-frame-100x100x20.stl'
Write-Stl $mA $fA

# ---- (b) plate + pins ----------------------------------------------------
$holeD = 8.0; $pinD = $holeD - $PinClearance; $plateT = 5.0; $pinH = 10.0
$mB = New-Mesh
$round = Get-Circle -20 0 ($holeD / 2) $Segments
$sq = Get-Box 16 -4 24 4
Add-Extrusion $mB (Get-Box -45 -20 45 20) @(@{ P = $round; Bh = ($Segments / 4); Bo = 3 }, @{ P = $sq; Bh = 2; Bo = 2 }) 0 $plateT
Add-Extrusion $mB (Get-Circle -20 35 ($pinD / 2) $Segments) @() 0 $pinH
Add-Extrusion $mB (Get-Box (20 - $pinD / 2) (35 - $pinD / 2) (20 + $pinD / 2) (35 + $pinD / 2)) @() 0 $pinH
$fB = Join-Path $OutDir 'cal-b-hole-pin.stl'
Write-Stl $mB $fB

# ---- (c) overhang tower --------------------------------------------------
$cw = 20.0; $seg = 8.0; $step = 4.0; $depth = 20.0
$x = $cw; $z = 4.0
$prof = New-Object System.Collections.ArrayList
foreach ($pt in @(@(0, 0), @($cw, 0), @($cw, $z))) { $prof.Add([double[]]$pt) | Out-Null }
foreach ($ang in 45, 55, 65) {
    $x += $seg * [math]::Tan($ang * [math]::PI / 180); $z += $seg
    $prof.Add([double[]]@($x, $z)) | Out-Null
    $z += $step
    $prof.Add([double[]]@($x, $z)) | Out-Null
}
$prof.Add([double[]]@(0, $z)) | Out-Null
$mC = New-Mesh
Add-Extrusion $mC $prof.ToArray() @() 0 $depth
# rotate (x,y,z) -> (x, depth - z, y): profile height becomes Z, proper rotation
for ($i = 0; $i -lt $mC.V.Count; $i++) { $v = $mC.V[$i]; $mC.V[$i] = [double[]]@($v[0], ($depth - $v[2]), $v[1]) }
$fC = Join-Path $OutDir 'cal-c-overhang-tower.stl'
Write-Stl $mC $fC

# ---- verify written files ------------------------------------------------
$volFormula = $H * ((10000.0 - 2 * 0.5 * $ch * $ch) - ((100 - 2 * $t) * (100 - 2 * $t) - 2 * 0.5 * [math]::Pow($ch - $t * (2 - [math]::Sqrt(2.0)), 2)))
foreach ($f in $fA, $fB, $fC) {
    $r = Test-StlFile $f
    '{0}: bbox {1:N3} x {2:N3} x {3:N3} mm, {4} triangles, open/non-manifold edges = {5}, degenerate = {6}, volume {7:N2} mm3' -f (Split-Path $f -Leaf), $r.Size[0], $r.Size[1], $r.Size[2], $r.Triangles, $r.BadEdges, $r.Degenerate, $r.Volume
    if ($r.BadEdges -ne 0 -or $r.Degenerate -ne 0 -or $r.Volume -le 0) { $fail = $true; 'FAIL: mesh not closed/outward' }
    foreach ($s in $r.Size) { if ($s -gt 120) { $fail = $true; 'FAIL: size over 120 mm' } }
    if ($f -eq $fA) {
        $pct = 100 * ($r.Volume - $volFormula) / $volFormula
        '  frame volume formula {0:N2} mm3, mesh {1:N2} mm3, difference {2:N4} %' -f $volFormula, $r.Volume, $pct
        if ([math]::Abs($pct) -ge 0.1) { $fail = $true; 'FAIL: volume off by >= 0.1 %' }
        if ([math]::Abs($r.Size[0] - 100) -gt 0.001 -or [math]::Abs($r.Size[1] - 100) -gt 0.001 -or [math]::Abs($r.Size[2] - 20) -gt 0.001) { $fail = $true; 'FAIL: frame is not 100 x 100 x 20' }
    }
}
'round features: {0} sides, hole/pin vertices on the circle (inscribed), flat-to-flat error for D8 = {1:N4} mm' -f $Segments, (8 * (1 - [math]::Cos([math]::PI / $Segments)))
'pin diameter {0:N2} mm (clearance {1:N2} mm on diameter)' -f $pinD, $PinClearance
if ($fail) { exit 1 }
