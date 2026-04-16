#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Diagnostic Collector for Windows - System diagnostic information gatherer for L1/L2 support handoffs.

.DESCRIPTION
    Gathers system configuration, hardware info, disk usage, network status, services,
    event logs, installed software, and Windows updates. Outputs reports in Markdown,
    HTML, or JSON format with automatic threshold detection for common issues.

.PARAMETER Html
    Output report in HTML format.

.PARAMETER Markdown
    Output report in Markdown format (default).

.PARAMETER Json
    Output report in JSON format.

.PARAMETER Host
    Custom hostname tag for the report.

.PARAMETER Upload
    Upload the report to a configured endpoint.

.EXAMPLE
    .\diag-collect.ps1
    Generates a Markdown diagnostic report to stdout.

.EXAMPLE
    .\diag-collect.ps1 -Html -Upload
    Generates an HTML report and uploads it.

.EXAMPLE
    .\diag-collect.ps1 -Json -Host "WORKSTATION-42"
    Generates JSON output tagged with custom hostname.

.NOTES
    Author: L1 Support Tools
    Version: 1.0.0
    Requires: PowerShell 5.1 or PowerShell 7+
#>

[CmdletBinding()]
param(
    [switch]$Html,
    [switch]$Markdown,
    [switch]$Json,
    [string]$Host,
    [switch]$Upload
)

# Script version
$script:Version = '1.0.0'

# Get the script directory
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $script:ScriptDir) {
    $script:ScriptDir = $PSScriptRoot
}
if (-not $script:ScriptDir) {
    $script:ScriptDir = Get-Location
}

