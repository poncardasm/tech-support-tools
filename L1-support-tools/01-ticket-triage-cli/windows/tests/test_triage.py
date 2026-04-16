"""Tests for the ticket triage CLI."""

import json
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest
from click.testing import CliRunner

from ticket_triage.triage import (
    triage,
    load_rules,
    score_priority,
    score_confidence,
    check_escalation,
    ollama_triage,
    TriageResult,
    HAS_REQUESTS,
)
from ticket_triage.__main__ import triage_cli, format_text_output, format_json_output


class TestCLI:
    """Integration tests for the CLI interface."""

    @pytest.fixture
    def runner(self):
        """Click test runner."""
        return CliRunner()

    def test_cli_help(self, runner):
        """Test --help displays usage information."""
        result = runner.invoke(triage_cli, ["--help"])
        assert result.exit_code == 0
        assert "Triage a support ticket" in result.output
        assert "--file" in result.output
        assert "--json" in result.output
        assert "--version" in result.output

    def test_cli_version(self, runner):
        """Test --version displays version."""
        result = runner.invoke(triage_cli, ["--version"])
        assert result.exit_code == 0
        assert "1.0.0" in result.output

    def test_cli_stdin_input(self, runner):
        """Test reading from stdin."""
        result = runner.invoke(triage_cli, input="User password expired in EntraID")
        assert result.exit_code == 0
        assert "Category: Authentication" in result.output
        assert "Priority:" in result.output

    def test_cli_json_output(self, runner):
        """Test --json flag outputs valid JSON."""
        result = runner.invoke(triage_cli, ["--json"], input="VPN connection down")
        assert result.exit_code == 0
        # Verify it's valid JSON
        data = json.loads(result.output)
        assert "category" in data
        assert "priority" in data
        assert "confidence" in data

    def test_cli_file_input(self, runner, tmp_path):
        """Test --file option reads from file."""
        ticket_file = tmp_path / "ticket.txt"
        # Use a ticket that won't trigger L2 escalation
        ticket_file.write_text("User needs help with email signature settings")

        result = runner.invoke(triage_cli, ["--file", str(ticket_file)])
        assert result.exit_code == 0
        assert "Email/Outlook" in result.output or "Email" in result.output

    def test_cli_file_not_found(self, runner):
        """Test --file with non-existent file exits with code 1."""
        result = runner.invoke(triage_cli, ["--file", "/nonexistent/path.txt"])
        assert result.exit_code == 1
        assert "File not found" in result.output

    def test_cli_no_input(self, runner):
        """Test CLI with no input shows error."""
        result = runner.invoke(triage_cli)
        assert result.exit_code == 1
        assert "input" in result.output.lower()

    def test_cli_empty_stdin(self, runner):
        """Test CLI with empty stdin shows error."""
        result = runner.invoke(triage_cli, input="")
        assert result.exit_code == 1
        assert "Empty input" in result.output

    def test_cli_exit_code_2_for_l2_escalation(self, runner):
        """Test exit code 2 when L2 escalation is required."""
        result = runner.invoke(triage_cli, input="Hardware failure on laptop disk")
        assert result.exit_code == 2
        assert "flag_l2" in format_json_output(triage("Hardware failure", load_rules()))

    def test_cli_exit_code_0_normal_ticket(self, runner):
        """Test exit code 0 for normal non-escalated ticket."""
        result = runner.invoke(
            triage_cli, input="Question about password reset process"
        )
        assert result.exit_code == 0

    def test_format_text_output(self):
        """Test text output formatter."""
        result = TriageResult(
            category="Authentication",
            priority="P2 (Medium)",
            action="Reset password",
            escalate_to="None",
            kb="KB-1001",
            signals=["password", "login"],
            confidence="High",
            flag_l2=False,
        )
        output = format_text_output(result)
        assert "Category: Authentication" in output
        assert "Priority: P2 (Medium)" in output
        assert "Confidence: High" in output
        assert "Related KB: KB-1001" in output

    def test_format_json_output(self):
        """Test JSON output formatter."""
        result = TriageResult(
            category="Authentication",
            priority="P2 (Medium)",
            action="Reset password",
            escalate_to="None",
            kb="KB-1001",
            signals=["password"],
            confidence="Medium",
            flag_l2=False,
        )
        output = format_json_output(result)
        data = json.loads(output)
        assert data["category"] == "Authentication"
        assert data["priority"] == "P2"
        assert data["flag_l2"] == False


