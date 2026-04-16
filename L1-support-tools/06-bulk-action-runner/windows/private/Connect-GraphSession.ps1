<#
.SYNOPSIS
    Connects to Microsoft Graph with appropriate scopes.

.DESCRIPTION
    Establishes a connection to Microsoft Graph API with the required
    permissions for bulk operations. Uses interactive login or cached credentials.

.PARAMETER Scopes
    Array of Graph API scopes to request.

.EXAMPLE
    Connect-GraphSession
#>
function Connect-GraphSession {
    [CmdletBinding()]
    param(
        [string[]]$Scopes = @(
            'User.ReadWrite.All',
            'GroupMember.ReadWrite.All',
            'Directory.ReadWrite.All'
        )
    )
    
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            Write-Verbose "Connecting to Microsoft Graph..."
            Connect-MgGraph -Scopes $Scopes -NoWelcome
        }
        else {
            Write-Verbose "Already connected to Microsoft Graph as $($context.Account)"
        }
    }
    catch {
        throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    }
}
