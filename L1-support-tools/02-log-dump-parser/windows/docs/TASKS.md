# Log Dump Parser — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with dependencies (click, python-evtx)
- [x] Create `log_parse/__init__.py`
- [x] Create `log_parse/__main__.py`
- [x] Verify `pip install -e .` works

---

## Phase 2: Format Detection

- [x] Implement file format detection
- [x] Detect Windows Event Log (.evtx)
- [x] Detect Windows Event XML
- [x] Detect JSON Lines
- [x] Detect IIS log format
- [x] Fallback to plain text

---

## Phase 3: Parsers

- [x] Implement EVTX parser (python-evtx)
- [x] Implement JSON Lines parser
- [x] Implement IIS log parser
- [x] Implement plain text parser
- [x] Implement syslog parser

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

- [x] Create test fixtures (sample EVTX, JSON)
- [x] Test format detection
- [x] Test parsing
- [x] Test analysis

---

## Phase 9: Windows Build

- [x] Create PyInstaller spec
- [ ] Build standalone executable
- [ ] Test `log-parse.exe`

---

## Phase 10: Documentation

- [x] Write `README.md`
- [x] Document Windows-specific log formats
- [x] Add usage examples
