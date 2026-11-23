#!/usr/bin/env python3
"""Check that the Visual Studio and Xcode project files reference source files that exist.

For each ``.vcxproj`` (``<ClCompile|ClInclude|None|... Include="...">``) and each ``project.pbxproj``
(``path = ...;``) under ``examples/projects``, resolve every relative path that points into ``examples/src``
and report how many exist, how many do not, and the first missing one. Case-sensitive on purpose: a path that
differs only in case from the file on disk builds on Windows and macOS (case-insensitive by default) and
fails on Linux. Writes ``data/wrapper-check.tsv``.
Usage: ``python3 tasks/adhoc/cmake-crossplatform-build/wrapper_check.py``
"""

from __future__ import annotations

import pathlib
import re

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[3]
PROJECTS: pathlib.Path = REPO / "examples" / "projects"
OUT: pathlib.Path = pathlib.Path(__file__).resolve().parent / "data" / "wrapper-check.tsv"
VCX: re.Pattern[str] = re.compile(r'(?:ClCompile|ClInclude|None|Image|ResourceCompile)\s+Include="([^"]+)"')
PBX: re.Pattern[str] = re.compile(r"path = ([^;]+);")


def exists_exact(path: pathlib.Path) -> bool:
    """Whether ``path`` exists with exactly this capitalization.

    Args:
        path: An absolute, normalized path.

    Returns:
        bool: True when every component matches a directory entry byte for byte.
    """
    current: pathlib.Path = pathlib.Path(path.anchor)
    part: str
    for part in path.parts[1:]:
        if not current.is_dir() or part not in {entry.name for entry in current.iterdir()}:
            return False
        current = current / part
    return True


def check(project_dir: pathlib.Path, references: list[str]) -> tuple[int, int, str]:
    """Count the existing and missing in-tree references.

    Args:
        project_dir: The directory the references are relative to.
        references: Raw path strings from the project file.

    Returns:
        tuple[int, int, str]: (existing, missing, first missing path or "").
    """
    good: int = 0
    bad: int = 0
    first: str = ""
    raw: str
    for raw in references:
        normalized: str = raw.strip().strip('"').replace("\\", "/")
        if "src/" not in normalized and "shared/" not in normalized:
            continue
        resolved: pathlib.Path = pathlib.Path(__import__("os").path.normpath(project_dir / normalized))
        if exists_exact(resolved):
            good += 1
        else:
            bad += 1
            first = first or normalized
    return good, bad, first


def main() -> None:
    """Write the wrapper check table."""
    rows: list[str] = ["platform\tchapter\tdemo\texisting\tmissing\tfirst_missing"]
    project: pathlib.Path
    for project in sorted(PROJECTS.glob("microsoft/chapt*/*/*.vcxproj")):
        good, bad, first = check(project.parent, VCX.findall(project.read_text(errors="replace")))
        rows.append(f"microsoft\t{project.parent.parent.name}\t{project.parent.name}\t{good}\t{bad}\t{first}")
    pbx: pathlib.Path
    for pbx in sorted(PROJECTS.glob("apple/chapt*/*/*.xcodeproj/project.pbxproj")):
        demo_dir: pathlib.Path = pbx.parent.parent
        good, bad, first = check(demo_dir, PBX.findall(pbx.read_text(errors="replace")))
        rows.append(f"apple\t{demo_dir.parent.name}\t{demo_dir.name}\t{good}\t{bad}\t{first}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(rows) + "\n")
    missing: int = sum(1 for row in rows[1:] if int(row.split("\t")[4]) > 0)
    print(f"{len(rows) - 1} project files checked, {missing} reference a missing file")


if __name__ == "__main__":
    main()
