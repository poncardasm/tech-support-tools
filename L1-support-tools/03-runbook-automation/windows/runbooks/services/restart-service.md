# Restart Windows Service

Safely restart a Windows service with status verification.

## Prerequisites

- Administrative privileges may be required
- Service name must be valid

## Steps

1. Check if service exists
   ```powershell
   $serviceName = "Spooler"
   $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
   if (-not $service) {
       throw "Service '$serviceName' not found"
   }
   Write-Host "Found service: $($service.DisplayName)"
   ```

2. Check initial status
   ```powershell
   Get-Service -Name $serviceName | Select-Object Name, Status
   ```

3. Stop the service
   ```powershell
   Stop-Service -Name $serviceName -Force
   ```

4. Verify service stopped
   ```powershell
   $service = Get-Service -Name $serviceName
   if ($service.Status -ne 'Stopped') {
       throw "Service failed to stop. Current status: $($service.Status)"
   }
   Write-Host "Service stopped successfully"
   ```

5. Start the service
   ```powershell
   Start-Service -Name $serviceName
   ```

6. Verify service started
   ```powershell
   $service = Get-Service -Name $serviceName
   if ($service.Status -eq 'Running') {
       Write-Host "SUCCESS: Service is running" -ForegroundColor Green
   } else {
       throw "Service failed to start. Current status: $($service.Status)"
   }
   ```

## Verification

Service should be in "Running" status at completion.

## Common Services

- `Spooler` - Print Spooler
- `w3svc` - World Wide Web Publishing Service
- `BITS` - Background Intelligent Transfer Service
- `MpsSvc` - Windows Defender Firewall
