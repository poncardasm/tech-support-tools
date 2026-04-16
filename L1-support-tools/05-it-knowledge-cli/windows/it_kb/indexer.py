"""Database and indexing utilities for IT Knowledge CLI."""

import sqlite3
import sqlite_vec
import frontmatter
from pathlib import Path
from datetime import datetime
from typing import Optional

from .config import get_index_path, ensure_config_dir
from .embeddings import get_embedding, get_embedding_dim


def init_db() -> sqlite3.Connection:
    """Initialize the SQLite database with vector search extension."""
    ensure_config_dir()
    conn = sqlite3.connect(get_index_path())

    # Load sqlite-vec extension
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)

    # Create articles table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS articles (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT,
            content TEXT NOT NULL,
            last_updated TEXT
        )
    """)

    # Create virtual table for vector search
    embedding_dim = get_embedding_dim()
    conn.execute(f"""
        CREATE VIRTUAL TABLE IF NOT EXISTS article_embeddings USING vec0(
            article_id TEXT PRIMARY KEY,
            embedding FLOAT[{embedding_dim}] NOT NULL
        )
    """)

    conn.commit()
    return conn


def index_directory(directory: str, category: Optional[str] = None) -> int:
    """Index all markdown files from a directory.

    Args:
        directory: Path to directory containing markdown files
        category: Optional category to assign to all articles

    Returns:
        Number of articles indexed
    """
    conn = init_db()
    count = 0

    for path in Path(directory).rglob("*.md"):
        try:
            with open(path, "r", encoding="utf-8") as f:
                article = frontmatter.load(f)

            content = article.content
            metadata = dict(article)

            if category:
                metadata["category"] = category

            # Skip if no content
            if not content.strip():
                continue

            # Generate embedding
            embedding_bytes = get_embedding(content)
            if embedding_bytes is None:
                print(f"Warning: Could not generate embedding for {path}")
                continue

            article_id = metadata.get("id", path.stem)
            title = metadata.get("title", path.stem)
            article_category = metadata.get("category", "")
            last_updated = metadata.get("last_updated", datetime.now().isoformat()[:10])

            # Insert article
            conn.execute(
                """
                INSERT OR REPLACE INTO articles 
                (id, title, category, content, last_updated)
                VALUES (?, ?, ?, ?, ?)
            """,
                (article_id, title, article_category, content, last_updated),
            )

            # Insert embedding
            conn.execute(
                """
                INSERT OR REPLACE INTO article_embeddings 
                (article_id, embedding)
                VALUES (?, ?)
            """,
                (article_id, embedding_bytes),
            )

            count += 1
            print(f"Indexed: {article_id} — {title}")

        except Exception as e:
            print(f"Error indexing {path}: {e}")

    conn.commit()
    conn.close()
    return count


def add_article(
    title: str, content: str, category: str = "", article_id: Optional[str] = None
) -> Optional[str]:
    """Add a new KB article.

    Args:
        title: Article title
        content: Article content
        category: Article category
        article_id: Optional article ID (generated from title if not provided)

    Returns:
        Article ID if successful, None otherwise
    """
    if article_id is None:
        # Generate ID from title
        article_id = f"KB-{title.lower().replace(' ', '-')[:30]}"

    conn = init_db()

    try:
        embedding_bytes = get_embedding(content)
        if embedding_bytes is None:
            return None

        last_updated = datetime.now().isoformat()[:10]

        conn.execute(
            """
            INSERT OR REPLACE INTO articles 
            (id, title, category, content, last_updated)
            VALUES (?, ?, ?, ?, ?)
        """,
            (article_id, title, category, content, last_updated),
        )

        conn.execute(
            """
            INSERT OR REPLACE INTO article_embeddings 
            (article_id, embedding)
            VALUES (?, ?)
        """,
            (article_id, embedding_bytes),
        )

        conn.commit()
        return article_id
    except Exception as e:
        print(f"Error adding article: {e}")
        return None
    finally:
        conn.close()


def list_articles(category: Optional[str] = None) -> list[dict]:
    """List all indexed articles.

    Args:
        category: Optional filter by category

    Returns:
        List of article dictionaries
    """
    conn = init_db()

    try:
        if category:
            cursor = conn.execute(
                "SELECT id, title, category, last_updated FROM articles WHERE category = ? ORDER BY title",
                (category,),
            )
        else:
            cursor = conn.execute(
                "SELECT id, title, category, last_updated FROM articles ORDER BY title"
            )

        results = []
        for row in cursor.fetchall():
            results.append(
                {
                    "id": row[0],
                    "title": row[1],
                    "category": row[2],
                    "last_updated": row[3],
                }
            )
        return results
    finally:
        conn.close()
