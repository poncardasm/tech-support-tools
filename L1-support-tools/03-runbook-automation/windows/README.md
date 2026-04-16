# Runbook Automation for Windows

A PowerShell module for managing and executing markdown-based runbooks with embedded PowerShell steps.

## Overview

Runbook Automation lets you write operational procedures in Markdown with executable PowerShell code blocks. Execute them sequentially with a single command—no more copy-paste from wikis into terminals.

## Installation

### Prerequisites

- PowerShell 7.0 or later
- Windows PowerShell 5.1 (with limited support)

### Install from Source

```powershell
cd 03-runbook-automation/windows
Import-Module .\runbook.psd1
```

## Quick Start

### 1. Create a Runbook

Create a Markdown file with PowerShell code blocks:

````markdown
# Restart IIS Application Pool

## Steps

1. Check current status
   ```powershell
   Get-IISAppPool -Name "DefaultAppPool"
   ```
````

2. Stop the application pool

   ```powershell
   Stop-IISAppPool -Name "DefaultAppPool"
   ```

3. Start the application pool
   ```powershell
   Start-IISAppPool -Name "DefaultAppPool"
   ```

````

### 2. Execute the Runbook

```powershell
# Execute all steps
Invoke-Runbook -FilePath 'runbooks\iis\restart-apppool.md'

# Or use the alias
runbook 'runbooks\iis\restart-apppool.md'
````

## Features

### Execute Runbooks

```powershell
# Execute a runbook
Invoke-Runbook -FilePath 'runbooks\restart-service.md'

# Dry run (show commands without executing)
Invoke-Runbook -FilePath 'runbooks\restart-service.md' -DryRun

# Resume from last failed step
Invoke-Runbook -FilePath 'runbooks\restart-service.md' -Resume

# Start from specific step
Invoke-Runbook -FilePath 'runbooks\restart-service.md' -FromStep 3

# Show all steps without executing
Invoke-Runbook -FilePath 'runbooks\restart-service.md' -ShowSteps
```

### List and Search Runbooks

```powershell
# List all runbooks
Get-RunbookList

# List runbooks in a specific category
Get-RunbookList -Category 'iis'

# Search runbooks by name
Search-Runbook -Query 'restart'

# Search runbooks by content
Search-Runbook -Query 'Get-Service' -SearchContent

# Show formatted index
Show-RunbookIndex
```

### State Management

```powershell
# Get saved state for a runbook
Get-RunbookState -FilePath 'runbooks\restart-service.md'

# Clear saved state
Clear-RunbookState -FilePath 'runbooks\restart-service.md'
```

## Runbook Format

Runbooks are standard Markdown files with PowerShell code blocks:

````markdown
# Title of the Runbook

Brief description of what this runbook does.

## Steps

1. First step description
   ```powershell
   Write-Host "Step 1"
   ```
````

2. Second step description
   ```powershell
   Get-Process | Select-Object -First 5
   ```

## Verification

Optional verification steps.

````

### Step Syntax

Steps are fenced code blocks with `powershell` or `pwsh` language tag:

- ` ```powershell ` - PowerShell code
- ` ```pwsh ` - PowerShell Core code

Other code blocks (Python, YAML, etc.) are ignored during execution.

## Error Handling

When a step fails, the tool stops and prompts for action:

````

[!] Step 3 failed with exit code 1
Error: Something went wrong

[DID NOT EXPECT THIS] Stopping. Options:
[s] Skip this step and continue
[f] Force continue (ignore failures)
[a] Abort execution

>

````

Options:
- **s** - Skip this step and continue with the next
- **f** - Force continue (ignore all future failures)
- **a** - Abort execution immediately

## State Persistence

Execution state is automatically saved to `%APPDATA%\runbook\state\<runbook-name>.json`:

```json
{
  "runbook": "restart-service.md",
  "current_step": 3,
  "last_run": "2025-01-20T10:30:00",
  "success": false
}
````

This allows you to resume from where you left off using `-Resume`.

## Directory Structure

```
runbook-automation/
├── runbook.psd1          # Module manifest
├── runbook.psm1          # Module script
├── public/               # Exported functions
│   ├── Invoke-Runbook.ps1
│   ├── Get-RunbookList.ps1
│   └── Search-Runbook.ps1
├── private/              # Internal functions
│   ├── Parse-MarkdownSteps.ps1
│   ├── Invoke-Step.ps1
│   └── Save-RunbookState.ps1
├── runbooks/             # Sample runbooks
│   ├── iis/
│   ├── services/
│   ├── networking/
│   └── infrastructure/
└── tests/                # Pester tests
    └── runbook.Tests.ps1
```

## Testing

Run the Pester test suite:

```powershell
cd 03-runbook-automation/windows
Invoke-Pester tests/ -Output Detailed
```

## Sample Runbooks

The module includes sample runbooks for common Windows tasks:

- **IIS** - Application pool restart, website management
- **Services** - Windows service restart and configuration
- **Networking** - Connectivity checks, DNS resolution
- **Infrastructure** - Event log clearing, disk cleanup

## Known Limitations

1. **Execution Policy** — May need `Set-ExecutionPolicy RemoteSigned` or `RemoteSigned`
2. **Administrator Privileges** — Some runbooks require elevated PowerShell
3. **Interactive Steps** — Cannot handle interactive prompts in code blocks
4. **PowerShell Only** — Only PowerShell/pwsh code blocks are executed

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please ensure:

1. Code follows PowerShell best practices
2. All tests pass (`Invoke-Pester tests/`)
3. Documentation is updated for new features
4. Sample runbooks are provided for new functionality

## See Also

- macOS/Linux version available in `03-runbook-automation/macos/`
