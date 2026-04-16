"""Test suite for ticket-triage CLI."""

from pathlib import Path

import pytest
from ticket_triage.triage import (
    load_rules,
    triage,
    TriageResult,
    score_priority,
    score_confidence,
    check_escalation,
)


class TestCategoryMatching:
    """Test all 8 categories match correctly."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_authentication_ticket(self, rules):
        """Test authentication category matching."""
        result = triage("User can't login, password expired in EntraID", rules)
        assert result.category == "authentication"
        assert result.priority.startswith("P2")  # no P1 override

    def test_network_vpn_ticket(self, rules):
        """Test network/VPN category matching."""
        result = triage(
            "VPN connection keeps dropping, cannot connect to network", rules
        )
        assert result.category == "network"

    def test_email_ticket(self, rules):
        """Test email/Outlook category matching."""
        result = triage("Outlook calendar not syncing, email signature missing", rules)
        assert result.category == "email"

    def test_hardware_ticket(self, rules):
        """Test hardware category matching."""
        result = triage("Laptop screen is blank, hardware failure detected", rules)
        assert result.category == "hardware"

    def test_software_ticket(self, rules):
        """Test software category matching."""
        result = triage("Application keeps crashing, need to reinstall software", rules)
        assert result.category == "software"

    def test_access_request_ticket(self, rules):
        """Test access request category matching."""
        result = triage("Need access to SharePoint folder and Teams group", rules)
        assert result.category == "access_request"

    def test_printing_ticket(self, rules):
        """Test printing category matching."""
        result = triage("Printer not working, print job stuck in queue", rules)
        assert result.category == "printing"

    def test_other_unknown_ticket(self, rules):
        """Test Other/Unknown fallback category."""
        result = triage("Something weird happened today", rules)
        assert result.category == "Other/Unknown"


class TestPriorityScoring:
    """Test priority scoring logic."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_p1_override_down(self, rules):
        """Test P1 override with 'down' keyword."""
        result = triage(
            "URGENT: entire team can't access VPN, production is down", rules
        )
        assert result.priority.startswith("P1")

    def test_p1_override_outage(self, rules):
        """Test P1 override with 'outage' keyword."""
        result = triage("There is an outage affecting everyone", rules)
        assert result.priority.startswith("P1")

    def test_p1_urgent_modifier(self, rules):
        """Test P1 with urgency modifier."""
        result = triage("VPN is down ASAP", rules)
        assert result.priority.startswith("P1")

    def test_p2_default(self, rules):
        """Test default P2 priority."""
        result = triage("User needs password reset", rules)
        assert result.priority.startswith("P2")

    def test_p3_indicator(self, rules):
        """Test P3 indicator words."""
        result = triage("Please fix when possible, cosmetic issue", rules)
        assert result.priority.startswith("P3")

    def test_p4_indicator(self, rules):
        """Test P4 indicator words."""
        result = triage("FYI, for reference only, no action needed", rules)
        assert result.priority.startswith("P4")

    def test_urgency_bump_p3_to_p2(self, rules):
        """Test urgency modifier bumps P3 to P2."""
        result = triage("Cosmetic issue when possible but fix immediately", rules)
        # P3 base + urgency bump = P2
        assert result.priority.startswith("P2")

    def test_p1_cannot_be_bumped_higher(self, rules):
        """Test P1 cannot be bumped higher."""
        result = triage("Production is down immediately", rules)
        # Already P1, stays P1
        assert result.priority.startswith("P1")


class TestEscalation:
    """Test escalation flag conditions."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_escalation_flag_auth_mfa(self, rules):
        """Test escalation flag for authentication + MFA."""
        result = triage("User locked out, MFA token not working", rules)
        assert result.flag_l2 == True
        assert "L2" in result.escalate_to

    def test_escalation_flag_hardware_failure(self, rules):
        """Test escalation flag for hardware failure."""
        result = triage("Laptop hardware failure, device is dead", rules)
        assert result.flag_l2 == True
        assert "L2" in result.escalate_to

    def test_escalation_flag_p1_auth_security(self, rules):
        """Test escalation flag for P1 + Authentication."""
        result = triage("URGENT: EntraID is down, everyone locked out", rules)
        assert result.flag_l2 == True
        assert "Security" in result.escalate_to

    def test_no_escalation_normal_ticket(self, rules):
        """Test no escalation for normal tickets."""
        result = triage("User needs password reset", rules)
        assert result.flag_l2 == False
        assert result.escalate_to == "None"


class TestConfidence:
    """Test confidence scoring."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_high_confidence(self, rules):
        """Test high confidence with 3+ keywords."""
        result = triage(
            "User can't login, password expired, account locked in EntraID", rules
        )
        assert result.confidence == "High"

    def test_medium_confidence(self, rules):
        """Test medium confidence with 1-2 keywords."""
        result = triage("User can't login", rules)
        assert result.confidence == "Medium"

    def test_low_confidence_ambiguous(self, rules):
        """Test low confidence with multiple categories."""
        result = triage("VPN is down and can't login to email", rules)
        assert result.confidence == "Low"

    def test_low_confidence_no_match(self, rules):
        """Test low confidence with no category match."""
        result = triage("Something weird happened", rules)
        assert result.confidence == "Low"


