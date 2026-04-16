"""Tests for log-parse parser and analyzer."""

import pytest
from log_parse.parser import (
    LogEntry,
    detect_format,
    parse_file,
    parse_json_lines,
    parse_iis,
    parse_plain,
    parse_syslog,
)
from log_parse.analyzer import (
    normalize_message,
    analyze_entries,
    filter_entries,
    suggest_actions,
)


class TestFormatDetection:
    """Test format detection from file headers."""

    def test_detects_json_lines(self, tmp_path):
        log_file = tmp_path / "test.json"
        log_file.write_text('{"level": "ERROR", "message": "test"}\n')
        assert detect_format(str(log_file)) == "json_lines"

    def test_detects_iis_from_header(self, tmp_path):
        log_file = tmp_path / "iis.log"
        log_file.write_text("#Fields: date time s-ip cs-method\n")
        assert detect_format(str(log_file)) == "iis"

    def test_detects_evtx_by_extension(self, tmp_path):
        log_file = tmp_path / "test.evtx"
        log_file.write_text("binary content")
        assert detect_format(str(log_file)) == "evtx"

    def test_falls_back_to_plain(self, tmp_path):
        log_file = tmp_path / "test.txt"
        log_file.write_text("Just some plain text log\n")
        assert detect_format(str(log_file)) == "plain"

    def test_stdin_defaults_to_plain(self):
        assert detect_format(None) == "plain"

    def test_detects_syslog(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan  1 12:00:00 host process: message\n")
        assert detect_format(str(log_file)) == "syslog"


class TestJsonLinesParser:
    """Test JSON Lines log parsing."""

    def test_parses_simple_json(self, tmp_path):
        log_file = tmp_path / "test.json"
        log_file.write_text(
            '{"level": "ERROR", "message": "test error", "timestamp": "2024-01-01T00:00:00Z"}\n'
        )

        entries = list(parse_json_lines(str(log_file)))
        assert len(entries) == 1
        assert entries[0].level == "ERROR"
        assert entries[0].message == "test error"

    def test_parses_multiple_lines(self, tmp_path):
        log_file = tmp_path / "test.json"
        log_file.write_text(
            '{"level": "ERROR", "message": "error1"}\n'
            '{"level": "INFO", "message": "info1"}\n'
            '{"level": "WARN", "message": "warn1"}\n'
        )

        entries = list(parse_json_lines(str(log_file)))
        assert len(entries) == 3
        assert entries[0].level == "ERROR"
        assert entries[1].level == "INFO"
        assert entries[2].level == "WARN"

    def test_handles_windows_event_json(self, tmp_path):
        log_file = tmp_path / "events.json"
        log_file.write_text(
            '{"TimeGenerated": "2024-01-01T00:00:00", "Level": 2, "ProviderName": "Test", "Message": "Error occurred"}\n'
        )

        entries = list(parse_json_lines(str(log_file)))
        assert len(entries) == 1
        assert entries[0].source == "Test"


class TestIisParser:
    """Test IIS log parsing."""

    def test_parses_iis_with_header(self, tmp_path):
        log_file = tmp_path / "iis.log"
        log_file.write_text(
            "#Software: Microsoft Internet Information Services 10.0\n"
            "#Fields: date time s-ip cs-method cs-uri-stem s-port sc-status\n"
            "2024-01-01 12:00:00 192.168.1.1 GET /index.html 80 200\n"
            "2024-01-01 12:00:01 192.168.1.1 GET /error 80 500\n"
        )

        entries = list(parse_iis(str(log_file)))
        assert len(entries) == 2
        assert entries[0].level == "INFO"  # 200 status
        assert entries[1].level == "ERROR"  # 500 status

    def test_parses_iis_without_header(self, tmp_path):
        log_file = tmp_path / "iis.log"
        log_file.write_text("2024-01-01 12:00:00 192.168.1.1 GET /index.html 200\n")

        entries = list(parse_iis(str(log_file)))
        assert len(entries) == 1
        assert entries[0].level == "INFO"


class TestSyslogParser:
    """Test syslog parsing."""

    def test_parses_rfc3164(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan  1 12:00:00 myhost myapp: Test message\n")

        entries = list(parse_syslog(str(log_file)))
        assert len(entries) == 1
        assert entries[0].timestamp == "Jan  1 12:00:00"
        assert entries[0].source == "myapp"

    def test_detects_error_level(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan  1 12:00:00 myhost myapp: Critical error occurred\n")

        entries = list(parse_syslog(str(log_file)))
        assert entries[0].level == "ERROR"

    def test_detects_warn_level(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan  1 12:00:00 myhost myapp: Warning: something wrong\n")

        entries = list(parse_syslog(str(log_file)))
        assert entries[0].level == "WARN"


class TestPlainTextParser:
    """Test plain text log parsing."""

    def test_detects_error_keywords(self, tmp_path):
        log_file = tmp_path / "test.log"
        log_file.write_text("Application error occurred\n")

        entries = list(parse_plain(str(log_file)))
        assert entries[0].level == "ERROR"

    def test_extracts_timestamp(self, tmp_path):
        log_file = tmp_path / "test.log"
        log_file.write_text("2024-01-01T12:00:00 Something happened\n")

        entries = list(parse_plain(str(log_file)))
        assert entries[0].timestamp == "2024-01-01T12:00:00"


class TestMessageNormalization:
    """Test message normalization for grouping."""

    def test_normalizes_ip_addresses(self):
        msg = "Connection from 192.168.1.1 failed"
        assert normalize_message(msg) == "Connection from [IP] failed"

    def test_normalizes_uuids(self):
        msg = "Error for user 550e8400-e29b-41d4-a716-446655440000"
        assert "[UUID]" in normalize_message(msg)

    def test_normalizes_guids(self):
        msg = "Registry key {550e8400-e29b-41d4-a716-446655440000} not found"
        assert "[GUID]" in normalize_message(msg)

    def test_normalizes_pids(self):
        msg = "Process PID:1234 terminated"
        assert "[PID]" in normalize_message(msg)

    def test_truncates_long_messages(self):
        msg = "x" * 200
        assert len(normalize_message(msg)) <= 150


class TestAnalysis:
    """Test log analysis functions."""

    def test_analyze_groups_errors(self):
        entries = [
            LogEntry("", "ERROR", "app", "Connection failed", ""),
            LogEntry("", "ERROR", "app", "Connection failed", ""),  # Same error
            LogEntry("", "WARN", "app", "Low memory", ""),
        ]

        analysis = analyze_entries(entries)
        assert len(analysis["error_counts"]) == 1
        assert analysis["error_counts"][0][1] == 2  # Count of 2

    def test_analyze_counts_by_source(self):
        entries = [
            LogEntry("", "INFO", "app1", "msg1", ""),
            LogEntry("", "INFO", "app1", "msg2", ""),
            LogEntry("", "INFO", "app2", "msg3", ""),
        ]

        analysis = analyze_entries(entries)
        assert analysis["top_sources"][0] == ("app1", 2)

    def test_suggest_actions_for_connection_errors(self):
        analysis = {"error_counts": [("Connection refused", 5)], "warning_counts": []}
        suggestions = suggest_actions(analysis)
        assert len(suggestions) > 0
        assert "accessible" in suggestions[0].lower()


class TestFilters:
    """Test entry filtering."""

    def test_filter_by_level(self):
        entries = [
            LogEntry("", "ERROR", "app", "error msg", ""),
            LogEntry("", "INFO", "app", "info msg", ""),
            LogEntry("", "WARN", "app", "warn msg", ""),
        ]

        filtered = filter_entries(entries, level=["ERROR"])
        assert len(filtered) == 1
        assert filtered[0].level == "ERROR"

    def test_filter_by_source(self):
        entries = [
            LogEntry("", "ERROR", "IIS", "error", ""),
            LogEntry("", "ERROR", "SQL", "error", ""),
        ]

        filtered = filter_entries(entries, source="IIS")
        assert len(filtered) == 1
        assert filtered[0].source == "IIS"

    def test_filter_by_grep(self):
        entries = [
            LogEntry("", "ERROR", "app", "connection refused", ""),
            LogEntry("", "ERROR", "app", "disk full", ""),
        ]

        filtered = filter_entries(entries, grep="connection")
        assert len(filtered) == 1
        assert "connection" in filtered[0].message

    def test_filter_by_time(self):
        entries = [
            LogEntry("2024-01-01T10:00:00", "ERROR", "app", "msg", ""),
            LogEntry("2024-01-02T10:00:00", "ERROR", "app", "msg", ""),
            LogEntry("2024-01-03T10:00:00", "ERROR", "app", "msg", ""),
        ]

        filtered = filter_entries(entries, since="2024-01-02", until="2024-01-02")
        assert len(filtered) == 1
