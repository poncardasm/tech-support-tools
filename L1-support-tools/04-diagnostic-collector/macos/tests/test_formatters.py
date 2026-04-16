"""Tests for diagnostic collector formatters and thresholds"""

import pytest
from diag.formatters import (
    parse_collector_output,
    format_markdown,
    format_html,
    format_json,
)
from diag.thresholds import ThresholdChecker, parse_percentage, check_thresholds


class TestParseCollectorOutput:
    """Test the parse_collector_output function."""

    def test_parse_simple_section(self):
        raw = "=== SYSTEM ===\nhostname=test-mac\nos=14.3.1\n"
        result = parse_collector_output(raw)

        assert result["hostname"] == "test-mac"
        assert "SYSTEM" in result["sections"]
        assert result["sections"]["SYSTEM"]["hostname"] == "test-mac"
        assert result["sections"]["SYSTEM"]["os"] == "14.3.1"

    def test_parse_multiple_sections(self):
        raw = "=== SYSTEM ===\nhostname=test\n=== DISK ===\ndrive=/ used=100G\n"
        result = parse_collector_output(raw)

        assert "SYSTEM" in result["sections"]
        assert "DISK" in result["sections"]

    def test_parse_multiline_value(self):
        raw = "=== LOGS ===\nrecent_errors<<EOF\nError 1\nError 2\nEOF\n"
        result = parse_collector_output(raw)

        assert "LOGS" in result["sections"]
        assert result["sections"]["LOGS"]["recent_errors"] == "Error 1\nError 2"

    def test_timestamp_added(self):
        raw = "=== SYSTEM ===\nhostname=test\n"
        result = parse_collector_output(raw)

        assert "collected_at" in result
        assert len(result["collected_at"]) > 0


class TestFormatMarkdown:
    """Test the format_markdown function."""

    def test_basic_structure(self):
        data = {
            "hostname": "test-mac",
            "collected_at": "2024-01-01 12:00:00",
            "sections": {"SYSTEM": {"hostname": "test-mac", "os_version": "14.3.1"}},
        }
        md = format_markdown(data)

        assert "# Diagnostic Report" in md
        assert "test-mac" in md
        assert "2024-01-01" in md

    def test_system_section_formatting(self):
        data = {
            "hostname": "test-mac",
            "collected_at": "2024-01-01 12:00:00",
            "sections": {
                "SYSTEM": {
                    "hostname": "test-mac",
                    "os_name": "macOS",
                    "os_version": "14.3.1",
                    "model": "MacBook Pro",
                    "chip": "M1",
                    "uptime": "5 days",
                }
            },
        }
        md = format_markdown(data)

        assert "## System" in md
        assert "**Hostname:**" in md
        assert "test-mac" in md
        assert "MacBook Pro" in md

    def test_disk_warning_highlighting(self):
        data = {
            "hostname": "test",
            "collected_at": "2024-01-01 12:00:00",
            "sections": {
                "DISK": {"drive=/": "used=450G total=500G percent=90 status=CRITICAL"}
            },
        }
        md = format_markdown(data)

        assert "CRITICAL" in md or "🔴" in md


class TestFormatHTML:
    """Test the format_html function."""

    def test_html_structure(self):
        data = {
            "hostname": "test-mac",
            "collected_at": "2024-01-01 12:00:00",
            "sections": {},
        }
        html = format_html(data)

        assert "<!DOCTYPE html>" in html
        assert "<html>" in html
        assert "</html>" in html
        assert "test-mac" in html

    def test_html_escaping(self):
        data = {
            "hostname": 'test<>&"mac',
            "collected_at": "2024-01-01 12:00:00",
            "sections": {},
        }
        html = format_html(data)

        assert "<" in html
        assert "test<mac" not in html  # Should be escaped


class TestFormatJSON:
    """Test the format_json function."""

    def test_valid_json_output(self):
        data = {
            "hostname": "test-mac",
            "collected_at": "2024-01-01 12:00:00",
            "sections": {"SYSTEM": {"hostname": "test-mac"}},
        }
        json_str = format_json(data)

        import json

        parsed = json.loads(json_str)  # Should not raise
        assert parsed["hostname"] == "test-mac"


