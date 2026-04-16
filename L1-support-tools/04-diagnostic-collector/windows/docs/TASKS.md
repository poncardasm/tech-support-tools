# Diagnostic Collector — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create main `diag-collect.ps1` script
- [x] Create `modules/` directory structure
- [x] Create `formatters/` directory structure
- [x] Test basic script execution

---

## Phase 2: Collector Modules

- [x] Implement `Get-SystemInfo.ps1`
- [x] Implement `Get-DiskInfo.ps1` with threshold detection
- [x] Implement `Get-NetworkInfo.ps1`
- [x] Implement `Get-ServiceInfo.ps1`
- [x] Implement `Get-EventLogInfo.ps1`
- [x] Implement `Get-InstalledSoftwareInfo.ps1`
- [x] Implement `Get-UpdateInfo.ps1`
- [x] Implement `Get-ActiveUsersInfo.ps1`
- [x] Implement `Get-NetworkTests.ps1`

---

## Phase 3: Formatters

- [x] Implement `Format-Markdown.ps1`
- [x] Implement `Format-Html.ps1`
- [x] Implement `Format-Json.ps1`

---

## Phase 4: Thresholds

- [x] Implement disk space threshold detection (80%, 90%)
- [x] Implement memory threshold detection (90%)
- [x] Flag pending security updates
- [x] Flag failed services

---

## Phase 5: Upload Feature

- [x] Implement `--upload` option
- [x] Support configurable endpoint
- [x] Handle authentication

---

## Phase 6: Testing

- [x] Create Pester test suite
- [x] Test threshold detection
- [x] Test all collectors
- [x] Test formatters

---

## Phase 7: Documentation

- [x] Write `README.md`
- [x] Document all collected data
- [x] Add usage examples

---

## Phase 8: Distribution

- [x] Host script for `Invoke-WebRequest | Invoke-Expression`
- [x] Create signed version (optional)
- [x] Push to GitHub
