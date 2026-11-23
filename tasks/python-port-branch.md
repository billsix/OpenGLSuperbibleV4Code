# A `python` branch with the Python port of every demo (moved here from modelviewprojection)

**Status:** proposed — needs go-ahead and the answers below (filed 2026-11-23)
**Priority:** 6
**Difficulty:** 5
**Created:** 2026-11-23
**Part of:** a three-task split, the maintainer's plan (William Emerison Six <billsix@gmail.com>, 2026-11-23):
(1) this task, (2) `tasks/extract-code-the-classics-to-own-repo.md` in `github.com/billsix/modelviewprojection`,
(3) `tasks/rewrite-history-without-ports.md` in the same repository. Task 3 must not start until this one and task 2 are
done, because it deletes the port from that repository's history.

## BLUF

The Python translation of these demos lives in `github.com/billsix/modelviewprojection` at `ports/openglsuperbiblev4/`
(104 `.py` files, 22 chapters). Move it into this repository on a branch named `python`, cut from `master`, so `master`
keeps the original C and C++ untouched and the branch carries the port, a container that builds and runs both halves, and
the port's cold-start docs. This is the fourth repeat of a pattern the maintainer already used three times (see
Context). Done means: `git switch python` gives a repository where `make shell` can run any C++ demo (freeglut, X11) and
the Python port of it (GLFW, Wayland), `make check` imports every port with no display, the port's reference docs and
open tasks have moved here, and `master` has not changed.

## Context (read first)

