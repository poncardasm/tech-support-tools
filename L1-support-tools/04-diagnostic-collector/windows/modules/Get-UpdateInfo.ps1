# Windows Update Information Collector
# Gathers information about pending Windows updates

function Get-UpdateInfo {
    <#
    .SYNOPSIS
        Collects information about pending Windows updates.
    .OUTPUTS
        Array of hashtables containing update details.
    #>
    [CmdletBinding()]
    param()

    $updates = @()

    try {
        # Check if PSWindowsUpdate module is available
        $hasPSWindowsUpdate = Get-Module -ListAvailable -Name PSWindowsUpdate -ErrorAction SilentlyContinue

        if ($hasPSWindowsUpdate) {
            Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
            $pendingUpdates = Get-WUList -ErrorAction SilentlyContinue

            foreach ($update in $pendingUpdates) {
                $updates += @{
                    Title = $update.Title
                    KB = $update.KBArticleID
                    IsSecurity = $update.Categories -contains 'Security Updates' -or $update.Title -match 'Security'
                    Size = $update.Size
                    IsDownloaded = $update.IsDownloaded
                    IsMandatory = $update.IsMandatory
                }
            }
        }
        else {
            # Use Windows Update API directly via COM
            try {
                $session = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
                $searcher = $session.CreateUpdateSearcher()
                $searchResult = $searcher.Search("IsInstalled=0 and Type='Software'")

                foreach ($update in $searchResult.Updates) {
                    $isSecurity = $false
                    foreach ($category in $update.Categories) {
                        if ($category.Name -match 'Security') {
                            $isSecurity = $true
                            break
                        }
                    }

                    $updates += @{
                        Title = $update.Title
                        KB = if ($update.KBArticleIDs.Count -gt 0) { "KB" + $update.KBArticleIDs[0] } else { $null }
                        IsSecurity = $isSecurity
                        IsDownloaded = $update.IsDownloaded
                        IsMandatory = $update.IsMandatory
                        Size = [math]::Round($update.MaxDownloadSize / 1MB, 2)
                    }
                }
            }
            catch {
                # COM method failed
            }
        }

        # Add summary
        $securityCount = ($updates | Where-Object { $_.IsSecurity }).Count
        $updates += @{
            _Summary = @{
                TotalPending = ($updates | Where-Object { -not $_.StartsWith('_') }).Count
                SecurityUpdates = $securityCount
                PSWindowsUpdateAvailable = [bool]$hasPSWindowsUpdate
            }
        }
    }
    catch {
        Write-Warning "Failed to collect update info: $_"
        $updates += @{
            Error = "Update collection failed: $_"
            _Summary = @{
                TotalPending = 0
                SecurityUpdates = 0
                PSWindowsUpdateAvailable = $false
            }
        }
    }

    return $updates
}
