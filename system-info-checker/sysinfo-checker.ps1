<#
System Info Checker
Author: Mchael Poncardas (https://github.com/poncardasm)
Description: A script to gather system information.
#>


# Retrieve operating system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Retrieve CPU details
$cpu = Get-CimInstance -ClassName Win32_Processor

# Retrieve memory (RAM) details
$memory = Get-CimInstance -ClassName Win32_PhysicalMemory

# Retrieve GPU details
$gpu = Get-CimInstance -ClassName Win32_VideoController

# Display Operating System Information
Write-Host "=== Operating System Information ==="
Write-Host "Caption: $($os.Caption)"
Write-Host "Version: $($os.Version)"
Write-Host "Build Number: $($os.BuildNumber)"
Write-Host "OS Architecture: $($os.OSArchitecture)"
Write-Host ""

# Display CPU Information
Write-Host "=== CPU Information ==="
Write-Host "Name: $($cpu.Name)"
Write-Host "Number Of Cores: $($cpu.NumberOfCores)"
Write-Host "Number Of Logical Processors: $($cpu.NumberOfLogicalProcessors)"
Write-Host "Max Clock Speed: $($cpu.MaxClockSpeed) MHz"
Write-Host ""

# Display Memory (RAM) Information
$totalMemoryGB = [math]::Round((($os.TotalVisibleMemorySize) / 1MB), 2)
Write-Host "=== Memory (RAM) Information ==="
Write-Host "Total Visible Memory: $totalMemoryGB GB"
Write-Host "Detailed Module Info:"
foreach ($mod in $memory) {
    $capacityGB = [math]::Round(($mod.Capacity / 1GB), 2)
    Write-Host "---------------------------------"
    Write-Host "Manufacturer: $($mod.Manufacturer)"
    Write-Host "Capacity: $capacityGB GB"
    Write-Host "Speed: $($mod.Speed) MHz"
}
Write-Host ""

# Display GPU Information
Write-Host "=== GPU Information ==="
foreach ($g in $gpu) {
    Write-Host "---------------------------------"
    Write-Host "Name: $($g.Name)"
    Write-Host "Driver Version: $($g.DriverVersion)"
    Write-Host "Adapter RAM: $([math]::Round(($g.AdapterRAM / 1GB), 2)) GB"
    Write-Host "Video Processor: $($g.VideoProcessor)"
}
