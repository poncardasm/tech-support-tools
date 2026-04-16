"""Log Parse - CLI tool for parsing and analyzing log files."""

__version__ = "0.1.0"
__all__ = ["LogEntry", "parse_file", "detect_format"]

from .parser import LogEntry, parse_file, detect_format
