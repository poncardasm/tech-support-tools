<#
System Info Checker
Author: Mchael Poncardas (https://github.com/poncardasm)
Description: A script to gather system information.
#>

# Define the log file path
$logFile = "SystemInfo.log"

# Remove the log file if it already exists to start fresh
if (Test-Path $logFile) {
  Remove-Item $logFile
}

# Function to write text to the log file
function Write-Log {
  param ([string]$text)
  $text | Out-File -FilePath $logFile -Append
}

# Retrieve operating system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Retrieve CPU details
$cpu = Get-CimInstance -ClassName Win32_Processor

# Retrieve memory (RAM) details
$memory = Get-CimInstance -ClassName Win32_PhysicalMemory

# Retrieve GPU details
$gpu = Get-CimInstance -ClassName Win32_VideoController

# Write Operating System Information
Write-Log "=== Operating System Information ==="
Write-Log "Caption: $($os.Caption)"
Write-Log "Version: $($os.Version)"
Write-Log "Build Number: $($os.BuildNumber)"
Write-Log "OS Architecture: $($os.OSArchitecture)"
Write-Log ""

# Write CPU Information
Write-Log "=== CPU Information ==="
Write-Log "Name: $($cpu.Name)"
Write-Log "Number Of Cores: $($cpu.NumberOfCores)"
Write-Log "Number Of Logical Processors: $($cpu.NumberOfLogicalProcessors)"
Write-Log "Max Clock Speed: $($cpu.MaxClockSpeed) MHz"
Write-Log ""

# Write Memory (RAM) Information
$totalMemoryGB = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
Write-Log "=== Memory (RAM) Information ==="
Write-Log "Total Visible Memory: $totalMemoryGB GB"
Write-Log "Detailed Module Info:"
foreach ($mod in $memory) {
  $capacityGB = [math]::Round(($mod.Capacity / 1GB), 2)
  Write-Log "---------------------------------"
  Write-Log "Manufacturer: $($mod.Manufacturer)"
  Write-Log "Capacity: $capacityGB GB"
  Write-Log "Speed: $($mod.Speed) MHz"
}
Write-Log ""

# Write GPU Information
Write-Log "=== GPU Information ==="
foreach ($g in $gpu) {
  Write-Log "---------------------------------"
  Write-Log "Name: $($g.Name)"
  Write-Log "Driver Version: $($g.DriverVersion)"
  Write-Log "Adapter RAM: $([math]::Round(($g.AdapterRAM / 1GB), 2)) GB"
  Write-Log "Video Processor: $($g.VideoProcessor)"
}
