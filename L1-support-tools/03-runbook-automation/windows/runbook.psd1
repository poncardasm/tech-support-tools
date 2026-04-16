@{
    RootModule = 'runbook.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a3f7b2c4-d8e1-4f5a-9b0c-6e2d8f1a3c5e'
    Author = 'L1 Support Tools'
    CompanyName = 'L1 Support Tools'
    Copyright = '(c) 2025 L1 Support Tools. All rights reserved.'
    Description = 'CLI tool for managing and executing markdown-based runbooks on Windows'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Invoke-Runbook',
        'Get-RunbookList',
        'Search-Runbook',
        'Get-RunbookState',
        'Clear-RunbookState'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @(
        'runbook'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('runbook', 'automation', 'cli', 'markdown', 'powershell')
            LicenseUri = 'https://github.com/example/runbook-automation/blob/main/LICENSE'
            ProjectUri = 'https://github.com/example/runbook-automation'
            ReleaseNotes = 'Initial release of Runbook Automation for Windows'
        }
    }
}
