# Get-TopProcesses

**Author:** Mchael Poncardas <br>
**Version:** 1.0.0 <br>
**Platform:** Windows PowerShell 5.1+

## Overview

Get-TopProcesses retrieves running processes and identifies the top resource consumers by CPU or RAM usage. Processes with multiple instances are automatically grouped and their resource usage is aggregated, providing a clear picture of which applications are consuming the most system resources.

## Features

- ✅ Groups duplicate processes to show total resource usage per application
- ✅ Flexible sorting by CPU or RAM
- ✅ Configurable number of results (1-100)
- ✅ Optional CSV export functionality
- ✅ Verbose output for troubleshooting
- ✅ No administrator privileges required
- ✅ No external dependencies

## Usage

### Basic Usage

Display top 10 processes by CPU usage:

```powershell
.\Get-TopProcesses.ps1
```

### Sort by RAM

```powershell
.\Get-TopProcesses.ps1 -SortBy RAM
```

### Get More Results

```powershell
.\Get-TopProcesses.ps1 -TopCount 20
```

### Export to CSV

```powershell
.\Get-TopProcesses.ps1 -TopCount 15 -ExportPath "C:\Reports\top-processes.csv"
```

### Verbose Output

```powershell
.\Get-TopProcesses.ps1 -Verbose
```

### Combined Parameters

```powershell
.\Get-TopProcesses.ps1 -TopCount 25 -SortBy RAM -ExportPath "C:\Temp\ram-usage.csv" -Verbose
```

## Parameters

| Parameter  | Type   | Required | Default | Description                               |
| ---------- | ------ | -------- | ------- | ----------------------------------------- |
| TopCount   | int    | No       | 10      | Number of top processes to return (1-100) |
| SortBy     | string | No       | CPU     | Sort by 'CPU' or 'RAM'                    |
| ExportPath | string | No       | -       | Path to export results as CSV             |

## Output

Returns PowerShell objects with the following properties:

- **Name**: Process name
- **CPU(s)**: Total CPU time in seconds (rounded to 2 decimal places)
- **RAM (MB)**: Total RAM usage in megabytes (rounded to 2 decimal places)

### Example Output

```md
Name CPU(s) RAM (MB)

---

chrome 145.23 1024.50
Code 89.12 856.25
pwsh 45.67 312.75
Slack 32.45 445.80
Teams 28.90 678.30
```

## Use Cases

- **Performance Troubleshooting**: Identify which applications are causing high CPU or memory usage
- **System Monitoring**: Regular checks to understand resource consumption patterns
- **Capacity Planning**: Export historical data to CSV for analysis
- **User Support**: Quickly identify resource-intensive applications during help desk calls

## Requirements

- Windows operating system
- PowerShell 5.1 or later
- No administrator privileges required
- No external modules required

## Notes

- Processes are grouped by name, so multiple instances (e.g., multiple Chrome tabs) are consolidated
- CPU time is cumulative since process start, not current CPU percentage
- RAM values represent current working set memory
- Use `-Verbose` flag to see detailed operation steps

## Troubleshooting

**No output returned:**

- Check that you have permission to query process information
- Try running with `-Verbose` to see diagnostic messages

**Export path error:**

- Ensure the directory exists before exporting
- Check write permissions on the target directory

**Process information incomplete:**

- Some system processes may not report CPU usage if recently started
- This is normal Windows behavior

## Version History

- **1.0.0** (2025-12-22): Initial release
  - Process grouping by name
  - Configurable top count and sort order
  - CSV export functionality
  - Verbose logging support

## License

Part of the [tech-support-tools](https://github.com/poncardasm/tech-support-tools) collection.
