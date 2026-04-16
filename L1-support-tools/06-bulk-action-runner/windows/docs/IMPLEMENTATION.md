# Bulk Action Runner — Implementation Plan (Windows)

## 1. Project Setup

### 1.1 Prerequisites

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### 1.2 File Structure

```
bulk-action-runner/
├── bulk-run.psd1
├── bulk-run.psm1
├── public/
│   ├── Invoke-BulkPasswordReset.ps1
│   ├── Invoke-BulkAddGroup.ps1
│   ├── Invoke-BulkEnableMailbox.ps1
│   └── Invoke-BulkDeprovision.ps1
├── private/
│   ├── Connect-GraphSession.ps1
│   ├── Get-BulkConfig.ps1
│   ├── Write-BulkOutput.ps1
│   └── Start-Throttle.ps1
├── tests/
│   ├── bulk-run.Tests.ps1
│   └── fixtures/
│       └── users.csv
└── README.md
```

---

## 2. Core Functions

### 2.1 Invoke-BulkPasswordReset.ps1

```powershell
function Invoke-BulkPasswordReset {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        
        [string]$ReportPath,
        
        [switch]$DryRun
    )
    
    $users = Import-Csv $CsvPath
    $results = @()
    
    foreach ($user in $users) {
        $email = $user.email
        $tempPassword = New-TemporaryPassword
        
        if ($DryRun) {
            Write-BulkOutput -Type OK -Message "$email — would reset password"
            continue
        }
        
        try {
            Update-MgUser -UserId $email -PasswordProfile @{
                Password = $tempPassword
                ForceChangePasswordNextLogin = $true
            }
            Write-BulkOutput -Type OK -Message "$email — password reset, temp: $tempPassword"
            $results += [PSCustomObject]@{
                email = $email
                operation = 'password-reset'
                result = 'success'
                detail = ''
                timestamp = (Get-Date -Format 'o')
            }
        } catch {
            Write-BulkOutput -Type FAIL -Message "$email — error: $($_.Exception.Message)"
            $results += [PSCustomObject]@{
                email = $email
                operation = 'password-reset'
                result = 'failure'
                detail = $_.Exception.Message
                timestamp = (Get-Date -Format 'o')
            }
        }
        
        Start-Throttle -Milliseconds 500
    }
    
    if ($ReportPath) {
        $results | Export-Csv $ReportPath -NoTypeInformation
    }
}
```

### 2.2 Invoke-BulkAddGroup.ps1

```powershell
function Invoke-BulkAddGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        
        [Parameter(Mandatory)]
        [string]$Group,
        
        [string]$ReportPath,
        
        [switch]$DryRun
    )
    
    $users = Import-Csv $CsvPath
    $groupId = (Get-MgGroup -Filter "displayName eq '$Group'").Id
    
    foreach ($user in $users) {
        $email = $user.email
        
        if ($DryRun) {
            Write-BulkOutput -Type OK -Message "$email — would add to $Group"
            continue
        }
        
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $email
            Write-BulkOutput -Type OK -Message "$email — added to $Group"
        } catch {
            Write-BulkOutput -Type FAIL -Message "$email — error: $($_.Exception.Message)"
        }
        
        Start-Throttle -Milliseconds 500
    }
}
```

### 2.3 Start-Throttle.ps1

```powershell
function Start-Throttle {
    param([int]$Milliseconds = 500)
    Start-Sleep -Milliseconds $Milliseconds
}
```

---

## 3. Output Formatting

### 3.1 Write-BulkOutput.ps1

```powershell
function Write-BulkOutput {
    param(
        [ValidateSet('OK', 'FAIL', 'WARN')]
        [string]$Type,
        
        [string]$Message
    )
    
    $prefix = @{
        'OK'   = '[OK]   '
        'FAIL' = '[FAIL] '
        'WARN' = '[WARN] '
    }
    
    Write-Host "$($prefix[$Type])$Message"
}
```

---

## 4. Testing

### 4.1 bulk-run.Tests.ps1

```powershell
Describe "Bulk Action Runner" {
    BeforeAll {
        Import-Module ./bulk-run.psd1
    }
    
    Context "Invoke-BulkPasswordReset" {
        It "Should accept -WhatIf" {
            { Invoke-BulkPasswordReset -CsvPath tests/fixtures/users.csv -WhatIf } | Should -Not -Throw
        }
    }
}
```

---

## 5. Known Pitfalls (Windows)

1. **Rate limiting** — EntraID throttles at ~500 requests/min; 500ms delay is safe
2. **Large CSVs** — Use streaming for files > 10k rows
3. **Error handling** — Continue processing on individual failures
4. **Authentication** — Reuse Graph connection across operations

---

## 6. Out of Scope

- Rollback/undo operations
- Excel file input
- Web UI
