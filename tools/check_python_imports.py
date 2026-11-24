"""Import every module of the Python port, with no display and no GL context.

A demo opens its window only under ``if __name__ == "__main__":``, so
importing it proves that its imports resolve (PyOpenGL, glfw, imgui_bundle,
gacalc, ``_common``, ``_geometry``, ``_primitives``) and that nothing runs at
import time.

Usage:
    python3 tools/check_python_imports.py          # every module under python/
    python3 tools/check_python_imports.py chapt01  # paths containing the text
"""

import importlib.util
import pathlib
import sys
import traceback
import types

REPO: pathlib.Path = pathlib.Path(__file__).resolve().parents[1]
PYTHON_DIR: pathlib.Path = REPO / "python"


def import_module_from_path(path: pathlib.Path) -> None:
    """Import one source file under a name unique to its path.

    Args:
        path: The ``.py`` file to import.

    Raises:
        Exception: Whatever the module raises while importing.
    """
    relative: pathlib.Path = path.relative_to(PYTHON_DIR).with_suffix("")
    name: str = "port_" + "_".join(relative.parts)
    spec: importlib.machinery.ModuleSpec | None = (
        importlib.util.spec_from_file_location(name, path)
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {path}")
    module: types.ModuleType = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)


def main() -> int:
    """Import every module and report the failures.

    Returns:
        ``0`` when every module imported, ``1`` otherwise.
    """
    sys.path.insert(0, str(PYTHON_DIR))
    pattern: str = sys.argv[1] if len(sys.argv) > 1 else ""
    paths: list[pathlib.Path] = sorted(
        path
        for path in PYTHON_DIR.glob("**/*.py")
        if pattern in path.as_posix()
    )
    failures: list[pathlib.Path] = []
    for path in paths:
        try:
            import_module_from_path(path)
        except Exception:
            failures.append(path)
            print(f"FAIL {path.relative_to(REPO)}")
            traceback.print_exc(limit=3)
    print(f"{len(paths) - len(failures)} of {len(paths)} modules imported")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
