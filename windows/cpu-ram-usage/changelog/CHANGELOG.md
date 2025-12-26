# Changelog

All notable changes to the **Get-TopProcesses** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1] - 2025-12-26

### Added
- Interactive banner displaying script information (author, version, description)
- Quiet mode parameter (`-Quiet`) to suppress interactive prompts for automation and scripting
- Enhanced comment-based help with comprehensive examples
- Improved metadata in script header with email contact

### Changed
- Refactored code to meet PowerShell development standards
- Enhanced parameter validation and documentation
- Improved output formatting and verbose messages

---

## [1.0] - 2025-12-22

### Added
- Process grouping by name to consolidate duplicate instances
- Configurable top count parameter (`-TopCount`) with range validation (1-100)
- Sort by CPU or RAM usage with `-SortBy` parameter
- CSV export functionality via `-ExportPath` parameter
- Verbose logging support for troubleshooting
- Comprehensive error handling with try-catch blocks
- Returns structured PowerShell objects with Name, CPU(s), and RAM (MB) properties
- No administrator privileges required
- No external module dependencies