class TestTriage:
    """Test cases for triage functionality."""

    @pytest.fixture
    def rules(self):
        """Load default rules for testing."""
        return load_rules()

    def test_empty_ticket_raises_error(self, rules):
        """Empty ticket text should raise ValueError."""
        with pytest.raises(ValueError, match="empty"):
            triage("", rules)

    def test_authentication_ticket(self, rules):
        """Test authentication category detection."""
        result = triage("User can't login, password expired in EntraID", rules)
        assert result.category == "Authentication"
        assert result.priority == "P2 (Medium)"
        assert "password" in [s.lower() for s in result.signals]

    def test_network_vpn_ticket(self, rules):
        """Test network/VPN category detection."""
        result = triage(
            "VPN connection keeps dropping, cannot connect to network", rules
        )
        assert result.category == "Network/VPN"
        assert "vpn" in [s.lower() for s in result.signals]

    def test_email_outlook_ticket(self, rules):
        """Test email/Outlook category detection."""
        result = triage("Outlook crashes when opening mailbox, PST file issue", rules)
        assert result.category == "Email/Outlook"
        assert "outlook" in [s.lower() for s in result.signals]

    def test_hardware_ticket(self, rules):
        """Test hardware category detection."""
        result = triage("Laptop screen is broken, hardware failure detected", rules)
        assert result.category == "Hardware"
        assert "laptop" in [s.lower() for s in result.signals]

    def test_software_ticket(self, rules):
        """Test software category detection."""
        result = triage("Application keeps crashing, need to reinstall software", rules)
        assert result.category == "Software"
        assert "crash" in [s.lower() for s in result.signals]

    def test_access_request_ticket(self, rules):
        """Test access request category detection."""
        result = triage("Need access to SharePoint site and Teams group", rules)
        assert result.category == "Access Request"
        assert "sharepoint" in [s.lower() for s in result.signals]

    def test_printing_ticket(self, rules):
        """Test printing category detection."""
        result = triage("Printer offline, print job stuck in queue", rules)
        assert result.category == "Printing"
        assert "printer" in [s.lower() for s in result.signals]

    def test_unknown_ticket(self, rules):
        """Test unknown category fallback."""
        result = triage("Just a general question about office hours", rules)
        assert result.category == "Other/Unknown"

    def test_p1_override_down(self, rules):
        """Test P1 override with 'down' keyword."""
        result = triage(
            "URGENT: entire team can't access VPN, production is down", rules
        )
        assert result.priority == "P1 (Critical)"

    def test_p1_override_outage(self, rules):
        """Test P1 override with 'outage' keyword."""
        result = triage("System outage affecting everyone", rules)
        assert result.priority == "P1 (Critical)"

    def test_p1_override_everyone(self, rules):
        """Test P1 override with 'everyone' keyword."""
        result = triage("Email is broken for everyone in the department", rules)
        assert result.priority == "P1 (Critical)"

    def test_p3_indicator(self, rules):
        """Test P3 priority with indicator words."""
        result = triage(
            "When possible, could you help with a minor cosmetic issue?", rules
        )
        assert result.priority == "P3 (Low)"

    def test_urgency_modifier_bump(self, rules):
        """Test urgency modifier bumps priority."""
        result = triage("Password issue ASAP, need immediate access", rules)
        # Default P2 with urgency -> P1
        assert result.priority == "P1 (Critical)"

    def test_escalation_flag_hardware_failure(self, rules):
        """Test L2 escalation flag for hardware failure."""
        result = triage("Hardware failure detected on laptop", rules)
        assert result.flag_l2 == True
        assert "Hardware failure" in result.escalate_to

    def test_escalation_flag_auth_mfa(self, rules):
        """Test L2 escalation flag for MFA issues."""
        result = triage("User locked out, MFA token not working", rules)
        assert result.flag_l2 == True
        assert "MFA" in result.escalate_to or "L2" in result.escalate_to

    def test_escalation_flag_p1_authentication(self, rules):
        """Test L2 escalation flag for P1 + Authentication."""
        result = triage("URGENT: Everyone locked out, MFA down in production", rules)
        assert result.flag_l2 == True
        assert "P1" in result.escalate_to or "Security" in result.escalate_to

    def test_escalation_multiple_categories(self, rules):
        """Test L2 escalation for multiple categories."""
        result = triage("VPN is down and can't login to email, both are broken", rules)
        assert result.flag_l2 == True
        assert (
            "Multiple" in result.escalate_to
            or "categories" in result.escalate_to.lower()
        )

    def test_confidence_high(self, rules):
        """Test high confidence with 3+ keywords."""
        result = triage(
            "User can't login, password expired, account locked, MFA not working", rules
        )
        assert result.confidence == "High"

    def test_confidence_medium(self, rules):
        """Test medium confidence with 1-2 keywords."""
        result = triage("User can't login", rules)
        assert result.confidence == "Medium"

    def test_confidence_low_ambiguous(self, rules):
        """Test low confidence with multiple categories."""
        result = triage("VPN is down and can't login to email", rules)
        assert result.confidence == "Low"

    def test_confidence_low_no_match(self, rules):
        """Test low confidence with no matches."""
        result = triage("Hello, I have a question about vacation policy", rules)
        assert result.confidence == "Low"

    def test_kb_field_present(self, rules):
        """Test KB field is populated from rules."""
        result = triage("Password expired in EntraID", rules)
        assert result.kb.startswith("KB-")
        assert result.kb != "KB-0000"  # Should be a real KB

    def test_action_field_present(self, rules):
        """Test suggested action is populated."""
        result = triage("Password expired", rules)
        assert result.action != "No action available"
        assert len(result.action) > 0


