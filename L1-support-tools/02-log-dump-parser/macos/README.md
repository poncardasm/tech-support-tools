# log-parse (macOS)

macOS-specific implementation of the log-parse CLI tool.

## Platform-Specific Features

### macOS System Logs

Parse macOS unified logging system (ULS) exports:

```bash
# Export macOS system logs
log show --last 1h --style json > macos_logs.json
log-parse macos_logs.json

# Stream and parse
log stream --level error | log-parse -
```

### Standard Unix Logs

```bash
# System logs
log-parse /var/log/system.log

# Installation logs
log-parse /var/log/install.log

# Application crash logs
log-parse ~/Library/Logs/DiagnosticReports/*.crash
```

## Installation

### Homebrew (Recommended)

```bash
brew tap mchael/tools
brew install log-parse
```

### From Source

```bash
cd 02-log-dump-parser/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Development

```bash
# Run tests
pytest tests/ -v

# Test with fixtures
log-parse tests/fixtures/syslog.log
log-parse tests/fixtures/json_lines.log --json
```

## macOS-Specific Log Sources

| Source             | Path                                               | Format |
| ------------------ | -------------------------------------------------- | ------ |
| System log         | `/var/log/system.log`                              | syslog |
| Install log        | `/var/log/install.log`                             | plain  |
| Diagnostic reports | `~/Library/Logs/DiagnosticReports/`                | plain  |
| Docker Desktop     | `~/Library/Containers/com.docker.docker/Data/log/` | json   |

## Configuration

Config directory: `~/.config/log-parse/`

## See Also

- [Main Project README](../../README.md)
- [PRD](docs/PRD.md) - Product Requirements
- [Implementation](docs/IMPLEMENTATION.md) - Technical Details
- [Tasks](docs/TASKS.md) - Development Checklist
