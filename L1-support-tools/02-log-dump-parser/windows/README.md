# Log Dump Parser (Windows)

CLI tool for parsing and analyzing Windows log files (.evtx, IIS, JSON, plain text).

## Installation

```powershell
cd 02-log-dump-parser\windows
python -m venv .venv
.venv\Scripts\activate
pip install -e .
```

## Usage

```powershell
# Parse a Windows Event Log
log-parse C:\Windows\System32\winevt\Logs\Application.evtx

# Parse with filters
log-parse --level ERROR,WARN application.evtx
log-parse --since "2024-01-01" --until "2024-03-01" app.log
log-parse --grep "connection refused" error.log
log-parse --source "IIS" iis.log

# Parse from stdin
Get-Content log.txt | log-parse -

# Output as JSON
log-parse --json app.log > results.json

# Output as CSV
log-parse --csv app.log > results.csv
```

## Supported Formats

- **Windows Event Log (.evtx)** - Binary Windows event logs
- **Windows Event XML** - Exported event log XML format
- **JSON Lines** - One JSON object per line
- **IIS Logs** - IIS W3C log format
- **Syslog** - RFC 3164/5424 format
- **Plain text** - Best-effort detection

## Filters

- `--level ERROR,WARN` - Filter by severity level
- `--since "YYYY-MM-DD"` - Start date filter
- `--until "YYYY-MM-DD"` - End date filter
- `--source "ProcessName"` - Filter by source
- `--grep "pattern"` - Search within messages
- `--top N` - Show top N patterns (default 10)

## Output Formats

- **Text (default)** - Human-readable summary with grouped errors/warnings
- **JSON (`--json`)** - Structured JSON for pipelines
- **CSV (`--csv`)** - Flat CSV for Excel import

## Examples

### View errors in system log
```powershell
log-parse --level ERROR C:\Logs\system.evtx
```

### Export to CSV for Excel analysis
```powershell
log-parse --csv C:\Logs\iis.log > analysis.csv
```

### Find authentication failures
```powershell
log-parse --grep "authentication fail" C:\Logs\Security.evtx
```

## Building Standalone Executable

```powershell
pip install pyinstaller
pyinstaller log-parse.spec
# Output: dist/log-parse.exe
```

## Configuration

Config directory: `%APPDATA%\log-parse\`

## See Also

- [Main Project README](../../README.md)
- [macOS Implementation](../macos/)
- [PRD](docs/PRD.md) - Product Requirements
- [Implementation](docs/IMPLEMENTATION.md) - Technical Plan
- [Tasks](docs/TASKS.md) - Development Checklist
