# Ticket Triage CLI — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with Click + PyYAML + requests deps (requests optional, for `--llm`)
- [x] Create `ticket_triage/__init__.py` with version
- [x] Create `ticket_triage/__main__.py` for `python -m ticket_triage` entry
- [x] Create `tests/test_triage.py` with empty test class
- [x] Create `.gitignore`
- [x] Verify `pip install -e .` works and `ticket-triage --help` prints

---

## Phase 2: Rule Engine + Core Logic

- [x] Create `ticket_triage/rules.yaml` with all 8 categories (include `suggested_action` field per category)
- [x] Implement `ticket_triage/triage.py`:
  - `load_rules()` — load YAML, merge user config
  - `TriageResult` namedtuple
  - `triage()` — main function
  - `score_priority()` — P1 override logic, urgency modifiers, priority bump
  - `score_confidence()` — confidence based on keyword match count and category overlap
  - `check_escalation()` — flag conditions
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
- [x] Test: `cat ticket.txt | ticket-triage` works
- [x] Test: `ticket-triage --file /path/to/ticket.txt` works
- [x] Test: `ticket-triage --json` outputs valid JSON
- [x] Test: empty stdin exits with code 1

---

## Phase 4: LLM Mode (if Ollama available)

- [ ] Implement `ollama_triage()` function
- [ ] Wire `--llm` flag: rule engine → LLM refinement fallback chain
- [ ] Test: `--llm` with Ollama running returns refined result
- [ ] Test: `--llm` with Ollama down falls back to rule engine silently
- [ ] Add `requests` as optional dependency in `pyproject.toml` (only installed for LLM mode)
- [ ] Mock Ollama responses in tests for CI environments without Ollama

---

## Phase 5: Config Override

- [x] Implement `~/.config/ticket-triage/rules.yaml` merge
- [x] Test: user rules override defaults

---

## Phase 6: Test Suite

- [x] All Phase 2-5 tests passing
- [x] Add fixtures: `tests/fixtures/*.txt` — one ticket per category
- [x] Add confidence scoring tests (High/Medium/Low)
- [x] Run full suite: `pytest tests/ -v`

---

## Phase 7: Homebrew Packaging

- [x] Create `Formula/ticket-triage.rb` Homebrew formula
- [ ] Test: `brew install -- Formula/ticket-triage.rb` works
- [ ] Test: `ticket-triage` command available after install
- [ ] Create tap repository (optional)

---

## Phase 8: Docs + Polish

- [x] Write `README.md` with macOS install instructions + usage examples
- [x] Add Homebrew installation instructions
- [x] Add `--help` docstring and Click built-in help
- [ ] Tag v1.0.0 git tag

---

## Phase 9: Publish

- [ ] Push to GitHub
- [ ] Optional: publish to PyPI
- [ ] Optional: create Homebrew tap
