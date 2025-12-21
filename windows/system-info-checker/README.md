# System Info Checker

This PowerShell script gathers detailed system information—including operating system, CPU, motherboard, memory (RAM), and GPU details—and outputs the data into a dated log file.

## Features

- **Operating System:** Retrieves OS caption, version, build number, and system architecture.
- **CPU:** Gathers CPU name, number of cores, logical processors, and maximum clock speed.
- **Motherboard:** Collects motherboard manufacturer, product, version, and serial number.
- **Memory (RAM):** Displays total visible memory and detailed module information such as capacity, clock speeds, DDR version, and more.
- **GPU:** Captures GPU name, driver version, video processor, and approximate VRAM.

## Prerequisites

- **Operating System:** Windows
- **PowerShell Version:** 5.1 or newer
- Built-in Windows CIM/WMI modules

## Usage

1. **Copy code or Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/yourrepository.git
   ```

2. **Navigate to the Script Directory**

   Change to the directory where the script is located.

3. **Run the Script**

   Open PowerShell and execute:

   ```powershell
   .\sysinfo-checker.ps1
   ```

4. **Follow On-Screen Instructions**

   - Press "Enter" to start the system info check.
   - Once the process is complete, a log file (named with the current date, e.g., `2025-02-19-SystemInfo.log`) will be generated.
   - Press "Enter" again to exit.

## Security Considerations

- This script is designed to **only read** system information and create a log file.
- It does not modify system settings or send any data externally.
- As with any script from an external source, please review the code before running it.
