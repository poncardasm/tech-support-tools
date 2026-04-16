<#
.SYNOPSIS
    Delays execution for a specified time.

.DESCRIPTION
    Throttles operations by sleeping for the specified milliseconds.
    Default is 500ms to avoid EntraID rate limits.

.PARAMETER Milliseconds
    Number of milliseconds to sleep.

.EXAMPLE
    Start-Throttle -Milliseconds 500
#>
function Start-Throttle {
    [CmdletBinding()]
    param(
        [int]$Milliseconds = 500
    )
    
    Write-Verbose "Throttling for $Milliseconds ms"
    Start-Sleep -Milliseconds $Milliseconds
}
