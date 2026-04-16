@{
    RootModule = 'bulk-run.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b4c7a1d2-5e3f-4a8b-9c6d-1e2f3a4b5c6d'
    Author = 'L1 Support Tools'
    Description = 'CSV-powered bulk operations tool for L1 support'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Invoke-BulkPasswordReset',
        'Invoke-BulkAddGroup',
        'Invoke-BulkEnableMailbox',
        'Invoke-BulkDeprovision',
        'Invoke-BulkAction'
    )
    
    AliasesToExport = @(
        'bulk-run'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('AzureAD', 'EntraID', 'Bulk', 'CSV', 'Support')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}
