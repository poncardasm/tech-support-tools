"""CSV parsing and reading utilities."""

import csv
from pathlib import Path
from typing import Iterator, Dict


def read_csv(csv_path: str) -> Iterator[Dict[str, str]]:
    """Read CSV file and yield each row as a dictionary.

    Supports both comma and semicolon delimiters.
    Handles missing columns gracefully by returning empty string.

    Args:
        csv_path: Path to the CSV file

    Yields:
        Dictionary representing each row
    """
    path = Path(csv_path)

    with open(path, "r", encoding="utf-8") as f:
        # Try to detect delimiter from first line
        sample = f.read(4096)
        f.seek(0)

        delimiter = ","
        if ";" in sample and "," not in sample:
            delimiter = ";"

        reader = csv.DictReader(f, delimiter=delimiter)

        # Ensure 'email' column exists
        if reader.fieldnames and "email" not in reader.fieldnames:
            # Try case-insensitive match
            email_col = None
            for col in reader.fieldnames:
                if col.lower() == "email":
                    email_col = col
                    break

            if not email_col:
                raise click.ClickException(
                    f"CSV must have an 'email' column. Found: {reader.fieldnames}"
                )

        for row in reader:
            # Normalize email column name
            if "email" not in row:
                for key in list(row.keys()):
                    if key.lower() == "email":
                        row["email"] = row.pop(key)
                        break
            yield row
