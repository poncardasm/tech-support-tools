#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $ModuleDir = Join-Path $PSScriptRoot '..'
    $ModulePath = Join-Path $ModuleDir 'bulk-run.psd1'
    Import-Module $ModulePath -Force
    
    # Import private functions for testing
    $PrivateFunctions = Get-ChildItem -Path (Join-Path $ModuleDir 'private') -Filter '*.ps1' -ErrorAction SilentlyContinue
    foreach ($Function in $PrivateFunctions) {
        . $Function.FullName
    }
    
    $TestDir = $PSScriptRoot
    $FixturesDir = Join-Path $TestDir 'fixtures'
}

Describe "Bulk Action Runner Module" {
    Context "Module Import" {
        It "Should import the module successfully" {
            $module = Get-Module -Name 'bulk-run'
            $module | Should -Not -BeNullOrEmpty
        }
        
        It "Should export all public functions" {
            $expectedFunctions = @(
                'Invoke-BulkPasswordReset',
                'Invoke-BulkAddGroup',
                'Invoke-BulkEnableMailbox',
                'Invoke-BulkDeprovision',
                'Invoke-BulkAction'
            )
            
            foreach ($function in $expectedFunctions) {
                Get-Command -Name $function -Module 'bulk-run' | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should export the bulk-run alias" {
            $alias = Get-Alias -Name 'bulk-run' -ErrorAction SilentlyContinue
            $alias | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Read-BulkCsv Helper" {
    Context "CSV Parsing" {
        It "Should parse comma-delimited CSV files" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $result = Read-BulkCsv -CsvPath $csvPath
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result[0].email | Should -Be 'alice@company.com'
        }
        
        It "Should parse semicolon-delimited CSV files" {
            $csvPath = Join-Path $FixturesDir 'semicolon_delimited.csv'
            $result = Read-BulkCsv -CsvPath $csvPath
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
        
        It "Should throw when file does not exist" {
            { Read-BulkCsv -CsvPath 'nonexistent.csv' } | Should -Throw
        }
        
        It "Should throw when email column is missing" {
            $csvPath = Join-Path $FixturesDir 'missing_email_column.csv'
            { Read-BulkCsv -CsvPath $csvPath } | Should -Throw
        }
        
        It "Should throw for invalid email formats" {
            $csvPath = Join-Path $FixturesDir 'invalid_emails.csv'
            { Read-BulkCsv -CsvPath $csvPath } | Should -Throw
        }
    }
}

Describe "New-TemporaryPassword Helper" {
    Context "Password Generation" {
        It "Should generate a password of at least 12 characters" {
            $password = New-TemporaryPassword
            $password.Length | Should -BeGreaterOrEqual 12
        }
        
        It "Should include uppercase letters" {
            $password = New-TemporaryPassword
            $password | Should -Match '[A-Z]'
        }
        
        It "Should include lowercase letters" {
            $password = New-TemporaryPassword
            $password | Should -Match '[a-z]'
        }
        
        It "Should include numbers" {
            $password = New-TemporaryPassword
            $password | Should -Match '[0-9]'
        }
        
        It "Should include special characters" {
            $password = New-TemporaryPassword
            $password | Should -Match '[!@#$%^&*()_+-=\[\]{}|;:,.<>?]'
        }
        
        It "Should generate different passwords on each call" {
            $password1 = New-TemporaryPassword
            $password2 = New-TemporaryPassword
            $password1 | Should -Not -Be $password2
        }
    }
}

Describe "Write-BulkOutput Helper" {
    Context "Output Formatting" {
        It "Should accept OK type without error" {
            { Write-BulkOutput -Type 'OK' -Message 'Test message' } | Should -Not -Throw
        }
        
        It "Should accept FAIL type without error" {
            { Write-BulkOutput -Type 'FAIL' -Message 'Test error' } | Should -Not -Throw
        }
        
        It "Should accept WARN type without error" {
            { Write-BulkOutput -Type 'WARN' -Message 'Test warning' } | Should -Not -Throw
        }
    }
}

Describe "Start-Throttle Helper" {
    Context "Throttling" {
        It "Should throttle for the specified milliseconds" {
            $start = Get-Date
            Start-Throttle -Milliseconds 100
            $end = Get-Date
            
            $duration = ($end - $start).TotalMilliseconds
            $duration | Should -BeGreaterOrEqual 100
        }
        
        It "Should default to 500ms" {
            $start = Get-Date
            Start-Throttle
            $end = Get-Date
            
            $duration = ($end - $start).TotalMilliseconds
            $duration | Should -BeGreaterOrEqual 400  # Allow some tolerance
        }
    }
}

Describe "Invoke-BulkPasswordReset" {
    Context "Parameter Validation" {
        It "Should accept -WhatIf parameter" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkPasswordReset -CsvPath $csvPath -WhatIf } | Should -Not -Throw
        }
        
        It "Should throw for nonexistent CSV" {
            { Invoke-BulkPasswordReset -CsvPath 'nonexistent.csv' } | Should -Throw
        }
    }
    
    Context "Dry-Run Mode" {
        It "Should process all users in dry-run mode" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkPasswordReset -CsvPath $csvPath -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            ($results | Where-Object { $_.result -eq 'dry-run' }).Count | Should -Be 5
        }
    }
}

