# Runbook Automation — PRD (macOS)

## 1. Concept & Vision

A CLI tool for managing markdown-based runbooks with embedded executable steps. Write a runbook in Markdown, mark steps with a special syntax, and execute them sequentially with one command — no more copy-paste from wikis into terminals.

Target feel: a shared playbook that lives in Git, looks good in any Markdown viewer, and actually runs.

## 2. Functional Spec

### 2.1 Runbook Format

```markdown
# Restart PostgreSQL Service

## Steps

1. Check current status
   ```bash
   systemctl status postgresql
   ```
   Expected: active (running) or inactive

2. Stop the service
   ```bash
   sudo systemctl stop postgresql
   ```

3. Verify it stopped
   ```bash
   systemctl status postgresql | grep "Active"
   ```
   Expected: inactive

4. Start the service
   ```bash
   sudo systemctl start postgresql
   ```

5. Confirm restart
   ```bash
   systemctl status postgresql | grep "Active"
   ```
   Expected: active (running)

## Verification
All steps must return exit code 0.
```

### 2.2 Execution

```bash
runbook run restart-postgresql.md
runbook run restart-postgresql.md --from-step 3  # resume from step 3
runbook run restart-postgresql.md --dry-run       # show what would execute
runbook run /path/to/runbooks/authentication/reset-vpn.md
```

### 2.3 Step Syntax

Steps are fenced code blocks with `bash`, `sh`, or `zsh` language tag:

```markdown
```bash
sudo systemctl restart postgresql
``````

Other code blocks (Python, YAML configs, SQL) are displayed but not executed.

### 2.4 Execution Behavior

- Each step runs in sequence
- Output is printed as-is (no capture unless `--capture` flag)
- Exit code 0 → next step
- Exit code != 0 → **stop and prompt**:

```
[STEP 3/5] systemctl status postgresql
  Exit code: 3
  Output: Unit postgresql.service could not be found.

[DID NOT EXPECT THIS] Stopping. Options:
  [s] Skip this step and continue
  [f] Force continue
  [a] Abort
>
```

### 2.5 Resume / Resume

```bash
runbook run restart-postgresql.md --resume  # continue from last failed step
runbook run restart-postgresql.md --from-step 3  # jump to step 3
```

State saved to `~/.config/runbook/state/<runbook-name>.json`:

```json
{"runbook": "restart-postgresql.md", "current_step": 3, "last_run": "ISO8601"}
```

### 2.6 Dry Run

`--dry-run` prints each step's command without executing, numbered:

```
[STEP 1/5] Check current status
  COMMAND: systemctl status postgresql

[STEP 2/5] Stop the service
  COMMAND: sudo systemctl stop postgresql
  ...
```

### 2.7 Runbook Index

```bash
runbook list                              # list all runbooks in ./runbooks/
runbook list --category authentication    # filter by subdirectory
runbook search "VPN"                      # search runbook names + content
runbook run --show-steps reset-vpn.md     # show steps without running
```

## 3. Technical Approach

- **Language:** Python 3.10+
- **CLI framework:** Click
- **Markdown parsing:** `markdown_it` or `mistune` for syntax parsing
- **Shell execution:** `subprocess.run()` with `shell=True`
- **Runbook storage:** `runbooks/` directory — git-native
- **State:** `~/.config/runbook/state/` JSON files

### File Structure

```
runbook-automation/
├── pyproject.toml
├── runbook/
│   ├── __init__.py
│   ├── __main__.py
│   ├── parser.py
│   ├── executor.py
│   ├── indexer.py
│   └── state.py
├── runbooks/
│   ├── authentication/
│   ├── networking/
│   └── infrastructure/
├── tests/
│   └── test_parser.py
├── Formula/
│   └── runbook.rb
└── README.md
```

## 4. Success Criteria

- [ ] `runbook run <file.md>` executes all bash steps in sequence
- [ ] Non-zero exit stops execution and prompts user
- [ ] `--resume` continues from last failed step
- [ ] `--dry-run` shows commands without executing
- [ ] `--from-step N` jumps to specific step
- [ ] `runbook list` and `runbook search` work
- [ ] State persisted between runs (resume survives Ctrl+C)

## 5. Out of Scope (v1)

- Non-bash script steps (PowerShell not supported on macOS version)
- Cloud integration (AWS, Azure runbooks)
- Web UI for runbook editing
- Multi-user runbook locking
- Conditionals / variables in runbooks
