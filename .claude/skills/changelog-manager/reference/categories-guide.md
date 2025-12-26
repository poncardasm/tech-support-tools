# Changelog Categories Reference Guide

This guide provides detailed information about the standard changelog categories from [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), with specific examples for tech support scripts and tools.

---

## Category Overview

The six standard categories are:

1. **Added** - New features, parameters, or capabilities
2. **Changed** - Modifications to existing functionality
3. **Deprecated** - Features marked for future removal
4. **Removed** - Features that have been deleted
5. **Fixed** - Bug fixes and corrections
6. **Security** - Security-related changes or vulnerability patches

---

## 1. Added

### When to Use
Use `### Added` for any **new** functionality, features, parameters, or capabilities that didn't exist in the previous version.

### PowerShell Script Examples

**Parameters:**
- Added `-Quiet` parameter to suppress interactive banner and run silently
- Added `-Verbose` support for detailed operation logging
- Added `-ExportPath` parameter to specify custom output location
- Added `-Credential` parameter for remote authentication
- Added `-WhatIf` support for preview mode without making changes
- Added `-NoLogFile` switch to skip log file creation

**Features:**
- Added interactive ASCII banner displaying script information
- Added auto-open feature that launches log file after generation
- Added email notification when script completes
- Added progress bar for long-running operations
- Added support for remote computer diagnostics
- Added ability to export results in multiple formats (CSV, JSON, XML)

**Functionality:**
- Added comprehensive comment-based help documentation with examples
- Added pipeline support with structured object output
- Added error handling with detailed troubleshooting messages
- Added validation for all user inputs
- Added retry logic for network operations
- Added scheduled task creation helper

**Data Collection:**
- Added CPU temperature monitoring
- Added network adapter speed detection
- Added disk SMART status checking
- Added Windows Update history retrieval

### Bash Script Examples

- Added configuration file support for persistent settings
- Added backup retention policy with automatic cleanup
- Added incremental backup using rsync hard links
- Added email alerts for backup failures
- Added backup verification with checksum comparison
- Added bandwidth throttling option
- Added support for excluding files by pattern
- Added dry-run mode to preview changes without executing

### Web Application Examples

- Added dark mode toggle with persistent preference
- Added export to PDF functionality
- Added keyboard shortcuts for common actions
- Added auto-save feature every 30 seconds
- Added mobile-responsive layout

---

## 2. Changed

### When to Use
Use `### Changed` for **modifications** to existing functionality that alter behavior but don't add entirely new features or remove existing ones.

### PowerShell Script Examples

**Behavior Changes:**
- Changed default timeout from 30 seconds to 60 seconds
- Changed log file naming format to include timestamp
- Changed output to return structured objects instead of formatted text
- Changed parameter validation to be more strict
- Changed default sort order from ascending to descending

**Improvements:**
- Improved error messages for better clarity and troubleshooting guidance
- Improved performance of data collection by 50%
- Improved output formatting for better readability
- Improved memory efficiency in large data processing
- Improved logging with more detailed operation tracking

**Refactoring:**
- Refactored code to meet PowerShell best practices and standards
- Refactored to use CmdletBinding instead of basic parameters
- Refactored file operations to use native cmdlets instead of .NET methods
- Enhanced code structure with proper function separation

**Updates:**
- Updated default values to more reasonable settings
- Updated documentation with additional examples
- Updated banner to include author contact information
- Updated compatibility to require PowerShell 5.1 or later

### Bash Script Examples

- Changed backup directory structure to improve organization
- Changed rsync options for better performance
- Changed log rotation from daily to weekly
- Improved configuration file parsing with better error handling
- Enhanced notification system with more detailed status messages
- Updated retention policy calculation logic

### Web Application Examples

- Changed UI layout for improved usability
- Improved load time by optimizing asset delivery
- Updated styling to match modern design standards
- Enhanced form validation with real-time feedback

---

## 3. Deprecated

### When to Use
Use `### Deprecated` for features that **still work** but are planned for removal in a future version. This gives users advance warning to update their workflows.

### Examples

**Parameters:**
- Deprecated `-OldPath` parameter in favor of `-ExportPath` (will be removed in v3.0)
- Deprecated `-LegacyFormat` switch (use `-Format Classic` instead, removal planned for v2.0)
- Deprecated `-XMLExport` (use `-ExportPath file.xml` instead)

