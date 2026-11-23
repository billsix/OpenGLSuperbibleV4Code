#!/usr/bin/env python3
"""Tabulate the git history of the SuperBible 4 fork by area.

Writes ``data/history.tsv``: one row per commit, oldest first: short SHA, date, subject, and the number of
files touched in each area (sources under ``examples/src``, the three platform wrapper trees, ``contrib``,
``tasks`` and everything else) plus lines added and deleted in the sources. Run from anywhere.
Usage: ``python3 tasks/adhoc/cmake-crossplatform-build/history_table.py``
"""

from __future__ import annotations

import pathlib
import subprocess

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[3]
OUT: pathlib.Path = pathlib.Path(__file__).resolve().parent / "data" / "history.tsv"
AREAS: tuple[tuple[str, str], ...] = (
    ("src", "examples/src/"),
    ("linux", "examples/projects/linux/"),
    ("apple", "examples/projects/apple/"),
    ("microsoft", "examples/projects/microsoft/"),
    ("contrib", "contrib/"),
    ("tasks", "tasks/"),
)


def area_of(path: str) -> str:
    """The area a path belongs to.

    Args:
        path: A repository-relative path.

    Returns:
        str: ``src``, ``linux``, ``apple``, ``microsoft``, ``contrib``, ``tasks`` or ``other``.
    """
    name: str
    prefix: str
    for name, prefix in AREAS:
        if path.startswith(prefix):
            return name
    return "other"


def main() -> None:
    """Write the history table."""
    raw: str = subprocess.run(
        ["git", "log", "--reverse", "--numstat", "--format=@@%h\t%ad\t%s", "--date=short"],
        cwd=REPO, capture_output=True, text=True, check=True,
    ).stdout
    rows: list[list[str]] = []
    current: list[str] = []
    counts: dict[str, int] = {}
    added: int = 0
    deleted: int = 0

    def flush() -> None:
        if current:
            rows.append([*current, *(str(counts.get(name, 0)) for name in
                                     ("src", "linux", "apple", "microsoft", "contrib", "tasks", "other")),
                         str(added), str(deleted)])

    line: str
    for line in raw.splitlines():
        if line.startswith("@@"):
            flush()
            current = line[2:].split("\t", 2)
            counts = {}
            added = deleted = 0
        elif line.strip():
            parts: list[str] = line.split("\t", 2)
            if len(parts) == 3:
                area: str = area_of(parts[2])
                counts[area] = counts.get(area, 0) + 1
                if area == "src" and parts[0].isdigit() and parts[1].isdigit():
                    added += int(parts[0])
                    deleted += int(parts[1])
    flush()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    header: str = "sha\tdate\tsubject\tsrc\tlinux\tapple\tmicrosoft\tcontrib\ttasks\tother\tsrc_added\tsrc_deleted"
    OUT.write_text("\n".join([header] + ["\t".join(row) for row in rows]) + "\n")
    print(f"{len(rows)} commits written to {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
