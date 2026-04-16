# JSON Formatter (implicit - just uses ConvertTo-Json)
# This module provides a consistent interface for JSON output

function Format-Json {
    <#
    .SYNOPSIS
        Formats diagnostic report as JSON with consistent settings.
    .PARAMETER Report
        The diagnostic report hashtable.
    .PARAMETER Depth
        The maximum depth for JSON serialization (default: 10).
    .OUTPUTS
        String containing formatted JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Report,

        [int]$Depth = 10
    )

    # ConvertTo-Json handles the actual formatting
    # This function exists to provide a consistent interface
    # matching the other formatters
    return $Report | ConvertTo-Json -Depth $Depth
}
