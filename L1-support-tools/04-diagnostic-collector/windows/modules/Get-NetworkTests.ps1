# Network Tests Collector
# Performs basic network connectivity tests

function Get-NetworkTests {
    <#
    .SYNOPSIS
        Performs basic network connectivity tests.
    .OUTPUTS
        Hashtable containing test results.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        Tests = @()
        AllPassed = $true
    }

    # Test DNS resolution
    $dnsTest = @{
        Name = 'DNS Resolution (google.com)'
        Target = 'google.com'
        Type = 'DNS'
        Passed = $false
        Result = ''
        ResponseTime = 0
    }

    try {
        $dnsResult = Resolve-DnsName -Name 'google.com' -Type A -ErrorAction Stop -QuickTimeout
        $dnsTest.Passed = $true
        $dnsTest.Result = "Resolved to $($dnsResult[0].IPAddress)"
    }
    catch {
        $dnsTest.Passed = $false
        $dnsTest.Result = "Failed: $_"
        $result.AllPassed = $false
    }
    $result.Tests += $dnsTest

    # Test gateway ping
    try {
        $gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | 
            Select-Object -First 1

        if ($gateway) {
            $gatewayTest = @{
                Name = 'Gateway Ping'
                Target = $gateway.NextHop
                Type = 'Ping'
                Passed = $false
                Result = ''
                ResponseTime = 0
            }

            try {
                $pingResult = Test-Connection -ComputerName $gateway.NextHop -Count 1 -ErrorAction Stop
                $gatewayTest.Passed = $true
                $gatewayTest.ResponseTime = $pingResult.ResponseTime
                $gatewayTest.Result = "Success (RTT: $($pingResult.ResponseTime)ms)"
            }
            catch {
                $gatewayTest.Passed = $false
                $gatewayTest.Result = "Failed: $_"
                $result.AllPassed = $false
            }
            $result.Tests += $gatewayTest
        }
    }
    catch {
        # Gateway test failed
    }

    # Test internet connectivity (ping 8.8.8.8)
    $internetTest = @{
        Name = 'Internet Connectivity (8.8.8.8)'
        Target = '8.8.8.8'
        Type = 'Ping'
        Passed = $false
        Result = ''
        ResponseTime = 0
    }

    try {
        $pingResult = Test-Connection -ComputerName '8.8.8.8' -Count 1 -ErrorAction Stop
        $internetTest.Passed = $true
        $internetTest.ResponseTime = $pingResult.ResponseTime
        $internetTest.Result = "Success (RTT: $($pingResult.ResponseTime)ms)"
    }
    catch {
        $internetTest.Passed = $false
        $internetTest.Result = "Failed: $_"
        $result.AllPassed = $false
    }
    $result.Tests += $internetTest

    # Test HTTPS connectivity
    $httpsTest = @{
        Name = 'HTTPS Connectivity (google.com:443)'
        Target = 'google.com'
        Type = 'HTTPS'
        Passed = $false
        Result = ''
        ResponseTime = 0
    }

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $request = [System.Net.WebRequest]::Create('https://google.com')
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $sw.Stop()
        $response.Close()
        $httpsTest.Passed = $true
        $httpsTest.ResponseTime = $sw.ElapsedMilliseconds
        $httpsTest.Result = "Success (RTT: $($sw.ElapsedMilliseconds)ms)"
    }
    catch {
        $httpsTest.Passed = $false
        $httpsTest.Result = "Failed: $_"
        $result.AllPassed = $false
    }
    $result.Tests += $httpsTest

    # Get public IP (optional)
    try {
        $publicIp = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 5 -ErrorAction SilentlyContinue
        $result.PublicIP = $publicIp.ip
    }
    catch {
        # Public IP detection optional
    }

    return $result
}
