"""Log entry analysis and filtering."""

import re
from collections import Counter
from datetime import datetime
from typing import List, Optional, Dict, Any
from .parser import LogEntry


def normalize_message(msg: str) -> str:
    """Normalize a message for grouping by replacing variable parts."""
    # Replace IP addresses
    msg = re.sub(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", "[IP]", msg)
    # Replace hex IDs
    msg = re.sub(r"\b[0-9a-fA-F]{8,}\b", "[ID]", msg)
    # Replace large numbers (IDs, timestamps)
    msg = re.sub(r"\b\d{6,}\b", "[NUM]", msg)
    # Replace quoted strings that look like IDs
    msg = re.sub(r'"[0-9a-f-]{8,}"', '"[ID]"', msg)
    # Replace UUIDs
    msg = re.sub(
        r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b",
        "[UUID]",
        msg,
    )

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

    # Time filtering (basic string comparison for now)
    if since:
        filtered = [e for e in filtered if e.timestamp and e.timestamp >= since]

    if until:
        filtered = [e for e in filtered if e.timestamp and e.timestamp <= until]

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

        if entry.level == "ERROR":
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

    # Common patterns and suggestions
    patterns = {
        "connection refused": "Check if the target service is running and accessible",
        "connection timed out": "Check network connectivity and firewall rules",
        "authentication fail": "Review credentials and authentication configuration",
        "permission denied": "Check file permissions and user access rights",
        "disk full": "Free up disk space or expand storage",
        "memory": "Check memory usage and consider restarting the service",
        "cpu": "Check CPU usage and investigate high-load processes",
        "timeout": "Review timeout settings and service performance",
        "dns": "Check DNS resolution and network configuration",
        "certificate": "Check SSL/TLS certificate validity and configuration",
        "database": "Check database connectivity and health",
        "lock": "Check for stale locks and resource contention",
        "segmentation fault": "Check for application bugs and core dumps",
        "core dump": "Analyze core dump for application issues",
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
