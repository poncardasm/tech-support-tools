# Diagnostic Collector — PRD (macOS)

## 1. Concept & Vision

A one-command system info collector for L1/L2 handoffs. Instead of asking 20 questions over chat — "what does `top` say? what about `df -h`?" — L1 runs one script that gathers everything useful: hardware info, disk space, running services, recent errors, memory, CPU, and installed packages. Output is a clean HTML or Markdown report L2 can read instantly.

Target feel: the L1 agent who actually prepared properly for the escalation.

## 2. Functional Spec

### 2.1 Usage

```bash
# One command, no args needed
curl -s script.run/diag | bash
# or
diag-collect                    # interactive
diag-collect --html             # HTML report (default)
diag-collect --markdown         # Markdown report
diag-collect --json             # JSON for APIs
diag-collect --host macbook-pro-42  # tag the hostname
diag-collect --upload           # upload to internal pastebin/S3
```

### 2.2 What It Collects

| Category | Commands / Sources |
|---|---|
| System | hostname, `sw_vers`, `system_profiler SPHardwareDataType`, uptime |
| CPU/RAM | `top -l 1`, `vm_stat`, `sysctl hw.memsize` |
| Disk | `df -h`, `diskutil info`, APFS container status |
| Network | `ifconfig`, `netstat -rn`, `/etc/resolv.conf`, `scutil --dns` |
| Services | `launchctl list`, homebrew services if installed |
| Logs | last 50 errors from `log show --predicate 'messageType == error'` |
| Installed Packages | `brew list`, `pip list`, `npm list -g` |
| Updates | `softwareupdate --list`, pending macOS updates |
| Active Users | `who`, `last` last 10 logins |
| Network Tests | DNS resolution, gateway ping, internet connectivity |

### 2.3 Output

Markdown format:

```markdown
# Diagnostic Report — macbook-pro-42
Collected: 2024-03-01 14:23:00 EET

## System
- Hostname: macbook-pro-42
- macOS: Sonoma 14.3.1
- Model: MacBook Pro (16-inch, 2021)
- Chip: Apple M1 Pro
- Uptime: 14 days, 3 hours

## CPU / Memory
- CPU: Apple M1 Pro (10 cores)
- Memory: 28.5 GB / 32 GB used (89%)
- Top processes: Docker (4.2GB), Slack (1.2GB)

## Disk
- /: 412 GB / 512 GB (80%) — WARNING HIGH
- /System/Volumes/Data: 1.8 TB / 2 TB (90%) — CRITICAL

## Network
- en0: 192.168.1.42/24
- Gateway: 192.168.1.1
- DNS: 8.8.8.8, 1.1.1.1
- Internet: OK (ping 8.8.8.8 successful)

## Running Services (launchctl)
- com.apple.Dock.server: running
- com.apple.coreservicesd: running
- homebrew.mxcl.postgresql: running

## Recent Errors (last 50)
- kernel: (3 occurrences) SMC warning
- backupd: (2 occurrences) Time Machine backup failed

## Installed Packages
- Homebrew: 47 packages
- pip (global): 23 packages
- npm (global): 12 packages

## Pending Updates
- macOS: 2 updates available (1 security update)
- Homebrew: 8 packages outdated
```

### 2.4 Thresholds

| Condition | Flag |
|---|---|
| Disk > 80% | WARNING HIGH |
| Disk > 90% | CRITICAL |
| RAM > 90% | WARNING HIGH |
| Security updates pending | SECURITY PATCHES AVAILABLE |
| Service down | DOWN |

### 2.5 Upload

`--upload` flag uploads report to a configured endpoint and prints the URL.

## 3. Technical Approach

- **Language:** Bash (primary) + Python for JSON output
- **Distribution:** Single self-extracting script via `curl | bash`
- **No external deps** beyond standard macOS utilities
- **JSON output:** Python helper script (called from Bash)

### File Structure

```
diagnostic-collector/
├── pyproject.toml
├── diag/
│   ├── __init__.py
│   ├── __main__.py
│   ├── collector.sh          # main Bash script
│   ├── formatters.py         # JSON/Markdown output helpers
│   └── thresholds.py
├── tests/
│   └── test_formatters.py
├── Formula/
│   └── diag-collect.rb
└── README.md
```

## 4. Success Criteria

- [ ] `curl -s .../collector.sh | bash` runs on macOS 13 (Ventura) and macOS 14 (Sonoma)
- [ ] All 10 categories collected in < 30 seconds
- [ ] Disk > 80% correctly flagged as WARNING
- [ ] Markdown output renders correctly in GitHub Flavored Markdown
- [ ] JSON output is valid and parseable
- [ ] `--upload` POSTs to configurable endpoint

## 5. Out of Scope (v1)

- Windows support
- Linux compatibility
- Real-time monitoring / dashboards
- Alerting integration (PagerDuty, OpsGenie)
