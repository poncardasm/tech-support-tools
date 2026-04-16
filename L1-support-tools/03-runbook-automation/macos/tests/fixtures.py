"""Sample runbook fixtures for testing."""

import pytest
from pathlib import Path


@pytest.fixture
def simple_runbook(tmp_path):
    """A simple runbook with one step."""
    runbook = tmp_path / "simple.md"
    runbook.write_text("""# Simple Runbook

A basic test runbook.

```bash
echo "Hello, World!"
```
""")
    return str(runbook)


@pytest.fixture
def multi_step_runbook(tmp_path):
    """A runbook with multiple steps."""
    runbook = tmp_path / "multi-step.md"
    runbook.write_text("""# Multi-Step Runbook

This runbook has multiple steps.

## Step 1: Check environment

```bash
uname -a
```

## Step 2: Check disk space

```bash
df -h
```

## Step 3: List processes

```bash
ps aux | head -10
```
""")
    return str(runbook)


@pytest.fixture
def failing_runbook(tmp_path):
    """A runbook with a step that will fail."""
    runbook = tmp_path / "failing.md"
    runbook.write_text("""# Failing Runbook

This runbook has a failing step.

```bash
echo "This step succeeds"
```

```bash
exit 1
```

```bash
echo "This won't run unless forced"
```
""")
    return str(runbook)


@pytest.fixture
def mixed_language_runbook(tmp_path):
    """A runbook with various code block types."""
    runbook = tmp_path / "mixed.md"
    runbook.write_text("""# Mixed Language Runbook

This runbook has different code block types.

## Config (not executable)

```yaml
database:
  host: localhost
  port: 5432
```

## Setup script

```bash
#!/bin/bash
echo "Setting up..."
```

## Python script (not executable by runbook)

```python
print("This won't be executed by runbook CLI")
```

## Shell variant

```sh
echo "Using sh"
```

## Zsh variant

```zsh
echo "Using zsh"
```
""")
    return str(runbook)


@pytest.fixture
def complex_runbook(tmp_path):
    """A complex runbook with verification steps."""
    runbook = tmp_path / "complex.md"
    runbook.write_text("""# PostgreSQL Service Restart

Restart PostgreSQL service safely.

## Pre-check

```bash
# Check if PostgreSQL is installed
which psql || exit 1
```

## Stop Service

```bash
brew services stop postgresql
```

## Verify stopped

```bash
! pgrep -x postgres
```

## Start Service

```bash
brew services start postgresql
```

## Post-check

```bash
sleep 2
pgrep -x postgres
```
""")
    return str(runbook)


@pytest.fixture
def runbooks_dir(tmp_path):
    """A directory with categorized runbooks."""
    # Create category directories
    (tmp_path / "authentication").mkdir()
    (tmp_path / "networking").mkdir()
    (tmp_path / "infrastructure").mkdir()

    # Create runbooks
    (tmp_path / "authentication" / "reset-password.md").write_text("""# Reset Password

```bash
echo "Resetting password..."
```
""")

    (tmp_path / "networking" / "restart-vpn.md").write_text("""# Restart VPN

```bash
echo "Restarting VPN..."
```
""")

    (tmp_path / "infrastructure" / "clear-logs.md").write_text("""# Clear Logs

```bash
echo "Clearing logs..."
```
""")

    (tmp_path / "README.md").write_text("# Runbooks\n\nThis directory contains runbooks.")

    return str(tmp_path)
