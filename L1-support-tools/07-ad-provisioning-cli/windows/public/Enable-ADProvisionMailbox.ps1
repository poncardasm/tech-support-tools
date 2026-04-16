function Enable-ADProvisionMailbox {
    <#
    .SYNOPSIS
        Enables Exchange Online mailbox for a user.
    .DESCRIPTION
        Enables an Exchange Online mailbox for an existing Azure AD user.
        Requires the Exchange Online PowerShell module.
    .PARAMETER Username
        The user ID (GUID) or User Principal Name
    .PARAMETER WhatIf
        Shows what would happen without making changes
    .EXAMPLE
        Enable-ADProvisionMailbox -Username "asmith@company.com"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Username
    )
    
    process {
        # Connect to both Microsoft Graph and Exchange Online
        Connect-GraphSession
        Connect-ExchangeSession
        
        if ($PSCmdlet.ShouldProcess($Username, "Enable Exchange Online mailbox")) {
            try {
                # Resolve to UPN if GUID provided
                $upn = $Username
                if ($Username -notmatch '@') {
                    $user = Get-MgUser -UserId $Username -ErrorAction Stop
                    if (-not $user) {
                        Write-ProvisionOutput -Type FAIL -Message "User '$Username' not found"
                        throw "User '$Username' not found"
                    }
                    $upn = $user.UserPrincipalName
                }
                
                # Check if mailbox already exists
                $existingMailbox = Get-Mailbox -Identity $upn -ErrorAction SilentlyContinue
                if ($existingMailbox) {
                    Write-ProvisionOutput -Type WARN -Message "Mailbox already exists for $upn"
                    return
                }
                
                # Enable the mailbox
                Enable-Mailbox -Identity $upn
                Write-ProvisionOutput -Type OK -Message "Mailbox enabled for $upn"
            }
            catch {
                Write-ProvisionOutput -Type FAIL -Message "Failed to enable mailbox: $_"
                throw
            }
        }
        else {
            Write-ProvisionOutput -Type OK -Message "[WhatIf] Would enable mailbox for $Username"
        }
    }
}
