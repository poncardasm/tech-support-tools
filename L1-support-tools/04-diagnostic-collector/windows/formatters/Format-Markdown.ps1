# Markdown Formatter
# Formats diagnostic report as Markdown

function Format-Markdown {
    <#
    .SYNOPSIS
        Formats diagnostic report as Markdown.
    .PARAMETER Report
        The diagnostic report hashtable.
    .OUTPUTS
        String containing formatted Markdown.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Report
    )

    $sb = New-Object System.Text.StringBuilder

    # Header
    [void]$sb.AppendLine("# Diagnostic Report - $($Report.hostname)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Collected:** $($Report.timestamp)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Diagnostic Collector v$($Report.version)**")
    [void]$sb.AppendLine("")

    # Summary / Alerts
    $thresholds = $Report.sections.Thresholds
    if ($thresholds.total_alerts -gt 0) {
        [void]$sb.AppendLine("## ⚠️ Alerts")
        [void]$sb.AppendLine("")

        if ($thresholds.critical -gt 0) {
            [void]$sb.AppendLine("**CRITICAL: $($thresholds.critical) issue(s) detected**")
            [void]$sb.AppendLine("")
        }

        if ($thresholds.warnings -gt 0) {
            [void]$sb.AppendLine("**Warnings: $($thresholds.warnings)**")
            [void]$sb.AppendLine("")
        }

        foreach ($alert in $thresholds.alerts) {
            $icon = if ($alert.severity -eq 'CRITICAL') { '🔴' } else { '🟡' }
            [void]$sb.AppendLine("- $icon **[$($alert.category)]** $($alert.message)")
        }
        [void]$sb.AppendLine("")
    }
    else {
        [void]$sb.AppendLine("## ✅ System Status")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("No threshold alerts detected. System appears healthy.")
        [void]$sb.AppendLine("")
    }

    # System Section
    $system = $Report.sections.System
    [void]$sb.AppendLine("## System")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Property | Value |")
    [void]$sb.AppendLine("|----------|-------|")
    [void]$sb.AppendLine("| Hostname | $($system.Hostname) |")
    [void]$sb.AppendLine("| Domain | $($system.Domain) |")
    [void]$sb.AppendLine("| OS | $($system.OS_Name) $($system.OS_Version) |")
    [void]$sb.AppendLine("| Architecture | $($system.OS_Architecture) |")
    [void]$sb.AppendLine("| Uptime | $($system.Uptime) |")
    [void]$sb.AppendLine("| Manufacturer | $($system.Manufacturer) |")
    [void]$sb.AppendLine("| Model | $($system.Model) |")
    [void]$sb.AppendLine("| System Type | $($system.SystemType) |")
    [void]$sb.AppendLine("| Total Memory | $($system.TotalPhysicalMemory) GB |")
    [void]$sb.AppendLine("| BIOS Version | $($system.BIOS_Version) |")
    [void]$sb.AppendLine("")

    # CPU / Memory Section
    $cpuMemory = $Report.sections.CpuMemory
    [void]$sb.AppendLine("## CPU / Memory")
    [void]$sb.AppendLine("")

    if ($cpuMemory.CPU.Name) {
        $cpu = $cpuMemory.CPU
        [void]$sb.AppendLine("### CPU")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("- **Processor:** $($cpu.Name)")
        [void]$sb.AppendLine("- **Cores:** $($cpu.Cores) | **Threads:** $($cpu.LogicalProcessors)")
        [void]$sb.AppendLine("- **Max Speed:** $($cpu.MaxClockSpeed) MHz")
        if ($cpu.PercentUsed) {
            [void]$sb.AppendLine("- **Current Usage:** $($cpu.PercentUsed)%")
        }
        [void]$sb.AppendLine("")
    }

    if ($cpuMemory.RAM.TotalGB) {
        $ram = $cpuMemory.RAM
        [void]$sb.AppendLine("### Memory")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("- **Total:** $($ram.TotalGB) GB")
        [void]$sb.AppendLine("- **Used:** $($ram.UsedGB) GB ($($ram.PercentUsed)%)")
        [void]$sb.AppendLine("- **Free:** $($ram.FreeGB) GB ($($ram.PercentFree)%)")
        [void]$sb.AppendLine("")
    }

    if ($cpuMemory.TopProcesses.Count -gt 0) {
        [void]$sb.AppendLine("### Top Processes (by Memory)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Process | PID | Memory |")
        [void]$sb.AppendLine("|---------|-----|--------|")
        foreach ($proc in $cpuMemory.TopProcesses | Select-Object -First 5) {
            [void]$sb.AppendLine("| $($proc.Name) | $($proc.Id) | $($proc.MemoryMB) MB |")
        }
        [void]$sb.AppendLine("")
    }

    # Disk Section
    $disks = $Report.sections.Disk | Where-Object { -not $_.ContainsKey('_PhysicalDisks') }
    [void]$sb.AppendLine("## Disk")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Drive | Label | Filesystem | Total | Used | Free | Usage | Status |")
    [void]$sb.AppendLine("|-------|-------|------------|-------|------|------|-------|--------|")

    foreach ($disk in $disks) {
        $statusIcon = switch ($disk.Status) {
            'OK' { '✅' }
            'WARNING HIGH' { '🟡' }
            'CRITICAL' { '🔴' }
            default { '⚪' }
        }
        [void]$sb.AppendLine("| $($disk.Drive) | $($disk.FileSystemLabel) | $($disk.FileSystem) | $($disk.TotalGB) GB | $($disk.UsedGB) GB | $($disk.FreeGB) GB | $($disk.PercentUsed)% | $statusIcon $($disk.Status) |")
    }
    [void]$sb.AppendLine("")

    # Network Section
    $network = $Report.sections.Network
    [void]$sb.AppendLine("## Network")
    [void]$sb.AppendLine("")

    if ($network.Adapters.Count -gt 0) {
        [void]$sb.AppendLine("### Network Adapters")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | MAC | IPv4 | IPv6 | Gateway | Status |")
        [void]$sb.AppendLine("|------|-----|------|------|---------|--------|")

        foreach ($adapter in $network.Adapters) {
            $ipv4 = ($adapter.IPv4Addresses -join ', ')
            $ipv6 = ($adapter.IPv6Addresses -join ', ').Substring(0, [Math]::Min(30, ($adapter.IPv6Addresses -join ', ').Length))
            $gateway = ($adapter.Gateways -join ', ')
            [void]$sb.AppendLine("| $($adapter.Name) | $($adapter.MacAddress) | $ipv4 | $ipv6... | $gateway | $($adapter.Status) |")
        }
        [void]$sb.AppendLine("")
    }

    if ($network.DNS.Count -gt 0) {
        [void]$sb.AppendLine("### DNS Servers")
        [void]$sb.AppendLine("")
        foreach ($dns in $network.DNS) {
            [void]$sb.AppendLine("- $dns")
        }
        [void]$sb.AppendLine("")
    }

    # Services Section
    $services = $Report.sections.Services | Where-Object { -not $_.ContainsKey('_Summary') }
    $serviceSummary = ($Report.sections.Services | Where-Object { $_.ContainsKey('_Summary') })._Summary

    [void]$sb.AppendLine("## Services")
    [void]$sb.AppendLine("")
    if ($serviceSummary) {
        [void]$sb.AppendLine("- **Total:** $($serviceSummary.Total)")
        [void]$sb.AppendLine("- **Running:** $($serviceSummary.Running)")
        [void]$sb.AppendLine("- **Stopped:** $($serviceSummary.Stopped)")
        if ($serviceSummary.AutoNotRunning -gt 0) {
            [void]$sb.AppendLine("- **Auto services stopped:** ⚠️ $($serviceSummary.AutoNotRunning)")
        }
        [void]$sb.AppendLine("")
    }

    $runningServices = $services | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 10
    if ($runningServices.Count -gt 0) {
        [void]$sb.AppendLine("### Running Services (sample)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Display Name | Start Type |")
        [void]$sb.AppendLine("|------|--------------|------------|")
        foreach ($svc in $runningServices) {
            [void]$sb.AppendLine("| $($svc.Name) | $($svc.DisplayName) | $($svc.StartType) |")
        }
        [void]$sb.AppendLine("")
    }

    # Event Logs Section
    $eventLogs = $Report.sections.EventLogs
    [void]$sb.AppendLine("## Event Logs (Last 24h)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Application Errors:** $($eventLogs.ApplicationErrors)")
    [void]$sb.AppendLine("- **System Errors:** $($eventLogs.SystemErrors)")
    if ($eventLogs.SecurityErrors -ge 0) {
        [void]$sb.AppendLine("- **Security Errors:** $($eventLogs.SecurityErrors)")
    }
    [void]$sb.AppendLine("")

    if ($eventLogs.ErrorSummary.Count -gt 0) {
        [void]$sb.AppendLine("### Error Summary by Source")
        [void]$sb.AppendLine("")
        foreach ($source in $eventLogs.ErrorSummary.GetEnumerator() | Sort-Object Value -Descending) {
            [void]$sb.AppendLine("- **$($source.Name):** $($source.Value) error(s)")
        }
        [void]$sb.AppendLine("")
    }

    if ($eventLogs.RecentErrors.Count -gt 0) {
        [void]$sb.AppendLine("### Recent Errors")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Time | Log | Level | ID | Source | Message |")
        [void]$sb.AppendLine("|------|-----|-------|----|--------|---------|")
        foreach ($err in $eventLogs.RecentErrors | Select-Object -First 10) {
            $msg = $err.Message.Substring(0, [Math]::Min(40, $err.Message.Length))
            [void]$sb.AppendLine("| $($err.TimeCreated) | $($err.LogName) | $($err.LevelDisplayName) | $($err.Id) | $($err.ProviderName) | $msg... |")
        }
        [void]$sb.AppendLine("")
    }

    # Installed Software Section
    $software = $Report.sections.InstalledSoftware
    [void]$sb.AppendLine("## Installed Software")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Total Applications:** $($software.TotalCount)")
    [void]$sb.AppendLine("")

    if ($software.TopPublishers.Count -gt 0) {
        [void]$sb.AppendLine("### Top Publishers")
        [void]$sb.AppendLine("")
        foreach ($pub in $software.TopPublishers | Select-Object -First 5) {
            [void]$sb.AppendLine("- **$($pub.Name):** $($pub.Count) app(s)")
        }
        [void]$sb.AppendLine("")
    }

    $sampleApps = $software.InstalledApps | Select-Object -First 10
    if ($sampleApps.Count -gt 0) {
        [void]$sb.AppendLine("### Sample Applications")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Version | Publisher |")
        [void]$sb.AppendLine("|------|---------|-----------|")
        foreach ($app in $sampleApps) {
            [void]$sb.AppendLine("| $($app.Name) | $($app.Version) | $($app.Publisher) |")
        }
        [void]$sb.AppendLine("")
    }

    # Updates Section
    $updates = $Report.sections.Updates | Where-Object { -not $_.ContainsKey('_Summary') }
    $updateSummary = ($Report.sections.Updates | Where-Object { $_.ContainsKey('_Summary') })._Summary

    [void]$sb.AppendLine("## Windows Updates")
    [void]$sb.AppendLine("")

    if ($updateSummary) {
        [void]$sb.AppendLine("- **Pending Updates:** $($updateSummary.TotalPending)")
        if ($updateSummary.SecurityUpdates -gt 0) {
            [void]$sb.AppendLine("- **Security Updates:** ⚠️ $($updateSummary.SecurityUpdates)")
        }
        [void]$sb.AppendLine("")
    }

    if ($updates.Count -gt 0) {
        [void]$sb.AppendLine("| Title | KB | Security | Size |")
        [void]$sb.AppendLine("|-------|-----|----------|------|")
        foreach ($update in $updates | Select-Object -First 10) {
            $isSec = if ($update.IsSecurity) { '🔒 Yes' } else { 'No' }
            [void]$sb.AppendLine("| $($update.Title.Substring(0, [Math]::Min(40, $update.Title.Length)))... | $($update.KB) | $isSec | $($update.Size) MB |")
        }
        [void]$sb.AppendLine("")
    }

    # Active Users Section
    $users = $Report.sections.ActiveUsers
    [void]$sb.AppendLine("## Active Users")
    [void]$sb.AppendLine("")

    if ($users.CurrentUser) {
        [void]$sb.AppendLine("- **Current User:** $($users.CurrentUser.Domain)\$($users.CurrentUser.Username)")
        if ($users.CurrentUser.IsAdmin) {
            [void]$sb.AppendLine("- **Admin Status:** ✅ Administrator")
        }
        else {
            [void]$sb.AppendLine("- **Admin Status:** ❌ Standard User")
        }
        [void]$sb.AppendLine("")
    }

    if ($users.ActiveSessions.Count -gt 0) {
        [void]$sb.AppendLine("### Active Sessions")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Username | Session | State | Idle Time | Logon Time |")
        [void]$sb.AppendLine("|----------|---------|-------|-----------|------------|")
        foreach ($session in $users.ActiveSessions | Select-Object -First 10) {
            $activeMarker = if ($session.IsActive) { '▶ ' } else { '' }
            [void]$sb.AppendLine("| $activeMarker$($session.Username) | $($session.SessionName) | $($session.State) | $($session.IdleTime) | $($session.LogonTime) |")
        }
        [void]$sb.AppendLine("")
    }

    if ($users.UniqueUsers -and $users.UniqueUsers.Count -gt 0) {
        [void]$sb.AppendLine("### Unique Logged-on Users")
        [void]$sb.AppendLine("")
        foreach ($user in $users.UniqueUsers) {
            [void]$sb.AppendLine("- $($user.Domain)\$($user.Username) ($($user.Sessions) session(s))")
        }
        [void]$sb.AppendLine("")
    }

    # Network Tests Section
    $tests = $Report.sections.NetworkTests
    [void]$sb.AppendLine("## Network Connectivity Tests")
    [void]$sb.AppendLine("")

    $allPassed = $tests.AllPassed
    if ($allPassed) {
        [void]$sb.AppendLine("✅ **All connectivity tests passed**")
    }
    else {
        [void]$sb.AppendLine("❌ **Some connectivity tests failed**")
    }
    [void]$sb.AppendLine("")

    if ($tests.Tests.Count -gt 0) {
        [void]$sb.AppendLine("| Test | Target | Status | Result |")
        [void]$sb.AppendLine("|------|--------|--------|--------|")
        foreach ($test in $tests.Tests) {
            $statusIcon = if ($test.Passed) { '✅' } else { '❌' }
            $result = if ($test.Passed -and $test.ResponseTime) {
                "$($test.Result)"
            }
            else {
                $test.Result
            }
            [void]$sb.AppendLine("| $($test.Name) | $($test.Target) | $statusIcon | $result |")
        }
        [void]$sb.AppendLine("")
    }

    if ($tests.PublicIP) {
        [void]$sb.AppendLine("- **Public IP:** $($tests.PublicIP)")
        [void]$sb.AppendLine("")
    }

    # Footer
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("*Generated by Diagnostic Collector v$($Report.version)*")
    [void]$sb.AppendLine("")

    return $sb.ToString()
}
