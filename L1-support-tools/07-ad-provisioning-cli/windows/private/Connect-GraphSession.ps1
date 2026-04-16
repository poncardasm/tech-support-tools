function Connect-GraphSession {
    <#
    .SYNOPSIS
        Establishes connection to Microsoft Graph if not already connected.
    .DESCRIPTION
        Checks if there's an active Microsoft Graph session. If not, loads
        credentials from config and connects using certificate-based authentication.
    #>
    [CmdletBinding()]
    param()
    
    # Check if already connected
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($context) {
        Write-Verbose "Already connected to Microsoft Graph as $($context.Account)"
        return
    }
    
    # Load configuration
    $config = Get-ProvisionConfig
    
    try {
        # Connect using certificate-based authentication
        $connectParams = @{
            ClientId = $config.AZURE_CLIENT_ID
            TenantId = $config.AZURE_TENANT_ID
            CertificateThumbprint = $config.AZURE_CERTIFICATE_THUMBPRINT
            NoWelcome = $true
        }
        
        Connect-MgGraph @connectParams | Out-Null
        Write-Verbose "Connected to Microsoft Graph successfully"
    }
    catch {
        Write-ProvisionOutput -Type FAIL -Message "Failed to connect to Microsoft Graph: $_"
        throw
    }
}
