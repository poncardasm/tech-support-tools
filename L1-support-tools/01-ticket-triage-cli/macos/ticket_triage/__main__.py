"""Main entry point for ticket-triage CLI."""

import click
import sys
from pathlib import Path

from .triage import load_rules, triage, format_result, format_json
from . import __version__


@click.command()
@click.option(
    "--file", "-f", type=click.Path(exists=True), help="Read ticket from file"
)
@click.option("--llm", is_flag=True, help="Use local Ollama for enhanced triage")
@click.option("--json", "output_json", is_flag=True, help="Output as JSON")
@click.version_option(version=__version__)
def cli(file, llm, output_json):
    """Triage a support ticket. Reads from stdin if no file provided."""
    # Load rules
    rules = load_rules()

    # Get input
    if file:
        with open(file, "r", encoding="utf-8") as f:
            ticket_text = f.read()
    elif not sys.stdin.isatty():
        ticket_text = sys.stdin.read()
    else:
        click.echo(
            "Error: No input provided. Use --file or pipe ticket text via stdin.",
            err=True,
        )
        sys.exit(1)

    # Validate input
    if not ticket_text or not ticket_text.strip():
        click.echo("Error: Empty ticket text provided.", err=True)
        sys.exit(1)

    # Run triage
    try:
        result = triage(ticket_text, rules, use_llm=llm)
    except Exception as e:
        click.echo(f"Error during triage: {e}", err=True)
        sys.exit(1)

    # Output result
    if output_json:
        click.echo(format_json(result))
    else:
        click.echo(format_result(result))

    # Exit with appropriate code
    if result.flag_l2:
        sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    cli()
