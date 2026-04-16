function New-ADProvisionUser {
    <#
    .SYNOPSIS
        Creates a new user in Azure AD/EntraID with optional mailbox.
    .DESCRIPTION
        Creates a new user account, adds them to specified groups,
        and optionally enables their Exchange Online mailbox.
    .PARAMETER Username
        The username (mail nickname) for the new user
    .PARAMETER DisplayName
        The full display name of the user
    .PARAMETER Email
        The user principal name (email address)
    .PARAMETER Department
        The department for organizational grouping
    .PARAMETER Groups
        Optional array of group names to add the user to
    .PARAMETER EnableMailbox
        Switch to enable Exchange Online mailbox
    .PARAMETER WhatIf
        Shows what would happen without making changes
    .EXAMPLE
        New-ADProvisionUser -Username "asmith" -DisplayName "Alice Smith" -Email "asmith@company.com" -Department "IT"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        
        [Parameter(Mandatory)]
        [string]$DisplayName,
        
        [Parameter(Mandatory)]
        [string]$Email,
        
        [Parameter(Mandatory)]
        [string]$Department,
        
        [string[]]$Groups = @(),
        
        [switch]$EnableMailbox
    )
    
    # Connect to Microsoft Graph
    Connect-GraphSession
    
    # Generate temporary password
    $tempPassword = New-TemporaryPassword
    
    $shouldProcessMessage = "Create user $Email in Azure AD"
    if ($Groups.Count -gt 0) {
        $shouldProcessMessage += " and add to groups: $($Groups -join ', ')"
    }
    if ($EnableMailbox) {
        $shouldProcessMessage += " with mailbox enabled"
    }
    
    if ($PSCmdlet.ShouldProcess($Email, $shouldProcessMessage)) {
        try {
            # Create password profile
            $passwordProfile = @{
                Password = $tempPassword
                ForceChangePasswordNextSignIn = $true
            }
            
            # Create the user
            $userParams = @{
                DisplayName = $DisplayName
                UserPrincipalName = $Email
                MailNickname = $Username
                AccountEnabled = $true
                PasswordProfile = $passwordProfile
                Department = $Department
            }
            
            $user = New-MgUser @userParams
            
            Write-ProvisionOutput -Type OK -Message "User $Email created"
            
            # Add to department group automatically
            $deptGroup = "$Department-All"
            try {
                $group = Get-MgGroup -Filter "displayName eq '$deptGroup'" -ErrorAction Stop
                if ($group) {
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                    Write-ProvisionOutput -Type OK -Message "Added to department group $deptGroup"
                }
            }
            catch {
                Write-ProvisionOutput -Type WARN -Message "Department group $deptGroup not found or could not be added"
            }
            
            # Add to additional groups
            foreach ($groupName in $Groups) {
                try {
                    $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction Stop
                    if ($group) {
                        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                        Write-ProvisionOutput -Type OK -Message "Added to group $groupName"
                    }
                }
                catch {
                    Write-ProvisionOutput -Type FAIL -Message "Failed to add to group $groupName`: $_"
                }
            }
            
            # Enable mailbox if requested
            if ($EnableMailbox) {
                try {
                    Enable-ADProvisionMailbox -Username $user.Id
                }
                catch {
                    Write-ProvisionOutput -Type FAIL -Message "Failed to enable mailbox: $_"
                }
            }
            
            # Output the temporary password
            Write-ProvisionOutput -Type TEMP -Message "Password: $tempPassword - force change required on first login"
            
            return $user
        }
        catch {
            Write-ProvisionOutput -Type FAIL -Message "Failed to create user: $_"
            throw
        }
    }
    else {
        # WhatIf mode - show what would happen
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would create user $Email"
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would add to department: $Department"
        if ($Groups.Count -gt 0) {
            Write-ProvisionOutput -Type OK -Message "[WhatIf] Would add to groups: $($Groups -join ', ')"
        }
        if ($EnableMailbox) {
            Write-ProvisionOutput -Type OK -Message "[WhatIf] Would enable Exchange Online mailbox"
        }
        Write-ProvisionOutput -Type TEMP -Message "[WhatIf] Would generate temporary password"
    }
}
