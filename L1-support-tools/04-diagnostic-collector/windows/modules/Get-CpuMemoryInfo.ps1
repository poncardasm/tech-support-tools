# CPU and Memory Information Collector
# Gathers CPU and memory usage statistics

function Get-CpuMemoryInfo {
    <#
    .SYNOPSIS
        Collects CPU and memory usage information.
    .OUTPUTS
        Hashtable containing CPU and memory details.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        CPU = @{}
        RAM = @{}
        TopProcesses = @()
    }

    try {
        # Get CPU information
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue

        $cpuName = if ($cpu -is [array]) { $cpu[0].Name } else { $cpu.Name }
        $cpuCores = if ($cpu -is [array]) { $cpu[0].NumberOfCores } else { $cpu.NumberOfCores }
        $cpuLogical = if ($cpu -is [array]) { $cpu[0].NumberOfLogicalProcessors } else { $cpu.NumberOfLogicalProcessors }

        $result.CPU = @{
            Name = $cpuName
            Manufacturer = if ($cpu -is [array]) { $cpu[0].Manufacturer } else { $cpu.Manufacturer }
            Cores = $cpuCores
            LogicalProcessors = $cpuLogical
            MaxClockSpeed = if ($cpu -is [array]) { $cpu[0].MaxClockSpeed } else { $cpu.MaxClockSpeed }
            PercentUsed = if ($cpuCounter) { [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 1) } else { 0 }
            Architecture = if ($cpu -is [array]) { $cpu[0].Architecture } else { $cpu.Architecture }
        }
    }
    catch {
        Write-Warning "Failed to collect CPU info: $_"
        $result.CPU = @{ Error = "CPU collection failed: $_" }
    }

    try {
        # Get memory information
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue

        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRAM = [math]::Round($totalRAM - $freeRAM, 2)
        $percentUsed = if ($totalRAM -gt 0) { [math]::Round(($usedRAM / $totalRAM) * 100, 1) } else { 0 }

        $result.RAM = @{
            TotalGB = $totalRAM
            UsedGB = $usedRAM
            FreeGB = $freeRAM
            PercentUsed = $percentUsed
            PercentFree = [math]::Round(100 - $percentUsed, 1)
            VirtualTotalGB = [math]::Round($os.TotalVirtualMemorySize / 1MB, 2)
            VirtualFreeGB = [math]::Round($os.FreeVirtualMemory / 1MB, 2)
        }
    }
    catch {
        Write-Warning "Failed to collect memory info: $_"
        $result.RAM = @{ Error = "Memory collection failed: $_" }
    }

    try {
        # Get top processes by memory usage
        $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | ForEach-Object {
            @{
                Name = $_.ProcessName
                Id = $_.Id
                MemoryMB = [math]::Round($_.WorkingSet / 1MB, 1)
                CPUPercent = if ($_.CPU) { [math]::Round($_.CPU, 1) } else { 0 }
            }
        }
        $result.TopProcesses = $processes
    }
    catch {
        Write-Warning "Failed to collect process info: $_"
    }

    return $result
}
