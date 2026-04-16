"""Report generation utilities."""

import csv
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any

import click


def save_report(results: List[Dict[str, Any]], report_path: str) -> None:
    """Save operation results to a CSV report file.

    Args:
        results: List of result dictionaries
        report_path: Path to save the report
    """
    path = Path(report_path)

    fieldnames = ["email", "operation", "result", "detail", "timestamp"]

    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for result in results:
            row = {
                "email": result.get("email", ""),
                "operation": result.get("operation", ""),
                "result": result.get("result", ""),
                "detail": result.get("detail", ""),
                "timestamp": result.get("timestamp", datetime.now().isoformat()),
            }
            writer.writerow(row)

    click.echo(f"Report saved to: {path}")
