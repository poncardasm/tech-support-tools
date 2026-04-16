function Get-RunbookList {
    <#
    .SYNOPSIS
        List all runbooks in the runbooks directory.
    
    .DESCRIPTION
        Scans the runbooks directory and returns a list of all markdown runbooks.
        Can filter by category (subdirectory).
    
    .PARAMETER Path
        Path to the runbooks directory. Defaults to .\runbooks.
    
    .PARAMETER Category
        Filter by subdirectory name.
    
    .EXAMPLE
        Get-RunbookList
    
    .EXAMPLE
        Get-RunbookList -Category 'iis'
    
    .OUTPUTS
        System.Object[] - Array of runbook objects with Name, Path, and Category.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.\runbooks',
        
        [Parameter()]
        [string]$Category
    )
    
    $searchPath = if ($Category) {
        Join-Path -Path $Path -ChildPath $Category
    }
    else {
        $Path
    }
    
    if (-not (Test-Path -Path $searchPath)) {
        Write-Warning "Runbooks directory not found: $searchPath"
        return @()
    }
    
    $runbooks = Get-ChildItem -Path $searchPath -Filter '*.md' -Recurse |
        ForEach-Object {
            # Calculate relative path from the runbooks root
            $relativePath = $_.FullName.Replace((Resolve-Path $Path).Path, '').TrimStart('\', '/')
            $categoryName = $_.Directory.Name
            
            [PSCustomObject]@{
                Name     = $_.BaseName
                Path     = $_.FullName
                RelativePath = $relativePath
                Category = $categoryName
                Size     = $_.Length
                Modified = $_.LastWriteTime
            }
        }
    
    return $runbooks
}

function Search-Runbook {
    <#
    .SYNOPSIS
        Search runbooks by name or content.
    
    .DESCRIPTION
        Searches for runbooks matching the query in filename or content.
    
    .PARAMETER Query
        Search query string.
    
    .PARAMETER Path
        Path to the runbooks directory. Defaults to .\runbooks.
    
    .PARAMETER SearchContent
        Also search in file content (slower but more thorough).
    
    .EXAMPLE
        Search-Runbook -Query 'restart'
    
    .EXAMPLE
        Search-Runbook -Query 'IIS' -SearchContent
    
    .OUTPUTS
        System.Object[] - Array of matching runbook objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Query,
        
        [Parameter()]
        [string]$Path = '.\runbooks',
        
        [Parameter()]
        [switch]$SearchContent
    )
    
    $runbooks = Get-RunbookList -Path $Path
    $results = @()
    $queryLower = $Query.ToLower()
    
    foreach ($runbook in $runbooks) {
        $match = $false
        $matchType = ''
        
        # Check name match
        if ($runbook.Name.ToLower().Contains($queryLower)) {
            $match = $true
            $matchType = 'name'
        }
        
        # Check category match
        if (-not $match -and $runbook.Category.ToLower().Contains($queryLower)) {
            $match = $true
            $matchType = 'category'
        }
        
        # Check content match if requested
        if (-not $match -and $SearchContent) {
            $content = Get-Content -Path $runbook.Path -Raw
            if ($content.ToLower().Contains($queryLower)) {
                $match = $true
                $matchType = 'content'
            }
        }
        
        if ($match) {
            $results += [PSCustomObject]@{
                Name      = $runbook.Name
                Path      = $runbook.Path
                Category  = $runbook.Category
                MatchType = $matchType
                Size      = $runbook.Size
                Modified  = $runbook.Modified
            }
        }
    }
    
    return $results
}

function Show-RunbookIndex {
    <#
    .SYNOPSIS
        Display a formatted list of all runbooks.
    
    .DESCRIPTION
        Shows a nicely formatted table of all available runbooks.
    
    .PARAMETER Path
        Path to the runbooks directory. Defaults to .\runbooks.
    
    .EXAMPLE
        Show-RunbookIndex
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.\runbooks'
    )
    
    $runbooks = Get-RunbookList -Path $Path
    
    if (-not $runbooks) {
        Write-Host "No runbooks found in $Path" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Available Runbooks" -ForegroundColor Green
    Write-Host ("=" * 70)
    
    # Group by category
    $grouped = $runbooks | Group-Object -Property Category
    
    foreach ($group in $grouped) {
        Write-Host ""
        Write-Host "[$($group.Name)]" -ForegroundColor Cyan
        Write-Host ("-" * 40)
        
        foreach ($runbook in $group.Group) {
            Write-Host "  $($runbook.Name)" -ForegroundColor White -NoNewline
            Write-Host " ($($runbook.RelativePath))" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Total: $($runbooks.Count) runbook(s)" -ForegroundColor Green
}
