# Runbook Automation — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create PowerShell module structure (`runbook.psd1`, `runbook.psm1`)
- [x] Create `public/` directory
- [x] Create `private/` directory
- [x] Create `runbooks/` directory
- [x] Verify `Import-Module ./runbook.psd1` works

---

## Phase 2: Markdown Parsing

- [x] Implement `Parse-MarkdownSteps.ps1`
- [x] Extract `powershell` and `pwsh` code blocks
- [x] Handle step numbering

---

## Phase 3: Step Execution

- [x] Implement `Invoke-Step.ps1`
- [x] Execute PowerShell code
- [x] Capture output and exit code
- [x] Handle errors

---

## Phase 4: Runbook Execution

- [x] Implement `Invoke-Runbook.ps1`
- [x] Execute steps in sequence
- [x] Handle `--dry-run` mode
- [x] Handle `--from-step` option
- [x] Handle `--resume` option

---

## Phase 5: State Management

- [x] Implement `Save-RunbookState.ps1`
- [x] Implement `Get-RunbookState.ps1`
- [x] Implement `Clear-RunbookState.ps1`
- [x] Store state in `%APPDATA%\runbook\state\`

---

## Phase 6: Error Handling

- [x] Implement prompt on failure
- [x] Skip, force continue, abort options
- [x] Handle Ctrl+C gracefully

---

## Phase 7: Runbook Index

- [x] Implement `Get-RunbookList.ps1`
- [x] Implement `Search-Runbook.ps1`
- [x] Support category filtering

---

## Phase 8: Testing

- [x] Create Pester test suite
- [x] Create sample runbook fixtures
- [x] Test parsing
- [x] Test execution
- [x] Test state management

---

## Phase 9: Documentation

- [x] Write `README.md`
- [x] Document runbook format
- [x] Add PowerShell-specific examples

---

## Phase 10: Sample Runbooks

- [x] Create sample runbooks for common Windows tasks
- [x] IIS restart
- [x] Service restart
- [x] Event log clearing

---

## Phase 11: Publish

- [ ] Push to GitHub
- [ ] Optional: publish to PowerShell Gallery
