# Add the Python port of every demo to this repository's `master` (moved from modelviewprojection)

**Status:** proposed — needs go-ahead (filed 2026-11-23; revised 2026-11-24 to one branch and a verified layout)
**Priority:** 6
**Difficulty:** 5
**Created:** 2026-11-23
**Part of:** a three-task split, the maintainer's plan (William Emerison Six <billsix@gmail.com>, 2026-11-23):
(1) this task, (2) `tasks/extract-code-the-classics-to-own-repo.md` in `github.com/billsix/modelviewprojection`,
(3) `tasks/rewrite-history-without-ports.md` in the same repository. Task 3 must not start until this one and task 2 are
done, because it deletes the port from that repository's history.

## BLUF

The Python translation of these demos lives in `github.com/billsix/modelviewprojection` at `ports/openglsuperbiblev4/`
(104 `.py` files, 22 chapters). Move it into this repository's **single branch** (`master`; the maintainer decided
2026-11-24 against a separate `python` branch), under a new top-level `python/` directory, next to the untouched C and
C++ in `examples/`. The port reads the textures and shaders that already live in `examples/src/`, and the existing
`Dockerfile` and `Makefile` grow a Python layer so one image builds and runs both halves. Done means: on `master`,
`make shell` can run any C++ demo (freeglut, X11) and the Python port of it (GLFW, Wayland), `make check` imports every
port with no display, the port's reference docs and open tasks live here, and `examples/` is byte-for-byte unchanged by
this task.

## Context (read first)

- **The pattern, three finished examples**, each with a `python` *branch* (this repository departs from them on purpose:
  one branch). Read their `README.md`, `AGENTS.md` and `tasks/archive/2026/10/19/*` for the container and doc shape:
  `github.com/billsix/sb7code` (closest model: `tasks/archive/2026/10/19/pythonize-and-containerize-port.md`;
  `python/` flat scripts plus a shared `python/sb7/` package, top-level `Dockerfile`, `Makefile` with
  `make image|shell|run|run-c|check|type-check|format|list`, `entrypoint/`, `tasks/reference/python-port/` with six
  docs, `tools/check_local_annotations.py`), `github.com/billsix/openglredbook9examples` (`python/redbook9/`) and
  `github.com/billsix/OpenGL` (McNopper; `python/src/`).
- **The source** is `ports/openglsuperbiblev4/` in `github.com/billsix/modelviewprojection`: one file per demo,
  `chaptNN/<demo>/<demo>.py` (the same names as `examples/src/chaptNN/<demo>/` here), plus `_common.py` (503 lines:
  window and fullscreen state, an ImGui menubar, a walk-around `Camera`) and `_primitives.py` (225 lines: precomputed
  tessellation replacing `glutSolid*`). Each demo finds `_common` by prepending the ports root to `sys.path` and loads its
  assets from its own directory (`PWD`). Its README, rulebook and trap list: `ports/openglsuperbiblev4/README.md`,
  `tasks/reference/superbible-ports-guide.md`, `tasks/reference/gl-and-imgui-gotchas.md` in that repository. Chapters
  19, 20 and 22 are partly stubs (Win32/MFC, Carbon/Cocoa, OpenGL ES).
- **This repository's layout today (verified 2026-11-24):** `examples/src/chaptNN/<demo>/` (C++ plus each demo's
  textures and shaders) and `examples/src/shared/` (GLTools); `examples/cmake/` (generated, from
  `tools/gen_chapter_cmake.py`), `examples/projects/` (old per-platform trees); `CMakeLists.txt`; one `Dockerfile`
  (Fedora 45) running `entrypoint/01-install-base.sh` and `02-install-graphics.sh`; `Makefile` (`image`, `shell`,
  `shell-exec`, `format`, `image-export`, `image-import`, `help`; the repository bind-mounted at `/superbible4`, X11 and
  Wayland passthrough already in `SHELL_RUN_FLAGS`); `entrypoint/format.sh` (clang-format); `tools/`;
  `.dockerignore` (excludes `tasks/`, `examples/`, `contrib/`, so the image bakes only toolchain, never source);
  `.clang-format`. There is no Python anywhere yet and no `constraints.txt`.
- **Not self-contained.** 13 port files import `modelviewprojection.mathutils` (`find_normal`, `plane_equation`,
  `distance_to_plane`, and similar) and 13 import `gacalc.g3` (`github.com/billsix/geometricalgebra`). sb7code vendored
  the one shared module as a frozen copy (`python/sb7/window.py`); see question 2.
