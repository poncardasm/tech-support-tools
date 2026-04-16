"""Output formatting utilities."""

import sys
from typing import Literal

import click


def write_output(status: Literal["OK", "FAIL"], message: str) -> None:
    """Write formatted output to stdout.

    Args:
        status: OK or FAIL
        message: The message to display
    """
    prefix = f"[{status:4}]"
    output = f"{prefix} {message}"
    click.echo(output)
