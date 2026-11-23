#!/usr/bin/env python3
"""Tabulate every demo of the SuperBible 4 tree: sources, project wrappers, GLUT use, shared files.

Writes ``data/demos.tsv`` beside this script (a snapshot worklog for the audit documents). One row per
directory ``examples/src/chaptNN/<demo>``. Columns: chapter, demo, source file count, lines of C/C++, which
of the three platform wrappers exist (Makefile / Xcode project / Visual Studio project), the GLUT calls the
sources make (count), whether ImGui is used, which shared GLTools files the sources include, the libraries
the Linux Makefile links, and the platform ``#ifdef`` tokens in the sources.

Run from anywhere: paths are derived from the script location.
Usage: ``python3 tasks/adhoc/cmake-crossplatform-build/inventory.py``
"""

from __future__ import annotations

import pathlib
import re

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[3]
SRC: pathlib.Path = REPO / "examples" / "src"
PROJECTS: pathlib.Path = REPO / "examples" / "projects"
OUT: pathlib.Path = pathlib.Path(__file__).resolve().parent / "data" / "demos.tsv"

SOURCE_SUFFIXES: frozenset[str] = frozenset({".c", ".cpp", ".h", ".hpp", ".cc", ".cxx", ".m", ".mm"})
GLUT_CALL: re.Pattern[str] = re.compile(r"\bglut[A-Z][A-Za-z0-9]*")
SHARED: tuple[str, ...] = ("GLee", "gltools", "math3d", "VBOMesh", "TriangleMesh", "stopwatch", "glframe", "openexr")
PLATFORM_TOKEN: re.Pattern[str] = re.compile(
    r"#\s*(?:if|ifdef|ifndef|elif)\b[^\n]*?\b(__APPLE__|WIN32|_WIN32|__linux__|__unix__|GLX|__GNUC__|_MSC_VER)\b"
)
LIBS_LINE: re.Pattern[str] = re.compile(r"^\s*LIBS\s*[:+]?=\s*(.*)$", re.MULTILINE)


def sources_of(directory: pathlib.Path) -> list[pathlib.Path]:
    """All C/C++/Objective-C sources and headers under ``directory``.

    Args:
        directory: A demo directory under ``examples/src``.

    Returns:
        list[pathlib.Path]: the files, sorted.
    """
    return sorted(
        path for path in directory.rglob("*") if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES
    )


def wrapper_exists(platform: str, chapter: str, demo: str, pattern: str) -> bool:
    """Whether a platform wrapper directory for the demo contains a file matching ``pattern``.

    Args:
        platform: ``linux``, ``apple`` or ``microsoft``.
        chapter: The chapter directory name, such as ``chapt01``.
        demo: The demo name (matched case-insensitively against the wrapper directory names).
        pattern: A glob, such as ``Makefile`` or ``*.vcxproj``.

    Returns:
        bool: True when a wrapper with that file exists.
    """
    base: pathlib.Path = PROJECTS / platform / chapter
    if not base.is_dir():
        return False
    directory: pathlib.Path
    for directory in base.iterdir():
        if directory.is_dir() and directory.name.lower() == demo.lower():
            return any(directory.rglob(pattern))
    return False


def linux_libs(chapter: str, demo: str) -> str:
    """The ``LIBS`` value of the demo's Linux Makefile, or an empty string.

    Args:
        chapter: The chapter directory name.
        demo: The demo name.

    Returns:
        str: the libraries, space separated.
    """
    base: pathlib.Path = PROJECTS / "linux" / chapter
    if not base.is_dir():
        return ""
    directory: pathlib.Path
    for directory in base.iterdir():
        if directory.is_dir() and directory.name.lower() == demo.lower():
            makefile: pathlib.Path = directory / "Makefile"
            if makefile.is_file():
                found: re.Match[str] | None = LIBS_LINE.search(makefile.read_text(errors="replace"))
                return found.group(1).strip() if found else ""
    return ""


def main() -> None:
    """Write the demo table."""
    OUT.parent.mkdir(parents=True, exist_ok=True)
    rows: list[list[str]] = []
    header: list[str] = [
        "chapter", "demo", "files", "lines", "makefile", "xcode", "vcxproj",
        "glut_calls", "glut_distinct", "imgui", "shared", "linux_libs", "platform_tokens",
    ]
    chapter_dir: pathlib.Path
    for chapter_dir in sorted(SRC.glob("chapt*")):
        demo_dir: pathlib.Path
        for demo_dir in sorted(path for path in chapter_dir.iterdir() if path.is_dir()):
            files: list[pathlib.Path] = sources_of(demo_dir)
            text: str = "\n".join(path.read_text(errors="replace") for path in files)
            glut: list[str] = GLUT_CALL.findall(text)
            shared: list[str] = [name for name in SHARED if re.search(rf"\b{name}", text)]
            tokens: set[str] = set(PLATFORM_TOKEN.findall(text))
            rows.append([
                chapter_dir.name,
                demo_dir.name,
                str(len(files)),
                str(text.count("\n")),
                "y" if wrapper_exists("linux", chapter_dir.name, demo_dir.name, "Makefile") else "-",
                "y" if wrapper_exists("apple", chapter_dir.name, demo_dir.name, "*.xcodeproj") else "-",
                "y" if wrapper_exists("microsoft", chapter_dir.name, demo_dir.name, "*.vcxproj") else "-",
                str(len(glut)),
                str(len(set(glut))),
                "y" if re.search(r"imgui", text, re.IGNORECASE) else "-",
                ",".join(shared),
                linux_libs(chapter_dir.name, demo_dir.name),
                ",".join(sorted(tokens)),
            ])
    lines: list[str] = ["\t".join(header)] + ["\t".join(row) for row in rows]
    OUT.write_text("\n".join(lines) + "\n")
    print(f"{len(rows)} demos written to {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
