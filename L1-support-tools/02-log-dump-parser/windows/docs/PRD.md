# Log Dump Parser — PRD (Windows)

## 1. Concept & Vision

A CLI tool that takes a raw log file (any format: Windows Event Logs, Syslog, IIS logs, application logs, JSON logs, Docker, Kubernetes) and returns a cleaned, structured summary of errors and warnings grouped by frequency and severity. No more scrolling through 10,000 lines.

Target feel: a senior sysadmin sitting next to you saying "here's what's actually wrong — ignore the noise."

## 2. Functional Spec

### 2.1 Input

```powershell
log-parse C:\Logs\system.evtx
log-parse --format evtx C:\Logs\application.evtx
log-parse --json C:\Logs\container-logs.json
log-parse --since "2024-01-01 00:00:00" app.log
Get-Content raw_log.txt | log-parse
```

### 2.2 Supported Formats

| Format | Auto-detected by |
|---|---|
| Windows Event Log (.evtx) | file extension + binary header |
| Windows Event XML | `<Event>` root tag |
| JSON Lines | one JSON object per line |
| IIS/Apache logs | standard IIS log format pattern |
| Plain text (fallback) | best-effort regex extraction |

### 2.3 Output

```
=== Log Summary ===
File: C:\Logs\application.evtx
Lines parsed: 14,232 | Errors: 23 | Warnings: 87

[ERRORS — 23 total]
  12x Application crash in .NET Runtime
   7x Authentication failure for user admin
   4x Disk space threshold exceeded on C:

[WARNINGS — 87 total]
  40x Session token expired (idle timeout)
  22x Retry attempt for external API call
  15x Memory usage above 80%

[STATISTICS]
  Time range: 2024-03-01 09:00:00 → 2024-03-01 17:30:00
  Top source: .NET Runtime (143 entries)
  Top error source: Application (18 errors)

[SUGGESTED ACTIONS]
  - ".NET Runtime crash" → check application event log for .NET errors
  - "Authentication failure" → review failed login audit log
  - "Disk space threshold" → run `Get-Volume` on affected drive
```

### 2.4 Filters

```
--level ERROR,WARN     # only show errors and warnings
--since "1 hour ago"   # relative time filter
--until "2024-03-01"   # absolute time filter
--source ".NET Runtime" # filter by source
--grep "connection"    # search within results
--top 10               # show only top 10 error patterns
```

### 2.5 Output Formats

- Text (default) — human-readable summary
- `--json` — structured JSON for pipelines
- `--csv` — flat CSV for import into Excel

## 3. Technical Approach

- **Language:** Python 3.10+
- **CLI framework:** Click
- **Log parsing:** `python-evtx` for Windows Event Logs, regex for others
- **Auto-detection:** heuristic based on first 10 lines
- **No external APIs** — fully local

### File Structure

```
log-dump-parser/
├── pyproject.toml
├── log_parse/
│   ├── __init__.py
│   ├── __main__.py
│   ├── parser.py
│   ├── formatters.py
│   ├── patterns.yaml
│   └── patterns/
│       ├── evtx.py
│       ├── json_lines.py
│       └── iis.py
├── tests/
│   └── test_parser.py
├── build/
│   └── log-parse.exe
└── README.md
```

## 4. Success Criteria

- [x] Auto-detects Windows Event Log, JSON Lines, IIS formats
- [x] Groups duplicate errors into frequency counts
- [x] `--level`, `--since`, `--until`, `--source` filters work
- [x] `--json` and `--csv` output valid formats
- [x] 10k event log entries processed in < 5 seconds
- [x] Graceful handling of corrupted event logs (skip + warn)

## 5. Out of Scope (v1)

- Real-time log streaming (tail -f support)
- Web UI
- Elasticsearch/Splunk integration
- Multi-file aggregation
