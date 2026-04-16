# Runbook Automation Module
# Provides CLI functionality for managing and executing markdown-based runbooks

# Get the module root path
$script:ModuleRoot = $PSScriptRoot

# Import private functions
$privateFunctions = Get-ChildItem -Path (Join-Path $script:ModuleRoot 'private') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($function in $privateFunctions) {
    . $function.FullName
}

# Import public functions
$publicFunctions = Get-ChildItem -Path (Join-Path $script:ModuleRoot 'public') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($function in $publicFunctions) {
    . $function.FullName
}

# Export public functions
foreach ($function in $publicFunctions) {
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($function.Name)
    Export-ModuleMember -Function $functionName
}

# Export aliases
Set-Alias -Name 'runbook' -Value 'Invoke-Runbook'
Export-ModuleMember -Alias 'runbook'
