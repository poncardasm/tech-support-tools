"""Configuration utilities for IT Knowledge CLI (Windows)."""

import os
from pathlib import Path


def get_config_path() -> Path:
    """Return the configuration directory path for Windows.

    Uses %APPDATA%\it-kb as the config location.
    """
    appdata = os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming")
    return Path(appdata) / "it-kb"


def get_index_path() -> Path:
    """Return the vector database path."""
    return get_config_path() / "index.db"


def ensure_config_dir():
    """Ensure the configuration directory exists."""
    get_config_path().mkdir(parents=True, exist_ok=True)
