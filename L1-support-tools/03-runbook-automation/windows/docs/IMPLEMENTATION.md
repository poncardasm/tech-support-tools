# Runbook Automation — Implementation Plan (Windows)

## 1. Project Setup

```powershell
cd runbook-automation
# No Python needed - pure PowerShell
```

## 2. File Structure

```
runbook-automation/
├── runbook.psd1
├── runbook.psm1
├── public/
│   ├── Invoke-Runbook.ps1
│   ├── Get-RunbookList.ps1
│   └── Search-Runbook.ps1
├── private/
│   ├── Parse-MarkdownSteps.ps1
│   ├── Invoke-Step.ps1
│   └── Save-RunbookState.ps1
├── runbooks/
│   ├── iis/
│   ├── services/
│   └── networking/
├── tests/
│   └── runbook.Tests.ps1
└── README.md
```

---

## 3. Core Functions

### 3.1 Parse-MarkdownSteps.ps1

```powershell
function Parse-MarkdownSteps {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    $steps = @()
    $stepNumber = 0
    
    # Match fenced code blocks with powershell/pwsh language
    $pattern = '(?s)```(?:powershell|pwsh)\s*\n(.*?)```'
    $matches = [regex]::Matches($content, $pattern)
    
    foreach ($match in $matches) {
        $stepNumber++
        $steps += [PSCustomObject]@{
            Number = $stepNumber
            Code = $match.Groups[1].Value.Trim()
        }
    }
    
    return $steps
}
```

### 3.2 Invoke-Step.ps1

```powershell
function Invoke-Step {
    param(
        [int]$StepNumber,
        [int]$TotalSteps,
        [string]$Code,
        [switch]$DryRun
    )
    
    Write-Host "[STEP $StepNumber/$TotalSteps] $Code"
    
    if ($DryRun) {
        Write-Host "  COMMAND: $Code"
        return @{ ExitCode = 0; Output = '' }
    }
    
    try {
        $output = Invoke-Expression $Code 2>&1
        $exitCode = $LASTEXITCODE ?? 0
        
        Write-Host "  Output: $output"
        
        return @{
            ExitCode = $exitCode
            Output = $output
        }
    } catch {
        return @{
            ExitCode = 1
            Output = $_.Exception.Message
        }
    }
}
```

### 3.3 Invoke-Runbook.ps1

```powershell
function Invoke-Runbook {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [int]$FromStep = 1,
        [switch]$Resume,
        [switch]$DryRun
    )
    
    $steps = Parse-MarkdownSteps -FilePath $FilePath
    $totalSteps = $steps.Count
    
    # Handle resume
    if ($Resume) {
        $state = Get-RunbookState -FilePath $FilePath
        $FromStep = $state.CurrentStep
    }
    
    $stepIndex = $FromStep - 1
    
    for ($i = $stepIndex; $i -lt $totalSteps; $i++) {
        $step = $steps[$i]
        
        $result = Invoke-Step `
            -StepNumber $step.Number `
            -TotalSteps $totalSteps `
            -Code $step.Code `
            -DryRun:$DryRun
        
        # Save state
        Save-RunbookState -FilePath $FilePath -StepNumber $step.Number
        
        # Handle failure
        if ($result.ExitCode -ne 0 -and -not $DryRun) {
            Write-Host ""
            Write-Host "[DID NOT EXPECT THIS] Stopping. Options:"
            Write-Host "  [s] Skip this step and continue"
            Write-Host "  [f] Force continue"
            Write-Host "  [a] Abort"
            
            $choice = Read-Host ">"
            
            switch ($choice.ToLower()) {
                's' { continue }
                'f' { continue }
                'a' { return }
            }
        }
    }
    
    Write-Host "[OK] Runbook completed successfully"
}
```

### 3.4 Save-RunbookState.ps1

```powershell
function Save-RunbookState {
    param(
        [string]$FilePath,
        [int]$StepNumber
    )
    
    $stateDir = Join-Path $env:APPDATA 'runbook\state'
    $null = New-Item -ItemType Directory -Force -Path $stateDir
    
    $stateFile = Join-Path $stateDir (Split-Path $FilePath -Leaf) + '.json'
    
    $state = @{
        runbook = $FilePath
        current_step = $StepNumber
        last_run = (Get-Date -Format 'o')
    }
    
    $state | ConvertTo-Json | Set-Content $stateFile
}

function Get-RunbookState {
    param([string]$FilePath)
    
    $stateFile = Join-Path $env:APPDATA "runbook\state\$($FilePath | Split-Path -Leaf).json"
    
    if (Test-Path $stateFile) {
        return Get-Content $stateFile | ConvertFrom-Json
    }
    
    return @{ CurrentStep = 1 }
}
```

---

## 4. Runbook List/Search

### 4.1 Get-RunbookList.ps1

```powershell
function Get-RunbookList {
    param(
        [string]$Path = '.\runbooks',
        [string]$Category
    )
    
    $searchPath = if ($Category) {
        Join-Path $Path $Category
    } else {
        $Path
    }
    
    Get-ChildItem -Path $searchPath -Filter '*.md' -Recurse |
        ForEach-Object {
            [PSCustomObject]@{
                Name = $_.BaseName
                Path = $_.FullName
                Category = $_.Directory.Name
            }
        }
}
```

---

## 5. Testing

```powershell
# tests/runbook.Tests.ps1
Describe "Runbook Automation" {
    BeforeAll {
        Import-Module ./runbook.psd1
    }
    
    Context "Parse-MarkdownSteps" {
        It "Should extract PowerShell steps" {
            $steps = Parse-MarkdownSteps -FilePath 'tests/fixtures/sample.md'
            $steps.Count | Should -BeGreaterThan 0
        }
    }
}
```

---

## 6. Known Pitfalls (Windows)

1. **Execution policy** — May need `Set-ExecutionPolicy RemoteSigned`
2. **Administrator privileges** — Some runbooks need elevation
3. **Path spaces** — Handle paths with spaces correctly
4. **Interactive steps** — Can't handle interactive prompts

---

## 7. Out of Scope

- Bash/sh support (use macOS/Linux version)
- Cloud runbook integration
- Web UI
