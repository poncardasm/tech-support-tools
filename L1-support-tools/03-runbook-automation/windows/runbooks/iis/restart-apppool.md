# Restart IIS Application Pool

Restart an IIS application pool safely with verification steps.

## Steps

1. Check current status
   ```powershell
   Get-IISAppPool -Name "DefaultAppPool" | Select-Object Name, State
   ```

2. Stop the application pool
   ```powershell
   Stop-IISAppPool -Name "DefaultAppPool"
   ```

3. Wait briefly to ensure shutdown
   ```powershell
   Start-Sleep -Seconds 2
   ```

4. Verify it stopped
   ```powershell
   $pool = Get-IISAppPool -Name "DefaultAppPool"
   if ($pool.State -ne 'Stopped') {
       throw "Application pool did not stop successfully"
   }
   Write-Host "Application pool stopped successfully"
   ```

5. Start the application pool
   ```powershell
   Start-IISAppPool -Name "DefaultAppPool"
   ```

6. Confirm restart
   ```powershell
   $pool = Get-IISAppPool -Name "DefaultAppPool"
   if ($pool.State -eq 'Started') {
       Write-Host "SUCCESS: Application pool is running" -ForegroundColor Green
   } else {
       throw "Application pool failed to start"
   }
   ```

## Verification

All steps must return exit code 0. The final step confirms the application pool is in "Started" state.

## Notes

- Requires IIS Administration module
- Run as Administrator if managing system app pools
- Will fail if the application pool doesn't exist
