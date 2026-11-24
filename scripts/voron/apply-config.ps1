<#
apply-config.ps1 - the single gate for writing config files to the Voron printers (spec 002, T001).
PowerShell 5.1. ASCII only on purpose (no BOM needed).

Sequence (every write request goes through Invoke-MrPost / Invoke-MrUpload, which refuse to run
unless the idle gate and the hash gate have passed, and never run with -WhatIf):
  1. GET  /printer/info, /printer/objects/query?print_stats=state   idle gate
  2. GET  /server/files/config/<RemotePath>                         hash gate (current vs expected)
  3. POST /server/files/upload (backup copy on the machine) + local copy, both re-hashed
  4. POST /server/files/upload (new file), download again, re-hash
  5. POST /printer/firmware_restart, then poll /printer/info until ready (skipped by -NoRestart)
  6. print one ledger line (date | machine | file | old hash | new hash | backup | rollback)
-Restore: same flow, -LocalFile is a backup copy to put back (-ExpectedSha256 = hash now on machine).
-WhatIf : does the read-only gates, prints the steps and the rollback command, sends no write.
#>
param(
    [ValidateSet('TRI', 'V24')][string]$Printer,
    [string]$Ip,
    [string]$BaseUrl,                       # only http://127.0.0.1:<port> (fake Moonraker for tests)
    [Parameter(Mandatory)][string]$RemotePath,   # relative to the config root, e.g. overrides.cfg
    [Parameter(Mandatory)][string]$LocalFile,    # new content (or the backup copy with -Restore)
    [string]$BaseFile,                      # local copy the working version is based on
    [string]$ExpectedSha256,                # or its SHA256
    [Parameter(Mandatory)][string]$Reason,
    [switch]$WhatIf,
    [switch]$NoRestart,
    [switch]$Restore,
    [switch]$DiscardPendingSaveConfig,      # accept that a restart drops a pending save-config change
    [switch]$AllowMoonrakerConf,            # moonraker.conf may only be written with this
    [int]$RestartTimeoutSec = 120
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:WriteOk = $false      # becomes $true only after the idle gate and the hash gate pass
$script:Rollback = $null
$script:Stage = $null

# ---------------------------------------------------------------- target
$known = @{ TRI = '192.0.2.90'; V24 = '192.0.2.89' }
if ($BaseUrl) {
    if ($BaseUrl -notmatch '^http://127\.0\.0\.1:\d{1,5}$') { throw "-BaseUrl must look like http://127.0.0.1:<port>" }
    $base = $BaseUrl
    $machine = if ($Printer) { $Printer } else { 'MOCK' }
} else {
    if ($Ip) {
        $parsed = $null
        if (-not [System.Net.IPAddress]::TryParse($Ip, [ref]$parsed)) { throw "-Ip is not an IP address: $Ip" }
    }
    if ($Printer -and $Ip -and $known[$Printer] -ne $Ip) { throw "-Printer $Printer is $($known[$Printer]), not $Ip" }
    if (-not $Ip) {
        if (-not $Printer) { throw "give -Printer TRI|V24 (or -Ip, or -BaseUrl for a test)" }
        $Ip = $known[$Printer]
    }
    $base = "http://${Ip}:7125"
    $machine = if ($Printer) { $Printer } else { 'ip-' + ($Ip -replace '\.', '-') }
}

# ---------------------------------------------------------------- inputs
# allow-list: [dir/]*name.cfg|name.conf ; dir segments have no dots; nothing under backups/
if ($RemotePath -notmatch '^([A-Za-z0-9_][A-Za-z0-9_-]*/)*[A-Za-z0-9_][A-Za-z0-9_.-]*\.(cfg|conf)$' -or $RemotePath -match '^backups(/|$)') {
    throw "-RemotePath must be a relative path to a .cfg or .conf file inside the config root (not under backups/): $RemotePath"
}
if ($RemotePath.Split('/')[-1] -ieq 'moonraker.conf' -and -not $AllowMoonrakerConf) {
    throw "writing moonraker.conf needs -AllowMoonrakerConf"
}
if (-not (Test-Path -LiteralPath $LocalFile -PathType Leaf)) { throw "-LocalFile not found: $LocalFile" }
$LocalFile = (Resolve-Path -LiteralPath $LocalFile).Path
$reasonSafe = ($Reason -replace '[^A-Za-z0-9_-]', '-').Trim('-')
if (-not $reasonSafe) { throw "-Reason is empty after cleaning" }

function Get-Sha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower() }

