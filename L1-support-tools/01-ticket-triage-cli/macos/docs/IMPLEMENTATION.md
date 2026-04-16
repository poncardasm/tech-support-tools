# Ticket Triage CLI — Implementation Plan (macOS)

## 1. Project Setup

### 1.1 Initialize Python project

```bash
cd ticket-triage-cli
python3 -m venv .venv
source .venv/bin/activate
pip install build pyyaml click requests
```

### 1.2 Create pyproject.toml

Standard Python packaging with Click CLI. Core deps: PyYAML, Click. Optional dep: `requests` (only for `--llm` mode).

### 1.3 File Structure

```
ticket-triage-cli/
├── pyproject.toml
├── ticket_triage/
│   ├── __init__.py
│   ├── __main__.py     # python -m ticket_triage entry
│   ├── triage.py       # core logic
│   └── rules.yaml      # default rules
├── tests/
│   └── test_triage.py
├── Formula/
│   └── ticket-triage.rb  # Homebrew formula
├── README.md
└── .gitignore
```

---

## 2. Core Architecture

### 2.1 rules.yaml

Flat YAML file with category name as key.

```yaml
categories:
  authentication:
    keywords: [password, login, MFA, SSO, EntraID, locked, access denied]
    escalation: L2 if MFA or account locked
    suggested_action: Reset EntraID password via Admin Center
    kb: KB-1001
    priority_bump: 0

  network:
    keywords: [VPN, connection, network, firewall, timeout, cannot connect]
    escalation: L2 if VPN profile corrupted
    suggested_action: Check VPN connection and reconnect
    kb: KB-1005
    priority_bump: 0
```

Load with `yaml.safe_load()`. Merge with user config at `~/.config/ticket-triage/rules.yaml` if exists.

### 2.2 triage.py

```python
def triage(raw_ticket: str, rules: dict) -> TriageResult:
    """
    1. Lowercase + strip input
    2. Extract keywords (simple word boundary match)
    3. Match against category keywords
    4. Score priority (P1 override words + base score)
    5. Score confidence based on match count and category overlap
    6. Check escalation conditions
    7. Return TriageResult namedtuple
    """
```

**TriageResult namedtuple:**

```python
from collections import namedtuple
TriageResult = namedtuple('TriageResult', [
    'category', 'priority', 'action', 'escalate_to',
    'kb', 'signals', 'confidence', 'flag_l2'
])
```

### 2.2a Confidence Calculation

```python
def score_confidence(matched_keywords: list[str], category_count: int) -> str:
    if category_count > 1:
        return "Low"
    if len(matched_keywords) >= 3:
        return "High"
    if len(matched_keywords) >= 1:
        return "Medium"
    return "Low"
```

### 2.2b Priority Mapping

```python
PRIORITY_LEVELS = {"P1": 1, "P2": 2, "P3": 3, "P4": 4}
PRIORITY_LABELS = {1: "P1 (Critical)", 2: "P2 (Medium)", 3: "P3 (Low)", 4: "P4 (Info)"}

def resolve_priority(base: str, urgency_bump: bool, priority_bump: int) -> str:
    level = PRIORITY_LEVELS[base]
    if urgency_bump and level > 1:
        level -= 1  # bump up one level (lower number = higher priority)
    level = max(1, level - priority_bump)
    return PRIORITY_LABELS[level]
```

### 2.3 Priority Scoring Logic

```
base_priority = P2  # default when no override words match
if any_p1_override_word: base_priority = P1
if any_p3_indicator_word: base_priority = P3
if any_p4_indicator_word: base_priority = P4
if any_urgency_modifier: bump one level (P3→P2, P2→P1, P4→P3; P1 stays P1)
if category_has_priority_bump: apply bump value
```

P1 override words: `["down", "outage", "everyone", "production", "urgent", "ASAP", "immediately"]`
P3 indicators: `["when possible", cosmetic terms, question patterns]`
P4 indicators: `["FYI", "for reference", "no action needed"]`

### 2.4 Escalation Flag Logic

```python
def should_escalate(ticket_text: str, category: str) -> tuple[bool, str]:
    # Authentication + MFA/locked keywords → L2 + Security flag
    # Hardware + failure keywords → L2 immediate
    # Multiple categories detected → L2 review
    # P1 + Authentication → L2 + Security
```

---

## 3. CLI Interface (Click)

### 3.1 Main command

```python
@click.command()
@click.option('--file', '-f', type=click.Path(), help='Read ticket from file')
@click.option('--llm', is_flag=True, help='Use local Ollama for enhanced triage')
@click.option('--json', 'output_json', is_flag=True, help='Output as JSON')
@click.version_option(version='1.0.0')
def triage_cli(file, llm, output_json):
    """Triage a support ticket. Reads from stdin if no file provided."""
```

### 3.2 Input handling

- `file` provided → read file contents
- stdin pipe → read stdin
- neither → print usage and exit(1)

