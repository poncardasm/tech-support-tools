# Bulk Action Runner — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create PowerShell module structure (`bulk-run.psd1`, `bulk-run.psm1`)
- [x] Create `public/` directory with empty function files
- [x] Create `private/` directory for helpers
- [x] Verify `Import-Module ./bulk-run.psd1` works

---

## Phase 2: CSV Parsing

- [x] Test `Import-Csv` with sample CSV files
- [x] Handle missing columns gracefully
- [x] Support both comma and semicolon delimiters

---

## Phase 3: Operations

- [x] Implement `Invoke-BulkPasswordReset`
- [x] Implement `Invoke-BulkAddGroup`
- [x] Implement `Invoke-BulkEnableMailbox`
- [x] Implement `Invoke-BulkDeprovision`
- [x] All commands support `-WhatIf`

---

## Phase 4: Throttling

- [x] Implement `Start-Throttle` helper
- [x] Configure 500ms delay between rows
- [ ] Test with 100-row CSV

---

## Phase 5: Reporting

- [x] Implement `--report` CSV output
- [x] Include all 5 columns: email, operation, result, detail, timestamp
- [ ] Test report generation

---

## Phase 6: Testing

- [x] Create Pester test suite
- [x] Create test fixture CSV files
- [x] Test `-WhatIf` mode for all operations

---

## Phase 7: Documentation

- [x] Write `README.md` with PowerShell examples
- [x] Document CSV format requirements
- [x] Add troubleshooting section

---

## Phase 8: Publish

- [ ] Push to GitHub
- [ ] Optional: publish to PowerShell Gallery
