"""Runbook indexing and discovery."""

import re
from pathlib import Path
from typing import List, Dict, Optional


def list_runbooks(
    directory: str = "./runbooks", category: Optional[str] = None, recursive: bool = True
) -> List[Dict]:
    """List all runbooks in a directory.

    Args:
        directory: Root directory to search for runbooks.
        category: Optional category (subdirectory) to filter by.
        recursive: Whether to search recursively.

    Returns:
        List of runbook dictionaries with 'name', 'path', 'category' keys.
    """
    search_path = Path(directory).expanduser().resolve()

    if not search_path.exists():
        return []

    if category:
        search_path = search_path / category
        if not search_path.exists():
            return []

    runbooks = []

    if recursive:
        pattern = "**/*.md"
    else:
        pattern = "*.md"

    for path in search_path.glob(pattern):
        # Skip hidden files and common non-runbook patterns
        if path.name.startswith(".") or path.name.startswith("_"):
            continue

        # Skip common non-runbook markdown files
        if path.name.lower() in ("readme.md", "changelog.md", "license.md", "contributing.md"):
            continue

        # Calculate category relative to the root directory
        try:
            rel_path = path.relative_to(Path(directory).expanduser().resolve())
            category_name = str(rel_path.parent) if rel_path.parent.name else "default"
        except ValueError:
            category_name = path.parent.name or "default"

        runbooks.append(
            {
                "name": path.stem,
                "path": str(path),
                "category": category_name,
                "size": path.stat().st_size,
            }
        )

    # Sort by category, then name
    runbooks.sort(key=lambda x: (x["category"], x["name"]))

    return runbooks


def search_runbooks(
    query: str, directory: str = "./runbooks", search_content: bool = True
) -> List[Dict]:
    """Search runbooks by name and optionally content.

    Args:
        query: Search string (case-insensitive).
        directory: Root directory to search.
        search_content: Whether to search within file content.

    Returns:
        List of matching runbook dictionaries.
    """
    query_lower = query.lower()
    results = []
    seen_paths = set()

    # First pass: search by name
    all_runbooks = list_runbooks(directory)

    for rb in all_runbooks:
        if query_lower in rb["name"].lower():
            results.append(rb)
            seen_paths.add(rb["path"])

    # Second pass: search by content (if enabled)
    if search_content:
        for rb in all_runbooks:
            if rb["path"] in seen_paths:
                continue

            try:
                content = Path(rb["path"]).read_text(encoding="utf-8").lower()
                if query_lower in content:
                    results.append(rb)
                    seen_paths.add(rb["path"])
            except (IOError, UnicodeDecodeError):
                continue

    return results


def get_runbook_info(file_path: str) -> Dict:
    """Get detailed information about a specific runbook.

    Args:
        file_path: Path to the runbook file.

    Returns:
        Dictionary with runbook metadata.
    """
    path = Path(file_path)

    if not path.exists():
        return {"error": f"File not found: {file_path}"}

    try:
        content = path.read_text(encoding="utf-8")

        # Extract title
        title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        title = title_match.group(1) if title_match else path.stem

        # Count steps (code blocks)
        step_count = len(re.findall(r"```(?:bash|sh|zsh)", content))

        # Extract description (first paragraph after title)
        description = ""
        if title_match:
            after_title = content[title_match.end() :]
            desc_match = re.search(r"\n\n([^#\n].*?)\n\n", after_title, re.DOTALL)
            if desc_match:
                description = desc_match.group(1).strip()[:200]

        stat = path.stat()

        return {
            "name": path.stem,
            "path": str(path),
            "title": title,
            "description": description,
            "category": path.parent.name or "default",
            "step_count": step_count,
            "size": stat.st_size,
            "modified": stat.st_mtime,
        }

    except Exception as e:
        return {"error": f"Error reading file: {e}"}


def get_categories(directory: str = "./runbooks") -> List[str]:
    """Get a list of all categories (subdirectories with runbooks).

    Args:
        directory: Root directory to search.

    Returns:
        List of category names.
    """
    search_path = Path(directory).expanduser().resolve()

    if not search_path.exists():
        return []

    categories = set()

    for path in search_path.rglob("*.md"):
        if path.name.startswith(".") or path.name.startswith("_"):
            continue
        if path.name.lower() in ("readme.md", "changelog.md", "license.md"):
            continue

        try:
            rel_path = path.relative_to(search_path)
            category = str(rel_path.parent) if rel_path.parent.name else "default"
            categories.add(category)
        except ValueError:
            categories.add(path.parent.name or "default")

    return sorted(categories)
