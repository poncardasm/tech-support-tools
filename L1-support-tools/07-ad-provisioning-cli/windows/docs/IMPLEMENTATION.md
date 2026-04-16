# AD/User Provisioning CLI — Implementation Plan (Windows)

## 1. Project Setup

### 1.1 Prerequisites

```powershell
# Install PowerShell 7+ if not already installed
winget install Microsoft.PowerShell

# Install required modules
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

### 1.2 File Structure

```
ad-provisioning-cli/
├── ad-provision.psd1        # Module manifest
├── ad-provision.psm1        # Module entry point
├── public/
│   ├── New-ADProvisionUser.ps1
│   ├── Add-ADProvisionGroup.ps1
│   ├── Enable-ADProvisionMailbox.ps1
│   ├── Reset-ADProvisionPassword.ps1
│   └── Remove-ADProvisionUser.ps1
├── private/
│   ├── Connect-GraphSession.ps1
│   ├── Get-ProvisionConfig.ps1
│   └── Write-ProvisionOutput.ps1
├── config/
│   └── creds.env.example
├── tests/
│   └── ad-provision.Tests.ps1
└── README.md
```

---

## 2. Module Structure

### 2.1 ad-provision.psd1 (Manifest)

```powershell
@{
    RootModule = 'ad-provision.psm1'
    ModuleVersion = '1.0.0'
    FunctionsToExport = @(
        'New-ADProvisionUser'
        'Add-ADProvisionGroup'
        'Enable-ADProvisionMailbox'
        'Reset-ADProvisionPassword'
        'Remove-ADProvisionUser'
    )
    RequiredModules = @(
        @{ ModuleName = 'Microsoft.Graph'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.0.0' }
    )
}
```

### 2.2 ad-provision.psm1 (Entry Point)

```powershell
# Import all public functions
$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue )
foreach ($import in $Public) {
    . $import.FullName
}

# Import all private functions
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue )
foreach ($import in $Private) {
    . $import.FullName
}

Export-ModuleMember -Function $Public.BaseName
```

---

## 3. Core Functions

### 3.1 New-ADProvisionUser.ps1

```powershell
function New-ADProvisionUser {
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
    
    # Connect to Graph if not already connected
    Connect-GraphSession
    
    if ($PSCmdlet.ShouldProcess($Email, "Create new user")) {
        # Create user via Microsoft Graph
        $user = New-MgUser -DisplayName $DisplayName -UserPrincipalName $Email `
            -MailNickname $Username -AccountEnabled `
            -PasswordProfile @{ Password = (New-TemporaryPassword); ForceChangePasswordNextLogin = $true }
        
        Write-ProvisionOutput -Type OK -Message "User $Email created"
        
        # Add to groups
        foreach ($group in $Groups) {
            Add-ADProvisionGroup -Username $user.Id -Group $group
        }
        
        # Enable mailbox if requested
        if ($EnableMailbox) {
            Enable-ADProvisionMailbox -Username $user.Id
        }
        
        return $user
    }
}
```

### 3.2 Reset-ADProvisionPassword.ps1

```powershell
function Reset-ADProvisionPassword {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )
    
    Connect-GraphSession
    
    $tempPassword = New-TemporaryPassword
    
    if ($PSCmdlet.ShouldProcess($Username, "Reset password")) {
        Update-MgUser -UserId $Username -PasswordProfile @{
            Password = $tempPassword
            ForceChangePasswordNextLogin = $true
        }
        
        Write-ProvisionOutput -Type TEMP -Message "Password: $tempPassword — force change required"
    }
}
```

### 3.3 Remove-ADProvisionUser.ps1 (Deprovision)

```powershell
function Remove-ADProvisionUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        
        [string]$Reason
    )
    
    Connect-GraphSession
    
    if ($PSCmdlet.ShouldProcess($Username, "Deprovision user")) {
        # Disable account
        Update-MgUser -UserId $Username -AccountEnabled:$false
        Write-ProvisionOutput -Type OK -Message "Account disabled"
        
        # Remove from all groups
        $groups = Get-MgUserMemberOf -UserId $Username
        foreach ($group in $groups) {
            Remove-MgGroupMember -GroupId $group.Id -DirectoryObjectId $Username
        }
        Write-ProvisionOutput -Type OK -Message "Removed from all groups"
        
        # Revoke sessions
        Revoke-MgUserSignInSession -UserId $Username
        Write-ProvisionOutput -Type OK -Message "Sessions revoked"
    }
}
```

---

## 4. Helper Functions

### 4.1 Connect-GraphSession.ps1

```powershell
function Connect-GraphSession {
    $config = Get-ProvisionConfig
    
    if (-not (Get-MgContext)) {
        Connect-MgGraph -ClientId $config.ClientId `
            -TenantId $config.TenantId `
            -CertificateThumbprint $config.CertificateThumbprint
    }
}
```

### 4.2 Get-ProvisionConfig.ps1

```powershell
function Get-ProvisionConfig {
    $configPath = Join-Path $env:APPDATA 'ad-provision\creds.env'
    
    if (Test-Path $configPath) {
        $envContent = Get-Content $configPath
        $config = @{}
        foreach ($line in $envContent) {
            if ($line -match '^([^=]+)=(.*)$') {
                $config[$matches[1]] = $matches[2]
            }
        }
        return [PSCustomObject]$config
    }
    
    throw "Config not found at $configPath. Create creds.env from creds.env.example."
}
```

### 4.3 Write-ProvisionOutput.ps1

```powershell
function Write-ProvisionOutput {
    param(
        [ValidateSet('OK', 'FAIL', 'TEMP', 'WARN')]
        [string]$Type,
        
        [string]$Message
    )
    
    $prefix = switch ($Type) {
        'OK'   { '[OK]   ' }
        'FAIL' { '[FAIL] ' }
        'TEMP' { '[TEMP] ' }
        'WARN' { '[WARN] ' }
    }
    
    Write-Host "$prefix$Message"
}
```

---

## 5. Configuration

### 5.1 creds.env.example

```env
AZURE_CLIENT_ID=your-app-client-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CERTIFICATE_THUMBPRINT=your-cert-thumbprint
```

---

## 6. Testing

### 6.1 Pester Tests (tests/ad-provision.Tests.ps1)

```powershell
Describe "AD Provision Module" {
    BeforeAll {
        Import-Module ./ad-provision.psd1
    }
    
    Context "New-ADProvisionUser" {
        It "Should create user with -WhatIf" {
            { New-ADProvisionUser -Username "testuser" -DisplayName "Test User" `
                -Email "test@company.com" -Department "IT" -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Reset-ADProvisionPassword" {
        It "Should accept -WhatIf" {
            { Reset-ADProvisionPassword -Username "testuser" -WhatIf } | Should -Not -Throw
        }
    }
}
```

---

## 7. Installation

```powershell
# Copy module to PowerShell modules path
Copy-Item -Recurse ./ad-provisioning-cli "$env:Documents\PowerShell\Modules\ad-provision"

# Import and use
Import-Module ad-provision
New-ADProvisionUser -Username alice -DisplayName "Alice Smith" -Email alice@company.com -Department IT
```

---

## 8. Known Pitfalls (Windows)

1. **Certificate-based auth** — Ensure certificate is in CurrentUser\My store
2. **Exchange Online module** — Requires separate connection
3. **Rate limiting** — Microsoft Graph has throttling limits; implement delays for bulk ops
4. **Permission scopes** — App registration needs User.ReadWrite.All, Group.ReadWrite.All

---

## 9. Out of Scope

- Bulk operations (use bulk-action-runner)
- GUI interface
- On-prem AD support (Azure AD / EntraID only)
