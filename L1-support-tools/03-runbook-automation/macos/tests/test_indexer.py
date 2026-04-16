"""Tests for the runbook indexer module."""

import pytest
from pathlib import Path

from runbook.indexer import list_runbooks, search_runbooks, get_runbook_info, get_categories


class TestListRunbooks:
    """Test the list_runbooks function."""

    def test_list_empty_directory(self, tmp_path):
        result = list_runbooks(str(tmp_path))
        assert result == []

    def test_list_single_runbook(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        result = list_runbooks(str(tmp_path))
        assert len(result) == 1
        assert result[0]["name"] == "test"

    def test_list_with_category(self, tmp_path):
        category_dir = tmp_path / "networking"
        category_dir.mkdir()
        runbook = category_dir / "test.md"
        runbook.write_text("# Test")

        result = list_runbooks(str(tmp_path))
        assert len(result) == 1
        assert "networking" in result[0]["category"]

    def test_filter_by_category(self, tmp_path):
        # Create runbooks in different categories
        (tmp_path / "auth").mkdir()
        (tmp_path / "net").mkdir()

        (tmp_path / "auth" / "reset.md").write_text("# Reset")
        (tmp_path / "net" / "vpn.md").write_text("# VPN")
        (tmp_path / "general.md").write_text("# General")

        # Filter to only auth category
        result = list_runbooks(str(tmp_path), category="auth")
        assert len(result) == 1
        assert result[0]["name"] == "reset"

    def test_skip_readme(self, tmp_path):
        readme = tmp_path / "README.md"
        readme.write_text("# README")

        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        result = list_runbooks(str(tmp_path))
        assert len(result) == 1
        assert result[0]["name"] == "test"

    def test_skip_hidden_files(self, tmp_path):
        hidden = tmp_path / ".hidden.md"
        hidden.write_text("# Hidden")

        visible = tmp_path / "visible.md"
        visible.write_text("# Visible")

        result = list_runbooks(str(tmp_path))
        assert len(result) == 1
        assert result[0]["name"] == "visible"


class TestSearchRunbooks:
    """Test the search_runbooks function."""

    def test_search_by_name(self, tmp_path):
        (tmp_path / "vpn-setup.md").write_text("# VPN Setup")
        (tmp_path / "auth-reset.md").write_text("# Auth Reset")

        result = search_runbooks("vpn", str(tmp_path))
        assert len(result) == 1
        assert result[0]["name"] == "vpn-setup"

    def test_search_by_content(self, tmp_path):
        (tmp_path / "runbook1.md").write_text("# Runbook\n\nConfigure DNS settings")
        (tmp_path / "runbook2.md").write_text("# Runbook\n\nSomething else")

        result = search_runbooks("DNS", str(tmp_path))
        assert len(result) == 1
        assert result[0]["name"] == "runbook1"

    def test_search_no_results(self, tmp_path):
        (tmp_path / "test.md").write_text("# Test")

        result = search_runbooks("nonexistent", str(tmp_path))
        assert result == []

    def test_search_case_insensitive(self, tmp_path):
        (tmp_path / "UPPER.md").write_text("# Test")

        result = search_runbooks("upper", str(tmp_path))
        assert len(result) == 1

        result = search_runbooks("UPPER", str(tmp_path))
        assert len(result) == 1


class TestGetRunbookInfo:
    """Test the get_runbook_info function."""

    def test_get_info(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("""# My Test Runbook

This is a description.

```bash
echo hello
```

```bash
sleep 1
```
""")

        info = get_runbook_info(str(runbook))

        assert info["name"] == "test"
        assert info["title"] == "My Test Runbook"
        assert info["step_count"] == 2
        assert "description" in info

    def test_get_info_no_title(self, tmp_path):
        runbook = tmp_path / "my-runbook.md"
        runbook.write_text("```bash\necho hello\n```")

        info = get_runbook_info(str(runbook))
        assert info["title"] == "my-runbook"

    def test_get_info_nonexistent(self, tmp_path):
        info = get_runbook_info(str(tmp_path / "nonexistent.md"))
        assert "error" in info


class TestGetCategories:
    """Test the get_categories function."""

    def test_get_categories(self, tmp_path):
        (tmp_path / "cat1").mkdir()
        (tmp_path / "cat2").mkdir()

        (tmp_path / "cat1" / "rb1.md").write_text("# Test")
        (tmp_path / "cat2" / "rb2.md").write_text("# Test")
        (tmp_path / "rb3.md").write_text("# Test")

        cats = get_categories(str(tmp_path))

        assert "cat1" in cats
        assert "cat2" in cats
        # The root-level runbook should have 'default' category
        assert "default" in cats or "" in cats

    def test_get_categories_empty(self, tmp_path):
        cats = get_categories(str(tmp_path))
        assert cats == []
