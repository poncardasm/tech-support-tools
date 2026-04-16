# AD/User Provisioning CLI — PRD (Windows)

## 1. Concept & Vision

A single-command tool for L1 support to provision AD accounts, group memberships, and mailboxes without touching the slow Admin Center UI. One command replaces 10 clicks. L1 gets a clean confirmation output; no accidental misclicks.

Target feel: a trusted script that does exactly what you asked, shows you what it did, and errors loudly if something goes wrong.

## 2. Functional Spec

### 2.1 Commands

```powershell
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

Uses stored Azure AD / EntraID app credentials via environment variables or `%APPDATA%\ad-provision\creds.env`.

## 3. Technical Approach

- **Language:** PowerShell 7+ (native Windows integration)
- **Azure/EntraID:** `Microsoft.Graph` PowerShell module
- **Exchange Online:** `ExchangeOnlineManagement` module
- **CLI framework:** Native PowerShell parameters
- **Config:** `.env` file at `%APPDATA%\ad-provision\creds.env`

### File Structure

```
ad-provisioning-cli/
├── ad-provision.psd1        # Module manifest
├── ad-provision.psm1        # Module implementation
├── public/
│   ├── New-ADUser.ps1
│   ├── Add-ADGroupMember.ps1
│   ├── Enable-Mailbox.ps1
│   ├── Reset-UserPassword.ps1
│   └── Deprovision-User.ps1
├── private/
│   ├── Connect-Graph.ps1
│   └── Get-Config.ps1
├── tests/
│   └── ad-provision.Tests.ps1
└── README.md
```

## 4. Success Criteria

- [ ] `New-ADUser` creates AD account + mailbox in one call
- [ ] `Add-ADGroupMember` returns success/error per group
- [ ] `Reset-UserPassword` forces change-on-next-login flag
- [ ] `Deprovision-User` disables + removes group membership
- [ ] `-WhatIf` mode works for all operations
- [ ] Creds loaded from `%APPDATA%\ad-provision\creds.env`
- [ ] Errors printed to stderr with exit code 1

## 5. Out of Scope (v1)

- Bulk import (CSV)
- Group policy management
- Non-EntraID directories
- Self-service UI
