# Runbook Automation — Implementation Plan (macOS)

## 1. Project Setup

```bash
cd runbook-automation
python3 -m venv .venv
source .venv/bin/activate
pip install click mistune
```

## 2. File Structure

```
runbook-automation/
├── pyproject.toml
├── runbook/
│   ├── __init__.py
│   ├── __main__.py
│   ├── parser.py
│   ├── executor.py
│   ├── indexer.py
│   └── state.py
├── runbooks/
│   ├── authentication/
│   ├── networking/
│   └── infrastructure/
├── tests/
│   └── test_parser.py
├── Formula/
│   └── runbook.rb
└── README.md
```

---

## 3. Core Architecture

### 3.1 parser.py

```python
import mistune
from dataclasses import dataclass
from typing import Iterator

@dataclass
class Step:
    number: int
    code: str
    language: str

class StepExtractor(mistune.HTMLRenderer):
    def __init__(self):
        super().__init__()
        self.steps = []
        self.step_number = 0
        self.in_code_block = False
        self.current_lang = None
        self.current_code = []
    
    def block_code(self, code, lang=None):
        if lang in ('bash', 'sh', 'zsh'):
            self.step_number += 1
            self.steps.append(Step(
                number=self.step_number,
                code=code.strip(),
                language=lang
            ))
        return super().block_code(code, lang)

def parse_runbook(file_path: str) -> list[Step]:
    with open(file_path) as f:
        content = f.read()
    
    # Simple regex approach for extracting bash/sh code blocks
    import re
    pattern = r'```(?:bash|sh|zsh)\s*\n(.*?)```'
    matches = re.findall(pattern, content, re.DOTALL)
    
    steps = []
    for i, code in enumerate(matches, 1):
        steps.append(Step(number=i, code=code.strip(), language='bash'))
    
    return steps
```

### 3.2 executor.py

```python
import subprocess
import sys
from .parser import Step
from .state import save_state, load_state

def execute_step(step: Step, total: int, dry_run: bool = False) -> dict:
    print(f"[STEP {step.number}/{total}] {step.code[:50]}...")
    
    if dry_run:
        print(f"  COMMAND: {step.code}")
        return {'exit_code': 0, 'output': ''}
    
    result = subprocess.run(
        step.code,
        shell=True,
        capture_output=True,
        text=True
    )
    
    if result.stdout:
        print(f"  Output: {result.stdout[:200]}")
    if result.stderr:
        print(f"  Error: {result.stderr[:200]}", file=sys.stderr)
    
    return {
        'exit_code': result.returncode,
        'output': result.stdout + result.stderr
    }

def execute_runbook(file_path: str, from_step: int = 1, dry_run: bool = False):
    steps = parse_runbook(file_path)
    total = len(steps)
    
    for step in steps[from_step - 1:]:
        result = execute_step(step, total, dry_run)
        
        save_state(file_path, step.number)
        
        if result['exit_code'] != 0 and not dry_run:
            print("\n[DID NOT EXPECT THIS] Stopping. Options:")
            print("  [s] Skip this step and continue")
            print("  [f] Force continue")
            print("  [a] Abort")
            
            choice = input("> ").lower()
            
            if choice == 'a':
                return
            elif choice in ('s', 'f'):
                continue
    
    print("[OK] Runbook completed successfully")
```

### 3.3 state.py

```python
import json
from pathlib import Path
from datetime import datetime

def get_state_path(file_path: str) -> Path:
    state_dir = Path.home() / '.config' / 'runbook' / 'state'
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir / (Path(file_path).stem + '.json')

def save_state(file_path: str, step_number: int):
    state_file = get_state_path(file_path)
    state = {
        'runbook': file_path,
        'current_step': step_number,
        'last_run': datetime.now().isoformat()
    }
    state_file.write_text(json.dumps(state))

def load_state(file_path: str) -> dict:
    state_file = get_state_path(file_path)
    if state_file.exists():
        return json.loads(state_file.read_text())
    return {'current_step': 1}
```

### 3.4 indexer.py

```python
from pathlib import Path

def list_runbooks(directory: str = './runbooks', category: str = None) -> list[dict]:
    search_path = Path(directory)
    if category:
        search_path = search_path / category
    
    runbooks = []
    for path in search_path.rglob('*.md'):
        runbooks.append({
            'name': path.stem,
            'path': str(path),
            'category': path.parent.name
        })
    
    return runbooks

def search_runbooks(query: str, directory: str = './runbooks') -> list[dict]:
    runbooks = list_runbooks(directory)
    results = []
    
    for rb in runbooks:
        with open(rb['path']) as f:
            content = f.read().lower()
        
        if query.lower() in rb['name'].lower() or query.lower() in content:
            results.append(rb)
    
    return results
```

---

## 4. CLI

```python
# __main__.py
import click
from .executor import execute_runbook
from .indexer import list_runbooks, search_runbooks

@click.group()
def cli():
    """Runbook Automation CLI."""
    pass

@cli.command()
@click.argument('file', type=click.Path(exists=True))
@click.option('--from-step', default=1, help='Start from step N')
@click.option('--resume', is_flag=True, help='Resume from last failed step')
@click.option('--dry-run', is_flag=True, help='Show commands without executing')
def run(file, from_step, resume, dry_run):
    """Execute a runbook."""
    if resume:
        from .state import load_state
        state = load_state(file)
        from_step = state.get('current_step', 1)
    
    execute_runbook(file, from_step, dry_run)

@cli.command()
@click.option('--category', help='Filter by category')
def list(category):
    """List all runbooks."""
    runbooks = list_runbooks(category=category)
    for rb in runbooks:
        click.echo(f"{rb['name']:30} ({rb['category']})")

@cli.command()
@click.argument('query')
def search(query):
    """Search runbooks."""
    results = search_runbooks(query)
    for rb in results:
        click.echo(f"{rb['name']:30} ({rb['category']})")

if __name__ == '__main__':
    cli()
```

---

## 5. Testing

```python
# tests/test_parser.py
from runbook.parser import parse_runbook

def test_parse_runbook():
    steps = parse_runbook('tests/fixtures/sample.md')
    assert len(steps) > 0
    assert steps[0].language == 'bash'
```

---

## 6. Known Pitfalls (macOS)

1. **Sudo prompts** — Interactive sudo won't work well
2. **Path spaces** — Quote paths correctly
3. **Zsh vs Bash** — User's shell may differ
4. **Permissions** — Some runbooks need sudo

---

## 7. Out of Scope

- PowerShell support (use Windows version)
- Cloud runbook integration
- Web UI
