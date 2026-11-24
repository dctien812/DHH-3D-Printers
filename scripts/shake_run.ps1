param([string]$Ip, [string]$Name)
# Runs the Shake&Tune belt comparison, then an X-axis shaper test up to 200 Hz, one after the other.
function State { $q = Invoke-RestMethod "http://${Ip}:7125/printer/objects/query?print_stats&toolhead&idle_timeout&webhooks" -TimeoutSec 20; $q.result.status }
function Run([string]$g) {
    Write-Output "[$Name] $(Get-Date -Format HH:mm:ss) start: $g"
    try { Invoke-RestMethod -Method Post "http://${Ip}:7125/printer/gcode/script" -Body (@{ script = $g } | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec 1500 | Out-Null; Write-Output "[$Name] $(Get-Date -Format HH:mm:ss) done" }
    catch { Write-Output "[$Name] $(Get-Date -Format HH:mm:ss) request ended: $($_.Exception.Message)" }
    # wait until the printer is no longer busy
    for ($i = 0; $i -lt 120; $i++) { Start-Sleep 10; try { $s = State; if ($s.idle_timeout.state -ne 'Printing') { break } } catch {} }
    $s = State; Write-Output "[$Name] klippy=$($s.webhooks.state) idle=$($s.idle_timeout.state) homed='$($s.toolhead.homed_axes)'"
    if ($s.webhooks.state -ne 'ready') { throw "klippy not ready: $($s.webhooks.state_message)" }
}
$s = State
if ($s.webhooks.state -ne 'ready' -or $s.print_stats.state -in 'printing', 'paused') { throw "[$Name] not idle" }
if ($s.toolhead.homed_axes -ne 'xyz') { Run 'G28' }
Run 'COMPARE_BELTS_RESPONSES FREQ_END=200'
Run 'AXES_SHAPER_CALIBRATION AXIS=X FREQ_END=200'
$r = Invoke-RestMethod "http://${Ip}:7125/server/files/list?root=config" -TimeoutSec 20
$r.result | Where-Object { $_.path -like 'ShakeTune_results/*' } | Sort-Object modified -Descending | Select-Object -First 4 | ForEach-Object { "[$Name] file $($_.path)" }
