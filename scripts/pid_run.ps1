param([string]$Ip, [double]$ExtTemp = 270, [double]$BedTemp = 110, [string]$OutJson, [int]$MaxMinutesPerHeater = 45)
# Runs PID_CALIBRATE for the hotend, then the bed, on one printer through Moonraker.
# No motion. Reads the recommended values from the G-code responses and writes them to JSON.
# Any error or timeout switches all heaters off.
$ErrorActionPreference = 'Stop'
function Q($path, $t = 10) { Invoke-RestMethod -Uri "http://${Ip}:7125$path" -TimeoutSec $t }
function G($script, $t = 30) { Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125/printer/gcode/script?script=$([uri]::EscapeDataString($script))" -TimeoutSec $t }
$results = [ordered]@{ ip = $Ip; started = (Get-Date).ToString('s') }
try {
    $st = (Q '/printer/objects/query?print_stats=state').result.status.print_stats.state
    if ($st -in 'printing', 'paused') { throw "printer is $st - not calibrating" }
    foreach ($h in @(@('extruder', $ExtTemp), @('heater_bed', $BedTemp))) {
        $name = $h[0]; $target = [double]$h[1]
        $s = (Q '/printer/objects/query?extruder=temperature&heater_bed=temperature&temperature_sensor%20Chamber=temperature').result.status
        $marker = @((Q '/server/gcode_store?count=1').result.gcode_store)[-1].time
        $t0 = Get-Date
        "[$($t0.ToString('HH:mm:ss'))] $Ip PID_CALIBRATE HEATER=$name TARGET=$target (start $([math]::Round($s.$name.temperature,1))C, chamber $([math]::Round($s.'temperature_sensor Chamber'.temperature,1))C)"
        $clientErr = $null
        try { G "PID_CALIBRATE HEATER=$name TARGET=$target" ($MaxMinutesPerHeater * 60) | Out-Null }
        catch { $clientErr = $_.Exception.Message }
        if ($clientErr) {
            # The request can drop or time out while Klipper keeps calibrating: wait for the
            # heater target to return to 0, which marks the end of PID_CALIBRATE.
            $deadline = $t0.AddMinutes($MaxMinutesPerHeater)
            while ((Get-Date) -lt $deadline) {
                try { $tg = (Q "/printer/objects/query?$name=target").result.status.$name.target; if ($tg -eq 0) { break } } catch {}
                Start-Sleep -Seconds 10
            }
            if ((Get-Date) -ge $deadline) { throw "PID_CALIBRATE on $name did not finish within $MaxMinutesPerHeater min ($clientErr)" }
        }
        $store = @((Q '/server/gcode_store?count=300').result.gcode_store | Where-Object { $_.time -gt $marker })
        $err = $store | Where-Object { $_.type -eq 'response' -and $_.message -match '^!!' } | Select-Object -Last 1
        if ($err) { throw "Klipper error during $name calibration: $($err.message)" }
        $msg = ($store | Where-Object { $_.message -match 'pid_Kp=' } | Select-Object -Last 1).message
        if (-not $msg) { throw "no PID result found for $name (client: $clientErr)" }
        $m = [regex]::Match($msg, 'pid_Kp=([\d.]+)\s+pid_Ki=([\d.]+)\s+pid_Kd=([\d.]+)')
        $secs = [int]((Get-Date) - $t0).TotalSeconds
        $results[$name] = [ordered]@{ kp = [double]$m.Groups[1].Value; ki = [double]$m.Groups[2].Value; kd = [double]$m.Groups[3].Value; target = $target; start_temp = [math]::Round($s.$name.temperature, 1); chamber = [math]::Round($s.'temperature_sensor Chamber'.temperature, 1); seconds = $secs }
        "   -> pid_Kp=$($m.Groups[1].Value) pid_Ki=$($m.Groups[2].Value) pid_Kd=$($m.Groups[3].Value)  ($secs s)"
    }
    $results.status = 'ok'
} catch {
    $results.status = "error: $($_.Exception.Message)"
    "ERROR: $($_.Exception.Message) - switching heaters off"
    try { G 'TURN_OFF_HEATERS' | Out-Null } catch { "TURN_OFF_HEATERS failed: $($_.Exception.Message)" }
} finally {
    $results.finished = (Get-Date).ToString('s')
    if ($OutJson) { $results | ConvertTo-Json -Depth 4 | Set-Content -Path $OutJson -Encoding utf8 }
    $tg = $null; try { $tg = (Q '/printer/objects/query?extruder=target&heater_bed=target').result.status; "heater targets now: extruder=$($tg.extruder.target) bed=$($tg.heater_bed.target)" } catch {}
}
