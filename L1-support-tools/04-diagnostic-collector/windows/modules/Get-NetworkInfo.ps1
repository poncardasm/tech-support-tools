# Network Information Collector
# Gathers network interface configuration

function Get-NetworkInfo {
    <#
    .SYNOPSIS
        Collects network interface configuration information.
    .OUTPUTS
        Hashtable containing network details.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        Adapters = @()
        DNS = @()
        Routes = @()
    }

    try {
        # Get network adapters with IP
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue | 
                Where-Object { $_.AddressFamily -eq 'IPv4' -and -not $_.IPAddress.StartsWith('127.') }

            $ipv6Config = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue | 
                Where-Object { $_.AddressFamily -eq 'IPv6' -and -not $_.IPAddress.StartsWith('fe80:') }

            $gateway = Get-NetRoute -InterfaceIndex $adapter.InterfaceIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue

            $adapterInfo = @{
                Name = $adapter.Name
                InterfaceDescription = $adapter.InterfaceDescription
                MacAddress = $adapter.MacAddress
                LinkSpeed = $adapter.LinkSpeed
                Status = $adapter.Status
                IPv4Addresses = $ipConfig | ForEach-Object { $_.IPAddress }
                IPv6Addresses = $ipv6Config | ForEach-Object { $_.IPAddress }
                PrefixLengths = $ipConfig | ForEach-Object { $_.PrefixLength }
                Gateways = $gateway | ForEach-Object { $_.NextHop }
            }

            $result.Adapters += $adapterInfo
        }
    }
    catch {
        Write-Warning "Failed to collect network adapter info: $_"
    }

    try {
        # Get DNS settings
        $dnsServers = Get-DnsClientServerAddress -ErrorAction SilentlyContinue | 
            Where-Object { $_.AddressFamily -eq 2 } |  # IPv4
            Select-Object -ExpandProperty ServerAddresses -Unique

        $result.DNS = $dnsServers
    }
    catch {
        Write-Warning "Failed to collect DNS info: $_"
    }

    try {
        # Get routing information
        $routes = Get-NetRoute -ErrorAction SilentlyContinue | 
            Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' }

        $result.Routes = $routes | ForEach-Object {
            @{
                InterfaceAlias = $_.InterfaceAlias
                NextHop = $_.NextHop
                RouteMetric = $_.RouteMetric
            }
        }
    }
    catch {
        Write-Warning "Failed to collect routing info: $_"
    }

    # Get hostname and domain info
    $result.Hostname = $env:COMPUTERNAME
    $result.Domain = $env:USERDNSDOMAIN
    $result.FullHostname = [System.Net.Dns]::GetHostName()

    return $result
}
