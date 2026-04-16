"""Tests for the runbook parser module."""

import pytest
from pathlib import Path
import tempfile

from runbook.parser import (
    parse_runbook,
    extract_steps,
    validate_runbook,
    parse_runbook_with_metadata,
)
from runbook.parser import Step


class TestStep:
    """Test the Step dataclass."""

    def test_step_creation(self):
        step = Step(number=1, code="echo hello", language="bash")
        assert step.number == 1
        assert step.code == "echo hello"
        assert step.language == "bash"

    def test_step_repr(self):
        step = Step(number=1, code="echo hello world this is a long command", language="bash")
        repr_str = repr(step)
        assert "Step(1" in repr_str
        assert "bash" in repr_str


class TestExtractSteps:
    """Test the extract_steps function."""

    def test_extract_bash_code_block(self):
        content = """
# Test Runbook

## Step 1
```bash
echo hello
```
"""
        steps = extract_steps(content)
        assert len(steps) == 1
        assert steps[0].number == 1
        assert steps[0].code == "echo hello"
        assert steps[0].language == "bash"

    def test_extract_sh_code_block(self):
        content = """
```sh
echo hello
```
"""
        steps = extract_steps(content)
        assert len(steps) == 1
        assert steps[0].language == "bash"  # Defaults to bash

    def test_extract_zsh_code_block(self):
        content = """
```zsh
echo hello
```
"""
        steps = extract_steps(content)
        assert len(steps) == 1
        assert steps[0].language == "bash"  # Defaults to bash

    def test_extract_multiple_code_blocks(self):
        content = """
```bash
echo step 1
```

Some text

```bash
echo step 2
```

```bash
echo step 3
```
"""
        steps = extract_steps(content)
        assert len(steps) == 3
        assert steps[0].number == 1
        assert steps[1].number == 2
        assert steps[2].number == 3

    def test_ignore_other_languages(self):
        content = """
```python
print("hello")
```

```bash
echo hello
```

```yaml
key: value
```
"""
        steps = extract_steps(content)
        assert len(steps) == 1
        assert steps[0].code == "echo hello"

    def test_multiline_code(self):
        content = """
```bash
#!/bin/bash
echo "line 1"
echo "line 2"
echo "line 3"
```
"""
        steps = extract_steps(content)
        assert len(steps) == 1
        assert "line 1" in steps[0].code
        assert "line 2" in steps[0].code
        assert "line 3" in steps[0].code


class TestParseRunbook:
    """Test the parse_runbook function."""

    def test_parse_valid_runbook(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("""
# Test Runbook

```bash
echo hello
```
""")
        steps = parse_runbook(str(runbook))
        assert len(steps) == 1
        assert steps[0].code == "echo hello"

    def test_parse_nonexistent_file(self):
        with pytest.raises(FileNotFoundError):
            parse_runbook("/nonexistent/path/runbook.md")

    def test_parse_non_md_file(self, tmp_path):
        file = tmp_path / "test.txt"
        file.write_text("```bash\necho hello\n```")
        with pytest.raises(ValueError):
            parse_runbook(str(file))


class TestParseRunbookWithMetadata:
    """Test the parse_runbook_with_metadata function."""

    def test_parse_with_title(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# My Test Runbook

This is a description.

```bash
echo hello
```
""")
        result = parse_runbook_with_metadata(str(runbook))
        assert result["title"] == "My Test Runbook"
        assert "description" in result
        assert result["step_count"] == 1
        assert "steps" in result

    def test_parse_without_title(self, tmp_path):
        runbook = tmp_path / "my-runbook.md"
        runbook.write_text("""
```bash
echo hello
```
""")
        result = parse_runbook_with_metadata(str(runbook))
        assert result["title"] == "my-runbook"


class TestValidateRunbook:
    """Test the validate_runbook function."""

    def test_validate_valid_runbook(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("```bash\necho hello\n```")
        is_valid, errors = validate_runbook(str(runbook))
        assert is_valid
        assert len(errors) == 0

    def test_validate_no_shell_blocks(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("```python\nprint('hello')\n```")
        is_valid, errors = validate_runbook(str(runbook))
        assert not is_valid
        assert any("No shell code blocks" in e for e in errors)

    def test_validate_nonexistent_file(self):
        is_valid, errors = validate_runbook("/nonexistent/test.md")
        assert not is_valid
        assert any("not found" in e.lower() for e in errors)
