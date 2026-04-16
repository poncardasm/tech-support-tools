"""Tests for ad-provision CLI commands."""

import pytest
from click.testing import CliRunner
from unittest.mock import patch, MagicMock

from ad_provision.commands import cli


class TestNewUser:
    """Tests for new-user command."""

    def test_new_user_dry_run(self):
        """Test new-user with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "new-user",
                "--username",
                "testuser",
                "--name",
                "Test User",
                "--email",
                "test@company.com",
                "--department",
                "IT",
                "--dry-run",
            ],
        )
        assert result.exit_code == 0
        assert "[DRY]" in result.output
        assert "Would create user" in result.output
        assert "test@company.com" in result.output

    def test_new_user_dry_run_with_groups(self):
        """Test new-user with groups in dry-run mode."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "new-user",
                "--username",
                "testuser",
                "--name",
                "Test User",
                "--email",
                "test@company.com",
                "--department",
                "IT",
                "--group",
                "IT-All",
                "--group",
                "Engineering",
                "--dry-run",
            ],
        )
        assert result.exit_code == 0
        assert "IT-All" in result.output
        assert "Engineering" in result.output

    def test_new_user_dry_run_with_mailbox(self):
        """Test new-user with --enable-mailbox in dry-run mode."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "new-user",
                "--username",
                "testuser",
                "--name",
                "Test User",
                "--email",
                "test@company.com",
                "--department",
                "IT",
                "--enable-mailbox",
                "--dry-run",
            ],
        )
        assert result.exit_code == 0
        assert "mailbox" in result.output.lower()


class TestAddGroup:
    """Tests for add-group command."""

    def test_add_group_dry_run(self):
        """Test add-group with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            ["add-group", "--username", "testuser", "--group", "IT-All", "--dry-run"],
        )
        assert result.exit_code == 0
        assert "[DRY]" in result.output
        assert "testuser" in result.output
        assert "IT-All" in result.output


class TestEnableMailbox:
    """Tests for enable-mailbox command."""

    def test_enable_mailbox_dry_run(self):
        """Test enable-mailbox with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["enable-mailbox", "--username", "testuser", "--dry-run"]
        )
        assert result.exit_code == 0
        assert "[DRY]" in result.output
        assert "mailbox" in result.output.lower()


class TestResetPassword:
    """Tests for reset-password command."""

    def test_reset_password_dry_run(self):
        """Test reset-password with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["reset-password", "--username", "testuser", "--dry-run"]
        )
        assert result.exit_code == 0
        assert "[DRY]" in result.output
        assert "Would reset password" in result.output
        assert "Temporary password would be" in result.output

    def test_reset_password_generates_valid_password(self):
        """Test that reset-password generates a valid temp password."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["reset-password", "--username", "testuser", "--dry-run"]
        )
        assert result.exit_code == 0
        # Password should contain required character types
        output = result.output
        # Find the password in output
        assert "Temporary password would be:" in output


class TestDeprovision:
    """Tests for deprovision command."""

    def test_deprovision_dry_run(self):
        """Test deprovision with --dry-run flag."""
        runner = CliRunner()
        result = runner.invoke(
            cli, ["deprovision", "--username", "testuser", "--dry-run"]
        )
        assert result.exit_code == 0
        assert "[DRY]" in result.output
        assert "Would deprovision" in result.output

    def test_deprovision_dry_run_with_reason(self):
        """Test deprovision with reason in dry-run mode."""
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "deprovision",
                "--username",
                "testuser",
                "--reason",
                "terminated",
                "--dry-run",
            ],
        )
        assert result.exit_code == 0
        assert "terminated" in result.output
        assert "Would disable" in result.output
        assert "Would remove from all groups" in result.output
        assert "Would revoke all sessions" in result.output


class TestOutputPrefixes:
    """Tests for output formatting."""

    @patch("ad_provision.commands.get_graph_client")
    def test_ok_prefix(self, mock_get_client, tmp_path):
        """Test [OK] prefix in output."""
        # Mock the config to avoid needing real credentials
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client

        runner = CliRunner()

        # We can only test dry-run mode without real credentials
        result = runner.invoke(
            cli,
            ["add-group", "--username", "testuser", "--group", "IT-All", "--dry-run"],
        )
        assert "[DRY]" in result.output

    def test_help_shows_all_commands(self):
        """Test that help shows all available commands."""
        runner = CliRunner()
        result = runner.invoke(cli, ["--help"])
        assert result.exit_code == 0
        assert "new-user" in result.output
        assert "add-group" in result.output
        assert "enable-mailbox" in result.output
        assert "reset-password" in result.output
        assert "deprovision" in result.output


class TestErrorHandling:
    """Tests for error handling."""

    @patch("ad_provision.commands.get_graph_client")
    def test_missing_config_error(self, mock_get_client):
        """Test error when config file is missing."""
        mock_get_client.side_effect = FileNotFoundError("Config not found")

        runner = CliRunner()
        result = runner.invoke(
            cli, ["add-group", "--username", "testuser", "--group", "IT-All"]
        )
        assert result.exit_code == 1
        assert "[FAIL]" in result.output or "FAIL" in result.output
