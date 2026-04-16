function Connect-ExchangeSession {
    <#
    .SYNOPSIS
        Establishes connection to Exchange Online if not already connected.
    .DESCRIPTION
        Checks if there's an active Exchange Online session. If not, loads
        credentials from config and connects.
    #>
    [CmdletBinding()]
    param()
    
    # Check if already connected
    try {
        $session = Get-ConnectionInformation -ErrorAction SilentlyContinue
        if ($session -and $session.TokenStatus -eq 'Active') {
            Write-Verbose "Already connected to Exchange Online"
            return
        }
    }
    catch {
        # Not connected, continue to connect
    }
    
    # Load configuration
    $config = Get-ProvisionConfig
    
    try {
        # Connect using certificate-based authentication
        Connect-ExchangeOnline -AppId $config.AZURE_CLIENT_ID `
            -Organization "$($config.AZURE_TENANT_ID).onmicrosoft.com" `
            -CertificateThumbprint $config.AZURE_CERTIFICATE_THUMBPRINT `
            -ShowBanner:$false
        
        Write-Verbose "Connected to Exchange Online successfully"
    }
    catch {
        Write-ProvisionOutput -Type FAIL -Message "Failed to connect to Exchange Online: $_"
        throw
    }
}
