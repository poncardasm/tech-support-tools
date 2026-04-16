"""Main entry point for log-parse CLI."""

import click
import sys
from pathlib import Path
from typing import Optional

from .parser import parse_file, detect_format
from .analyzer import analyze_entries, filter_entries
from .formatters import format_text, format_json, format_csv


@click.command()
@click.argument("file", type=click.Path(exists=True, allow_dash=True))
@click.option(
    "--format",
    "-f",
    help="Force log format (syslog, journald, docker, json_lines, apache, plain)",
)
@click.option(
    "--level", "-l", help="Filter by level: ERROR, WARN, INFO, DEBUG (comma-separated)"
)
@click.option("--since", help="Filter from timestamp")
@click.option("--until", help="Filter until timestamp")
@click.option("--source", "-s", help="Filter by source/process name")
@click.option("--grep", "-g", help="Search within message text")
@click.option(
    "--top", "-t", type=int, default=10, help="Show top N patterns (default: 10)"
)
@click.option("--json", "output_json", is_flag=True, help="Output as JSON")
@click.option("--csv", "output_csv", is_flag=True, help="Output as CSV")
@click.option("--output", "-o", type=click.Path(), help="Write output to file")
def cli(
    file: str,
    format: Optional[str],
    level: Optional[str],
    since: Optional[str],
    until: Optional[str],
    source: Optional[str],
    grep: Optional[str],
    top: int,
    output_json: bool,
    output_csv: bool,
    output: Optional[str],
):
    """Parse and analyze log files.

    FILE: Path to log file (use - for stdin)
    """
    # Handle stdin
    file_path = None if file == "-" else file

    # Detect or use forced format
    detected_format = format or detect_format(file_path)

    # Parse entries
    entries = list(parse_file(file_path, detected_format))

    # Apply filters
    level_filter = level.split(",") if level else None
    filtered_entries = filter_entries(
        entries, level=level_filter, since=since, until=until, source=source, grep=grep
    )

    # Analyze
    analysis = analyze_entries(filtered_entries, top_n=top)

    # Calculate stats
    stats = {
        "file": file if file_path else "<stdin>",
        "format": detected_format,
        "total": len(entries),
        "filtered": len(filtered_entries),
        "errors": sum(1 for e in filtered_entries if e.level == "ERROR"),
        "warnings": sum(1 for e in filtered_entries if e.level == "WARN"),
    }

    # Generate output
    if output_json:
        result = format_json(analysis, stats)
    elif output_csv:
        result = format_csv(filtered_entries)
    else:
        result = format_text(analysis, stats)

    # Write output
    if output:
        with open(output, "w") as f:
            f.write(result)
        click.echo(f"Output written to {output}")
    else:
        click.echo(result)


if __name__ == "__main__":
    cli()
