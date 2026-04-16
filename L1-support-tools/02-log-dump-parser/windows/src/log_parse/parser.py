"""Log file parsing with format detection for Windows."""

import re
import json
import sys
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

    path = Path(file_path)

    # Check extension first
    if path.suffix.lower() == ".evtx":
        return "evtx"

    with open(file_path, "rb") as f:
        # Read first 2KB for detection
        header = f.read(2048)

    # Split into lines for analysis
    lines = header.split(b"\n")[:10]  # Check first 10 lines

    for line in lines:
        if not line.strip():
            continue

        # Windows Event XML format
        if b"<Event" in line or b"<Event xmlns" in header:
            return "evtx_xml"

        # IIS log format
        if b"#Fields:" in line or b"#Software:" in line or b"#Version:" in line:
            return "iis"

        # Apache/Nginx access log (IP address at start)
        if re.match(rb"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", line):
            return "iis"

        # JSON lines
        if line.strip().startswith(b"{"):
            try:
                json.loads(line)
                return "json_lines"
            except json.JSONDecodeError:
                pass

        # Syslog pattern (RFC 3164) - common in Windows apps
        syslog_pattern = rb"^[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}"
        if re.match(syslog_pattern, line):
            return "syslog"

    return "plain"


def parse_file(file_path: Optional[str], format: str = None) -> Iterator[LogEntry]:
    """Parse a log file and yield LogEntry objects."""
    detected = format or detect_format(file_path)

    if detected == "evtx":
        yield from parse_evtx(file_path)
    elif detected == "evtx_xml":
        yield from parse_evtx_xml(file_path)
    elif detected == "json_lines":
        yield from parse_json_lines(file_path)
    elif detected == "iis":
        yield from parse_iis(file_path)
    elif detected == "syslog":
        yield from parse_syslog(file_path)
    else:
        yield from parse_plain(file_path)


def _get_file(file_path: Optional[str], mode: str = "r"):
    """Get file handle or stdin."""
    if file_path is None:
        return sys.stdin
    return open(file_path, mode, errors="ignore")


