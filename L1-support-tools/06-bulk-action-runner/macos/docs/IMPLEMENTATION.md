# Bulk Action Runner — Implementation Plan (macOS)

## 1. Project Setup

```bash
cd bulk-action-runner
python3 -m venv .venv
source .venv/bin/activate
pip install msgraph-sdk azure-identity click python-dotenv
```

## 2. File Structure

```
bulk-action-runner/
├── pyproject.toml
├── bulk/
│   ├── __init__.py
│   ├── __main__.py
│   ├── operations.py
│   ├── report.py
│   ├── config.py
│   └── output.py
├── tests/
│   ├── test_operations.py
│   └── fixtures/
│       └── users.csv
├── Formula/
│   └── bulk-run.rb
└── README.md
```

---

## 3. Core Architecture

### 3.1 __main__.py

```python
import click
from .operations import password_reset, add_group, enable_mailbox, deprovision

@click.group()
def cli():
    """Bulk Action Runner for Azure AD operations."""
    pass

@cli.command()
@click.argument('csv_file', type=click.Path(exists=True))
@click.option('--dry-run', is_flag=True)
@click.option('--report', type=click.Path())
def password_reset(csv_file, dry_run, report):
    """Reset passwords for all users in CSV."""
    from .operations import bulk_password_reset
    bulk_password_reset(csv_file, dry_run, report)

@cli.command()
@click.argument('csv_file', type=click.Path(exists=True))
@click.option('--group', required=True, help='Group to add users to')
@click.option('--dry-run', is_flag=True)
@click.option('--report', type=click.Path())
def add_group(csv_file, group, dry_run, report):
    """Add all users in CSV to a group."""
    from .operations import bulk_add_group
    bulk_add_group(csv_file, group, dry_run, report)

if __name__ == '__main__':
    cli()
```

### 3.2 operations.py

```python
import csv
import time
from pathlib import Path
from .config import get_graph_client
from .output import write_output
from .report import save_report

def bulk_password_reset(csv_path: str, dry_run: bool, report_path: str = None):
    client = get_graph_client()
    results = []
    
    with open(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            email = row['email']
            temp_password = generate_temp_password()
            
            if dry_run:
                write_output('OK', f'{email} — would reset password')
                continue
            
            try:
                client.users.by_user_id(email).patch(
                    body={'passwordProfile': {
                        'password': temp_password,
                        'forceChangePasswordNextSignIn': True
                    }}
                )
                write_output('OK', f'{email} — password reset, temp: {temp_password}')
                results.append({'email': email, 'operation': 'password-reset', 'result': 'success'})
            except Exception as e:
                write_output('FAIL', f'{email} — error: {e}')
                results.append({'email': email, 'operation': 'password-reset', 'result': 'failure', 'detail': str(e)})
            
            time.sleep(0.5)  # Throttle
    
    if report_path:
        save_report(results, report_path)

def bulk_add_group(csv_path: str, group_name: str, dry_run: bool, report_path: str = None):
    client = get_graph_client()
    group_id = get_group_id(client, group_name)
    
    with open(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            email = row['email']
            
            if dry_run:
                write_output('OK', f'{email} — would add to {group_name}')
                continue
            
            try:
                client.groups.by_group_id(group_id).members.ref.post(
                    body={'@odata.id': f'https://graph.microsoft.com/v1.0/users/{email}'}
                )
                write_output('OK', f'{email} — added to {group_name}')
            except Exception as e:
                write_output('FAIL', f'{email} — error: {e}')
            
            time.sleep(0.5)
```

---

## 4. Testing

```python
# tests/test_operations.py
from click.testing import CliRunner
from bulk import cli

def test_password_reset_dry_run():
    runner = CliRunner()
    result = runner.invoke(cli, ['password-reset', 'tests/fixtures/users.csv', '--dry-run'])
    assert 'would reset password' in result.output
```

---

## 5. Known Pitfalls (macOS)

1. **CSV encoding** — Use UTF-8 encoding for cross-platform compatibility
2. **Throttling** — Microsoft Graph has rate limits; 500ms delay per row
3. **Error handling** — Continue on individual failures, collect all errors

---

## 6. Out of Scope

- Rollback/undo operations
- Excel file input
- Web UI
