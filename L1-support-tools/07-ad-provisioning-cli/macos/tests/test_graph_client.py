"""Tests for graph client module."""

import pytest
from unittest.mock import patch, MagicMock

from ad_provision.graph_client import get_credential, get_graph_client


class TestGetCredential:
    """Tests for get_credential function."""

    @patch("ad_provision.graph_client.CertificateCredential")
    def test_certificate_credential_preferred(self, mock_cert_class):
        """Test that certificate credential is used when available."""
        mock_cert = MagicMock()
        mock_cert_class.return_value = mock_cert

        config = {
            "AZURE_TENANT_ID": "test-tenant",
            "AZURE_CLIENT_ID": "test-client",
            "AZURE_CERTIFICATE_PATH": "/path/to/cert.pem",
            "AZURE_CLIENT_SECRET": "test-secret",
        }

        credential = get_credential(config)

        mock_cert_class.assert_called_once_with(
            tenant_id="test-tenant",
            client_id="test-client",
            certificate_path="/path/to/cert.pem",
        )

    @patch("ad_provision.graph_client.ClientSecretCredential")
    def test_client_secret_fallback(self, mock_secret_class):
        """Test that client secret is used when no certificate."""
        mock_secret = MagicMock()
        mock_secret_class.return_value = mock_secret

        config = {
            "AZURE_TENANT_ID": "test-tenant",
            "AZURE_CLIENT_ID": "test-client",
            "AZURE_CERTIFICATE_PATH": None,
            "AZURE_CLIENT_SECRET": "test-secret",
        }

        credential = get_credential(config)

        mock_secret_class.assert_called_once_with(
            tenant_id="test-tenant",
            client_id="test-client",
            client_secret="test-secret",
        )


class TestGetGraphClient:
    """Tests for get_graph_client function."""

    @patch("ad_provision.graph_client.load_config")
    @patch("ad_provision.graph_client.get_credential")
    @patch("ad_provision.graph_client.GraphServiceClient")
    def test_get_graph_client_success(
        self, mock_client_class, mock_get_credential, mock_load_config
    ):
        """Test successful graph client creation."""
        mock_load_config.return_value = {
            "AZURE_CLIENT_ID": "test-client",
            "AZURE_TENANT_ID": "test-tenant",
            "AZURE_CERTIFICATE_PATH": "/path/to/cert.pem",
        }
        mock_credential = MagicMock()
        mock_get_credential.return_value = mock_credential
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client

        client = get_graph_client()

        mock_load_config.assert_called_once()
        mock_get_credential.assert_called_once()
        mock_client_class.assert_called_once_with(mock_credential)
        assert client == mock_client

    @patch("ad_provision.graph_client.load_config")
    def test_get_graph_client_config_error(self, mock_load_config):
        """Test that config errors are propagated."""
        mock_load_config.side_effect = FileNotFoundError("Config not found")

        with pytest.raises(FileNotFoundError) as exc_info:
            get_graph_client()

        assert "Config not found" in str(exc_info.value)
