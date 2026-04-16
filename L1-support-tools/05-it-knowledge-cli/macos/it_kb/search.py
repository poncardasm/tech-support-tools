"""Search utilities for IT Knowledge CLI (macOS)."""

import sqlite3
import sqlite_vec
import numpy as np
from typing import Optional

from .config import get_index_path
from .embeddings import get_embedding, bytes_to_vector


def search(query: str, top_n: int = 3) -> list[dict]:
    """Search for articles using vector similarity.

    Args:
        query: Search query
        top_n: Number of results to return

    Returns:
        List of result dictionaries with similarity scores
    """
    conn = sqlite3.connect(get_index_path())

    try:
        # Load sqlite-vec extension
        conn.enable_load_extension(True)
        sqlite_vec.load(conn)
        conn.enable_load_extension(False)

        # Generate query embedding
        query_embedding_bytes = get_embedding(query)
        if query_embedding_bytes is None:
            return []

        query_vector = bytes_to_vector(query_embedding_bytes)
        query_vector_bytes = query_vector.tobytes()

        # Search using sqlite-vec
        cursor = conn.execute(
            """
            SELECT 
                a.id,
                a.title,
                a.category,
                a.content,
                a.last_updated,
                e.distance
            FROM article_embeddings e
            JOIN articles a ON a.id = e.article_id
            WHERE e.embedding MATCH ?
            ORDER BY e.distance
            LIMIT ?
        """,
            (query_vector_bytes, top_n),
        )

        results = []
        for row in cursor.fetchall():
            # sqlite-vec returns distance; convert to similarity
            distance = row[5] if row[5] is not None else 1.0
            similarity = max(0.0, 1.0 - distance)

            results.append(
                {
                    "id": row[0],
                    "title": row[1],
                    "category": row[2],
                    "content": row[3],
                    "last_updated": row[4],
                    "similarity": similarity,
                }
            )

        return results
    finally:
        conn.close()


def get_article(article_id: str) -> Optional[dict]:
    """Get a single article by ID.

    Args:
        article_id: The article ID

    Returns:
        Article dictionary or None
    """
    conn = sqlite3.connect(get_index_path())

    try:
        cursor = conn.execute(
            "SELECT id, title, category, content, last_updated FROM articles WHERE id = ?",
            (article_id,),
        )

        row = cursor.fetchone()
        if row:
            return {
                "id": row[0],
                "title": row[1],
                "category": row[2],
                "content": row[3],
                "last_updated": row[4],
            }
        return None
    finally:
        conn.close()
