# Log Dump Parser — Implementation Plan (macOS)

## 1. Project Setup

```bash
cd log-dump-parser
python3 -m venv .venv
source .venv/bin/activate
pip install click pyyaml pyparsing
```

## 2. File Structure

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
│       ├── syslog.py
│       ├── journald.py
│       └── docker.py
├── tests/
│   ├── test_parser.py
│   └── fixtures/
│       ├── sample.log
│       └── sample.json
├── Formula/
│   └── log-parse.rb
└── README.md
```

---

## 3. Core Architecture

### 3.1 parser.py

```python
from pathlib import Path
from typing import Iterator
from dataclasses import dataclass
import re

@dataclass
class LogEntry:
    timestamp: str
    level: str  # ERROR, WARN, INFO, DEBUG
    source: str
    message: str
    raw: str

def detect_format(file_path: str) -> str:
    with open(file_path, 'rb') as f:
        header = f.read(500)
        
        # journald JSON export
        if b'__CURSOR' in header:
            return 'journald'
        
        # JSON lines
        first_line = header.split(b'\n')[0]
        if first_line.strip().startswith(b'{'):
            if b'"log"' in first_line:
                return 'docker'
            return 'json_lines'
        
        # Syslog pattern
        syslog_pattern = rb'^[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}'
        if re.match(syslog_pattern, header):
            return 'syslog'
        
        # Apache/Nginx
        if re.match(rb'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', header):
            return 'apache'
    
    return 'plain'

def parse_file(file_path: str, format: str = None) -> Iterator[LogEntry]:
    detected = format or detect_format(file_path)
    
    if detected == 'syslog':
        yield from parse_syslog(file_path)
    elif detected == 'journald':
        yield from parse_journald(file_path)
    elif detected == 'docker':
        yield from parse_docker(file_path)
    elif detected == 'json_lines':
        yield from parse_json_lines(file_path)
    else:
        yield from parse_plain(file_path)
```

### 3.2 patterns/syslog.py

```python
import re
from dataclasses import dataclass

SYSLOG_PATTERN = re.compile(
    r'^(\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+'  # timestamp
    r'(\S+)\s+'  # hostname
    r'(\S+?)(?:\[\d+\])?:\s+'  # process
    r'(.*)$'  # message
)

LEVEL_KEYWORDS = {
    'error': 'ERROR',
    'fail': 'ERROR',
    'critical': 'ERROR',
    'warning': 'WARN',
    'warn': 'WARN',
}

def parse_syslog(file_path: str):
    with open(file_path, 'r', errors='ignore') as f:
        for line in f:
            match = SYSLOG_PATTERN.match(line.strip())
            if match:
                timestamp, hostname, source, message = match.groups()
                
                level = 'INFO'
                for keyword, lvl in LEVEL_KEYWORDS.items():
                    if keyword in message.lower():
                        level = lvl
                        break
                
                yield LogEntry(
                    timestamp=timestamp,
                    level=level,
                    source=source,
                    message=message,
                    raw=line
                )
```

### 3.3 patterns/journald.py

```python
import json

def parse_journald(file_path: str):
    with open(file_path, 'r') as f:
        for line in f:
            try:
                data = json.loads(line)
                priority = data.get('PRIORITY', '6')
                level = {'3': 'ERROR', '4': 'WARN', '6': 'INFO'}.get(priority, 'INFO')
                
                yield LogEntry(
                    timestamp=data.get('__REALTIME_TIMESTAMP', ''),
                    level=level,
                    source=data.get('SYSLOG_IDENTIFIER', data.get('_COMM', 'unknown')),
                    message=data.get('MESSAGE', ''),
                    raw=line
                )
            except json.JSONDecodeError:
                continue
```

---

## 4. Analysis Functions

```python
from collections import Counter
import re

def analyze_entries(entries: list[LogEntry], level_filter: list[str] = None) -> dict:
    errors = Counter()
    warnings = Counter()
    sources = Counter()
    
    for entry in entries:
        if level_filter and entry.level not in level_filter:
            continue
        
        sources[entry.source] += 1
        
        if entry.level == 'ERROR':
            errors[normalize_message(entry.message)] += 1
        elif entry.level == 'WARN':
            warnings[normalize_message(entry.message)] += 1
    
    return {
        'error_counts': errors.most_common(10),
        'warning_counts': warnings.most_common(10),
        'top_sources': sources.most_common(5),
    }

def normalize_message(msg: str) -> str:
    msg = re.sub(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', '[IP]', msg)
    msg = re.sub(r'\b\d{4,}\b', '[ID]', msg)
    return msg[:100]
```

---

## 5. CLI

```python
# __main__.py
import click
from .parser import parse_file, detect_format
from .analyzer import analyze_entries
from .formatters import format_text, format_json

@click.command()
@click.argument('file', type=click.Path(exists=True))
@click.option('--format', help='Force log format')
@click.option('--level', help='Filter by level (ERROR,WARN)')
@click.option('--since', help='Filter from timestamp')
@click.option('--json', 'output_json', is_flag=True)
def cli(file, format, level, since, output_json):
    entries = list(parse_file(file, format))
    analysis = analyze_entries(entries, level.split(',') if level else None)
    
    stats = {
        'file': file,
        'total': len(entries),
        'errors': sum(1 for e in entries if e.level == 'ERROR'),
        'warnings': sum(1 for e in entries if e.level == 'WARN'),
    }
    
    if output_json:
        print(format_json(analysis, stats))
    else:
        print(format_text(analysis, stats))

if __name__ == '__main__':
    cli()
```

---

## 6. Known Pitfalls (macOS)

1. **File encoding** — Use `errors='ignore'` for unknown encodings
2. **Large files** — Stream processing for files > 100MB
3. **Log rotation** — Handle compressed logs (.gz, .bz2)
4. **Permission** — Some logs require sudo

---

## 7. Out of Scope

- Real-time streaming
- Remote log collection
- Web UI