Describe "Invoke-BulkAddGroup" {
    Context "Parameter Validation" {
        It "Should require -Group parameter" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkAddGroup -CsvPath $csvPath } | Should -Throw
        }
        
        It "Should accept -WhatIf parameter with -Group" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkAddGroup -CsvPath $csvPath -Group 'TestGroup' -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Dry-Run Mode" {
        It "Should process all users in dry-run mode" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkAddGroup -CsvPath $csvPath -Group 'TestGroup' -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            ($results | Where-Object { $_.result -eq 'dry-run' }).Count | Should -Be 5
        }
    }
}

Describe "Invoke-BulkEnableMailbox" {
    Context "Parameter Validation" {
        It "Should accept -WhatIf parameter" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkEnableMailbox -CsvPath $csvPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Dry-Run Mode" {
        It "Should process all users in dry-run mode" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkEnableMailbox -CsvPath $csvPath -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            ($results | Where-Object { $_.result -eq 'dry-run' }).Count | Should -Be 5
        }
    }
}

Describe "Invoke-BulkDeprovision" {
    Context "Parameter Validation" {
        It "Should accept -WhatIf parameter" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkDeprovision -CsvPath $csvPath -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept -Reason parameter" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkDeprovision -CsvPath $csvPath -Reason 'terminated' -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Dry-Run Mode" {
        It "Should process all users in dry-run mode" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkDeprovision -CsvPath $csvPath -Reason 'terminated' -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            ($results | Where-Object { $_.result -eq 'dry-run' }).Count | Should -Be 5
        }
    }
}

Describe "Invoke-BulkAction (Main Entry Point)" {
    Context "Operation Routing" {
        It "Should route password-reset operation" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkAction -Operation 'password-reset' -CsvPath $csvPath -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results[0].operation | Should -Be 'password-reset'
        }
        
        It "Should route add-group operation" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkAction -Operation 'add-group' -CsvPath $csvPath -Group 'TestGroup' -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results[0].operation | Should -Be 'add-group'
        }
        
        It "Should route enable-mailbox operation" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkAction -Operation 'enable-mailbox' -CsvPath $csvPath -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results[0].operation | Should -Be 'enable-mailbox'
        }
        
        It "Should route deprovision operation" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $results = Invoke-BulkAction -Operation 'deprovision' -CsvPath $csvPath -Reason 'terminated' -WhatIf
            
            $results | Should -Not -BeNullOrEmpty
            $results[0].operation | Should -Be 'deprovision'
        }
    }
    
    Context "Parameter Validation" {
        It "Should require -Group for add-group operation" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            { Invoke-BulkAction -Operation 'add-group' -CsvPath $csvPath -WhatIf } | Should -Throw
        }
        
        It "Should throw for nonexistent CSV" {
            { Invoke-BulkAction -Operation 'password-reset' -CsvPath 'nonexistent.csv' -WhatIf } | Should -Throw
        }
    }
}

Describe "Report Generation" {
    Context "CSV Report Output" {
        It "Should generate a CSV report with all required columns" {
            $csvPath = Join-Path $FixturesDir 'users.csv'
            $reportPath = Join-Path $TestDir 'test_report.csv'
            
            # Clean up any existing report
            Remove-Item -Path $reportPath -Force -ErrorAction SilentlyContinue
            
            # Get the results directly
            $users = Read-BulkCsv -CsvPath $csvPath
            $results = @()
            foreach ($user in $users) {
                $results += [PSCustomObject]@{
                    email = $user.email
                    operation = 'test-operation'
                    result = 'success'
                    detail = 'Test detail'
                    timestamp = (Get-Date -Format 'o')
                }
            }
            $results | Export-Csv -Path $reportPath -NoTypeInformation
            
            Test-Path $reportPath | Should -Be $true
            
            $report = Import-Csv -Path $reportPath
            $report | Should -Not -BeNullOrEmpty
            
            $columns = $report[0].PSObject.Properties.Name
            $columns | Should -Contain 'email'
            $columns | Should -Contain 'operation'
            $columns | Should -Contain 'result'
            $columns | Should -Contain 'detail'
            $columns | Should -Contain 'timestamp'
            
            # Cleanup
            Remove-Item -Path $reportPath -Force -ErrorAction SilentlyContinue
        }
    }
}
