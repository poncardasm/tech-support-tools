# Bulk Action Runner PowerShell Module
#Requires -Version 7.0

# Get the module directory
$ModuleDir = $PSScriptRoot

# Import private functions first
$PrivateFunctions = Get-ChildItem -Path (Join-Path $ModuleDir 'private') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    . $Function.FullName
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path $ModuleDir 'public') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    . $Function.FullName
}

# Export public functions
Export-ModuleMember -Function @(
    'Invoke-BulkPasswordReset',
    'Invoke-BulkAddGroup',
    'Invoke-BulkEnableMailbox',
    'Invoke-BulkDeprovision',
    'Invoke-BulkAction'
) -Alias @(
    'bulk-run'
)
