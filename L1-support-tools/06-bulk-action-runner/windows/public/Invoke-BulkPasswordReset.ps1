<#
.SYNOPSIS
    Performs bulk password resets from a CSV file.

.DESCRIPTION
    Reads user emails from a CSV file and resets passwords for each user.
    Generates temporary passwords and forces password change on next login.

.PARAMETER CsvPath
    Path to the CSV file containing user emails.

.PARAMETER ReportPath
    Optional path to save a CSV report of results.

.EXAMPLE
    Invoke-BulkPasswordReset -CsvPath users.csv
    
    Invoke-BulkPasswordReset -CsvPath users.csv -ReportPath results.csv -WhatIf
#>
function Invoke-BulkPasswordReset {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CsvPath,
        
        [Parameter(Position = 1)]
        [string]$ReportPath
    )
    
    begin {
        $users = Read-BulkCsv -CsvPath $CsvPath
        $results = [System.Collections.ArrayList]::new()
        $operation = 'password-reset'
        
        if (-not $WhatIfPreference) {
            Connect-GraphSession
        }
        
        Write-BulkOutput -Type OK -Message "Processing $($users.Count) users for password reset..."
    }
    
    process {
        foreach ($user in $users) {
            $email = $user.email
            $tempPassword = New-TemporaryPassword
            
            if ($WhatIfPreference) {
                Write-BulkOutput -Type OK -Message "$email — would reset password"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'dry-run'
                    detail = 'Would reset password'
                    timestamp = (Get-Date -Format 'o')
                }) | Out-Null
                continue
            }
            
            try {
                $params = @{
                    Password = $tempPassword
                    ForceChangePasswordNextSignIn = $true
                }
                
                Update-MgUser -UserId $email -PasswordProfile $params -ErrorAction Stop
                
                Write-BulkOutput -Type OK -Message "$email — password reset, temp: $tempPassword"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'success'
                    detail = "Temp password: $tempPassword"
                    timestamp = (Get-Date -Format 'o')
                }) | Out-Null
            }
            catch {
                $errorMsg = $_.Exception.Message
                Write-BulkOutput -Type FAIL -Message "$email — error: $errorMsg"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'failure'
                    detail = $errorMsg
                    timestamp = (Get-Date -Format 'o')
                }) | Out-Null
            }
            
            Start-Throttle -Milliseconds 500
        }
    }
    
    end {
        $successCount = ($results | Where-Object { $_.result -eq 'success' }).Count
        $failCount = ($results | Where-Object { $_.result -eq 'failure' }).Count
        $dryRunCount = ($results | Where-Object { $_.result -eq 'dry-run' }).Count
        
        Write-Host ""
        Write-BulkOutput -Type OK -Message "Completed: $successCount succeeded"
        if ($failCount -gt 0) {
            Write-BulkOutput -Type FAIL -Message "Completed: $failCount failed"
        }
        if ($dryRunCount -gt 0) {
            Write-BulkOutput -Type WARN -Message "Completed: $dryRunCount dry-run"
        }
        
        if ($ReportPath) {
            $results | Export-Csv -Path $ReportPath -NoTypeInformation
            Write-BulkOutput -Type OK -Message "Report saved to: $ReportPath"
        }
        
        return $results
    }
}