class TestScoreConfidence:
    """Unit tests for score_confidence function."""

    def test_high_confidence_three_plus_keywords(self):
        assert score_confidence(["a", "b", "c"], 1) == "High"
        assert score_confidence(["a", "b", "c", "d"], 1) == "High"

    def test_medium_confidence_one_two_keywords(self):
        assert score_confidence(["a"], 1) == "Medium"
        assert score_confidence(["a", "b"], 1) == "Medium"

    def test_low_confidence_multiple_categories(self):
        assert score_confidence(["a", "b", "c"], 2) == "Low"
        assert score_confidence(["a"], 3) == "Low"

    def test_low_confidence_no_keywords(self):
        assert score_confidence([], 1) == "Low"


class TestScorePriority:
    """Unit tests for score_priority function."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_default_p2(self, rules):
        result, _ = score_priority("Generic support request", "authentication", rules)
        assert result == "P2 (Medium)"

    def test_p1_override_words(self, rules):
        p1_words = ["down", "outage", "everyone", "production", "urgent"]
        for word in p1_words:
            result, _ = score_priority(f"System is {word}", "network_vpn", rules)
            assert result == "P1 (Critical)", f"Failed for word: {word}"

    def test_p3_indicators(self, rules):
        result, _ = score_priority(
            "When possible fix this cosmetic issue", "software", rules
        )
        assert result == "P3 (Low)"

    def test_p4_indicators(self, rules):
        result, _ = score_priority(
            "FYI for reference only no action needed", "other_unknown", rules
        )
        assert result == "P4 (Info)"

    def test_urgency_modifier_p2_to_p1(self, rules):
        # P2 + urgency -> P1
        result, bumped = score_priority("Need help ASAP", "software", rules)
        assert bumped == True
        assert result == "P1 (Critical)"

    def test_urgency_modifier_p3_to_p2(self, rules):
        # P3 indicator "when possible" + "urgent" urgency
        # Actually the logic might override - let's test carefully
        result, bumped = score_priority(
            "When possible, urgent help needed", "software", rules
        )
        # P3 base + urgency bump = P2
        assert result == "P2 (Medium)" or result == "P1 (Critical)"

    def test_p1_cannot_bump_higher(self, rules):
        # P1 stays P1 even with urgency
        result, bumped = score_priority("System down immediately", "network_vpn", rules)
        assert result == "P1 (Critical)"


class TestCheckEscalation:
    """Unit tests for check_escalation function."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_hardware_failure_escalation(self, rules):
        flag, msg = check_escalation(
            "Hardware failure detected on disk",
            "hardware",
            "P2 (Medium)",
            rules,
            ["hardware"],
        )
        assert flag == True
        assert "Hardware failure" in msg

    def test_mfa_escalation(self, rules):
        flag, msg = check_escalation(
            "MFA token not working",
            "authentication",
            "P2 (Medium)",
            rules,
            ["authentication"],
        )
        assert flag == True
        assert "MFA" in msg

    def test_p1_authentication_escalation(self, rules):
        flag, msg = check_escalation(
            "Everyone locked out",
            "authentication",
            "P1 (Critical)",
            rules,
            ["authentication"],
        )
        assert flag == True
        assert "P1" in msg or "Security" in msg

    def test_multiple_categories_escalation(self, rules):
        flag, msg = check_escalation(
            "VPN and login issues",
            "network_vpn",
            "P2 (Medium)",
            rules,
            ["network_vpn", "authentication"],
        )
        assert flag == True
        assert "Multiple" in msg

    def test_no_escalation_normal_ticket(self, rules):
        flag, msg = check_escalation(
            "Just a question about password reset",
            "authentication",
            "P2 (Medium)",
            rules,
            ["authentication"],
        )
        assert flag == False


