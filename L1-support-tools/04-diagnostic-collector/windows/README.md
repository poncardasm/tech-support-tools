# Diagnostic Collector for Windows

A one-command system diagnostic collector for L1/L2 support handoffs. Gathers system configuration, hardware info, disk usage, network status, services, event logs, installed software, and Windows updates — outputting a clean report that L2 can read instantly.

## Quick Start

### Option 1: Direct Download (One-liner)

```powershell
# Download and execute directly
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mchael/L1-support-tools/main/04-diagnostic-collector/windows/diag-collect.ps1 -OutFile diag-collect.ps1
.\diag-collect.ps1
```

### Option 2: Invoke-WebRequest | Invoke-Expression

```powershell
# One-line execution (from trusted source)
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mchael/L1-support-tools/main/04-diagnostic-collector/windows/diag-collect.ps1 | Invoke-Expression
```

### Option 3: Clone and Run

```powershell
# Clone the repository
git clone https://github.com/mchael/L1-support-tools.git
cd L1-support-tools/04-diagnostic-collector/windows

# Run the collector
.\diag-collect.ps1
```

## Usage

```powershell
# Interactive mode - outputs to stdout
.\diag-collect.ps1

# Output formats
.\diag-collect.ps1 -Html              # HTML report
.\diag-collect.ps1 -Markdown          # Markdown report (default)
.\diag-collect.ps1 -Json              # JSON output for APIs

# Options
.\diag-collect.ps1 -Host "WORKSTATION-42"  # Tag with custom hostname
.\diag-collect.ps1 -Upload                # Upload to configured endpoint
.\diag-collect.ps1 -Html -Upload           # Upload HTML report
```

## What It Collects

| Category | Data Collected |
|----------|----------------|
| **System** | hostname, Windows version, model, BIOS, manufacturer, uptime |
| **CPU/Memory** | Processor details, core count, current usage, memory stats, top processes |
| **Disk** | All volumes, usage %, free space, SMART status (if available), threshold alerts |
| **Network** | Adapters, MAC addresses, IPv4/IPv6, DNS servers, gateway, routes |
| **Services** | Running services, stopped auto-start services, summary counts |
| **Event Logs** | Last 50 errors from Application/System logs (24h window), error summaries |
| **Installed Software** | Registry-based software inventory, publisher counts, version info |
| **Windows Updates** | Pending updates, security patches, update counts |
| **Active Users** | Current user, active sessions (quser), logged-on users |
| **Network Tests** | DNS resolution, gateway ping, internet connectivity, HTTPS tests |

## Thresholds & Warnings

The collector automatically flags common issues:

| Condition | Alert Level | Indicator |
|-----------|-------------|-----------|
| Disk usage > 90% | 🔴 CRITICAL | Status highlighted in red |
| Disk usage > 80% | 🟡 WARNING HIGH | Status highlighted in yellow |
| Memory usage > 90% | 🔴 CRITICAL | Critical alert generated |
| Memory usage > 80% | 🟡 WARNING | Warning generated |
| CPU usage > 90% | 🟡 WARNING | Warning generated |
| Service stopped (auto-start) | 🟡 WARNING | Flagged in service list |
| Security updates pending | 🟡 WARNING | Alert with count |
| > 10 application errors (24h) | 🟡 WARNING | Event log warning |
| Internet unreachable | 🔴 CRITICAL | Network test failure |

## Output Examples

### Markdown (Default)

```markdown
# Diagnostic Report - DESKTOP-ABC123
**Collected:** 2024-03-15 14:23:00
**Diagnostic Collector v1.0.0**

## ⚠️ Alerts
**CRITICAL: 1 issue(s) detected**

- 🔴 **[DISK]** Disk D: is at 95% capacity

## System
| Property | Value |
|----------|-------|
| Hostname | DESKTOP-ABC123 |
| OS | Windows 11 Pro 23H2 |
| Uptime | 5 days, 3 hours |
| Manufacturer | Dell Inc. |

## Disk
| Drive | Label | Total | Used | Free | Usage | Status |
|-------|-------|-------|------|------|-------|--------|
| C: | Windows | 512 GB | 256 GB | 256 GB | 50% | ✅ OK |
| D: | Data | 1024 GB | 970 GB | 54 GB | 95% | 🔴 CRITICAL |
```

### HTML

Self-contained HTML with responsive styling, color-coded alerts, and sortable tables. Opens in any browser.

### JSON

Structured data for programmatic processing:

