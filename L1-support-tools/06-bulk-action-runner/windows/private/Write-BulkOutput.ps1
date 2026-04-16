<#
.SYNOPSIS
    Writes formatted output for bulk operations.

.DESCRIPTION
    Writes colored output with status prefixes for bulk operation results.

.PARAMETER Type
    Status type: OK, FAIL, or WARN.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-BulkOutput -Type OK -Message "User processed successfully"
#>
function Write-BulkOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('OK', 'FAIL', 'WARN')]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    $prefix = switch ($Type) {
        'OK'   { '[OK]   ' }
        'FAIL' { '[FAIL] ' }
        'WARN' { '[WARN] ' }
    }
    
    $color = switch ($Type) {
        'OK'   { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
    }
    
    Write-Host "$prefix$Message" -ForegroundColor $color
}
