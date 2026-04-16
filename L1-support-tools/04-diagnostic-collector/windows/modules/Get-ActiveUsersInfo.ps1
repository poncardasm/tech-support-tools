# Active Users Information Collector
# Gathers information about currently logged on users

function Get-ActiveUsersInfo {
    <#
    .SYNOPSIS
        Collects information about currently logged on users and sessions.
    .OUTPUTS
        Hashtable containing user session details.
    #>
    [CmdletBinding()]
    param()

    $result = @{
        ActiveSessions = @()
        RecentLogins = @()
        TotalActive = 0
    }

    try {
        # Get active sessions using query user (quser)
        try {
            $quserOutput = quser 2>$null
            if ($quserOutput) {
                # Parse quser output
                $lines = $quserOutput -split "`r?`n"
                for ($i = 1; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i].Trim()
                    if ($line -and -not $line.StartsWith('USERNAME')) {
                        # Parse the line (handling various formats)
                        $parts = $line -split '\s+'
                        if ($parts.Count -ge 3) {
                            $sessionInfo = @{
                                Username = $parts[0].Replace('>', '')  # Remove active session marker
                                SessionName = if ($parts[1] -match '^[rdp|console|tcp]') { $parts[1] } else { 'N/A' }
                                Id = if ($parts[1] -match '^[rdp|console|tcp]') { $parts[2] } else { $parts[1] }
                                State = if ($parts[1] -match '^[rdp|console|tcp]') { $parts[3] } else { $parts[2] }
                                IdleTime = if ($parts[1] -match '^[rdp|console|tcp]') { $parts[4] } else { $parts[3] }
                                LogonTime = if ($parts.Count -gt 5) { ($parts[5..($parts.Count-1)] -join ' ') } else { 'Unknown' }
                                IsActive = $line.Contains('>')
                            }
                            $result.ActiveSessions += $sessionInfo
                        }
                    }
                }
            }
        }
        catch {
            # quser might fail on some systems
        }

        # Alternative: Get logged on users via WMI
        try {
            $loggedOnUsers = Get-CimInstance -ClassName Win32_LoggedOnUser -ErrorAction SilentlyContinue
            $userSessions = @{}

            foreach ($session in $loggedOnUsers) {
                $domain = $session.Antecedent.Domain
                $username = $session.Antecedent.Name

                if ($username -and $username -ne 'SYSTEM' -and $username -ne 'NETWORK SERVICE' -and $username -ne 'LOCAL SERVICE') {
                    $key = "$domain\$username"
                    if (-not $userSessions.ContainsKey($key)) {
                        $userSessions[$key] = @{
                            Domain = $domain
                            Username = $username
                            SessionCount = 0
                        }
                    }
                    $userSessions[$key].SessionCount++
                }
            }

            $result.UniqueUsers = $userSessions.Values | ForEach-Object {
                @{
                    Username = $_.Username
                    Domain = $_.Domain
                    Sessions = $_.SessionCount
                }
            }
        }
        catch {
            # WMI method might fail
        }

        $result.TotalActive = $result.ActiveSessions.Count

        # Get current user
        $result.CurrentUser = @{
            Username = $env:USERNAME
            Domain = $env:USERDOMAIN
            IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
    }
    catch {
        Write-Warning "Failed to collect active user info: $_"
        $result.Error = "User collection failed: $_"
    }

    return $result
}
