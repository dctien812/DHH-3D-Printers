# Fleet.psm1 - read-only helpers for the 6-printer fleet (spec 001).
# Rules: Moonraker via HTTP GET only; no packet is ever sent to Bambu printers;
# secrets (access code, serial) are never printed or returned.
# PowerShell 5.1. File is ASCII on purpose (no BOM needed).

Set-StrictMode -Version 2.0

function Get-FleetSha256 {
    <# SHA256 (lowercase hex) of a file. #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Path)
    process {
        (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
    }
}

function Test-MoonrakerPathAllowed {
    <# $true only for the read-only GET endpoints: anchored, no "..", no encoded dots. #>
    param([string]$Path)
    if ($Path -match '\.\.|%2e|%5c|\\') { return $false }
    $Path -match '^/(printer/info|printer/objects/query(\?.*)?|server/files/.+|server/gcode_store(\?.*)?|machine/system_info|machine/proc_stats|machine/update/status|server/history/.*)$'
}

function Test-SsdpSource {
    <# Accept a parsed SSDP packet only when its Location equals the real sender IP. #>
    param($Parsed, [string]$SenderIp)
    [bool]$Parsed -and [bool]$Parsed.Ip -and ($Parsed.Ip -eq $SenderIp)
}

function Invoke-MoonrakerGet {
    <# Single GET to Moonraker. Only the allowed read endpoints are accepted. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Ip,
        [Parameter(Mandatory)][string]$Path,       # e.g. /printer/info
        [int]$TimeoutSec = 10
    )
    if (-not (Test-MoonrakerPathAllowed $Path)) {
        throw "Path not allowed (read-only endpoints only): $Path"
    }
    $uri = "http://$Ip$Path"
    Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec $TimeoutSec -UseBasicParsing
}

function Get-MoonrakerInfo {
    <# /printer/info -> result object (state, klippy_state fields, hostname, software_version). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Ip, [int]$TimeoutSec = 10)
    (Invoke-MoonrakerGet -Ip $Ip -Path '/printer/info' -TimeoutSec $TimeoutSec).result
}

function Get-MoonrakerObjects {
    <# /printer/objects/query?obj1&obj2=field1,field2 -> result.status.
       -Objects: hashtable name -> string[] of fields (empty = all fields). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Ip,
        [Parameter(Mandatory)][hashtable]$Objects,
        [int]$TimeoutSec = 10
    )
    $parts = foreach ($k in $Objects.Keys) {
        $f = @($Objects[$k])
        if ($f.Count -gt 0) { '{0}={1}' -f [uri]::EscapeDataString($k), ($f -join ',') }
        else { [uri]::EscapeDataString($k) }
    }
    $q = '/printer/objects/query?' + ($parts -join '&')
    (Invoke-MoonrakerGet -Ip $Ip -Path $q -TimeoutSec $TimeoutSec).result.status
}

function Get-MoonrakerFiles {
    <# /server/files/list?root=<root> -> file list; or -Download relative path under root
       via /server/files/<root>/<path> returned as text. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Ip,
        [string]$Root = 'config',
        [string]$RelPath,
        [int]$TimeoutSec = 20
    )
    if ($RelPath) {
        if ($RelPath -match '(^|[/\\])\.\.([/\\]|$)' -or $RelPath.StartsWith('/')) { throw "RelPath not allowed: $RelPath" }
        $enc = ($RelPath -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
        Invoke-MoonrakerGet -Ip $Ip -Path "/server/files/$Root/$enc" -TimeoutSec $TimeoutSec
    } else {
        (Invoke-MoonrakerGet -Ip $Ip -Path "/server/files/list?root=$Root" -TimeoutSec $TimeoutSec).result
    }
}

function Test-PrinterIdle {
    <# Returns $true only when klippy is ready and print_stats.state is not printing/paused.
       Returns $false on any doubt (no answer, unknown state). Read-only (GET). #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Ip, [int]$TimeoutSec = 10)
    try {
        $info = Get-MoonrakerInfo -Ip $Ip -TimeoutSec $TimeoutSec
        if ($info.state -ne 'ready') { return $false }
        $st = Get-MoonrakerObjects -Ip $Ip -Objects @{ print_stats = @('state') } -TimeoutSec $TimeoutSec
        return ($st.print_stats.state -in @('standby', 'complete', 'cancelled'))
    } catch {
        return $false
    }
}

function ConvertFrom-BambuSsdp {
    <# Parse one SSDP datagram text from a Bambu printer. Returns Model, Name, Version,
       Connect, Ip. The USN line (serial) and every other header are dropped. #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Text)
    process {
        $map = @{
            'DevModel.bambu.com'   = 'Model'
            'DevName.bambu.com'    = 'Name'
            'DevVersion.bambu.com' = 'Version'
            'DevConnect.bambu.com' = 'Connect'
            'Location'             = 'Ip'
        }
        $o = [ordered]@{ Model = $null; Name = $null; Version = $null; Connect = $null; Ip = $null }
        foreach ($line in ($Text -split "`r?`n")) {
            $i = $line.IndexOf(':')
            if ($i -lt 1) { continue }
            $key = $line.Substring(0, $i).Trim()
            if ($map.ContainsKey($key)) {
                $o[$map[$key]] = $line.Substring($i + 1).Trim()
            }
        }
        if ($null -eq $o.Model -and $null -eq $o.Name) { return }
        [pscustomobject]$o
    }
}

function Receive-BambuSsdp {
    <# Passive listen on UDP 2021 for -ListenSec seconds; sends nothing. Returns parsed
       objects (no serial) de-duplicated by Ip. #>
    [CmdletBinding()]
    param([int]$ListenSec = 15, [int]$Port = 2021)
    $udp = New-Object System.Net.Sockets.UdpClient
    $found = @{}
    try {
        $udp.Client.SetSocketOption('Socket', 'ReuseAddress', $true)
        $udp.Client.Bind((New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Any), $Port))
        $udp.Client.ReceiveTimeout = 1000
        $end = (Get-Date).AddSeconds($ListenSec)
        while ((Get-Date) -lt $end) {
            try {
                $ep = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Any), 0
                $bytes = $udp.Receive([ref]$ep)
            } catch [System.Net.Sockets.SocketException] { continue }
            $p = [System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-BambuSsdp
            if ($p -and (Test-SsdpSource -Parsed $p -SenderIp $ep.Address.ToString())) {
                if (-not $p.Ip) { $p.Ip = $ep.Address.ToString() }
                $found[$p.Ip] = $p
            }
        }
    } finally { $udp.Close() }
    $found.Values
}

Export-ModuleMember -Function Get-FleetSha256, Invoke-MoonrakerGet, Get-MoonrakerInfo, Get-MoonrakerObjects, Get-MoonrakerFiles, Test-PrinterIdle, ConvertFrom-BambuSsdp, Receive-BambuSsdp
