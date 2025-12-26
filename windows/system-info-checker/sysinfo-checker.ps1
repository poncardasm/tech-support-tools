<#
.SYNOPSIS
    Gathers comprehensive system information and generates a detailed report.

.DESCRIPTION
    This script collects hardware and software information from the local computer including:
    - Operating System details
    - CPU specifications
    - Motherboard information
    - Memory (RAM) configuration with DDR version detection
    - GPU/Graphics card details

    The information is logged to a date-stamped file and optionally returned as structured objects.
    The script provides detailed RAM information including XMP/DOCP configuration notes.

.PARAMETER LogPath
    Specifies the directory where the log file will be created.
    Default: Current directory

.PARAMETER LogFileName
    Specifies the name of the log file. If not provided, uses format: YYYY-MM-DD-SystemInfo.log

.PARAMETER NoLogFile
    If specified, skips creating a log file and only returns objects to the pipeline.

.PARAMETER PassThru
    If specified, returns structured objects in addition to creating the log file.

.EXAMPLE
    .\Get-SystemInfo.ps1

    Runs the system information checker with default settings, creating a log file
    in the current directory with today's date.

.EXAMPLE
    .\Get-SystemInfo.ps1 -LogPath "C:\Logs" -Verbose

    Creates the log file in C:\Logs and displays verbose progress information.

.EXAMPLE
    .\Get-SystemInfo.ps1 -NoLogFile -PassThru | Export-Csv "system-info.csv" -NoTypeInformation

    Skips log file creation and exports the system information to a CSV file.

.EXAMPLE
    $systemInfo = .\Get-SystemInfo.ps1 -PassThru

    Creates the log file and also captures the system information as objects for further processing.

.NOTES
    Author: Mchael Poncardas (m@poncardas.com)
    Version: 2.1
    Last Updated: 2025-12-26
    Requires: PowerShell 5.1 or later
    Requires Administrator: No

.LINK
    https://github.com/poncardasm/tech-support-tools
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$LogPath = $PWD.Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogFileName,

    [Parameter()]
    [switch]$NoLogFile,

    [Parameter()]
    [switch]$PassThru
)

#region Helper Functions

function Write-Log {
    <#
    .SYNOPSIS
        Writes text to the log file.

    .DESCRIPTION
        Appends text to the script's log file if logging is enabled.

    .PARAMETER Text
        The text to write to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    if (-not $script:NoLogFile -and $script:logFile) {
        try {
            $Text | Out-File -FilePath $script:logFile -Append -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to write to log file: $_"
        }
    }
}

function Get-MemoryDDRVersion {
    <#
    .SYNOPSIS
        Determines DDR version from memory part number.

    .DESCRIPTION
        Analyzes the memory module part number to identify DDR version (DDR3/DDR4/DDR5).

    .PARAMETER PartNumber
        The memory module part number.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PartNumber
    )

    if ($PartNumber -match "D5") { return "DDR5" }
    elseif ($PartNumber -match "D4") { return "DDR4" }
    elseif ($PartNumber -match "D3") { return "DDR3" }
    else { return "Unknown" }
}

function Get-MemoryRatedSpeed {
    <#
    .SYNOPSIS
        Extracts rated speed from memory part number.

    .DESCRIPTION
        Attempts to determine the maximum rated speed of a memory module from its part number.

    .PARAMETER PartNumber
        The memory module part number.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PartNumber
    )

    # Common speed patterns in part numbers
    $speedPatterns = @('6400', '6000', '5600', '5200', '4800', '4400', '4000', '3600', '3200', '3000', '2666', '2400', '2133')

    foreach ($speed in $speedPatterns) {
        if ($PartNumber -match $speed) {
            return $speed
        }
    }

    return "Unknown"
}

#endregion

#region Main Script

