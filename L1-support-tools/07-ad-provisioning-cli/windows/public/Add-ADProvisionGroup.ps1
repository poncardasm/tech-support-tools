function Add-ADProvisionGroup {
    <#
    .SYNOPSIS
        Adds a user to an Azure AD group.
    .DESCRIPTION
        Adds an existing user to one or more Azure AD groups by group name.
    .PARAMETER Username
        The user ID (GUID) or User Principal Name
    .PARAMETER Group
        The display name of the group to add the user to
    .PARAMETER WhatIf
        Shows what would happen without making changes
    .EXAMPLE
        Add-ADProvisionGroup -Username "asmith@company.com" -Group "IT-Admins"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        
        [Parameter(Mandatory)]
        [string]$Group
    )
    
    # Connect to Microsoft Graph
    Connect-GraphSession
    
    if ($PSCmdlet.ShouldProcess($Username, "Add to group $Group")) {
        try {
            # Get the group
            $targetGroup = Get-MgGroup -Filter "displayName eq '$Group'" -ErrorAction Stop
            
            if (-not $targetGroup) {
                Write-ProvisionOutput -Type FAIL -Message "Group '$Group' not found"
                throw "Group '$Group' not found"
            }
            
            # Resolve user ID if UPN provided
            $userId = $Username
            if ($Username -match '@') {
                $user = Get-MgUser -Filter "userPrincipalName eq '$Username'" -ErrorAction Stop
                if ($user) {
                    $userId = $user.Id
                }
                else {
                    Write-ProvisionOutput -Type FAIL -Message "User '$Username' not found"
                    throw "User '$Username' not found"
                }
            }
            
            # Check if user is already a member
            try {
                $isMember = Get-MgGroupMember -GroupId $targetGroup.Id | Where-Object { $_.Id -eq $userId }
                if ($isMember) {
                    Write-ProvisionOutput -Type WARN -Message "User already in group $Group"
                    return
                }
            }
            catch {
                # Continue if check fails - we'll try to add anyway
            }
            
            # Add user to group
            New-MgGroupMember -GroupId $targetGroup.Id -DirectoryObjectId $userId
            Write-ProvisionOutput -Type OK -Message "Added to group $Group"
        }
        catch {
            Write-ProvisionOutput -Type FAIL -Message "Failed to add to group $Group`: $_"
            throw
        }
    }
    else {
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would add $Username to group $Group"
    }
}
