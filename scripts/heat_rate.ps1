param([string[]]$Files, [string]$Heater = 'heater_bed', [double]$Hyst = 5.0)
# For every heat-up (target set above current temp), report the slowest temperature gain over
# 60 s and 120 s windows while temp < target - hyst, plus the lowest temp seen after reaching
# the target band (sag), to size verify_heater margins.
$rx = [regex]("^Stats ([\d.]+):.*?\b" + [regex]::Escape($Heater) + ": target=([\d.]+) temp=([\d.]+) pwm=([\d.]+)")
$cur = $null; $results = @()
function Close-Heatup($h) {
    if ($null -eq $h -or $h.ts.Count -lt 5) { return $null }
    $min60 = [double]::MaxValue; $min120 = [double]::MaxValue
    for ($i = 0; $i -lt $h.ts.Count; $i++) {
        for ($j = $i; $j -lt $h.ts.Count; $j++) {
            $dt = $h.ts[$j] - $h.ts[$i]
            if ($dt -ge 60 -and $dt -lt 62) { $g = $h.temps[$j] - $h.temps[$i]; if ($g -lt $min60) { $min60 = $g } }
            if ($dt -ge 120 -and $dt -lt 122) { $g = $h.temps[$j] - $h.temps[$i]; if ($g -lt $min120) { $min120 = $g }; break }
        }
    }
    [pscustomobject]@{ start = [int]$h.ts[0]; target = $h.target; from = $h.temps[0]; secs = [int]($h.ts[-1] - $h.ts[0]); min_gain_60s = [math]::Round($min60, 2); min_gain_120s = [math]::Round($min120, 2); sag_min_after = $h.sag; maxpwm_hold = $h.pwmhold }
}
$prevTarget = 0.0
foreach ($f in $Files) {
    foreach ($line in [System.IO.File]::ReadLines($f)) {
        if (-not $line.StartsWith('Stats ')) { continue }
        $m = $rx.Match($line); if (-not $m.Success) { continue }
        $t = [double]$m.Groups[1].Value; $target = [double]$m.Groups[2].Value; $temp = [double]$m.Groups[3].Value; $pwm = [double]$m.Groups[4].Value
        if ($target -ne $prevTarget) {
            if ($cur) { $r = Close-Heatup $cur; if ($r) { $results += $r } }
            $cur = $null
            if ($target -gt 0 -and $temp -lt $target - $Hyst) { $cur = @{ ts = New-Object System.Collections.Generic.List[double]; temps = New-Object System.Collections.Generic.List[double]; target = $target; reached = $false; sag = 999.0; pwmhold = 0.0 } }
        }
        $prevTarget = $target
        if ($cur) {
            if (-not $cur.reached) {
                if ($temp -lt $target - $Hyst) { $cur.ts.Add($t); $cur.temps.Add($temp) } else { $cur.reached = $true }
            } else {
                if ($temp -lt $cur.sag) { $cur.sag = $temp }
                if ($temp -ge $target - 1 -and $pwm -gt $cur.pwmhold) { $cur.pwmhold = $pwm }
            }
        }
    }
}
if ($cur) { $r = Close-Heatup $cur; if ($r) { $results += $r } }
$results | Format-Table -AutoSize | Out-String -Width 200
