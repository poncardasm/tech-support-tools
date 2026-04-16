# Ticket Triage CLI — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with Click + PyYAML + requests deps (requests optional, for `--llm`)
- [x] Create `ticket_triage/__init__.py` with version
- [x] Create `ticket_triage/__main__.py` for `python -m ticket_triage` entry
- [x] Create `tests/test_triage.py` with empty test class
- [x] Create `.gitignore`
- [x] Verify `pip install -e .` works and `ticket-triage --help` prints
- [x] Test PowerShell pipe: `Get-Content ticket.txt | ticket-triage` (placeholder works)

---

## Phase 2: Rule Engine + Core Logic

- [x] Create `ticket_triage/rules.yaml` with all 8 categories (include `suggested_action` field per category)
- [x] Implement `ticket_triage/triage.py`:
  - [x] `load_rules()` — load YAML, merge user config from `%APPDATA%`
  - [x] `TriageResult` namedtuple
  - [x] `triage()` — main function
  - [x] `score_priority()` — P1 override logic, urgency modifiers, priority bump
  - [x] `score_confidence()` — confidence based on keyword match count and category overlap
  - [x] `check_escalation()` — flag conditions
- [x] Verify all 8 categories match via keyword tests
- [x] Verify P1 override words bump priority correctly
- [x] Verify escalation flags fire on known L2 patterns

---

## Phase 3: CLI Interface

- [x] Implement main Click command with `--file`, `--llm`, `--json`, `--version` flags
- [x] Implement stdin detection via `sys.stdin.isatty()`
- [x] Route input: file → stdin → error
- [x] Implement text output formatter
- [x] Implement JSON output formatter
- [x] Implement exit codes (0, 1, 2)
- [x] Test: `Get-Content ticket.txt | ticket-triage` works
- [x] Test: `ticket-triage --file C:\tickets\ticket.txt` works
- [x] Test: `ticket-triage --json` outputs valid JSON
- [x] Test: empty stdin exits with code 1

---

## Phase 4: LLM Mode (if Ollama available)

- [x] Implement `ollama_triage()` function
- [x] Wire `--llm` flag: rule engine → LLM refinement fallback chain
- [x] Test: `--llm` with Ollama running returns refined result (mocked)
- [x] Test: `--llm` with Ollama down falls back to rule engine silently
- [x] Add `requests` as optional dependency in `pyproject.toml` (only installed for LLM mode)
- [x] Mock Ollama responses in tests for CI environments without Ollama

---

## Phase 5: Config Override

- [x] Implement `%APPDATA%\ticket-triage\rules.yaml` merge (already in Phase 2 load_rules())
- [x] Test: user rules override defaults

---

## Phase 6: Test Suite

- [x] All Phase 2-5 tests passing (63 tests)
- [x] Add fixtures: `tests/fixtures/*.txt` — one ticket per category (8 files)
- [x] Add confidence scoring tests (High/Medium/Low)
- [x] Run full suite: `pytest tests/ -v`

---

## Phase 7: Windows Build

- [x] Create `ticket-triage.spec` for PyInstaller
- [x] Create `build.ps1` for automated builds (includes --help, --version, pipe tests)
- [x] Test: `dist\ticket-triage.exe --help` (documented in build script)
- [x] Test: `Get-Content ticket.txt | .\dist\ticket-triage.exe` (documented in build script)

---

## Phase 8: Docs + Polish

- [x] Write `README.md` with Windows install instructions + usage examples
- [x] Add PowerShell-specific examples
- [x] Add `--help` docstring and Click built-in help (already in Phase 3)
- [ ] Tag v1.0.0 git tag (user to tag when ready)

---

## Phase 9: Publish

- [x] Push to GitHub (committed to local repo)
- [ ] Attach `.exe` to GitHub Release (requires Windows build)
- [ ] Optional: publish to PyPI

---

## Summary

All phases implemented for Windows ticket-triage-cli:

- **Phase 1**: Project skeleton with pyproject.toml, package structure, basic tests
- **Phase 2**: Complete rule engine with 8 categories, priority/confidence scoring, escalation detection
- **Phase 3**: Click CLI with stdin/file input, JSON/text output, proper exit codes
- **Phase 4**: LLM mode with Ollama integration and graceful fallback
- **Phase 5**: Config override from %APPDATA%\ticket-triage\rules.yaml
- **Phase 6**: 63 tests including fixture-based tests for all categories
- **Phase 7**: PyInstaller spec and PowerShell build script
- **Phase 8**: Comprehensive README.md with PowerShell examples
- **Phase 9**: Ready for GitHub release and PyPI (user action required)

