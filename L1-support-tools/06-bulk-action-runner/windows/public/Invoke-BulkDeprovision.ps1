<#
.SYNOPSIS
    Performs bulk user deprovisioning from a CSV file.

.DESCRIPTION
    Reads user emails from a CSV file and deprovisions each user account.
    Disables the account and removes group memberships.

.PARAMETER CsvPath
    Path to the CSV file containing user emails.

.PARAMETER Reason
    Reason for deprovisioning (e.g., "terminated", "contract ended").

.PARAMETER ReportPath
    Optional path to save a CSV report of results.

.EXAMPLE
    Invoke-BulkDeprovision -CsvPath users.csv -Reason "terminated"
    
    Invoke-BulkDeprovision -CsvPath users.csv -Reason "contract ended" -WhatIf
#>
function Invoke-BulkDeprovision {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CsvPath,
        
        [Parameter(Position = 1)]
        [string]$Reason = 'deprovisioned',
        
        [Parameter(Position = 2)]
        [string]$ReportPath
    )
    
    begin {
        $users = Read-BulkCsv -CsvPath $CsvPath
        $results = [System.Collections.ArrayList]::new()
        $operation = 'deprovision'
        
        if (-not $WhatIfPreference) {
            Connect-GraphSession
        }
        
        Write-BulkOutput -Type OK -Message "Processing $($users.Count) users for deprovisioning (reason: $Reason)..."
    }
    
    process {
        foreach ($user in $users) {
            $email = $user.email
            
            if ($WhatIfPreference) {
                Write-BulkOutput -Type OK -Message "$email — would deprovision (reason: $Reason)"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'dry-run'
                    detail = "Would deprovision (reason: $Reason)"
                    timestamp = (Get-Date -Format 'o')
                }) | Out-Null
                continue
            }
            
            try {
                # Get user details
                $userObj = Get-MgUser -Filter "userPrincipalName eq '$email'" -Property 'Id,AccountEnabled' -ErrorAction Stop | Select-Object -First 1
                if (-not $userObj) {
                    throw "User not found: $email"
                }
                
                # Check if already disabled
                if (-not $userObj.AccountEnabled) {
                    Write-BulkOutput -Type WARN -Message "$email — account already disabled"
                    $results.Add([PSCustomObject]@{
                        email = $email
                        operation = $operation
                        result = 'skipped'
                        detail = 'Account already disabled'
                        timestamp = (Get-Date -Format 'o')
                    }) | Out-Null
                    Start-Throttle -Milliseconds 500
                    continue
                }
                
                # Get user's group memberships
                $groups = Get-MgUserMemberOf -UserId $userObj.Id -ErrorAction SilentlyContinue | 
                    Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' -and $_.GroupTypes -notcontains 'Unified' }
                
                $groupCount = 0
                foreach ($group in $groups) {
                    try {
                        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $userObj.Id -ErrorAction Stop
                        $groupCount++
                    }
                    catch {
                        Write-Verbose "Failed to remove $email from group $($group.DisplayName): $($_.Exception.Message)"
                    }
                    Start-Throttle -Milliseconds 200
                }
                
                # Disable account
                Update-MgUser -UserId $userObj.Id -AccountEnabled:$false -ErrorAction Stop
                
                Write-BulkOutput -Type OK -Message "$email — deprovisioned, removed from $groupCount groups"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'success'
                    detail = "Removed from $groupCount groups"
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
        $skipCount = ($results | Where-Object { $_.result -eq 'skipped' }).Count
        $dryRunCount = ($results | Where-Object { $_.result -eq 'dry-run' }).Count
        
        Write-Host ""
        Write-BulkOutput -Type OK -Message "Completed: $successCount succeeded"
        if ($skipCount -gt 0) {
            Write-BulkOutput -Type WARN -Message "Completed: $skipCount skipped (already disabled)"
        }
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
