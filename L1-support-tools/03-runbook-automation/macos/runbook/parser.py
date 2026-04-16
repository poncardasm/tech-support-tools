"""Markdown runbook parser."""

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, List


@dataclass
class Step:
    """Represents a single executable step in a runbook."""

    number: int
    code: str
    language: str
    title: str = ""

    def __repr__(self) -> str:
        return f"Step({self.number}, {self.language}, {self.code[:30]}...)"


def parse_runbook(file_path: str) -> List[Step]:
    """Parse a markdown runbook and extract executable shell steps.

    Args:
        file_path: Path to the markdown runbook file.

    Returns:
        List of Step objects representing executable code blocks.

    Raises:
        FileNotFoundError: If the runbook file doesn't exist.
        ValueError: If the file is not a valid markdown file.
    """
    path = Path(file_path)

    if not path.exists():
        raise FileNotFoundError(f"Runbook not found: {file_path}")

    if not path.suffix == ".md":
        raise ValueError(f"Runbook must be a .md file: {file_path}")

    content = path.read_text(encoding="utf-8")
    return extract_steps(content)


def extract_steps(content: str) -> List[Step]:
    """Extract shell code blocks from markdown content.

    Looks for fenced code blocks with bash, sh, or zsh language tags.

    Args:
        content: Markdown content to parse.

    Returns:
        List of Step objects, numbered sequentially.
    """
    steps = []

    # Pattern to match fenced code blocks with bash/sh/zsh
    # Matches ```bash, ```sh, ```zsh (with optional info string)
    pattern = r"```(?:bash|sh|zsh)\s*\n(.*?)```"

    matches = re.findall(pattern, content, re.DOTALL)

    for i, code in enumerate(matches, 1):
        # Clean up the code - strip whitespace but preserve structure
        cleaned_code = code.strip()

        # Determine language (default to bash if unclear)
        lang = "bash"
        if code.strip().startswith("#!/bin/zsh") or code.strip().startswith("#!/usr/bin/env zsh"):
            lang = "zsh"
        elif code.strip().startswith("#!/bin/sh") or code.strip().startswith("#!/usr/bin/env sh"):
            lang = "sh"

        steps.append(Step(number=i, code=cleaned_code, language=lang, title=""))

    return steps


def parse_runbook_with_metadata(file_path: str) -> dict:
    """Parse a runbook and return both steps and metadata.

    Args:
        file_path: Path to the markdown runbook file.

    Returns:
        Dictionary with 'steps', 'title', and 'description' keys.
    """
    path = Path(file_path)
    content = path.read_text(encoding="utf-8")

    # Extract title (first # heading)
    title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    title = title_match.group(1) if title_match else path.stem

    # Extract description (first paragraph after title)
    description = ""
    if title_match:
        after_title = content[title_match.end() :]
        desc_match = re.search(r"\n\n([^#\n].*?)\n\n", after_title, re.DOTALL)
        if desc_match:
            description = desc_match.group(1).strip()

    steps = extract_steps(content)

    return {
        "title": title,
        "description": description,
        "steps": steps,
        "path": str(path),
        "step_count": len(steps),
    }


def validate_runbook(file_path: str) -> tuple[bool, List[str]]:
    """Validate a runbook file for correctness.

    Args:
        file_path: Path to the markdown runbook file.

    Returns:
        Tuple of (is_valid, list of error messages).
    """
    errors = []

    try:
        path = Path(file_path)
        if not path.exists():
            return False, [f"File not found: {file_path}"]

        if not path.suffix == ".md":
            errors.append("File must have .md extension")

        content = path.read_text(encoding="utf-8")

        # Check for at least one shell code block
        shell_pattern = r"```(?:bash|sh|zsh)"
        if not re.search(shell_pattern, content, re.IGNORECASE):
            errors.append("No shell code blocks (bash/sh/zsh) found")

        # Check for unclosed code blocks
        open_blocks = content.count("```")
        if open_blocks % 2 != 0:
            errors.append("Unclosed code block detected")

        return len(errors) == 0, errors

    except Exception as e:
        return False, [f"Validation error: {str(e)}"]
