param([string]$Ip, [string]$Name, [int[]]$Accels = @(10000, 12000), [int]$Speed = 400, [int]$Iterations = 5)
# Ellis-style skipped-step test sent as plain G-code (no macro needed on the printer):
# home, read the MCU step counters, run the pattern, home again, read the counters again.
$base = "http://${Ip}:7125"
function G([string]$script, [int]$timeout = 900) { Invoke-RestMethod -Method Post "$base/printer/gcode/script" -Body (@{ script = $script } | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec $timeout | Out-Null }
function McuPos {
    $marker = "TS_MARK_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    G "M400`nG4 P1000`nRESPOND MSG=`"$marker`"`nGET_POSITION"
    Start-Sleep 2
    $st = (Invoke-RestMethod "$base/server/gcode_store?count=60" -TimeoutSec 20).result.gcode_store
    $seen = $false
    foreach ($e in $st) { if ($e.message -match $marker) { $seen = $true }; if ($seen -and $e.message -match 'mcu: (.*)') { $line = ($e.message -split "`n" | Where-Object { $_ -match '^(// )?mcu:' } | Select-Object -First 1); $h = @{}; foreach ($mm in [regex]::Matches($line, '(stepper_\w+):(-?\d+)')) { $h[$mm.Groups[1].Value] = [long]$mm.Groups[2].Value }; return $h } }
    throw "[$Name] no GET_POSITION answer found"
}
$q = (Invoke-RestMethod "$base/printer/objects/query?print_stats&webhooks&toolhead&configfile=settings" -TimeoutSec 20).result.status
if ($q.webhooks.state -ne 'ready' -or $q.print_stats.state -in 'printing', 'paused') { throw "[$Name] not idle" }
$c = $q.configfile.settings; $us = [int]$c.stepper_x.microsteps
$xmax = [double]$q.toolhead.axis_maximum[0]; $ymax = [double]$q.toolhead.axis_maximum[1]
$b = 20; $x0 = $b; $y0 = $b; $x1 = $xmax - $b; $y1 = $ymax - $b; $cx = $xmax / 2; $cy = $ymax / 2
$a0 = $cx - 10; $a1 = $cx + 10; $b0 = $cy - 10; $b1 = $cy + 10; $F = $Speed * 60
$restore = "SET_VELOCITY_LIMIT VELOCITY=$($c.printer.max_velocity) ACCEL=$($c.printer.max_accel) MINIMUM_CRUISE_RATIO=$($c.printer.minimum_cruise_ratio)"
$park = "G28 X Y`nG90`nG0 X$($xmax - 1) Y$($ymax - 1) F1800"
Write-Output "[$Name] microsteps=$us run_current_x=$($c.'tmc2209 stepper_x'.run_current)$($c.'tmc5160 stepper_x'.run_current) area=${x0}..${x1} x ${y0}..${y1} speed=$Speed"
if ($q.toolhead.homed_axes -ne 'xyz') { G 'G28' }
G "G90`nG0 Z30 F600"
foreach ($accel in $Accels) {
    try {
        G $park; $before = McuPos
        $pat = @("SET_VELOCITY_LIMIT VELOCITY=$Speed ACCEL=$accel MINIMUM_CRUISE_RATIO=0.5", "G0 X$x0 Y$y0 F$F")
        for ($i = 0; $i -lt $Iterations; $i++) {
            $pat += "G0 X$x0 Y$y0 F$F", "G0 X$x1 Y$y1", "G0 X$x0 Y$y0", "G0 X$x1 Y$y0", "G0 X$x0 Y$y1", "G0 X$x1 Y$y0"
            $pat += "G0 X$x0 Y$y0", "G0 X$x0 Y$y1", "G0 X$x1 Y$y1", "G0 X$x1 Y$y0"
            $pat += "G0 X$a0 Y$b0", "G0 X$a1 Y$b1", "G0 X$a0 Y$b0", "G0 X$a1 Y$b0", "G0 X$a0 Y$b1", "G0 X$a1 Y$b0"
            $pat += "G0 X$a0 Y$b0", "G0 X$a0 Y$b1", "G0 X$a1 Y$b1", "G0 X$a1 Y$b0"
        }
        $pat += 'M400', $restore
        G ($pat -join "`n")
        G $park; $after = McuPos
        $dx = $after.stepper_x - $before.stepper_x; $dy = $after.stepper_y - $before.stepper_y
        $res = 'PASS'; if ([math]::Abs($dx) -gt $us -or [math]::Abs($dy) -gt $us) { $res = 'FAIL (skipped steps)' }
        Write-Output "[$Name] accel=$accel stepper_x $($before.stepper_x) -> $($after.stepper_x) (diff $dx)  stepper_y $($before.stepper_y) -> $($after.stepper_y) (diff $dy)  limit +-$us  => $res"
        if ($res -ne 'PASS') { break }
    }
    catch { Write-Output "[$Name] accel=$accel ERROR: $($_.Exception.Message)"; try { G $restore } catch {}; break }
}
try { G $restore } catch {}
$s = (Invoke-RestMethod "$base/printer/objects/query?webhooks&toolhead" -TimeoutSec 20).result.status
Write-Output "[$Name] end: klippy=$($s.webhooks.state) max_accel_now=$($s.toolhead.max_accel) max_velocity_now=$($s.toolhead.max_velocity)"
