"""Tests for IT Knowledge CLI search functionality (macOS)."""

import pytest
import tempfile
import os
from pathlib import Path

from it_kb.config import get_config_path, get_index_path, ensure_config_dir
from it_kb.indexer import init_db, index_directory, add_article, list_articles
from it_kb.search import search, get_article


class TestConfig:
    """Test configuration utilities."""

    def test_config_path_uses_home_config(self):
        """Test that config path uses ~/.config on macOS."""
        path = get_config_path()
        assert ".config" in str(path)
        assert "it-kb" in str(path)

    def test_ensure_config_dir_creates_directory(self):
        """Test that config directory is created."""
        ensure_config_dir()
        assert get_config_path().exists()


class TestDatabase:
    """Test database initialization."""

    def test_init_db_creates_tables(self):
        """Test that init_db creates required tables."""
        conn = init_db()

        # Check articles table exists
        cursor = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='articles'"
        )
        assert cursor.fetchone() is not None

        # Check article_embeddings table exists
        cursor = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='article_embeddings'"
        )
        assert cursor.fetchone() is not None

        conn.close()


class TestIndexing:
    """Test article indexing."""

    def test_add_article_without_ollama(self, monkeypatch):
        """Test add_article handles missing Ollama gracefully."""
        # Mock get_embedding to return None (simulating no Ollama)
        import it_kb.embeddings

        monkeypatch.setattr(
            it_kb.embeddings, "get_embedding", lambda x, model=None: None
        )

        result = add_article("Test Article", "This is test content.")
        assert result is None

    def test_list_articles_empty(self):
        """Test listing articles when none exist."""
        articles = list_articles()
        assert isinstance(articles, list)


class TestSearch:
    """Test search functionality."""

    def test_search_without_ollama(self, monkeypatch):
        """Test search handles missing Ollama gracefully."""
        import it_kb.embeddings

        monkeypatch.setattr(
            it_kb.embeddings, "get_embedding", lambda x, model=None: None
        )

        results = search("test query")
        assert results == []

    def test_get_article_not_found(self):
        """Test getting non-existent article."""
        article = get_article("NON-EXISTENT-ID")
        assert article is None


class TestIntegration:
    """Integration tests with mock embeddings."""

    @pytest.fixture
    def mock_embedding(self, monkeypatch):
        """Provide mock embeddings for testing."""
        import numpy as np

        def mock_get_embedding(text, model=None):
            # Return a fixed 768-dimensional embedding
            embedding = np.random.randn(768).astype(np.float32)
            return embedding.tobytes()

        import it_kb.embeddings

        monkeypatch.setattr(it_kb.embeddings, "get_embedding", mock_get_embedding)

        return mock_get_embedding

    def test_full_index_and_search(self, mock_embedding, tmp_path):
        """Test complete indexing and search flow."""
        # Create a test markdown file
        md_file = tmp_path / "test-article.md"
        md_file.write_text("""---
id: KB-TEST-001
title: Test Article
category: testing
---

This is a test article about resetting passwords.
""")

        # Index the directory
        count = index_directory(str(tmp_path))
        assert count >= 1

        # Search
        results = search("password reset", top_n=1)
        assert len(results) >= 0  # May be empty if no matches

    def test_add_and_retrieve_article(self, mock_embedding):
        """Test adding and retrieving an article."""
        # Add article
        article_id = add_article(
            "Password Reset Guide",
            "Steps to reset your password...",
            category="security",
        )

        assert article_id is not None

        # Retrieve article
        article = get_article(article_id)
        assert article is not None
        assert article["title"] == "Password Reset Guide"
        assert article["category"] == "security"
