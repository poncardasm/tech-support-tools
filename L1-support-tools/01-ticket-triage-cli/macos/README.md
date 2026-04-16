# Ticket Triage CLI

CLI tool for L1 support ticket triage on macOS. Analyzes support ticket text and provides structured triage results including category, priority, suggested actions, and escalation guidance.

## Features

- **8 Category Taxonomy**: Authentication, Network/VPN, Email/Outlook, Hardware, Software, Access Request, Printing, Other/Unknown
- **Priority Scoring**: P1 (Critical) through P4 (Info) with urgency modifiers
- **Confidence Scoring**: High/Medium/Low based on keyword match quality
- **L2 Escalation Detection**: Automatic flagging for security issues, hardware failures, and multi-category ambiguity
- **JSON Output**: Machine-readable output for integration with other tools
- **User Configurable**: Override default rules via `~/.config/ticket-triage/rules.yaml`

## Installation

### Homebrew (Recommended)

```bash
brew tap poncardasm/l1-tools
brew install ticket-triage
```

### Development Install

```bash
git clone https://github.com/poncardasm/L1-support-tools.git
cd L1-support-tools/01-ticket-triage-cli/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Usage

### Basic Usage

```bash
# Pipe ticket text via stdin
cat ticket.txt | ticket-triage
echo "User can't login, password expired" | ticket-triage

# Read from file
ticket-triage --file /path/to/ticket.txt

# Output as JSON
ticket-triage --json < ticket.txt
echo "VPN is down" | ticket-triage --json
```

### Example Output

**Text Output:**
```
Category: authentication
Priority: P2 (Medium)
Suggested action: Reset EntraID password via Admin Center
Escalate to: None
Related KB: KB-1001
Root cause signals: ['password', 'login']
Confidence: Medium
```

**JSON Output:**
```json
{
  "category": "authentication",
  "priority": "P2",
  "action": "Reset EntraID password via Admin Center",
  "escalate_to": "None",
  "kb": "KB-1001",
  "signals": ["password", "login"],
  "confidence": "Medium",
  "flag_l2": false
}
```

### Command-Line Options

```
Options:
  -f, --file PATH  Read ticket from file
  --llm            Use local Ollama for enhanced triage (future)
  --json           Output as JSON
  --version        Show the version and exit
  --help           Show help message and exit
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Triage complete successfully |
| `1` | Parse error / no input provided |
| `2` | Triage result recommends L2 escalation |

Use exit code 2 in scripts to automatically route tickets to L2:

```bash
if ticket-triage --file ticket.txt; then
    echo "Handle as L1"
elif [ $? -eq 2 ]; then
    echo "Escalate to L2"
fi
```

## Category Taxonomy

| Category | Keywords |
|----------|----------|
| Authentication | password, login, MFA, SSO, EntraID, locked, access denied |
| Network/VPN | VPN, connection, network, firewall, timeout, cannot connect |
| Email/Outlook | outlook, email, calendar, mailbox, PST, OST, signature |
| Hardware | laptop, monitor, keyboard, mouse, hardware failure, device |
| Software | install, uninstall, update, crash, blue screen, application |
| Access Request | access, permissions, SharePoint, Teams, group, role |
| Printing | printer, print job, driver, spooler |
| Other/Unknown | no match above |

## Priority Scoring

- **P1 (Critical)**: Keywords like "down", "outage", "everyone", "production", "urgent"
- **P2 (Medium)**: Default priority
- **P3 (Low)**: Keywords like "when possible", "cosmetic"
- **P4 (Info)**: Keywords like "FYI", "for reference", "no action needed"

**Urgency Modifiers**: Words like "ASAP", "immediately", "right now" bump priority by one level (P3→P2, P2→P1).

## Configuration

Create `~/.config/ticket-triage/rules.yaml` to override default rules:

```yaml
categories:
  authentication:
    keywords: [password, login, MFA, SSO, EntraID, locked, "access denied"]
    escalation: "L2 if MFA not working or account locked"
    suggested_action: "Reset EntraID password via Admin Center"
    kb: "KB-1001"
    priority_bump: 0
```

User rules are merged with defaults, allowing you to customize without losing built-in categories.

## Escalation Rules

The following conditions automatically flag tickets for L2 escalation:

- **Authentication + MFA/locked**: Security-related authentication issues
- **Hardware + failure keywords**: Hardware failures requiring L2 immediate attention
- **P1 + Authentication**: Critical authentication issues (Security team involvement)
- **Multiple categories**: Ambiguous tickets needing L2 review

## Development

```bash
# Run tests
pytest tests/ -v

# Install development dependencies
pip install -e ".[llm]"
```

## License

MIT License - See LICENSE file for details.
