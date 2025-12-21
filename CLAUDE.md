# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a collection of cross-platform technical support tools organized by operating system. The tools are standalone scripts designed for system diagnostics, troubleshooting, and maintenance tasks.

## Repository Structure

The codebase is organized by platform:

- `windows/` - PowerShell scripts for Windows systems
- `macos/` - Bash scripts for macOS/Unix systems
- `web-app/` - Browser-based utilities (vanilla HTML/CSS/JS)

Each tool is self-contained in its own subdirectory with minimal dependencies.

## Platform-Specific Development

### Windows (PowerShell)

All Windows scripts use PowerShell `.ps1` format and follow these conventions:

- **Header format**: Include author and description comments at the top
  ```powershell
  <#
  Tool Name
  Author: Mchael Poncardas (https://github.com/poncardasm)
  Description: Brief description of what the script does.
  #>
  ```

- **Execution policy**: Users may need to run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` before running scripts

- **Interactive prompts**: Scripts use `Read-Host` for user interaction (start prompt and exit prompt)

- **Output format**: System diagnostic scripts generate dated log files using the format `YYYY-MM-DD-ToolName.log`

- **Logging pattern**: Use a `Write-Log` function that appends to file with `Out-File -FilePath $logFile -Append`

- **WMI/CIM queries**: Use `Get-CimInstance` for system information (Win32_OperatingSystem, Win32_Processor, Win32_BaseBoard, Win32_PhysicalMemory, Win32_VideoController)

### macOS (Bash)

Bash scripts for macOS follow these conventions:

- **Configuration-driven**: Scripts use separate `.conf` files to store user settings
  - Source config files with `source "$CONFIG_FILE"`
  - Check for config file existence before sourcing

- **Backup script architecture** (macos/backup-script/):
  - Uses `rsync` with `--link-dest` for incremental backups
  - Configuration in `backup.conf`:
    - `SOURCE_DIRS` - Space-separated list of directories to backup (quoted if containing spaces)
    - `BACKUP_ROOT` - Destination for backups
    - `RETENTION_DAYS` - Number of days to keep old backups
    - `EXCLUDE_PATTERNS` - Space-separated list of patterns to exclude
  - Creates timestamped backup directories: `YYYY-MM-DD_HH-MM`
  - Maintains a `latest` symlink to most recent backup
  - Generates timestamped log files in the backup root
  - Uses `find` with `-mtime +$RETENTION_DAYS` for cleanup

- **Error handling**: Use `set -e` to exit on errors

- **Array handling**: Convert space-separated config strings to arrays with `read -r -a ARRAY_NAME <<< "$CONFIG_VAR"`

### Web Applications

Web apps are static HTML/CSS/JS with no build process:

- Self-contained in single directories
- No frameworks or dependencies
- Can be opened directly in browser

## Testing Scripts

Since these are standalone scripts without a test framework:

- **Windows scripts**: Test manually by running in PowerShell. Check that log files are generated correctly and contain expected system information.

- **macOS backup script**: Always test with dummy data first before using on critical data. Verify:
  - Backup directories are created with correct timestamps
  - `rsync` properly links to previous backup
  - Retention cleanup works as expected
  - Log files capture all operations

- **Web apps**: Open `index.html` in a browser and verify functionality

## Configuration Files

The macOS backup script uses a configuration pattern that could be extended to other tools:

- Keep configuration separate from script logic
- Use clear variable names that match their purpose
- Document expected formats in the config file
- Always validate that config files exist before sourcing

## Common Patterns

### Log File Naming
- Format: `YYYY-MM-DD-ToolName.log` for Windows tools
- Format: `YYYY-MM-DD_HH-MM_backup.log` for macOS backup logs

### User Interaction
- Windows: Use `Read-Host -Prompt` for start and exit prompts
- Display success message showing the log file name

### Error Handling
- Bash: Use `set -e` and check for required files/directories
- PowerShell: Use `-ErrorAction SilentlyContinue` for expected failures (like cleaning temp files)

## Important Notes

- **No destructive operations without warnings**: The backup script README warns users to test with dummy data first
- **Cross-platform considerations**: Windows and macOS tools solve similar problems but use platform-specific approaches (PowerShell vs Bash, WMI vs standard Unix tools)
- **Minimal dependencies**: Tools should run with only built-in system utilities
