function Invoke-Step {
    <#
    .SYNOPSIS
        Execute a single runbook step.
    
    .DESCRIPTION
        Executes a single PowerShell code block from a runbook step.
        Displays step information, executes the code, and captures output and exit code.
    
    .PARAMETER Step
        The step object containing Number, Code, and Language.
    
    .PARAMETER TotalSteps
        Total number of steps (for display purposes).
    
    .PARAMETER DryRun
        If set, only displays what would be executed without actually running.
    
    .EXAMPLE
        $result = Invoke-Step -Step $step -TotalSteps 5 -DryRun
    
    .OUTPUTS
        System.Collections.Hashtable - Dictionary with ExitCode, Output, Error, and Success properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Step,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalSteps,
        
        [switch]$DryRun
    )
    
    # Display step info
    $codePreview = ($Step.Code -replace "`n", " ").Substring(0, [Math]::Min(50, $Step.Code.Length))
    if ($Step.Code.Length -gt 50) {
        $codePreview += '...'
    }
    
    Write-Host ""
    Write-Host "[STEP $($Step.Number)/$TotalSteps] $codePreview" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    
    if ($DryRun) {
        Write-Host "DRY RUN - Command would execute:" -ForegroundColor Yellow
        Write-Host "  $ $($Step.Code.Substring(0, [Math]::Min(80, $Step.Code.Length)))"
        if ($Step.Code.Length -gt 80) {
            Write-Host "  ... ($($Step.Code.Length) chars total)"
        }
        return @{
            ExitCode = 0
            Output   = ''
            Error    = ''
            Success  = $true
        }
    }
    
    # Execute the code
    try {
        # Create a script block from the code
        $scriptBlock = [scriptblock]::Create($Step.Code)
        
        # Capture output
        $output = $null
        $errorOutput = $null
        $exitCode = 0
        $success = $true
        
        # Execute in a new scope to isolate variables
        $output = & $scriptBlock 2>&1
        
        # Check for errors in the output stream
        if ($output -is [System.Management.Automation.ErrorRecord]) {
            $errorOutput = $output.Exception.Message
            $exitCode = 1
            $success = $false
        }
        elseif ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            $exitCode = $LASTEXITCODE
            $success = $false
        }
        
        # Print output if any
        if ($output -and -not ($output -is [System.Management.Automation.ErrorRecord])) {
            $outputString = ($output | Out-String).Trim()
            if ($outputString) {
                Write-Host $outputString
            }
        }
        
        # Print error if any
        if ($errorOutput) {
            Write-Host "  (stderr): $errorOutput" -ForegroundColor Red
        }
        
        return @{
            ExitCode = $exitCode
            Output   = if ($output -isnot [System.Management.Automation.ErrorRecord]) { ($output | Out-String).Trim() } else { '' }
            Error    = $errorOutput
            Success  = $success
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "  ERROR: $errorMsg" -ForegroundColor Red
        return @{
            ExitCode = 1
            Output   = ''
            Error    = $errorMsg
            Success  = $false
        }
    }
}

function Show-RunbookSteps {
    <#
    .SYNOPSIS
        Display all steps in a runbook without executing.
    
    .DESCRIPTION
        Parses a runbook and displays all executable steps without running them.
    
    .PARAMETER FilePath
        Path to the markdown runbook file.
    
    .EXAMPLE
        Show-RunbookSteps -FilePath 'runbooks\restart-iis.md'
    
    .OUTPUTS
        System.Boolean - True if steps were displayed, False on error.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $steps = Parse-MarkdownSteps -FilePath $FilePath
    }
    catch {
        Write-Error "Error parsing runbook: $_"
        return $false
    }
    
    if (-not $steps) {
        Write-Host "No executable steps found in runbook." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host ""
    Write-Host "Runbook: $FilePath" -ForegroundColor Green
    Write-Host "Total steps: $($steps.Count)"
    Write-Host ("=" * 60)
    
    foreach ($step in $steps) {
        $codeLines = $step.Code.Trim() -split "`n"
        $firstLine = $codeLines[0].Substring(0, [Math]::Min(60, $codeLines[0].Length))
        if ($codeLines.Count -gt 1) {
            $firstLine += " ... ($($codeLines.Count) lines)"
        }
        
        Write-Host ""
        Write-Host "[$($step.Number)] $firstLine" -ForegroundColor Cyan
        Write-Host "    Language: $($step.Language)"
    }
    
    Write-Host ""
    Write-Host ("=" * 60)
    return $true
}
