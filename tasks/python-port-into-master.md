# The Python port of every demo, moved into this repository's `master`

**Done:** 2026-11-24 (work commit; the archive move follows). Task 1 of a three-task split, the maintainer's plan (William
Emerison Six <billsix@gmail.com>, 2026-11-23): task 2 is `tasks/extract-code-the-classics-to-own-repo.md` and task 3 is
`tasks/copy-history-without-ports.md`, both in `github.com/billsix/modelviewprojection`. Decisions: one branch, not a `python`
branch (2026-11-24), and the recommendation on each of the five open questions (2026-11-24, "go with your recommendations on all
five").

## What was done

The Python translation of every SuperBible v4 demo (104 `.py` files, 22 chapters) moved from
`ports/openglsuperbiblev4/` in `github.com/billsix/modelviewprojection` to `python/` here, next to the untouched C and C++ in
`examples/`. The work happened on the branch `python-port-into-master`, for the maintainer to merge into `master`.

- **History came with it** (question 1: yes). A fresh clone of the course repository went through `git filter-repo`, keeping
  `ports/openglsuperbiblev4/**/*.py` and its `README.md`, renamed to `python/`, so assets and the stray `#ccube.py#` stayed
  behind. It was merged with `--allow-unrelated-histories`: 52 commits touch `python/` now, authorship and dates kept, SHAs
  new. `git diff master -- examples` was empty after the merge.
- **No asset copies** (question 3). Each demo reads its textures and shaders from the same directory under `examples/src/`
  through `_common.asset_dir(PWD)` (`ASSET_DIR` in the demos). 39 files were changed by the codemod
  `tasks/adhoc/python-port-into-master/repoint_port.py` (idempotent: second run, zero changes; removed in the archive commit).
  Two cases the codemod does not cover: `chapt19/SphereWorld32` now names `Grass.tga`, `Wood.tga`, `Orb.tga` as the C++
  directory spells them, and `chapt15/shaders/shaders.{vs,fs}` stay beside the Python (flattened from a nested `shaders/`
  directory) because the C++ original embeds the GLSL in `shaders.cpp`.
- **`mathutils` vendored** (question 2). `python/_geometry.py` holds `find_normal` and `plane_equation`, the only two functions
  the 13 call sites use (the doc listed three or four; `distance_to_plane` is unused). `gacalc==0.1.1` is a dependency.
- **Docs and tasks moved** (questions 4 and 5). The translation guide and the gotchas (sections 1 to 6) are rewritten under
  `tasks/reference/python-port/`; the five task docs `superbible-full-port`, `ports-ux-pass`, `pixbufobj-port-fidelity`,
  `curate-superbible-v4-demos` and `v4-chapt14-shadowmap-fix` are copied into `tasks/` with paths rewritten (the course
  repository's copies are deleted by task 3, not here). The per-demo structure and the stubs for chapters 19, 20 and 22
  are kept.
- **Container and gates.** One `Dockerfile` serves both halves: `entrypoint/03-install-python.sh` builds `/venv` from
  `python/requirements.txt` and the `uv pip compile`d `python/constraints.txt` (`make update-pins`); `01-install-base.sh` gained
  `uv`, `02-install-graphics.sh` the Wayland and EGL client libraries. `Makefile` targets: `run DEMO=chapt01/block`,
  `run-c DEMO=chapt01/block`, `list`, `check`, `type-check`, `update-pins`; `make format` runs clang-format and ruff.
  Departures from the plan: ruff settings are in a repository-root `ruff.toml` (it also governs `tools/`), not
  `python/pyproject.toml`; `ty` is not a gate (the course repository's reason: glfw and imgui stub friction), so
  `type-check` is the annotate-every-binding checker alone. Tools added: `check_python_imports.py`, `check_local_annotations.py`
  (copied), `keywordify.py` (moved, default tree `python/`), `run_python_demo.sh`, `run_c_demo.sh`, `run_python_demos_xvfb.sh`.
  `.dockerignore` now excludes `build/` (the context was shipping it) and `python/**/__pycache__`.

## Verification (all in the container, 2026-11-24)

- `make check`: 105 of 105 modules import with no display. `make type-check`: clean. `make format`: exit 0 and a second run
  changes nothing; `git status examples` is empty (the C++ is byte-for-byte as before).
- `tools/run_python_demos_xvfb.sh` (every demo under Xvfb and llvmpipe, 5 s each): 94 alive of 102; the other 8 are the 7
  documented stubs (`chapt19/GLView`, `RThread`, `chapt20/*` four, `chapt22/ES_example`: they print a notice and exit) plus one
  sweep bug found and fixed (a `__pycache__` directory counted as a demo; the sweep and `make list` now skip it).
  `chapt19/fscreen` is alive but shows 5 colours; the cause is not investigated.
- `tools/run_c_demo.sh chapt01/block` builds one CMake target in `build/cmake-ctr` and runs it on Xvfb; its picture matches
  the Python `chapt01/block` picture (wireframe cube on a blue floor).

Not verified: the Wayland path (this sandbox has no Wayland session), the interactive `-it` path of `make run` and
`make run-c`, and any real GPU. Those need the maintainer's display, the same as the existing hardware punchlist in
`tasks/superbible-full-port.md`.

## Which mvp demos stay and which go once the port is deleted (verified 2026-11-24)

Nothing remaining in the course repository reads a file under `ports/` or imports from it (`git grep` over `src`, `tests`,
`book/docs`, `notebooks`, `assignments`, `tools`). The curriculum demos that came from SuperBible v4 carry their own copies
of their shaders and textures in their own directories, byte-identical (md5) to the files under `examples/src/` here. No asset
under `ports/` has to survive; the ones that stay are the demos' own copies.

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

Everything else under `ports/openglsuperbiblev4/` goes in task 3 (it now lives here), and `tools/keywordify.py` moved here.
Demos 01 to 21 are the course's own and have no port.

## Owed

- The maintainer merges `python-port-into-master` into `master` and pushes.
- Task 3 deletes the course repository's copy (and its copies of the five task docs above, `tools/keywordify.py` and the two
  reference docs). Task 3 now creates a new repository (`Programming3DComputerGraphics`) as a copy of the history instead of
  rewriting the old one.
- `chapt19/fscreen` (5 colours under Xvfb) and the Wayland and host checks are open verification, not defects found.
