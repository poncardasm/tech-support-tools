"""Log file parsing with format detection."""

import re
import json
from dataclasses import dataclass
from typing import Iterator, Optional
from pathlib import Path


@dataclass
class LogEntry:
    """Represents a parsed log entry."""

    timestamp: str
    level: str  # ERROR, WARN, INFO, DEBUG
    source: str
    message: str
    raw: str


def detect_format(file_path: Optional[str]) -> str:
    """Detect log format from file header."""
    if file_path is None:
        return "plain"  # stdin default

    with open(file_path, "rb") as f:
        # Read first 2KB for detection
        header = f.read(2048)

    # Split into lines for analysis
    lines = header.split(b"\n")[:10]  # Check first 10 lines

    for line in lines:
        if not line.strip():
            continue

        # journald JSON export
        if b"__CURSOR" in line:
            return "journald"

        # Docker container logs
        if b'"log"' in line and b'"stream"' in line:
            return "docker"

        # JSON lines
        if line.strip().startswith(b"{"):
            try:
                json.loads(line)
                return "json_lines"
            except json.JSONDecodeError:
                pass

        # Apache/Nginx access log (IP address at start)
        if re.match(rb"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", line):
            return "apache"

        # Syslog pattern (RFC 3164)
        syslog_pattern = rb"^[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}"
        if re.match(syslog_pattern, line):
            return "syslog"

        # RFC 5424 syslog
        rfc5424_pattern = rb"^<\d+>\d+ "
        if re.match(rfc5424_pattern, line):
            return "syslog"

    return "plain"


def parse_file(file_path: Optional[str], format: str = None) -> Iterator[LogEntry]:
    """Parse a log file and yield LogEntry objects."""
    detected = format or detect_format(file_path)

    if detected == "syslog":
        yield from parse_syslog(file_path)
    elif detected == "journald":
        yield from parse_journald(file_path)
    elif detected == "docker":
        yield from parse_docker(file_path)
    elif detected == "json_lines":
        yield from parse_json_lines(file_path)
    elif detected == "apache":
        yield from parse_apache(file_path)
    else:
        yield from parse_plain(file_path)


