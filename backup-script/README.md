# System Backup Scripts

This repository contains simple, script-based solutions for creating incremental backups of your data on different operating systems, specifically macOS and Windows.

The core approach utilizes incremental backups (saving disk space by linking to previous backups for unchanged files) and a retention policy to automatically clean up old backups.

## Repository Structure

The backup scripts and their associated configuration files are organized into directories based on the target operating system:

- `macos/`: Contains the bash script (`backup.sh`) and configuration file (`backup.conf`) for backing up data on macOS.
- `windows/`: Contains the PowerShell script (`windows_backup.ps1`) and configuration file (`windows_backup.conf` - _assuming you have one_) for backing up data on Windows.

Refer to the `README.md` file within each operating system directory (`macos/README.md` and `windows/README.md`) for specific instructions on configuration, usage, and details about the scripts in that directory.

## Configuration Files

Both the macOS and Windows backup scripts use separate configuration files to define settings like source directories, backup location, and retention policy. This keeps the script logic separate from your specific settings, making the scripts more reusable and easier to manage.

The specific variables and their formats are detailed in the `README.md` file located within each operating system's directory (e.g., `macos/README.md` for the macOS script).

## Warning

- Be extremely careful when setting the backup destination (configured in the respective `.conf` files). If misconfigured, the scripts could potentially delete important data. **Always test with dummy data and directories first.**
- Review the specific backup script and its configuration file for the operating system you are using to ensure it meets your needs and you understand its behavior before running it on critical data.

## Disclaimer

These scripts are provided as is, without warranty of any kind. Use them at your own risk. Review and customize the scripts and their configuration files before using them.
