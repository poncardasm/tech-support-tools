# Diagnostic Collector for macOS

A one-command system diagnostic collector for L1/L2 support handoffs. Gathers hardware info, disk space, running services, recent errors, memory, CPU, and installed packages — outputting a clean report that L2 can read instantly.

## Quick Start

### Option 1: Homebrew (Recommended)

```bash
# Add tap (if hosted)
brew tap mchael/l1-tools
brew install diag-collect

# Or install directly from repo
brew install --HEAD ./Formula/diag-collect.rb
```

### Option 2: Direct Installation

```bash
# Clone the repository
git clone https://github.com/mchael/L1-support-tools.git
cd L1-support-tools/04-diagnostic-collector/macos

# Install Python dependencies
pip install -e .

# Or use the standalone script
./diag/collector.sh --help
```

### Option 3: Curl (One-liner)

```bash
# Standalone Bash collector (no Python needed)
curl -s https://raw.githubusercontent.com/mchael/L1-support-tools/main/04-diagnostic-collector/macos/diag/collector.sh | bash
```

## Usage

```bash
# Interactive mode - outputs to stdout
diag-collect

# Output formats
diag-collect --html              # HTML report
diag-collect --markdown          # Markdown report (default)
diag-collect --json              # JSON output for APIs

# Options
diag-collect --host macbook-42   # Tag with custom hostname
diag-collect --upload            # Upload to configured endpoint
```

## What It Collects

| Category | Data Collected |
|----------|----------------|
| **System** | hostname, macOS version, model, chip, memory, uptime |
| **CPU/Memory** | Usage stats, top processes, memory pressure |
| **Disk** | All mounted volumes, usage %, APFS status |
| **Network** | Interfaces, IPs, gateway, DNS, connectivity tests |
| **Services** | Launchctl services, Homebrew services |
| **Logs** | Last 50 errors from system log (24h) |
| **Packages** | Homebrew, pip, npm package counts |
| **Updates** | Pending macOS and Homebrew updates |
| **Users** | Active sessions, recent logins |

## Thresholds & Warnings

The collector automatically flags issues:

| Condition | Flag |
|-----------|------|
| Disk usage > 80% | 🟡 WARNING HIGH |
| Disk usage > 90% | 🔴 CRITICAL |
| Memory usage > 80% | 🟡 WARNING HIGH |
| Memory usage > 90% | 🔴 CRITICAL |
| Security updates pending | 🟡 SECURITY PATCHES AVAILABLE |
| Internet unreachable | 🔴 CRITICAL |

## Output Examples

### Markdown (Default)

```markdown
# Diagnostic Report — macbook-pro-42
Collected: 2024-03-01 14:23:00

## System
- **Hostname:** macbook-pro-42
- **OS:** macOS Sonoma 14.3.1
- **Model:** MacBook Pro (16-inch, 2021)
- **Chip:** Apple M1 Pro
- **Uptime:** 14 days, 3 hours

## Disk
- **/:** 412 GB / 512 GB (80%) 🟡 **WARNING HIGH**
```

### HTML

Self-contained HTML with styling that renders in any browser.

### JSON

Structured data for programmatic processing:

```json
{
  "hostname": "macbook-pro-42",
  "collected_at": "2024-03-01 14:23:00",
  "sections": {
    "SYSTEM": { "hostname": "macbook-pro-42", ... },
    "DISK": { ... }
  }
}
```

## Configuration

### Environment Variables

```bash
export OUTPUT_FORMAT=markdown    # Default output format
export UPLOAD_ENDPOINT=https://... # URL for --upload feature
export HOSTNAME_TAG=server-01    # Custom hostname tag
```

### Upload Feature

Set `UPLOAD_ENDPOINT` to a URL that accepts POST requests:

```bash
export UPLOAD_ENDPOINT="https://paste.example.com/upload"
diag-collect --upload --markdown
```

## Permissions

Some features may require permissions:

- **Full Disk Access**: For reading system logs
- **Network Access**: For connectivity tests

The collector gracefully degrades if permissions are missing — it won't fail, just skip the restricted data.

## Development

```bash
# Setup
cd 04-diagnostic-collector/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Run tests
pytest tests/ -v

# Run collector directly
./diag/collector.sh --markdown
```

## File Structure

```
04-diagnostic-collector/macos/
├── diag/
│   ├── __init__.py          # Package init
│   ├── __main__.py          # CLI entry point
│   ├── collector.sh         # Main Bash collection script
│   ├── formatters.py        # Output formatters (MD, HTML, JSON)
│   └── thresholds.py        # Threshold detection
├── tests/
│   └── test_formatters.py   # pytest suite
├── Formula/
│   └── diag-collect.rb      # Homebrew formula
├── pyproject.toml           # Python package config
└── docs/
    ├── PRD.md               # Product requirements
    ├── IMPLEMENTATION.md    # Technical details
    └── TASKS.md             # Implementation checklist
```

## System Requirements

- **macOS**: 13 (Ventura) or later
- **Python**: 3.10+ (for Python features)
- **Bash**: For standalone collector.sh

## Limitations

- macOS only (no Windows/Linux support in this tool)
- Some log collection requires Full Disk Access
- Intel and Apple Silicon Macs may report memory slightly differently

## License

MIT License - See LICENSE file in repository root.

## Contributing

This is part of the L1 Support Tools monorepo. See the main repository for contribution guidelines.

## Troubleshooting

### "log show" returns no data
Grant Full Disk Access to Terminal/iTerm in **System Settings > Privacy & Security > Full Disk Access**.

### Permission denied running collector.sh
```bash
chmod +x diag/collector.sh
```

### Python module not found
```bash
pip install -e .
```

## Version History

- **1.0.0** - Initial release
  - System, disk, memory, network collection
  - Markdown, HTML, JSON output formats
  - Threshold detection (80%, 90%)
  - Upload support
  - Homebrew packaging
