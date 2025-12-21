# PowerShell Tech Support Script Development Rules

## Core Principles

1. **Security First**: Never include hardcoded credentials, API keys, or sensitive data
2. **Safety First**: Always implement safeguards for destructive operations
3. **Professional Quality**: Code should be production-ready, not just functional
4. **Documentation**: Every script must be self-documenting and include help

## Script Structure Standards

### File Naming

- Use PascalCase with verb-noun pattern: `Get-SystemHealth.ps1`, `Reset-UserPassword.ps1`
- Use approved PowerShell verbs only (check with `Get-Verb`)
- Be descriptive: avoid abbreviations unless universally understood

### Script Header (Mandatory)

Every script MUST start with:

```powershell
<#
.SYNOPSIS
    Brief one-line description of what the script does

.DESCRIPTION
    Detailed explanation of functionality, use cases, and behavior

.PARAMETER ParameterName
    Description of what this parameter does and expected values

.EXAMPLE
    Script-Name -Parameter "Value"
    Explanation of what this example demonstrates

.EXAMPLE
    Script-Name -Parameter "Value" -Verbose
    Another example showing different usage

.NOTES
    Author: Mchael Poncardas
    Version: 1.0.0
    Last Updated: YYYY-MM-DD
    Requires: PowerShell 5.1 or later
    Required Modules: (list if any)
    Requires Administrator: Yes/No

.LINK
    https://github.com/poncardasm/tech-support-tools
#>
```

## Code Quality Standards

### Error Handling (Required)

```powershell
# Always wrap risky operations in try-catch
try {
    # Operation code
}
catch {
    Write-Error "Descriptive error message: $_"
    # Clean up or rollback if needed
    exit 1
}
```

### Input Validation (Required)

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName,

    [Parameter()]
    [ValidateRange(1,65535)]
    [int]$Port = 80,

    [Parameter()]
    [ValidateSet('Start','Stop','Restart')]
    [string]$Action = 'Start'
)
```

### Required Parameters

- Use `[CmdletBinding()]` for all scripts
- Add `SupportsShouldProcess` for scripts that make changes
- Validate all inputs appropriately
- Provide sensible default values where appropriate

## Security Requirements

### ✅ Always Do

- Use `Get-Credential` for authentication (never hardcode passwords)
- Implement least privilege - check if admin rights are actually needed
- Validate and sanitize all user inputs
- Use secure string for sensitive data: `[SecureString]`
- Log security-relevant actions
- Use `-WhatIf` and `-Confirm` for destructive operations

### ❌ Never Do

- Hardcode passwords, API keys, or tokens
- Store credentials in plain text
- Execute commands from unvalidated user input
- Disable security features without explicit user consent
- Use `Invoke-Expression` with user-supplied data
- Suppress all errors with `-ErrorAction SilentlyContinue` globally

### Credential Handling Example

```powershell
# Good
$Credential = Get-Credential -Message "Enter domain admin credentials"
Get-ADUser -Filter * -Credential $Credential

# Bad - NEVER DO THIS
$Password = "P@ssw0rd123"
$Username = "admin"
```

## Safety Practices

### Destructive Operations

For any script that deletes, modifies, or stops services:

```powershell
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(...)

if ($PSCmdlet.ShouldProcess($Target, $Operation)) {
    # Perform the action
}
```

### Require Administrator Check

```powershell
#Requires -RunAsAdministrator

# Or check programmatically:
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrator privileges"
    exit 1
}
```

### Backup Before Modifying

For registry changes, file modifications, or configuration updates:

```powershell
# Create backup before making changes
$BackupPath = "C:\Backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $OriginalPath $BackupPath -Recurse
```

## Output and Logging Standards

### Use Proper Output Streams

```powershell
Write-Verbose "Detailed operation information"  # Use -Verbose to see
Write-Debug "Debug information"                 # Use -Debug to see
Write-Information "Informational message"       # General info
Write-Warning "Non-critical warning"            # Warnings
Write-Error "Error occurred"                    # Errors
Write-Output $Results                           # Actual output data
```

### Return Objects, Not Text

```powershell
# Good - returns structured data
[PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    FreeSpaceGB = $FreeSpace
    Status = 'Healthy'
}

# Bad - returns formatted text
"Computer: $env:COMPUTERNAME, Free: $FreeSpace GB"
```

### Optional Export Functionality

```powershell
param(
    [Parameter()]
    [string]$ExportPath
)

$Results = Get-YourData

if ($ExportPath) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Information "Results exported to: $ExportPath"
}

$Results  # Return to pipeline
```

## Performance Best Practices

### Use Built-in Cmdlets

```powershell
# Good
Get-ChildItem -Path C:\Temp -Recurse

# Bad
cmd /c dir C:\Temp /s
```

### Filter Left, Format Right

```powershell
# Good - filtering happens early
Get-Process | Where-Object {$_.CPU -gt 100} | Select-Object Name, CPU