- **The pattern, three finished examples.** Each is an upstream's example code with a `python` branch added by the
  maintainer; `master` stays the original. Read their `python`-branch `README.md`, `AGENTS.md` and
  `tasks/archive/2026/10/19/*` before planning anything:
  - `github.com/billsix/sb7code` (SuperBible 7th ed.), branch `python`. The closest model: its archived task
    `tasks/archive/2026/10/19/pythonize-and-containerize-port.md` is this task's template (phases, decisions, the media
    departure). Layout: `python/` (flat scripts plus a `python/sb7/` shared package installed with `pip install -e python/`),
    top-level `Dockerfile`, `Makefile` (`make image|shell|run|run-c|check|type-check|format|list`), `entrypoint/`,
    `tasks/reference/python-port/` (six reference docs: README map, `c-to-python-rules.md`, `fidelity-audit.md`,
    `frameworks.md`, `headless-verification.md`, `mesa-and-pyopengl-traps.md`), `tasks/verify-port-visually.md` (blocked on
    the maintainer's display), `tools/check_local_annotations.py`. The branch is 4 commits over `master` (one "Added
    python versions", one "added types", a sweep, an archive); the port's mvp history was not carried over.
  - `github.com/billsix/openglredbook9examples`, branch `python`: `python/redbook9/`, same shape, 4 commits.
  - `github.com/billsix/OpenGL` (McNopper), branch `python`: `python/src/`, same shape, 3 commits.
- **The source here** is the `ports/openglsuperbiblev4/` tree in `github.com/billsix/modelviewprojection`: one file per
  demo, `chaptNN/<demo>/<demo>.py` (the same names as `examples/src/chaptNN/<demo>/` here), plus `_common.py` (503 lines:
  the window and fullscreen state, an ImGui menubar, a walk-around `Camera`) and `_primitives.py` (225 lines: precomputed
  tessellation that replaces the `glutSolid*` shapes). Its README, translation rulebook and trap list are in that
  repository: `ports/openglsuperbiblev4/README.md`, `tasks/reference/superbible-ports-guide.md`,
  `tasks/reference/gl-and-imgui-gotchas.md`. Chapters 19, 20 and 22 are partly stubs (Win32/MFC, Carbon/Cocoa, OpenGL ES).
- **Not self-contained.** 13 files import `modelviewprojection.mathutils` (`find_normal`, `plane_equation`,
  `distance_to_plane`, and similar) and 13 import `gacalc.g3` (`github.com/billsix/geometricalgebra`). The sb7code move
  handled the same problem by vendoring the one shared module as a frozen copy (`python/sb7/window.py`); see question 2.
- **Assets are mostly duplicates.** Of the 154 non-Python files in the port (TGAs, shaders, EXR images, a LICENSE), 148 are
  byte-identical to the file at the same path under `examples/src/` here; six are not: three `chapt19/SphereWorld32/*.tga`
  (not in the C++ tree), `chapt15/shaders/shaders/shaders.vs` and `.fs` (a nested copy), and a stray Emacs backup
  `chapt05/ccube/#ccube.py#` that was committed by accident (do not carry it over). The sb7code move made the port read
  the repository's own media instead of carrying a copy; do the same here (question 3).
- **Port and C++ have drifted both ways.** On 2026-11-23 this repository changed three demos to run on current Mesa:
  `chapt06/motionblur` (texture-sum replacement for the accumulation buffer, copied from the Python port),
  `chapt07/imaging` (CPU imaging operations, copied from the Python port) and `chapt21/fonts` (font fallback). The
  Python side's own fidelity gaps: `chapt18/pixbufobj` shows "multiple spinning images" on the maintainer's GPU but not
  under llvmpipe (`tasks/pixbufobj-port-fidelity.md` in mvp); the walk-around camera is wired into only one canary
  (`tasks/ports-ux-pass.md` in mvp); host verification is incomplete (`tasks/superbible-full-port.md` in mvp).
- **Wayland and the loader.** Here the demos use GLee, which resolves entry points through GLX, so the C++ side runs on
  X11 or XWayland. The Python side uses PyOpenGL (EGL-capable) and runs on Wayland. sb7code's `AGENTS.md` describes the
  same split ("Two display backends, on purpose") and its `make run-c` launches the C++ demo with `WAYLAND_DISPLAY`
  unset. The mvp trap list has the one hazard to know: `import glfw` must come before `import imgui_bundle`, or
  imgui-bundle's X11-only GLFW wins and PyOpenGL finds no current context on Wayland. The other direction, a native
  Wayland C++ build, is a separate proposed task: `tasks/glut-shim-on-glfw.md`.
- **Container.** This repository's `Makefile` and `Dockerfile` already provide `make image|shell|shell-exec|format` for the
  C++ side (Fedora 45, freeglut, Mesa, Xvfb, openbox, clang-format). The branch needs the Python dependencies added
  (PyOpenGL, glfw, imgui-bundle, numpy, imageio, OpenEXR for `texfloat`, gacalc) and targets for both halves, following
  sb7code's `Makefile`.

## Plan (each phase is a staging boundary; do not start before the answers below)

1. Cut `python` from `master` (check `git log master..python` is empty first).
2. Copy `ports/openglsuperbiblev4/` from a clean checkout of mvp to `python/`: demos at
   `python/chaptNN/<demo>/<demo>.py`, no copied assets that duplicate `examples/src/`, no `__pycache__`, no `#ccube.py#`.
   Vendor `_common.py`, `_primitives.py` and whatever of `mathutils` the demos use (question 2); repoint every import;
   strip sandbox paths (`/superbible`, `/mvp`) from committed code; add `python/requirements.txt` and `pyproject.toml`.
3. Point asset loading at `examples/src/<chapter>/<demo>/` (or the chosen alternative, question 3), keeping the shader
   file names the book uses.
4. Top-level container for both halves, on top of the existing `Makefile`; `make run DEMO=chapt01/block` (Python,
   Wayland) and `make run-c DEMO=chapt01/block` (C++, X11).
5. Cold-start docs: copy and rewrite `superbible-ports-guide.md` and `gl-and-imgui-gotchas.md` into
   `tasks/reference/python-port/` so they read against this repository alone; harvest the open mvp tasks listed in
   question 4 into `tasks/`; add a `python` banner to `README.md` and `CLAUDE.md` on the branch only.
6. Gates: `make check` (import all 104 modules), `make type-check`, `make format`, plus the existing C++ `make format`; a
   headless render sweep on Xvfb like `tools/run_cmake_demos_xvfb.sh` for the Python side.
7. Sweep, stage, and leave the commit to the maintainer. Do not push `python` until the maintainer says so.
8. Record in the done-record that mvp's copy is deleted by task 3, not here.

## Open questions

1. Should the port's git history come with it? The three earlier branches did not (one "Added python versions" commit).
   This time `git filter-repo --path ports/openglsuperbiblev4 --path-rename ports/openglsuperbiblev4/:python/` could
   extract the 52 commits that touched it (`git log -- ports/openglsuperbiblev4` in that repository, 2026-11-23) and rebase them onto `python`, keeping authorship and dates; the cost is
   rewritten SHAs and a longer branch. Recommend: yes, keep the history, because after task 3 the original SHAs exist only
   in the archived repository.
2. How should the branch get `mathutils` and `gacalc`? (a) vendor the three or four `mathutils` functions the demos use
   as a frozen module (the sb7code precedent) and depend on `gacalc` from `github.com/billsix/geometricalgebra`; or (b)
   depend on `modelviewprojection` itself as well (the maintainer said both are allowed). Recommend (a): the new
   `modelviewprojection` repository is not installable from PyPI, and 13 call sites do not justify the dependency.
3. Assets: reference this repository's `examples/src/` files (recommended, no duplicates; the three `SphereWorld32`
   TGAs and nested `shaders` copies are the exceptions and need a home), or copy them beside each Python demo as the mvp
   port does (84 MB working tree, 148 duplicate files)?
4. Which mvp task documents move with the port? Candidates: `tasks/pixbufobj-port-fidelity.md`,
   `tasks/ports-ux-pass.md`, `tasks/superbible-full-port.md`, `tasks/curate-superbible-v4-demos.md`,
   `tasks/v4-chapt14-shadowmap-fix.md`, and the reference docs above. Recommend: move all of them; each is about this
   port, and mvp's own copy is removed by task 3.
5. Should the Python port keep its per-demo `README.md` and the stubs for chapters 19, 20 and 22, or drop the stubs?
   Recommend: keep them, so every C++ demo still has a Python counterpart file as in mvp.
