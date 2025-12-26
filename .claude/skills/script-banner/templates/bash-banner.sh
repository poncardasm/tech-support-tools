#!/bin/bash
# Bash Script Banner Template
# Replace placeholders with actual values when creating a new script

# ============================================================================
# CONSOLE BANNER
# ============================================================================
# Place this near the beginning of the script, after shebang and initial setup

echo ""
echo "+-----------------------------------------------------------------------------+"
echo "|                          [**SCRIPT NAME HERE**]                             |"
echo "+-----------------------------------------------------------------------------+"
echo "| About        : [Brief description of what the script does. Can wrap to]    |"
echo "|                [multiple lines if needed for longer descriptions]           |"
echo "| Author       : Mchael Poncardas                                             |"
echo "| Email        : m@poncardas.com                                              |"
echo "| Version      : [X.Y]                                                        |"
echo "| Last Updated : [YYYY-MM-DD]                                                 |"
echo "| Requires     : [Bash X.X or later / Additional requirements]               |"
echo "+-----------------------------------------------------------------------------+"
echo ""
read -p "Press Enter to continue..." </dev/tty


# ============================================================================
# LOG FILE BANNER (For scripts that write to log files)
# ============================================================================
# Place at the beginning of log file output
# Assumes log file variable is $LOG_FILE

{
    echo "+-----------------------------------------------------------------------------+"
    echo "|                          [**SCRIPT NAME HERE**]                             |"
    echo "+-----------------------------------------------------------------------------+"
    echo "| About        : [Brief description of what the script does. Can wrap to]    |"
    echo "|                [multiple lines if needed for longer descriptions]           |"
    echo "| Author       : Mchael Poncardas                                             |"
    echo "| Email        : m@poncardas.com                                              |"
    echo "| Version      : [X.Y]                                                        |"
    echo "| Last Updated : [YYYY-MM-DD]                                                 |"
    echo "| Requires     : [Bash X.X or later / Additional requirements]               |"
    echo "+-----------------------------------------------------------------------------+"
    echo ""
} >> "$LOG_FILE"


# ============================================================================
# FORMATTING GUIDELINES
# ============================================================================

# Total Width: 79 characters (including + and | border characters)
# Content Width: 77 characters (between the | borders)

# Script Name:
#   - CENTER the text
#   - Use UPPERCASE
#   - Pad with spaces to center within 77 characters
#   - Example for "BACKUP AUTOMATION TOOL" (22 chars):
#     (77 - 22) / 2 = 27.5 → 27 spaces left, 28 spaces right
#     "|                            BACKUP AUTOMATION TOOL                           |"

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
#     "| About        : Automates incremental backups using rsync with retention     |"
#     "|                policies and detailed logging.                               |"


# ============================================================================
# REPLACEMENT CHECKLIST
# ============================================================================

# When using this template:
# [ ] Replace [**SCRIPT NAME HERE**] with centered, uppercase script name
# [ ] Replace [Brief description...] with actual script description
# [ ] Replace [X.Y] with version number (1.0 for new scripts)
# [ ] Replace [YYYY-MM-DD] with current date
# [ ] Replace [Bash X.X...] with actual requirements
# [ ] Verify total line width is exactly 79 characters
# [ ] Test that all text aligns properly
# [ ] Ensure </dev/tty is used with read command for stdin compatibility

# ============================================================================
# NOTES
# ============================================================================

# The </dev/tty redirection in the read command ensures the prompt works
# correctly even when the script is run with input redirection.

# For scripts that should support silent/non-interactive modes,
# consider adding a --silent or --no-interactive flag:
#
# SILENT=false
# while [[ $# -gt 0 ]]; do
#     case $1 in
#         --silent|-s)
#             SILENT=true
#             shift
#             ;;
#     esac
# done
#
# if [ "$SILENT" = false ]; then
#     # Display banner here
# fi


# ============================================================================
# EXAMPLE: Properly Formatted Banner
# ============================================================================

: <<'EXAMPLE'
echo ""
echo "+-----------------------------------------------------------------------------+"
echo "|                            BACKUP AUTOMATION TOOL                           |"
echo "+-----------------------------------------------------------------------------+"
echo "| About        : Automates incremental backups using rsync with retention     |"
echo "|                policies and detailed logging.                               |"
echo "| Author       : Mchael Poncardas                                             |"
echo "| Email        : m@poncardas.com                                              |"
echo "| Version      : 1.0                                                          |"
echo "| Last Updated : 2025-12-26                                                   |"
echo "| Requires     : Bash 4.0 or later, rsync                                     |"
echo "+-----------------------------------------------------------------------------+"
echo ""
read -p "Press Enter to start backup process..." </dev/tty
EXAMPLE
