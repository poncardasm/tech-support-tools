"""Log entry analysis and filtering for Windows logs."""

import re
from collections import Counter
from datetime import datetime
from typing import List, Optional, Dict, Any
from .parser import LogEntry


def normalize_message(msg: str) -> str:
    """Normalize a message for grouping by replacing variable parts."""
    # Replace IP addresses
    msg = re.sub(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", "[IP]", msg)
    # Replace Windows-style GUIDs in braces (before hex IDs to avoid partial match)
    msg = re.sub(
        r"\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}",
        "[GUID]",
        msg,
    )
    # Replace UUIDs (before hex IDs to avoid partial match)
    msg = re.sub(
        r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b",
        "[UUID]",
        msg,
    )
    # Replace hex IDs
    msg = re.sub(r"\b[0-9a-fA-F]{8,}\b", "[ID]", msg)
    # Replace large numbers (IDs, timestamps)
    msg = re.sub(r"\b\d{6,}\b", "[NUM]", msg)
    # Replace quoted strings that look like IDs
    msg = re.sub(r'"[0-9a-f-]{8,}"', '"[ID]"', msg)
    # Replace PIDs and thread IDs
    msg = re.sub(r"\bPID[:\s]\d+\b", "PID:[PID]", msg, flags=re.IGNORECASE)
    msg = re.sub(r"\bTID[:\s]\d+\b", "TID:[TID]", msg, flags=re.IGNORECASE)
    # Replace process IDs in parentheses
    msg = re.sub(r"\(\d+\)", "([PID])", msg)

    return msg[:150]  # Truncate long messages


def filter_entries(
    entries: List[LogEntry],
    level: Optional[List[str]] = None,
    since: Optional[str] = None,
    until: Optional[str] = None,
    source: Optional[str] = None,
    grep: Optional[str] = None,
) -> List[LogEntry]:
    """Filter log entries based on criteria."""
    filtered = entries

    if level:
        level_upper = [l.upper() for l in level]
        filtered = [e for e in filtered if e.level in level_upper]

    if source:
        source_lower = source.lower()
        filtered = [e for e in filtered if source_lower in e.source.lower()]

    if grep:
        grep_lower = grep.lower()
        filtered = [
            e
            for e in filtered
            if grep_lower in e.message.lower() or grep_lower in e.raw.lower()
        ]

    # Time filtering (support prefix matching for partial dates)
    if since:
        filtered = [
            e
            for e in filtered
            if e.timestamp and (e.timestamp >= since or e.timestamp.startswith(since))
        ]

    if until:

        def within_until(ts):
            if not ts:
                return False
            # If timestamp starts with until prefix (e.g., "2024-01-02T10" starts with "2024-01-02"), include it
            if ts.startswith(until):
                return True
            # Otherwise use string comparison
            return ts <= until

        filtered = [e for e in filtered if within_until(e.timestamp)]

    return filtered


def analyze_entries(entries: List[LogEntry], top_n: int = 10) -> Dict[str, Any]:
    """Analyze log entries and return grouped statistics."""
    errors = Counter()
    warnings = Counter()
    infos = Counter()
    sources = Counter()

    timestamps = []

    for entry in entries:
        sources[entry.source] += 1

        if entry.timestamp:
            timestamps.append(entry.timestamp)

        normalized = normalize_message(entry.message)

        if entry.level == "ERROR" or entry.level == "CRITICAL":
            errors[normalized] += 1
        elif entry.level == "WARN":
            warnings[normalized] += 1
        elif entry.level == "INFO":
            infos[normalized] += 1

    # Calculate time range
    time_range = None
    if timestamps:
        try:
            # Sort and get min/max
            sorted_ts = sorted(timestamps)
            time_range = {
                "start": sorted_ts[0] if sorted_ts else None,
                "end": sorted_ts[-1] if sorted_ts else None,
            }
        except:
            pass

    return {
        "error_counts": errors.most_common(top_n),
        "warning_counts": warnings.most_common(top_n),
        "info_counts": infos.most_common(top_n),
        "top_sources": sources.most_common(5),
        "time_range": time_range,
    }


def suggest_actions(analysis: Dict[str, Any]) -> List[str]:
    """Generate suggested actions based on analysis."""
    suggestions = []

    error_messages = [msg for msg, count in analysis.get("error_counts", [])]
    all_messages = error_messages + [
        msg for msg, count in analysis.get("warning_counts", [])
    ]

    # Common patterns and suggestions for Windows
    patterns = {
        # Network/Connection
        "connection refused": "Check if the target service is running and accessible",
        "connection timed out": "Check network connectivity and firewall rules",
        "connection reset": "Check for network instability or firewall blocking",
        "could not connect": "Verify network connectivity and service status",
        # Authentication/Security
        "authentication fail": "Review credentials and authentication configuration",
        "access denied": "Check file permissions and user access rights (use icacls)",
        "permission denied": "Check file permissions and user access rights (use icacls)",
        "logon fail": "Check account status and password",
        "invalid credentials": "Verify username and password",
        # Resources
        "disk full": "Free up disk space or expand storage (use Get-Volume)",
        "out of disk": "Free up disk space or expand storage",
        "no space left": "Free up disk space or expand storage",
        "memory": "Check memory usage and consider restarting the service",
        "out of memory": "Increase available memory or restart the application",
        "cpu": "Check CPU usage and investigate high-load processes",
        "timeout": "Review timeout settings and service performance",
        # System/Driver
        "driver": "Update or reinstall device drivers",
        "dll": "Check for missing or corrupted DLL files",
        "registry": "Check registry permissions and corruption",
        "service": "Check Windows Service configuration and status (use services.msc)",
        # Application
        "exception": "Review application logs for stack traces",
        "crash": "Check application logs and Windows Event Viewer for crash details",
        "fault": "Review application error logs and Windows Event Viewer",
        "hang": "Check for deadlock or infinite loop conditions",
        # Database
        "database": "Check database connectivity and health",
        "sql": "Review SQL errors and database connection settings",
        # Web/IIS
        "500": "Check application error logs for server-side errors",
        "404": "Verify resource exists and URL is correct",
        "403": "Check IIS authentication and authorization settings",
        "502": "Check upstream service status",
        "503": "Check service availability and resource constraints",
        # Windows-specific
        "wmi": "Check WMI repository health and permissions",
        "powershell": "Review PowerShell execution policy and script syntax",
        "netlogon": "Check domain controller connectivity",
        "dns": "Check DNS resolution and network configuration",
        "certificate": "Check SSL/TLS certificate validity and configuration",
        "cryptographic": "Check certificate store and cryptographic providers",
        "lock": "Check for stale locks and resource contention",
        "deadlock": "Check for circular dependencies in resources",
        "segmentation fault": "Check for application bugs and core dumps",
        "core dump": "Analyze core dump for application issues",
        # .NET
        "runtime": "Check .NET Framework/Runtime version compatibility",
        "clr": "Review .NET runtime configuration and version",
    }

    found_suggestions = set()
    for message in all_messages:
        msg_lower = message.lower()
        for pattern, suggestion in patterns.items():
            if pattern in msg_lower and suggestion not in found_suggestions:
                suggestions.append(f'"{message[:40]}..." → {suggestion}')
                found_suggestions.add(suggestion)
                break

    return suggestions[:5]  # Limit to top 5
