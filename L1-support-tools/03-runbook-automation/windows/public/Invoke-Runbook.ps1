function Invoke-Runbook {
    <#
    .SYNOPSIS
        Execute a markdown runbook.
    
    .DESCRIPTION
        Parses a markdown runbook and executes all PowerShell steps in sequence.
        Supports dry-run mode, resuming from a specific step, and handles failures with prompts.
    
    .PARAMETER FilePath
        Path to the markdown runbook file.
    
    .PARAMETER FromStep
        Step number to start from (1-indexed).
    
    .PARAMETER Resume
        Resume from the last saved state.
    
    .PARAMETER DryRun
        Show commands without executing.
    
    .PARAMETER ShowSteps
        Display all steps without executing.
    
    .EXAMPLE
        Invoke-Runbook -FilePath 'runbooks\restart-iis.md'
    
    .EXAMPLE
        Invoke-Runbook -FilePath 'runbooks\restart-iis.md' -DryRun
    
    .EXAMPLE
        Invoke-Runbook -FilePath 'runbooks\restart-iis.md' -Resume
    
    .EXAMPLE
        Invoke-Runbook -FilePath 'runbooks\restart-iis.md' -FromStep 3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,
        
        [Parameter()]
        [int]$FromStep = 1,
        
        [Parameter()]
        [switch]$Resume,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$ShowSteps
    )
    
    # Parse the runbook
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
    
    $total = $steps.Count
    
    # Handle show steps mode
    if ($ShowSteps) {
        return Show-RunbookSteps -FilePath $FilePath
    }
    
    # Handle resume
    if ($Resume) {
        $state = Get-RunbookState -FilePath $FilePath
        $FromStep = $state.CurrentStep + 1
        if ($FromStep -gt $total) {
            Write-Host "Runbook already completed. Use -FromStep 1 to restart." -ForegroundColor Yellow
            return $true
        }
        Write-Host "Resuming from step $FromStep" -ForegroundColor Cyan
    }
    
    # Validate FromStep
    if ($FromStep -lt 1) {
        $FromStep = 1
    }
    if ($FromStep -gt $total) {
        Write-Error "Starting step $FromStep is beyond the last step ($total)"
        return $false
    }
    
    if ($FromStep -gt 1) {
        Write-Host "Starting from step $FromStep of $total" -ForegroundColor Cyan
    }
    else {
        Write-Host "Executing $total step(s)..." -ForegroundColor Cyan
    }
    
    # Execute steps in sequence
    $forceContinue = $false
    $completedSteps = 0
    
    for ($i = ($FromStep - 1); $i -lt $total; $i++) {
        $step = $steps[$i]
        
        $result = Invoke-Step -Step $step -TotalSteps $total -DryRun:$DryRun
        $completedSteps++
        
        # Save state after each step (for resume functionality)
        if (-not $DryRun) {
            Save-RunbookState -FilePath $FilePath -StepNumber $step.Number -Success $result.Success
        }
        
        # Handle failures
        if (-not $result.Success -and -not $DryRun -and -not $forceContinue) {
            $choice = Prompt-OnFailure -Step $step -Result $result
            
            switch ($choice) {
                'a' {
                    Write-Host ""
                    Write-Host "[ABORTED] Runbook execution stopped." -ForegroundColor Red
                    return $false
                }
                'f' {
                    $forceContinue = $true
                    Write-Host "Continuing (ignoring future failures)..." -ForegroundColor Yellow
                }
                's' {
                    Write-Host "Skipping and continuing..." -ForegroundColor Yellow
                }
            }
        }
        
        # Small delay between steps for readability
        if (-not $DryRun -and $step.Number -lt $total) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    if ($DryRun) {
        Write-Host ""
        Write-Host "[DRY RUN] Would have executed $total step(s)" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "[OK] Runbook completed successfully" -ForegroundColor Green
    }
    
    return $true
}

function Prompt-OnFailure {
    <#
    .SYNOPSIS
        Prompt user for action when a step fails.
    
    .DESCRIPTION
        Displays failure information and prompts user to skip, force continue, or abort.
    
    .PARAMETER Step
        The step that failed.
    
    .PARAMETER Result
        The execution result dictionary.
    
    .OUTPUTS
        System.String - User choice: 's' (skip), 'f' (force continue), or 'a' (abort).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Step,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    Write-Host ""
    Write-Host "[!] Step $($Step.Number) failed with exit code $($Result.ExitCode)" -ForegroundColor Red
    
    if ($Result.Error) {
        Write-Host "Error: $($Result.Error.Substring(0, [Math]::Min(200, $Result.Error.Length)))" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[DID NOT EXPECT THIS] Stopping. Options:" -ForegroundColor Yellow
    Write-Host "  [s] Skip this step and continue"
    Write-Host "  [f] Force continue (ignore failures)"
    Write-Host "  [a] Abort execution"
    
    while ($true) {
        try {
            $choice = Read-Host ">"
            $choice = $choice.Trim().ToLower()
            
            if ($choice -in @('s', 'skip')) {
                return 's'
            }
            elseif ($choice -in @('f', 'force', 'continue')) {
                return 'f'
            }
            elseif ($choice -in @('a', 'abort', 'q', 'quit')) {
                return 'a'
            }
            else {
                Write-Host "Please enter 's' (skip), 'f' (force), or 'a' (abort)" -ForegroundColor Yellow
            }
        }
        catch [System.Management.Automation.PipelineStoppedException] {
            # Handle Ctrl+C
            Write-Host ""
            Write-Host "Aborting..." -ForegroundColor Red
            return 'a'
        }
    }
}
