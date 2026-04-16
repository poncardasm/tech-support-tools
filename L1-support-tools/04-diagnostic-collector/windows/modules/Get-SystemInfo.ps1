# System Information Collector
# Gathers basic system details: hostname, OS version, uptime, manufacturer, model

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Collects basic system information.
    .OUTPUTS
        Hashtable containing system details.
    #>
    [CmdletBinding()]
    param()

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue

        # Calculate uptime
        $uptime = $null
        if ($os.LastBootUpTime) {
            $uptime = (Get-Date) - $os.LastBootUpTime
        }

        # Get Windows version info
        $windowsVersion = $null
        try {
            $windowsVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        }
        catch {
            # Registry access failed, use WMI
        }

        $displayVersion = if ($windowsVersion.DisplayVersion) {
            $windowsVersion.DisplayVersion
        }
        elseif ($os.Version) {
            $os.Version
        }
        else {
            'Unknown'
        }

        return @{
            Hostname = $env:COMPUTERNAME
            Domain = $env:USERDOMAIN
            OS_Name = $os.Caption
            OS_Version = $displayVersion
            OS_Architecture = $os.OSArchitecture
            InstallDate = $os.InstallDate
            LastBootUpTime = $os.LastBootUpTime
            Uptime = if ($uptime) {
                "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
            }
            else {
                'Unknown'
            }
            Manufacturer = $computer.Manufacturer
            Model = $computer.Model
            SystemType = $computer.SystemType
            BIOS_Version = $bios.SMBIOSBIOSVersion
            BIOS_Date = $bios.ReleaseDate
            SerialNumber = $bios.SerialNumber
            TotalPhysicalMemory = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        }
    }
    catch {
        Write-Warning "Failed to collect system info: $_"
        return @{
            Hostname = $env:COMPUTERNAME
            Error = "Collection failed: $_"
        }
    }
}