# Bad - processes everything first
Get-Process | Select-Object Name, CPU | Where-Object {$_.CPU -gt 100}
```

### Avoid Aliases in Scripts

```powershell
# Good
Get-ChildItem
Remove-Item

# Bad (only use aliases interactively)
gci
rm
```

## Documentation Requirements

### Inline Comments

- Explain WHY, not WHAT (code shows what)
- Document complex logic or workarounds
- Reference sources for non-obvious solutions

```powershell
# Check if service exists before attempting restart
# Prevents error when service is not installed
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Restart-Service -Name $ServiceName
}
```

### Function Documentation

```powershell
function Get-SystemHealth {
    <#
    .SYNOPSIS
        Checks system health metrics

    .DESCRIPTION
        Collects CPU, memory, disk, and service status
        Returns structured object for reporting

    .EXAMPLE
        Get-SystemHealth

    .EXAMPLE
        Get-SystemHealth | Export-Csv health.csv
    #>
    [CmdletBinding()]
    param()

    # Function code
}
```

## Testing Requirements

### Test in Safe Environment First

- Use VMs or test machines
- Take snapshots before testing destructive scripts
- Test with different Windows versions
- Test with both admin and standard user accounts

### Test Cases to Cover

- ✅ Valid inputs (happy path)
- ✅ Invalid inputs (error handling)
- ✅ Edge cases (empty results, maximum values)
- ✅ No parameters (defaults work correctly)
- ✅ With `-Verbose` and `-Debug` flags
- ✅ With `-WhatIf` (for scripts that modify system)

### Include Test Examples in Documentation

```powershell
<#
.EXAMPLE
    Test-Connection -ComputerName "localhost"
    Tests connection to local machine

.EXAMPLE
    Test-Connection -ComputerName "offline-pc"
    Demonstrates error handling for unreachable computer
#>
```

## Version Control Standards

### Semantic Versioning

- **1.0.0**: Initial release
- **1.0.1**: Bug fixes
- **1.1.0**: New features (backward compatible)
- **2.0.0**: Breaking changes

### Update Version in Script Header

```powershell
.NOTES
    Version: 1.2.0
    Last Updated: 2024-12-19
    Changelog:
        1.2.0 - Added export to JSON functionality
        1.1.0 - Added remote computer support
        1.0.0 - Initial release
```

## Script Organization Patterns

### Single Responsibility

Each script should do ONE thing well

### Modular Functions

```powershell
function Get-DiskSpace {
    # Reusable function
}

function Test-ServiceHealth {
    # Another reusable function
}

# Main script logic
$DiskInfo = Get-DiskSpace
$ServiceInfo = Test-ServiceHealth
```

### Parameters Over Hardcoding

```powershell
# Good
param([string]$LogPath = "C:\Logs")

# Bad
$LogPath = "C:\Logs"  # Hardcoded
```

## Accessibility and Usability

### Clear Error Messages

```powershell
# Good
Write-Error "Cannot connect to $ComputerName. Verify the computer is online and network is reachable."

# Bad
Write-Error "Error occurred"
```

### Progress Indication

For long-running operations:

```powershell
Write-Progress -Activity "Scanning computers" -Status "Processing $ComputerName" -PercentComplete (($i / $Total) * 100)
```

### Helpful Verbose Output

```powershell
Write-Verbose "Connecting to $ComputerName..."
Write-Verbose "Retrieved 150 results"
Write-Verbose "Filtering results by date..."
```

## Code Style Guidelines

### Formatting

- Use 4 spaces for indentation (not tabs)
- Opening brace on same line for functions/statements
- One statement per line
- Use blank lines to separate logical blocks

### Naming Conventions

- **Functions**: PascalCase with Verb-Noun (`Get-SystemInfo`)
- **Variables**: camelCase (`$computerName`, `$resultList`)
- **Parameters**: PascalCase (`$ComputerName`, `$ExportPath`)
- **Constants**: UPPERCASE (`$MAX_RETRIES`)

### Example

```powershell
function Get-ServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop

        [PSCustomObject]@{
            Name = $service.Name
            Status = $service.Status
            StartType = $service.StartType
        }
    }
    catch {
        Write-Error "Failed to retrieve service '$ServiceName': $_"
    }
}
```

## Final Checklist

Before considering a script complete, verify:

- [ ] Comment-based help is complete and accurate
- [ ] All parameters are validated
- [ ] Error handling is implemented with try-catch
- [ ] `-WhatIf` and `-Confirm` support for changes
- [ ] No hardcoded credentials or sensitive data
- [ ] Administrator requirement is checked if needed
- [ ] Returns objects (not formatted text)
- [ ] Includes usage examples in help
- [ ] Verbose output for troubleshooting
- [ ] Tested in clean environment
- [ ] Version number updated
- [ ] Code follows style guidelines
- [ ] No aliases used in script code
- [ ] Clear error messages
- [ ] README.md documentation exists

## Resources

- [PowerShell Best Practices](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Approved Verbs](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [PowerShell Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
