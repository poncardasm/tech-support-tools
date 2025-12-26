<#
.SYNOPSIS
    Get the top processes by CPU and RAM usage

.DESCRIPTION
    Retrieves running processes, groups them by name to consolidate duplicate instances,
    and returns the top N processes sorted by CPU or RAM usage. This is useful for
    identifying resource-intensive applications during troubleshooting or performance analysis.

.PARAMETER TopCount
    Number of top processes to return. Default is 10.

.PARAMETER SortBy
    Sort results by 'CPU' or 'RAM'. Default is 'CPU'.

.PARAMETER ExportPath
    Optional path to export results as CSV file. If not specified, results are displayed in console only.

.PARAMETER Quiet
    Suppresses the interactive banner and runs silently. Useful for scripting and automation.

.EXAMPLE
    Get-TopProcesses
    Returns top 10 processes sorted by CPU usage

.EXAMPLE
    Get-TopProcesses -TopCount 5 -SortBy RAM
    Returns top 5 processes sorted by RAM usage

.EXAMPLE
    Get-TopProcesses -TopCount 20 -SortBy CPU -Verbose
    Returns top 20 processes sorted by CPU with verbose output

.EXAMPLE
    Get-TopProcesses -TopCount 15 -ExportPath "C:\Reports\processes.csv"
    Returns top 15 processes and exports to CSV file

.NOTES
    Author: Mchael Poncardas (m@poncardas.com)
    Version: 1.1
    Last Updated: 2025-12-26
    Requires: PowerShell 5.1 or later
    Required Modules: None
    Requires Administrator: No

.LINK
    https://github.com/poncardasm/tech-support-tools
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$TopCount = 10,

    [Parameter()]
    [ValidateSet('CPU', 'RAM')]
    [string]$SortBy = 'CPU',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ExportPath,

    [Parameter()]
    [switch]$Quiet
)

# Display banner (unless -Quiet is specified)
if (-not $Quiet) {
    Write-Host ""
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "|                          TOP PROCESSES MONITOR                              |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "| About        : Retrieves running processes and displays the top N by CPU    |"
    Write-Host "|                or RAM usage for performance analysis and troubleshooting.   |"
    Write-Host "| Author       : Mchael Poncardas                                             |"
    Write-Host "| Email        : m@poncardas.com                                              |"
    Write-Host "| Version      : 1.1                                                          |"
    Write-Host "| Last Updated : 2025-12-26                                                   |"
    Write-Host "| Requires     : PowerShell 5.1 or later                                      |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host ""
    Read-Host -Prompt "Press 'Enter' key to run Top Processes Monitor"
}

try {
    Write-Verbose "Starting process analysis..."
    Write-Verbose "Parameters: TopCount=$TopCount, SortBy=$SortBy"

    # Get all running processes
    # Group by name to consolidate multiple instances of the same process
    Write-Verbose "Retrieving process information..."
    $processes = Get-Process -ErrorAction Stop

    Write-Verbose "Grouping processes by name and calculating resource usage..."
    $results = $processes | Group-Object -Property Name | ForEach-Object {
        # Calculate total CPU time for all instances of this process
        $totalCpu = ($_.Group | Measure-Object CPU -Sum).Sum

        # Calculate total RAM (WorkingSet) for all instances of this process
        $totalRam = ($_.Group | Measure-Object WorkingSet -Sum).Sum

        [PSCustomObject]@{
            Name      = $_.Name
            'CPU(s)'  = [math]::Round($totalCpu, 2)
            'RAM (MB)' = [math]::Round($totalRam / 1MB, 2)
        }
    }

    # Sort by the specified property and get top N results
    Write-Verbose "Sorting by $SortBy and selecting top $TopCount processes..."
    $sortProperty = if ($SortBy -eq 'CPU') { 'CPU(s)' } else { 'RAM (MB)' }
    $topProcesses = $results | Sort-Object $sortProperty -Descending | Select-Object -First $TopCount

    Write-Verbose "Found $($topProcesses.Count) processes"

    # Export to CSV if path specified
    if ($ExportPath) {
        Write-Verbose "Exporting results to: $ExportPath"
        $topProcesses | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Information "Results exported to: $ExportPath"
    }

    # Return results to pipeline
    $topProcesses
}
catch {
    Write-Error "Failed to retrieve process information: $_"
    exit 1
}
