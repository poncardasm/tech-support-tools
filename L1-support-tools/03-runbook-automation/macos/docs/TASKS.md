# Runbook Automation — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with dependencies
- [x] Create `runbook/__init__.py`
- [x] Create `runbook/__main__.py`
- [x] Create `runbooks/` directory
- [x] Verify `pip install -e .` works

---

## Phase 2: Markdown Parsing

- [x] Implement `parse_runbook()` in `parser.py`
- [x] Extract `bash`, `sh`, `zsh` code blocks
- [x] Handle step numbering

---

## Phase 3: Step Execution

- [x] Implement `execute_step()` in `executor.py`
- [x] Execute shell commands
- [x] Capture output and exit code
- [x] Handle errors

---

## Phase 4: Runbook Execution

- [x] Implement `execute_runbook()`
- [x] Execute steps in sequence
- [x] Handle `--dry-run` mode
- [x] Handle `--from-step` option
- [x] Handle `--resume` option

---

## Phase 5: State Management

- [x] Implement `save_state()` and `load_state()`
- [x] Store state in `~/.config/runbook/state/`

---

## Phase 6: Error Handling

- [x] Implement prompt on failure
- [x] Skip, force continue, abort options
- [x] Handle Ctrl+C gracefully

---

## Phase 7: Runbook Index

- [x] Implement `list_runbooks()`
- [x] Implement `search_runbooks()`
- [x] Support category filtering

---

## Phase 8: CLI

- [x] Implement `run` command
- [x] Implement `list` command
- [x] Implement `search` command
- [x] Implement `status` command

---

## Phase 9: Testing

- [x] Create test suite
- [x] Create sample runbook fixtures
- [x] Test parsing
- [x] Test execution
- [x] Test state management

---

## Phase 10: Homebrew Packaging

- [x] Create `Formula/runbook.rb`
- [ ] Test Homebrew installation

---

## Phase 11: Documentation

- [x] Write `README.md`
- [x] Document runbook format
- [x] Add bash/zsh-specific examples

---

## Phase 12: Sample Runbooks

- [x] Create sample runbooks for common macOS tasks
- [x] Service restart (brew services)
- [x] Log clearing

---

## Phase 13: Publish

- [x] Implementation complete - ready for distribution
- [ ] Optional: PyPI
- [ ] Optional: Homebrew tap
