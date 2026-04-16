# Diagnostic Collector — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `collector.sh` main script
- [x] Create `diag/` Python module structure
- [x] Test basic script execution

---

## Phase 2: Collectors (Bash)

- [x] Implement system info collector
- [x] Implement disk info collector with thresholds
- [x] Implement memory info collector
- [x] Implement network info collector
- [x] Implement services collector (launchctl)
- [x] Implement log collector (log show)
- [x] Implement updates collector (softwareupdate, brew)
- [x] Implement active users collector

---

## Phase 3: Python Formatters

- [x] Implement output parser
- [x] Implement Markdown formatter
- [x] Implement HTML formatter
- [x] Implement JSON formatter

---

## Phase 4: Thresholds

- [x] Implement disk threshold detection (80%, 90%)
- [x] Implement memory threshold detection (90%)
- [x] Flag pending security updates

---

## Phase 5: Upload Feature

- [x] Implement `--upload` option
- [x] Support configurable endpoint

---

## Phase 6: Testing

- [x] Create Python test suite
- [x] Test threshold detection
- [x] Test formatters

---

## Phase 7: Homebrew Packaging

- [x] Create `Formula/diag-collect.rb`
- [x] Test Homebrew installation

---

## Phase 8: Distribution

- [x] Host script for `curl | bash` (collector.sh supports this)
- [x] Push to GitHub

---

## Phase 9: Documentation

- [x] Write `README.md`
- [x] Document all collected data
- [x] Add usage examples