```json
{
  "hostname": "DESKTOP-ABC123",
  "timestamp": "2024-03-15 14:23:00",
  "version": "1.0.0",
  "sections": {
    "System": { "hostname": "DESKTOP-ABC123", ... },
    "Disk": [ { "drive": "C:", "percent_used": 50, "status": "OK" }, ... ],
    "Thresholds": {
      "total_alerts": 1,
      "critical": 1,
      "warnings": 0,
      "alerts": [...]
    }
  }
}
```

## Configuration

### Environment Variables

```powershell
# Set default output format
$env:DIAG_COLLECT_FORMAT = "markdown"    # or "html" or "json"

# Configure upload endpoint
$env:DIAG_COLLECT_UPLOAD_URL = "https://paste.internal/upload"
$env:DIAG_COLLECT_UPLOAD_TOKEN = "your-api-token"

# Set default hostname tag
$env:DIAG_COLLECT_HOSTNAME = "custom-name"
```

### Upload Feature

Set the upload endpoint to a URL that accepts POST requests:

```powershell
$env:DIAG_COLLECT_UPLOAD_URL = "https://paste.example.com/upload"
.\diag-collect.ps1 -Upload -Html
```

Expected POST body:
```json
{
  "content": "<report content>",
  "hostname": "WORKSTATION-01",
  "timestamp": "2024-03-15T14:23:00Z",
  "format": "html"
}
```

## Permissions

Some features work better with elevated privileges:

- **Event Log Access**: May require admin rights for Security log
- **Windows Update**: COM access works without admin; PSWindowsUpdate module requires elevation
- **All other features**: Work with standard user permissions

The collector gracefully degrades if permissions are missing — it won't fail, just skips the restricted data with a warning.

## Testing

```powershell
# Run the Pester test suite
cd 04-diagnostic-collector/windows
Invoke-Pester tests/diag-collect.Tests.ps1

# Run with verbose output
Invoke-Pester tests/diag-collect.Tests.ps1 -Verbose
```

## File Structure

```
04-diagnostic-collector/windows/
├── diag-collect.ps1                    # Main script (the deliverable)
├── modules/
│   ├── Get-SystemInfo.ps1              # OS, hostname, hardware
│   ├── Get-CpuMemoryInfo.ps1           # CPU/memory stats, processes
│   ├── Get-DiskInfo.ps1                  # Volume usage, thresholds
│   ├── Get-NetworkInfo.ps1               # Adapters, IPs, DNS, routes
│   ├── Get-ServiceInfo.ps1               # Windows services
│   ├── Get-EventLogInfo.ps1              # Recent errors
│   ├── Get-InstalledSoftwareInfo.ps1     # Software inventory
│   ├── Get-UpdateInfo.ps1                # Pending updates
│   ├── Get-ActiveUsersInfo.ps1           # Logged-on users
│   └── Get-NetworkTests.ps1              # Connectivity tests
├── formatters/
│   ├── Format-Markdown.ps1               # Markdown output
│   ├── Format-Html.ps1                   # HTML output
│   └── Format-Json.ps1                   # JSON output wrapper
├── tests/
│   └── diag-collect.Tests.ps1            # Pester test suite
├── docs/
│   ├── PRD.md                            # Product requirements
│   ├── IMPLEMENTATION.md                 # Technical details
│   └── TASKS.md                          # Implementation checklist
└── README.md                             # This file
```

## System Requirements

- **Windows**: Windows 10 (1607+) or Windows 11
- **PowerShell**: 5.1 or PowerShell 7+
- **Execution Policy**: May require `RemoteSigned` or `Bypass` for downloaded scripts

Check your execution policy:
```powershell
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Limitations

- Windows only (no macOS/Linux support in this tool)
- Some log collection requires admin rights
- Windows Update detection relies on Windows Update COM API or PSWindowsUpdate module
- Network tests may be blocked by firewalls

## Troubleshooting

### "Execution of scripts is disabled on this system"

Run PowerShell as Administrator and set execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access denied" for event logs

Some event logs require admin rights. Run PowerShell as Administrator, or the collector will skip those logs gracefully.

### Empty Windows Update list

Windows Update detection requires the Windows Update service to be running. Try:
```powershell
Get-Service wuauserv
Start-Service wuauserv
```

### Network tests fail

Network connectivity tests may be blocked by corporate firewalls. The script will report failures but continue collecting other data.

## Version History

- **1.0.0** - Initial release
  - 10 collection categories
  - Markdown, HTML, JSON output
  - Threshold detection (80%, 90%)
  - Upload support
  - Pester test suite

## License

MIT License - See LICENSE file in repository root.

## Contributing

This is part of the L1 Support Tools monorepo. See the main repository for contribution guidelines.

## See Also

- [macOS Diagnostic Collector](../macos/README.md) - macOS version of this tool
- [Main L1 Support Tools README](../../README.md)
