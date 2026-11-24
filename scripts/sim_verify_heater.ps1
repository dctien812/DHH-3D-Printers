param([string[]]$Files, [string]$Heater = 'heater_bed')
# Replays the heater temperature/target trace from klippy.log "Stats" lines through a
# re-implementation of Klipper's verify_heater check_event(), for several parameter sets.

$sets = @(
    @{ name = 'current 5/500/1/120'; hyst = 5.0; maxerr = 500.0; gain = 1.0; cgt = 120.0 },
    @{ name = 'klipper 5/120/2/60';  hyst = 5.0; maxerr = 120.0; gain = 2.0; cgt = 60.0 },
    @{ name = 'cand 5/120/1/120';    hyst = 5.0; maxerr = 120.0; gain = 1.0; cgt = 120.0 },
    @{ name = 'cand 5/200/1/90';     hyst = 5.0; maxerr = 200.0; gain = 1.0; cgt = 90.0 },
    @{ name = 'cand 5/250/1/120';    hyst = 5.0; maxerr = 250.0; gain = 1.0; cgt = 120.0 },
    @{ name = 'cand 5/120/2/90';     hyst = 5.0; maxerr = 120.0; gain = 2.0; cgt = 90.0 }
)
function New-State { @{ approaching = $false; starting = $false; last_target = 0.0; goal_temp = 0.0; goal_time = [double]::MaxValue; error = 0.0; peak = 0.0; faults = 0; stops = 0 } }
$states = @{}; foreach ($s in $sets) { $states[$s.name] = New-State }

$rx = [regex]("^Stats ([\d.]+):.*?\b" + [regex]::Escape($Heater) + ": target=([\d.]+) temp=([\d.]+)")
$lines = 0; $heatups = 0; $prevTarget = 0.0; $restarts = 0
$minRate = @{}
foreach ($f in $Files) {
    foreach ($line in [System.IO.File]::ReadLines($f)) {
        if ($line.StartsWith('Start printer at')) {
            $restarts++
            foreach ($s in $sets) { $states[$s.name] = New-State }
            continue
        }
        if (-not $line.StartsWith('Stats ')) { continue }
        $m = $rx.Match($line); if (-not $m.Success) { continue }
        $lines++
        $t = [double]$m.Groups[1].Value; $target = [double]$m.Groups[2].Value; $temp = [double]$m.Groups[3].Value
        if ($target -gt 0 -and $target -ne $prevTarget) { $heatups++ }
        $prevTarget = $target
        foreach ($s in $sets) {
            $st = $states[$s.name]
            if ($temp -ge ($target - $s.hyst) -or $target -le 0) {
                $st.approaching = $false; $st.starting = $false
                if ($temp -le ($target + $s.hyst)) { $st.error = 0.0 }
                $st.last_target = $target
                continue
            }
            $st.error += ($target - $s.hyst) - $temp
            if (-not $st.approaching) {
                if ($target -ne $st.last_target) {
                    $st.approaching = $true; $st.starting = $true
                    $st.goal_temp = $temp + $s.gain; $st.goal_time = $t + $s.cgt
                } else {
                    if ($st.error -gt $st.peak) { $st.peak = $st.error }
                    if ($st.error -ge $s.maxerr) { $st.faults++; $st.error = 0.0; $st.last_target = -1 }
                }
            } elseif ($temp -ge $st.goal_temp) {
                $st.starting = $false; $st.error = 0.0
                $st.goal_temp = $temp + $s.gain; $st.goal_time = $t + $s.cgt
            } elseif ($t -ge $st.goal_time) {
                $st.approaching = $false; $st.stops++
            } elseif ($st.starting) {
                $st.goal_temp = [math]::Min($st.goal_temp, $temp + $s.gain)
            }
            if ($st.last_target -ne -1) { $st.last_target = $target } else { $st.last_target = $target }
        }
    }
}
"samples=$lines heatup_target_changes=$heatups restarts=$restarts"
foreach ($s in $sets) { $st = $states[$s.name]; "{0,-22} would_fault={1,3}  approach_stalls={2,3}  peak_error_not_approaching={3,8:N1}" -f $s.name, $st.faults, $st.stops, $st.peak }
