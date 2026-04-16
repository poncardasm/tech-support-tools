"""Configuration utilities for IT Knowledge CLI."""

from pathlib import Path


def get_config_path() -> Path:
    """Return the configuration directory path."""
    return Path.home() / ".config" / "it-kb"


def get_index_path() -> Path:
    """Return the vector database path."""
    return get_config_path() / "index.db"


def ensure_config_dir():
    """Ensure the configuration directory exists."""
    get_config_path().mkdir(parents=True, exist_ok=True)
