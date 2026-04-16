# Diagnostic Collector — PRD (Windows)

## 1. Concept & Vision

A one-command system info collector for L1/L2 handoffs. Instead of asking 20 questions over chat — "what does Task Manager show? what about Event Viewer?" — L1 runs one script that gathers everything useful: system config, running processes, recent errors, memory, CPU, disk, network, and installed software. Output is a clean HTML or Markdown report L2 can read instantly.

Target feel: the L1 agent who actually prepared properly for the escalation.

## 2. Functional Spec

### 2.1 Usage

```powershell
# One command, no args needed
Invoke-WebRequest -Uri script.run/diag.ps1 | Invoke-Expression
# or
diag-collect                    # interactive
diag-collect --html             # HTML report (default)
diag-collect --markdown         # Markdown report
diag-collect --json             # JSON for APIs
diag-collect --host workstation-42  # tag the hostname
diag-collect --upload           # upload to internal pastebin/S3
```

### 2.2 What It Collects

| Category | Commands / Sources |
|---|---|
| System | hostname, OS version, system uptime, manufacturer/model |
| CPU/RAM | `Get-Process`, `Get-CimInstance Win32_OperatingSystem`, CPU utilization |
| Disk | `Get-Volume`, `Get-PhysicalDisk`, SMART status if available |
| Network | `Get-NetIPAddress`, `Get-NetRoute`, DNS settings, gateway ping |
| Services | `Get-Service` running services |
| Event Logs | last 50 errors from Application and System logs |
| Installed Software | `Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*` |
| Windows Updates | pending updates via `Get-WindowsUpdate` (if PSWindowsUpdate installed) |
| Active Users | `query user`, logged on sessions |
| Network Tests | DNS resolution, gateway ping, internet connectivity |

### 2.3 Output

Markdown format:

```markdown
# Diagnostic Report — WORKSTATION-42
Collected: 2024-03-01 14:23:00 EET

## System
- Hostname: WORKSTATION-42
- OS: Windows 11 Pro 23H2
- Uptime: 14 days, 3 hours
- Manufacturer: Dell Inc.
- Model: Precision 5560

## CPU / Memory
- CPU: 11th Gen Intel(R) Core(TM) i7-11850H @ 2.50GHz
- RAM: 28.5 GB / 32 GB used (89%)
- Top processes: chrome.exe (2.1GB), Teams.exe (1.8GB)

## Disk
- C: 412 GB / 512 GB (80%) — WARNING HIGH
- D: 1.8 TB / 2 TB (90%) — CRITICAL

## Network
- Ethernet: 192.168.1.42/24
- Gateway: 192.168.1.1
- DNS: 8.8.8.8, 1.1.1.1
- Internet: OK (ping 8.8.8.8 successful)

## Running Services
- WinRM: Running
- Spooler: Running
- wuauserv: Stopped

## Recent Errors (last 50)
- Application: 15 errors in last 24h
- System: 8 errors in last 24h
- Top error: .NET Runtime error (EventID 1026)

## Pending Updates
- 14 updates available (3 are security patches)
```

### 2.4 Thresholds

| Condition | Flag |
|---|---|
| Disk > 80% | WARNING HIGH |
| Disk > 90% | CRITICAL |
| RAM > 90% | WARNING HIGH |
| Pending security updates | SECURITY PATCHES AVAILABLE |
| Service failure | DOWN |

### 2.5 Upload

`--upload` flag uploads report to a configured endpoint and prints the URL.

## 3. Technical Approach

- **Language:** PowerShell 5.1+ (runs on all Windows versions)
- **Distribution:** Single script via `Invoke-WebRequest | Invoke-Expression`
- **No external deps** beyond standard Windows cmdlets
- **JSON output:** PowerShell `ConvertTo-Json`

### File Structure

```
diagnostic-collector/
├── diag-collect.ps1          # main script (the deliverable)
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

## 4. Success Criteria

- [ ] `diag-collect` runs on Windows 10 and Windows 11
- [ ] All 10 categories collected in < 30 seconds
- [ ] Disk > 80% correctly flagged as WARNING
- [ ] Markdown output renders correctly
- [ ] JSON output is valid and parseable
- [ ] `--upload` POSTs to configurable endpoint

## 5. Out of Scope (v1)

- Linux/macOS support
- Real-time monitoring / dashboards
- Alerting integration (PagerDuty, OpsGenie)
