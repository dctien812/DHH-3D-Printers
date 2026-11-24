<#
apply-config.mock.ps1 - runs scripts\voron\apply-config.ps1 against a FAKE Moonraker
(System.Net.HttpListener on 127.0.0.1, random free port). Spec 002, T035.
PowerShell 5.1. ASCII only. Never talks to a real printer: every call uses -BaseUrl http://127.0.0.1:<port>.

Run:   powershell -NoProfile -ExecutionPolicy Bypass -File tests\apply-config.mock.ps1
Exit:  0 if every case passed, 1 otherwise. Transcript goes to -ReportPath (default tests\tmp\mock-run.md).
-ScriptPath lets you run the same cases against a COPY of apply-config.ps1 (used to prove the cases catch faults).
Local backups made by the script use -Reason mocktest-*; they are deleted at start and end.
#>
param(
    [string]$ScriptPath,
    [string]$ReportPath
)
$ErrorActionPreference = 'Continue'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $ScriptPath) { $ScriptPath = Join-Path $ProjectRoot 'scripts\voron\apply-config.ps1' }
$ScriptPath = (Resolve-Path -LiteralPath $ScriptPath).Path
$AppRoot = (Resolve-Path (Join-Path (Split-Path $ScriptPath) '..\..')).Path
$BkRoot = Join-Path $AppRoot 'fleet\backups'
$TmpDir = Join-Path $PSScriptRoot 'tmp'
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
if (-not $ReportPath) { $ReportPath = Join-Path $TmpDir 'mock-run.md' }

function Remove-MockBackups {
    if (Test-Path -LiteralPath $BkRoot) {
        Get-ChildItem -LiteralPath $BkRoot -Directory -Filter '*mocktest*' | Remove-Item -Recurse -Force
    }
}
function Get-Sha256([byte[]]$b) {
    $h = [Security.Cryptography.SHA256]::Create()
    ([BitConverter]::ToString($h.ComputeHash($b)) -replace '-', '').ToLower()
}

# ---------------------------------------------------------------- fixtures
$enc = [Text.Encoding]::ASCII
$origBytes = $enc.GetBytes("[stepper_x]`r`nposition_endstop: 300`r`n`r`n[printer]`r`nmax_velocity: 300`r`n")
$newBytes  = $enc.GetBytes("[stepper_x]`r`nposition_endstop: 301`r`n`r`n[printer]`r`nmax_velocity: 350`r`n")
$mOrig     = $enc.GetBytes("[gcode_macro MOCK_ORIG]`r`ngcode: M117 orig`r`n")
$mNew      = $enc.GetBytes("[gcode_macro MOCK_NEW]`r`ngcode: M117 new`r`n")
$origSha = Get-Sha256 $origBytes; $newSha = Get-Sha256 $newBytes
$mOrigSha = Get-Sha256 $mOrig; $mNewSha = Get-Sha256 $mNew
$newFile  = Join-Path $TmpDir 'new_overrides.cfg'
$newMFile = Join-Path $TmpDir 'new_m.cfg'
[IO.File]::WriteAllBytes($newFile, $newBytes)
[IO.File]::WriteAllBytes($newMFile, $mNew)
$date = Get-Date -Format 'yyyy-MM-dd'

