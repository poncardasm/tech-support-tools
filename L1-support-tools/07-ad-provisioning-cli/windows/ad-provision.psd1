@{
    RootModule = 'ad-provision.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'L1 Support Tools'
    CompanyName = 'Company'
    Copyright = '(c) 2024 Company. All rights reserved.'
    Description = 'AD/User Provisioning CLI for L1 Support - Windows PowerShell Module'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'New-ADProvisionUser'
        'Add-ADProvisionGroup'
        'Enable-ADProvisionMailbox'
        'Reset-ADProvisionPassword'
        'Remove-ADProvisionUser'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @(
        @{ ModuleName = 'Microsoft.Graph.Users'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Groups'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.0.0' }
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('ActiveDirectory', 'AzureAD', 'EntraID', 'Provisioning', 'L1-Support')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release - AD/User Provisioning CLI'
        }
    }
}
