# AD/User Provisioning CLI - Pester Test Suite
#Requires -Modules Pester
#Requires -Version 7.0

BeforeAll {
    # Get the module path
    $ModulePath = Join-Path $PSScriptRoot '..' 'ad-provision.psd1'
    $ModuleRoot = Join-Path $PSScriptRoot '..'
    
    # Import the module
    Import-Module $ModulePath -Force -ErrorAction Stop
}

AfterAll {
    # Remove the module after tests
    Remove-Module ad-provision -Force -ErrorAction SilentlyContinue
}

Describe "AD Provision Module" {
    Context "Module Import" {
        It "Should import the module without errors" {
            Get-Module ad-provision | Should -Not -BeNullOrEmpty
        }
        
        It "Should export all public functions" {
            $exportedFunctions = @(
                'New-ADProvisionUser'
                'Add-ADProvisionGroup'
                'Enable-ADProvisionMailbox'
                'Reset-ADProvisionPassword'
                'Remove-ADProvisionUser'
            )
            
            foreach ($function in $exportedFunctions) {
                Get-Command -Module ad-provision -Name $function | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "New-ADProvisionUser" {
    Context "Parameter Validation" {
        It "Should require Username parameter" {
            { New-ADProvisionUser -DisplayName "Test" -Email "test@company.com" -Department "IT" } |
                Should -Throw -ExpectedMessage "*Username*"
        }
        
        It "Should require DisplayName parameter" {
            { New-ADProvisionUser -Username "testuser" -Email "test@company.com" -Department "IT" } |
                Should -Throw -ExpectedMessage "*DisplayName*"
        }
        
        It "Should require Email parameter" {
            { New-ADProvisionUser -Username "testuser" -DisplayName "Test" -Department "IT" } |
                Should -Throw -ExpectedMessage "*Email*"
        }
        
        It "Should require Department parameter" {
            { New-ADProvisionUser -Username "testuser" -DisplayName "Test" -Email "test@company.com" } |
                Should -Throw -ExpectedMessage "*Department*"
        }
    }
    
    Context "WhatIf Mode" {
        It "Should not throw with -WhatIf" {
            { New-ADProvisionUser -Username "testuser" -DisplayName "Test User" `
                -Email "test@company.com" -Department "IT" -WhatIf } | Should -Not -Throw
        }
        
        It "Should output WhatIf messages" {
            $output = New-ADProvisionUser -Username "testuser" -DisplayName "Test User" `
                -Email "test@company.com" -Department "IT" -WhatIf 6>&1
            
            ($output | Where-Object { $_ -match "\[WhatIf\]" }) | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Add-ADProvisionGroup" {
    Context "Parameter Validation" {
        It "Should require Username parameter" {
            { Add-ADProvisionGroup -Group "IT-Admins" } |
                Should -Throw -ExpectedMessage "*Username*"
        }
        
        It "Should require Group parameter" {
            { Add-ADProvisionGroup -Username "testuser" } |
                Should -Throw -ExpectedMessage "*Group*"
        }
    }
    
    Context "WhatIf Mode" {
        It "Should not throw with -WhatIf" {
            { Add-ADProvisionGroup -Username "testuser" -Group "IT-Admins" -WhatIf } | Should -Not -Throw
        }
    }
}

Describe "Enable-ADProvisionMailbox" {
    Context "Parameter Validation" {
        It "Should require Username parameter" {
            { Enable-ADProvisionMailbox } | Should -Throw -ExpectedMessage "*Username*"
        }
    }
    
    Context "WhatIf Mode" {
        It "Should not throw with -WhatIf" {
            { Enable-ADProvisionMailbox -Username "testuser" -WhatIf } | Should -Not -Throw
        }
    }
}

Describe "Reset-ADProvisionPassword" {
    Context "Parameter Validation" {
        It "Should require Username parameter" {
            { Reset-ADProvisionPassword } | Should -Throw -ExpectedMessage "*Username*"
        }
    }
    
    Context "WhatIf Mode" {
        It "Should not throw with -WhatIf" {
            { Reset-ADProvisionPassword -Username "testuser" -WhatIf } | Should -Not -Throw
        }
    }
}

Describe "Remove-ADProvisionUser" {
    Context "Parameter Validation" {
        It "Should require Username parameter" {
            { Remove-ADProvisionUser } | Should -Throw -ExpectedMessage "*Username*"
        }
    }
    
    Context "WhatIf Mode" {
        It "Should not throw with -WhatIf" {
            { Remove-ADProvisionUser -Username "testuser" -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept optional Reason parameter with WhatIf" {
            { Remove-ADProvisionUser -Username "testuser" -Reason "Testing" -WhatIf } | 
                Should -Not -Throw
        }
        
        It "Should accept RemoveMailbox switch with WhatIf" {
            { Remove-ADProvisionUser -Username "testuser" -RemoveMailbox -WhatIf } | 
                Should -Not -Throw
        }
    }
}

Describe "Helper Functions" {
    Context "Write-ProvisionOutput" {
        It "Should output OK message with green prefix" {
            $output = Write-ProvisionOutput -Type OK -Message "Test OK" 6>&1
            $output | Should -BeLike "*[OK]*Test OK*"
        }
        
        It "Should output FAIL message with red prefix" {
            $output = Write-ProvisionOutput -Type FAIL -Message "Test FAIL" 6>&1
            $output | Should -BeLike "*[FAIL]*Test FAIL*"
        }
        
        It "Should output TEMP message with yellow prefix" {
            $output = Write-ProvisionOutput -Type TEMP -Message "Test TEMP" 6>&1
            $output | Should -BeLike "*[TEMP]*Test TEMP*"
        }
        
        It "Should output WARN message with yellow prefix" {
            $output = Write-ProvisionOutput -Type WARN -Message "Test WARN" 6>&1
            $output | Should -BeLike "*[WARN]*Test WARN*"
        }
    }
    
    Context "New-TemporaryPassword" {
        It "Should generate password of default length (16)" {
            $password = New-TemporaryPassword
            $password.Length | Should -Be 16
        }
        
        It "Should generate password of specified length" {
            $password = New-TemporaryPassword -Length 20
            $password.Length | Should -Be 20
        }
        
        It "Should contain at least one uppercase letter" {
            $password = New-TemporaryPassword
            $password | Should -Match "[A-Z]"
        }
        
        It "Should contain at least one lowercase letter" {
            $password = New-TemporaryPassword
            $password | Should -Match "[a-z]"
        }
        
        It "Should contain at least one number" {
            $password = New-TemporaryPassword
            $password | Should -Match "[0-9]"
        }
        
        It "Should contain at least one special character" {
            $password = New-TemporaryPassword
            $password | Should -Match "[!@#\$%^&\*]"
        }
    }
}

Describe "Configuration Loading" {
    Context "Get-ProvisionConfig" {
        It "Should throw when config file does not exist" {
            # Mock the env:APPDATA path to a non-existent location
            $originalAppData = $env:APPDATA
            $env:APPDATA = Join-Path $TestDrive "NonExistent"
            
            { Get-ProvisionConfig } | Should -Throw
            
            $env:APPDATA = $originalAppData
        }
        
        It "Should parse valid config file" {
            # Create a test config file
            $testAppData = Join-Path $TestDrive "ad-provision"
            New-Item -ItemType Directory -Path $testAppData -Force
            
            $configContent = @"
AZURE_CLIENT_ID=test-client-id
AZURE_TENANT_ID=test-tenant-id
AZURE_CERTIFICATE_THUMBPRINT=test-thumbprint
"@
            $configPath = Join-Path $testAppData "creds.env"
            Set-Content -Path $configPath -Value $configContent
            
            # Mock the env:APPDATA
            $originalAppData = $env:APPDATA
            $env:APPDATA = $TestDrive
            
            $config = Get-ProvisionConfig
            $config.AZURE_CLIENT_ID | Should -Be "test-client-id"
            $config.AZURE_TENANT_ID | Should -Be "test-tenant-id"
            $config.AZURE_CERTIFICATE_THUMBPRINT | Should -Be "test-thumbprint"
            
            $env:APPDATA = $originalAppData
        }
    }
}
