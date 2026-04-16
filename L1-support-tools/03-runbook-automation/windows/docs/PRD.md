# Runbook Automation — PRD (Windows)

## 1. Concept & Vision

A CLI tool for managing markdown-based runbooks with embedded executable steps. Write a runbook in Markdown, mark steps with a special syntax, and execute them sequentially with one command — no more copy-paste from wikis into terminals.

Target feel: a shared playbook that lives in Git, looks good in any Markdown viewer, and actually runs.

## 2. Functional Spec

### 2.1 Runbook Format

```markdown
# Restart IIS Application Pool

## Steps

1. Check current status
   ```powershell
   Get-WebAppPoolState -Name "DefaultAppPool"
   ```
   Expected: Started or Stopped

2. Stop the application pool
   ```powershell
   Stop-WebAppPool -Name "DefaultAppPool"
   ```

3. Verify it stopped
   ```powershell
   Get-WebAppPoolState -Name "DefaultAppPool"
   ```
   Expected: Stopped

4. Start the application pool
   ```powershell
   Start-WebAppPool -Name "DefaultAppPool"
   ```

5. Confirm restart
   ```powershell
   Get-WebAppPoolState -Name "DefaultAppPool"
   ```
   Expected: Started

## Verification
All steps must return exit code 0.
```

### 2.2 Execution

```powershell
runbook run restart-iis-apppool.md
runbook run restart-iis-apppool.md --from-step 3  # resume from step 3
runbook run restart-iis-apppool.md --dry-run       # show what would execute
runbook run C:\runbooks\iis\restart-apppool.md
```

### 2.3 Step Syntax

Steps are fenced code blocks with `powershell` or `pwsh` language tag:

```markdown
```powershell
Restart-Service -Name "Spooler"
``````

Other code blocks (Python, YAML configs, SQL) are displayed but not executed.

### 2.4 Execution Behavior

- Each step runs in sequence
- Output is printed as-is (no capture unless `--capture` flag)
- Exit code 0 → next step
- Exit code != 0 → **stop and prompt**:

```
[STEP 3/5] Get-WebAppPoolState -Name "DefaultAppPool"
  Exit code: 1
  Output: The application pool does not exist.

[DID NOT EXPECT THIS] Stopping. Options:
  [s] Skip this step and continue
  [f] Force continue
  [a] Abort
>
```

### 2.5 Resume / Resume

```powershell
runbook run restart-iis-apppool.md --resume  # continue from last failed step
runbook run restart-iis-apppool.md --from-step 3  # jump to step 3
```

State saved to `%APPDATA%\runbook\state\<runbook-name>.json`:

```json
{"runbook": "restart-iis-apppool.md", "current_step": 3, "last_run": "ISO8601"}
```

### 2.6 Dry Run

`--dry-run` prints each step's command without executing, numbered:

```
[STEP 1/5] Check current status
  COMMAND: Get-WebAppPoolState -Name "DefaultAppPool"

[STEP 2/5] Stop the application pool
  COMMAND: Stop-WebAppPool -Name "DefaultAppPool"
  ...
```

### 2.7 Runbook Index

```powershell
runbook list                              # list all runbooks in .\runbooks\
runbook list --category iis               # filter by subdirectory
runbook search "AppPool"                  # search runbook names + content
runbook run --show-steps restart-iis.md   # show steps without running
```

## 3. Technical Approach

- **Language:** PowerShell 7+
- **Markdown parsing:** `ConvertFrom-Markdown` or custom regex parser
- **Shell execution:** PowerShell runspace
- **Runbook storage:** `runbooks/` directory — git-native
- **State:** `%APPDATA%\runbook\state\` JSON files

### File Structure

```
runbook-automation/
├── runbook.psd1
├── runbook.psm1
├── public/
│   ├── Invoke-Runbook.ps1
│   ├── Get-RunbookList.ps1
│   └── Search-Runbook.ps1
├── private/
│   ├── Parse-MarkdownSteps.ps1
│   ├── Invoke-Step.ps1
│   └── Save-RunbookState.ps1
├── runbooks/
│   ├── iis/
│   ├── services/
│   └── networking/
├── tests/
│   └── runbook.Tests.ps1
└── README.md
```

## 4. Success Criteria

- [ ] `runbook run <file.md>` executes all PowerShell steps in sequence
- [ ] Non-zero exit stops execution and prompts user
- [ ] `--resume` continues from last failed step
- [ ] `--dry-run` shows commands without executing
- [ ] `--from-step N` jumps to specific step
- [ ] `runbook list` and `runbook search` work
- [ ] State persisted between runs (resume survives Ctrl+C)

## 5. Out of Scope (v1)

- Non-PowerShell script steps (bash/cmd not supported on Windows version)
- Cloud integration (AWS, Azure runbooks)
- Web UI for runbook editing
- Multi-user runbook locking
- Conditionals / variables in runbooks
