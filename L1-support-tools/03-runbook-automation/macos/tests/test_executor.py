"""Tests for the runbook executor module."""

import pytest
from pathlib import Path
import tempfile

from runbook.executor import execute_step, execute_runbook, show_runbook_steps, prompt_on_failure
from runbook.parser import Step


class TestExecuteStep:
    """Test the execute_step function."""

    def test_execute_simple_command(self, capsys):
        step = Step(number=1, code="echo 'hello world'", language="bash")
        result = execute_step(step, total=1, dry_run=False)

        assert result["exit_code"] == 0
        assert result["success"]
        assert "hello world" in result["output"]

        captured = capsys.readouterr()
        assert "[STEP 1/1]" in captured.out

    def test_dry_run(self, capsys):
        step = Step(number=1, code="rm -rf /", language="bash")
        result = execute_step(step, total=1, dry_run=True)

        assert result["exit_code"] == 0  # Dry run always succeeds
        assert result["success"]

        captured = capsys.readouterr()
        assert "DRY RUN" in captured.out
        assert "rm -rf" in captured.out

    def test_failing_command(self):
        step = Step(number=1, code="exit 1", language="bash")
        result = execute_step(step, total=1, dry_run=False)

        assert result["exit_code"] == 1
        assert not result["success"]

    def test_command_with_error_output(self, capsys):
        step = Step(number=1, code="echo 'error' >&2", language="bash")
        result = execute_step(step, total=1, dry_run=False)

        assert result["exit_code"] == 0
        assert "error" in result["stderr"]


class TestExecuteRunbook:
    """Test the execute_runbook function."""

    def test_execute_simple_runbook(self, tmp_path, capsys):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# Test

```bash
echo "step 1"
```

```bash
echo "step 2"
```
""")
        success = execute_runbook(str(runbook), dry_run=True)
        assert success

        captured = capsys.readouterr()
        assert "[STEP 1/2]" in captured.out
        assert "[STEP 2/2]" in captured.out

    def test_from_step_option(self, tmp_path, capsys):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# Test

```bash
echo "step 1"
```

```bash
echo "step 2"
```

```bash
echo "step 3"
```
""")
        success = execute_runbook(str(runbook), from_step=2, dry_run=True)
        assert success

        captured = capsys.readouterr()
        assert "Starting from step 2" in captured.out
        # Should NOT see step 1
        assert "[STEP 1/3]" not in captured.out
        # Should see steps 2 and 3
        assert "[STEP 2/3]" in captured.out

    def test_empty_runbook(self, tmp_path, capsys):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test\n\nNo code blocks here.")
        success = execute_runbook(str(runbook), dry_run=True)
        assert success  # Empty runbook is considered successful

        captured = capsys.readouterr()
        assert "No executable steps" in captured.out

    def test_from_step_too_high(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# Test

```bash
echo "step 1"
```
""")
        success = execute_runbook(str(runbook), from_step=10, dry_run=True)
        assert not success


class TestShowRunbookSteps:
    """Test the show_runbook_steps function."""

    def test_show_steps(self, tmp_path, capsys):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# Test Runbook

```bash
echo "first command"
```

```bash
echo "second command"
```
""")
        success = show_runbook_steps(str(runbook))
        assert success

        captured = capsys.readouterr()
        assert "Total steps: 2" in captured.out
        assert "[1]" in captured.out
        assert "[2]" in captured.out

    def test_show_steps_empty(self, tmp_path, capsys):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test\n\nNo code blocks")
        success = show_runbook_steps(str(runbook))
        assert success

        captured = capsys.readouterr()
        assert "No executable steps" in captured.out

    def test_show_steps_invalid_file(self, capsys):
        success = show_runbook_steps("/nonexistent/runbook.md")
        assert not success


class TestPromptOnFailure:
    """Test the prompt_on_failure function."""

    def test_prompt_abort(self, monkeypatch, capsys):
        step = Step(number=1, code="exit 1", language="bash")
        result = {"exit_code": 1, "error": "Command failed"}

        monkeypatch.setattr("builtins.input", lambda _: "a")

        choice = prompt_on_failure(step, result)
        assert choice == "a"

    def test_prompt_skip(self, monkeypatch):
        step = Step(number=1, code="exit 1", language="bash")
        result = {"exit_code": 1, "error": ""}

        monkeypatch.setattr("builtins.input", lambda _: "s")

        choice = prompt_on_failure(step, result)
        assert choice == "s"

    def test_prompt_force(self, monkeypatch):
        step = Step(number=1, code="exit 1", language="bash")
        result = {"exit_code": 1, "error": ""}

        monkeypatch.setattr("builtins.input", lambda _: "f")

        choice = prompt_on_failure(step, result)
        assert choice == "f"

    def test_prompt_invalid_then_valid(self, monkeypatch):
        step = Step(number=1, code="exit 1", language="bash")
        result = {"exit_code": 1, "error": ""}

        inputs = iter(["invalid", "x", "a"])
        monkeypatch.setattr("builtins.input", lambda _: next(inputs))

        choice = prompt_on_failure(step, result)
        assert choice == "a"
