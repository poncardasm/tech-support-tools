function Parse-MarkdownSteps {
    <#
    .SYNOPSIS
        Parse a markdown runbook and extract executable PowerShell steps.
    
    .DESCRIPTION
        Reads a markdown file and extracts fenced code blocks with powershell or pwsh
        language tags. Returns an array of step objects with number, code, and language.
    
    .PARAMETER FilePath
        Path to the markdown runbook file.
    
    .EXAMPLE
        $steps = Parse-MarkdownSteps -FilePath 'runbooks\restart-iis.md'
    
    .OUTPUTS
        System.Object[] - Array of step objects with Number, Code, and Language properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Validate file exists
    if (-not (Test-Path -Path $FilePath)) {
        throw "Runbook not found: $FilePath"
    }
    
    # Validate file extension
    if (-not $FilePath.EndsWith('.md')) {
        throw "Runbook must be a .md file: $FilePath"
    }
    
    # Read file content
    $content = Get-Content -Path $FilePath -Raw
    
    $steps = @()
    $stepNumber = 0
    
    # Pattern to match fenced code blocks with powershell/pwsh language
    # Matches ```powershell, ```pwsh (with optional info string)
    $pattern = '(?s)```(?:powershell|pwsh)\s*\n(.*?)```'
    
    $matches = [regex]::Matches($content, $pattern)
    
    foreach ($match in $matches) {
        $stepNumber++
        $code = $match.Groups[1].Value.Trim()
        
        # Determine language (powershell or pwsh)
        $language = if ($match.Value.StartsWith('```pwsh')) { 'pwsh' } else { 'powershell' }
        
        $steps += [PSCustomObject]@{
            Number   = $stepNumber
            Code     = $code
            Language = $language
        }
    }
    
    Write-Verbose "Parsed $stepNumber steps from $FilePath"
    return $steps
}

function Parse-RunbookMetadata {
    <#
    .SYNOPSIS
        Parse a runbook and return both steps and metadata.
    
    .DESCRIPTION
        Parses a markdown runbook and extracts the title, description, and steps.
    
    .PARAMETER FilePath
        Path to the markdown runbook file.
    
    .OUTPUTS
        System.Collections.Hashtable - Dictionary with Title, Description, Steps, Path, and StepCount.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $path = Resolve-Path $FilePath
    $content = Get-Content -Path $path -Raw
    
    # Extract title (first # heading)
    $titleMatch = [regex]::Match($content, '^#\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { [System.IO.Path]::GetFileNameWithoutExtension($path) }
    
    # Extract description (first paragraph after title)
    $description = ''
    if ($titleMatch.Success) {
        $afterTitle = $content.Substring($titleMatch.Index + $titleMatch.Length)
        $descMatch = [regex]::Match($afterTitle, '\n\n([^#\n].*?)\n\n', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($descMatch.Success) {
            $description = $descMatch.Groups[1].Value.Trim()
        }
    }
    
    $steps = Parse-MarkdownSteps -FilePath $path
    
    return @{
        Title       = $title
        Description = $description
        Steps       = $steps
        Path        = $path.Path
        StepCount   = $steps.Count
    }
}

function Test-RunbookValid {
    <#
    .SYNOPSIS
        Validate a runbook file for correctness.
    
    .DESCRIPTION
        Checks if a runbook file exists, has the correct extension,
        and contains at least one PowerShell code block.
    
    .PARAMETER FilePath
        Path to the markdown runbook file.
    
    .OUTPUTS
        System.Boolean - True if valid, False otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Check file exists
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    # Check extension
    if (-not $FilePath.EndsWith('.md')) {
        Write-Error "File must have .md extension"
        return $false
    }
    
    $content = Get-Content -Path $FilePath -Raw
    
    # Check for at least one PowerShell code block
    $powershellPattern = '```(?:powershell|pwsh)'
    if (-not ($content -match $powershellPattern)) {
        Write-Error "No PowerShell code blocks (powershell/pwsh) found"
        return $false
    }
    
    # Check for unclosed code blocks
    $openBlocks = ($content | Select-String -Pattern '```' -AllMatches).Matches.Count
    if ($openBlocks % 2 -ne 0) {
        Write-Error "Unclosed code block detected"
        return $false
    }
    
    return $true
}