def parse_evtx(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse Windows Event Log (.evtx) format using python-evtx."""
    try:
        import Evtx.Evtx as evtx
        from xml.etree import ElementTree
    except ImportError:
        # Fallback to plain text if python-evtx not available
        yield from parse_plain(file_path)
        return

    if file_path is None:
        # Can't parse binary format from stdin easily
        yield from parse_plain(file_path)
        return

    # Level mapping from Windows Event Log
    LEVEL_MAP = {
        "1": "CRITICAL",
        "2": "ERROR",
        "3": "WARN",
        "4": "INFO",
        "5": "DEBUG",
    }

    XML_NS = "{http://schemas.microsoft.com/win/2004/08/events/event}"

    try:
        with evtx.Evtx(file_path) as log:
            for record in log.records():
                try:
                    xml = record.xml()
                    root = ElementTree.fromstring(xml)

                    # Extract System element
                    system = root.find(f".//{XML_NS}System")
                    if system is None:
                        continue

                    # Timestamp
                    time_created = system.find(f"{XML_NS}TimeCreated")
                    timestamp = ""
                    if time_created is not None:
                        timestamp = time_created.get("SystemTime", "")

                    # Level
                    level_elem = system.find(f"{XML_NS}Level")
                    level = "INFO"
                    if level_elem is not None and level_elem.text:
                        level = LEVEL_MAP.get(level_elem.text, "INFO")

                    # Source/Provider
                    provider = system.find(f"{XML_NS}Provider")
                    source = "Unknown"
                    if provider is not None:
                        source = provider.get("Name", "Unknown")

                    # Event ID for message context
                    event_id_elem = system.find(f"{XML_NS}EventID")
                    event_id = ""
                    if event_id_elem is not None and event_id_elem.text:
                        event_id = level_elem.text

                    # Message from data section or rendering info
                    message = ""

                    # Try to get message from EventData
                    data = root.find(f".//{XML_NS}EventData")
                    if data is not None:
                        data_items = []
                        for d in data.findall(f"{XML_NS}Data"):
                            name = d.get("Name", "")
                            val = d.text or ""
                            if name:
                                data_items.append(f"{name}: {val}")
                            else:
                                data_items.append(val)
                        if data_items:
                            message = " | ".join(data_items)

                    # Try to get from RenderingInfo
                    if not message:
                        rendering = root.find(f".//{XML_NS}RenderingInfo")
                        if rendering is not None:
                            msg_elem = rendering.find(f"{XML_NS}Message")
                            if msg_elem is not None and msg_elem.text:
                                message = msg_elem.text

                    # Fallback to raw XML summary
                    if not message:
                        message = f"EventID {event_id}" if event_id else "No message"

                    yield LogEntry(
                        timestamp=timestamp,
                        level=level,
                        source=source,
                        message=message[:500],
                        raw=xml[:1000],
                    )
                except Exception:
                    # Skip corrupted records
                    continue
    except Exception as e:
        # If we can't parse EVTX, fall back to plain text
        sys.stderr.write(f"Warning: Could not parse EVTX file: {e}\n")
        yield from parse_plain(file_path)


def parse_evtx_xml(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse Windows Event Log exported as XML."""
    from xml.etree import ElementTree

    LEVEL_MAP = {
        "1": "CRITICAL",
        "2": "ERROR",
        "3": "WARN",
        "4": "INFO",
        "5": "DEBUG",
    }

    XML_NS = "{http://schemas.microsoft.com/win/2004/08/events/event}"

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    with get_file() as f:
        # Read entire file for XML parsing
        try:
            content = f.read()
            root = ElementTree.fromstring(content)

            for event in root.findall(f".//{XML_NS}Event"):
                try:
                    system = event.find(f"{XML_NS}System")
                    if system is None:
                        continue

                    time_created = system.find(f"{XML_NS}TimeCreated")
                    timestamp = (
                        time_created.get("SystemTime", "")
                        if time_created is not None
                        else ""
                    )

                    level_elem = system.find(f"{XML_NS}Level")
                    level = "INFO"
                    if level_elem is not None and level_elem.text:
                        level = LEVEL_MAP.get(level_elem.text, "INFO")

                    provider = system.find(f"{XML_NS}Provider")
                    source = (
                        provider.get("Name", "Unknown")
                        if provider is not None
                        else "Unknown"
                    )

                    # Get message
                    message = ""
                    data = event.find(f"{XML_NS}EventData")
                    if data is not None:
                        data_items = []
                        for d in data.findall(f"{XML_NS}Data"):
                            name = d.get("Name", "")
                            val = d.text or ""
                            if name:
                                data_items.append(f"{name}: {val}")
                            else:
                                data_items.append(val)
                        if data_items:
                            message = " | ".join(data_items)

                    yield LogEntry(
                        timestamp=timestamp,
                        level=level,
                        source=source,
                        message=message[:500] if message else "No message",
                        raw=ElementTree.tostring(event, encoding="unicode")[:1000],
                    )
                except Exception:
                    continue
        except ElementTree.ParseError:
            # Fall back to line-by-line parsing
            yield from parse_plain(file_path)


def parse_json_lines(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse generic JSON Lines format."""

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                data = json.loads(line)

                # Extract common log fields with various naming conventions
                timestamp = data.get(
                    "timestamp",
                    data.get(
                        "time", data.get("@timestamp", data.get("TimeGenerated", ""))
                    ),
                )
                level_val = data.get(
                    "level",
                    data.get(
                        "severity", data.get("log_level", data.get("Level", "INFO"))
                    ),
                )
                # Handle numeric level values (Windows Event Log uses 1-5)
                if isinstance(level_val, int):
                    level_map = {
                        1: "CRITICAL",
                        2: "ERROR",
                        3: "WARN",
                        4: "INFO",
                        5: "DEBUG",
                    }
                    level = level_map.get(level_val, "INFO")
                else:
                    level = str(level_val).upper()
                source = data.get(
                    "source",
                    data.get(
                        "logger",
                        data.get("component", data.get("ProviderName", "unknown")),
                    ),
                )
                message = data.get(
                    "message",
                    data.get(
                        "msg", data.get("log", data.get("Message", json.dumps(data)))
                    ),
                )

                yield LogEntry(
                    timestamp=str(timestamp),
                    level=level
                    if level in ["ERROR", "WARN", "INFO", "DEBUG", "CRITICAL"]
                    else "INFO",
                    source=str(source),
                    message=str(message),
                    raw=line,
                )
            except (json.JSONDecodeError, ValueError):
                continue


def parse_iis(file_path: Optional[str]) -> Iterator[LogEntry]:
    """Parse IIS log format."""
    # IIS format: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

    fields = None
    header_pattern = re.compile(r"^#Fields:\s*(.+)$")

    with get_file() as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                # Parse header directives
                match = header_pattern.match(line)
                if match:
                    fields = [f.strip() for f in match.group(1).split(" ")]
                continue

            # Parse log entry
            parts = line.split(" ")
            if len(parts) < 3:
                continue

            # Default field positions (W3C standard)
            if fields:
                # Build dict from fields
                entry = {}
                for i, field in enumerate(fields):
                    if i < len(parts):
                        entry[field] = parts[i]

                date = entry.get("date", "")
                time = entry.get("time", "")
                timestamp = f"{date} {time}" if date and time else ""

                method = entry.get("cs-method", "")
                url = entry.get("cs-uri-stem", "")
                status = entry.get("sc-status", "200")
                time_taken = entry.get("time-taken", "")

                try:
                    status_int = int(status)
                    if status_int >= 500:
                        level = "ERROR"
                    elif status_int >= 400:
                        level = "WARN"
                    else:
                        level = "INFO"
                except ValueError:
                    level = "INFO"

                source = entry.get("s-ip", "IIS")
                message = f"{method} {url} {status}"
                if time_taken:
                    message += f" ({time_taken}ms)"
            else:
                # Assume standard format without headers
                # date time c-ip cs-method cs-uri-stem sc-status
                if len(parts) >= 6:
                    timestamp = f"{parts[0]} {parts[1]}"
                    level = "INFO"
                    try:
                        status = int(parts[5])
                        if status >= 500:
                            level = "ERROR"
                        elif status >= 400:
                            level = "WARN"
                    except ValueError:
                        pass
                    source = parts[2]  # c-ip
                    message = f"{parts[3]} {parts[4]} {parts[5]}"
                else:
                    level = "INFO"
                    timestamp = ""
                    source = "IIS"
                    message = line

            yield LogEntry(
                timestamp=timestamp,
                level=level,
                source=source,
                message=message,
                raw=line,
            )


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
        r"\d{2}:\d{2}:\d{2}",  # Simple time
    ]

    def get_file():
        if file_path is None:
            return sys.stdin
        return open(file_path, "r", errors="ignore")

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
