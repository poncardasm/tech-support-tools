function Write-ProvisionOutput {
    <#
    .SYNOPSIS
        Writes formatted output messages with standardized prefixes.
    .DESCRIPTION
        Outputs messages with [OK], [FAIL], [TEMP], or [WARN] prefixes
        for consistent CLI feedback.
    .PARAMETER Type
        The type of message: OK, FAIL, TEMP, or WARN
    .PARAMETER Message
        The message text to display
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('OK', 'FAIL', 'TEMP', 'WARN')]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    $prefix = switch ($Type) {
        'OK'   { '[OK]   ' }
        'FAIL' { '[FAIL] ' }
        'TEMP' { '[TEMP] ' }
        'WARN' { '[WARN] ' }
    }
    
    $color = switch ($Type) {
        'OK'   { 'Green' }
        'FAIL' { 'Red' }
        'TEMP' { 'Yellow' }
        'WARN' { 'DarkYellow' }
    }
    
    Write-Host "$prefix$Message" -ForegroundColor $color
}
