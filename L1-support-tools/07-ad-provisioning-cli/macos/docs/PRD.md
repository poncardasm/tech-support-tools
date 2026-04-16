# AD/User Provisioning CLI — PRD (macOS)

## 1. Concept & Vision

A single-command tool for L1 support to provision AD accounts, group memberships, and mailboxes without touching the slow Admin Center UI. One command replaces 10 clicks. L1 gets a clean confirmation output; no accidental misclicks.

Target feel: a trusted script that does exactly what you asked, shows you what it did, and errors loudly if something goes wrong.

## 2. Functional Spec

### 2.1 Commands

```bash
ad-provision new-user alice --name "Alice Smith" --email alice@company.com --department IT
ad-provision add-group alice --group "IT-All"
ad-provision enable-mailbox alice
ad-provision reset-password alice
ad-provision deprovision alice --reason "terminated"
```

### 2.2 Operations

| Operation | What it does |
|---|---|
| `new-user` | Create AD account, set UPN, add to dept group, create mailbox |
| `add-group` | Add existing user to AD group |
| `enable-mailbox` | Enable Exchange Online mailbox for existing user |
| `reset-password` | Set temp password, force change on next login |
| `deprovision` | Disable account, remove groups, revoke session tokens |

### 2.3 Output

Every command prints structured confirmation:

```
[OK] User alice@company.com created
[OK] Added to group IT-All
[OK] Mailbox enabled
[TEMP] Password: Xy#9aBc! — force change required
```

### 2.4 Dry-run Mode

`--dry-run` flag shows what would happen without making changes.

### 2.5 Credentials

Uses stored Azure AD / EntraID app credentials via environment variables or `~/.config/ad-provision/creds.env`.

## 3. Technical Approach

- **Language:** Python 3.10+
- **Azure/EntraID:** `msgraph-sdk` + `azure-identity`
- **Exchange Online:** `exchangeonline-mgmt` via Microsoft Graph
- **CLI framework:** Click
- **Config:** `.env` file at `~/.config/ad-provision/creds.env`

### File Structure

```
ad-provisioning-cli/
├── pyproject.toml
├── ad_provision/
│   ├── __init__.py
│   ├── __main__.py
│   ├── commands.py
│   ├── graph_client.py
│   └── config.py
├── tests/
│   └── test_commands.py
├── Formula/
│   └── ad-provision.rb
└── README.md
```

## 4. Success Criteria

- [ ] `new-user` creates AD account + mailbox in one call
- [ ] `add-group` returns success/error per group
- [ ] `reset-password` forces change-on-next-login flag
- [ ] `deprovision` disables + removes group membership
- [ ] `--dry-run` mode works for all operations
- [ ] Creds loaded from `~/.config/ad-provision/creds.env`
- [ ] Errors printed to stderr with exit code 1

## 5. Out of Scope (v1)

- Bulk import (CSV) — use bulk-action-runner instead
- Group policy management
- Non-EntraID directories
- Self-service UI
