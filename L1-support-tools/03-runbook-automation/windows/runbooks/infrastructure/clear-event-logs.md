# Clear Windows Event Logs

Clear specified Windows event logs safely with backup option.

## Prerequisites

- Administrative privileges required
- Backup directory must exist if backing up

## Steps

1. Display available log sizes
   ```powershell
   Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | 
       Sort-Object -Property RecordCount -Descending | 
       Select-Object -First 10 |
       Select-Object LogName, RecordCount, @{N='SizeMB';E={[math]::Round($_.FileSize / 1MB, 2)}}
   ```

2. Backup Application log (optional)
   ```powershell
   $backupPath = Join-Path $env:TEMP "Application-Log-$(Get-Date -Format 'yyyyMMdd-HHmmss').evtx"
   wevtutil epl Application "$backupPath"
   Write-Host "Application log backed up to: $backupPath"
   ```

3. Clear Application log
   ```powershell
   wevtutil cl Application
   Write-Host "Application log cleared"
   ```

4. Backup System log (optional)
   ```powershell
   $backupPath = Join-Path $env:TEMP "System-Log-$(Get-Date -Format 'yyyyMMdd-HHmmss').evtx"
   wevtutil epl System "$backupPath"
   Write-Host "System log backed up to: $backupPath"
   ```

5. Clear System log
   ```powershell
   wevtutil cl System
   Write-Host "System log cleared"
   ```

6. Verify logs cleared
   ```powershell
   Get-WinEvent -ListLog Application, System | 
       Select-Object LogName, RecordCount |
       ForEach-Object {
           $status = if ($_.RecordCount -eq 0) { "CLEARED" } else { "CONTAINS DATA" }
           Write-Host "$($_.LogName): $status ($($_.RecordCount) records)"
       }
   ```

## Verification

All targeted logs should show 0 records.

## Notes

- **DANGER**: Clearing event logs removes diagnostic information
- Always backup before clearing in production
- Some security logs may be protected and cannot be cleared
- Consider using event forwarding for compliance requirements

## Related Runbooks

- `restart-service.md` - Restart Windows Event Log service if needed