### 3.3 Output formatting

Text output (default):
```
Category: Authentication
Priority: P2 (Medium)
Suggested action: Reset EntraID password via Admin Center
Escalate to: L2 if "MFA not working" or "account locked"
Related KB: KB-1042
Root cause signals: ["VPN", "credential", "reset"]
Confidence: High
```

JSON output (`--json`):
```json
{
  "category": "Authentication",
  "priority": "P2",
  "action": "Reset EntraID password via Admin Center",
  "escalate_to": "L2 if MFA or account locked",
  "kb": "KB-1001",
  "signals": ["password", "login"],
  "confidence": "High",
  "flag_l2": false
}
```

### 3.4 Exit codes

| Code | Meaning |
|---|---|
| 0 | triage complete |
| 1 | parse error / no input |
| 2 | requires L2 escalation |

---

## 4. Local LLM Mode (v2 — implement only if time allows)

### 4.1 Ollama integration

```python
def ollama_triage(ticket: str, rules_categories: list[str]) -> dict:
    prompt = f"""Ticket: {ticket}

Categories: {rules_categories}

Return JSON: {{"category": "...", "confidence": "High/Medium/Low", "reasoning": "..."}}"""

    resp = requests.post(
        'http://localhost:11434/api/generate',
        json={'model': 'llama3.2', 'prompt': prompt, 'stream': False},
        timeout=30
    )
    return json.loads(resp.json()['response'])
```

### 4.2 Fallback chain

```
ticket text → rule engine triage
  → if --llm flag AND ollama available → LLM refinement
  → else → return rule engine result
```

Graceful degradation: if Ollama is down, warn and fall back to rule engine silently.

---

## 5. Config Override (macOS)

```python
from pathlib import Path

def load_rules():
    default_rules = Path(__file__).parent / 'rules.yaml'
    user_rules = Path.home() / '.config' / 'ticket-triage' / 'rules.yaml'
    
    with open(default_rules) as f:
        rules = yaml.safe_load(f)
    
    if user_rules.exists():
        with open(user_rules) as f:
            user = yaml.safe_load(f)
        if user and 'categories' in user:
            rules['categories'].update(user['categories'])  # user overrides default
    
    return rules
```

---

## 6. Testing Strategy

### 6.1 Test cases (test_triage.py)

```python
def test_authentication_ticket():
    result = triage("User can't login, password expired in EntraID", rules)
    assert result.category == "Authentication"
    assert result.priority == "P2"  # no P1 override

def test_p1_override():
    result = triage("URGENT: entire team can't access VPN, production is down", rules)
    assert result.priority == "P1"

def test_escalation_flag_auth_mfa():
    result = triage("User locked out, MFA token not working", rules)
    assert result.flag_l2 == True
    assert "Security" in result.escalate_to

def test_confidence():
    result = triage("User can't login, password expired, account locked", rules)
    assert result.confidence == "High"

def test_low_confidence_ambiguous():
    result = triage("VPN is down and can't login to email", rules)
    assert result.confidence == "Low"

def test_no_input():
    with pytest.raises(ValueError, match="empty"):
        triage("", rules)
```

### 6.2 Test fixtures

`tests/fixtures/` — sample tickets per category.

---

## 7. Installation

### 7a. Editable install (dev)

```bash
pip install -e .
```

### 7b. Build + distribute

```bash
pip install build
python -m build
# uploads to PyPI (future)
```

### 7c. Homebrew installation

```bash
brew tap your-org/tap
brew install ticket-triage
```

Installable as `ticket-triage` command after editable install.

---

## 8. Homebrew Formula (Formula/ticket-triage.rb)

```ruby
class TicketTriage < Formula
  desc "CLI tool for L1 support ticket triage"
  homepage "https://github.com/your-org/ticket-triage-cli"
  url "https://github.com/your-org/ticket-triage-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "python@3.11"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "Category", pipe_output(bin/"ticket-triage", "User can't login")
  end
end
```

---

## 9. Known Pitfalls (macOS)

1. **stdin detection** — `sys.stdin.isatty()` is the correct check. Don't rely on `len(sys.argv)` alone.
2. **Unicode in output** — macOS Terminal handles emoji natively. Test with zsh and bash.
3. **YAML anchor refs** — Don't use YAML anchors in rules.yaml with `pyyaml` default loader; use `yaml.safe_load()` which ignores them.
4. **LLM timeout** — Set `timeout=30` on Ollama requests. Never hang the CLI waiting for LLM.
5. **Multi-line input** — Strip only trailing newlines, preserve internal structure for keyword context.
6. **Homebrew Python** — Ensure formula uses correct Python version.

---

## 10. Out of Scope

- Ticket system integration (ServiceNow, Jira)
- Persistent ticket state
- Web UI or GUI wrapper
- Non-English support
- macOS `.app` bundle
