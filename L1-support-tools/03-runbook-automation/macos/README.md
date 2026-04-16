# Runbook Automation CLI (macOS)

A CLI tool for managing and executing markdown-based runbooks with embedded shell commands. Write a runbook in Markdown, and execute it step-by-step — no more copy-paste from wikis into terminals.

## Features

- **Markdown-native**: Runbooks are just Markdown files — view them in GitHub, your IDE, or any Markdown viewer
- **Step-by-step execution**: Execute bash/sh/zsh code blocks sequentially
- **Interactive error handling**: On failure, choose to skip, force continue, or abort
- **Resume support**: Stop and resume from where you left off
- **Dry-run mode**: Preview what would execute without running commands
- **Runbook discovery**: List and search your runbook collection
- **State persistence**: Track execution progress between runs

## Installation

### Via Homebrew (recommended)

```bash
brew tap example/runbook
brew install runbook
```

### Via pip

```bash
pip install runbook-automation
```

### From source

```bash
git clone https://github.com/example/runbook-automation.git
cd runbook-automation/macos
pip install -e .
```

## Quick Start

### 1. Create a runbook

```markdown
# Restart PostgreSQL Service

## Pre-check

```bash
brew services list | grep postgresql
```

## Stop Service

```bash
brew services stop postgresql
```

## Start Service

```bash
brew services start postgresql
```

## Verify

```bash
pgrep -x postgres
```
```

### 2. Execute it

```bash
# Run the runbook
runbook run restart-postgres.md

# Preview without executing
runbook run restart-postgres.md --dry-run

# Resume from last failed step
runbook run restart-postgres.md --resume

# Start from step 3
runbook run restart-postgres.md --from-step 3
```

## Runbook Format

Runbooks are standard Markdown files with executable code blocks:

- **Executable blocks**: Use `bash`, `sh`, or `zsh` language tags
- **Non-executable blocks**: Python, YAML, JSON, SQL, etc. are displayed but not run
- **Step numbering**: Automatic based on order in file

```markdown
# My Runbook Title

Introduction text here.

## Step 1: Do something

```bash
echo "Hello, World!"
```

## Configuration (not executable)

```yaml
setting: value
```

## Step 2: Do something else

```bash
uname -a
```
```

## CLI Commands

### `runbook run <file>`

Execute a runbook.

```bash
runbook run my-runbook.md
runbook run my-runbook.md --dry-run
runbook run my-runbook.md --from-step 3
runbook run my-runbook.md --resume
runbook run my-runbook.md --show-steps
```

### `runbook list`

List all runbooks in a directory.

```bash
runbook list
runbook list --category networking
runbook list --directory ./my-runbooks
```

### `runbook search <query>`

Search runbooks by name or content.

```bash
runbook search "VPN"
runbook search "restart"
```

### `runbook status <file>`

Check execution status of a runbook.

```bash
runbook status my-runbook.md
```

## Directory Structure

Organize runbooks in categories:

```
runbooks/
├── authentication/
│   ├── reset-password.md
│   └── unlock-account.md
├── networking/
│   ├── restart-vpn.md
│   └── check-connectivity.md
└── infrastructure/
    ├── restart-brew-services.md
    └── clear-logs.md
```

## Error Handling

When a step fails, you'll see:

```
[!] Step 3 failed with exit code 1
Error: command not found

[DID NOT EXPECT THIS] Stopping. Options:
  [s] Skip this step and continue
  [f] Force continue (ignore failures)
  [a] Abort execution
>
```

Press `s` to skip the failed step, `f` to continue and ignore future failures, or `a` to abort.

## State Management

Execution state is saved to `~/.config/runbook/state/<runbook-name>.json`:

```json
{
  "runbook": "/path/to/runbook.md",
  "current_step": 3,
  "last_run": "2024-01-15T10:30:00",
  "success": false
}
```

This enables:
- **Resume**: Continue from where you stopped
- **Ctrl+C handling**: Safe interruption with state preservation

## Configuration

State and configuration are stored in:

```
~/.config/runbook/
├── state/           # Execution state files
└── config.json      # User preferences (future)
```

## macOS-Specific Notes

- Uses `/bin/bash` for shell execution
- Sudo prompts: Interactive sudo within runbooks may not work as expected
- Path handling: Properly handles spaces in paths
- Zsh vs Bash: Detects shebang lines for script language detection

## Development

### Setup

```bash
cd 03-runbook-automation/macos
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### Testing

```bash
pytest tests/ -v
```

### Project Structure

```
runbook/
├── __init__.py      # Package init
├── __main__.py      # CLI entry point
├── parser.py        # Markdown parsing
├── executor.py      # Step execution engine
├── indexer.py       # Runbook discovery
└── state.py         # State management
```

## Sample Runbooks

The project includes sample runbooks for common macOS tasks:

- **Service restart**: `runbooks/infrastructure/restart-brew-services.md`
- **Log clearing**: `runbooks/infrastructure/clear-logs.md`
- **VPN reset**: `runbooks/networking/reset-vpn.md`

## License

MIT

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request
