# Service Information Collector
# Gathers information about Windows services

function Get-ServiceInfo {
    <#
    .SYNOPSIS
        Collects Windows service information.
    .OUTPUTS
        Array of hashtables containing service details.
    #>
    [CmdletBinding()]
    param()

    $services = @()

    try {
        # Get all services
        $allServices = Get-Service -ErrorAction SilentlyContinue

        # Get detailed service info via WMI for more details
        $wmiServices = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue | 
            Select-Object Name, DisplayName, State, Status, StartMode, StartName

        # Focus on running services and automatic services that are stopped
        $filteredServices = $allServices | Where-Object {
            $_.Status -eq 'Running' -or 
            ($_.StartType -eq 'Automatic' -and $_.Status -ne 'Running')
        } | Select-Object -First 50

        foreach ($svc in $filteredServices) {
            $wmiInfo = $wmiServices | Where-Object { $_.Name -eq $svc.Name } | Select-Object -First 1

            $services += @{
                Name = $svc.Name
                DisplayName = $svc.DisplayName
                Status = $svc.Status
                StartType = $svc.StartType
                ServiceType = $svc.ServiceType
                Account = if ($wmiInfo) { $wmiInfo.StartName } else { 'Unknown' }
            }
        }

        # Add summary counts
        $services += @{
            _Summary = @{
                Total = $allServices.Count
                Running = ($allServices | Where-Object { $_.Status -eq 'Running' }).Count
                Stopped = ($allServices | Where-Object { $_.Status -eq 'Stopped' }).Count
                AutoNotRunning = ($allServices | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }).Count
            }
        }
    }
    catch {
        Write-Warning "Failed to collect service info: $_"
        $services += @{
            Error = "Service collection failed: $_"
        }
    }

    return $services
}
