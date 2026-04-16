function Remove-ADProvisionUser {
    <#
    .SYNOPSIS
        Deprovisions a user account (disable, remove groups, revoke sessions).
    .DESCRIPTION
        Performs offboarding tasks: disables the account, removes from all
        groups, revokes active sessions, and optionally removes the mailbox.
    .PARAMETER Username
        The user ID (GUID) or User Principal Name
    .PARAMETER Reason
        Optional reason for deprovisioning (logged for audit)
    .PARAMETER RemoveMailbox
        Switch to also remove the Exchange Online mailbox
    .PARAMETER WhatIf
        Shows what would happen without making changes
    .EXAMPLE
        Remove-ADProvisionUser -Username "asmith@company.com" -Reason "Terminated"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        
        [string]$Reason,
        
        [switch]$RemoveMailbox
    )
    
    # Connect to Microsoft Graph
    Connect-GraphSession
    
    $shouldProcessMessage = "Deprovision user $Username"
    if ($Reason) {
        $shouldProcessMessage += " (Reason: $Reason)"
    }
    
    if ($PSCmdlet.ShouldProcess($Username, $shouldProcessMessage)) {
        try {
            # Resolve to ID if UPN provided
            $userId = $Username
            if ($Username -match '@') {
                $user = Get-MgUser -Filter "userPrincipalName eq '$Username'" -ErrorAction Stop
                if (-not $user) {
                    Write-ProvisionOutput -Type FAIL -Message "User '$Username' not found"
                    throw "User '$Username' not found"
                }
                $userId = $user.Id
            }
            
            # Get all group memberships before removal
            $groups = Get-MgUserMemberOf -UserId $userId -All
            $groupCount = 0
            
            foreach ($group in $groups) {
                if ($group.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group') {
                    try {
                        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $userId
                        $groupCount++
                    }
                    catch {
                        Write-ProvisionOutput -Type WARN -Message "Could not remove from group $($group.DisplayName): $_"
                    }
                }
            }
            Write-ProvisionOutput -Type OK -Message "Removed from $groupCount groups"
            
            # Revoke all sign-in sessions
            try {
                Revoke-MgUserSignInSession -UserId $userId
                Write-ProvisionOutput -Type OK -Message "All sign-in sessions revoked"
            }
            catch {
                Write-ProvisionOutput -Type WARN -Message "Could not revoke sessions: $_"
            }
            
            # Disable the account
            Update-MgUser -UserId $userId -AccountEnabled:$false
            Write-ProvisionOutput -Type OK -Message "Account disabled"
            
            # Remove mailbox if requested
            if ($RemoveMailbox) {
                try {
                    Connect-ExchangeSession
                    $user = Get-MgUser -UserId $userId
                    Disable-Mailbox -Identity $user.UserPrincipalName -Confirm:$false
                    Write-ProvisionOutput -Type OK -Message "Mailbox removed"
                }
                catch {
                    Write-ProvisionOutput -Type WARN -Message "Could not remove mailbox: $_"
                }
            }
            
            Write-ProvisionOutput -Type OK -Message "Deprovisioning complete for $Username"
            if ($Reason) {
                Write-Verbose "Reason logged: $Reason"
            }
        }
        catch {
            Write-ProvisionOutput -Type FAIL -Message "Failed to deprovision user: $_"
            throw
        }
    }
    else {
        # WhatIf mode
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would remove from all groups"
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would revoke sign-in sessions"
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would disable account"
        if ($RemoveMailbox) {
            Write-ProvisionOutput -Type OK -Message "[WhatIf] Would remove mailbox"
        }
        if ($Reason) {
            Write-ProvisionOutput -Type OK -Message "[WhatIf] Reason: $Reason"
        }
    }
}