# ---------------------------------------------------------------- fake Moonraker
$S = [hashtable]::Synchronized(@{
    log = (New-Object System.Collections.ArrayList); uploads = (New-Object System.Collections.ArrayList)
    files = @{}; klippy = 'ready'; print = 'standby'; printAfter = -1; psq = 0; fail500 = ''
    restartNever = $false; restarted = $false; readyAt = [datetime]::MinValue; restartDelay = 4
    started = $false; listener = $null; err = ''
})
$handler = {
    param($S, $port)
    $latin = [Text.Encoding]::GetEncoding(28591)
    $utf8 = New-Object Text.UTF8Encoding($false)
    function Send($ctx, [int]$code, [string]$json, [byte[]]$raw) {
        $res = $ctx.Response; $res.StatusCode = $code
        if ($null -eq $raw) { $raw = $utf8.GetBytes($json); $res.ContentType = 'application/json' }
        else { $res.ContentType = 'application/octet-stream' }
        $res.ContentLength64 = $raw.Length
        $res.OutputStream.Write($raw, 0, $raw.Length); $res.Close()
    }
    try {
        $l = New-Object System.Net.HttpListener
        $l.Prefixes.Add("http://127.0.0.1:$port/")
        $l.Start(); $S.listener = $l; $S.started = $true
    } catch { $S.err = "$_"; $S.started = $true; return }
    while ($l.IsListening) {
        try { $ctx = $l.GetContext() } catch { break }
        try {
            $req = $ctx.Request; $m = $req.HttpMethod; $raw = $req.RawUrl; $path = $raw.Split('?')[0]
            [void]$S.log.Add("$m $raw")
            if ($m -eq 'GET' -and $path -eq '/printer/info') {
                $st = $S.klippy
                if ($S.restarted) {
                    if ($S.restartNever) { $st = 'startup' }
                    elseif ((Get-Date) -ge $S.readyAt) { $st = 'ready' } else { $st = 'startup' }
                }
                Send $ctx 200 ('{"result":{"state":"' + $st + '","state_message":"mock ' + $st + '"}}') $null
            }
            elseif ($m -eq 'GET' -and $path -eq '/printer/objects/query') {
                $S.psq = $S.psq + 1
                $ps = $S.print
                if ($S.printAfter -ge 0 -and $S.psq -gt $S.printAfter) { $ps = 'printing' }
                Send $ctx 200 ('{"result":{"status":{"print_stats":{"state":"' + $ps + '"}}}}') $null
            }
            elseif ($m -eq 'POST' -and $path -eq '/printer/firmware_restart') {
                $S.restarted = $true; $S.readyAt = (Get-Date).AddSeconds($S.restartDelay)
                Send $ctx 200 '{"result":"ok"}' $null
            }
            elseif ($m -eq 'POST' -and $path -eq '/server/files/upload') {
                $ms = New-Object IO.MemoryStream; $req.InputStream.CopyTo($ms)
                $body = $latin.GetString($ms.ToArray())
                $b = [regex]::Match($req.ContentType, 'boundary=("?)([^";]+)\1').Groups[2].Value
                $fields = @{}; $fname = $null; $fbody = $null
                foreach ($part in ($body -split [regex]::Escape("--$b"))) {
                    if ($part.Length -lt 4 -or $part.StartsWith('--')) { continue }
                    $part = $part.Substring(2)
                    $i = $part.IndexOf("`r`n`r`n"); if ($i -lt 0) { continue }
                    $head = $part.Substring(0, $i); $val = $part.Substring($i + 4)
                    if ($val.EndsWith("`r`n")) { $val = $val.Substring(0, $val.Length - 2) }
                    $n = [regex]::Match($head, 'name="([^"]+)"').Groups[1].Value
                    $fm = [regex]::Match($head, 'filename="([^"]*)"')
                    if ($fm.Success) { $fname = $fm.Groups[1].Value; $fbody = $val } else { $fields[$n] = $val }
                }
                $key = $fname; if ($fields.ContainsKey('path') -and $fields['path']) { $key = $fields['path'] + '/' + $fname }
                $bytes = $latin.GetBytes($fbody)
                $sha = ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)) -replace '-', '').ToLower()
                if ($fields['root'] -ne 'config') { Send $ctx 400 '{"error":"bad root"}' $null }
                elseif ($fields.ContainsKey('checksum') -and $fields['checksum'] -ne $sha) { Send $ctx 400 '{"error":"checksum mismatch"}' $null }
                elseif ($S.fail500 -and $key -match $S.fail500) { Send $ctx 500 '{"error":"mock forced failure"}' $null }
                else {
                    $S.files[$key] = $bytes; [void]$S.uploads.Add($key)
                    Send $ctx 201 ('{"item":{"path":"' + $key + '","root":"config"},"action":"create_file"}') $null
                }
            }
            elseif ($m -eq 'GET' -and $path.StartsWith('/server/files/config/')) {
                $rel = [uri]::UnescapeDataString($path.Substring('/server/files/config/'.Length))
                if ($S.files.ContainsKey($rel)) { Send $ctx 200 '' ([byte[]]$S.files[$rel]) }
                else { Send $ctx 404 '{"error":"not found"}' $null }
            }
            else { Send $ctx 404 '{"error":"mock: unknown route"}' $null }
        } catch {
            try { Send $ctx 500 ('{"error":"mock handler exception"}') $null } catch { }
        }
    }
}
function Reset-Mock([hashtable]$Over = @{}, [switch]$KeepFiles) {
    $S.log.Clear(); $S.uploads.Clear(); $S.klippy = 'ready'; $S.print = 'standby'; $S.printAfter = -1; $S.psq = 0
    $S.fail500 = ''; $S.restartNever = $false; $S.restarted = $false; $S.readyAt = [datetime]::MinValue; $S.restartDelay = 4
    if (-not $KeepFiles) { $S.files.Clear(); $S.files['overrides.cfg'] = $origBytes; $S.files['macros/m.cfg'] = $mOrig }
    foreach ($k in $Over.Keys) { $S[$k] = $Over[$k] }
}

