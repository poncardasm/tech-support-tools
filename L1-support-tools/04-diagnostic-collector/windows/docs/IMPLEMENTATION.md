# Diagnostic Collector — Implementation Plan (Windows)

## 1. Project Setup

### 1.1 File Structure

```
diagnostic-collector/
├── diag-collect.ps1          # main script
├── modules/
│   ├── Get-SystemInfo.ps1
│   ├── Get-DiskInfo.ps1
│   ├── Get-NetworkInfo.ps1
│   ├── Get-ServiceInfo.ps1
│   ├── Get-EventLogInfo.ps1
│   └── Get-UpdateInfo.ps1
├── formatters/
│   ├── Format-Html.ps1
│   ├── Format-Markdown.ps1
│   └── Format-Json.ps1
├── tests/
│   └── diag-collect.Tests.ps1
└── README.md
```

---

## 2. Main Script (diag-collect.ps1)

```powershell
param(
    [switch]$Html,
    [switch]$Markdown,
    [switch]$Json,
    [string]$Host,
    [switch]$Upload
)

# Collect all data
$report = @{
    timestamp = Get-Date -Format 'o'
    hostname = $Host ?? $env:COMPUTERNAME
    system = Get-SystemInfo
    cpu_memory = Get-CpuMemoryInfo
    disk = Get-DiskInfo
    network = Get-NetworkInfo
    services = Get-ServiceInfo
    event_logs = Get-EventLogInfo
    installed_software = Get-InstalledSoftwareInfo
    updates = Get-UpdateInfo
    active_users = Get-ActiveUsersInfo
    network_tests = Get-NetworkTests
}

# Apply thresholds
$report = Apply-Thresholds $report

# Format output
if ($Json) {
    $output = $report | ConvertTo-Json -Depth 10
} elseif ($Html) {
    $output = Format-Html $report
} else {
    $output = Format-Markdown $report
}

# Output or upload
if ($Upload) {
    $url = Invoke-Upload $output
    Write-Host "Report uploaded: $url"
} else {
    Write-Output $output
}
```

---

## 3. Collector Modules

### 3.1 Get-SystemInfo.ps1

```powershell
function Get-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    
    return @{
        hostname = $env:COMPUTERNAME
        os = $os.Caption + ' ' + $os.Version
        uptime = (Get-Date) - $os.LastBootUpTime
        manufacturer = $computer.Manufacturer
        model = $computer.Model
    }
}
```

### 3.2 Get-DiskInfo.ps1

```powershell
function Get-DiskInfo {
    $volumes = Get-Volume | Where-Object { $_.DriveLetter }
    
    $result = foreach ($vol in $volumes) {
        $usedPercent = [math]::Round(($vol.Size - $vol.SizeRemaining) / $vol.Size * 100, 1)
        $status = if ($usedPercent -gt 90) { 'CRITICAL' }
                  elseif ($usedPercent -gt 80) { 'WARNING HIGH' }
                  else { 'OK' }
        
        @{
            drive = "$($vol.DriveLetter):"
            used_gb = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 1)
            total_gb = [math]::Round($vol.Size / 1GB, 1)
            percent = $usedPercent
            status = $status
        }
    }
    
    return $result
}
```

### 3.3 Get-EventLogInfo.ps1

```powershell
function Get-EventLogInfo {
    $appErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Level = 2
        StartTime = (Get-Date).AddHours(-24)
    } -MaxEvents 50 -ErrorAction SilentlyContinue
    
    $sysErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 2
        StartTime = (Get-Date).AddHours(-24)
    } -MaxEvents 50 -ErrorAction SilentlyContinue
    
    return @{
        application_errors = $appErrors.Count
        system_errors = $sysErrors.Count
        recent_errors = ($appErrors + $sysErrors) | 
            Select-Object -First 50 |
            ForEach-Object { $_.Message }
    }
}
```

---

## 4. Formatters

### 4.1 Format-Markdown.ps1

```powershell
function Format-Markdown {
    param($report)
    
    $md = @"
# Diagnostic Report — $($report.hostname)
Collected: $($report.timestamp)

## System
- Hostname: $($report.system.hostname)
- OS: $($report.system.os)
- Uptime: $($report.system.uptime.Days) days, $($report.system.uptime.Hours) hours
- Manufacturer: $($report.system.manufacturer)
- Model: $($report.system.model)

## CPU / Memory
- CPU: $($report.cpu_memory.cpu)
- RAM: $($report.cpu_memory.used_ram) GB / $($report.cpu_memory.total_ram) GB used ($($report.cpu_memory.ram_percent)%)

## Disk
"@
    
    foreach ($disk in $report.disk) {
        $md += "`n- $($disk.drive): $($disk.used_gb) GB / $($disk.total_gb) GB ($($disk.percent)%) — $($disk.status)"
    }
    
    return $md
}
```

---

## 5. Testing

```powershell
# tests/diag-collect.Tests.ps1
Describe "Diagnostic Collector" {
    It "Should collect system info" {
        $result = Get-SystemInfo
        $result.hostname | Should -Not -BeNullOrEmpty
    }
    
    It "Should flag disk > 80% as WARNING" {
        $result = Get-DiskInfo
        foreach ($disk in $result) {
            if ($disk.percent -gt 80) {
                $disk.status | Should -BeIn @('WARNING HIGH', 'CRITICAL')
            }
        }
    }
}
```

---

## 6. Known Pitfalls (Windows)

1. **Admin privileges** — Some commands require elevation
2. **Event log access** — May need admin rights
3. **Windows Update** — PSWindowsUpdate module optional
4. **Remote execution** — WinRM may need configuration

---

## 7. Out of Scope

- Linux/macOS support
- Real-time monitoring
- Agent-based collection
