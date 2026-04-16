# Installed Software Information Collector
# Gathers information about installed software

function Get-InstalledSoftwareInfo {
    <#
    .SYNOPSIS
        Collects information about installed software.
    .OUTPUTS
        Hashtable containing software inventory.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        InstalledApps = @()
        TotalCount = 0
        ByPublisher = @{}
    }

    try {
        # Get software from registry (64-bit)
        $regPath64 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        $software64 = Get-ItemProperty -Path $regPath64 -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -and -not $_.SystemComponent }

        # Get software from registry (32-bit on 64-bit systems)
        $regPath32 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        $software32 = Get-ItemProperty -Path $regPath32 -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -and -not $_.SystemComponent }

        # Combine and deduplicate
        $allSoftware = $software64 + $software32 | 
            Sort-Object DisplayName -Unique |
            Select-Object -First 100  # Limit to first 100 for performance

        foreach ($app in $allSoftware) {
            $appInfo = @{
                Name = $app.DisplayName
                Version = $app.DisplayVersion
                Publisher = $app.Publisher
                InstallDate = $app.InstallDate
                InstallLocation = $app.InstallLocation
                UninstallString = if ($app.UninstallString) { $app.UninstallString.Substring(0, [Math]::Min(50, $app.UninstallString.Length)) + '...' } else { $null }
            }

            $result.InstalledApps += $appInfo

            # Count by publisher
            $publisher = $app.Publisher
            if ($publisher) {
                if (-not $result.ByPublisher[$publisher]) {
                    $result.ByPublisher[$publisher] = 0
                }
                $result.ByPublisher[$publisher]++
            }
        }

        $result.TotalCount = ($software64 + $software32 | Sort-Object DisplayName -Unique).Count

        # Get top publishers
        $result.TopPublishers = $result.ByPublisher.GetEnumerator() | 
            Sort-Object Value -Descending | 
            Select-Object -First 10 | 
            ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
    }
    catch {
        Write-Warning "Failed to collect installed software info: $_"
        $result.Error = "Software collection failed: $_"
    }

    return $result
}
