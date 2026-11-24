param([string]$File)
# Temperature tracking during the last completed SD print in a klippy.log:
# for each heater, the longest constant-target segment after the temperature first reached
# the target: min/max deviation, RMS and the max power seen.
$lines = [IO.File]::ReadAllLines($File)
$start = -1; $end = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) { if ($end -lt 0 -and $lines[$i] -like 'Finished SD card print*') { $end = $i }; if ($end -ge 0 -and $lines[$i] -like 'Starting SD card print*') { $start = $i; break } }
if ($start -lt 0) { "no completed print found"; return }
foreach ($heater in 'extruder', 'heater_bed') {
    $rx = [regex]("\b" + $heater + ": target=([\d.]+) temp=([\d.]+) pwm=([\d.]+)")
    $segs = @(); $cur = $null
    for ($i = $start; $i -le $end; $i++) {
        if (-not $lines[$i].StartsWith('Stats ')) { continue }
        $m = $rx.Match($lines[$i]); if (-not $m.Success) { continue }
        $tg = [double]$m.Groups[1].Value; $tp = [double]$m.Groups[2].Value; $pw = [double]$m.Groups[3].Value
        if ($null -eq $cur -or $cur.target -ne $tg) { if ($cur) { $segs += $cur }; $cur = @{ target = $tg; reached = $false; d = New-Object System.Collections.Generic.List[double]; pmax = 0.0 } }
        if ($tg -le 0) { continue }
        if (-not $cur.reached -and [math]::Abs($tp - $tg) -le 1.0) { $cur.reached = $true }
        if ($cur.reached) { $cur.d.Add($tp - $tg); if ($pw -gt $cur.pmax) { $cur.pmax = $pw } }
    }
    if ($cur) { $segs += $cur }
    $best = $segs | Where-Object { $_.d.Count -gt 0 } | Sort-Object { $_.d.Count } -Descending | Select-Object -First 1
    if (-not $best) { "${heater}: no settled segment"; continue }
    $arr = $best.d.ToArray(); $rms = [math]::Sqrt(($arr | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum / $arr.Count)
    $within1 = ($arr | Where-Object { [math]::Abs($_) -le 1.0 }).Count / $arr.Count * 100
    "{0,-10} target {1,5} C for {2,5} s: min {3,6:N2}  max {4,6:N2}  RMS {5,5:N2} C  within +-1C {6,5:N1}%  max power {7:N2}" -f $heater, $best.target, $arr.Count, ($arr | Measure-Object -Minimum).Minimum, ($arr | Measure-Object -Maximum).Maximum, $rms, $within1, $best.pmax
}
