# Log Dump Parser — PRD (macOS)

## 1. Concept & Vision

A CLI tool that takes a raw log file (any format: Syslog, journald, application log, Apache, Nginx, Docker, Kubernetes, JSON logs) and returns a cleaned, structured summary of errors and warnings grouped by frequency and severity. No more scrolling through 10,000 lines.

Target feel: a senior sysadmin sitting next to you saying "here's what's actually wrong — ignore the noise."

## 2. Functional Spec

### 2.1 Input

```bash
log-parse /var/log/system.log
log-parse --format syslog /var/log/syslog
log-parse --json /path/to/container-logs.json
log-parse --since "2024-01-01 00:00:00" app.log
cat raw_log.txt | log-parse
```

### 2.2 Supported Formats

| Format | Auto-detected by |
|---|---|
| Syslog (RFC 3164/5424) | timestamp + hostname + process pattern |
| journald (JSON export) | `__CURSOR` field |
| JSON Lines | one JSON object per line |
| Apache/Nginx access | IP + timestamp + request pattern |
| Docker/containerd | JSON with `log` field |
| Plain text (fallback) | best-effort regex extraction |

### 2.3 Output

```
=== Log Summary ===
File: /var/log/system.log
Lines parsed: 14,232 | Errors: 23 | Warnings: 87

[ERRORS — 23 total]
  12x Connection refused to db:5432
   7x Authentication failure for user admin
   4x Disk space threshold exceeded on /dev/sda1

[WARNINGS — 87 total]
  40x Session token expired (idle timeout)
  22x Retry attempt for external API call
  15x Memory usage above 80%

[STATISTICS]
  Time range: 2024-03-01 09:00:00 → 2024-03-01 17:30:00
  Top talker: sshd (143 entries)
  Top error source: postgres.service (18 errors)

[SUGGESTED ACTIONS]
  - "Connection refused to db" → check if PostgreSQL service is running
  - "Authentication failure" → review failed login audit log
  - "Disk space threshold" → run `df -h` on affected host
```

### 2.4 Filters

```
--level ERROR,WARN     # only show errors and warnings
--since "1 hour ago"   # relative time filter
--until "2024-03-01"   # absolute time filter
--source nginx         # filter by source/process name
--grep "connection"    # search within results
--top 10               # show only top 10 error patterns
```

### 2.5 Output Formats

- Text (default) — human-readable summary
- `--json` — structured JSON for pipelines
- `--csv` — flat CSV for import into Excel/Sheets

## 3. Technical Approach

- **Language:** Python 3.10+
- **CLI framework:** Click
- **Log parsing:** regex + `pyparsing` for structured formats
- **Auto-detection:** heuristic based on first 10 lines
- **No external APIs** — fully local

### File Structure

```
log-dump-parser/
├── pyproject.toml
├── log_parse/
│   ├── __init__.py
│   ├── __main__.py
│   ├── parser.py
│   ├── formatters.py
│   ├── patterns.yaml
│   └── patterns/
│       ├── syslog.py
│       ├── journald.py
│       └── docker.py
├── tests/
│   └── test_parser.py
├── Formula/
│   └── log-parse.rb
└── README.md
```

## 4. Success Criteria

- [ ] Auto-detects syslog, journald, JSON Lines, Apache, Docker formats
- [ ] Groups duplicate errors into frequency counts
- [ ] `--level`, `--since`, `--until`, `--source` filters work
- [ ] `--json` and `--csv` output valid formats
- [ ] 10k line log processed in < 2 seconds
- [ ] Graceful handling of malformed lines (skip + warn)

## 5. Out of Scope (v1)

- Real-time log streaming (tail -f support)
- Web UI
- Elasticsearch/Splunk integration
- Multi-file aggregation
