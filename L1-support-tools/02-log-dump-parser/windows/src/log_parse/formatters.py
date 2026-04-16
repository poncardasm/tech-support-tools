"""Output formatters for log analysis results."""

import json
import csv
import io
from typing import Dict, Any, List
from .parser import LogEntry


def format_text(analysis: Dict[str, Any], stats: Dict[str, Any]) -> str:
    """Format results as human-readable text."""
    lines = []

    # Header
    lines.append("=== Log Summary ===")
    lines.append(f"File: {stats.get('file', 'unknown')}")
    lines.append(f"Format: {stats.get('format', 'unknown')}")
    lines.append(
        f"Lines parsed: {stats.get('total', 0)} | Filtered: {stats.get('filtered', 0)}"
    )
    lines.append(
        f"Errors: {stats.get('errors', 0)} | Warnings: {stats.get('warnings', 0)}"
    )
    lines.append("")

    # Errors
    error_counts = analysis.get("error_counts", [])
    if error_counts:
        lines.append(f"[ERRORS — {stats.get('errors', 0)} total]")
        for msg, count in error_counts:
            lines.append(f"  {count}x {msg}")
        lines.append("")

    # Warnings
    warning_counts = analysis.get("warning_counts", [])
    if warning_counts:
        lines.append(f"[WARNINGS — {stats.get('warnings', 0)} total]")
        for msg, count in warning_counts:
            lines.append(f"  {count}x {msg}")
        lines.append("")

    # Statistics
    lines.append("[STATISTICS]")

    time_range = analysis.get("time_range")
    if time_range and time_range.get("start") and time_range.get("end"):
        lines.append(f"  Time range: {time_range['start']} → {time_range['end']}")

    top_sources = analysis.get("top_sources", [])
    if top_sources:
        lines.append(f"  Top sources:")
        for source, count in top_sources:
            lines.append(f"    {source}: {count} entries")

    lines.append("")

    # Suggested actions
    from .analyzer import suggest_actions

    suggestions = suggest_actions(analysis)
    if suggestions:
        lines.append("[SUGGESTED ACTIONS]")
        for suggestion in suggestions:
            lines.append(f"  - {suggestion}")
        lines.append("")

    return "\n".join(lines)


def format_json(analysis: Dict[str, Any], stats: Dict[str, Any]) -> str:
    """Format results as JSON."""
    result = {
        "stats": stats,
        "analysis": {
            "errors": [
                {"message": msg, "count": count}
                for msg, count in analysis.get("error_counts", [])
            ],
            "warnings": [
                {"message": msg, "count": count}
                for msg, count in analysis.get("warning_counts", [])
            ],
            "sources": [
                {"name": name, "count": count}
                for name, count in analysis.get("top_sources", [])
            ],
        },
        "time_range": analysis.get("time_range"),
    }

    from .analyzer import suggest_actions

    suggestions = suggest_actions(analysis)
    if suggestions:
        result["suggestions"] = suggestions

    return json.dumps(result, indent=2)


def format_csv(entries: List[LogEntry]) -> str:
    """Format entries as CSV."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow(["timestamp", "level", "source", "message"])

    # Data rows
    for entry in entries:
        writer.writerow([entry.timestamp, entry.level, entry.source, entry.message])

    return output.getvalue()