class TestThresholdChecker:
    """Test the ThresholdChecker class."""

    def test_disk_ok(self):
        checker = ThresholdChecker()
        result = checker.check_disk(50, "/")

        assert result == "OK"
        assert len(checker.criticals) == 0
        assert len(checker.warnings) == 0

    def test_disk_warning(self):
        checker = ThresholdChecker()
        result = checker.check_disk(85, "/")

        assert result == "WARNING HIGH"
        assert len(checker.warnings) == 1
        assert "85%" in checker.warnings[0]

    def test_disk_critical(self):
        checker = ThresholdChecker()
        result = checker.check_disk(95, "/")

        assert result == "CRITICAL"
        assert len(checker.criticals) == 1
        assert "95%" in checker.criticals[0]

    def test_memory_ok(self):
        checker = ThresholdChecker()
        result = checker.check_memory(50)

        assert result == "OK"
        assert len(checker.criticals) == 0

    def test_memory_critical(self):
        checker = ThresholdChecker()
        result = checker.check_memory(95)

        assert result == "CRITICAL"
        assert len(checker.criticals) == 1

    def test_security_updates_detection(self):
        checker = ThresholdChecker()
        result = checker.check_security_updates("Security Update 2024-001")

        assert result is True
        assert len(checker.warnings) == 1

    def test_internet_connectivity_failure(self):
        checker = ThresholdChecker()
        result = checker.check_internet_connectivity("UNREACHABLE")

        assert result is False
        assert len(checker.criticals) == 1

    def test_has_issues_true(self):
        checker = ThresholdChecker()
        checker.warnings.append("Test warning")

        assert checker.has_issues() is True

    def test_has_issues_false(self):
        checker = ThresholdChecker()

        assert checker.has_issues() is False

    def test_format_report(self):
        checker = ThresholdChecker()
        checker.criticals.append("Critical issue")
        checker.warnings.append("Warning issue")

        report = checker.format_report()

        assert "CRITICAL" in report
        assert "Critical issue" in report
        assert "WARNINGS" in report
        assert "Warning issue" in report


class TestParsePercentage:
    """Test the parse_percentage helper function."""

    def test_simple_number(self):
        assert parse_percentage("50") == 50

    def test_with_percent_sign(self):
        assert parse_percentage("75%") == 75

    def test_float_string(self):
        assert parse_percentage("82.5") == 82

    def test_invalid_input(self):
        assert parse_percentage("invalid") == 0

    def test_empty_string(self):
        assert parse_percentage("") == 0


class TestCheckThresholds:
    """Test the check_thresholds integration function."""

    def test_check_disk_in_data(self):
        data = {
            "sections": {
                "DISK": {"drive=/": "used=450G total=500G percent=95 status=CRITICAL"}
            }
        }
        checker = check_thresholds(data)

        assert len(checker.criticals) >= 1
        assert any("95%" in c for c in checker.criticals)

    def test_check_memory_in_data(self):
        data = {"sections": {"MEMORY": {"percent_used": "92", "total_mb": "16384"}}}
        checker = check_thresholds(data)

        assert len(checker.criticals) >= 1

    def test_empty_data(self):
        data = {"sections": {}}
        checker = check_thresholds(data)

        assert not checker.has_issues()


class TestIntegration:
    """Integration tests for the full pipeline."""

    def test_full_pipeline(self):
        raw_input = """=== SYSTEM ===
hostname=test-mac
os_name=macOS
os_version=14.3.1
model=MacBook Pro
chip=M1 Pro
total_memory=32GB
uptime=10 days
current_user=admin

=== DISK ===
drive=/ used=400G total=500G percent=80 status=WARNING HIGH

=== MEMORY ===
total_mb=32768
used_mb=29491
percent_used=90
status=WARNING HIGH

=== NETWORK ===
interface=en0 ip=192.168.1.100
gateway=192.168.1.1
dns=8.8.8.8
internet_status=OK (ping 8.8.8.8 successful)
dns_resolution=OK
"""

        # Parse
        data = parse_collector_output(raw_input)
        assert data["hostname"] == "test-mac"

        # Format as markdown
        md = format_markdown(data)
        assert "# Diagnostic Report" in md
        assert "test-mac" in md

        # Format as HTML
        html = format_html(data)
        assert "<!DOCTYPE html>" in html

        # Format as JSON
        json_str = format_json(data)
        import json

        parsed = json.loads(json_str)
        assert parsed["hostname"] == "test-mac"

        # Check thresholds
        checker = check_thresholds(data)
        assert checker.has_issues()  # Should have disk and memory warnings
