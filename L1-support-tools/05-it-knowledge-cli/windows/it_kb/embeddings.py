"""Embedding utilities for IT Knowledge CLI."""

import requests
import numpy as np
from typing import Optional


# Global cache for embeddings to avoid regenerating
_embedding_cache = {}


def get_embedding(text: str, model: str = "nomic-embed-text") -> Optional[bytes]:
    """Generate embedding vector using Ollama.

    Args:
        text: The text to embed
        model: The Ollama model to use (default: nomic-embed-text)

    Returns:
        Embedding as bytes, or None if Ollama is unavailable
    """
    # Check cache first
    cache_key = f"{model}:{text[:100]}"
    if cache_key in _embedding_cache:
        return _embedding_cache[cache_key]

    try:
        resp = requests.post(
            "http://localhost:11434/api/embeddings",
            json={"model": model, "prompt": text},
            timeout=30,
        )
        resp.raise_for_status()
        embedding_data = resp.json().get("embedding")

        if embedding_data:
            # Convert to numpy array then to bytes for storage
            embedding_array = np.array(embedding_data, dtype=np.float32)
            embedding_bytes = embedding_array.tobytes()
            _embedding_cache[cache_key] = embedding_bytes
            return embedding_bytes

        return None
    except requests.exceptions.ConnectionError:
        return None
    except requests.exceptions.Timeout:
        return None
    except Exception:
        return None


def get_embedding_dim(model: str = "nomic-embed-text") -> int:
    """Get the dimension of embeddings for a model.

    nomic-embed-text produces 768-dimensional embeddings.
    """
    return 768


def bytes_to_vector(embedding_bytes: bytes) -> np.ndarray:
    """Convert bytes back to numpy vector."""
    return np.frombuffer(embedding_bytes, dtype=np.float32)