class TestScoreFunctions:
    """Test individual scoring functions."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_score_priority_with_p1_override(self, rules):
        """Test score_priority with P1 override."""
        priority, _ = score_priority("System is down", "network", rules)
        assert priority.startswith("P1")

    def test_score_priority_default(self, rules):
        """Test score_priority default to P2."""
        priority, _ = score_priority("User needs help", "other", rules)
        assert priority.startswith("P2")

    def test_score_confidence_high(self):
        """Test score_confidence returns High."""
        assert score_confidence(["kw1", "kw2", "kw3"], 1) == "High"

    def test_score_confidence_medium(self):
        """Test score_confidence returns Medium."""
        assert score_confidence(["kw1"], 1) == "Medium"

    def test_score_confidence_low_multiple_categories(self):
        """Test score_confidence returns Low with multiple categories."""
        assert score_confidence(["kw1", "kw2", "kw3"], 2) == "Low"

    def test_score_confidence_low_no_keywords(self):
        """Test score_confidence returns Low with no keywords."""
        assert score_confidence([], 1) == "Low"


class TestTriageResult:
    """Test TriageResult structure."""

    def test_triage_result_fields(self):
        """Test TriageResult has all required fields."""
        result = TriageResult(
            category="authentication",
            priority="P2 (Medium)",
            action="Reset password",
            escalate_to="None",
            kb="KB-1001",
            signals=["password", "login"],
            confidence="High",
            flag_l2=False,
        )
        assert result.category == "authentication"
        assert result.priority == "P2 (Medium)"
        assert result.action == "Reset password"
        assert result.escalate_to == "None"
        assert result.kb == "KB-1001"
        assert result.signals == ["password", "login"]
        assert result.confidence == "High"
        assert result.flag_l2 == False


class TestErrorHandling:
    """Test error handling."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def test_empty_ticket_raises_error(self, rules):
        """Test empty ticket raises ValueError."""
        with pytest.raises(ValueError, match="Empty"):
            triage("", rules)

    def test_whitespace_ticket_raises_error(self, rules):
        """Test whitespace-only ticket raises ValueError."""
        with pytest.raises(ValueError, match="Empty"):
            triage("   \n\t  ", rules)


class TestOutputFormatters:
    """Test output formatting functions."""

    @pytest.fixture
    def sample_result(self):
        return TriageResult(
            category="authentication",
            priority="P2 (Medium)",
            action="Reset password",
            escalate_to="L2 if MFA not working",
            kb="KB-1001",
            signals=["password", "login"],
            confidence="High",
            flag_l2=False,
        )

    def test_format_result(self, sample_result):
        """Test text formatter."""
        from ticket_triage.triage import format_result

        output = format_result(sample_result)
        assert "Category: authentication" in output
        assert "Priority: P2 (Medium)" in output
        assert "Suggested action: Reset password" in output
        assert "Confidence: High" in output

    def test_format_json(self, sample_result):
        """Test JSON formatter."""
        import json
        from ticket_triage.triage import format_json

        output = format_json(sample_result)
        data = json.loads(output)
        assert data["category"] == "authentication"
        assert data["priority"] == "P2"
        assert data["flag_l2"] == False


class TestFixtures:
    """Test fixture files for each category."""

    @pytest.fixture
    def rules(self):
        return load_rules()

    def load_fixture(self, filename):
        """Load a fixture file from tests/fixtures/."""
        fixture_path = Path(__file__).parent / "fixtures" / filename
        with open(fixture_path, "r") as f:
            return f.read()

    def test_authentication_fixture(self, rules):
        """Test authentication fixture file."""
        text = self.load_fixture("authentication.txt")
        result = triage(text, rules)
        assert result.category == "authentication"
        assert result.confidence == "High"  # Multiple keywords matched
        assert result.flag_l2 == True  # MFA/locked detected

    def test_network_fixture(self, rules):
        """Test network fixture file."""
        text = self.load_fixture("network.txt")
        result = triage(text, rules)
        assert result.category == "network"

    def test_email_fixture(self, rules):
        """Test email fixture file."""
        text = self.load_fixture("email.txt")
        result = triage(text, rules)
        assert result.category == "email"

    def test_hardware_fixture(self, rules):
        """Test hardware fixture file."""
        text = self.load_fixture("hardware.txt")
        result = triage(text, rules)
        assert result.category == "hardware"
        assert result.flag_l2 == True  # Hardware failure detected

    def test_software_fixture(self, rules):
        """Test software fixture file."""
        text = self.load_fixture("software.txt")
        result = triage(text, rules)
        assert result.category == "software"

    def test_access_request_fixture(self, rules):
        """Test access request fixture file."""
        text = self.load_fixture("access_request.txt")
        result = triage(text, rules)
        assert result.category == "access_request"

    def test_printing_fixture(self, rules):
        """Test printing fixture file."""
        text = self.load_fixture("printing.txt")
        result = triage(text, rules)
        assert result.category == "printing"

    def test_unknown_fixture(self, rules):
        """Test unknown fixture file."""
        text = self.load_fixture("unknown.txt")
        result = triage(text, rules)
        assert result.category == "Other/Unknown"
        assert result.confidence == "Low"
