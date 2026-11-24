# backup-orca.ps1 - copy %APPDATA%\OrcaSlicer\user verbatim into profiles\orca_backup\<date>\
# and write manifest.sha256. Source is read-only. Refuses to overwrite an existing backup.
# Does not print file contents (.info files contain user_id).
[CmdletBinding()]
param(
    [string]$Date = (Get-Date -Format 'yyyy-MM-dd'),
    [string]$Source = (Join-Path $env:APPDATA 'OrcaSlicer\user')
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\lib\Fleet.psm1') -Force

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$dest = Join-Path $root "profiles\orca_backup\$Date"
if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
if (Test-Path -LiteralPath $dest) { throw "Backup already exists, not overwriting: $dest" }

New-Item -ItemType Directory -Path $dest | Out-Null
Copy-Item -Path (Join-Path $Source '*') -Destination $dest -Recurse

$srcFull = (Resolve-Path -LiteralPath $Source).Path.TrimEnd('\')
$files = Get-ChildItem -LiteralPath $srcFull -Recurse -File
$lines = foreach ($f in $files) {
    $rel = $f.FullName.Substring($srcFull.Length + 1)
    $copy = Join-Path $dest $rel
    $h = Get-FleetSha256 $copy
    if ($h -ne (Get-FleetSha256 $f.FullName)) { throw "Hash mismatch after copy: $rel" }
    '{0}  {1}' -f $h, ($rel -replace '\\', '/')
}
[System.IO.File]::WriteAllLines((Join-Path $dest 'manifest.sha256'), [string[]]$lines, (New-Object System.Text.UTF8Encoding($false)))

$json = @(Get-ChildItem -LiteralPath $dest -Recurse -File -Filter *.json)
$mach = @($json | Where-Object { $_.DirectoryName -match '\\machine$' }).Count
$fil = @($json | Where-Object { $_.DirectoryName -match '\\filament(\\|$)' }).Count
$proc = @($json | Where-Object { $_.DirectoryName -match '\\process$' }).Count
"Backup: $dest"
"Files copied: $(@($lines).Count) (manifest.sha256 written)"
"json: machine=$mach filament=$fil process=$proc"
