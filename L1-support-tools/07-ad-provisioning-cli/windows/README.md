# AD/User Provisioning CLI (Windows)

A PowerShell module for L1 support to provision AD accounts, group memberships, and mailboxes without touching the slow Admin Center UI. One command replaces 10 clicks.

## Features

- **Create users** with department auto-assignment
- **Add to groups** with existence checking
- **Enable mailboxes** in Exchange Online
- **Reset passwords** with force-change flag
- **Deprovision users** (disable, remove groups, revoke sessions)
- **Dry-run mode** with `-WhatIf` for all operations
- **Certificate-based authentication** for secure automation

## Prerequisites

- PowerShell 7.0 or later
- Microsoft.Graph.Users module (v2.0.0+)
- Microsoft.Graph.Groups module (v2.0.0+)
- ExchangeOnlineManagement module (v3.0.0+)

### Installing Prerequisites

```powershell
# Install PowerShell 7 (if not already installed)
winget install Microsoft.PowerShell

# Install required modules
Install-Module Microsoft.Graph.Users -Scope CurrentUser -MinimumVersion 2.0.0
Install-Module Microsoft.Graph.Groups -Scope CurrentUser -MinimumVersion 2.0.0
Install-Module ExchangeOnlineManagement -Scope CurrentUser -MinimumVersion 3.0.0
```

## Setup

### 1. Azure AD App Registration

You need an Azure AD app registration with the following permissions:

- **User.ReadWrite.All** - Create and manage users
- **Group.ReadWrite.All** - Manage group memberships
- **Organization.Read.All** - Read tenant information

And admin consent granted for these permissions.

### 2. Certificate Authentication

Upload a certificate to your app registration and note the thumbprint. The certificate must be installed in the user's `CurrentUser\My` certificate store.

### 3. Configuration File

Create the configuration file at `%APPDATA%\ad-provision\creds.env`:

```powershell
# Create the directory
mkdir "$env:APPDATA\ad-provision"

# Copy the example file and edit
copy config\creds.env.example "$env:APPDATA\ad-provision\creds.env"
notepad "$env:APPDATA\ad-provision\creds.env"
```

Edit the file with your credentials:

```env
AZURE_CLIENT_ID=your-app-client-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CERTIFICATE_THUMBPRINT=your-cert-thumbprint
```

## Installation

### Option 1: Manual Installation

```powershell
# Copy module to PowerShell modules path
$modulePath = Join-Path $env:Documents "PowerShell\Modules\ad-provision"
Copy-Item -Recurse .\ad-provisioning-cli $modulePath

# Import the module
Import-Module ad-provision
```

### Option 2: Development Installation

```powershell
# Navigate to the module directory
cd 07-ad-provisioning-cli\windows

# Import directly
Import-Module .\ad-provision.psd1 -Force
```

## Usage

### Create a New User

```powershell
# Basic user creation
New-ADProvisionUser `
    -Username "asmith" `
    -DisplayName "Alice Smith" `
    -Email "asmith@company.com" `
    -Department "IT"

# With additional groups and mailbox
New-ADProvisionUser `
    -Username "bjones" `
    -DisplayName "Bob Jones" `
    -Email "bjones@company.com" `
    -Department "Sales" `
    -Groups @("Sales-Managers", "All-Company") `
    -EnableMailbox
```

**Output:**
```
[OK]   User bjones@company.com created
[OK]   Added to department group Sales-All
[OK]   Added to group Sales-Managers
[OK]   Added to group All-Company
[OK]   Mailbox enabled for bjones@company.com
[TEMP] Password: Xy#9aBc!123 - force change required on first login
```

### Add User to Group

```powershell
Add-ADProvisionGroup -Username "asmith@company.com" -Group "IT-Admins"
```

### Enable Mailbox

```powershell
Enable-ADProvisionMailbox -Username "asmith@company.com"
```

### Reset Password

```powershell
Reset-ADProvisionPassword -Username "asmith@company.com"
```

**Output:**
```
[OK]   Password reset for asmith@company.com
[TEMP] Password: Ab#9xYz!456 - force change required on next login
```

### Deprovision User

