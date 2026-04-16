# Disk Information Collector
# Gathers disk usage information with threshold detection

function Get-DiskInfo {
    <#
    .SYNOPSIS
        Collects disk volume information including usage and health status.
    .OUTPUTS
        Array of hashtables containing disk details.
    #>
    [CmdletBinding()]
    param()

    $disks = @()

    try {
        # Get volume information
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }

        foreach ($vol in $volumes) {
            $sizeGB = [math]::Round($vol.Size / 1GB, 2)
            $usedGB = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 2)
            $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
            $percentUsed = if ($vol.Size -gt 0) {
                [math]::Round(($vol.Size - $vol.SizeRemaining) / $vol.Size * 100, 1)
            }
            else {
                0
            }

            # Determine status based on thresholds
            $status = 'OK'
            if ($percentUsed -gt 90) {
                $status = 'CRITICAL'
            }
            elseif ($percentUsed -gt 80) {
                $status = 'WARNING HIGH'
            }

            $disks += @{
                Drive = "$($vol.DriveLetter):"
                FileSystem = $vol.FileSystem
                FileSystemLabel = $vol.FileSystemLabel
                TotalGB = $sizeGB
                UsedGB = $usedGB
                FreeGB = $freeGB
                PercentUsed = $percentUsed
                PercentFree = [math]::Round(100 - $percentUsed, 1)
                Status = $status
                HealthStatus = $vol.HealthStatus
            }
        }

        # Also get physical disk information
        try {
            $physicalDisks = Get-PhysicalDisk | Where-Object { $_.BusType -ne 'File Backed Virtual' }
            $disks += @{
                _PhysicalDisks = $physicalDisks | ForEach-Object {
                    @{
                        FriendlyName = $_.FriendlyName
                        MediaType = $_.MediaType
                        SizeGB = [math]::Round($_.Size / 1GB, 2)
                        HealthStatus = $_.HealthStatus
                        OperationalStatus = $_.OperationalStatus
                    }
                }
            }
        }
        catch {
            # Physical disk info optional
        }
    }
    catch {
        Write-Warning "Failed to collect disk info: $_"
        $disks += @{
            Error = "Disk collection failed: $_"
        }
    }

    return $disks
}
