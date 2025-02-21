<#
System Info Checker
Author: Mchael Poncardas (https://github.com/poncardasm)
Description: A script to gather system information.
#>

# Prompt the user to press "Enter" to start
Read-Host -Prompt "Press 'Enter' key to run System Info checker"

# Get the current date in the desired format (YYYY-MM-DD)
$date = Get-Date -Format "yyyy-MM-dd"

# Define the log file name with the date included, e.g., 2025-02-19-SystemInfo.log
$logFile = "$date-SystemInfo.log"

# Remove the log file if it already exists to start fresh
if (Test-Path $logFile) {
    Remove-Item $logFile
}

# Function to write text to the log file
function Write-Log {
    param ([string]$text)
    $text | Out-File -FilePath $logFile -Append
}

# Write a header with the date inside the log file
Write-Log "=== System Information Log ==="
Write-Log "Log Date: $date"
Write-Log "-----------------------------------"
Write-Log ""

# Retrieve operating system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Retrieve CPU details
$cpu = Get-CimInstance -ClassName Win32_Processor

# Retrieve Motherboard details
$motherboard = Get-CimInstance -ClassName Win32_BaseBoard

# Retrieve memory (RAM) details
$memory = Get-CimInstance -ClassName Win32_PhysicalMemory

# Retrieve GPU details
$gpu = Get-CimInstance -ClassName Win32_VideoController

# Write Operating System Information
Write-Log "===================================="
Write-Log "=== Operating System Information ==="
Write-Log "===================================="
Write-Log "Caption: $($os.Caption)"
Write-Log "Version: $($os.Version)"
Write-Log "Build Number: $($os.BuildNumber)"
Write-Log "OS Architecture: $($os.OSArchitecture)"
Write-Log ""

# Write CPU Information
Write-Log "======================="
Write-Log "=== CPU Information ==="
Write-Log "======================="
Write-Log "Name: $($cpu.Name)"
Write-Log "Number Of Cores: $($cpu.NumberOfCores)"
Write-Log "Number Of Logical Processors: $($cpu.NumberOfLogicalProcessors)"
Write-Log "Max Clock Speed: $($cpu.MaxClockSpeed) MHz"
Write-Log ""

# Write Motherboard Information
Write-Log "==============================="
Write-Log "=== Motherboard Information ==="
Write-Log "==============================="
Write-Log "Manufacturer: $($motherboard.Manufacturer)"
Write-Log "Product: $($motherboard.Product)"
Write-Log "Version: $($motherboard.Version)"
Write-Log "Serial Number: $($motherboard.SerialNumber)"
Write-Log ""

# Write Memory (RAM) Information
$totalMemoryGB = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
Write-Log "================================"
Write-Log "=== Memory (RAM) Information ==="
Write-Log "================================"
Write-Log "Total Visible Memory: $totalMemoryGB GB"
Write-Log "Detailed Module Info:"
foreach ($mod in $memory) {
    $capacityGB = [math]::Round(($mod.Capacity / 1GB), 2)
    Write-Log "---------------------------------"
    Write-Log "Manufacturer: $($mod.Manufacturer)"
    Write-Log "Capacity: $capacityGB GB"
    Write-Log "Speed: $($mod.Speed) MHz"
    Write-Log "Form Factor: $($mod.FormFactor)"
    Write-Log "Part Number: $($mod.PartNumber)"
}
Write-Log ""

# Write GPU Information
Write-Log "======================="
Write-Log "=== GPU Information ==="
Write-Log "======================="
foreach ($g in $gpu) {
    Write-Log "---------------------------------"
    Write-Log "Name: $($g.Name)"
    Write-Log "Driver Version: $($g.DriverVersion)"
    if ($g.AdapterRAM -and $g.AdapterRAM -gt 0) {
        $adapterRAMGB = [math]::Round(($g.AdapterRAM / 1GB), 2)
        Write-Log "Adapter RAM (approx. VRAM): $adapterRAMGB GB"
    }
    else {
        Write-Log "Adapter RAM (approx. VRAM): Not available"
    }
    Write-Log "Video Processor: $($g.VideoProcessor)"
    Write-Log "(Note: The AdapterRAM property may not always accurately represent VRAM)"
}
Write-Log ""

# Notify the user that the script finished successfully and show the log file name
Write-Host "Success! Please check the $logFile"

# Wait for the user to press "Enter" before exiting
Read-Host -Prompt "Press 'Enter' to exit"
