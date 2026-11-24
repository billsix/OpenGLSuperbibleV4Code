"""Repoint the imported Python port at this repository's assets and vendored math.

One-shot codemod for ``tasks/python-port-into-master.md``. It rewrites every demo under
``python/chaptNN/`` so that

* asset reads go through ``ASSET_DIR`` (``_common.asset_dir(PWD)``, the demo's directory
  under ``examples/src/``) instead of ``PWD`` (the demo's own directory), and
* ``from modelviewprojection.mathutils import ...`` becomes ``from _geometry import ...``
  (``python/_geometry.py`` is the vendored copy of the two functions the demos use).

``chapt15/shaders`` is skipped: its two ``.vs``/``.fs`` files exist only beside the Python
demo, because the C++ original embeds the GLSL in ``shaders.cpp``.

Idempotent: a second run changes nothing. Paths are relative to the repository root.

Usage:
    python3 tasks/adhoc/python-port-into-master/repoint_port.py
"""

import pathlib
import re

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[3]
PYTHON_DIR: pathlib.Path = REPO / "python"
SKIPPED_ASSET_DEMOS: frozenset[str] = frozenset({"chapt15/shaders/shaders.py"})

# Lines that define PWD or use it to find the port root; every other PWD use is an asset read.
PWD_DEFINITION: re.Pattern[str] = re.compile(r"^\s*_?PWD(: str)? = os\.path\.dirname\(os\.path\.abspath\(__file__\)\)\s*$")
PWD_SYS_PATH: re.Pattern[str] = re.compile(r"^\s*sys\.path(\.insert\(0, .*PWD.*\)| = \[p for p in sys\.path if p != _PWD\])\s*$")
COMMON_IMPORT: re.Pattern[str] = re.compile(r"^import _common  # noqa: E402\s*$")
MATHUTILS_IMPORT: re.Pattern[str] = re.compile(
    r"^from modelviewprojection\.mathutils import (\((?P<multi>[^)]*)\)|(?P<single>[^\n(]+))\n", re.MULTILINE
)
ASSET_DIR_LINE: str = "ASSET_DIR: str = _common.asset_dir(PWD)"


def repoint(relative: str, source: str) -> str:
    """Return ``source`` with asset reads and the mathutils import repointed.

    Args:
        relative: The demo's path under ``python/``, with forward slashes.
        source: The demo's current text.

    Returns:
        The rewritten text (equal to ``source`` when nothing applies).
    """
    names: list[str] = []
    match: re.Match[str] | None = MATHUTILS_IMPORT.search(source)
    if match is not None:
        raw: str = match.group("multi") if match.group("multi") is not None else match.group("single")
        names = sorted(n.strip() for n in raw.replace("\n", " ").split(",") if n.strip())
        source = source[: match.start()] + source[match.end() :]
    lines: list[str] = source.split("\n")
    uses_assets: bool = False
    if relative not in SKIPPED_ASSET_DEMOS:
        for index, line in enumerate(lines):
            if "PWD" not in line or line == ASSET_DIR_LINE:
                continue
            if PWD_DEFINITION.match(line) or PWD_SYS_PATH.match(line):
                continue
            if line.lstrip().startswith(("#", '"', "'")) or re.search(r"\bPWD\b", line) is None:
                continue
            uses_assets = True
            lines[index] = re.sub(r"\bPWD\b", "ASSET_DIR", line)
    out: list[str] = []
    for index, line in enumerate(lines):
        out.append(line)
        if COMMON_IMPORT.match(line):
            if names:
                out.append(f"from _geometry import {', '.join(names)}  # noqa: E402")
            if (uses_assets or ASSET_DIR_LINE in lines) and ASSET_DIR_LINE not in lines[index + 1 :]:
                out.append(ASSET_DIR_LINE)
    return "\n".join(out)


def main() -> None:
    """Rewrite every demo under ``python/chaptNN/`` and report how many changed."""
    changed: list[str] = []
    for path in sorted(PYTHON_DIR.glob("chapt*/**/*.py")):
        relative: str = path.relative_to(PYTHON_DIR).as_posix()
        before: str = path.read_text()
        after: str = repoint(relative, before)
        if after != before:
            path.write_text(after)
            changed.append(relative)
    print(f"changed {len(changed)} files")


if __name__ == "__main__":
    main()
