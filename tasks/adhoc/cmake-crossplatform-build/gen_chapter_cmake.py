#!/usr/bin/env python3
"""Generate ``examples/cmake/chaptNN.cmake`` from the Linux Makefiles' link lines.

For every ``examples/projects/linux/<chapter>/<demo>/Makefile`` this runs ``make -n`` (a dry run), takes the one
``-o <binary>`` compile line, and keeps the demo's own sources (those under ``src/<chapter>/``), dropping the shared
GLTools files that the ``gltools`` library supplies. Demos that need ImGui get the IMGUI keyword; demos that need other libraries (OpenEXR) are listed in a
comment per chapter and left for a later step. Idempotent: rerunning rewrites identical files.

Usage: ``python3 tasks/adhoc/cmake-crossplatform-build/gen_chapter_cmake.py``
"""

from __future__ import annotations

import pathlib
import re
import shlex
import subprocess

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[3]
LINUX: pathlib.Path = REPO / "examples" / "projects" / "linux"
SRC: pathlib.Path = REPO / "examples" / "src"
OUT: pathlib.Path = REPO / "examples" / "cmake"
SHARED_NAMES: frozenset[str] = frozenset({"math3d.cpp", "gltools.cpp", "GLee.c"})


def link_command(makefile_dir: pathlib.Path) -> str | None:
    """The dry-run compile command that produces the demo binary, or None.

    Args:
        makefile_dir: A demo's Linux project directory.

    Returns:
        str | None: the command line containing ``-o``, or None when there is none.
    """
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["make", "-n", "-C", str(makefile_dir)], capture_output=True, text=True, check=False
    )
    lines: list[str] = [line for line in result.stdout.splitlines() if " -o " in line and "-c " not in line.split(" -o ")[0]]
    return lines[0] if lines else None


#: Demos that link X11 libraries the dry-run line does not show; they build only on Linux.
X11_DEMOS: dict[str, str] = {"GLXBasics": "X11 Xi Xmu", "fonts": "X11 Xi Xmu"}


def shared_extras(command: str) -> list[str]:
    """Shared GLTools sources beyond the ``gltools`` library (``TriangleMesh.cpp``, ``VBOMesh.cpp``).

    Args:
        command: The dry-run compile line.

    Returns:
        list[str]: file names under ``src/shared``.
    """
    names: list[str] = re.findall(r"src/shared/([A-Za-z0-9_]+\.(?:cpp|c))\b", command)
    return [n for n in dict.fromkeys(names) if n not in SHARED_NAMES]


def demo_sources(chapter: str, command: str) -> tuple[list[str], bool, list[str]]:
    """Split a link command into the demo's sources, whether it needs ImGui, and any extra libraries.

    Args:
        chapter: The chapter directory name.
        command: The dry-run compile line.

    Returns:
        tuple[list[str], bool, list[str]]: sources relative to ``src/<chapter>/<demo>`` (or the chapter), the ImGui
        flag, and the library names beyond GLUT, GL, GLU and m.
    """
    words: list[str] = shlex.split(command)
    sources: list[str] = []
    imgui: bool = any("imgui" in word for word in words)
    libs: list[str] = [w[2:] for w in words if w.startswith("-l") and w[2:] not in {"glut", "GL", "GLU", "m", "stdc++"}]
    word: str
    for word in words:
        if re.search(r"\.(c|cpp)$", word) and f"src/{chapter}/" in word:
            sources.append(word.split(f"src/{chapter}/", 1)[1])
    return sources, imgui, libs


def main() -> None:
    """Write one cmake file per chapter."""
    OUT.mkdir(exist_ok=True)
    chapter_dir: pathlib.Path
    for chapter_dir in sorted(LINUX.glob("chapt*")):
        chapter: str = chapter_dir.name
        added: list[str] = []
        later: list[str] = []
        demo_dir: pathlib.Path
        for demo_dir in sorted(p for p in chapter_dir.iterdir() if (p / "Makefile").is_file()):
            command: str | None = link_command(demo_dir)
            if command is None:
                later.append(f"{demo_dir.name} (no link command)")
                continue
            sources: list[str]
            imgui: bool
            libs: list[str]
            sources, imgui, libs = demo_sources(chapter, command)
            demo_path: str = sources[0].rsplit("/", 1)[0] if sources and "/" in sources[0] else ""
            if libs or not sources:
                later.append(f"{demo_dir.name} ({' '.join(libs)}{'' if sources else ' no demo sources'})")
                continue
            # The source directory on disk can differ in case from the Makefile directory; use the Makefile's spelling of the sources.
            folder: str = demo_path.split("/")[0] if "/" in sources[0] else ""
            names: list[str] = [s.split("/", 1)[1] if "/" in s else s for s in sources]
            extras: list[str] = shared_extras(command)
            line: str = f"add_demo({chapter} {folder} SOURCES {' '.join(names)}"
            if extras:
                line += f" SHARED {' '.join(extras)}"
            if imgui:
                line += " IMGUI"
            if folder in X11_DEMOS:
                added.append(f"if(UNIX AND NOT APPLE)\n  {line} LIBS {X11_DEMOS[folder]})\nendif()")
            else:
                added.append(line + ")")
        body: list[str] = [f"# Generated by tasks/adhoc/cmake-crossplatform-build/gen_chapter_cmake.py from the Linux Makefiles."]
        if later:
            body.append("# Not added yet: " + "; ".join(later))
        body.extend(added)
        (OUT / f"{chapter}.cmake").write_text("\n".join(body) + "\n")
        print(chapter, len(added), "added,", len(later), "later")


if __name__ == "__main__":
    main()
