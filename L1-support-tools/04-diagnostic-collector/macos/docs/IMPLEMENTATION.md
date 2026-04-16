# Diagnostic Collector — Implementation Plan (macOS)

## 1. Project Setup

```bash
cd diagnostic-collector
python3 -m venv .venv
source .venv/bin/activate
pip install click
```

## 2. File Structure

```
diagnostic-collector/
├── pyproject.toml
├── diag/
│   ├── __init__.py
│   ├── __main__.py
│   ├── collector.sh
│   ├── formatters.py
│   └── thresholds.py
├── tests/
│   └── test_formatters.py
├── Formula/
│   └── diag-collect.rb
└── README.md
```

---

## 3. Main Script (collector.sh)

```bash
#!/bin/bash

# Diagnostic Collector for macOS

collect_system_info() {
    echo "hostname=$(hostname)"
    echo "os=$(sw_vers -productVersion)"
    echo "os_name=$(sw_vers -productName)"
    echo "model=$(system_profiler SPHardwareDataType | awk '/Model Name/{print $3}')"
    echo "chip=$(system_profiler SPHardwareDataType | awk '/Chip/{for(i=3;i<=NF;i++)printf $i" "}')"
    echo "uptime=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
}

collect_disk_info() {
    df -h | awk 'NR>1 {
        used=$3
        total=$2
        pct=$5
        mount=$9
        gsub(/%/, "", pct)
        status="OK"
        if (pct > 90) status="CRITICAL"
        else if (pct > 80) status="WARNING HIGH"
        print "drive=" mount, "used=" used, "total=" total, "percent=" pct, "status=" status
    }'
}

collect_memory_info() {
    # macOS memory via vm_stat and top
    vm_stat | head -10
    top -l 1 | grep "PhysMem"
}

collect_network_info() {
    ifconfig | grep "inet " | awk '{print "ip="$2}'
    netstat -rn | grep default | awk '{print "gateway="$2}'
    scutil --dns | grep "nameserver" | awk '{print "dns="$3}'
}

collect_services() {
    launchctl list | grep -v "^#" | awk '{print "service="$3, "status="$1}'
}

collect_logs() {
    log show --predicate 'messageType == error' --last 1d | head -50
}

collect_updates() {
    softwareupdate --list 2>/dev/null || echo "No updates available"
    
    if command -v brew &> /dev/null; then
        brew outdated
    fi
}

# Main
collect_all() {
    echo "=== SYSTEM ==="
    collect_system_info
    echo ""
    echo "=== DISK ==="
    collect_disk_info
    echo ""
    echo "=== MEMORY ==="
    collect_memory_info
    echo ""
    echo "=== NETWORK ==="
    collect_network_info
    echo ""
    echo "=== SERVICES ==="
    collect_services
    echo ""
    echo "=== LOGS ==="
    collect_logs
    echo ""
    echo "=== UPDATES ==="
    collect_updates
}

case "${1:-}" in
    --json)
        collect_all | python3 -m diag.formatters --json
        ;;
    --html)
        collect_all | python3 -m diag.formatters --html
        ;;
    *)
        collect_all
        ;;
esac
```

---

## 4. Python Formatters (formatters.py)

```python
import click
import sys
import json

@click.command()
@click.option('--json', 'output_json', is_flag=True)
@click.option('--html', 'output_html', is_flag=True)
def format_output(output_json, output_html):
    data = parse_collector_output(sys.stdin.read())
    
    if output_json:
        print(json.dumps(data, indent=2))
    elif output_html:
        print(format_html(data))
    else:
        print(format_markdown(data))

def parse_collector_output(raw: str) -> dict:
    result = {'sections': {}}
    current_section = None
    
    for line in raw.split('\n'):
        if line.startswith('=== ') and line.endswith(' ==='):
            current_section = line.strip('= ')
            result['sections'][current_section] = []
        elif current_section and '=' in line:
            result['sections'][current_section].append(line)
    
    return result

def format_markdown(data: dict) -> str:
    md = f"# Diagnostic Report\n\n"
    for section, lines in data.get('sections', {}).items():
        md += f"## {section}\n"
        for line in lines:
            md += f"- {line}\n"
        md += "\n"
    return md

if __name__ == '__main__':
    format_output()
```

---

## 5. Testing

```python
# tests/test_formatters.py
from diag.formatters import parse_collector_output, format_markdown

def test_parse_output():
    raw = "=== SYSTEM ===\nhostname=test\n=== DISK ===\ndrive=/"
    result = parse_collector_output(raw)
    assert 'SYSTEM' in result['sections']
    assert 'DISK' in result['sections']

def test_format_markdown():
    data = {'sections': {'SYSTEM': ['hostname=test']}}
    md = format_markdown(data)
    assert '# Diagnostic Report' in md
    assert '## SYSTEM' in md
```

---

## 6. Known Pitfalls (macOS)

1. **Permissions** — Some commands may need Full Disk Access
2. **SIP** — System Integrity Protection blocks some paths
3. **Apple Silicon** — Different memory reporting than Intel Macs
4. **Homebrew** — Optional dependency for package listing

---

## 7. Out of Scope

- Windows/Linux support
- Real-time monitoring
- GUI application
