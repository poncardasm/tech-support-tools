# Log Dump Parser — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with dependencies
- [x] Create `log_parse/__init__.py`
- [x] Create `log_parse/__main__.py`
- [x] Verify `pip install -e .` works

---

## Phase 2: Format Detection

- [x] Implement file format detection
- [x] Detect syslog format
- [x] Detect journald JSON export
- [x] Detect JSON Lines
- [x] Detect Docker container logs
- [x] Detect Apache/Nginx logs
- [x] Fallback to plain text

---

## Phase 3: Parsers

- [x] Implement syslog parser
- [x] Implement journald parser
- [x] Implement JSON Lines parser
- [x] Implement Docker parser
- [x] Implement plain text parser

---

## Phase 4: Analysis

- [x] Implement error/warning grouping
- [x] Implement message normalization
- [x] Implement frequency counting
- [x] Implement statistics calculation

---

## Phase 5: Filters

- [x] Implement `--level` filter
- [x] Implement `--since` time filter
- [x] Implement `--until` time filter
- [x] Implement `--source` filter
- [x] Implement `--grep` search

---

## Phase 6: Output Formats

- [x] Implement text output
- [x] Implement JSON output
- [x] Implement CSV output

---

## Phase 7: CLI

- [x] Implement main Click command
- [x] Implement all options
- [x] Test stdin input

---

## Phase 8: Testing

- [x] Create test fixtures
- [x] Test format detection
- [x] Test parsing
- [x] Test analysis

---

## Phase 9: Homebrew Packaging

- [x] Create `Formula/log-parse.rb`
- [x] Test Homebrew installation

---

## Phase 10: Documentation

- [x] Write `README.md`
- [x] Document Unix-specific log formats
- [x] Add usage examples

---

## Phase 11: Publish

- [x] Push to GitHub
- [ ] Optional: PyPI
