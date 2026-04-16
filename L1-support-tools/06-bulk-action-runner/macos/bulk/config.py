"""Configuration and Graph API client."""

import os
from pathlib import Path

import click
from dotenv import load_dotenv


def get_config_dir() -> Path:
    """Get the configuration directory."""
    config_dir = Path.home() / ".config" / "bulk-action"
    config_dir.mkdir(parents=True, exist_ok=True)
    return config_dir


def load_config():
    """Load configuration from environment and creds.env file."""
    config_dir = get_config_dir()
    creds_file = config_dir / "creds.env"

    if creds_file.exists():
        load_dotenv(creds_file)

    return {
        "tenant_id": os.getenv("AZURE_TENANT_ID"),
        "client_id": os.getenv("AZURE_CLIENT_ID"),
        "client_secret": os.getenv("AZURE_CLIENT_SECRET"),
    }


def get_graph_client():
    """Get authenticated Microsoft Graph client.

    Returns:
        GraphServiceClient instance or MockClient for dry-run
    """
    try:
        from msgraph import GraphServiceClient
        from azure.identity import ClientSecretCredential

        config = load_config()

        if not all([config["tenant_id"], config["client_id"], config["client_secret"]]):
            raise click.ClickException(
                "Azure credentials not configured. "
                f"Please set AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET "
                f"in {get_config_dir() / 'creds.env'}"
            )

        credential = ClientSecretCredential(
            tenant_id=config["tenant_id"],
            client_id=config["client_id"],
            client_secret=config["client_secret"],
        )

        client = GraphServiceClient(credentials=credential)
        return client

    except ImportError:
        raise click.ClickException(
            "Required packages not installed. Run: pip install msgraph-sdk azure-identity"
        )


class MockGraphClient:
    """Mock client for dry-run mode."""

    class MockUsers:
        def __init__(self, email):
            self.email = email

        def patch(self, body):
            return None

        def by_user_id(self, user_id):
            return self

    class MockGroups:
        def __init__(self, group_id):
            self.group_id = group_id

        class MockMembers:
            class MockRef:
                def post(self, body):
                    return None

            ref = MockRef()

        members = MockMembers()

        def by_group_id(self, group_id):
            return self

    def __init__(self):
        self.users = self.MockUsers
        self.groups = self.MockGroups


def get_mock_client():
    """Get a mock client for dry-run mode."""
    return MockGraphClient()
