# Bulk Action Runner — PRD (macOS)

## 1. Concept & Vision

A CSV-powered bulk operations tool for L1 support. Upload a CSV of user identifiers, pick an operation, and execute in batch — password resets, group additions, mailbox enables. Things HelpDesk GUIs make painful and slow.

Target feel: the senior admin who says "give me the CSV" and gets it done in 30 seconds.

## 2. Functional Spec

### 2.1 Usage

```bash
bulk-run password-reset users.csv
bulk-run add-group users.csv --group "IT-All"
bulk-run enable-mailbox users.csv
bulk-run deprovision users.csv --reason "terminated"
bulk-run --dry-run enable-mailbox users.csv
bulk-run --report output.csv enable-mailbox users.csv
```

### 2.2 Input CSV Format

```csv
email,display_name,department
alice@company.com,Alice Smith,IT
bob@company.com,Bob Jones,Finance
carol@company.com,Carol White,IT
```

### 2.3 Operations

| Operation | What it does |
|---|---|
| `password-reset` | Set temp password + force change flag for each user |
| `add-group` | Add each user to specified AD group |
| `enable-mailbox` | Enable Exchange Online mailbox per user |
| `deprovision` | Disable account + remove group memberships |

### 2.4 Output

Per-user result printed to stdout:

```
[OK]   alice@company.com — password reset, temp: Xy#9aBc!
[OK]   bob@company.com — added to IT-All
[FAIL] carol@company.com — mailbox already enabled (code: 400)
```

### 2.5 Dry-run

`--dry-run` shows what would happen per row without making changes.

### 2.6 Report Export

`--report output.csv` saves results to CSV:

```csv
email,operation,result,detail,timestamp
alice@company.com,password-reset,success,,2024-03-01T14:00:00
bob@company.com,add-group,success,,2024-03-01T14:00:01
carol@company.com,enable-mailbox,failure,mailbox already enabled,2024-03-01T14:00:02
```

### 2.7 Throttling

Each operation runs with 500ms delay between rows to avoid triggering EntraID rate limits.

## 3. Technical Approach

- **Language:** Python 3.10+
- **CLI framework:** Click
- **Azure/EntraID:** `msgraph-sdk` + `azure-identity`
- **CSV parsing:** `csv` stdlib
- **Credentials:** `~/.config/bulk-action/creds.env`

### File Structure

```
bulk-action-runner/
├── pyproject.toml
├── bulk/
│   ├── __init__.py
│   ├── __main__.py
│   ├── operations.py
│   ├── report.py
│   └── config.py
├── tests/
│   └── test_operations.py
├── Formula/
│   └── bulk-run.rb
└── README.md
```

## 4. Success Criteria

- [ ] `bulk-run password-reset users.csv` processes 100-row CSV in < 60 seconds
- [ ] Per-row success/failure clearly reported
- [ ] `--dry-run` mode shows all planned operations without calling Graph API
- [ ] `--report` saves valid CSV with all 5 columns
- [ ] Rate limiting: 500ms between operations, no 429 errors from EntraID
- [ ] Failed rows don't stop the batch — process all rows, report all failures

## 5. Out of Scope (v1)

- Complex conditional operations per row (different groups per row)
- Non-CSV input (Excel, Google Sheets direct import)
- Undo/rollback operations
- GUI
