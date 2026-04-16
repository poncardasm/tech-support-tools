"""Configuration loading for ad-provision."""

import os
from pathlib import Path
from dotenv import load_dotenv


def load_config() -> dict:
    """Load configuration from ~/.config/ad-provision/creds.env.

    Returns:
        dict: Configuration with AZURE_CLIENT_ID, AZURE_TENANT_ID,
              AZURE_CERTIFICATE_PATH

    Raises:
        FileNotFoundError: If config file doesn't exist
        ValueError: If required configuration is missing
    """
    config_path = Path.home() / ".config" / "ad-provision" / "creds.env"

    if not config_path.exists():
        raise FileNotFoundError(
            f"Config not found at {config_path}. "
            "Copy config/creds.env.example to that location and fill in your values."
        )

    load_dotenv(config_path)

    config = {
        "AZURE_CLIENT_ID": os.getenv("AZURE_CLIENT_ID"),
        "AZURE_TENANT_ID": os.getenv("AZURE_TENANT_ID"),
        "AZURE_CERTIFICATE_PATH": os.getenv("AZURE_CERTIFICATE_PATH"),
        "AZURE_CLIENT_SECRET": os.getenv("AZURE_CLIENT_SECRET"),
    }

    # Expand ~ in certificate path
    if config["AZURE_CERTIFICATE_PATH"]:
        config["AZURE_CERTIFICATE_PATH"] = os.path.expanduser(
            config["AZURE_CERTIFICATE_PATH"]
        )

    # Validate required fields
    if not config["AZURE_CLIENT_ID"]:
        raise ValueError("AZURE_CLIENT_ID is required in config")
    if not config["AZURE_TENANT_ID"]:
        raise ValueError("AZURE_TENANT_ID is required in config")

    # Must have either certificate path or client secret
    if not config["AZURE_CERTIFICATE_PATH"] and not config["AZURE_CLIENT_SECRET"]:
        raise ValueError(
            "Either AZURE_CERTIFICATE_PATH or AZURE_CLIENT_SECRET is required"
        )

    return config
