#!/usr/bin/env python3
"""Join the audit's data tables into the Markdown per-demo table of ``tasks/reference/source-audit.md``.

Reads ``data/demos.tsv``, ``data/linux-build.tsv`` and ``data/linux-run.tsv`` and prints a Markdown table, one
row per demo, to stdout. Usage: ``python3 tasks/adhoc/cmake-crossplatform-build/make_demo_table.py``
"""

from __future__ import annotations

import csv
import pathlib

DATA: pathlib.Path = pathlib.Path(__file__).resolve().parent / "data"


def read(name: str) -> list[dict[str, str]]:
    """Rows of a tab-separated data file.

    Args:
        name: File name under ``data/``.

    Returns:
        list[dict[str, str]]: one dict per row.
    """
    with (DATA / name).open() as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def main() -> None:
    """Print the table."""
    build: dict[tuple[str, str], dict[str, str]] = {
        (row["chapter"], row["demo"].lower()): row for row in read("linux-build.tsv")
    }
    run: dict[tuple[str, str], dict[str, str]] = {
        (row["chapter"], row["demo"].lower()): row for row in read("linux-run.tsv")
    }
    print("| chapter / demo | lines | GLUT calls | shared | Makefile | Xcode | VS | Linux build | Linux run (5 s, Xvfb) |")
    print("|---|---:|---:|---|:-:|:-:|:-:|---|---|")
    row: dict[str, str]
    for row in read("demos.tsv"):
        key: tuple[str, str] = (row["chapter"], row["demo"].lower())
        built: dict[str, str] | None = build.get(key)
        ran: dict[str, str] | None = run.get(key)
        build_cell: str = "-" if built is None else ("ok" if built["status"] == "ok" else "FAIL")
        run_cell: str = "-"
        if ran is not None:
            run_cell = ran["result"] if ran["result"] != "alive" else f"alive, {ran['colours']} colours"
        shared: str = row["shared"].replace("gltools", "gt").replace("math3d", "m3d")
        imgui: str = " +ImGui" if row["imgui"] == "y" else ""
        print(
            f"| {row['chapter']}/{row['demo']}{imgui} | {row['lines']} | {row['glut_calls']} | {shared} "
            f"| {row['makefile']} | {row['xcode']} | {row['vcxproj']} | {build_cell} | {run_cell} |"
        )


if __name__ == "__main__":
    main()