$tcp = New-Object System.Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0); $tcp.Start()
$port = $tcp.LocalEndpoint.Port; $tcp.Stop()
$Url = "http://127.0.0.1:$port"
$rs = [runspacefactory]::CreateRunspace(); $rs.Open()
$psh = [powershell]::Create(); $psh.Runspace = $rs
[void]$psh.AddScript($handler).AddArgument($S).AddArgument($port)
$async = $psh.BeginInvoke()
$t0 = Get-Date
while (-not $S.started -and ((Get-Date) - $t0).TotalSeconds -lt 10) { Start-Sleep -Milliseconds 100 }
if (-not $S.started -or $S.err) { Write-Output "mock failed to start: $($S.err)"; exit 2 }

# ---------------------------------------------------------------- harness
$script:Results = New-Object System.Collections.ArrayList
$script:Md = New-Object System.Text.StringBuilder
$script:Cur = $null
function Start-Case([string]$Id, [string]$Title) {
    $script:Cur = @{ Id = $Id; Title = $Title; Fails = (New-Object System.Collections.ArrayList); Runs = (New-Object System.Collections.ArrayList); Info = (New-Object System.Collections.ArrayList) }
}
function Assert-That([bool]$Cond, [string]$Msg) { if (-not $Cond) { [void]$script:Cur.Fails.Add($Msg) } }
function Add-Info([string]$Msg) { [void]$script:Cur.Info.Add($Msg) }
function Invoke-Apply([string[]]$ArgList) {
    foreach ($a in $ArgList) { if ($a -match '192\.168\.1\.') { throw "harness refuses to pass a printer address: $a" } }
    $S.log.Clear(); $S.uploads.Clear()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgList 2>&1 | Out-String
    $code = $LASTEXITCODE; $sw.Stop()
    $log = @($S.log.ToArray())
    $r = [pscustomobject]@{ Code = $code; Out = $o.Trim(); Log = $log; Writes = @($log | Where-Object { $_ -notmatch '^GET ' }).Count; Sec = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
    [void]$script:Cur.Runs.Add(@{ Args = ($ArgList -join ' '); R = $r })
    $r
}
function Complete-Case {
    $c = $script:Cur
    $last = $c.Runs[$c.Runs.Count - 1].R
    $totalW = 0; foreach ($x in $c.Runs) { $totalW += $x.R.Writes }
    $codes = ($c.Runs | ForEach-Object { $_.R.Code }) -join ','
    $res = [pscustomobject]@{ Id = $c.Id; Title = $c.Title; Pass = ($c.Fails.Count -eq 0); Codes = $codes; Writes = $totalW; Fails = ($c.Fails -join '; ') }
    [void]$script:Results.Add($res)
    $verdict = 'FAIL'; if ($res.Pass) { $verdict = 'PASS' }
    [void]$script:Md.AppendLine("### Case $($c.Id) - $($c.Title) - $verdict")
    foreach ($x in $c.Runs) {
        [void]$script:Md.AppendLine('')
        [void]$script:Md.AppendLine('Command: `apply-config.ps1 ' + $x.Args + '`')
        [void]$script:Md.AppendLine("Exit code: $($x.R.Code)   write requests (non-GET) seen by mock: $($x.R.Writes)   seconds: $($x.R.Sec)")
        [void]$script:Md.AppendLine('Output:'); [void]$script:Md.AppendLine('```'); [void]$script:Md.AppendLine($x.R.Out); [void]$script:Md.AppendLine('```')
        [void]$script:Md.AppendLine('Requests received by mock:'); [void]$script:Md.AppendLine('```')
        if ($x.R.Log.Count -eq 0) { [void]$script:Md.AppendLine('(none)') } else { foreach ($l in $x.R.Log) { [void]$script:Md.AppendLine($l) } }
        [void]$script:Md.AppendLine('```')
    }
    foreach ($i in $c.Info) { [void]$script:Md.AppendLine("Note: $i") }
    if (-not $res.Pass) { [void]$script:Md.AppendLine("FAILED CHECKS: $($res.Fails)") }
    [void]$script:Md.AppendLine('')
    Write-Output ("{0,-4} {1,-5} exit={2,-4} writes={3}  {4}" -f $c.Id, $verdict, $codes, $totalW, $c.Title)
    if (-not $res.Pass) { Write-Output "       -> $($res.Fails)" }
}
function Get-Args([string]$Case, [string]$Sha = $origSha, [string]$Remote = 'overrides.cfg', [string]$Local = $newFile) {
    @('-BaseUrl', $Url, '-RemotePath', $Remote, '-LocalFile', $Local, '-ExpectedSha256', $Sha, '-Reason', "mocktest-$Case")
}
function Test-Untouched {
    (Get-Sha256 ([byte[]]$S.files['overrides.cfg'])) -eq $origSha
}
function Test-Refused($r, [string]$Pattern) {
    Assert-That ($r.Code -ne 0) "exit code should be non-zero, was $($r.Code)"
    Assert-That ($r.Out -match $Pattern) "output should match /$Pattern/"
    Assert-That ($r.Writes -eq 0) "mock saw $($r.Writes) write request(s), expected 0"
    Assert-That (Test-Untouched) 'file on the fake machine was changed'
    Assert-That ($S.uploads.Count -eq 0) 'mock stored an upload'
}

Remove-MockBackups
Write-Output "Mock Moonraker on $Url ; script under test: $ScriptPath"
Write-Output ''

# ---- 1 / 1b printing, unknown state
Start-Case '1' 'print_stats.state = printing -> refuse'
Reset-Mock @{ print = 'printing' }
$r = Invoke-Apply (Get-Args 'c1'); Test-Refused $r "state is 'printing'"
Assert-That (-not (Test-Path (Join-Path $BkRoot "${date}_mocktest-c1"))) 'a local backup dir was created'
Complete-Case
Start-Case '1b' 'print_stats.state = weird (unknown) -> refuse'
Reset-Mock @{ print = 'weird' }
$r = Invoke-Apply (Get-Args 'c1b'); Test-Refused $r "unknown"
Complete-Case

# ---- 2 paused
Start-Case '2' 'print_stats.state = paused -> refuse'
Reset-Mock @{ print = 'paused' }
$r = Invoke-Apply (Get-Args 'c2'); Test-Refused $r "state is 'paused'"
Complete-Case

# ---- 3 klippy not ready
foreach ($k in 'startup', 'error', 'shutdown') {
    Start-Case "3-$k" "klippy state = $k -> refuse"
    Reset-Mock @{ klippy = $k }
    $r = Invoke-Apply (Get-Args "c3$k"); Test-Refused $r "klippy state is '$k'"
    Complete-Case
}

# ---- 4 hash mismatch
Start-Case '4' 'machine idle but hash on machine differs from -ExpectedSha256 -> stop'
Reset-Mock
$r = Invoke-Apply (Get-Args 'c4' ('f' * 64)); Test-Refused $r 'hash mismatch'
Assert-That (@($r.Log | Where-Object { $_ -eq 'GET /server/files/config/overrides.cfg' }).Count -eq 1) 'script did not download the file to compare hashes'
Complete-Case

# ---- 5 WhatIf
Start-Case '5' '-WhatIf on idle machine, hash matches -> only GETs, steps and rollback printed'
Reset-Mock
$r = Invoke-Apply ((Get-Args 'c5') + '-WhatIf')
Assert-That ($r.Code -eq 0) "exit code should be 0, was $($r.Code)"
Assert-That ($r.Writes -eq 0) "mock saw $($r.Writes) write request(s)"
Assert-That ($r.Log.Count -ge 3) 'script sent no read requests at all'
Assert-That ($r.Out -match 'WHATIF') 'no WHATIF banner'
Assert-That ($r.Out -match 'step 3' -and $r.Out -match 'step 4' -and $r.Out -match 'step 5') 'steps 3/4/5 not listed'
Assert-That ($r.Out -match 'rollback: powershell') 'rollback command not printed'
Assert-That (Test-Untouched -and $S.uploads.Count -eq 0) 'machine changed'
Assert-That (-not (Test-Path (Join-Path $BkRoot "${date}_mocktest-c5"))) 'local backup dir created under -WhatIf'
Complete-Case

# ---- 6 full success, then 10 restore (same fake machine state)
Start-Case '6' 'full success path: backup first, write second, restart last, ledger line'
Reset-Mock
$r = Invoke-Apply (Get-Args 'c6')
Assert-That ($r.Code -eq 0) "exit code should be 0, was $($r.Code)"
$posts = @($r.Log | Where-Object { $_ -notmatch '^GET ' })
Assert-That ($posts.Count -eq 3) "expected 3 write requests, saw $($posts.Count)"
if ($posts.Count -eq 3) {
    Assert-That ($posts[0] -eq 'POST /server/files/upload' -and $posts[1] -eq 'POST /server/files/upload' -and $posts[2] -eq 'POST /printer/firmware_restart') 'write order is not upload, upload, restart'
}
Assert-That ($S.uploads.Count -eq 2) "expected 2 stored uploads, saw $($S.uploads.Count)"
if ($S.uploads.Count -ge 2) {
    Assert-That ($S.uploads[0] -eq "backups/${date}_mocktest-c6/overrides.cfg") "first upload should be the backup, was $($S.uploads[0])"
    Assert-That ($S.uploads[1] -eq 'overrides.cfg') "second upload should be the new file, was $($S.uploads[1])"
}
Assert-That ((Get-Sha256 ([byte[]]$S.files['overrides.cfg'])) -eq $newSha) 'machine does not hold the new content'
Assert-That ($S.files.ContainsKey("backups/${date}_mocktest-c6/overrides.cfg") -and (Get-Sha256 ([byte[]]$S.files["backups/${date}_mocktest-c6/overrides.cfg"])) -eq $origSha) 'backup on machine missing or differs from original'
$bk6 = Join-Path $BkRoot "${date}_mocktest-c6\MOCK\overrides.cfg"
Assert-That (Test-Path -LiteralPath $bk6) "local backup missing: $bk6"
if (Test-Path -LiteralPath $bk6) { Assert-That ((Get-FileHash -LiteralPath $bk6 -Algorithm SHA256).Hash.ToLower() -eq $origSha) 'local backup hash differs from original' }
$lastPost = 0; for ($i = 0; $i -lt $r.Log.Count; $i++) { if ($r.Log[$i] -notmatch '^GET ') { $lastPost = $i } }
Assert-That ($r.Log[$lastPost] -eq 'POST /printer/firmware_restart') 'restart is not the last write'
Assert-That ($r.Log[$r.Log.Count - 1] -eq 'GET /printer/info') 'script did not poll /printer/info after restart'
$led = @($r.Out -split "`r?`n" | Where-Object { $_ -like 'LEDGER |*' })
Assert-That ($led.Count -eq 1) "expected 1 LEDGER line, saw $($led.Count)"
if ($led.Count -eq 1) {
    $f = $led[0] -split ' \| '
    Assert-That ($f.Count -eq 8) "LEDGER should have 8 fields, has $($f.Count)"
    if ($f.Count -eq 8) {
        Assert-That ($f[1] -eq $date) 'ledger date'
        Assert-That ($f[2] -eq 'MOCK') 'ledger machine'
        Assert-That ($f[3] -eq 'config/overrides.cfg') 'ledger file'
        Assert-That ($f[4] -eq $origSha) 'ledger old hash'
        Assert-That ($f[5] -eq $newSha) 'ledger new hash'
        Assert-That ($f[6] -match 'machine:config/backups/' -and $f[6] -match 'local:') 'ledger backup field'
        Assert-That ($f[7] -match '^rollback: powershell.* -Restore ') 'ledger rollback field'
    }
}
Complete-Case

Start-Case '10' '-Restore from the backup of case 6 puts original hash back on the machine'
Reset-Mock -KeepFiles
Assert-That ((Get-Sha256 ([byte[]]$S.files['overrides.cfg'])) -eq $newSha) 'precondition: machine should still hold new content from case 6'
if (Test-Path -LiteralPath $bk6) {
    $r = Invoke-Apply @('-BaseUrl', $Url, '-RemotePath', 'overrides.cfg', '-LocalFile', $bk6, '-ExpectedSha256', $newSha, '-Restore', '-Reason', 'mocktest-c10')
    Assert-That ($r.Code -eq 0) "exit code should be 0, was $($r.Code)"
    Assert-That ((Get-Sha256 ([byte[]]$S.files['overrides.cfg'])) -eq $origSha) 'machine content is not the original after restore'
    Assert-That ($r.Out -match 'LEDGER \|') 'no ledger line'
    Assert-That ($S.uploads.Count -eq 2) "expected 2 uploads (safety backup + restore), saw $($S.uploads.Count)"
    $bk10 = Join-Path $BkRoot "${date}_mocktest-c10\MOCK\overrides.cfg"
    Assert-That (Test-Path -LiteralPath $bk10) 'restore did not keep a local backup of the state it replaced'
    if (Test-Path -LiteralPath $bk10) { Assert-That ((Get-FileHash -LiteralPath $bk10 -Algorithm SHA256).Hash.ToLower() -eq $newSha) 'safety backup is not the replaced (new) content' }
} else {
    Assert-That $false 'no case-6 backup to restore from'
    [void](Invoke-Apply @('-BaseUrl', $Url, '-RemotePath', 'overrides.cfg', '-LocalFile', $newFile, '-ExpectedSha256', 'f'))
}
Complete-Case

# ---- 6b sub-directory path
Start-Case '6b' 'success with RemotePath in a sub-directory (macros/m.cfg)'
Reset-Mock
$r = Invoke-Apply (Get-Args 'c6b' $mOrigSha 'macros/m.cfg' $newMFile)
Assert-That ($r.Code -eq 0) "exit code should be 0, was $($r.Code)"
Assert-That ($S.uploads.Count -eq 2) "expected 2 uploads, saw $($S.uploads.Count)"
if ($S.uploads.Count -ge 2) {
    Assert-That ($S.uploads[0] -eq "backups/${date}_mocktest-c6b/macros/m.cfg") "backup key was $($S.uploads[0])"
    Assert-That ($S.uploads[1] -eq 'macros/m.cfg') "new file key was $($S.uploads[1])"
}
Assert-That ((Get-Sha256 ([byte[]]$S.files['macros/m.cfg'])) -eq $mNewSha) 'new content not on machine'
Complete-Case

# ---- 7 upload 500 on the new file
Start-Case '7' 'upload of the new file returns 500 -> error, no restart, rollback command'
Reset-Mock @{ fail500 = '^overrides\.cfg$' }
$r = Invoke-Apply (Get-Args 'c7')
Assert-That ($r.Code -ne 0) "exit code should be non-zero, was $($r.Code)"
Assert-That ($r.Out -match 'ERROR: ') 'no ERROR line'
Assert-That ($r.Out -match 'curl upload failed') 'error does not name the failed upload'
Assert-That ($r.Out -match 'ROLLBACK: powershell') 'rollback command not printed'
Assert-That (-not ($r.Log -contains 'POST /printer/firmware_restart')) 'script restarted Klipper after a failed write'
Assert-That (Test-Untouched) 'file on machine changed although upload failed'
Assert-That ($S.uploads.Count -eq 1) "expected only the backup upload, saw $($S.uploads.Count)"
Complete-Case

# ---- 8 printing starts mid-way
Start-Case '8a' 'machine turns printing right after the first gate -> no write at all'
Reset-Mock @{ printAfter = 1 }
$r = Invoke-Apply (Get-Args 'c8a'); Test-Refused $r "step 3.*printing"
Complete-Case
Start-Case '8b' 'machine turns printing after the backup, before the new file -> new file not written'
Reset-Mock @{ printAfter = 2 }
$r = Invoke-Apply (Get-Args 'c8b')
Assert-That ($r.Code -ne 0) "exit code should be non-zero, was $($r.Code)"
Assert-That ($r.Out -match "step 4.*printing") 'refusal should come from step 4'
Assert-That (Test-Untouched) 'target file changed'
Assert-That ($S.uploads.Count -eq 1 -and $S.uploads[0] -like 'backups/*') 'only the backup upload should exist'
Assert-That (-not ($r.Log -contains 'POST /printer/firmware_restart')) 'restart was sent'
Add-Info 'one write (the backup copy under backups/) is expected here; the config file itself is untouched'
Complete-Case

# ---- 9 never ready after restart
Start-Case '9' 'after firmware_restart the machine never returns to ready, -RestartTimeoutSec 10'
Reset-Mock @{ restartNever = $true }
$r = Invoke-Apply ((Get-Args 'c9') + @('-RestartTimeoutSec', '10'))
Assert-That ($r.Code -ne 0) "exit code should be non-zero, was $($r.Code)"
Assert-That ($r.Out -match 'not ready within 10s') 'timeout message missing'
Assert-That ($r.Out -match 'ROLLBACK: powershell') 'rollback command missing'
Assert-That ($r.Out -notmatch 'LEDGER \|') 'a LEDGER line was printed although restart failed'
Assert-That ($r.Sec -ge 9 -and $r.Sec -lt 40) "unexpected duration $($r.Sec)s"
Add-Info "file on machine was already replaced (hash = new): $((Get-Sha256 ([byte[]]$S.files['overrides.cfg'])) -eq $newSha)"
Complete-Case

# ---- 11 RemotePath tricks
Start-Case '11' '-RemotePath with .. or absolute path'
Reset-Mock
$mustReject = '../x.cfg', '/etc/passwd', 'C:\x.cfg', 'a/../b.cfg', '..\x.cfg', '%2e%2e/x.cfg', 'macros/', '-x.cfg'
foreach ($p in $mustReject) {
    Reset-Mock
    $r = Invoke-Apply (Get-Args 'c11' $origSha $p)
    Assert-That ($r.Code -ne 0) "RemotePath '$p' exit code was $($r.Code)"
    Assert-That ($r.Log.Count -eq 0) "RemotePath '$p' caused $($r.Log.Count) request(s)"
    Assert-That ($r.Out -match 'RemotePath must be a relative path') "RemotePath '$p' not rejected by the path check"
}
foreach ($p in 'a/./b.cfg', 'a//b.cfg', 'a..b.cfg', 'x.cfg?y=1') {
    Reset-Mock
    $r = Invoke-Apply (Get-Args 'c11' $origSha $p)
    Add-Info ("RemotePath '$p' -> exit $($r.Code), writes $($r.Writes), requests: " + ($r.Log -join ' ; '))
    Assert-That ($r.Writes -eq 0) "RemotePath '$p' caused a write"
}
Complete-Case

# ---- 12 BaseUrl
Start-Case '12' '-BaseUrl not http://127.0.0.1:<port> -> rejected'
foreach ($u in "http://127.0.0.2:$port", "http://localhost:$port", "https://127.0.0.1:$port", "$Url/x", "$Url/", 'http://127.0.0.1', 'ftp://127.0.0.1:21') {
    Reset-Mock
    $r = Invoke-Apply @('-BaseUrl', $u, '-RemotePath', 'overrides.cfg', '-LocalFile', $newFile, '-ExpectedSha256', $origSha, '-Reason', 'mocktest-c12')
    Assert-That ($r.Code -ne 0) "BaseUrl '$u' exit code was $($r.Code)"
    Assert-That ($r.Out -match 'BaseUrl must look like') "BaseUrl '$u' not rejected by the BaseUrl check"
    Assert-That ($r.Log.Count -eq 0) "BaseUrl '$u' caused $($r.Log.Count) request(s) to the mock"
}
Complete-Case

# ---------------------------------------------------------------- finish
try { $S.listener.Stop() } catch { }
try { [void]$psh.EndInvoke($async) } catch { }
$psh.Dispose(); $rs.Dispose()
Remove-MockBackups

$failed = @($script:Results | Where-Object { -not $_.Pass })
$head = "# apply-config mock run`r`nscript: $ScriptPath`r`nrun: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')   cases: $($script:Results.Count)   failed: $($failed.Count)`r`n`r`n"
[IO.File]::WriteAllText($ReportPath, $head + $script:Md.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Output ''
Write-Output "cases: $($script:Results.Count)  failed: $($failed.Count)  transcript: $ReportPath"
if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
