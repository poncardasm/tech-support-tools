<#
.SYNOPSIS
    Cleans temporary files from Windows system temp directories

.DESCRIPTION
    Removes files from user and system temp directories to free up disk space and maintain performance.
    Supports -WhatIf to preview what would be deleted without actually removing files.
    Returns summary information about the cleanup operation.

.PARAMETER Path
    Custom temp folder path(s) to clean. If not specified, cleans standard Windows temp locations:
    - User temp folder (%TEMP%)
    - System temp folder (C:\Windows\Temp)

.PARAMETER SkipSystemTemp
    If specified, skips cleaning the system temp folder (C:\Windows\Temp)

.EXAMPLE
    Clear-TempFiles.ps1
    Cleans both user and system temp folders with confirmation prompt

.EXAMPLE
    Clear-TempFiles.ps1 -Confirm:$false
    Cleans temp folders without confirmation prompt

.EXAMPLE
    Clear-TempFiles.ps1 -WhatIf
    Shows what files would be deleted without actually removing them

.EXAMPLE
    Clear-TempFiles.ps1 -Path "C:\CustomTemp" -Verbose
    Cleans a custom temp directory with verbose output

.EXAMPLE
    Clear-TempFiles.ps1 -SkipSystemTemp
    Cleans only the user temp folder, skipping system temp

.NOTES
    Author: Mchael Poncardas
    Version: 1.0.0
    Last Updated: 2024-12-22
    Requires: PowerShell 5.1 or later
    Requires Administrator: Recommended for cleaning system temp folder

.LINK
    https://github.com/poncardasm/tech-support-tools
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    [Parameter()]
    [switch]$SkipSystemTemp
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Some temp files may not be deletable."
    Write-Warning "For best results, run PowerShell as Administrator."
}

# Determine which folders to clean
if ($Path) {
    $tempFolders = $Path
} else {
    $tempFolders = @($env:TEMP)

    if (-not $SkipSystemTemp) {
        if ($isAdmin) {
            $tempFolders += "C:\Windows\Temp"
        } else {
            Write-Warning "Skipping system temp folder (C:\Windows\Temp) - requires Administrator privileges"
        }
    }
}

# Initialize results collection
$results = @()

foreach ($folder in $tempFolders) {
    Write-Verbose "Processing folder: $folder"

    # Validate folder exists
    if (-not (Test-Path -Path $folder)) {
        Write-Warning "Folder does not exist: $folder"
        continue
    }

    $itemsDeleted = 0
    $bytesFreed = 0
    $errors = 0

    try {
        # Get all items in the temp folder
        $items = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        $totalItems = ($items | Measure-Object).Count

        Write-Verbose "Found $totalItems items in $folder"

        foreach ($item in $items) {
            try {
                # Calculate size before deletion
                if (-not $item.PSIsContainer) {
                    $size = $item.Length
                } else {
                    $size = 0
                }

                # Attempt to remove item with ShouldProcess support
                if ($PSCmdlet.ShouldProcess($item.FullName, "Remove item")) {
                    Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
                    $itemsDeleted++
                    $bytesFreed += $size
                    Write-Debug "Deleted: $($item.FullName)"
                }
            }
            catch {
                $errors++
                Write-Debug "Could not delete: $($item.FullName) - $_"
                # Continue with next item - some files may be in use
            }
        }

        # Create result object for this folder
        $result = [PSCustomObject]@{
            Path = $folder
            ItemsDeleted = $itemsDeleted
            SpaceFreedMB = [math]::Round($bytesFreed / 1MB, 2)
            Errors = $errors
            Status = if ($errors -eq 0) { 'Success' } else { 'Partial' }
        }

        $results += $result

        Write-Information "Cleaned $folder - Removed $itemsDeleted items, freed $($result.SpaceFreedMB) MB"

        if ($errors -gt 0) {
            Write-Warning "$errors items could not be deleted from $folder (may be in use)"
        }
    }
    catch {
        Write-Error "Failed to clean folder '$folder': $_"

        $results += [PSCustomObject]@{
            Path = $folder
            ItemsDeleted = 0
            SpaceFreedMB = 0
            Errors = 1
            Status = 'Failed'
        }
    }
}

# Output summary
Write-Verbose "Cleanup operation completed"

# Return results object
$results
