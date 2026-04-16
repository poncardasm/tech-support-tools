# HTML Formatter
# Formats diagnostic report as self-contained HTML

function Format-Html {
    <#
    .SYNOPSIS
        Formats diagnostic report as self-contained HTML.
    .PARAMETER Report
        The diagnostic report hashtable.
    .OUTPUTS
        String containing formatted HTML.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Report
    )

    # CSS styles
    $css = @'
<style>
    * {
        box-sizing: border-box;
    }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
        line-height: 1.6;
        color: #333;
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
        background: #f5f5f5;
    }
    .container {
        background: white;
        border-radius: 8px;
        padding: 30px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    h1 {
        color: #2c3e50;
        border-bottom: 3px solid #3498db;
        padding-bottom: 10px;
        margin-top: 0;
    }
    h2 {
        color: #34495e;
        border-bottom: 2px solid #ecf0f1;
        padding-bottom: 8px;
        margin-top: 30px;
    }
    h3 {
        color: #7f8c8d;
        margin-top: 25px;
    }
    .meta {
        color: #7f8c8d;
        font-size: 0.9em;
        margin-bottom: 20px;
    }
    .alert-critical {
        background: #fee;
        border-left: 4px solid #e74c3c;
        padding: 15px;
        margin: 10px 0;
        border-radius: 4px;
    }
    .alert-warning {
        background: #fff8e1;
        border-left: 4px solid #f39c12;
        padding: 15px;
        margin: 10px 0;
        border-radius: 4px;
    }
    .alert-success {
        background: #e8f5e9;
        border-left: 4px solid #27ae60;
        padding: 15px;
        margin: 10px 0;
        border-radius: 4px;
    }
    .alert-title {
        font-weight: bold;
        margin-bottom: 10px;
    }
    .alert-critical .alert-title {
        color: #c0392b;
    }
    .alert-warning .alert-title {
        color: #d68910;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin: 15px 0;
        font-size: 0.9em;
    }
    th, td {
        text-align: left;
        padding: 12px;
        border-bottom: 1px solid #ecf0f1;
    }
    th {
        background: #34495e;
        color: white;
        font-weight: 600;
    }
    tr:hover {
        background: #f8f9fa;
    }
    .status-ok {
        color: #27ae60;
        font-weight: 600;
    }
    .status-warning {
        color: #f39c12;
        font-weight: 600;
    }
    .status-critical {
        color: #e74c3c;
        font-weight: 600;
    }
    .metric {
        display: inline-block;
        background: #ecf0f1;
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 0.85em;
        margin: 2px;
    }
    .metric-highlight {
        background: #3498db;
        color: white;
    }
    .footer {
        margin-top: 40px;
        padding-top: 20px;
        border-top: 1px solid #ecf0f1;
        color: #95a5a6;
        font-size: 0.85em;
        text-align: center;
    }
    .grid-2 {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 20px;
    }
    @media (max-width: 768px) {
        .grid-2 {
            grid-template-columns: 1fr;
        }
        body {
            padding: 10px;
        }
        .container {
            padding: 15px;
        }
    }
</style>
'@

    $sb = New-Object System.Text.StringBuilder

    [void]$sb.AppendLine('<!DOCTYPE html>')
    [void]$sb.AppendLine('<html lang="en">')
    [void]$sb.AppendLine('<head>')
    [void]$sb.AppendLine('    <meta charset="UTF-8">')
    [void]$sb.AppendLine('    <meta name="viewport" content="width=device-width, initial-scale=1.0">')
    [void]$sb.AppendLine("    <title>Diagnostic Report - $($Report.hostname)</title>")
    [void]$sb.AppendLine($css)
    [void]$sb.AppendLine('</head>')
    [void]$sb.AppendLine('<body>')
    [void]$sb.AppendLine('<div class="container">')

    # Header
    [void]$sb.AppendLine("<h1>Diagnostic Report - $($Report.hostname)</h1>")
    [void]$sb.AppendLine('<div class="meta">')
    [void]$sb.AppendLine("<strong>Collected:</strong> $($Report.timestamp)<br>")
    [void]$sb.AppendLine("<strong>Diagnostic Collector v$($Report.version)</strong>")
    [void]$sb.AppendLine('</div>')

    # Alerts Section
    $thresholds = $Report.sections.Thresholds
    if ($thresholds.total_alerts -gt 0) {
        if ($thresholds.critical -gt 0) {
            [void]$sb.AppendLine('<div class="alert-critical">')
            [void]$sb.AppendLine("<div class='alert-title'>⚠️ CRITICAL: $($thresholds.critical) issue(s) detected</div>")
            [void]$sb.AppendLine('</div>')
        }
        if ($thresholds.warnings -gt 0) {
            [void]$sb.AppendLine('<div class="alert-warning">')
            [void]$sb.AppendLine("<div class='alert-title'>⚠️ Warnings: $($thresholds.warnings)</div>")
            [void]$sb.AppendLine('</div>')
        }

        [void]$sb.AppendLine('<h2>Alerts</h2>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Severity</th><th>Category</th><th>Message</th></tr>')
        foreach ($alert in $thresholds.alerts) {
            $cssClass = if ($alert.severity -eq 'CRITICAL') { 'status-critical' } else { 'status-warning' }
            [void]$sb.AppendLine("<tr><td class='$cssClass'>$($alert.severity)</td><td>$($alert.category)</td><td>$($alert.message)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }
    else {
        [void]$sb.AppendLine('<div class="alert-success">')
        [void]$sb.AppendLine("<div class='alert-title'>✅ System Status: No threshold alerts detected</div>")
        [void]$sb.AppendLine('System appears healthy.')
        [void]$sb.AppendLine('</div>')
    }

    # System Section
    $system = $Report.sections.System
    [void]$sb.AppendLine('<h2>System Information</h2>')
    [void]$sb.AppendLine('<table>')
    [void]$sb.AppendLine('<tr><th>Property</th><th>Value</th></tr>')
    [void]$sb.AppendLine("<tr><td>Hostname</td><td>$($system.Hostname)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Domain</td><td>$($system.Domain)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Operating System</td><td>$($system.OS_Name) $($system.OS_Version)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Architecture</td><td>$($system.OS_Architecture)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Uptime</td><td>$($system.Uptime)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Manufacturer</td><td>$($system.Manufacturer)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Model</td><td>$($system.Model)</td></tr>")
    [void]$sb.AppendLine("<tr><td>System Type</td><td>$($system.SystemType)</td></tr>")
    [void]$sb.AppendLine("<tr><td>Total Memory</td><td>$($system.TotalPhysicalMemory) GB</td></tr>")
    [void]$sb.AppendLine("<tr><td>BIOS Version</td><td>$($system.BIOS_Version)</td></tr>")
    [void]$sb.AppendLine('</table>')

    # CPU / Memory Section
    $cpuMemory = $Report.sections.CpuMemory
    [void]$sb.AppendLine('<h2>CPU / Memory</h2>')

    if ($cpuMemory.CPU.Name) {
        $cpu = $cpuMemory.CPU
        [void]$sb.AppendLine('<h3>CPU</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Property</th><th>Value</th></tr>')
        [void]$sb.AppendLine("<tr><td>Processor</td><td>$($cpu.Name)</td></tr>")
        [void]$sb.AppendLine("<tr><td>Cores / Threads</td><td>$($cpu.Cores) / $($cpu.LogicalProcessors)</td></tr>")
        [void]$sb.AppendLine("<tr><td>Max Clock Speed</td><td>$($cpu.MaxClockSpeed) MHz</td></tr>")
        if ($cpu.PercentUsed) {
            $usageClass = if ($cpu.PercentUsed -gt 90) { 'status-critical' } elseif ($cpu.PercentUsed -gt 80) { 'status-warning' } else { 'status-ok' }
            [void]$sb.AppendLine("<tr><td>Current Usage</td><td class='$usageClass'>$($cpu.PercentUsed)%</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    if ($cpuMemory.RAM.TotalGB) {
        $ram = $cpuMemory.RAM
        [void]$sb.AppendLine('<h3>Memory</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Property</th><th>Value</th></tr>')
        [void]$sb.AppendLine("<tr><td>Total</td><td>$($ram.TotalGB) GB</td></tr>")
        $usedClass = if ($ram.PercentUsed -gt 90) { 'status-critical' } elseif ($ram.PercentUsed -gt 80) { 'status-warning' } else { 'status-ok' }
        [void]$sb.AppendLine("<tr><td>Used</td><td class='$usedClass'>$($ram.UsedGB) GB ($($ram.PercentUsed)%)</td></tr>")
        [void]$sb.AppendLine("<tr><td>Free</td><td>$($ram.FreeGB) GB ($($ram.PercentFree)%)</td></tr>")
        [void]$sb.AppendLine('</table>')
    }

    if ($cpuMemory.TopProcesses.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Top Processes (by Memory)</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Process</th><th>PID</th><th>Memory</th></tr>')
        foreach ($proc in $cpuMemory.TopProcesses | Select-Object -First 5) {
            [void]$sb.AppendLine("<tr><td>$($proc.Name)</td><td>$($proc.Id)</td><td>$($proc.MemoryMB) MB</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Disk Section
    $disks = $Report.sections.Disk | Where-Object { -not $_.ContainsKey('_PhysicalDisks') }
    [void]$sb.AppendLine('<h2>Disk</h2>')
    [void]$sb.AppendLine('<table>')
    [void]$sb.AppendLine('<tr><th>Drive</th><th>Label</th><th>Filesystem</th><th>Total</th><th>Used</th><th>Free</th><th>Usage</th><th>Status</th></tr>')

    foreach ($disk in $disks) {
        $statusClass = switch ($disk.Status) {
            'OK' { 'status-ok' }
            'WARNING HIGH' { 'status-warning' }
            'CRITICAL' { 'status-critical' }
            default { '' }
        }
        [void]$sb.AppendLine("<tr><td>$($disk.Drive)</td><td>$($disk.FileSystemLabel)</td><td>$($disk.FileSystem)</td><td>$($disk.TotalGB) GB</td><td>$($disk.UsedGB) GB</td><td>$($disk.FreeGB) GB</td><td>$($disk.PercentUsed)%</td><td class='$statusClass'>$($disk.Status)</td></tr>")
    }
    [void]$sb.AppendLine('</table>')

    # Network Section
    $network = $Report.sections.Network
    [void]$sb.AppendLine('<h2>Network</h2>')

    if ($network.Adapters.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Network Adapters</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Name</th><th>MAC</th><th>IPv4</th><th>IPv6</th><th>Gateway</th><th>Status</th></tr>')

        foreach ($adapter in $network.Adapters) {
            $ipv4 = ($adapter.IPv4Addresses -join ', ')
            $ipv6 = ($adapter.IPv6Addresses -join ', ')
            if ($ipv6.Length -gt 30) { $ipv6 = $ipv6.Substring(0, 30) + '...' }
            $gateway = ($adapter.Gateways -join ', ')
            [void]$sb.AppendLine("<tr><td>$($adapter.Name)</td><td>$($adapter.MacAddress)</td><td>$ipv4</td><td>$ipv6</td><td>$gateway</td><td>$($adapter.Status)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    if ($network.DNS.Count -gt 0) {
        [void]$sb.AppendLine('<h3>DNS Servers</h3>')
        [void]$sb.AppendLine('<ul>')
        foreach ($dns in $network.DNS) {
            [void]$sb.AppendLine("<li>$dns</li>")
        }
        [void]$sb.AppendLine('</ul>')
    }

    # Services Section
    $services = $Report.sections.Services | Where-Object { -not $_.ContainsKey('_Summary') }
    $serviceSummary = ($Report.sections.Services | Where-Object { $_.ContainsKey('_Summary') })._Summary

    [void]$sb.AppendLine('<h2>Services</h2>')
    if ($serviceSummary) {
        [void]$sb.AppendLine('<p>')
        [void]$sb.AppendLine("<span class='metric'>Total: $($serviceSummary.Total)</span>")
        [void]$sb.AppendLine("<span class='metric metric-highlight'>Running: $($serviceSummary.Running)</span>")
        [void]$sb.AppendLine("<span class='metric'>Stopped: $($serviceSummary.Stopped)</span>")
        if ($serviceSummary.AutoNotRunning -gt 0) {
            [void]$sb.AppendLine("<span class='metric status-critical'>Auto services stopped: $($serviceSummary.AutoNotRunning)</span>")
        }
        [void]$sb.AppendLine('</p>')
    }

    $runningServices = $services | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 10
    if ($runningServices.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Running Services (sample)</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Name</th><th>Display Name</th><th>Start Type</th></tr>')
        foreach ($svc in $runningServices) {
            [void]$sb.AppendLine("<tr><td>$($svc.Name)</td><td>$($svc.DisplayName)</td><td>$($svc.StartType)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Event Logs Section
    $eventLogs = $Report.sections.EventLogs
    [void]$sb.AppendLine('<h2>Event Logs (Last 24h)</h2>')
    [void]$sb.AppendLine('<ul>')
    [void]$sb.AppendLine("<li><strong>Application Errors:</strong> $($eventLogs.ApplicationErrors)</li>")
    [void]$sb.AppendLine("<li><strong>System Errors:</strong> $($eventLogs.SystemErrors)</li>")
    if ($eventLogs.SecurityErrors -ge 0) {
        [void]$sb.AppendLine("<li><strong>Security Errors:</strong> $($eventLogs.SecurityErrors)</li>")
    }
    [void]$sb.AppendLine('</ul>')

    if ($eventLogs.ErrorSummary.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Error Summary by Source</h3>')
        [void]$sb.AppendLine('<ul>')
        foreach ($source in $eventLogs.ErrorSummary.GetEnumerator() | Sort-Object Value -Descending) {
            [void]$sb.AppendLine("<li><strong>$($source.Name):</strong> $($source.Value) error(s)</li>")
        }
        [void]$sb.AppendLine('</ul>')
    }

    if ($eventLogs.RecentErrors.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Recent Errors</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Time</th><th>Log</th><th>Level</th><th>ID</th><th>Source</th><th>Message</th></tr>')
        foreach ($err in $eventLogs.RecentErrors | Select-Object -First 10) {
            $msg = $err.Message.Substring(0, [Math]::Min(40, $err.Message.Length))
            [void]$sb.AppendLine("<tr><td>$($err.TimeCreated)</td><td>$($err.LogName)</td><td>$($err.LevelDisplayName)</td><td>$($err.Id)</td><td>$($err.ProviderName)</td><td>$msg...</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Installed Software Section
    $software = $Report.sections.InstalledSoftware
    [void]$sb.AppendLine('<h2>Installed Software</h2>')
    [void]$sb.AppendLine("<p><strong>Total Applications:</strong> $($software.TotalCount)</p>")

    if ($software.TopPublishers.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Top Publishers</h3>')
        [void]$sb.AppendLine('<ul>')
        foreach ($pub in $software.TopPublishers | Select-Object -First 5) {
            [void]$sb.AppendLine("<li><strong>$($pub.Name):</strong> $($pub.Count) app(s)</li>")
        }
        [void]$sb.AppendLine('</ul>')
    }

    $sampleApps = $software.InstalledApps | Select-Object -First 10
    if ($sampleApps.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Sample Applications</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Name</th><th>Version</th><th>Publisher</th></tr>')
        foreach ($app in $sampleApps) {
            [void]$sb.AppendLine("<tr><td>$($app.Name)</td><td>$($app.Version)</td><td>$($app.Publisher)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Updates Section
    $updates = $Report.sections.Updates | Where-Object { -not $_.ContainsKey('_Summary') }
    $updateSummary = ($Report.sections.Updates | Where-Object { $_.ContainsKey('_Summary') })._Summary

    [void]$sb.AppendLine('<h2>Windows Updates</h2>')
    if ($updateSummary) {
        [void]$sb.AppendLine("<p><strong>Pending Updates:</strong> $($updateSummary.TotalPending)</p>")
        if ($updateSummary.SecurityUpdates -gt 0) {
            [void]$sb.AppendLine("<p class='status-warning'><strong>Security Updates:</strong> $($updateSummary.SecurityUpdates)</p>")
        }
    }

    if ($updates.Count -gt 0) {
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Title</th><th>KB</th><th>Security</th><th>Size</th></tr>')
        foreach ($update in $updates | Select-Object -First 10) {
            $isSec = if ($update.IsSecurity) { '🔒 Yes' } else { 'No' }
            $title = $update.Title
            if ($title.Length -gt 40) { $title = $title.Substring(0, 40) + '...' }
            [void]$sb.AppendLine("<tr><td>$title</td><td>$($update.KB)</td><td>$isSec</td><td>$($update.Size) MB</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Active Users Section
    $users = $Report.sections.ActiveUsers
    [void]$sb.AppendLine('<h2>Active Users</h2>')

    if ($users.CurrentUser) {
        [void]$sb.AppendLine('<ul>')
        [void]$sb.AppendLine("<li><strong>Current User:</strong> $($users.CurrentUser.Domain)\$($users.CurrentUser.Username)</li>")
        if ($users.CurrentUser.IsAdmin) {
            [void]$sb.AppendLine("<li><strong>Admin Status:</strong> ✅ Administrator</li>")
        }
        else {
            [void]$sb.AppendLine("<li><strong>Admin Status:</strong> ❌ Standard User</li>")
        }
        [void]$sb.AppendLine('</ul>')
    }

    if ($users.ActiveSessions.Count -gt 0) {
        [void]$sb.AppendLine('<h3>Active Sessions</h3>')
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Username</th><th>Session</th><th>State</th><th>Idle Time</th><th>Logon Time</th></tr>')
        foreach ($session in $users.ActiveSessions | Select-Object -First 10) {
            $activeMarker = if ($session.IsActive) { '▶ ' } else { '' }
            [void]$sb.AppendLine("<tr><td>$activeMarker$($session.Username)</td><td>$($session.SessionName)</td><td>$($session.State)</td><td>$($session.IdleTime)</td><td>$($session.LogonTime)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    # Network Tests Section
    $tests = $Report.sections.NetworkTests
    [void]$sb.AppendLine('<h2>Network Connectivity Tests</h2>')

    $allPassed = $tests.AllPassed
    if ($allPassed) {
        [void]$sb.AppendLine('<div class="alert-success">✅ <strong>All connectivity tests passed</strong></div>')
    }
    else {
        [void]$sb.AppendLine('<div class="alert-critical">❌ <strong>Some connectivity tests failed</strong></div>')
    }

    if ($tests.Tests.Count -gt 0) {
        [void]$sb.AppendLine('<table>')
        [void]$sb.AppendLine('<tr><th>Test</th><th>Target</th><th>Status</th><th>Result</th></tr>')
        foreach ($test in $tests.Tests) {
            $statusIcon = if ($test.Passed) { '✅' } else { '❌' }
            [void]$sb.AppendLine("<tr><td>$($test.Name)</td><td>$($test.Target)</td><td>$statusIcon</td><td>$($test.Result)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }

    if ($tests.PublicIP) {
        [void]$sb.AppendLine("<p><strong>Public IP:</strong> $($tests.PublicIP)</p>")
    }

    # Footer
    [void]$sb.AppendLine('<div class="footer">')
    [void]$sb.AppendLine("<p>Generated by Diagnostic Collector v$($Report.version)</p>")
    [void]$sb.AppendLine('</div>')

    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</body>')
    [void]$sb.AppendLine('</html>')

    return $sb.ToString()
}