**Functionality:**
- Deprecated text-based output format (use structured objects instead)
- Deprecated built-in email functionality (use separate notification script)
- Deprecated Windows 7 support (will require Windows 10+ in v2.0)

**Syntax:**
- Deprecated positional parameters (use named parameters instead)
- Deprecated comma-separated list input (use array format instead)

### Best Practices for Deprecation

When deprecating features:
1. **Explain why** it's being deprecated
2. **Provide alternative** - what should users use instead?
3. **Indicate timeline** - when will it be removed?
4. **Keep it working** - deprecated features should still function
5. **Add warnings** - optionally display deprecation warnings when used

**Example:**
```markdown
### Deprecated
- Deprecated `-OldPath` parameter in favor of `-ExportPath` for consistency across scripts.
  The `-OldPath` parameter will be removed in version 3.0. Please update your scripts to use `-ExportPath`.
```

---

## 4. Removed

### When to Use
Use `### Removed` for features, parameters, or functionality that have been **completely deleted** from the script.

### Examples

**Parameters:**
- Removed deprecated `-LegacyFormat` parameter (use `-Format` instead)
- Removed `-QuickScan` parameter (functionality merged into default behavior)
- Removed `-Debug` parameter (use built-in PowerShell `-Debug` instead)

**Features:**
- Removed built-in FTP upload functionality (superseded by cloud storage integration)
- Removed Windows XP compatibility code
- Removed manual configuration prompts (now uses config file)

**Dependencies:**
- Removed dependency on external curl binary (now uses Invoke-WebRequest)
- Removed requirement for .NET Framework 3.5

**Support:**
- Removed support for Windows Server 2008
- Removed support for PowerShell 4.0 and earlier
- Removed 32-bit binary support

### When Removal is a Breaking Change

If removal breaks backward compatibility, bump the **MAJOR** version (1.x → 2.0):

```markdown
## [2.0] - 2025-12-26

### Removed
- **BREAKING**: Removed `-InputFile` parameter (use `-Path` parameter instead)
- **BREAKING**: Removed legacy XML output format (JSON is now the only supported format)
```

---

## 5. Fixed

### When to Use
Use `### Fixed` for **bug fixes** - anything that corrects incorrect behavior or resolves issues.

### PowerShell Script Examples

**Logic Errors:**
- Fixed incorrect CPU usage calculation for multi-core processors
- Fixed memory values being displayed in bytes instead of GB
- Fixed percentage calculation showing values over 100%
- Fixed timezone conversion producing incorrect timestamps

**Crashes/Errors:**
- Fixed crash when log directory doesn't exist
- Fixed "access denied" error when running without admin privileges
- Fixed null reference exception when optional parameter is not provided
- Fixed script terminating on non-critical errors

**Function Issues:**
- Fixed Write-Log function not properly accepting empty strings for blank lines
- Fixed validation not working correctly for UNC paths
- Fixed export function creating malformed CSV files
- Fixed parameter set conflicts when using certain parameter combinations

**Output Issues:**
- Fixed duplicate success message appearing twice in console
- Fixed log file timestamps being in wrong format
- Fixed banner misalignment on narrow console windows
- Fixed progress bar not clearing after completion

**Performance:**
- Fixed memory leak in data collection loop
- Fixed excessive disk I/O causing slow performance
- Fixed script hanging on network timeout

### Bash Script Examples

- Fixed rsync not preserving file permissions
- Fixed backup failing when source contains spaces in path
- Fixed log rotation deleting current day's log
- Fixed email notification not sending on some systems
- Fixed script failing when run via cron due to PATH issues
- Fixed incorrect free space calculation on large drives (>2TB)

### Web Application Examples

- Fixed form submission failing in Safari browser
- Fixed date picker not displaying correctly on mobile devices
- Fixed calculation errors when decimal values are used
- Fixed export button not working after page refresh

---

## 6. Security

### When to Use
Use `### Security` for any changes related to **security vulnerabilities**, exploits, or security enhancements.

### Examples

**Vulnerability Fixes:**
- Fixed command injection vulnerability in user input validation
- Fixed SQL injection risk in database query construction
- Fixed path traversal vulnerability in file operations
- Fixed XSS vulnerability in error message display

**Security Enhancements:**
- Updated credential handling to use SecureString instead of plain text
- Removed hardcoded API keys from source code
- Added input sanitization for all user-provided values
- Enhanced logging to redact sensitive information

