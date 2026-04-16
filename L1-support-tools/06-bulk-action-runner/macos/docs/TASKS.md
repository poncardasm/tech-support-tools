# Bulk Action Runner — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with msgraph-sdk + azure-identity deps
- [x] Create `bulk/__init__.py` with version
- [x] Create `bulk/__main__.py` for CLI entry
- [x] Verify `pip install -e .` works and `bulk-run --help` prints

---

## Phase 2: CSV Parsing

- [x] Implement CSV reader with `csv.DictReader`
- [x] Handle missing columns gracefully
- [x] Support both comma and semicolon delimiters

---

## Phase 3: Operations

- [x] Implement `password-reset` operation
- [x] Implement `add-group` operation
- [x] Implement `enable-mailbox` operation
- [x] Implement `deprovision` operation
- [x] All commands support `--dry-run`

---

## Phase 4: Throttling

- [x] Implement 500ms delay between rows
- [ ] Test with 100-row CSV
- [ ] Verify no 429 errors from Graph API

---

## Phase 5: Reporting

- [x] Implement `--report` CSV output
- [x] Include all 5 columns
- [ ] Test report generation

---

## Phase 6: Testing

- [x] Create `tests/test_operations.py`
- [x] Create test fixture CSV files
- [x] Test `--dry-run` mode

---

## Phase 7: Homebrew Packaging

- [x] Create `Formula/bulk-run.rb`
- [ ] Test Homebrew installation

---

## Phase 8: Documentation

- [x] Write `README.md`
- [x] Document CSV format
- [x] Add troubleshooting section

---

## Phase 9: Publish

- [ ] Push to GitHub
- [ ] Optional: publish to PyPI
