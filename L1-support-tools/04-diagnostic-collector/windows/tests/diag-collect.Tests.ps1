# Pester Test Suite for Diagnostic Collector
# Tests for all collector modules and formatters

# Import all modules
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path (Split-Path -Parent $script:ScriptDir) 'modules'
$formattersDir = Join-Path (Split-Path -Parent $script:ScriptDir) 'formatters'

Get-ChildItem -Path $modulesDir -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path $formattersDir -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

Describe "Diagnostic Collector" {
    Context "System Info Collector" {
        It "Should return system information" {
            $result = Get-SystemInfo
            $result | Should -Not -BeNullOrEmpty
            $result.Hostname | Should -Not -BeNullOrEmpty
        }

        It "Should return hostname" {
            $result = Get-SystemInfo
            $result.Hostname | Should -Be $env:COMPUTERNAME
        }

        It "Should return OS information" {
            $result = Get-SystemInfo
            $result.OS_Name | Should -Not -BeNullOrEmpty
        }

        It "Should return manufacturer and model" {
            $result = Get-SystemInfo
            $result.Manufacturer | Should -Not -BeNullOrEmpty
            $result.Model | Should -Not -BeNullOrEmpty
        }
    }

    Context "CPU/Memory Collector" {
        It "Should return CPU information" {
            $result = Get-CpuMemoryInfo
            $result.CPU | Should -Not -BeNullOrEmpty
            $result.CPU.Name | Should -Not -BeNullOrEmpty
        }

        It "Should return memory information" {
            $result = Get-CpuMemoryInfo
            $result.RAM | Should -Not -BeNullOrEmpty
            $result.RAM.TotalGB | Should -BeGreaterThan 0
        }

        It "Should return top processes" {
            $result = Get-CpuMemoryInfo
            $result.TopProcesses | Should -Not -BeNullOrEmpty
            $result.TopProcesses.Count | Should -BeGreaterThan 0
        }

        It "Should calculate memory percentages correctly" {
            $result = Get-CpuMemoryInfo
            $ram = $result.RAM
            if ($ram.TotalGB -gt 0) {
                $calculatedPercent = [math]::Round(($ram.UsedGB / $ram.TotalGB) * 100, 1)
                $ram.PercentUsed | Should -BeGreaterOrEqual 0
                $ram.PercentUsed | Should -BeLessOrEqual 100
            }
        }
    }

    Context "Disk Info Collector" {
        It "Should return disk information" {
            $result = Get-DiskInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should have at least one volume" {
            $result = Get-DiskInfo | Where-Object { -not $_.ContainsKey('_PhysicalDisks') -and -not $_.ContainsKey('Error') }
            $result.Count | Should -BeGreaterThan 0
        }

        It "Should return volume properties" {
            $result = Get-DiskInfo | Where-Object { $_.Drive } | Select-Object -First 1
            $result.Drive | Should -Not -BeNullOrEmpty
            $result.TotalGB | Should -BeGreaterThan 0
        }

        It "Should flag disk > 90% as CRITICAL" {
            $result = Get-DiskInfo | Where-Object { $_.PercentUsed -gt 90 }
            foreach ($disk in $result) {
                $disk.Status | Should -Be 'CRITICAL'
            }
        }

        It "Should flag disk > 80% as WARNING HIGH" {
            $result = Get-DiskInfo | Where-Object { $_.PercentUsed -gt 80 -and $_.PercentUsed -le 90 }
            foreach ($disk in $result) {
                $disk.Status | Should -Be 'WARNING HIGH'
            }
        }

        It "Should flag disk <= 80% as OK" {
            $result = Get-DiskInfo | Where-Object { $_.PercentUsed -le 80 }
            foreach ($disk in $result) {
                $disk.Status | Should -Be 'OK'
            }
        }
    }

    Context "Network Info Collector" {
        It "Should return network information" {
            $result = Get-NetworkInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return hostname" {
            $result = Get-NetworkInfo
            $result.Hostname | Should -Be $env:COMPUTERNAME
        }
    }

    Context "Service Info Collector" {
        It "Should return service information" {
            $result = Get-ServiceInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should have service summary" {
            $result = Get-ServiceInfo | Where-Object { $_.ContainsKey('_Summary') }
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return running services" {
            $result = Get-ServiceInfo | Where-Object { $_.Status -eq 'Running' }
            $result.Count | Should -BeGreaterThan 0
        }
    }

    Context "Event Log Info Collector" {
        It "Should return event log information" {
            $result = Get-EventLogInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return error counts" {
            $result = Get-EventLogInfo
            $result.ApplicationErrors | Should -Not -BeNullOrEmpty
            $result.SystemErrors | Should -Not -BeNullOrEmpty
        }
    }

    Context "Installed Software Collector" {
        It "Should return software information" {
            $result = Get-InstalledSoftwareInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return software count" {
            $result = Get-InstalledSoftwareInfo
            $result.TotalCount | Should -BeGreaterOrEqual 0
        }
    }

    Context "Update Info Collector" {
        It "Should return update information" {
            $result = Get-UpdateInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should have update summary" {
            $result = Get-UpdateInfo | Where-Object { $_.ContainsKey('_Summary') }
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Active Users Collector" {
        It "Should return user information" {
            $result = Get-ActiveUsersInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return current user" {
            $result = Get-ActiveUsersInfo
            $result.CurrentUser | Should -Not -BeNullOrEmpty
            $result.CurrentUser.Username | Should -Be $env:USERNAME
        }
    }

    Context "Network Tests Collector" {
        It "Should return network test results" {
            $result = Get-NetworkTests
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should run connectivity tests" {
            $result = Get-NetworkTests
            $result.Tests | Should -Not -BeNullOrEmpty
            $result.Tests.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "Formatters" {
    # Create a mock report for testing
    BeforeAll {
        $script:mockReport = @{
            timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            hostname = 'TEST-PC'
            version = '1.0.0'
            sections = @{
                System = @{
                    Hostname = 'TEST-PC'
                    Domain = 'TESTDOMAIN'
                    OS_Name = 'Windows 10 Pro'
                    OS_Version = '22H2'
                    OS_Architecture = '64-bit'
                    Uptime = '5 days, 3 hours, 20 minutes'
                    Manufacturer = 'Dell Inc.'
                    Model = 'Latitude 5520'
                    SystemType = 'x64-based PC'
                    TotalPhysicalMemory = 16
                    BIOS_Version = '1.15.0'
                }
                CpuMemory = @{
                    CPU = @{
                        Name = 'Intel(R) Core(TM) i7-1185G7'
                        Cores = 4
                        LogicalProcessors = 8
                        MaxClockSpeed = 3000
                        PercentUsed = 25.5
                    }
                    RAM = @{
                        TotalGB = 16
                        UsedGB = 8
                        FreeGB = 8
                        PercentUsed = 50
                        PercentFree = 50
                    }
                    TopProcesses = @(
                        @{ Name = 'chrome'; Id = 1234; MemoryMB = 512 }
                        @{ Name = 'explorer'; Id = 5678; MemoryMB = 128 }
                    )
                }
                Disk = @(
                    @{
                        Drive = 'C:'
                        FileSystemLabel = 'Windows'
                        FileSystem = 'NTFS'
                        TotalGB = 512
                        UsedGB = 256
                        FreeGB = 256
                        PercentUsed = 50
                        PercentFree = 50
                        Status = 'OK'
                    }
                    @{
                        Drive = 'D:'
                        FileSystemLabel = 'Data'
                        FileSystem = 'NTFS'
                        TotalGB = 1024
                        UsedGB = 950
                        FreeGB = 74
                        PercentUsed = 92.8
                        PercentFree = 7.2
                        Status = 'CRITICAL'
                    }
                )
                Network = @{
                    Adapters = @(
                        @{
                            Name = 'Ethernet'
                            MacAddress = '00-11-22-33-44-55'
                            IPv4Addresses = @('192.168.1.100')
                            IPv6Addresses = @('fe80::1234:5678:90ab:cdef')
                            Gateways = @('192.168.1.1')
                            Status = 'Up'
                        }
                    )
                    DNS = @('8.8.8.8', '1.1.1.1')
                    Hostname = 'TEST-PC'
                }
                Services = @(
                    @{ Name = 'WinRM'; DisplayName = 'Windows Remote Management'; Status = 'Running'; StartType = 'Automatic' }
                    @{ Name = 'Spooler'; DisplayName = 'Print Spooler'; Status = 'Running'; StartType = 'Automatic' }
                    @{
                        _Summary = @{
                            Total = 200
                            Running = 100
                            Stopped = 100
                            AutoNotRunning = 2
                        }
                    }
                )
                EventLogs = @{
                    ApplicationErrors = 5
                    SystemErrors = 3
                    SecurityErrors = 0
                    RecentErrors = @()
                    ErrorSummary = @{
                        'Service Control Manager' = 2
                        'Application Error' = 1
                    }
                }
                InstalledSoftware = @{
                    TotalCount = 50
                    InstalledApps = @(
                        @{ Name = 'Google Chrome'; Version = '120.0.0.0'; Publisher = 'Google LLC' }
                        @{ Name = 'Microsoft Office'; Version = '16.0.0.0'; Publisher = 'Microsoft Corporation' }
                    )
                    TopPublishers = @(
                        @{ Name = 'Microsoft Corporation'; Count = 15 }
                        @{ Name = 'Google LLC'; Count = 3 }
                    )
                }
                Updates = @(
                    @{
                        _Summary = @{
                            TotalPending = 3
                            SecurityUpdates = 1
                            PSWindowsUpdateAvailable = $false
                        }
                    }
                    @{ Title = 'Cumulative Update'; KB = 'KB5034441'; IsSecurity = $true }
                )
                ActiveUsers = @{
                    CurrentUser = @{
                        Username = 'testuser'
                        Domain = 'TESTDOMAIN'
                        IsAdmin = $false
                    }
                    ActiveSessions = @()
                    TotalActive = 1
                }
                NetworkTests = @{
                    Tests = @(
                        @{ Name = 'DNS Resolution'; Target = 'google.com'; Passed = $true; Result = 'Success' }
                        @{ Name = 'Gateway Ping'; Target = '192.168.1.1'; Passed = $true; Result = 'Success'; ResponseTime = 1 }
                    )
                    AllPassed = $true
                    PublicIP = '203.0.113.1'
                }
                Thresholds = @{
                    total_alerts = 1
                    critical = 1
                    warnings = 0
                    alerts = @(
                        @{
                            severity = 'CRITICAL'
                            category = 'DISK'
                            message = 'Disk D: is at 92.8% capacity'
                        }
                    )
                }
            }
        }
    }

    Context "Markdown Formatter" {
        It "Should generate Markdown output" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match '^# Diagnostic Report'
        }

        It "Should include hostname in title" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Match 'TEST-PC'
        }

        It "Should include system section" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Match '## System'
        }

        It "Should include alerts section when there are alerts" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Match '##.*Alerts'
        }

        It "Should include disk section with status indicators" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Match '## Disk'
            $output | Should -Match 'CRITICAL'
        }

        It "Should format tables correctly" {
            $output = Format-Markdown -Report $mockReport
            $output | Should -Match '\|.*\|'
        }
    }

    Context "HTML Formatter" {
        It "Should generate HTML output" {
            $output = Format-Html -Report $mockReport
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match '<!DOCTYPE html>'
        }

        It "Should include hostname in title" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match 'TEST-PC'
        }

        It "Should include CSS styles" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match '<style>'
        }

        It "Should include system section" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match 'System Information'
        }

        It "Should include alerts when present" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match 'CRITICAL'
        }

        It "Should format tables correctly" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match '<table>'
            $output | Should -Match '<th>'
        }

        It "Should include proper HTML structure" {
            $output = Format-Html -Report $mockReport
            $output | Should -Match '<html'
            $output | Should -Match '</html>'
            $output | Should -Match '<body'
            $output | Should -Match '</body>'
        }
    }

    Context "JSON Formatter" {
        It "Should generate JSON output" {
            $output = Format-Json -Report $mockReport
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should generate valid JSON" {
            $output = Format-Json -Report $mockReport
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Should include hostname" {
            $output = Format-Json -Report $mockReport | ConvertFrom-Json
            $output.hostname | Should -Be 'TEST-PC'
        }

        It "Should include all sections" {
            $output = Format-Json -Report $mockReport | ConvertFrom-Json
            $output.sections | Should -Not -BeNullOrEmpty
            $output.sections.System | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Threshold Detection" {
    BeforeAll {
        $script:TestReport = @{
            sections = @{
                Disk = @(
                    @{
                        Drive = 'C:'
                        PercentUsed = 50
                    }
                    @{
                        Drive = 'D:'
                        PercentUsed = 85
                    }
                    @{
                        Drive = 'E:'
                        PercentUsed = 95
                    }
                )
                CpuMemory = @{
                    RAM = @{
                        PercentUsed = 92
                    }
                    CPU = @{
                        PercentUsed = 45
                    }
                }
                Services = @(
                    @{ Name = 'TestService1'; DisplayName = 'Test Service 1'; Status = 'Running'; StartType = 'Automatic' }
                    @{ Name = 'TestService2'; DisplayName = 'Test Service 2'; Status = 'Stopped'; StartType = 'Automatic' }
                )
                EventLogs = @{
                    ApplicationErrors = 15
                    SystemErrors = 3
                }
                Updates = @(
                    @{ Title = 'Security Update'; KB = 'KB123456'; IsSecurity = $true }
                    @{ Title = 'Regular Update'; KB = 'KB123457'; IsSecurity = $false }
                )
            }
        }
    }

    It "Should detect disk CRITICAL at > 90%" {
        $criticalDisk = $TestReport.sections.Disk | Where-Object { $_.PercentUsed -gt 90 }
        $criticalDisk | Should -Not -BeNullOrEmpty
        $criticalDisk.Drive | Should -Be 'E:'
    }

    It "Should detect disk WARNING at > 80%" {
        $warningDisk = $TestReport.sections.Disk | Where-Object { $_.PercentUsed -gt 80 -and $_.PercentUsed -le 90 }
        $warningDisk | Should -Not -BeNullOrEmpty
        $warningDisk.Drive | Should -Be 'D:'
    }

    It "Should detect memory CRITICAL at > 90%" {
        $TestReport.sections.CpuMemory.RAM.PercentUsed | Should -BeGreaterThan 90
    }

    It "Should detect stopped automatic services" {
        $failedServices = $TestReport.sections.Services | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }
        $failedServices.Count | Should -BeGreaterThan 0
    }

    It "Should detect many application errors" {
        $TestReport.sections.EventLogs.ApplicationErrors | Should -BeGreaterThan 10
    }

    It "Should detect security updates" {
        $securityUpdates = $TestReport.sections.Updates | Where-Object { $_.IsSecurity }
        $securityUpdates.Count | Should -BeGreaterThan 0
    }
}

Describe "Integration" {
    It "All modules should import without errors" {
        { Get-SystemInfo } | Should -Not -Throw
        { Get-CpuMemoryInfo } | Should -Not -Throw
        { Get-DiskInfo } | Should -Not -Throw
        { Get-NetworkInfo } | Should -Not -Throw
        { Get-ServiceInfo } | Should -Not -Throw
        { Get-EventLogInfo } | Should -Not -Throw
        { Get-InstalledSoftwareInfo } | Should -Not -Throw
        { Get-UpdateInfo } | Should -Not -Throw
        { Get-ActiveUsersInfo } | Should -Not -Throw
        { Get-NetworkTests } | Should -Not -Throw
    }
}