try {
    # Initialize logging
    $date = Get-Date -Format "yyyy-MM-dd"

    if (-not $NoLogFile) {
        if (-not $LogFileName) {
            $LogFileName = "$date-SystemInfo.log"
        }

        $script:logFile = Join-Path -Path $LogPath -ChildPath $LogFileName

        # Remove existing log file to start fresh
        if (Test-Path $script:logFile) {
            Write-Verbose "Removing existing log file: $script:logFile"
            Remove-Item $script:logFile -Force -ErrorAction Stop
        }

        Write-Verbose "Log file will be created at: $script:logFile"
    }
    else {
        Write-Verbose "Log file creation disabled (-NoLogFile specified)"
    }

    # Prompt user to start (maintaining original interactive behavior)
    if (-not $NoLogFile) {
        Write-Host ""
        Write-Host "+-----------------------------------------------------------------------------+"
        Write-Host "|                             SYSTEM INFO CHECKER                             |"
        Write-Host "+-----------------------------------------------------------------------------+"
        Write-Host "| About        : Gathers comprehensive system information and generates a     |"
        Write-Host "|                detailed report.                                             |"
        Write-Host "| Author       : Mchael Poncardas                                             |"
        Write-Host "| Email        : m@poncardas.com                                              |"
        Write-Host "| Version      : 2.1                                                          |"
        Write-Host "| Last Updated : 2025-12-26                                                   |"
        Write-Host "| Requires     : PowerShell 5.1 or later                                      |"
        Write-Host "+-----------------------------------------------------------------------------+"
        Write-Host ""
        Read-Host -Prompt "Press 'Enter' key to run System Info checker"
    }

    # Write log header
    Write-Log "+-----------------------------------------------------------------------------+"
    Write-Log "|                             SYSTEM INFO CHECKER                             |"
    Write-Log "+-----------------------------------------------------------------------------+"
    Write-Log "| About        : Gathers comprehensive system information and generates a     |"
    Write-Log "|                detailed report.                                             |"
    Write-Log "| Author       : Mchael Poncardas                                             |"
    Write-Log "| Email        : m@poncardas.com                                              |"
    Write-Log "| Version      : 2.1                                                          |"
    Write-Log "| Last Updated : 2025-12-26                                                   |"
    Write-Log "| Requires     : PowerShell 5.1 or later                                      |"
    Write-Log "+-----------------------------------------------------------------------------+"
    Write-Log ""
    Write-Log "=== System Information Log ==="
    Write-Log "Log Date: $date"
    Write-Log "-----------------------------------"
    Write-Log ""

    Write-Verbose "Gathering system information..."

    # Collection object to store all results
    $systemInformation = [PSCustomObject]@{
        OperatingSystem = $null
        CPU = $null
        Motherboard = $null
        Memory = @()
        GPU = @()
        CollectionDate = Get-Date
    }

    #region Operating System Information

    Write-Verbose "Retrieving operating system information..."
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

        $osInfo = [PSCustomObject]@{
            Caption = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
            TotalVisibleMemoryGB = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
        }

        $systemInformation.OperatingSystem = $osInfo

        Write-Log "===================================="
        Write-Log "=== Operating System Information ==="
        Write-Log "===================================="
        Write-Log "Caption: $($osInfo.Caption)"
        Write-Log "Version: $($osInfo.Version)"
        Write-Log "Build Number: $($osInfo.BuildNumber)"
        Write-Log "OS Architecture: $($osInfo.Architecture)"
        Write-Log ""

        Write-Debug "OS Info: $($osInfo | ConvertTo-Json)"
    }
    catch {
        Write-Error "Failed to retrieve operating system information: $_"
        throw
    }

    #endregion

    #region CPU Information

    Write-Verbose "Retrieving CPU information..."
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop

        $cpuInfo = [PSCustomObject]@{
            Name = $cpu.Name
            NumberOfCores = $cpu.NumberOfCores
            NumberOfLogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeedMHz = $cpu.MaxClockSpeed
        }

        $systemInformation.CPU = $cpuInfo

        Write-Log "======================="
        Write-Log "=== CPU Information ==="
        Write-Log "======================="
        Write-Log "Name: $($cpuInfo.Name)"
        Write-Log "Number Of Cores: $($cpuInfo.NumberOfCores)"
        Write-Log "Number Of Logical Processors: $($cpuInfo.NumberOfLogicalProcessors)"
        Write-Log "Max Clock Speed: $($cpuInfo.MaxClockSpeedMHz) MHz"
        Write-Log ""

        Write-Debug "CPU Info: $($cpuInfo | ConvertTo-Json)"
    }
    catch {
        Write-Error "Failed to retrieve CPU information: $_"
        throw
    }

    #endregion

    #region Motherboard Information

    Write-Verbose "Retrieving motherboard information..."
    try {
        $motherboard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction Stop

        $motherboardInfo = [PSCustomObject]@{
            Manufacturer = $motherboard.Manufacturer
            Product = $motherboard.Product
            Version = $motherboard.Version
            SerialNumber = $motherboard.SerialNumber
        }

        $systemInformation.Motherboard = $motherboardInfo

        Write-Log "==============================="
        Write-Log "=== Motherboard Information ==="
        Write-Log "==============================="
        Write-Log "Manufacturer: $($motherboardInfo.Manufacturer)"
        Write-Log "Product: $($motherboardInfo.Product)"
        Write-Log "Version: $($motherboardInfo.Version)"
        Write-Log "Serial Number: $($motherboardInfo.SerialNumber)"
        Write-Log ""

        Write-Debug "Motherboard Info: $($motherboardInfo | ConvertTo-Json)"
    }
    catch {
        Write-Error "Failed to retrieve motherboard information: $_"
        throw
    }

    #endregion

    #region Memory Information

    Write-Verbose "Retrieving memory information..."
    try {
        $memoryModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop

        Write-Log "================================"
        Write-Log "=== Memory (RAM) Information ==="
        Write-Log "================================"
        Write-Log "Total Visible Memory: $($osInfo.TotalVisibleMemoryGB) GB"
        Write-Log "Detailed Module Info:"
        Write-Log ""

        foreach ($module in $memoryModules) {
            $capacityGB = [math]::Round(($module.Capacity / 1GB), 2)
            $ddrVersion = Get-MemoryDDRVersion -PartNumber $module.PartNumber
            $ratedSpeed = Get-MemoryRatedSpeed -PartNumber $module.PartNumber

            $memoryInfo = [PSCustomObject]@{
                Manufacturer = $module.Manufacturer
                CapacityGB = $capacityGB
                ConfiguredClockSpeedMHz = $module.ConfiguredClockSpeed
                MaxRatedSpeedMHz = $ratedSpeed
                DDRVersion = $ddrVersion
                FormFactor = $module.FormFactor
                PartNumber = $module.PartNumber
                ConfiguredVoltageMV = $module.ConfiguredVoltage
            }

            $systemInformation.Memory += $memoryInfo

            Write-Log "---------------------------------"
            Write-Log "Manufacturer: $($memoryInfo.Manufacturer)"
            Write-Log "Capacity: $($memoryInfo.CapacityGB) GB"
            Write-Log "Current Running Speed: $($memoryInfo.ConfiguredClockSpeedMHz) MHz"
            Write-Log "Maximum Rated Speed: $($memoryInfo.MaxRatedSpeedMHz) MHz"
            Write-Log "DDR Version: $($memoryInfo.DDRVersion)"
            Write-Log "Form Factor: $($memoryInfo.FormFactor)"
            Write-Log "Part Number: $($memoryInfo.PartNumber)"
            Write-Log "Configured Voltage: $($memoryInfo.ConfiguredVoltageMV) mV"
            Write-Log ""

            if ($ratedSpeed -ne "Unknown" -and $ratedSpeed -ne $module.ConfiguredClockSpeed) {
                Write-Log "Note: To achieve maximum rated speed of $ratedSpeed MHz,"
                Write-Log "enable XMP/DOCP in your BIOS settings."
                Write-Log ""
            }

            Write-Debug "Memory Module: $($memoryInfo | ConvertTo-Json)"
        }

        Write-Log ""
    }
    catch {
        Write-Error "Failed to retrieve memory information: $_"
        throw
    }

    #endregion

    #region GPU Information

    Write-Verbose "Retrieving GPU information..."
    try {
        $gpuList = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop

        Write-Log "======================="
        Write-Log "=== GPU Information ==="
        Write-Log "======================="

        foreach ($gpu in $gpuList) {
            $adapterRAMGB = if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) {
                [math]::Round(($gpu.AdapterRAM / 1GB), 2)
            } else {
                $null
            }

            $gpuInfo = [PSCustomObject]@{
                Name = $gpu.Name
                DriverVersion = $gpu.DriverVersion
                AdapterRAMGB = $adapterRAMGB
                VideoProcessor = $gpu.VideoProcessor
            }

            $systemInformation.GPU += $gpuInfo

            Write-Log "---------------------------------"
            Write-Log "Name: $($gpuInfo.Name)"
            Write-Log "Driver Version: $($gpuInfo.DriverVersion)"

            if ($gpuInfo.AdapterRAMGB) {
                Write-Log "Adapter RAM (approx. VRAM): $($gpuInfo.AdapterRAMGB) GB"
            }
            else {
                Write-Log "Adapter RAM (approx. VRAM): Not available"
            }

            Write-Log "Video Processor: $($gpuInfo.VideoProcessor)"
            Write-Log "(Note: The AdapterRAM property may not always accurately represent VRAM)"
            Write-Log ""

            Write-Debug "GPU Info: $($gpuInfo | ConvertTo-Json)"
        }

        Write-Log ""
    }
    catch {
        Write-Error "Failed to retrieve GPU information: $_"
        throw
    }

    #endregion

    # Success message
    if (-not $NoLogFile) {
        Write-Host "Success! Please check the $script:logFile"
        Write-Host "Opening log file..."
        Invoke-Item $script:logFile
        Read-Host -Prompt "Press 'Enter' to exit"
    }
    else {
        Write-Verbose "System information collection completed successfully"
    }

    # Return objects if requested
    if ($PassThru -or $NoLogFile) {
        Write-Output $systemInformation
    }
}
catch {
    Write-Error "An error occurred while gathering system information: $_"
    exit 1
}
finally {
    Write-Verbose "Script execution completed"
}

#endregion
