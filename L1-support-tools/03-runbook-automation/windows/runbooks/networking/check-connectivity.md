# Check Network Connectivity

Run network connectivity tests and diagnostics.

## Steps

1. Check network adapter status
   ```powershell
   Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | 
       Select-Object Name, InterfaceDescription, LinkSpeed
   ```

2. Test localhost connectivity
   ```powershell
   Test-Connection -ComputerName "localhost" -Count 1 | 
       Select-Object Address, Status, Latency
   ```

3. Test DNS resolution
   ```powershell
   Resolve-DnsName -Name "google.com" -Type A | 
       Select-Object -First 1 | 
       Select-Object Name, IPAddress
   ```

4. Test external connectivity
   ```powershell
   $result = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction SilentlyContinue
   if ($result) {
       Write-Host "External connectivity OK (Average: $([math]::Round(($result | Measure-Object -Property ResponseTime -Average).Average, 1))ms)" -ForegroundColor Green
   } else {
       Write-Warning "External connectivity test failed"
   }
   ```

5. Display routing table
   ```powershell
   Get-NetRoute -DestinationPrefix "0.0.0.0/0" | 
       Select-Object DestinationPrefix, NextHop, InterfaceAlias
   ```

## Verification

All tests should complete without errors.

## Notes

- Tests require network access
- Some tests may fail in isolated environments
- DNS resolution test requires DNS server access
