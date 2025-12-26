# Changelog

All notable changes to the System Info Checker script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1] - 2025-12-26

### Added

- ASCII banner header displaying script information in console output
- ASCII banner header at the top of generated log files
- Auto-open feature that launches the log file in default text editor after successful generation
- Author contact information (m@poncardas.com) in banner

### Fixed

- Write-Log function now properly accepts empty strings for blank line formatting
- Removed duplicate success message that was appearing twice in console output

---

## [2.0] - 2025-12-22

### Changed

- Complete refactor to meet PowerShell standards and best practices
- Improved code structure with proper parameter validation
- Enhanced error handling throughout the script

### Added

- Proper CmdletBinding support with verbose and debug output
- Parameters: LogPath, LogFileName, NoLogFile, PassThru
- Object output support for pipeline integration
- Ability to export system information as structured objects
- Comprehensive help documentation with examples

---

## [1.0] - Initial Release

### Added

- Basic system information gathering functionality
- Operating System details collection
- CPU specifications retrieval
- Motherboard information collection
- Memory (RAM) configuration with DDR version detection
- GPU/Graphics card details
- Log file generation with date-stamped filenames
- Interactive prompts for user interaction