def parse_syslog(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse RFC 3164/5424 syslog format."""
    # RFC 3164: 'Jan  1 12:00:00 hostname process: message'
    syslog_pattern = re.compile(
        r"^(\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+"  # timestamp
        r"(\S+)\s+"  # hostname
        r"(\S+?)(?:\[(\d+)\])?:\s*"  # process[pid]:
        r"(.*)$"  # message
    )

    # RFC 5424: '<priority>version timestamp hostname appname ...'
    rfc5424_pattern = re.compile(
        r"^<(\d+)>\d+\s+"  # priority and version
        r"(\S+)\s+"  # timestamp
        r"(\S+)\s+"  # hostname
        r"(\S+)\s+"  # appname
        r"\S+\s+"  # procid
        r"\S+\s+"  # msgid
        r"(?:\[.*?\]\s+)?"  # structured data
        r"(.*)$"  # message
    )

    LEVEL_KEYWORDS = {
        "error": "ERROR",
        "fail": "ERROR",
        "failed": "ERROR",
        "critical": "ERROR",
        "fatal": "ERROR",
        "exception": "ERROR",
        "warning": "WARN",
        "warn": "WARN",
        "debug": "DEBUG",
    }

    def detect_level(message: str) -> str:
        msg_lower = message.lower()
        for keyword, lvl in LEVEL_KEYWORDS.items():
            if keyword in msg_lower:
                return lvl
        return "INFO"

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Try RFC 3164 first
            match = syslog_pattern.match(line)
            if match:
                timestamp, hostname, source, pid, message = match.groups()
                if pid:
                    source = f"{source}[{pid}]"

                yield LogEntry(
                    timestamp=timestamp,
                    level=detect_level(message),
                    source=source,
                    message=message,
                    raw=line,
                )
                continue

            # Try RFC 5424
            match = rfc5424_pattern.match(line)
            if match:
                priority, timestamp, hostname, source, message = match.groups()
                # Extract severity from priority (priority = facility * 8 + severity)
                severity = int(priority) & 7
                level_map = {
                    0: "ERROR",
                    1: "ERROR",
                    2: "ERROR",
                    3: "ERROR",
                    4: "WARN",
                    5: "INFO",
                    6: "INFO",
                    7: "DEBUG",
                }
                level = level_map.get(severity, "INFO")

                yield LogEntry(
                    timestamp=timestamp,
                    level=level,
                    source=source,
                    message=message,
                    raw=line,
                )
                continue

            # Fall back to plain text
            yield LogEntry(
                timestamp="",
                level=detect_level(line),
                source="unknown",
                message=line,
                raw=line,
            )


def parse_journald(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse journald JSON export format."""

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                data = json.loads(line)

                # Priority mapping (0=emerg, 3=err, 4=warn, 6=info, 7=debug)
                priority = data.get("PRIORITY", "6")
                level_map = {
                    "0": "ERROR",
                    "1": "ERROR",
                    "2": "ERROR",
                    "3": "ERROR",
                    "4": "WARN",
                    "5": "INFO",
                    "6": "INFO",
                    "7": "DEBUG",
                }
                level = level_map.get(str(priority), "INFO")

                # Timestamp from realtime
                timestamp = ""
                if "__REALTIME_TIMESTAMP" in data:
                    ts = (
                        int(data["__REALTIME_TIMESTAMP"]) / 1_000_000
                    )  # microseconds to seconds
                    from datetime import datetime

                    timestamp = datetime.fromtimestamp(ts).isoformat()

                # Source from syslog identifier or command
                source = data.get("SYSLOG_IDENTIFIER", data.get("_COMM", "unknown"))

                message = data.get("MESSAGE", "")

                yield LogEntry(
                    timestamp=timestamp,
                    level=level,
                    source=source,
                    message=message,
                    raw=line,
                )
            except (json.JSONDecodeError, ValueError, KeyError):
                continue


def parse_docker(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse Docker container JSON logs."""

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                data = json.loads(line)

                # Docker logs have 'log', 'stream', 'time' fields
                log_msg = data.get("log", "")
                stream = data.get("stream", "stdout")
                timestamp = data.get("time", "")

                # Detect level from message content
                LEVEL_KEYWORDS = {
                    "error": "ERROR",
                    "fail": "ERROR",
                    "warning": "WARN",
                    "warn": "WARN",
                    "debug": "DEBUG",
                }

                level = "INFO"
                msg_lower = log_msg.lower()
                for keyword, lvl in LEVEL_KEYWORDS.items():
                    if keyword in msg_lower:
                        level = lvl
                        break

                # stderr stream implies error
                if stream == "stderr":
                    level = "ERROR"

                yield LogEntry(
                    timestamp=timestamp,
                    level=level,
                    source="docker",
                    message=log_msg.strip(),
                    raw=line,
                )
            except json.JSONDecodeError:
                continue


def parse_json_lines(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse generic JSON Lines format."""

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                data = json.loads(line)

                # Extract common log fields
                timestamp = data.get(
                    "timestamp", data.get("time", data.get("@timestamp", ""))
                )
                level = data.get(
                    "level", data.get("severity", data.get("log_level", "INFO"))
                ).upper()
                source = data.get(
                    "source", data.get("logger", data.get("component", "unknown"))
                )
                message = data.get(
                    "message", data.get("msg", data.get("log", json.dumps(data)))
                )

                yield LogEntry(
                    timestamp=str(timestamp),
                    level=level
                    if level in ["ERROR", "WARN", "INFO", "DEBUG"]
                    else "INFO",
                    source=source,
                    message=str(message),
                    raw=line,
                )
            except (json.JSONDecodeError, ValueError):
                continue


def parse_apache(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse Apache/Nginx access logs."""
    # Combined log format
    apache_pattern = re.compile(
        r"^(\S+)\s+"  # IP
        r"\S+\s+"  # ident
        r"\S+\s+"  # auth
        r"\[([^\]]+)\]\s+"  # timestamp [day/month/year:hour:minute:second zone]
        r'"(\S+)\s+(\S+)\s+(\S+)"\s+'  # method url protocol
        r"(\d{3})\s+"  # status
        r"(\S+)\s+"  # bytes
        r'"([^"]*)"\s+'  # referrer
        r'"([^"]*)"'  # user-agent
    )

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            match = apache_pattern.match(line)
            if match:
                (
                    ip,
                    timestamp,
                    method,
                    url,
                    protocol,
                    status,
                    bytes_sent,
                    referrer,
                    user_agent,
                ) = match.groups()

                # Status code to level mapping
                status_int = int(status)
                if status_int >= 500:
                    level = "ERROR"
                elif status_int >= 400:
                    level = "WARN"
                else:
                    level = "INFO"

                message = f"{method} {url} {status} {bytes_sent}b"

                yield LogEntry(
                    timestamp=timestamp,
                    level=level,
                    source="apache/nginx",
                    message=message,
                    raw=line,
                )
            else:
                # Fall back to plain text
                yield LogEntry(
                    timestamp="",
                    level="INFO",
                    source="apache/nginx",
                    message=line,
                    raw=line,
                )


def parse_plain(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse plain text logs with best-effort extraction."""
    LEVEL_KEYWORDS = {
        "error": "ERROR",
        "fail": "ERROR",
        "failed": "ERROR",
        "failure": "ERROR",
        "critical": "ERROR",
        "fatal": "ERROR",
        "exception": "ERROR",
        "crash": "ERROR",
        "warning": "WARN",
        "warn": "WARN",
        "caution": "WARN",
        "debug": "DEBUG",
        "trace": "DEBUG",
    }

    # Try to extract timestamp patterns
    timestamp_patterns = [
        r"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}",  # ISO 8601
        r"\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}",  # MM/DD/YYYY
        r"\d{2}-\d{2}-\d{4}\s+\d{2}:\d{2}:\d{2}",  # DD-MM-YYYY
    ]

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    import sys

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Detect level
            level = "INFO"
            msg_lower = line.lower()
            for keyword, lvl in LEVEL_KEYWORDS.items():
                if keyword in msg_lower:
                    level = lvl
                    break

            # Try to extract timestamp
            timestamp = ""
            for pattern in timestamp_patterns:
                match = re.search(pattern, line)
                if match:
                    timestamp = match.group(0)
                    break

            yield LogEntry(
                timestamp=timestamp,
                level=level,
                source="unknown",
                message=line,
                raw=line,
            )
