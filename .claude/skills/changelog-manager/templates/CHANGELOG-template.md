# Changelog

All notable changes to the [**SCRIPT NAME**] will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0] - YYYY-MM-DD

### Added
- [Initial feature or functionality description]
- [Another initial feature]
- [Yet another feature]

---

## Template Instructions

Replace the following placeholders when creating a new changelog:

1. **[**SCRIPT NAME**]** - Replace with the actual script name (e.g., "System Info Checker", "Network Diagnostics Tool")
2. **YYYY-MM-DD** - Replace with today's date in ISO format (e.g., "2025-12-26")
3. **[Initial feature...]** - Replace with actual features of the initial release

## Example Sections for Updates

When updating the changelog for new versions, add sections like these at the TOP (after the header, before [1.0]):

```markdown
## [1.1] - 2025-12-27

### Added
- New parameter for custom output directory
- Support for JSON export format

### Fixed
- Resolved timeout issue with slow network connections

---
```

## Available Categories

Use these categories as needed (only include categories that have actual changes):

### Added
For new features, parameters, or functionality.

### Changed
For changes in existing functionality.

### Deprecated
For features that will be removed in upcoming releases.

### Removed
For removed features or functionality.

### Fixed
For any bug fixes.

### Security
For security-related changes or fixes.

## Semantic Versioning Guide

- **1.0 → 1.1**: Added features, bug fixes, improvements (backward compatible)
- **1.0 → 2.0**: Breaking changes, major rewrites, incompatible modifications

## Formatting Rules

1. **Date Format**: Always use `YYYY-MM-DD` (ISO 8601 format)
2. **Version Format**: Use `[X.Y]` in square brackets
3. **Separators**: Use `---` horizontal rules between version sections
4. **Bullet Points**: Use `-` for bullet points (not `*` or `+`)
5. **Category Order**: Added, Changed, Deprecated, Removed, Fixed, Security
6. **Indentation**: Keep categories flush left with `###`, bullet points indented with `-`

## Complete Example

Here's a complete example for a Network Diagnostics Tool:

```markdown
# Changelog

All notable changes to the Network Diagnostics Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2] - 2025-12-28

### Added
- Email notification support when diagnostics complete
- Custom DNS server specification parameter

### Changed
- Improved timeout handling for network tests
- Enhanced error messages with troubleshooting suggestions

### Fixed
- Resolved crash when network adapter is disabled
- Fixed incorrect bandwidth calculation on connections slower than 1 Mbps

---

## [1.1] - 2025-12-27

### Added
- Quiet mode parameter for automation and scripting
- Progress bar for long-running network tests
- Support for testing multiple hosts at once

### Fixed
- Fixed timeout not being respected in DNS lookup tests

---

## [1.0] - 2025-12-26

### Added
- Network connectivity testing with ping and traceroute
- DNS lookup functionality
- Port scanning for common services (80, 443, 22, 3389)
- Bandwidth speed test using built-in methods
- Log file generation with detailed diagnostic information
- Interactive banner displaying script information
- Export diagnostic results to JSON format
- Comprehensive comment-based help documentation
```

## Quick Reference

**Creating initial changelog for new script:**
1. Copy this template
2. Replace [**SCRIPT NAME**]
3. Replace YYYY-MM-DD with today's date
4. List all initial features under `### Added`
5. Use version `[1.0]`

**Adding an update to existing changelog:**
1. Add new section at TOP (after header)
2. Use incremented version number (1.0 → 1.1 or 2.0)
3. Use today's date
4. Categorize changes appropriately
5. Add `---` separator after the section

**Synchronize with script:**
- Update script's `.NOTES` Version and Last Updated
- Update script's banner Version and Last Updated (if applicable)
- Ensure all three locations match exactly