# Import all modules
$modulesDir = Join-Path $script:ScriptDir 'modules'
if (Test-Path $modulesDir) {
    Get-ChildItem -Path $modulesDir -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# Import all formatters
$formattersDir = Join-Path $script:ScriptDir 'formatters'
if (Test-Path $formattersDir) {
    Get-ChildItem -Path $formattersDir -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# Set default output format if none specified
if (-not $Html -and -not $Markdown -and -not $Json) {
    $Markdown = $true
}

function Show-Usage {
    @"
Diagnostic Collector v$script:Version

Usage: diag-collect.ps1 [OPTIONS]

Options:
    -Html           Output report in HTML format
    -Markdown       Output report in Markdown format (default)
    -Json           Output report in JSON format
    -Host <name>    Tag report with custom hostname
    -Upload         Upload report to configured endpoint
    -Help           Show this help message

Examples:
    .\diag-collect.ps1                          # Markdown output
    .\diag-collect.ps1 -Html                     # HTML report
    .\diag-collect.ps1 -Json -Host "SERVER-01"    # JSON with custom hostname
    .\diag-collect.ps1 -Html -Upload              # Upload HTML report
"@
}

function Write-Status {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Invoke-DiagnosticCollection {
    <#
    .SYNOPSIS
        Collects all diagnostic data from the system.
    #>
    [CmdletBinding()]
    param()

    $report = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        hostname = if ($Host) { $Host } else { $env:COMPUTERNAME }
        version = $script:Version
        sections = @{}
    }

    # Collect all data sections
    Write-Status "Collecting system information..."
    $report.sections.System = Get-SystemInfo

    Write-Status "Collecting CPU and memory information..."
    $report.sections.CpuMemory = Get-CpuMemoryInfo

    Write-Status "Collecting disk information..."
    $report.sections.Disk = Get-DiskInfo

    Write-Status "Collecting network information..."
    $report.sections.Network = Get-NetworkInfo

    Write-Status "Collecting service information..."
    $report.sections.Services = Get-ServiceInfo

    Write-Status "Collecting event log information..."
    $report.sections.EventLogs = Get-EventLogInfo

    Write-Status "Collecting installed software information..."
    $report.sections.InstalledSoftware = Get-InstalledSoftwareInfo

    Write-Status "Collecting Windows Update information..."
    $report.sections.Updates = Get-UpdateInfo

    Write-Status "Collecting active user information..."
    $report.sections.ActiveUsers = Get-ActiveUsersInfo

    Write-Status "Running network connectivity tests..."
    $report.sections.NetworkTests = Get-NetworkTests

    # Apply threshold detection
    Write-Status "Analyzing thresholds..."
    $report.sections.Thresholds = Get-ThresholdStatus -Report $report

    return $report
}

function Get-ThresholdStatus {
    <#
    .SYNOPSIS
        Analyzes collected data for threshold violations.
    #>
    [CmdletBinding()]
    param([hashtable]$Report)

    $alerts = @()

    # Disk thresholds
    foreach ($disk in $Report.sections.Disk) {
        if ($disk.PercentUsed -gt 90) {
            $alerts += @{
                severity = 'CRITICAL'
                category = 'DISK'
                message = "Disk $($disk.Drive) is at $($disk.PercentUsed)% capacity"
            }
        }
        elseif ($disk.PercentUsed -gt 80) {
            $alerts += @{
                severity = 'WARNING'
                category = 'DISK'
                message = "Disk $($disk.Drive) is at $($disk.PercentUsed)% capacity"
            }
        }
    }

    # Memory thresholds
    $memory = $Report.sections.CpuMemory
    if ($memory.RAM.PercentUsed -gt 90) {
        $alerts += @{
            severity = 'CRITICAL'
            category = 'MEMORY'
            message = "Memory usage is at $($memory.RAM.PercentUsed)%"
        }
    }
    elseif ($memory.RAM.PercentUsed -gt 80) {
        $alerts += @{
            severity = 'WARNING'
            category = 'MEMORY'
            message = "Memory usage is at $($memory.RAM.PercentUsed)%"
        }
    }

    # CPU thresholds
    if ($memory.CPU.PercentUsed -gt 90) {
        $alerts += @{
            severity = 'WARNING'
            category = 'CPU'
            message = "CPU usage is at $($memory.CPU.PercentUsed)%"
        }
    }

    # Service failures
    $failedServices = $Report.sections.Services | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }
    foreach ($svc in $failedServices) {
        $alerts += @{
            severity = 'WARNING'
            category = 'SERVICE'
            message = "Service '$($svc.Name)' ($($svc.DisplayName)) is stopped but set to Automatic start"
        }
    }

    # Event log errors
    if ($Report.sections.EventLogs.ApplicationErrors -gt 10) {
        $alerts += @{
            severity = 'WARNING'
            category = 'EVENTS'
            message = "$($Report.sections.EventLogs.ApplicationErrors) application errors in last 24h"
        }
    }

    # Pending security updates
    $securityUpdates = $Report.sections.Updates | Where-Object { $_.IsSecurity }
    if ($securityUpdates.Count -gt 0) {
        $alerts += @{
            severity = 'WARNING'
            category = 'UPDATES'
            message = "$($securityUpdates.Count) security updates pending"
        }
    }

    return @{
        total_alerts = $alerts.Count
        critical = ($alerts | Where-Object { $_.severity -eq 'CRITICAL' }).Count
        warnings = ($alerts | Where-Object { $_.severity -eq 'WARNING' }).Count
        alerts = $alerts
    }
}

function Invoke-ReportUpload {
    <#
    .SYNOPSIS
        Uploads the report to a configured endpoint.
    #>
    [CmdletBinding()]
    param(
        [string]$Content,
        [string]$Format
    )

    # Get upload endpoint from environment or config
    $uploadEndpoint = $env:DIAG_COLLECT_UPLOAD_URL
    if (-not $uploadEndpoint) {
        # Default internal endpoint (to be configured)
        $uploadEndpoint = 'https://paste.internal/upload'
    }

    $headers = @{
        'Content-Type' = if ($Format -eq 'json') { 'application/json' } else { 'text/plain' }
        'X-Diagnostic-Collector' = 'true'
        'X-Hostname' = $env:COMPUTERNAME
    }

    # Add auth token if available
    $authToken = $env:DIAG_COLLECT_UPLOAD_TOKEN
    if ($authToken) {
        $headers['Authorization'] = "Bearer $authToken"
    }

    try {
        $body = @{
            content = $Content
            hostname = $env:COMPUTERNAME
            timestamp = Get-Date -Format 'o'
            format = $Format
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uploadEndpoint -Method POST -Headers $headers -Body $body -TimeoutSec 30
        return $response.url
    }
    catch {
        Write-Error "Failed to upload report: $_"
        return $null
    }
}

# Main execution
if ($PSBoundParameters.ContainsKey('Help') -or $args -contains '-Help' -or $args -contains '--help' -or $args -contains '-h' -or $args -contains '/?') {
    Show-Usage
    exit 0
}

Write-Host "`nDiagnostic Collector v$script:Version`n" -ForegroundColor Cyan
Write-Host "Collecting diagnostic information from $env:COMPUTERNAME...`n" -ForegroundColor White

try {
    $report = Invoke-DiagnosticCollection

    # Format output
    $outputFormat = 'markdown'
    if ($Json) {
        $output = ConvertTo-Json -InputObject $report -Depth 10
        $outputFormat = 'json'
    }
    elseif ($Html) {
        $output = Format-Html -Report $report
        $outputFormat = 'html'
    }
    else {
        $output = Format-Markdown -Report $report
    }

    # Output or upload
    if ($Upload) {
        Write-Status "Uploading report..."
        $url = Invoke-ReportUpload -Content $output -Format $outputFormat
        if ($url) {
            Write-Host "`nReport uploaded successfully!" -ForegroundColor Green
            Write-Host "URL: $url" -ForegroundColor Cyan
        }
        else {
            Write-Error "Upload failed. Outputting to console instead:`n"
            Write-Output $output
        }
    }
    else {
        Write-Output $output
    }

    # Summary
    Write-Host "`n--- Summary ---" -ForegroundColor Cyan
    $alerts = $report.sections.Thresholds
    if ($alerts.critical -gt 0) {
        Write-Host "CRITICAL alerts: $($alerts.critical)" -ForegroundColor Red
    }
    if ($alerts.warnings -gt 0) {
        Write-Host "Warnings: $($alerts.warnings)" -ForegroundColor Yellow
    }
    if ($alerts.total_alerts -eq 0) {
        Write-Host "No threshold alerts detected." -ForegroundColor Green
    }

    exit 0
}
catch {
    Write-Error "Diagnostic collection failed: $_"
    exit 1
}
