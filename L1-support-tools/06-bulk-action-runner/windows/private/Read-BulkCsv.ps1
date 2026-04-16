<#
.SYNOPSIS
    Parses a CSV file and validates required columns.

.DESCRIPTION
    Reads a CSV file and ensures it contains the 'email' column.
    Supports both comma and semicolon delimiters.

.PARAMETER CsvPath
    Path to the CSV file.

.PARAMETER RequiredColumns
    Array of column names that must exist in the CSV.

.EXAMPLE
    $users = Read-BulkCsv -CsvPath "users.csv"
#>
function Read-BulkCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        
        [string[]]$RequiredColumns = @('email')
    )
    
    # Verify file exists
    if (-not (Test-Path -Path $CsvPath)) {
        throw "CSV file not found: $CsvPath"
    }
    
    # Read the first line to detect delimiter
    $firstLine = Get-Content -Path $CsvPath -TotalCount 1
    
    # Determine delimiter based on first line
    $delimiter = ','
    if ($firstLine -match ';' -and $firstLine -notmatch ',') {
        $delimiter = ';'
    }
    
    try {
        $users = Import-Csv -Path $CsvPath -Delimiter $delimiter -ErrorAction Stop
    }
    catch {
        throw "Failed to parse CSV file: $CsvPath - $($_.Exception.Message)"
    }
    
    if (-not $users) {
        throw "CSV file is empty: $CsvPath"
    }
    
    # Validate required columns
    if ($users.Count -gt 0) {
        $firstRow = $users | Select-Object -First 1
        $actualColumns = $firstRow.PSObject.Properties.Name
        
        foreach ($column in $RequiredColumns) {
            if ($actualColumns -notcontains $column) {
                throw "Required column '$column' not found in CSV. Available columns: $($actualColumns -join ', ')"
            }
        }
    }
    
    # Validate email format for each row
    $emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    $invalidRows = @()
    
    foreach ($user in $users) {
        if ($user.email -notmatch $emailRegex) {
            $invalidRows += "Row with email '$($user.email)' has invalid format"
        }
    }
    
    if ($invalidRows.Count -gt 0) {
        throw "Invalid email format found:`n$($invalidRows -join "`n")"
    }
    
    return $users
}