$expected = $null
if ($BaseFile) {
    if (-not (Test-Path -LiteralPath $BaseFile -PathType Leaf)) { throw "-BaseFile not found: $BaseFile" }
    $expected = Get-Sha $BaseFile
}
if ($ExpectedSha256) {
    $e = $ExpectedSha256.Trim().ToLower()
    if ($e -notmatch '^[0-9a-f]{64}$') { throw "-ExpectedSha256 is not a SHA256 hex string" }
    if ($expected -and $expected -ne $e) { throw "-BaseFile hash and -ExpectedSha256 disagree" }
    $expected = $e
}
if (-not $expected) { throw "give -BaseFile or -ExpectedSha256 (hash of the file now on the machine)" }

$newSha = Get-Sha $LocalFile
$leaf = $RemotePath.Split('/')[-1]
$remoteDir = if ($RemotePath.Contains('/')) { $RemotePath.Substring(0, $RemotePath.LastIndexOf('/')) } else { '' }
$date = Get-Date -Format 'yyyy-MM-dd'
$bkName = "${date}_$reasonSafe"
$bkRemoteRel = "backups/$bkName/$RemotePath"                      # relative to the config root
$bkRemoteDir = "backups/$bkName" + $(if ($remoteDir) { "/$remoteDir" } else { '' })
$bkLocal = Join-Path $ProjectRoot ("fleet\backups\$bkName\$machine\" + ($RemotePath -replace '/', '\'))

# ---------------------------------------------------------------- helpers
function Get-Mr([string]$Path) {
    try { Invoke-RestMethod -Method Get -Uri ($base + $Path) -TimeoutSec 10 -UseBasicParsing }
    catch { throw "Cannot get $Path from Moonraker at ${base}: $($_.Exception.Message)" }
}

function Assert-Idle([string]$When) {
    $info = (Get-Mr '/printer/info').result
    $ready = ($info.state -eq 'ready')
    if (-not $ready) {
        # -Restore must work when the new file put klippy into error/shutdown
        if (-not ($Restore -and $info.state -in 'error', 'shutdown')) { throw "[$When] klippy state is '$($info.state)', not ready - refusing, nothing written" }
    }
    $st = $null; $ps = $null
    try { $st = (Get-Mr '/printer/objects/query?print_stats=state&configfile=save_config_pending&extruder=target&heater_bed=target&idle_timeout=state').result.status; $ps = $st.print_stats.state }
    catch { if ($ready) { throw } }       # no print_stats while klippy is down
    if ($ps -in 'printing', 'paused') { throw "[$When] print_stats.state is '$ps' - refusing, nothing written" }
    if ($ready -and $ps -notin 'standby', 'complete', 'cancelled', 'error') { throw "[$When] print_stats.state is '$ps' (unknown) - refusing, nothing written" }
    if ($ready) { Assert-NoSideEffects $When $st }
}

function Get-Field($Obj, [string]$Name) {
    if ($null -ne $Obj -and $Obj.PSObject.Properties.Name -contains $Name) { $Obj.$Name } else { $null }
}

function Assert-NoSideEffects([string]$When, $s) {
    # klippy is ready here. Restart drops a pending save-config and switches heaters off.
    if ((Get-Field (Get-Field $s 'configfile') 'save_config_pending') -eq $true -and -not $DiscardPendingSaveConfig) {
        throw "[$When] a save-config change is pending; a restart will lose it - nothing written. Use -DiscardPendingSaveConfig to accept"
    }
    if (-not $Restore) {
        foreach ($h in 'extruder', 'heater_bed') {
            $t = Get-Field (Get-Field $s $h) 'target'
            if ($null -ne $t -and [double]$t -gt 0) { throw "[$When] $h target is $t - the machine is being heated, refusing, nothing written" }
        }
        if ((Get-Field (Get-Field $s 'idle_timeout') 'state') -eq 'Printing') { throw "[$When] idle_timeout is Printing - refusing, nothing written" }
    }
}

function Get-RemoteFile([string]$Rel, [string]$Out) {
    # returns $true and saves raw bytes to $Out, or $false when the machine answers 404
    $enc = ($Rel -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
    if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Force }
    try {
        Invoke-WebRequest -Uri "$base/server/files/config/$enc" -OutFile $Out -TimeoutSec 30 -UseBasicParsing | Out-Null
        return $true
    } catch {
        $r = $_.Exception.Response
        if ($r -and [int]$r.StatusCode -eq 404) { return $false }
        throw "Cannot download config/${Rel} from ${base}: $($_.Exception.Message)"
    }
}

# --- the only two functions that send a write request ---
function Assert-WriteAllowed([string]$What) {
    if ($WhatIf) { throw "internal: write '$What' attempted under -WhatIf" }
    if (-not $script:WriteOk) { throw "internal: write '$What' attempted before the idle and hash gates passed" }
}

function Invoke-MrPost([string]$Path) {
    Assert-WriteAllowed "POST $Path"
    Invoke-RestMethod -Method Post -Uri ($base + $Path) -TimeoutSec 15 -UseBasicParsing | Out-Null
}

function Invoke-MrUpload([string]$File, [string]$SubDir, [string]$Sha) {
    Assert-WriteAllowed "upload $SubDir/$([IO.Path]::GetFileName($File))"
    $a = @('-sS', '-f', '--max-time', '60', '-F', "file=@$File", '--form-string', 'root=config')
    if ($SubDir) { $a += @('--form-string', "path=$SubDir") }
    $a += @('--form-string', "checksum=$Sha", "$base/server/files/upload")
    $out = & curl.exe @a
    $shown = (@($SubDir, [IO.Path]::GetFileName($File)) | Where-Object { $_ }) -join '/'
    if ($LASTEXITCODE -ne 0) { throw "curl upload failed (exit $LASTEXITCODE) for $shown" }
    $out
}

function Get-RollbackCommand {
    $c = "powershell -NoProfile -File `"$PSCommandPath`""
    if ($BaseUrl) { $c += " -BaseUrl $BaseUrl" }
    if ($Printer) { $c += " -Printer $Printer" } elseif (-not $BaseUrl) { $c += " -Ip $Ip" }
    $c += " -RemotePath $RemotePath -LocalFile `"$bkLocal`" -ExpectedSha256 $newSha -Restore -Reason rollback-$reasonSafe"
    $c
}

function Wait-Ready {
    $t0 = Get-Date; $seenNotReady = $false
    while (((Get-Date) - $t0).TotalSeconds -lt $RestartTimeoutSec) {
        Start-Sleep -Seconds 3
        $state = 'unreachable'; $msg = ''
        try { $i = (Invoke-RestMethod -Uri "$base/printer/info" -TimeoutSec 5 -UseBasicParsing).result; $state = $i.state; $msg = $i.state_message } catch { }
        if ($state -ne 'ready') { $seenNotReady = $true }
        if ($state -in 'error', 'shutdown') { throw "klippy went to '$state': $msg" }
        if ($state -eq 'ready' -and ($seenNotReady -or ((Get-Date) - $t0).TotalSeconds -gt 20)) { return }
    }
    throw "klippy not ready within ${RestartTimeoutSec}s"
}

# ---------------------------------------------------------------- main
try {
    $script:Stage = Join-Path ([IO.Path]::GetTempPath()) ('apply-config-' + [guid]::NewGuid().ToString('N'))
    foreach ($d in 'cur', 'bk', 'new', 'chk') { New-Item -ItemType Directory -Path (Join-Path $script:Stage $d) | Out-Null }
    $cur = Join-Path $script:Stage "cur\$leaf"

    # 1. idle gate
    Assert-Idle 'step 1'
    # 2. hash gate
    if (-not (Get-RemoteFile $RemotePath $cur)) { throw "config/$RemotePath does not exist on the machine - refusing (this script only replaces existing files)" }
    $oldSha = Get-Sha $cur
    if ($oldSha -ne $expected) { throw "hash mismatch on machine for config/${RemotePath}: machine=$oldSha expected=$expected - nothing written" }
    $script:WriteOk = $true
    $rb = Get-RollbackCommand

    if ($WhatIf) {
        "WHATIF target=$base machine=$machine file=config/$RemotePath (read-only gates passed, no write sent)"
        "  step 3: backup on machine -> config/$bkRemoteRel ; local -> $bkLocal"
        "  step 4: upload $LocalFile ($newSha) to config/$RemotePath, download and compare"
        "  step 5: " + $(if ($NoRestart) { 'no restart (-NoRestart)' } else { "POST /printer/firmware_restart, wait ready up to ${RestartTimeoutSec}s" })
        "  rollback: $rb"
        return
    }

    # 3. backup in two places
    if (Test-Path -LiteralPath $bkLocal) { throw "local backup already exists, use another -Reason: $bkLocal" }
    $probe = Join-Path $script:Stage 'chk\probe'
    if (Get-RemoteFile $bkRemoteRel $probe) { throw "backup already exists on machine, use another -Reason: config/$bkRemoteRel" }
    New-Item -ItemType Directory -Path (Split-Path $bkLocal) -Force | Out-Null
    Copy-Item -LiteralPath $cur -Destination $bkLocal
    if ((Get-Sha $bkLocal) -ne $oldSha) { throw "local backup hash differs from original" }
    $bkStage = Join-Path $script:Stage "bk\$leaf"
    Copy-Item -LiteralPath $cur -Destination $bkStage
    Assert-Idle 'step 3'
    Invoke-MrUpload $bkStage $bkRemoteDir $oldSha | Out-Null
    $chk = Join-Path $script:Stage 'chk\bk'
    if (-not (Get-RemoteFile $bkRemoteRel $chk) -or (Get-Sha $chk) -ne $oldSha) { throw "backup on machine failed verification: config/$bkRemoteRel" }
    $script:Rollback = $rb

    # 4. write new file and verify
    $newStage = Join-Path $script:Stage "new\$leaf"
    Copy-Item -LiteralPath $LocalFile -Destination $newStage
    Assert-Idle 'step 4'
    $recheck = Join-Path $script:Stage 'chk\recheck'
    if (-not (Get-RemoteFile $RemotePath $recheck) -or (Get-Sha $recheck) -ne $oldSha) { throw "file on machine changed since the hash gate (edited elsewhere?) - new file not written; backup kept at config/$bkRemoteRel" }
    Invoke-MrUpload $newStage $remoteDir $newSha | Out-Null
    $chk2 = Join-Path $script:Stage 'chk\new'
    if (-not (Get-RemoteFile $RemotePath $chk2) -or (Get-Sha $chk2) -ne $newSha) { throw "file on machine does not match the new content after upload" }

    # 5. restart
    if ($NoRestart) { "NOTE: -NoRestart, Klipper still runs the old config" }
    else {
        Assert-Idle 'step 5'
        Invoke-MrPost '/printer/firmware_restart'
        Wait-Ready
    }

    # 6. ledger line
    "LEDGER | $date | $machine | config/$RemotePath | $oldSha | $newSha | machine:config/$bkRemoteRel local:$bkLocal | rollback: $rb"
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    if ($script:Rollback) { Write-Output "ROLLBACK: $script:Rollback" }
    $global:LASTEXITCODE = 1
    exit 1
} finally {
    if ($script:Stage -and (Test-Path -LiteralPath $script:Stage)) { Remove-Item -LiteralPath $script:Stage -Recurse -Force }
}
