# AD/User Provisioning CLI — Implementation Plan (macOS)

## 1. Project Setup

### 1.1 Initialize Python project

```bash
cd ad-provisioning-cli
python3 -m venv .venv
source .venv/bin/activate
pip install msgraph-sdk azure-identity click python-dotenv
```

### 1.2 File Structure

```
ad-provisioning-cli/
├── pyproject.toml
├── ad_provision/
│   ├── __init__.py
│   ├── __main__.py
│   ├── commands.py
│   ├── graph_client.py
│   ├── config.py
│   └── output.py
├── config/
│   └── creds.env.example
├── tests/
│   └── test_commands.py
├── Formula/
│   └── ad-provision.rb
└── README.md
```

---

## 2. Core Architecture

### 2.1 graph_client.py

```python
from azure.identity import CertificateCredential
from msgraph import GraphServiceClient

def get_graph_client() -> GraphServiceClient:
    config = load_config()
    credential = CertificateCredential(
        client_id=config['AZURE_CLIENT_ID'],
        tenant_id=config['AZURE_TENANT_ID'],
        certificate_path=config.get('AZURE_CERTIFICATE_PATH')
    )
    return GraphServiceClient(credential)
```

### 2.2 commands.py

```python
import click
from .graph_client import get_graph_client
from .output import write_output

@click.group()
def cli():
    """AD/User Provisioning CLI"""
    pass

@cli.command('new-user')
@click.option('--username', required=True)
@click.option('--name', required=True, help='Display name')
@click.option('--email', required=True)
@click.option('--department', required=True)
@click.option('--groups', multiple=True)
@click.option('--enable-mailbox', is_flag=True)
@click.option('--dry-run', is_flag=True)
def new_user(username, name, email, department, groups, enable_mailbox, dry_run):
    """Create a new AD user."""
    if dry_run:
        write_output('OK', f'Would create user {email}')
        return
    
    client = get_graph_client()
    # Create user via Microsoft Graph SDK
    # ...
    write_output('OK', f'User {email} created')

@cli.command('reset-password')
@click.option('--username', required=True)
@click.option('--dry-run', is_flag=True)
def reset_password(username, dry_run):
    """Reset user password."""
    temp_password = generate_temp_password()
    if dry_run:
        write_output('TEMP', f'Would set password: {temp_password}')
        return
    
    # Reset via Graph API
    write_output('TEMP', f'Password: {temp_password} — force change required')

@cli.command('deprovision')
@click.option('--username', required=True)
@click.option('--reason', default='')
@click.option('--dry-run', is_flag=True)
def deprovision(username, reason, dry_run):
    """Deprovision user account."""
    if dry_run:
        write_output('OK', f'Would deprovision {username}')
        return
    
    client = get_graph_client()
    # Disable account, remove groups, revoke sessions
    write_output('OK', 'Account disabled')
    write_output('OK', 'Removed from all groups')
    write_output('OK', 'Sessions revoked')
```

---

## 3. Configuration

### 3.1 config.py

```python
from pathlib import Path
from dotenv import load_dotenv
import os

def load_config() -> dict:
    config_path = Path.home() / '.config' / 'ad-provision' / 'creds.env'
    
    if not config_path.exists():
        raise FileNotFoundError(
            f"Config not found at {config_path}. "
            "Create creds.env from creds.env.example."
        )
    
    load_dotenv(config_path)
    return {
        'AZURE_CLIENT_ID': os.getenv('AZURE_CLIENT_ID'),
        'AZURE_TENANT_ID': os.getenv('AZURE_TENANT_ID'),
        'AZURE_CERTIFICATE_PATH': os.getenv('AZURE_CERTIFICATE_PATH'),
    }
```

### 3.2 creds.env.example

```env
AZURE_CLIENT_ID=your-app-client-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CERTIFICATE_PATH=~/.config/ad-provision/certificate.pem
```

---

## 4. Output Formatting

### 4.1 output.py

```python
def write_output(type_: str, message: str):
    prefix = {
        'OK': '[OK]   ',
        'FAIL': '[FAIL] ',
        'TEMP': '[TEMP] ',
        'WARN': '[WARN] ',
    }
    print(f"{prefix.get(type_, '[????] ')}{message}")
```

---

## 5. Testing

### 5.1 test_commands.py

```python
from click.testing import CliRunner
from ad_provision import cli

def test_new_user_dry_run():
    runner = CliRunner()
    result = runner.invoke(cli, [
        'new-user', '--username', 'testuser',
        '--name', 'Test User', '--email', 'test@company.com',
        '--department', 'IT', '--dry-run'
    ])
    assert 'Would create user' in result.output

def test_reset_password_dry_run():
    runner = CliRunner()
    result = runner.invoke(cli, [
        'reset-password', '--username', 'testuser', '--dry-run'
    ])
    assert 'Would set password' in result.output
```

---

## 6. Installation

### 6a. Editable install (dev)

```bash
pip install -e .
```

### 6b. Homebrew formula (Formula/ad-provision.rb)

```ruby
class AdProvision < Formula
  desc "CLI for Azure AD/EntraID user provisioning"
  homepage "https://github.com/your-org/ad-provisioning-cli"
  url "https://github.com/your-org/ad-provisioning-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "python@3.11"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "Usage", pipe_output(bin/"ad-provision", "--help")
  end
end
```

---

## 7. Known Pitfalls (macOS)

1. **Certificate path** — Use absolute path or expand `~` in config
2. **Keychain integration** — Can store certificates in macOS Keychain
3. **O365 modules** — Python SDK is preferred over PowerShell on macOS
4. **Permission scopes** — App registration needs User.ReadWrite.All, Group.ReadWrite.All

---

## 8. Out of Scope

- Bulk operations (use bulk-action-runner)
- GUI interface
- On-prem AD support (Azure AD / EntraID only)
