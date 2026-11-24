param([string]$Ip, [string[]]$Names, [int]$StepTimeoutSec = 1500, [int]$WaitSec = 240)
# Updates Moonraker update_manager entries one by one, stopping at the first failure.
# After each entry: waits until Moonraker is reachable, the updater is idle, and Klippy is ready.
$ErrorActionPreference = 'Stop'
function Get-Json($path, $timeout = 10) { Invoke-RestMethod -Uri "http://${Ip}:7125$path" -TimeoutSec $timeout }
function Wait-Ready([int]$maxSec = 240) {
    $deadline = (Get-Date).AddSeconds($maxSec); $last = ''
    while ((Get-Date) -lt $deadline) {
        try {
            $info = (Get-Json '/server/info').result
            $busy = (Get-Json '/machine/update/status?refresh=false').result.busy
            $last = "klippy=$($info.klippy_state) busy=$busy"
            if (-not $busy -and $info.klippy_state -eq 'ready') { return $last }
            if ($info.klippy_state -in 'error','shutdown' -and -not $busy) { return $last }
        } catch { $last = "unreachable: $($_.Exception.Message)" }
        Start-Sleep -Seconds 3
    }
    return "TIMEOUT ($last)"
}
foreach ($name in $Names) {
    $st = (Get-Json '/printer/objects/query?print_stats=state').result.status.print_stats.state
    if ($st -in 'printing', 'paused') { throw "printer is $st - stopping before $name" }
    $before = (Get-Json '/machine/update/status?refresh=false').result.version_info.$name
    if ($null -eq $before) { throw "unknown update entry '$name'" }
    $t0 = Get-Date
    $enc = [uri]::EscapeDataString($name)
    $err = $null
    try {
        Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125/machine/update/upgrade?name=$enc" -TimeoutSec $StepTimeoutSec | Out-Null
    } catch {
        $msg = $_.Exception.Message
        $code = $null; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        if ($code -eq 404) {
            $legacy = if ($name -eq 'klipper') { '/machine/update/klipper' } elseif ($name -eq 'moonraker') { '/machine/update/moonraker' } else { "/machine/update/client?name=$enc" }
            try { Invoke-RestMethod -Method Post -Uri "http://${Ip}:7125$legacy" -TimeoutSec $StepTimeoutSec | Out-Null } catch { $err = $_.Exception.Message }
        } elseif ($name -eq 'moonraker' -or $msg -match 'closed|aborted|forcibly|Unable to connect') {
            # Moonraker restarting itself (or a managed restart) can drop the HTTP request
        } else {
            $body = ''; try { $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream()); $body = $sr.ReadToEnd() } catch {}
            $err = "$msg $body"
        }
    }
    # Let the service restarts issued by the updater take effect before trusting "ready"
    if ($name -in 'moonraker', 'Klippain') { Start-Sleep -Seconds 15 } else { Start-Sleep -Seconds 6 }
    $wait = Wait-Ready $WaitSec
    $after = (Get-Json '/machine/update/status?refresh=false').result.version_info.$name
    $secs = [int]((Get-Date) - $t0).TotalSeconds
    if ($name -eq 'system') { "{0,-22} packages {1} -> {2}  ({3}s, {4})" -f $name, $before.package_count, $after.package_count, $secs, $wait }
    else { "{0,-22} {1} -> {2}  ({3}s, {4})" -f $name, $before.version, $after.version, $secs, $wait }
    if ($err) { throw "update of $name reported an error: $err" }
    if ($wait -notmatch 'klippy=ready busy=False') { throw "after $name the printer is not ready: $wait" }
    if ($after.version -ne $after.remote_version -and $name -ne 'cartographer_plugin') { "   WARNING: $name still not at remote version ($($after.remote_version))" }
}
