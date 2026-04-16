"""Tests for configuration module."""

import os
import pytest
from pathlib import Path
from unittest.mock import patch, mock_open

from ad_provision.config import load_config


class TestLoadConfig:
    """Tests for load_config function."""

    @patch("ad_provision.config.load_dotenv")
    def test_config_not_found(self, mock_load_dotenv):
        """Test FileNotFoundError when config doesn't exist."""
        with patch("pathlib.Path.exists", return_value=False):
            with pytest.raises(FileNotFoundError) as exc_info:
                load_config()

            assert "Config not found" in str(exc_info.value)

    @patch("ad_provision.config.load_dotenv")
    @patch.dict(
        os.environ,
        {
            "AZURE_CLIENT_ID": "test-client-id",
            "AZURE_TENANT_ID": "test-tenant-id",
            "AZURE_CERTIFICATE_PATH": "~/.config/test.pem",
        },
        clear=True,
    )
    def test_valid_config_with_certificate(self, mock_load_dotenv, tmp_path):
        """Test loading valid config with certificate auth."""
        # Create a mock config file
        config_file = tmp_path / "creds.env"
        config_file.write_text("""
AZURE_CLIENT_ID=test-client-id
AZURE_TENANT_ID=test-tenant-id
AZURE_CERTIFICATE_PATH=~/.config/ad-provision/cert.pem
""")

        with patch("ad_provision.config.Path.home", return_value=tmp_path):
            with patch("ad_provision.config.Path.exists", return_value=True):
                config = load_config()

        assert config["AZURE_CLIENT_ID"] == "test-client-id"
        assert config["AZURE_TENANT_ID"] == "test-tenant-id"
        # Path should be expanded
        assert "~" not in config["AZURE_CERTIFICATE_PATH"]

    @patch("ad_provision.config.load_dotenv")
    @patch.dict(
        os.environ,
        {
            "AZURE_CLIENT_ID": "test-client-id",
            "AZURE_TENANT_ID": "test-tenant-id",
            "AZURE_CLIENT_SECRET": "test-secret",
        },
        clear=True,
    )
    def test_valid_config_with_secret(self, mock_load_dotenv, tmp_path):
        """Test loading valid config with client secret auth."""
        with patch("ad_provision.config.Path.home", return_value=tmp_path):
            with patch("ad_provision.config.Path.exists", return_value=True):
                config = load_config()

        assert config["AZURE_CLIENT_ID"] == "test-client-id"
        assert config["AZURE_TENANT_ID"] == "test-tenant-id"
        assert config["AZURE_CLIENT_SECRET"] == "test-secret"

    @patch("ad_provision.config.load_dotenv")
    @patch.dict(
        os.environ,
        {
            "AZURE_CLIENT_ID": "",
            "AZURE_TENANT_ID": "test-tenant-id",
        },
        clear=True,
    )
    def test_missing_client_id(self, mock_load_dotenv, tmp_path):
        """Test ValueError when AZURE_CLIENT_ID is missing."""
        with patch("ad_provision.config.Path.home", return_value=tmp_path):
            with patch("ad_provision.config.Path.exists", return_value=True):
                with pytest.raises(ValueError) as exc_info:
                    load_config()

                assert "AZURE_CLIENT_ID is required" in str(exc_info.value)

    @patch("ad_provision.config.load_dotenv")
    @patch.dict(
        os.environ,
        {
            "AZURE_CLIENT_ID": "test-client-id",
            "AZURE_TENANT_ID": "",
        },
        clear=True,
    )
    def test_missing_tenant_id(self, mock_load_dotenv, tmp_path):
        """Test ValueError when AZURE_TENANT_ID is missing."""
        with patch("ad_provision.config.Path.home", return_value=tmp_path):
            with patch("ad_provision.config.Path.exists", return_value=True):
                with pytest.raises(ValueError) as exc_info:
                    load_config()

                assert "AZURE_TENANT_ID is required" in str(exc_info.value)

    @patch("ad_provision.config.load_dotenv")
    @patch.dict(
        os.environ,
        {
            "AZURE_CLIENT_ID": "test-client-id",
            "AZURE_TENANT_ID": "test-tenant-id",
        },
        clear=True,
    )
    def test_missing_auth_method(self, mock_load_dotenv, tmp_path):
        """Test ValueError when neither certificate nor secret is provided."""
        with patch("ad_provision.config.Path.home", return_value=tmp_path):
            with patch("ad_provision.config.Path.exists", return_value=True):
                with pytest.raises(ValueError) as exc_info:
                    load_config()

                assert (
                    "Either AZURE_CERTIFICATE_PATH or AZURE_CLIENT_SECRET is required"
                    in str(exc_info.value)
                )
