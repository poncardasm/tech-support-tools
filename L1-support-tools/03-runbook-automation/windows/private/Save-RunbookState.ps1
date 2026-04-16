function Save-RunbookState {
    <#
    .SYNOPSIS
        Save the current runbook execution state.
    
    .DESCRIPTION
        Saves the current step number and timestamp to a JSON file in %APPDATA%\runbook\state\.
    
    .PARAMETER FilePath
        Path to the runbook file.
    
    .PARAMETER StepNumber
        Current step number to save.
    
    .PARAMETER Success
        Whether the last step was successful.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [int]$StepNumber,
        
        [bool]$Success = $true
    )
    
    $stateDir = Join-Path $env:APPDATA 'runbook\state'
    $null = New-Item -ItemType Directory -Force -Path $stateDir
    
    $runbookName = Split-Path -Path $FilePath -Leaf
    $stateFile = Join-Path $stateDir "$runbookName.json"
    
    $state = @{
        runbook    = $FilePath
        current_step = $StepNumber
        last_run   = (Get-Date -Format 'o')
        success    = $Success
    }
    
    $state | ConvertTo-Json | Set-Content -Path $stateFile
    Write-Verbose "State saved to $stateFile"
}

function Get-RunbookState {
    <#
    .SYNOPSIS
        Get the saved state for a runbook.
    
    .DESCRIPTION
        Retrieves the saved state for a runbook from %APPDATA%\runbook\state\.
    
    .PARAMETER FilePath
        Path to the runbook file.
    
    .OUTPUTS
        System.Collections.Hashtable - State object with CurrentStep property.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $runbookName = Split-Path -Path $FilePath -Leaf
    $stateFile = Join-Path $env:APPDATA "runbook\state\$runbookName.json"
    
    if (Test-Path -Path $stateFile) {
        $state = Get-Content -Path $stateFile | ConvertFrom-Json
        return @{
            CurrentStep = $state.current_step
            LastRun     = $state.last_run
            Success     = $state.success
        }
    }
    
    return @{
        CurrentStep = 1
        LastRun     = $null
        Success     = $true
    }
}

function Clear-RunbookState {
    <#
    .SYNOPSIS
        Clear the saved state for a runbook.
    
    .DESCRIPTION
        Removes the saved state file for a runbook from %APPDATA%\runbook\state\.
    
    .PARAMETER FilePath
        Path to the runbook file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $runbookName = Split-Path -Path $FilePath -Leaf
    $stateFile = Join-Path $env:APPDATA "runbook\state\$runbookName.json"
    
    if (Test-Path -Path $stateFile) {
        Remove-Item -Path $stateFile -Force
        Write-Host "State cleared for $runbookName" -ForegroundColor Green
    }
    else {
        Write-Host "No state found for $runbookName" -ForegroundColor Yellow
    }
}
