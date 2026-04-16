function Reset-ADProvisionPassword {
    <#
    .SYNOPSIS
        Resets a user's password and forces change on next login.
    .DESCRIPTION
        Generates a new temporary password for the user and sets the
        force change password flag for the next sign-in.
    .PARAMETER Username
        The user ID (GUID) or User Principal Name
    .PARAMETER WhatIf
        Shows what would happen without making changes
    .EXAMPLE
        Reset-ADProvisionPassword -Username "asmith@company.com"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )
    
    # Connect to Microsoft Graph
    Connect-GraphSession
    
    # Generate temporary password
    $tempPassword = New-TemporaryPassword
    
    if ($PSCmdlet.ShouldProcess($Username, "Reset password")) {
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
            
            # Update password
            $passwordProfile = @{
                Password = $tempPassword
                ForceChangePasswordNextSignIn = $true
            }
            
            Update-MgUser -UserId $userId -PasswordProfile $passwordProfile
            Write-ProvisionOutput -Type OK -Message "Password reset for $Username"
            Write-ProvisionOutput -Type TEMP -Message "Password: $tempPassword - force change required on next login"
        }
        catch {
            Write-ProvisionOutput -Type FAIL -Message "Failed to reset password: $_"
            throw
        }
    }
    else {
        Write-ProvisionOutput -Type OK -Message "[WhatIf] Would reset password for $Username"
        Write-ProvisionOutput -Type TEMP -Message "[WhatIf] Would generate new temporary password"
    }
}
