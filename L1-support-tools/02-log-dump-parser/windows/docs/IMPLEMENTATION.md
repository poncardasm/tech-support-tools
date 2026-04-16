# Log Dump Parser — Implementation Plan (Windows)

## 1. Project Setup

```powershell
cd log-dump-parser
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install click python-evtx pyyaml pyinstaller
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
│       ├── evtx.py
│       ├── json_lines.py
│       └── iis.py
├── tests/
│   ├── test_parser.py
│   └── fixtures/
│       ├── sample.evtx
│       └── sample.json
├── build/
│   └── log-parse.exe
├── log-parse.spec
└── README.md
```

---

## 3. Core Architecture

### 3.1 parser.py

```python
from pathlib import Path
from typing import Iterator
from dataclasses import dataclass

@dataclass
class LogEntry:
    timestamp: str
    level: str  # ERROR, WARN, INFO, DEBUG
    source: str
    message: str
    raw: str

def detect_format(file_path: str) -> str:
    path = Path(file_path)
    
    # Check extension
    if path.suffix == '.evtx':
        return 'evtx'
    
    # Check content
    with open(file_path, 'rb') as f:
        header = f.read(100)
        
        if b'<Event' in header:
            return 'evtx_xml'
        
        # Check for JSON lines
        f.seek(0)
        first_line = f.readline()
        if first_line.strip().startswith(b'{'):
            return 'json_lines'
        
        # IIS log format
        if b'#Fields:' in header or b'#Software:' in header:
            return 'iis'
    
    return 'plain'

def parse_file(file_path: str, format: str = None) -> Iterator[LogEntry]:
    detected = format or detect_format(file_path)
    
    if detected == 'evtx':
        yield from parse_evtx(file_path)
    elif detected == 'evtx_xml':
        yield from parse_evtx_xml(file_path)
    elif detected == 'json_lines':
        yield from parse_json_lines(file_path)
    elif detected == 'iis':
        yield from parse_iis(file_path)
    else:
        yield from parse_plain(file_path)
```

### 3.2 patterns/evtx.py

```python
import Evtx.Evtx as evtx
import Evtx.Views as e_views
from xml.etree import ElementTree

def parse_evtx(file_path: str):
    with evtx.Evtx(file_path) as log:
        for record in log.records():
            xml = record.xml()
            root = ElementTree.fromstring(xml)
            
            # Extract fields
            system = root.find('.//{http://schemas.microsoft.com/win/2004/08/events}System')
            time_created = system.find('.//{http://schemas.microsoft.com/win/2004/08/events}TimeCreated')
            
            level = root.find('.//{http://schemas.microsoft.com/win/2004/08/events}Level')
            level_text = {'2': 'ERROR', '3': 'WARN', '4': 'INFO'}.get(level.text if level is not None else '4', 'INFO')
            
            provider = system.find('.//{http://schemas.microsoft.com/win/2004/08/events}Provider')
            source = provider.get('Name', 'Unknown') if provider is not None else 'Unknown'
            
            # Extract message from RenderedText or use raw
            message = extract_message(root)
            
            yield LogEntry(
                timestamp=time_created.get('SystemTime', '') if time_created is not None else '',
                level=level_text,
                source=source,
                message=message,
                raw=xml
            )
```

---

## 4. Analysis Functions

### 4.1 Group and Count

```python
from collections import Counter

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
    # Remove variable parts (PIDs, timestamps, IPs)
    import re
    msg = re.sub(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', '[IP]', msg)
    msg = re.sub(r'\b\d{4,}\b', '[ID]', msg)
    return msg[:100]
```

---

## 5. Output Formatters

```python
# formatters.py

def format_text(analysis: dict, stats: dict) -> str:
    output = []
    output.append("=== Log Summary ===")
    output.append(f"File: {stats['file']}")
    output.append(f"Lines parsed: {stats['total']} | Errors: {stats['errors']} | Warnings: {stats['warnings']}")
    output.append("")
    
    output.append(f"[ERRORS — {stats['errors']} total]")
    for msg, count in analysis['error_counts']:
        output.append(f"  {count:>4}x {msg}")
    
    output.append("")
    output.append(f"[WARNINGS — {stats['warnings']} total]")
    for msg, count in analysis['warning_counts']:
        output.append(f"  {count:>4}x {msg}")
    
    return '\n'.join(output)
```

---

## 6. CLI

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

## 7. Known Pitfalls (Windows)

1. **EVTX corruption** — Handle corrupted event logs gracefully
2. **Large files** — Stream processing for files > 100MB
3. **Encoding** — Windows logs may use various encodings
4. **Permission** — Some logs require admin access

---

## 8. Out of Scope

- Real-time streaming
- Remote log collection
- Web UI