**Authentication/Authorization:**
- Fixed privilege escalation vulnerability in admin check
- Updated authentication to require MFA for remote operations
- Enhanced access control for sensitive operations

**Data Protection:**
- Added encryption for sensitive data at rest
- Updated to use TLS 1.3 for network communications
- Enhanced file permissions to prevent unauthorized access

### Security Advisory Format

For security fixes, be specific enough to inform users but not so detailed that you provide exploit instructions:

**Good:**
```markdown
### Security
- Fixed input validation vulnerability that could allow unauthorized access. Users should update immediately.
```

**Avoid:**
```markdown
### Security
- Fixed vulnerability where entering `'; DROP TABLE users;--` in the username field executes arbitrary SQL
```

---

## Category Selection Decision Tree

Use this flowchart to choose the right category:

```
Is it a security issue?
├── YES → Security
└── NO
    └── Did something break that used to work?
        ├── YES → Fixed
        └── NO
            └── Is it completely new functionality?
                ├── YES → Added
                └── NO
                    └── Was something removed?
                        ├── YES (but still works with warning) → Deprecated
                        ├── YES (completely gone) → Removed
                        └── NO → Changed
```

---

## Combining Categories

A single version can (and often should) have multiple categories:

```markdown
## [1.2] - 2025-12-26

### Added
- Added `-Quiet` parameter for silent operation
- Added support for JSON export format

### Changed
- Improved error messages with more detailed troubleshooting steps
- Updated default timeout from 30s to 60s

### Fixed
- Fixed crash when network is unavailable
- Fixed incorrect timestamp in log files
```

---

## Writing Good Changelog Entries

### ✅ Good Examples

**Specific and actionable:**
- Fixed memory leak in data collection loop that occurred after 1000+ iterations
- Added `-Credential` parameter for authenticating to remote systems
- Changed default log retention from 7 days to 30 days

**Explains the impact:**
- Fixed CPU calculation for AMD processors showing incorrect core counts
- Removed Windows XP support to enable use of modern PowerShell features
- Added progress bar for operations taking longer than 5 seconds

### ❌ Bad Examples

**Too vague:**
- Fixed bugs
- Various improvements
- Updated code

**Too technical (user-facing changelog):**
- Refactored GetSystemInfo() method to use dependency injection pattern
- Replaced ArrayList with List<T> for better type safety
- Updated NuGet packages to latest versions

**Missing context:**
- Added parameter
- Changed behavior
- Fixed issue

---

## Special Cases

### Multiple Related Changes

If multiple changes are related, consider grouping with sub-bullets or combining:

**Option 1: Group related items**
```markdown
### Added
- Email notification system:
  - SMTP configuration support
  - HTML email templates
  - Attachment support for reports
```

**Option 2: Combine into one entry**
```markdown
### Added
- Email notification system with SMTP support, HTML templates, and report attachments
```

### Breaking Changes

Mark breaking changes clearly:

```markdown
## [2.0] - 2025-12-26

### Changed
- **BREAKING**: Renamed `-InputPath` to `-Path` for consistency
- **BREAKING**: Output format changed from text to structured objects

### Removed
- **BREAKING**: Removed support for PowerShell 4.0 and earlier
```

### Initial Release

For version 1.0, primarily use `### Added`:

```markdown
## [1.0] - Initial Release

### Added
- Core diagnostic functionality
- System information gathering
- Log file generation
- Interactive prompts
- Export to CSV
```

---

## Summary Quick Reference

| Category | When to Use | Version Impact |
|----------|-------------|----------------|
| **Added** | New features, parameters, capabilities | Minor (1.0 → 1.1) |
| **Changed** | Modifications to existing functionality | Minor (1.0 → 1.1) or Major if breaking |
| **Deprecated** | Features marked for future removal | Minor (1.0 → 1.1) |
| **Removed** | Features completely deleted | Major (1.0 → 2.0) if breaking |
| **Fixed** | Bug fixes and corrections | Minor (1.0 → 1.1) |
| **Security** | Security fixes or enhancements | Minor (1.0 → 1.1) but update ASAP |

---

## Remember

- **Be specific** - "Fixed memory leak in data collection" not "Fixed bugs"
- **Be user-focused** - Explain impact on users, not implementation details
- **Be honest** - Mark breaking changes clearly
- **Be organized** - Use categories consistently
- **Be timely** - Update changelog when you update the script

Following these guidelines ensures your changelogs are clear, useful, and professional!