- **Assets: nothing to copy.** Of the 154 non-Python files in the port, 148 are byte-identical to the same path under
  `examples/src/` here. The other six: `chapt19/SphereWorld32/{grass,orb,wood}.tga` are not at that path here but are
  byte-identical to `examples/src/chapt09/sphereworld/` and the other `sphereworld` directories' copies, so point the stub
  there; `chapt15/shaders/shaders/shaders.{vs,fs}` is a nested duplicate (check that `chapt15/shaders/shaders.py` reads
  `examples/src/chapt15/shaders/shaders.{vs,fs}`, and drop the nested copy); `chapt05/ccube/#ccube.py#` is an Emacs
  backup committed by accident (never carry it over).
- **Port and C++ have drifted both ways.** On 2026-11-23 this repository changed `chapt06/motionblur`, `chapt07/imaging`
  and `chapt21/fonts` to run on current Mesa (the first two copied from the Python port). The Python side's own fidelity
  gaps: `chapt18/pixbufobj` shows "multiple spinning images" on the maintainer's GPU but not under llvmpipe
  (`tasks/pixbufobj-port-fidelity.md` in mvp); the walk-around camera is wired into one canary
  (`tasks/ports-ux-pass.md` in mvp); host verification is incomplete (`tasks/superbible-full-port.md` in mvp).
- **Wayland and the loader.** GLee resolves entry points through GLX, so the C++ side runs on X11 or XWayland; the Python
  side (PyOpenGL, EGL-capable) runs on Wayland. sb7code's `AGENTS.md` ("Two display backends, on purpose") describes the
  same split and its `make run-c` launches C++ with `WAYLAND_DISPLAY` unset. The one hazard in the mvp trap list:
  `import glfw` must come before `import imgui_bundle`. A native Wayland C++ build is a separate task:
  `tasks/glut-shim-on-glfw.md`.

## Where each new thing goes (decided 2026-11-24; the maintainer asked that the layout be settled before work starts)

| New file or directory | Purpose |
|---|---|
| `python/chaptNN/<demo>/<demo>.py`, `python/_common.py`, `python/_primitives.py` | the port, same chapter and demo names as `examples/src/`; no asset files |
| `python/README.md` | run, verify, layout (carried over and rewritten against this repository) |
| `python/requirements.txt`, `python/constraints.txt`, `python/pyproject.toml` | dependencies (PyOpenGL, glfw, imgui-bundle, numpy, imageio, OpenEXR, gacalc), the `uv pip compile`d lock, and the ruff and `ty` settings that apply to `python/` only |
| `entrypoint/03-install-python.sh` | one more install script in the existing `Dockerfile` (a `/venv` created with `uv`, `uv pip install -c python/constraints.txt -r python/requirements.txt`); **one image for both halves**, no second Dockerfile |
| `Makefile` (existing) | add `run DEMO=chapt01/block` (Python, Wayland), `run-c DEMO=chapt01/block` (C++, `WAYLAND_DISPLAY` unset), `check`, `type-check`, `list`, `update-pins`; extend `format` with ruff |
| `entrypoint/format.sh` (existing) | add the ruff format and lint step, with the `status=0; … exit $status` shape |
| `tools/` (existing) | add `check_local_annotations.py` (copied from mvp), `keywordify.py` (moves with the port; its default tree becomes `python/`), and `run_python_demos_xvfb.sh` beside `run_cmake_demos_xvfb.sh` |
| `tasks/reference/python-port/` | the guide and gotchas docs rewritten to read against this repository |
| `README.md`, `CLAUDE.md`, `.gitignore` (existing) | the repository is now two languages permanently; the "don't modernize" rule keeps its scope as `examples/`, and `python/` follows the maintainer's Python standard; ignore `__pycache__`, `/venv` |

Assets: the port resolves a demo's files through one helper in `_common.py`,
`asset_path(chapter, demo, name)` → `<repo root>/examples/src/<chapter>/<demo>/<name>` (repo root found from
`__file__`, so it works in the container and on the host). The alternative, putting each `<demo>.py` beside the C++ in
`examples/src/<chapter>/<demo>/` so the existing relative paths work unchanged, was rejected: it mixes two languages inside
the CMake-managed directories and the clang-format scope, and `examples/` must stay untouched.

## Plan (each phase is a staging boundary)

