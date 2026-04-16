BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..' 'runbook.psd1'
    Import-Module $modulePath -Force
    
    # Create a temporary test directory
    $script:TestDir = Join-Path ([System.IO.Path]::GetTempPath()) "runbook-tests-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create test runbooks directory
    $script:TestRunbooksDir = Join-Path $script:TestDir 'runbooks'
    New-Item -ItemType Directory -Path $script:TestRunbooksDir -Force | Out-Null
}

AfterAll {
    # Clean up test directory
    if (Test-Path $script:TestDir) {
        Remove-Item -Path $script:TestDir -Recurse -Force
    }
    
    # Clean up any test state files
    $stateDir = Join-Path $env:APPDATA 'runbook\state'
    if (Test-Path $stateDir) {
        Get-ChildItem -Path $stateDir -Filter '*test*.json' | Remove-Item -Force
    }
}

Describe "Parse-MarkdownSteps" {
    BeforeEach {
        $script:TestFile = Join-Path $script:TestDir 'test-runbook.md'
    }
    
    It "Should extract PowerShell steps from a markdown file" {
        @"
# Test Runbook

## Steps

1. First step
   ```powershell
   Get-Process
   ```

2. Second step
   ```powershell
   Get-Service
   ```
"@ | Set-Content -Path $script:TestFile
        
        $steps = Parse-MarkdownSteps -FilePath $script:TestFile
        $steps.Count | Should -Be 2
        $steps[0].Code | Should -Be "Get-Process"
        $steps[1].Code | Should -Be "Get-Service"
    }
    
    It "Should extract pwsh code blocks" {
        @"
# Test Runbook

```pwsh
Write-Host "Hello"
```
"@ | Set-Content -Path $script:TestFile
        
        $steps = Parse-MarkdownSteps -FilePath $script:TestFile
        $steps.Count | Should -Be 1
        $steps[0].Language | Should -Be "pwsh"
    }
    
    It "Should ignore non-PowerShell code blocks" {
        @"
# Test Runbook

```powershell
Get-Process
```

```python
print("hello")
```

```bash
echo hello
```
"@ | Set-Content -Path $script:TestFile
        
        $steps = Parse-MarkdownSteps -FilePath $script:TestFile
        $steps.Count | Should -Be 1
    }
    
    It "Should throw for non-existent file" {
        { Parse-MarkdownSteps -FilePath 'nonexistent.md' } | Should -Throw
    }
    
    It "Should throw for non-markdown file" {
        $txtFile = Join-Path $script:TestDir 'test.txt'
        "test" | Set-Content -Path $txtFile
        { Parse-MarkdownSteps -FilePath $txtFile } | Should -Throw
    }
}

Describe "Test-RunbookValid" {
    BeforeEach {
        $script:TestFile = Join-Path $script:TestDir 'valid-test.md'
    }
    
    It "Should return true for valid runbook" {
        @"
# Test Runbook

```powershell
Get-Process
```
"@ | Set-Content -Path $script:TestFile
        
        Test-RunbookValid -FilePath $script:TestFile | Should -Be $true
    }
    
    It "Should return false for file without PowerShell blocks" {
        @"
# Test Runbook

Some text without code blocks.
"@ | Set-Content -Path $script:TestFile
        
        Test-RunbookValid -FilePath $script:TestFile | Should -Be $false
    }
    
    It "Should return false for non-existent file" {
        Test-RunbookValid -FilePath 'nonexistent.md' | Should -Be $false
    }
}

Describe "Invoke-Step" {
    It "Should execute a simple command successfully" {
        $step = [PSCustomObject]@{
            Number   = 1
            Code     = 'Write-Output "test"'
            Language = 'powershell'
        }
        
        $result = Invoke-Step -Step $step -TotalSteps 1
        $result.Success | Should -Be $true
        $result.ExitCode | Should -Be 0
    }
    
    It "Should handle dry-run mode" {
        $step = [PSCustomObject]@{
            Number   = 1
            Code     = 'Remove-Item -Path "C:\\" -Recurse'  # Dangerous command that won't run
            Language = 'powershell'
        }
        
        $result = Invoke-Step -Step $step -TotalSteps 1 -DryRun
        $result.Success | Should -Be $true
    }
    
    It "Should handle failed commands" {
        $step = [PSCustomObject]@{
            Number   = 1
            Code     = 'throw "Test error"'
            Language = 'powershell'
        }
        
        $result = Invoke-Step -Step $step -TotalSteps 1
        $result.Success | Should -Be $false
    }
}