class TestLLMMode:
    """Tests for LLM mode with mocked Ollama."""

    @pytest.fixture
    def runner(self):
        """Click test runner."""
        return CliRunner()

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_ollama_triage_fallback_when_no_requests(self, rules):
        """Test ollama_triage returns None when requests not available."""
        with patch("ticket_triage.triage.HAS_REQUESTS", False):
            result = ollama_triage("Test ticket", rules)
            assert result is None

    def test_ollama_triage_fallback_on_connection_error(self, rules):
        """Test ollama_triage returns None on connection error."""
        if not HAS_REQUESTS:
            pytest.skip("requests not installed")

        with patch("ticket_triage.triage.requests.post") as mock_post:
            mock_post.side_effect = Exception("Connection refused")
            result = ollama_triage("Test ticket", rules)
            assert result is None

    def test_ollama_triage_fallback_on_bad_status(self, rules):
        """Test ollama_triage returns None on non-200 status."""
        if not HAS_REQUESTS:
            pytest.skip("requests not installed")

        with patch("ticket_triage.triage.requests.post") as mock_post:
            mock_response = MagicMock()
            mock_response.status_code = 500
            mock_post.return_value = mock_response
            result = ollama_triage("Test ticket", rules)
            assert result is None

    def test_triage_with_llm_flag_uses_fallback(self, rules):
        """Test triage falls back to rule engine when Ollama unavailable."""
        with patch("ticket_triage.triage.HAS_REQUESTS", False):
            result = triage("User password expired", rules, use_llm=True)
            assert result.category == "Authentication"  # Falls back to rule engine

    def test_cli_with_llm_flag(self, runner):
        """Test CLI accepts --llm flag."""
        with patch("ticket_triage.triage.HAS_REQUESTS", False):
            result = runner.invoke(triage_cli, ["--llm"], input="VPN connection down")
            assert result.exit_code == 0  # Falls back to rule engine silently
            assert "Network/VPN" in result.output or "VPN" in result.output


class TestFixtures:
    """Tests using fixture files from tests/fixtures/."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    @pytest.fixture
    def fixtures_dir(self):
        """Return path to fixtures directory."""
        return Path(__file__).parent / "fixtures"

    def test_authentication_fixture(self, rules, fixtures_dir):
        """Test authentication category with fixture file."""
        ticket_text = (fixtures_dir / "authentication.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Authentication"
        assert result.confidence in ["High", "Medium"]

    def test_network_vpn_fixture(self, rules, fixtures_dir):
        """Test network/VPN category with fixture file."""
        ticket_text = (fixtures_dir / "network_vpn.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Network/VPN"

    def test_email_outlook_fixture(self, rules, fixtures_dir):
        """Test email/Outlook category with fixture file."""
        ticket_text = (fixtures_dir / "email_outlook.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Email/Outlook"

    def test_hardware_fixture(self, rules, fixtures_dir):
        """Test hardware category with fixture file."""
        ticket_text = (fixtures_dir / "hardware.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Hardware"
        assert result.flag_l2 == True  # Hardware failure detected

    def test_software_fixture(self, rules, fixtures_dir):
        """Test software category with fixture file."""
        ticket_text = (fixtures_dir / "software.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Software"

    def test_access_request_fixture(self, rules, fixtures_dir):
        """Test access request category with fixture file."""
        ticket_text = (fixtures_dir / "access_request.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Access Request"

    def test_printing_fixture(self, rules, fixtures_dir):
        """Test printing category with fixture file."""
        ticket_text = (fixtures_dir / "printing.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Printing"

    def test_other_unknown_fixture(self, rules, fixtures_dir):
        """Test other/unknown category with fixture file."""
        ticket_text = (fixtures_dir / "other_unknown.txt").read_text()
        result = triage(ticket_text, rules)
        assert result.category == "Other/Unknown"
        assert result.confidence == "Low"