1. Work on a branch the batch creates for the review (named for this task); the maintainer merges it into `master`.
2. Extract the port's history: from a fresh clone of mvp, `git filter-repo` keeping `ports/openglsuperbiblev4/**/*.py` and
   its `README.md`, renamed to `python/` (never the assets, never `#ccube.py#`), then bring it in with
   `git merge --allow-unrelated-histories` (question 1). Check with `git log -- python` and that `examples/` is unchanged.
3. Vendor `_common.py`, `_primitives.py` and the `mathutils` functions the demos use as a frozen module (question 2);
   repoint imports; strip sandbox paths (`/superbible`, `/mvp`) from committed code; add the requirements and
   `pyproject.toml`; replace each demo's `PWD`-relative asset path with `asset_path` (question 3).
4. Container: `03-install-python.sh`, the `Makefile` targets and `format.sh` step in the table above.
5. Docs: rewrite the guide and gotchas docs under `tasks/reference/python-port/`; move the open mvp tasks of question 4
   into `tasks/`; update `README.md`, `CLAUDE.md`, `python/README.md`.
6. Gates: `make check` (import all 104 modules), `make type-check`, `make format`, the C++ gate unchanged, and a headless
   Xvfb sweep of the Python demos.
7. Sweep, stage, and leave the commits to the maintainer unless commits are authorized for the batch.
8. Record in the done-record that mvp's copy is deleted by task 3, not here, and which mvp demos stay (below).

## Which mvp demos stay and which go once the port is deleted (verified 2026-11-24)

Nothing remaining in mvp reads a file under `ports/` or imports from it (`git grep` over `src`, `tests`, `book/docs`,
`notebooks`, `assignments`, `tools`). The curriculum demos that came from SuperBible v4 carry **their own copies** of
their shaders and textures in their own directories, byte-identical (md5) to the files under `examples/src/` here. So no
asset under `ports/` has to survive; the ones that stay are the demos' own copies.

| mvp demo (STAYS, the curriculum) | its own assets, which STAY with it | port counterpart (GOES with `ports/`) |
|---|---|---|
| `demo19a.py` | none | `chapt10/axes3d` |
| `demo19b.py` | none | `chapt04/atom` |
| `demo19c.py` | none | `chapt04/solar` |
| `demo19d.py` | none | `chapt12/moons` |
| `demo19e.py` | none | `chapt04/sphereworld` |
| `demo22/` | `block.vert`, `block.frag`, `Block4.tga`, `Block5.tga`, `Block6.tga`, `floor.tga` | `chapt01/block` |
| `demo22a/` | `pyramid.vert`, `pyramid.frag`, `stone.tga` | `chapt08/pyramid` |
| `demo22b/` (demo22 through a glTF round trip) | `block.vert`, `block.frag`; the textures come from `demo22/` | `chapt01/block` |
| `demo23/` | `litjet.vert`, `litjet.frag` | `chapt05/litjet` |
| `demo24/` | `sphereworld.vert`, `sphereworld.frag`, `grass.tga`, `wood.tga`, `orb.tga` | `chapt09/sphereworld` |

Everything else under `ports/openglsuperbiblev4/` GOES (all 104 files and their assets), and so do the mvp files that exist
only for the port: `tools/keywordify.py` (moves here, see the table above) and the port's reference docs (copied here, question 4).
Demos 01–21 are mvp's own and have no port.

## Open questions

Decisions the maintainer asked me to take as recommended (2026-11-24: "go with your recommendations on all five"); they are
recorded in this document when the work starts.

1. Should the port's git history come with it? Recommend: yes, as in Plan step 2. After task 3 the original SHAs exist only in
   the archived repository. The cost is a merge commit with unrelated history on the review branch and rewritten SHAs.
2. How should the port get `mathutils` and `gacalc`? Recommend: vendor the few `mathutils` functions the demos use as a frozen
   module (the sb7code precedent) and depend on `gacalc` from `github.com/billsix/geometricalgebra`.
3. Assets: recommend referencing `examples/src/` through `asset_path` (no copies); the stub for chapter 19 points at the
   chapter 9 `sphereworld` textures.
4. Which mvp task documents move with the port? Recommend: all of `pixbufobj-port-fidelity`, `ports-ux-pass`,
   `superbible-full-port`, `curate-superbible-v4-demos`, `v4-chapt14-shadowmap-fix`, and the two reference docs; mvp's copy
   is removed by task 3.
5. Keep the per-demo `README.md` and the stubs for chapters 19, 20 and 22? Recommend: keep, so every C++ demo has a Python
   counterpart file.
