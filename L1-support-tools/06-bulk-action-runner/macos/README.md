# Bulk Action Runner

A CSV-powered bulk operations tool for L1 support. Upload a CSV of user identifiers, pick an operation, and execute in batch — password resets, group additions, mailbox enables. Things HelpDesk GUIs make painful and slow.

> Target feel: the senior admin who says "give me the CSV" and gets it done in 30 seconds.

## Installation

### Via Homebrew (recommended)

```bash
brew tap l1-support-tools/tap
brew install bulk-run
```

### Via pip

```bash
pip install bulk-action-runner
```

### Development Install

```bash
git clone https://github.com/L1-support-tools/bulk-action-runner.git
cd bulk-action-runner/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Configuration

Before using the tool, configure your Azure credentials:

```bash
mkdir -p ~/.config/bulk-action
cat > ~/.config/bulk-action/creds.env << EOF
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
EOF
```

## Usage

### CSV Format

Your input CSV must have at least an `email` column:

```csv
email,display_name,department
alice@company.com,Alice Smith,IT
bob@company.com,Bob Jones,Finance
carol@company.com,Carol White,IT
```

The tool also supports semicolon-delimited CSV files for European locales.

### Commands

#### Password Reset

Reset passwords for all users in the CSV:

```bash
bulk-run password-reset users.csv
```

Output:
```
[OK  ] alice@company.com — password reset, temp: Xy#9aBc!
[OK  ] bob@company.com — password reset, temp: Ab#7cDe!
[OK  ] carol@company.com — password reset, temp: Zx#5fGh!
```

#### Add to Group

Add all users to an Azure AD group:

```bash
bulk-run add-group users.csv --group "IT-All"
```

Output:
```
[OK  ] alice@company.com — added to IT-All
[OK  ] bob@company.com — added to IT-All
[OK  ] carol@company.com — added to IT-All
```

#### Enable Mailbox

Enable Exchange Online mailbox for each user:

```bash
bulk-run enable-mailbox users.csv
```

#### Deprovision

Disable account and remove group memberships:

```bash
bulk-run deprovision users.csv --reason "terminated"
```

### Dry Run Mode

Preview what operations would be performed without making any changes:

```bash
bulk-run password-reset users.csv --dry-run
bulk-run add-group users.csv --group "IT-All" --dry-run
```

### Report Generation

Save detailed results to a CSV file:

```bash
bulk-run password-reset users.csv --report output.csv
```

The report includes:
- `email` — User's email address
- `operation` — Operation performed
- `result` — success or failure
- `detail` — Additional details (temp password, error message)
- `timestamp` — ISO 8601 timestamp

### Combining Options

You can combine `--dry-run` and `--report` for testing:

```bash
bulk-run password-reset users.csv --dry-run --report test-report.csv
```

## Features

- **Four Operations**: password-reset, add-group, enable-mailbox, deprovision
- **Dry-run Mode**: Preview operations without making changes
- **CSV Reports**: Export detailed results with timestamps
- **Rate Limiting**: 500ms delay between operations to avoid EntraID throttling
- **Error Resilience**: Failed rows don't stop the batch — all rows are processed
- **Flexible CSV**: Supports both comma and semicolon delimiters

## Troubleshooting

### Missing Azure Credentials

```
Error: Azure credentials not configured.
```

**Solution**: Create `~/.config/bulk-action/creds.env` with your Azure credentials.

### CSV Format Errors

```
Error: CSV must have an 'email' column.
```

**Solution**: Ensure your CSV has a column named `email` (case-insensitive).

### Rate Limiting (429 Errors)

The tool includes a 500ms throttle between operations. If you still hit rate limits:

1. Reduce batch size
2. Wait and retry
3. Contact Microsoft Support to increase your API quota

## Development

### Running Tests

```bash
cd bulk-action-runner/macos
source .venv/bin/activate
pytest tests/ -v
```

### Project Structure

```
bulk-action-runner/
├── bulk/
│   ├── __init__.py        # Package version
│   ├── __main__.py        # CLI entry point
│   ├── operations.py      # Operation implementations
│   ├── csv_reader.py      # CSV parsing utilities
│   ├── output.py          # Console output formatting
│   ├── report.py          # CSV report generation
│   └── config.py          # Azure configuration
├── tests/
│   ├── test_operations.py # CLI tests
│   └── fixtures/
│       └── users.csv      # Test fixture
├── Formula/
│   └── bulk-run.rb        # Homebrew formula
├── pyproject.toml         # Package metadata
└── README.md              # This file
```

## License

MIT License — see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit changes (`git commit -am 'feat: add new feature'`)
4. Push to branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please follow conventional commits for all commit messages.