```powershell
# Basic deprovisioning
Remove-ADProvisionUser -Username "asmith@company.com" -Reason "Terminated"

# With mailbox removal
Remove-ADProvisionUser `
    -Username "asmith@company.com" `
    -Reason "Contract ended" `
    -RemoveMailbox
```

**Output:**
```
[OK]   Removed from 5 groups
[OK]   All sign-in sessions revoked
[OK]   Account disabled
[OK]   Deprovisioning complete for asmith@company.com
```

### Dry-Run Mode

All commands support `-WhatIf` to preview changes:

```powershell
New-ADProvisionUser `
    -Username "testuser" `
    -DisplayName "Test User" `
    -Email "test@company.com" `
    -Department "IT" `
    -EnableMailbox `
    -WhatIf
```

**Output:**
```
[OK]   [WhatIf] Would create user test@company.com
[OK]   [WhatIf] Would add to department: IT
[OK]   [WhatIf] Would enable Exchange Online mailbox
[TEMP] [WhatIf] Would generate temporary password
```

## Available Commands

| Command | Description |
|---------|-------------|
| `New-ADProvisionUser` | Create user, add to dept group, optional mailbox |
| `Add-ADProvisionGroup` | Add existing user to AD group |
| `Enable-ADProvisionMailbox` | Enable Exchange Online mailbox |
| `Reset-ADProvisionPassword` | Set temp password, force change on login |
| `Remove-ADProvisionUser` | Disable, remove groups, revoke sessions |

## Testing

Run the Pester test suite:

```powershell
# Install Pester if not already installed
Install-Module Pester -Scope CurrentUser -MinimumVersion 5.0.0

# Run all tests
Invoke-Pester tests/

# Run with detailed output
Invoke-Pester tests/ -Output Detailed

# Run specific test
Invoke-Pester tests/ -Filter "New-ADProvisionUser"
```

## Output Format

All commands use standardized output prefixes:

| Prefix | Color | Meaning |
|--------|-------|---------|
| `[OK]` | Green | Success |
| `[FAIL]` | Red | Error |
| `[TEMP]` | Yellow | Temporary value (passwords) |
| `[WARN]` | Yellow | Warning/Notice |

## Troubleshooting

### "Config not found" error

Ensure the config file exists at `%APPDATA%\ad-provision\creds.env`:

```powershell
Test-Path "$env:APPDATA\ad-provision\creds.env"
```

### Certificate not found

Verify the certificate is in the correct store:

```powershell
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq "YOUR_THUMBPRINT" }
```

### Microsoft Graph connection fails

Check your app registration has the required permissions and admin consent:

```powershell
# Test connection manually
Connect-MgGraph -ClientId "your-client-id" -TenantId "your-tenant-id" -CertificateThumbprint "your-thumbprint"
Get-MgContext
```

### Module won't import

Check that all required modules are installed:

```powershell
Get-Module Microsoft.Graph.Users, Microsoft.Graph.Groups, ExchangeOnlineManagement -ListAvailable
```

## Security Notes

- The configuration file (`creds.env`) should have restricted permissions
- Certificate-based auth is required; password-based auth is not supported
- All operations are logged to the PowerShell verbose stream (use `-Verbose`)
- Temporary passwords are only displayed once - capture them immediately

## Project Structure

```
windows/
├── ad-provision.psd1              # Module manifest
├── ad-provision.psm1              # Module entry point
├── public/                          # Public functions
│   ├── New-ADProvisionUser.ps1
│   ├── Add-ADProvisionGroup.ps1
│   ├── Enable-ADProvisionMailbox.ps1
│   ├── Reset-ADProvisionPassword.ps1
│   └── Remove-ADProvisionUser.ps1
├── private/                       # Private helpers
│   ├── Connect-GraphSession.ps1
│   ├── Connect-ExchangeSession.ps1
│   ├── Get-ProvisionConfig.ps1
│   ├── Write-ProvisionOutput.ps1
│   └── New-TemporaryPassword.ps1
├── config/                        # Configuration templates
│   └── creds.env.example
├── tests/                         # Pester tests
│   └── ad-provision.Tests.ps1
├── docs/                          # Documentation
│   ├── PRD.md
│   ├── IMPLEMENTATION.md
│   └── TASKS.md
└── README.md                      # This file
```

## License

Internal use only - L1 Support Tools
