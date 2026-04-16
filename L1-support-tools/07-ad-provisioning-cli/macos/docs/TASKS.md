# AD/User Provisioning CLI — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with msgraph-sdk + azure-identity deps
- [x] Create `ad_provision/__init__.py` with version
- [x] Create `ad_provision/__main__.py` for CLI entry
- [x] Create `config/creds.env.example`
- [x] Verify `pip install -e .` works and `ad-provision --help` prints

---

## Phase 2: Microsoft Graph Integration

- [x] Implement `graph_client.py` with certificate-based auth
- [x] Implement `config.py` for loading credentials from `~/.config/`
- [ ] Test connection to EntraID with certificate

---

## Phase 3: Core Commands

- [x] Implement `new-user` command in Click
- [x] Implement `add-group` command
- [x] Implement `enable-mailbox` command
- [x] Implement `reset-password` command
- [x] Implement `deprovision` command
- [x] All commands support `--dry-run` flag

---

## Phase 4: Output Formatting

- [x] Implement `output.py` with consistent formatting
- [x] Test `[OK]`, `[FAIL]`, `[TEMP]`, `[WARN]` prefixes

---

## Phase 5: Testing

- [x] Create `tests/test_commands.py`
- [x] Test `--dry-run` mode for all commands
- [x] Mock Graph API calls for unit tests
- [x] Run `pytest tests/ -v`

---

## Phase 6: Homebrew Packaging

- [x] Create `Formula/ad-provision.rb`
- [ ] Test: `brew install -- Formula/ad-provision.rb` works

---

## Phase 7: Documentation

- [x] Write `README.md` with macOS-specific instructions
- [x] Document certificate setup
- [x] Add bash/zsh command examples

---

## Phase 8: Final Verification

- [x] All 31 tests passing
- [x] CLI commands working with --dry-run
- [x] Project structure complete
- [x] README documentation comprehensive
- [ ] Push to GitHub (requires repo setup)
- [ ] Optional: publish to PyPI
- [ ] Optional: create Homebrew tap
