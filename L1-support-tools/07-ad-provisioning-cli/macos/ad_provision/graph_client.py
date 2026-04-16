"""Microsoft Graph API client with Azure AD authentication."""

from typing import Optional
from azure.identity import ClientSecretCredential, CertificateCredential
from msgraph import GraphServiceClient
from ad_provision.config import load_config


def get_credential(config: dict):
    """Get Azure credential based on configuration.

    Supports either certificate-based or client secret authentication.
    Certificate-based auth is preferred for production.

    Args:
        config: Configuration dictionary

    Returns:
        Azure credential object
    """
    tenant_id = config["AZURE_TENANT_ID"]
    client_id = config["AZURE_CLIENT_ID"]

    # Prefer certificate-based auth if available
    if config.get("AZURE_CERTIFICATE_PATH"):
        return CertificateCredential(
            tenant_id=tenant_id,
            client_id=client_id,
            certificate_path=config["AZURE_CERTIFICATE_PATH"],
        )

    # Fall back to client secret
    return ClientSecretCredential(
        tenant_id=tenant_id,
        client_id=client_id,
        client_secret=config["AZURE_CLIENT_SECRET"],
    )


def get_graph_client() -> GraphServiceClient:
    """Get authenticated Microsoft Graph client.

    Returns:
        GraphServiceClient: Authenticated Graph API client

    Raises:
        FileNotFoundError: If config file doesn't exist
        ValueError: If configuration is invalid
    """
    config = load_config()
    credential = get_credential(config)

    return GraphServiceClient(credential)


def test_connection() -> bool:
    """Test connection to Microsoft Graph API.

    Returns:
        bool: True if connection successful

    Raises:
        Exception: If connection fails
    """
    client = get_graph_client()
    # Try to get organization info as a connection test
    result = client.organization.get()
    return result is not None
