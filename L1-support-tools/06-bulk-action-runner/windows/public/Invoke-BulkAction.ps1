<#
.SYNOPSIS
    Main entry point for bulk action operations.

.DESCRIPTION
    CLI-style entry point for bulk operations on users from CSV files.
    Supports password-reset, add-group, enable-mailbox, and deprovision operations.

.PARAMETER Operation
    The operation to perform: password-reset, add-group, enable-mailbox, deprovision.

.PARAMETER CsvPath
    Path to the CSV file containing user emails.

.PARAMETER Group
    Group name (required for add-group operation).

.PARAMETER Reason
    Reason for deprovisioning (optional for deprovision operation).

.PARAMETER ReportPath
    Path to save a CSV report of results.

.EXAMPLE
    bulk-run password-reset users.csv
    bulk-run add-group users.csv -Group "IT-All"
    bulk-run enable-mailbox users.csv
    bulk-run deprovision users.csv -Reason "terminated"
    bulk-run password-reset users.csv -WhatIf
    bulk-run add-group users.csv -Group "IT-All" -ReportPath results.csv
#>
function Invoke-BulkAction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('password-reset', 'add-group', 'enable-mailbox', 'deprovision')]
        [string]$Operation,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$CsvPath,
        
        [Parameter()]
        [string]$Group,
        
        [Parameter()]
        [string]$Reason,
        
        [Parameter()]
        [Alias('Report')]
        [string]$ReportPath
    )
    
    # Validate parameters based on operation
    switch ($Operation) {
        'add-group' {
            if ([string]::IsNullOrWhiteSpace($Group)) {
                throw "Parameter -Group is required for 'add-group' operation"
            }
        }
    }
    
    # Resolve CSV path
    $resolvedPath = Resolve-Path -Path $CsvPath -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        throw "CSV file not found: $CsvPath"
    }
    
    Write-Host ""
    Write-Host "=== Bulk Action Runner ===" -ForegroundColor Cyan
    Write-Host "Operation: $Operation" -ForegroundColor Cyan
    Write-Host "CSV: $($resolvedPath.Path)" -ForegroundColor Cyan
    if ($Group) { Write-Host "Group: $Group" -ForegroundColor Cyan }
    if ($Reason) { Write-Host "Reason: $Reason" -ForegroundColor Cyan }
    if ($WhatIfPreference) { Write-Host "Mode: Dry-run (WhatIf)" -ForegroundColor Yellow }
    Write-Host ""
    
    # Route to appropriate function
    switch ($Operation) {
        'password-reset' {
            return Invoke-BulkPasswordReset -CsvPath $resolvedPath.Path -ReportPath $ReportPath
        }
        'add-group' {
            return Invoke-BulkAddGroup -CsvPath $resolvedPath.Path -Group $Group -ReportPath $ReportPath
        }
        'enable-mailbox' {
            return Invoke-BulkEnableMailbox -CsvPath $resolvedPath.Path -ReportPath $ReportPath
        }
        'deprovision' {
            return Invoke-BulkDeprovision -CsvPath $resolvedPath.Path -Reason $Reason -ReportPath $ReportPath
        }
    }
}

# Create alias for CLI-style usage
Set-Alias -Name 'bulk-run' -Value 'Invoke-BulkAction' -Scope Script
