"""CLI interface for the ticket triage tool."""

import json
import sys
from pathlib import Path
from typing import Optional

import click

from ticket_triage import __version__
from ticket_triage.triage import triage, load_rules, TriageResult


def format_text_output(result: TriageResult) -> str:
    """Format triage result as human-readable text."""
    lines = [
        f"Category: {result.category}",
        f"Priority: {result.priority}",
        f"Suggested action: {result.action}",
        f"Escalate to: {result.escalate_to}",
        f"Related KB: {result.kb}",
        f"Root cause signals: {result.signals}",
        f"Confidence: {result.confidence}",
    ]
    return "\n".join(lines)


def format_json_output(result: TriageResult) -> str:
    """Format triage result as JSON."""
    data = {
        "category": result.category,
        "priority": result.priority.split()[0],  # Just the P1/P2/P3/P4 code
        "action": result.action,
        "escalate_to": result.escalate_to,
        "kb": result.kb,
        "signals": result.signals,
        "confidence": result.confidence,
        "flag_l2": result.flag_l2,
    }
    return json.dumps(data, indent=2)


def get_input_text(file_path: Optional[str]) -> str:
    """Get input text from file or stdin."""
    if file_path:
        # Read from file
        path = Path(file_path)
        if not path.exists():
            click.echo(f"Error: File not found: {file_path}", err=True)
            sys.exit(1)
        return path.read_text(encoding="utf-8")

    # Check if stdin has data (piped input)
    if not sys.stdin.isatty():
        return sys.stdin.read()

    return None


@click.command()
@click.option("--file", "-f", type=click.Path(), help="Read ticket from file")
@click.option("--llm", is_flag=True, help="Use local Ollama for enhanced triage")
@click.option("--json", "output_json", is_flag=True, help="Output as JSON")
@click.version_option(version=__version__, prog_name="ticket-triage")
def triage_cli(file: Optional[str], llm: bool, output_json: bool):
    """Triage a support ticket. Reads from stdin if no file provided.

    Examples:
        Get-Content ticket.txt | ticket-triage
        ticket-triage --file C:\tickets\ticket.txt
        echo "User can't login" | ticket-triage --json
    """
    # Get input text
    ticket_text = get_input_text(file)

    if ticket_text is None:
        click.echo(
            "Error: No input provided. Use --file or pipe ticket text via stdin.",
            err=True,
        )
        click.echo("\nExamples:", err=True)
        click.echo("  Get-Content ticket.txt | ticket-triage", err=True)
        click.echo("  ticket-triage --file C:\\tickets\\ticket.txt", err=True)
        sys.exit(1)

    # Strip whitespace and check for empty input
    ticket_text = ticket_text.strip()
    if not ticket_text:
        click.echo("Error: Empty input provided.", err=True)
        sys.exit(1)

    # Load rules
    rules = load_rules()

    # Run triage
    try:
        result = triage(ticket_text, rules, use_llm=llm)
    except ValueError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"Error processing ticket: {e}", err=True)
        sys.exit(1)

    # Output result
    if output_json:
        click.echo(format_json_output(result))
    else:
        click.echo(format_text_output(result))

    # Exit with code 2 if L2 escalation required
    if result.flag_l2:
        sys.exit(2)

    sys.exit(0)


def main():
    """Main entry point for the CLI."""
    triage_cli()


if __name__ == "__main__":
    main()
