"""Output formatting for ad-provision CLI."""

import sys
from typing import Optional


def write_output(type_: str, message: str, file: Optional[object] = None):
    """Write formatted output to stdout or stderr.

    Args:
        type_: Output type - OK, FAIL, TEMP, WARN
        message: Message to display
        file: Output stream (default: stdout)
    """
    prefix = {
        "OK": "[OK]   ",
        "FAIL": "[FAIL] ",
        "TEMP": "[TEMP] ",
        "WARN": "[WARN] ",
        "DRY": "[DRY]  ",
    }

    output = f"{prefix.get(type_, '[????] ')}{message}"

    if file is None:
        file = sys.stdout if type_ != "FAIL" else sys.stderr

    print(output, file=file)


def write_ok(message: str):
    """Write OK message."""
    write_output("OK", message)


def write_fail(message: str):
    """Write FAIL message to stderr."""
    write_output("FAIL", message)


def write_temp(message: str):
    """Write TEMP (temporary) message."""
    write_output("TEMP", message)


def write_warn(message: str):
    """Write WARN message."""
    write_output("WARN", message)


def write_dry(message: str):
    """Write DRY-RUN message."""
    write_output("DRY", message)
