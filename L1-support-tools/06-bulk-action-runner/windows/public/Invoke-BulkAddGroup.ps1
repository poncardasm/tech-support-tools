<#
.SYNOPSIS
    Performs bulk group additions from a CSV file.

.DESCRIPTION
    Reads user emails from a CSV file and adds each user to the specified AD group.

.PARAMETER CsvPath
    Path to the CSV file containing user emails.

.PARAMETER Group
    Name of the group to add users to.

.PARAMETER ReportPath
    Optional path to save a CSV report of results.

.EXAMPLE
    Invoke-BulkAddGroup -CsvPath users.csv -Group "IT-All"
    
    Invoke-BulkAddGroup -CsvPath users.csv -Group "IT-All" -WhatIf
#>
function Invoke-BulkAddGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CsvPath,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$Group,
        
        [Parameter(Position = 2)]
        [string]$ReportPath
    )
    
    begin {
        $users = Read-BulkCsv -CsvPath $CsvPath
        $results = [System.Collections.ArrayList]::new()
        $operation = 'add-group'
        
        if (-not $WhatIfPreference) {
            Connect-GraphSession
            
            # Resolve group name to ID
            $groupObj = Get-MgGroup -Filter "displayName eq '$Group'" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $groupObj) {
                throw "Group not found: $Group"
            }
            $script:groupId = $groupObj.Id
            Write-BulkOutput -Type OK -Message "Resolved group '$Group' to ID: $script:groupId"
        }
        
        Write-BulkOutput -Type OK -Message "Processing $($users.Count) users to add to group '$Group'..."
    }
    
    process {
        foreach ($user in $users) {
            $email = $user.email
            
            if ($WhatIfPreference) {
                Write-BulkOutput -Type OK -Message "$email — would add to $Group"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'dry-run'
                    detail = "Would add to $Group"
                    timestamp = (Get-Date -Format 'o')
                }) | Out-Null
                continue
            }
            
            try {
                # Get user ID from email
                $userObj = Get-MgUser -Filter "userPrincipalName eq '$email'" -ErrorAction Stop | Select-Object -First 1
                if (-not $userObj) {
                    throw "User not found: $email"
                }
                
                # Check if user is already in group
                $existingMember = Get-MgGroupMember -GroupId $script:groupId -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Id -eq $userObj.Id }
                
                if ($existingMember) {
                    Write-BulkOutput -Type WARN -Message "$email — already in group $Group"
                    $results.Add([PSCustomObject]@{
                        email = $email
                        operation = $operation
                        result = 'skipped'
                        detail = 'Already in group'
                        timestamp = (Get-Date -Format 'o')
                    }) | Out-Null
                    Start-Throttle -Milliseconds 500
                    continue
                }
                
                # Add user to group
                $body = @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($userObj.Id)"
                }
                New-MgGroupMember -GroupId $script:groupId -BodyParameter $body -ErrorAction Stop
                
                Write-BulkOutput -Type OK -Message "$email — added to $Group"
                $results.Add([PSCustomObject]@{
                    email = $email
                    operation = $operation
                    result = 'success'
                    detail = "Added to $Group"
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
            Write-BulkOutput -Type WARN -Message "Completed: $skipCount skipped (already in group)"
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
