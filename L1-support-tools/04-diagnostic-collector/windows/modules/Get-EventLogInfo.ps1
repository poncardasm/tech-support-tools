# Event Log Information Collector
# Gathers recent errors and warnings from Windows Event Logs

function Get-EventLogInfo {
    <#
    .SYNOPSIS
        Collects recent event log errors and warnings.
    .OUTPUTS
        Hashtable containing event log summary and recent errors.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        ApplicationErrors = 0
        SystemErrors = 0
        SecurityErrors = 0
        RecentErrors = @()
        ErrorSummary = @{}
    }

    $startTime = (Get-Date).AddHours(-24)

    try {
        # Get Application log errors
        $appErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Level = 1, 2  # Critical and Error
            StartTime = $startTime
        } -MaxEvents 50 -ErrorAction SilentlyContinue

        $result.ApplicationErrors = $appErrors.Count

        # Get System log errors
        $sysErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1, 2
            StartTime = $startTime
        } -MaxEvents 50 -ErrorAction SilentlyContinue

        $result.SystemErrors = $sysErrors.Count

        # Get Security log errors (may require admin)
        try {
            $secErrors = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                Level = 1, 2
                StartTime = $startTime
            } -MaxEvents 50 -ErrorAction SilentlyContinue
            $result.SecurityErrors = $secErrors.Count
        }
        catch {
            # Security log may be inaccessible
            $result.SecurityErrors = -1  # Indicates access denied
        }

        # Combine and format recent errors (top 20)
        $allErrors = @($appErrors) + @($sysErrors) | 
            Sort-Object TimeCreated -Descending | 
            Select-Object -First 20

        $result.RecentErrors = $allErrors | ForEach-Object {
            @{
                TimeCreated = $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')
                LogName = $_.LogName
                LevelDisplayName = $_.LevelDisplayName
                Id = $_.Id
                ProviderName = $_.ProviderName
                Message = if ($_.Message) { 
                    ($_.Message -split "`n")[0]  # First line only
                } else { 'No message available' }
            }
        }

        # Summarize errors by provider
        $errorGroups = $allErrors | Group-Object -Property ProviderName | 
            Sort-Object Count -Descending | 
            Select-Object -First 5

        foreach ($group in $errorGroups) {
            $result.ErrorSummary[$group.Name] = $group.Count
        }
    }
    catch {
        Write-Warning "Failed to collect event log info: $_"
        $result.Error = "Event log collection failed: $_"
    }

    return $result
}
