"""Tests for log-parse package."""

import pytest
import json
import tempfile
from pathlib import Path

from log_parse.parser import (
    LogEntry,
    detect_format,
    parse_file,
    parse_syslog,
    parse_json_lines,
    parse_docker,
    parse_journald,
    parse_apache,
    parse_plain,
)
from log_parse.analyzer import normalize_message, filter_entries, analyze_entries
from log_parse.formatters import format_text, format_json, format_csv


class TestFormatDetection:
    """Test format detection functionality."""

    def test_detect_syslog(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan 15 10:30:45 server sshd: test message\n")
        assert detect_format(str(log_file)) == "syslog"

    def test_detect_json_lines(self, tmp_path):
        log_file = tmp_path / "json.log"
        log_file.write_text('{"level": "INFO", "message": "test"}\n')
        assert detect_format(str(log_file)) == "json_lines"

    def test_detect_docker(self, tmp_path):
        log_file = tmp_path / "docker.log"
        log_file.write_text(
            '{"log": "test", "stream": "stdout", "time": "2024-01-01T00:00:00Z"}\n'
        )
        assert detect_format(str(log_file)) == "docker"

    def test_detect_journald(self, tmp_path):
        log_file = tmp_path / "journald.log"
        log_file.write_text('{"__CURSOR": "test", "MESSAGE": "test"}\n')
        assert detect_format(str(log_file)) == "journald"

    def test_detect_apache(self, tmp_path):
        log_file = tmp_path / "access.log"
        log_file.write_text(
            '192.168.1.1 - - [01/Jan/2024:00:00:00 +0000] "GET / HTTP/1.1" 200 123\n'
        )
        assert detect_format(str(log_file)) == "apache"

    def test_detect_plain(self, tmp_path):
        log_file = tmp_path / "plain.log"
        log_file.write_text("Some random log text\n")
        assert detect_format(str(log_file)) == "plain"


class TestSyslogParser:
    """Test syslog format parsing."""

    def test_parse_syslog_rfc3164(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text(
            "Jan 15 10:30:45 server1 sshd[1234]: Authentication failure\n"
        )

        entries = list(parse_syslog(str(log_file)))
        assert len(entries) == 1
        assert entries[0].timestamp == "Jan 15 10:30:45"
        assert entries[0].source == "sshd[1234]"
        assert entries[0].message == "Authentication failure"
        assert entries[0].level == "ERROR"  # Detected from message content

    def test_parse_syslog_with_pid(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text("Jan 15 10:30:45 server1 kernel: test message\n")

        entries = list(parse_syslog(str(log_file)))
        assert len(entries) == 1
        assert entries[0].source == "kernel"
        assert entries[0].message == "test message"

    def test_parse_syslog_level_detection(self, tmp_path):
        log_file = tmp_path / "syslog.log"
        log_file.write_text(
            "Jan 15 10:30:45 server1 app: Error occurred\n"
            "Jan 15 10:30:46 server1 app: Warning message\n"
            "Jan 15 10:30:47 server1 app: Info message\n"
        )

        entries = list(parse_syslog(str(log_file)))
        assert len(entries) == 3
        assert entries[0].level == "ERROR"
        assert entries[1].level == "WARN"
        assert entries[2].level == "INFO"


class TestJSONLinesParser:
    """Test JSON Lines format parsing."""

    def test_parse_json_lines(self, tmp_path):
        log_file = tmp_path / "json.log"
        log_file.write_text(
            '{"timestamp": "2024-01-15T10:30:45Z", "level": "ERROR", "source": "db", "message": "Connection refused"}\n'
            '{"timestamp": "2024-01-15T10:31:00Z", "level": "WARN", "source": "cache", "message": "Cache miss"}\n'
        )

        entries = list(parse_json_lines(str(log_file)))
        assert len(entries) == 2
        assert entries[0].timestamp == "2024-01-15T10:30:45Z"
        assert entries[0].level == "ERROR"
        assert entries[0].source == "db"
        assert entries[0].message == "Connection refused"


class TestDockerParser:
    """Test Docker log format parsing."""

    def test_parse_docker_stdout(self, tmp_path):
        log_file = tmp_path / "docker.log"
        log_file.write_text(
            '{"log": "Application starting...\\n", "stream": "stdout", "time": "2024-01-15T10:30:00Z"}\n'
        )

        entries = list(parse_docker(str(log_file)))
        assert len(entries) == 1
        assert entries[0].timestamp == "2024-01-15T10:30:00Z"
        assert entries[0].level == "INFO"
        assert entries[0].message == "Application starting..."

    def test_parse_docker_stderr(self, tmp_path):
        log_file = tmp_path / "docker.log"
        log_file.write_text(
            '{"log": "Error occurred\\n", "stream": "stderr", "time": "2024-01-15T10:30:05Z"}\n'
        )

        entries = list(parse_docker(str(log_file)))
        assert len(entries) == 1
        assert entries[0].level == "ERROR"


class TestJournaldParser:
    """Test journald JSON export parsing."""

    def test_parse_journald(self, tmp_path):
        log_file = tmp_path / "journald.log"
        log_file.write_text(
            '{"__CURSOR": "s=123", "__REALTIME_TIMESTAMP": "1705315845000000", "PRIORITY": "3", "SYSLOG_IDENTIFIER": "systemd", "MESSAGE": "Failed to start service"}\n'
        )

        entries = list(parse_journald(str(log_file)))
        assert len(entries) == 1
        assert entries[0].level == "ERROR"  # PRIORITY 3 = error
        assert entries[0].source == "systemd"
        assert entries[0].message == "Failed to start service"


class TestApacheParser:
    """Test Apache/Nginx access log parsing."""

    def test_parse_apache_combined(self, tmp_path):
        log_file = tmp_path / "access.log"
        log_file.write_text(
            '192.168.1.100 - - [15/Jan/2024:10:30:00 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"\n'
        )

        entries = list(parse_apache(str(log_file)))
        assert len(entries) == 1
        assert entries[0].level == "INFO"  # 200 status
        assert "GET /index.html" in entries[0].message

    def test_parse_apache_error_status(self, tmp_path):
        log_file = tmp_path / "access.log"
        log_file.write_text(
            '192.168.1.100 - - [15/Jan/2024:10:30:00 +0000] "GET /api/error HTTP/1.1" 500 42 "-" "Mozilla/5.0"\n'
        )

        entries = list(parse_apache(str(log_file)))
        assert entries[0].level == "ERROR"  # 500 status


class TestPlainParser:
    """Test plain text log parsing."""

    def test_parse_plain_text(self, tmp_path):
        log_file = tmp_path / "plain.log"
        log_file.write_text(
            "Error: Something went wrong\n"
            "Warning: This is a warning\n"
            "Just a normal info message\n"
        )

        entries = list(parse_plain(str(log_file)))
        assert len(entries) == 3
        assert entries[0].level == "ERROR"
        assert entries[1].level == "WARN"
        assert entries[2].level == "INFO"


class TestAnalyzer:
    """Test analysis functions."""

    def test_normalize_message(self):
        assert normalize_message("Error from 192.168.1.100") == "Error from [IP]"
        assert normalize_message("ID: abc123def456") == "ID: [ID]"

    def test_filter_entries_by_level(self):
        entries = [
            LogEntry("", "ERROR", "app", "Error 1", ""),
            LogEntry("", "WARN", "app", "Warning 1", ""),
            LogEntry("", "INFO", "app", "Info 1", ""),
        ]

        filtered = filter_entries(entries, level=["ERROR", "WARN"])
        assert len(filtered) == 2
        assert all(e.level in ["ERROR", "WARN"] for e in filtered)

    def test_filter_entries_by_source(self):
        entries = [
            LogEntry("", "ERROR", "database", "Error 1", ""),
            LogEntry("", "ERROR", "api", "Error 2", ""),
        ]

        filtered = filter_entries(entries, source="database")
        assert len(filtered) == 1
        assert filtered[0].source == "database"

    def test_filter_entries_by_grep(self):
        entries = [
            LogEntry("", "ERROR", "app", "Connection refused", ""),
            LogEntry("", "ERROR", "app", "Timeout error", ""),
        ]

        filtered = filter_entries(entries, grep="connection")
        assert len(filtered) == 1
        assert "connection" in filtered[0].message.lower()

    def test_analyze_entries(self):
        entries = [
            LogEntry(
                "2024-01-15T10:00:00Z",
                "ERROR",
                "db",
                "Connection refused to 192.168.1.100",
                "",
            ),
            LogEntry(
                "2024-01-15T10:01:00Z",
                "ERROR",
                "db",
                "Connection refused to 10.0.0.50",
                "",
            ),
            LogEntry("2024-01-15T10:02:00Z", "WARN", "cache", "Cache miss", ""),
        ]

        analysis = analyze_entries(entries)

        # Should group errors by normalized message
        assert len(analysis["error_counts"]) == 1
        assert analysis["error_counts"][0][1] == 2  # Count of 2

        # Should count sources
        assert len(analysis["top_sources"]) == 2


class TestFormatters:
    """Test output formatters."""

    def test_format_text(self):
        analysis = {
            "error_counts": [("Connection refused", 5)],
            "warning_counts": [("Cache miss", 3)],
            "top_sources": [("database", 5), ("cache", 3)],
            "time_range": {
                "start": "2024-01-15T10:00:00Z",
                "end": "2024-01-15T11:00:00Z",
            },
        }
        stats = {
            "file": "test.log",
            "format": "syslog",
            "total": 10,
            "filtered": 8,
            "errors": 5,
            "warnings": 3,
        }

        output = format_text(analysis, stats)
        assert "Log Summary" in output
        assert "ERRORS" in output
        assert "Connection refused" in output

    def test_format_json(self):
        analysis = {
            "error_counts": [("Error message", 1)],
            "warning_counts": [],
            "top_sources": [("app", 1)],
            "time_range": None,
        }
        stats = {
            "file": "test.log",
            "format": "plain",
            "total": 1,
            "filtered": 1,
            "errors": 1,
            "warnings": 0,
        }

        output = format_json(analysis, stats)
        data = json.loads(output)
        assert data["stats"]["file"] == "test.log"
        assert len(data["analysis"]["errors"]) == 1

    def test_format_csv(self):
        entries = [
            LogEntry("2024-01-15T10:00:00Z", "ERROR", "db", "Connection refused", ""),
        ]

        output = format_csv(entries)
        lines = output.strip().split("\n")
        assert len(lines) == 2
        assert "timestamp,level,source,message" in lines[0]
        assert "ERROR" in lines[1]
