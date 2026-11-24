param([string]$Ip, [int]$UpTimeoutSec = 600)
# Reboots the Pi through Moonraker, waits for it to come back with Klippy ready, then checks
# kernel, MCUs/CAN, services, config warnings and what is left in the OS update list.
$ErrorActionPreference = 'Stop'
function Get-Json($path, $timeout = 8) { Invoke-RestMethod -Uri "http://${Ip}:7125$path" -TimeoutSec $timeout }

$st = (Get-Json '/printer/objects/query?print_stats=state').result.status.print_stats.state
if ($st -in 'printing', 'paused') { throw "printer is $st - not rebooting" }
if ((Get-Json '/machine/update/status?refresh=false').result.busy) { throw "update manager busy - not rebooting" }
$k0 = (Get-Json '/machine/system_info').result.system_info.distribution.kernel_version
"kernel before: $k0"

Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125/machine/reboot" -TimeoutSec 15 | Out-Null
$t0 = Get-Date; "reboot requested at $($t0.ToString('HH:mm:ss'))"

# wait until it actually goes down
$down = $false; $deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) { try { Get-Json '/server/info' 3 | Out-Null; Start-Sleep -Seconds 2 } catch { $down = $true; break } }
"went down: $down after $([int]((Get-Date) - $t0).TotalSeconds)s"

# wait until Moonraker answers and Klippy is ready
$state = ''; $deadline = (Get-Date).AddSeconds($UpTimeoutSec)
while ((Get-Date) -lt $deadline) {
    try { $state = (Get-Json '/server/info' 5).result.klippy_state; if ($state -in 'ready', 'error', 'shutdown') { break } } catch { $state = 'unreachable' }
    Start-Sleep -Seconds 5
}
"back after $([int]((Get-Date) - $t0).TotalSeconds)s, klippy_state=$state"
if ($state -ne 'ready') {
    try { "state_message: " + (Get-Json '/printer/info').result.state_message } catch {}
    throw "Klippy not ready after reboot"
}
$info = (Get-Json '/server/info').result
$si = (Get-Json '/machine/system_info').result.system_info
"kernel after: $($si.distribution.kernel_version)"
"moonraker=$($info.moonraker_version) failed_components=$(@($info.failed_components) -join ',') warnings=$(@($info.warnings).Count)"
foreach ($w in $info.warnings) { "  W: $w" }
foreach ($p in $si.service_state.PSObject.Properties) { "  service {0,-14} {1}/{2}" -f $p.Name, $p.Value.active_state, $p.Value.sub_state }
$cf = (Get-Json '/printer/objects/query?configfile=warnings').result.status.configfile
"config warnings: $(@($cf.warnings).Count)"
$q = (Get-Json '/printer/objects/query?mcu=mcu_version,last_stats&mcu%20toolhead=mcu_version,last_stats&mcu%20cartographer=mcu_version,last_stats').result.status
foreach ($p in $q.PSObject.Properties) { $ls = $p.Value.last_stats; "  {0,-17} {1,-32} retransmit={2} invalid={3}" -f $p.Name, $p.Value.mcu_version, $ls.bytes_retransmit, $ls.bytes_invalid }
try { Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125/machine/update/refresh?name=system" -TimeoutSec 180 | Out-Null } catch { "  (system refresh: $($_.Exception.Message))" }
$sys = (Get-Json '/machine/update/status?refresh=false').result.version_info.system
"OS packages still pending: $($sys.package_count)$(if ($sys.package_count) { ' -> ' + (@($sys.package_list) -join ', ') })"
Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125/printer/gcode/script?script=CARTOGRAPHER_QUERY" -TimeoutSec 30 | Out-Null
(Get-Json '/server/gcode_store?count=6').result.gcode_store | Where-Object { $_.message -match 'Model' } | Select-Object -Last 2 | ForEach-Object { "  " + ($_.message -replace "`n", ' | ') }
