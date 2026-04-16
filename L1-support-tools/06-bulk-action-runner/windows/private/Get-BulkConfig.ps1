<#
.SYNOPSIS
    Gets the configuration path for bulk-action-runner.

.DESCRIPTION
    Returns the path to the configuration directory where credentials
    and settings are stored.

.EXAMPLE
    $configPath = Get-BulkConfig
#>
function Get-BulkConfig {
    [CmdletBinding()]
    param()
    
    $configDir = Join-Path $env:APPDATA 'bulk-action'
    
    if (-not (Test-Path -Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    return $configDir
}
