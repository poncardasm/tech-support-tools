# PowerShell Script Banner Template
# Replace placeholders with actual values when creating a new script

# ============================================================================
# CONSOLE BANNER (Interactive Mode)
# ============================================================================
# Place this AFTER parameter declarations, BEFORE main script logic
# Wrap in conditional if script has non-interactive modes

if (-not $NoInteractive) {  # Adjust condition based on your script's parameters
    Write-Host ""
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "|                          [**SCRIPT NAME HERE**]                             |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "| About        : [Brief description of what the script does. Can wrap to]    |"
    Write-Host "|                [multiple lines if needed for longer descriptions]           |"
    Write-Host "| Author       : Mchael Poncardas                                             |"
    Write-Host "| Email        : m@poncardas.com                                              |"
    Write-Host "| Version      : [X.Y]                                                        |"
    Write-Host "| Last Updated : [YYYY-MM-DD]                                                 |"
    Write-Host "| Requires     : [PowerShell X.X or later / Additional requirements]         |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host ""
    Read-Host -Prompt "Press 'Enter' key to run [Script Name]"
}


# ============================================================================
# LOG FILE BANNER (For scripts that generate log files)
# ============================================================================
# Place after log file initialization, at the beginning of log output
# Assumes you have a Write-Log function similar to system-info-checker

Write-Log "+-----------------------------------------------------------------------------+"
Write-Log "|                          [**SCRIPT NAME HERE**]                             |"
Write-Log "+-----------------------------------------------------------------------------+"
Write-Log "| About        : [Brief description of what the script does. Can wrap to]    |"
Write-Log "|                [multiple lines if needed for longer descriptions]           |"
Write-Log "| Author       : Mchael Poncardas                                             |"
Write-Log "| Email        : m@poncardas.com                                              |"
Write-Log "| Version      : [X.Y]                                                        |"
Write-Log "| Last Updated : [YYYY-MM-DD]                                                 |"
Write-Log "| Requires     : [PowerShell X.X or later / Additional requirements]         |"
Write-Log "+-----------------------------------------------------------------------------+"
Write-Log ""


# ============================================================================
# FORMATTING GUIDELINES
# ============================================================================

# Total Width: 79 characters (including + and | border characters)
# Content Width: 77 characters (between the | borders)

# Script Name:
#   - CENTER the text
#   - Use UPPERCASE
#   - Pad with spaces to center within 77 characters
#   - Example for "SYSTEM INFO CHECKER" (19 chars):
#     (77 - 19) / 2 = 29 spaces on each side
#     "|                             SYSTEM INFO CHECKER                             |"

# Field Labels:
#   - Left-align
#   - Use consistent spacing (pad to 12 chars + " : ")
#   - "About        : " (12 chars + " : ")
#   - "Author       : " (12 chars + " : ")
#   - "Email        : " (12 chars + " : ")
#   - "Version      : " (12 chars + " : ")
#   - "Last Updated : " (12 chars + " : ")
#   - "Requires     : " (12 chars + " : ")

# Multi-line Descriptions:
#   - First line starts at column 15 (after "About        : ")
#   - Continuation lines align at column 15 with 14 leading spaces
#   - Example:
#     "| About        : Performs comprehensive network connectivity tests and        |"
#     "|                generates a detailed diagnostic report.                      |"


# ============================================================================
# REPLACEMENT CHECKLIST
# ============================================================================

# When using this template:
# [ ] Replace [**SCRIPT NAME HERE**] with centered, uppercase script name
# [ ] Replace [Brief description...] with actual script description
# [ ] Replace [X.Y] with version number (1.0 for new scripts)
# [ ] Replace [YYYY-MM-DD] with current date
# [ ] Replace [PowerShell X.X...] with actual requirements
# [ ] Replace [Script Name] in Read-Host prompt with actual name
# [ ] Adjust the conditional check (if (-not $NoInteractive)) based on your script's parameters
# [ ] Verify total line width is exactly 79 characters
# [ ] Test that all text aligns properly

# ============================================================================
# EXAMPLE: Properly Formatted Banner
# ============================================================================

<#
    Write-Host ""
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "|                          NETWORK DIAGNOSTICS TOOL                           |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host "| About        : Performs comprehensive network connectivity tests and        |"
    Write-Host "|                generates a detailed diagnostic report.                      |"
    Write-Host "| Author       : Mchael Poncardas                                             |"
    Write-Host "| Email        : m@poncardas.com                                              |"
    Write-Host "| Version      : 1.0                                                          |"
    Write-Host "| Last Updated : 2025-12-26                                                   |"
    Write-Host "| Requires     : PowerShell 5.1 or later                                      |"
    Write-Host "+-----------------------------------------------------------------------------+"
    Write-Host ""
    Read-Host -Prompt "Press 'Enter' key to run Network Diagnostics"
#>
