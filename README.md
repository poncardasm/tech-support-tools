# Tech Support Tools

A collection of practical tools for technical support specialists. This repository houses a variety of scripts and utilities designed to simplify system diagnostics, troubleshooting, and day-to-day technical support tasks.

The goal of this repository is to serve as a centralized hub for practical tools that assist technical support specialists in their everyday tasks. By consolidating these utilities in one place, routine troubleshooting and system maintenance become more efficient and streamlined.

## Tools

- [**System Info Checker**](https://github.com/poncardasm/tech-support-tools/tree/main/system-info-checker)

  - A PowerShell script that gathers detailed system information including operating system, CPU, motherboard, memory, and GPU details. The tool generates a dated log file for easy reference.

- **Network Diagnostic Tool**

  - A script that tests network connectivity and retrieves information about network interfaces and current connections. A log file is also generated for analysis.

- **Disk Usage Analyzer**

  - A tool that checks disk space usage and identifies large files and folders, helping in the clean-up process.

- **Performance Monitor**

  - A script that monitors system performance metrics such as CPU usage, memory consumption, and response times for applications.

- **Software Inventory Tool**

  - A script that lists installed software on a system, including version numbers and installation dates.

- [**Diagnostic Test Runner**](#)

  - Automate a series of diagnostic tests to quickly identify common issues.
  - Check network connectivity (ping, DNS resolution, etc.).
  - Test hardware components (disk health, memory usage).
  - Verify critical software installations and configurations.
  - Log results to a file for further analysis.
  - Speeds up the troubleshooting process by running multiple tests at once and providing a clear report.

- **Clean Temp Files**
  - A script that deletes temporary files, cache, and other unnecessary data to free up disk space and improve system performance.

> More tools can be added as they are developed or contributed.

## Usage

Note: You might need to adjust PowerShell's execution policy to run scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
