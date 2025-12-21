# Tech Support Tools

A collection of practical tools for technical support specialists. This repository houses a variety of scripts and utilities designed to simplify system diagnostics, troubleshooting, and day-to-day technical support tasks.

I created this repository with the goal to build a centralized hub for practical tools that assist technical support specialists in their everyday tasks. By consolidating these utilities in one place, routine troubleshooting and system maintenance become more efficient and streamlined.

## Tools

### Windows (PowerShell)

- [**CPU and RAM Usage**](./windows/cpu-ram-usage/)

  - Identifies the top 10 processes consuming the most CPU and RAM.

### macOS (Bash)

- [**Backup Script**](./macos/backup-script/)

  - Creates incremental backups using `rsync` with hard-link support.
  - Uses configuration file for customizable settings.
  - Manages retention of old backups based on specified retention period.
  - Generates timestamped log files for backup operations.

### Web Applications

- [**Slugify**](./web-app/slugify/)

  - Browser-based text transformation tool that converts text to lowercase and replaces spaces with hyphens (slug format).
  - Standalone HTML/CSS/JavaScript application with no dependencies.

## Usage

Note: You might need to adjust PowerShell's execution policy to run `.ps1` scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
