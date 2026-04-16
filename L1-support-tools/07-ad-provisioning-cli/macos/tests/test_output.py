"""Tests for output formatting module."""

import sys
from io import StringIO

from ad_provision.output import (
    write_output,
    write_ok,
    write_fail,
    write_temp,
    write_warn,
    write_dry,
)


class TestOutputFormatting:
    """Tests for output formatting functions."""

    def test_write_output_ok(self):
        """Test write_output with OK type."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_output("OK", "Test message")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[OK]" in output
        assert "Test message" in output

    def test_write_output_fail(self):
        """Test write_output with FAIL type goes to stderr."""
        old_stderr = sys.stderr
        sys.stderr = StringIO()

        write_output("FAIL", "Error message")

        output = sys.stderr.getvalue()
        sys.stderr = old_stderr

        assert "[FAIL]" in output
        assert "Error message" in output

    def test_write_output_temp(self):
        """Test write_output with TEMP type."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_output("TEMP", "Temporary password")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[TEMP]" in output
        assert "Temporary password" in output

    def test_write_output_warn(self):
        """Test write_output with WARN type."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_output("WARN", "Warning message")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[WARN]" in output
        assert "Warning message" in output

    def test_write_ok(self):
        """Test write_ok helper function."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_ok("Success")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[OK]" in output
        assert "Success" in output

    def test_write_fail(self):
        """Test write_fail helper function."""
        old_stderr = sys.stderr
        sys.stderr = StringIO()

        write_fail("Failure")

        output = sys.stderr.getvalue()
        sys.stderr = old_stderr

        assert "[FAIL]" in output
        assert "Failure" in output

    def test_write_temp(self):
        """Test write_temp helper function."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_temp("Password123")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[TEMP]" in output
        assert "Password123" in output

    def test_write_warn(self):
        """Test write_warn helper function."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_warn("Caution")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[WARN]" in output
        assert "Caution" in output

    def test_write_dry(self):
        """Test write_dry helper function."""
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        write_dry("Would create user")

        output = sys.stdout.getvalue()
        sys.stdout = old_stdout

        assert "[DRY]" in output
        assert "Would create user" in output
