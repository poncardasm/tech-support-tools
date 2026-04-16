# Bulk Action Runner (Windows)

A PowerShell module for CSV-powered bulk operations on Microsoft Entra ID (Azure AD) users. Process hundreds of users in seconds with built-in rate limiting and dry-run support.

## Features

- **Password Resets** — Generate temporary passwords and force change on next login
- **Group Management** — Bulk add users to security groups
- **Mailbox Enable** — Enable Exchange Online mailboxes
- **User Deprovisioning** — Disable accounts and remove group memberships
- **Dry-Run Mode** — Preview all operations without making changes
- **CSV Reports** — Export detailed results with timestamps
- **Rate Limiting** — 500ms throttling between API calls to avoid EntraID limits
- **Error Resilience** — Continue processing on individual failures

## Requirements

- PowerShell 7.0+
- Microsoft.Graph PowerShell module
- EntraID (Azure AD) admin credentials with appropriate permissions

## Installation

```powershell
# Install Microsoft.Graph module if not already installed
Install-Module Microsoft.Graph -Scope CurrentUser

# Import the bulk-run module
Import-Module ./bulk-run.psd1
```

## Quick Start

### 1. Prepare your CSV file

```csv
email,display_name,department
alice@company.com,Alice Smith,IT
bob@company.com,Bob Jones,Finance
carol@company.com,Carol White,HR
```

The CSV must include an `email` column. Semicolon-delimited files are also supported.

### 2. Run bulk operations

```powershell
# Reset passwords for all users
bulk-run password-reset users.csv

# Add users to a group
bulk-run add-group users.csv -Group "IT-All"

# Enable mailboxes
bulk-run enable-mailbox users.csv

# Deprovision users (disable + remove groups)
bulk-run deprovision users.csv -Reason "terminated"
```

### 3. Preview with dry-run

```powershell
# See what would happen without making changes
bulk-run password-reset users.csv -WhatIf
```

### 4. Generate reports

```powershell
# Save results to CSV
bulk-run password-reset users.csv -ReportPath results.csv
```

## Available Operations

| Operation | Description | Required Parameters |
|-----------|-------------|---------------------|
| `password-reset` | Set temp password + force change | None |
| `add-group` | Add users to a security group | `-Group` |
| `enable-mailbox` | Enable Exchange Online mailboxes | None |
| `deprovision` | Disable account + remove memberships | `-Reason` (optional) |

## Usage Examples

### Password Reset

```powershell
# Basic usage
bulk-run password-reset users.csv

# With report
bulk-run password-reset users.csv -ReportPath reset_results.csv

# Dry-run preview
bulk-run password-reset users.csv -WhatIf
```

Output:
```
[OK]   alice@company.com — password reset, temp: Xy#9aBc!
[OK]   bob@company.com — password reset, temp: Pq#7rSt!
[FAIL] carol@company.com — error: User not found
```

### Add to Group

```powershell
# Add all users from CSV to a group
bulk-run add-group users.csv -Group "IT-All"

# Preview first
bulk-run add-group users.csv -Group "IT-All" -WhatIf
```

Output:
```
[OK]   alice@company.com — added to IT-All
[OK]   bob@company.com — added to IT-All
[WARN] carol@company.com — already in group IT-All
```

### Enable Mailboxes

```powershell
bulk-run enable-mailbox users.csv
```

### Deprovision Users

```powershell
# Default reason
bulk-run deprovision users.csv

# Custom reason
bulk-run deprovision users.csv -Reason "contract ended"
```

Output:
```
[OK]   alice@company.com — deprovisioned, removed from 3 groups
[WARN] bob@company.com — account already disabled
```

## Report Format

The CSV report includes the following columns:

| Column | Description |
|--------|-------------|
| `email` | User's email address |
| `operation` | Operation performed |
| `result` | success / failure / dry-run / skipped |
| `detail` | Additional information |
| `timestamp` | ISO 8601 timestamp |

Example report:
```csv
email,operation,result,detail,timestamp
alice@company.com,password-reset,success,Temp password: Xy#9aBc!,2024-03-01T14:00:00
bob@company.com,add-group,success,Added to IT-All,2024-03-01T14:00:01
carol@company.com,enable-mailbox,failure,mailbox already enabled,2024-03-01T14:00:02
```

## Advanced Usage

### Using Individual Functions

```powershell
# Import the module
Import-Module ./bulk-run.psd1

# Use individual functions
Invoke-BulkPasswordReset -CsvPath users.csv -WhatIf
Invoke-BulkAddGroup -CsvPath users.csv -Group "IT-All"
Invoke-BulkEnableMailbox -CsvPath users.csv
Invoke-BulkDeprovision -CsvPath users.csv -Reason "terminated"
```

### Combining Operations

```powershell
# Chain operations in a script
$csvPath = "new_hires.csv"

# First enable mailboxes
bulk-run enable-mailbox $csvPath

# Then add to appropriate groups
bulk-run add-group $csvPath -Group "All-Company"
bulk-run add-group $csvPath -Group "New-Hires"
```

## Rate Limiting

The module automatically throttles API calls with a 500ms delay between operations to avoid hitting EntraID rate limits (approximately 500 requests/minute). This is sufficient for most use cases.

## Error Handling

- Individual user failures don't stop the batch
- All failures are reported at the end
- Check the CSV report for complete details
- Use `-WhatIf` to validate before running

## Troubleshooting

### Module Import Fails

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion  # Should be 7.0+

# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Microsoft.Graph Module Not Found

```powershell
# Install the module
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Import required submodules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
```

### CSV Parsing Errors

Ensure your CSV:
- Has an `email` column (case-insensitive)
- Uses comma (`,`) or semicolon (`;`) as delimiter
- Contains valid email addresses
- Is saved with UTF-8 encoding (recommended)

### Authentication Errors

The module will prompt for Microsoft Graph authentication on first use. Ensure your account has:
- User.ReadWrite.All
- GroupMember.ReadWrite.All
- Directory.ReadWrite.All

## Testing

Run the test suite:

```powershell
# Run all tests
Invoke-Pester -Path ./tests/

# Run with details
Invoke-Pester -Path ./tests/ -Output Detailed
```

The test suite includes 37 tests covering:
- CSV parsing (comma and semicolon delimiters)
- Password generation
- Output formatting
- Throttling
- All four bulk operations
- Dry-run mode
- Report generation

## File Structure

```
bulk-action-runner/
├── bulk-run.psd1              # Module manifest
├── bulk-run.psm1              # Module loader
├── public/
│   ├── Invoke-BulkAction.ps1      # Main entry point
│   ├── Invoke-BulkPasswordReset.ps1
│   ├── Invoke-BulkAddGroup.ps1
│   ├── Invoke-BulkEnableMailbox.ps1
│   └── Invoke-BulkDeprovision.ps1
├── private/
│   ├── Read-BulkCsv.ps1           # CSV parsing
│   ├── Connect-GraphSession.ps1   # Graph API auth
│   ├── Get-BulkConfig.ps1         # Config paths
│   ├── Write-BulkOutput.ps1       # Console output
│   ├── New-TemporaryPassword.ps1  # Password generation
│   └── Start-Throttle.ps1         # Rate limiting
├── tests/
│   ├── bulk-run.Tests.ps1         # Test suite
│   └── fixtures/                   # Test CSV files
│       ├── users.csv
│       ├── semicolon_delimited.csv
│       └── ...
└── README.md
```

## License

Internal L1 Support Tools — Not for redistribution.

## Contributing

Follow the existing code style and add Pester tests for new features.
