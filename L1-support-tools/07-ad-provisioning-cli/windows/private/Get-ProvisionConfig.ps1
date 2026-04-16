function Get-ProvisionConfig {
    <#
    .SYNOPSIS
        Loads AD Provisioning configuration from environment file.
    .DESCRIPTION
        Reads the creds.env file from %APPDATA%\ad-provision\ and returns
        a configuration object with Azure AD credentials.
    .OUTPUTS
        PSCustomObject containing configuration values
    #>
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path $env:APPDATA 'ad-provision\creds.env'
    
    if (-not (Test-Path $configPath)) {
        $errorMessage = @"
Configuration file not found at: $configPath

Please create the file by copying from the example:
  1. mkdir "$env:APPDATA\ad-provision" (if it doesn't exist)
  2. Copy config\creds.env.example to $configPath
  3. Fill in your Azure AD application credentials

Required values:
  - AZURE_CLIENT_ID: Your EntraID app registration client ID
  - AZURE_TENANT_ID: Your Azure AD tenant ID
  - AZURE_CERTIFICATE_THUMBPRINT: Certificate thumbprint for authentication
"@
        throw $errorMessage
    }
    
    try {
        $envContent = Get-Content $configPath -ErrorAction Stop
        $config = @{}
        
        foreach ($line in $envContent) {
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                continue
            }
            
            # Parse KEY=VALUE format
            if ($line -match '^([A-Za-z0-9_]+)=(.*)$') {
                $key = $matches[1]
                $value = $matches[2]
                $config[$key] = $value
            }
        }
        
        # Validate required fields
        $requiredFields = @('AZURE_CLIENT_ID', 'AZURE_TENANT_ID', 'AZURE_CERTIFICATE_THUMBPRINT')
        foreach ($field in $requiredFields) {
            if (-not $config.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($config[$field])) {
                throw "Missing required configuration: $field"
            }
        }
        
        return [PSCustomObject]$config
    }
    catch {
        Write-ProvisionOutput -Type FAIL -Message "Failed to load configuration: $_"
        throw
    }
}
