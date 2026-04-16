# Ticket Triage CLI (Windows)

A CLI tool for triaging L1 support tickets using keyword-based classification. Takes raw ticket text and returns structured triage results: category, priority, suggested actions, escalation guidance, and confidence scoring.

## Features

- **8 Category Taxonomy**: Authentication, Network/VPN, Email/Outlook, Hardware, Software, Access Request, Printing, Other/Unknown
- **Priority Scoring**: P1 (Critical) through P4 (Info) with urgency modifiers
- **Confidence Scoring**: High/Medium/Low based on keyword match strength
- **L2 Escalation Detection**: Automatically flags tickets requiring L2 attention
- **PowerShell Pipe Support**: Native Windows integration with PowerShell
- **JSON Output**: Machine-readable output for automation
- **Optional LLM Mode**: Local Ollama integration for enhanced triage
- **User Config Override**: Customize rules via `%APPDATA%\ticket-triage\rules.yaml`

## Installation

### Option 1: Standalone Executable (Recommended for Windows)

1. Download `ticket-triage.exe` from [GitHub Releases](../../releases)
2. Place in a directory in your PATH (e.g., `C:\Tools\`)
3. Run from PowerShell or Command Prompt

### Option 2: Python Package

Requires Python 3.10 or later:

```powershell
# Install from source
pip install -e .

# Or install from PyPI (when published)
pip install ticket-triage
```

### Option 3: Build from Source

```powershell
# Clone and install
git clone https://github.com/L1-support-tools/ticket-triage-cli.git
cd ticket-triage-cli/windows
pip install -e .

# Build standalone executable (Windows only)
.\build.ps1 -InstallDeps -Test
```

## Usage

### Basic Usage

```powershell
# Pipe ticket text from file
Get-Content ticket.txt | ticket-triage

# Or use echo
echo "User can't login, password expired in EntraID" | ticket-triage

# Or use --file flag
ticket-triage --file C:\tickets\ticket.txt
```

### Output Format

```
Category: Authentication
Priority: P2 (Medium)
Suggested action: Reset EntraID password via Admin Center and verify MFA registration
Escalate to: L2 if MFA or account locked; Security team if breach suspected
Related KB: KB-1001
Root cause signals: ['password', 'login', 'entraid']
Confidence: High
```

### JSON Output

```powershell
echo "VPN connection down" | ticket-triage --json
```

```json
{
  "category": "Network/VPN",
  "priority": "P2",
  "action": "Check VPN connection, verify credentials, test alternative connection method",
  "escalate_to": "L2 if VPN profile corrupted or network infrastructure issue",
  "kb": "KB-1002",
  "signals": ["vpn", "connection"],
  "confidence": "High",
  "flag_l2": false
}
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Triage complete successfully |
| 1 | Parse error / no input provided |
| 2 | L2 escalation recommended (see `flag_l2: true` in JSON) |

### Optional LLM Mode

If you have [Ollama](https://ollama.com/) running locally:

```powershell
echo "Complex ticket description" | ticket-triage --llm
```

The tool will use Ollama for enhanced classification, falling back to the rule engine if Ollama is unavailable.

**Note**: LLM mode requires installing with the `llm` extra:

```powershell
pip install -e ".[llm]"
```

## Configuration

### Custom Rules

Create `%APPDATA%\ticket-triage\rules.yaml` to override default rules:

```yaml
categories:
  my_custom_category:
    keywords: [custom, words, here]
    escalation: L2 if complex
    suggested_action: Do something specific
    kb: KB-9999
    priority_bump: 0

priority:
  p1_override_words: [down, outage, everyone, production, urgent, critical]
  urgency_modifiers: [asap, immediately, right now]
```

### Priority Scoring

- **P1 (Critical)**: Override words like "down", "outage", "everyone", "production"
- **P2 (Medium)**: Default priority
- **P3 (Low)**: Indicators like "when possible", "cosmetic", "minor"
- **P4 (Info)**: Indicators like "FYI", "for reference", "no action needed"

Urgency modifiers (ASAP, immediately) bump priority up one level.

### Confidence Scoring

- **High**: Exactly one category matched with 3+ keywords
- **Medium**: Exactly one category matched with 1-2 keywords
- **Low**: Multiple categories matched or no category matched

### Escalation Rules

Tickets are flagged for L2 escalation when:
- Hardware failure keywords detected
- Multiple categories detected
- P1 + Authentication category
- MFA issues with Authentication
- Security-related keywords detected

## Development

### Running Tests

```powershell
# Run all tests
pytest tests/ -v

# Run specific test class
pytest tests/test_triage.py::TestTriage -v
```

### Project Structure

```
ticket-triage-cli/
├── ticket_triage/
│   ├── __init__.py          # Version info
│   ├── __main__.py          # CLI entry point
│   ├── triage.py            # Core triage logic
│   └── rules.yaml           # Default classification rules
├── tests/
│   ├── test_triage.py       # Test suite (63 tests)
│   └── fixtures/            # Sample tickets per category
├── build.ps1                # PowerShell build script
├── ticket-triage.spec       # PyInstaller spec
├── pyproject.toml           # Package configuration
└── README.md                # This file
```

### Building Standalone Executable

On Windows with Python and pip installed:

```powershell
# Install build dependencies and build
.\build.ps1 -InstallDeps -Test

# Or manually:
pip install pyinstaller
pyinstaller ticket-triage.spec
```

The executable will be created at `dist\ticket-triage.exe`.

## Category Taxonomy

| Category | Example Keywords |
|----------|------------------|
| Authentication | password, login, MFA, SSO, EntraID, locked, access denied |
| Network/VPN | VPN, connection, network, firewall, cannot connect, timeout |
| Email/Outlook | outlook, email, calendar, mailbox, PST, OST, signature |
| Hardware | laptop, monitor, keyboard, hardware failure, device, blue screen |
| Software | install, uninstall, update, crash, application, program |
| Access Request | permissions, SharePoint, Teams, group, role, entitlement |
| Printing | printer, print job, driver, spooler, toner, queue |
| Other/Unknown | No keywords matched |

## License

MIT License - See [LICENSE](../../LICENSE) for details.

## Support

For issues or questions, please open a [GitHub Issue](../../issues).