Describe "Get-RunbookList" {
    BeforeAll {
        # Create test runbooks
        $servicesDir = Join-Path $script:TestRunbooksDir 'services'
        $iisDir = Join-Path $script:TestRunbooksDir 'iis'
        New-Item -ItemType Directory -Path $servicesDir -Force | Out-Null
        New-Item -ItemType Directory -Path $iisDir -Force | Out-Null
        
        "# Service Runbook`n`n```powershell`nGet-Service`n```" | 
            Set-Content -Path (Join-Path $servicesDir 'restart-service.md')
        
        "# IIS Runbook`n`n```powershell`nGet-IISAppPool`n```" | 
            Set-Content -Path (Join-Path $iisDir 'restart-apppool.md')
    }
    
    It "Should list all runbooks" {
        $runbooks = Get-RunbookList -Path $script:TestRunbooksDir
        $runbooks.Count | Should -Be 2
    }
    
    It "Should filter by category" {
        $runbooks = Get-RunbookList -Path $script:TestRunbooksDir -Category 'iis'
        $runbooks.Count | Should -Be 1
        $runbooks[0].Category | Should -Be 'iis'
    }
    
    It "Should return empty array for non-existent path" {
        $runbooks = Get-RunbookList -Path 'nonexistent-path'
        $runbooks | Should -BeNullOrEmpty
    }
}

Describe "Search-Runbook" {
    BeforeAll {
        $searchDir = Join-Path $script:TestDir 'search-runbooks'
        New-Item -ItemType Directory -Path $searchDir -Force | Out-Null
        
        "# Restart IIS`n`n```powershell`nRestart-Service W3SVC`n```" | 
            Set-Content -Path (Join-Path $searchDir 'restart-iis.md')
        
        "# Check Services`n`n```powershell`nGet-Service`n```" | 
            Set-Content -Path (Join-Path $searchDir 'check-services.md')
    }
    
    It "Should find runbooks by name" {
        $results = Search-Runbook -Query 'iis' -Path $searchDir
        $results.Count | Should -Be 1
        $results[0].Name | Should -Be 'restart-iis'
    }
    
    It "Should search content when requested" {
        $results = Search-Runbook -Query 'Get-Service' -Path $searchDir -SearchContent
        $results.Count | Should -BeGreaterOrEqual 1
    }
    
    It "Should return empty for no matches" {
        $results = Search-Runbook -Query 'nonexistentxyz' -Path $searchDir
        $results | Should -BeNullOrEmpty
    }
}

Describe "State Management" {
    BeforeEach {
        $script:StateTestFile = Join-Path $script:TestDir 'state-test.md'
        "# Test`n`n```powershell`nWrite-Host 'test'`n```" | Set-Content -Path $script:StateTestFile
    }
    
    It "Should save and retrieve runbook state" {
        Save-RunbookState -FilePath $script:StateTestFile -StepNumber 3 -Success $true
        
        $state = Get-RunbookState -FilePath $script:StateTestFile
        $state.CurrentStep | Should -Be 3
    }
    
    It "Should return default state for new runbook" {
        $newFile = Join-Path $script:TestDir 'new-runbook.md'
        $state = Get-RunbookState -FilePath $newFile
        $state.CurrentStep | Should -Be 1
    }
    
    It "Should clear runbook state" {
        Save-RunbookState -FilePath $script:StateTestFile -StepNumber 2
        Clear-RunbookState -FilePath $script:StateTestFile
        
        $state = Get-RunbookState -FilePath $script:StateTestFile
        $state.CurrentStep | Should -Be 1
    }
}
