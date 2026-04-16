import os
import sys
import pytest
from click.testing import CliRunner

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from bulk.__main__ import cli


class TestPasswordResetCommand:
    """Test password-reset command."""

    def test_password_reset_dry_run(self):
        """Test password-reset with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["password-reset", "tests/fixtures/users.csv", "--dry-run"]
        )
        assert result.exit_code == 0
        assert "would reset password" in result.output
        assert "alice@company.com" in result.output
        assert "bob@company.com" in result.output
        assert "carol@company.com" in result.output

    def test_password_reset_help(self):
        """Test password-reset --help."""
        runner = CliRunner()
        result = runner.invoke(cli, ["password-reset", "--help"])
        assert result.exit_code == 0
        assert "Reset passwords for all users in CSV" in result.output
        assert "--dry-run" in result.output
        assert "--report" in result.output


class TestAddGroupCommand:
    """Test add-group command."""

    def test_add_group_dry_run(self):
        """Test add-group with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            ["add-group", "tests/fixtures/users.csv", "--group", "IT-All", "--dry-run"],
        )
        assert result.exit_code == 0
        assert "would add to IT-All" in result.output
        assert "alice@company.com" in result.output

    def test_add_group_missing_group_option(self):
        """Test add-group without required --group option."""
        runner = CliRunner()
        result = runner.invoke(cli, ["add-group", "tests/fixtures/users.csv"])
        assert result.exit_code != 0
        assert "Missing option" in result.output or "--group" in result.output


class TestEnableMailboxCommand:
    """Test enable-mailbox command."""

    def test_enable_mailbox_dry_run(self):
        """Test enable-mailbox with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["enable-mailbox", "tests/fixtures/users.csv", "--dry-run"]
        )
        assert result.exit_code == 0
        assert "would enable mailbox" in result.output


class TestDeprovisionCommand:
    """Test deprovision command."""

    def test_deprovision_dry_run(self):
        """Test deprovision with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "deprovision",
                "tests/fixtures/users.csv",
                "--reason",
                "terminated",
                "--dry-run",
            ],
        )
        assert result.exit_code == 0
        assert "would deprovision" in result.output
        assert "reason: terminated" in result.output


class TestReportGeneration:
    """Test report generation."""

    def test_report_generation(self, tmp_path):
        """Test that --report generates a valid CSV file."""
        import csv

        report_path = tmp_path / "report.csv"
        runner = CliRunner()

        result = runner.invoke(
            cli,
            [
                "password-reset",
                "tests/fixtures/users.csv",
                "--dry-run",
                "--report",
                str(report_path),
            ],
        )

        assert result.exit_code == 0
        assert report_path.exists()
        assert "Report saved to" in result.output

        # Verify CSV content
        with open(report_path, "r", newline="") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            assert len(rows) == 3  # 3 users in fixture
            assert "email" in reader.fieldnames
            assert "operation" in reader.fieldnames
            assert "result" in reader.fieldnames
            assert "detail" in reader.fieldnames
            assert "timestamp" in reader.fieldnames


class TestCSVInput:
    """Test CSV input handling."""

    def test_missing_csv_file(self):
        """Test error handling for non-existent CSV file."""
        runner = CliRunner()
        result = runner.invoke(cli, ["password-reset", "nonexistent.csv", "--dry-run"])
        assert result.exit_code != 0
        assert "does not exist" in result.output or "Invalid value" in result.output
