# OpenGLSuperBibleV4Code — context for Claude

**Third-party code, vendored as a fork.** This is the example code for *OpenGL SuperBible, 4th
edition* (Richard S. Wright Jr. et al., ~2007), **© the authors** — not Bill's original work.
This checkout is Bill's fork (`origin` = a self-hosted Pi git remote): the root commit is the
verbatim upstream import; everything since is Bill's revival work (build fixes on
Linux/macOS/Windows, a Dear ImGui retrofit into 4 demos, a Windows include-order fix, two GLSL
specular fixes, clang-format hygiene). Do not treat it as a maintained product or "modernize" it.

**Two languages, one branch:** `examples/` is the C++ (frozen at the 4th edition); `python/` is a faithful Python
port of every demo (moved here 2026-11-24 from the course repository, `github.com/billsix/modelviewprojection`, with
its history), reading the same textures and shaders from `examples/src/`. Each half is the other's oracle: compare the
C++ against the (diverged) port, e.g. the `chapt18/pixbufobj` "one image vs. multiple spinning images" issue. The
course repository keeps its own SuperBible-derived demos (`demo19a`–`19e`, `22`, `22a`, `22b`, `23`, `24`) and does not
read anything from here.

## Reference docs — read the relevant one before working in an area

A full map of this codebase lives in `tasks/reference/` (authored 2026-08-02 from a
subsystem-by-subsystem read; every claim `file:line`-anchored and verified):

- **`architecture-overview.md`** — start here: what the repo is, the FF→GLSL→platform teaching
  arc, the standard demo skeleton, dependencies, and how it corresponds to the mvp ports.
- **`gltools-framework.md`** — the `examples/src/shared/` library every demo builds on (math3d,
  glframe, gltools, GLee, VBOMesh, openexr) + a live/dead verdict table. **This is 4th-ed GLTools**
  (no 5th-ed `GLShaderManager`/`GLBatch`); **`glfrustum.h` is dead** (orphaned, won't compile).
- **`build-and-imgui-fork.md`** — how it builds (per-platform project trees, GLUT/**freeglut**, the
  one-shot link line) and the complete fork delta from git history.
- **`chapter-demo-inventory.md`** — the jump table: every demo in ch01–22, what it teaches, and its
  key `file:line`. Use it to find a Python port's C++ original.
- **The 2026-11-23 audit** (stage 1 of `tasks/archive/2026/11/23/cmake-crossplatform-build.md`; measured, not read):
  **`audit-summary.md`** (start here: findings, the revised CMake plan, open questions), **`source-audit.md`** (every
  demo: wrappers, whether it builds and runs on Linux), **`imgui-retrofit-status.md`** (the four ImGui demos work
  on Linux; the Makefile include path is wrong), **`history-audit.md`** (all 45 commits; the real source delta
  against the book is 15 files), **`windows-build-history.md`** (only 30 of 94 projects were converted),
  **`dependency-and-portability-audit.md`** (the GLUT surface, GLee macros, header forms), **`formatting-audit.md`**
  (Google style, no config committed). Where they disagree with the 2026-08-02 docs below, the audit wins.
- **`chapt18-advanced-buffers.md`** — deep-dive on the chapter under active debugging (pixbufobj's
  motion-blur feedback ring — the multi-image answer — and texfloat's float-texture setup).

## Build (CMake, added 2026-11-23)

`cmake -B build/cmake && cmake --build build/cmake` builds all 88 demos that had a Linux Makefile (`README.md` has the
macOS and Windows commands; those two are unverified, `tasks/cmake-verify-macos-windows.md`). Layout: `CMakeLists.txt`,
`examples/CMakeLists.txt` (`gltools` and `imgui` libraries, `add_demo()`), and `examples/cmake/chaptNN.cmake`, which are
**generated** by `tools/gen_chapter_cmake.py` from the old Makefiles: edit the generator, not the files. The old
per-platform trees under `examples/projects/` remain until the CMake build is verified on macOS and Windows.

## Container (added 2026-11-23)

`make image` / `make shell` / `make shell-exec SCRIPT=...|CMD=...` / `make format`: a Fedora 45 image with gcc, freeglut,
Mesa, Xvfb and clang-format; the source is bind-mounted, builds go to the ignored `build/`. `tools/run_cmake_demos_xvfb.sh`
runs every built demo headless (`BUILD_DIR=cmake-ctr`
for a container-only build tree: a host build in `build/cmake` and a container build cannot share one CMake cache). The audit's one-shot scripts and snapshot data are in git history under
`tasks/adhoc/cmake-crossplatform-build/` (removed when the task archived).

## Python port (`python/`, added 2026-11-24)

`make run DEMO=chapt01/block` runs the Python port, `make run-c DEMO=chapt01/block` the C++ original (X11; the demos'
GLee loader goes through GLX), `make list` lists the ports, `make check` imports every module with no display,
`make type-check` runs the annotate-every-binding checker (`ty` is not a gate: glfw/imgui stub friction), `make format`
runs clang-format and ruff (`ruff.toml`), `make update-pins` re-resolves `python/constraints.txt`. One image serves both
halves; the Python `/venv` is built by `entrypoint/03-install-python.sh`. `tools/run_python_demos_xvfb.sh` runs every
port headless. The display flags (Wayland socket, `XDG_SESSION_TYPE`, `PYGLFW_LIBRARY` = Fedora's dual-build `libglfw`, `XAUTHORITY`, `/dev/dri`)
are in the `Makefile` and explained in `python/README.md` ("Display"). A demo reads its assets through `_common.asset_dir()` (the same directory under `examples/src/`); the
only asset files beside the Python are `python/chapt15/shaders/shaders.{vs,fs}`. Read
`tasks/reference/python-port/translation-guide.md` before porting or bulk-editing the port and
`gl-and-imgui-gotchas.md` there before debugging GL or imgui. The Python follows the maintainer's Python standard
(annotate every binding, Google docstrings), not the "don't modernize" rule below, which covers `examples/` only.

`make shell` loads the maintainer's configuration like the other projects of the template: the host's `~/.tmux.conf`, `~/.gitconfig` and
`~/.gnupg` are mounted when present (`:Z` relabels them), `entrypoint/dotfiles/.extrabashrc` sets the two-line prompt, `GPG_TTY` and an
`exit()` that runs `format.sh` from the repository root, and `shell.sh` sets `VIRTUAL_ENV_DISABLE_PROMPT=1` so the venv name stays out of the
prompt. Editing a dotfile rebuilds only the last image layers.

## Review records

Latest: `tasks/review/2026/11/23/repo-review.md` (a scoped review for the CMake task; frozen).

## Tasks

Work lives in `tasks/` (the study that produced the reference set: `tasks/archive/2026/08/02/study-the-source.md`; the
CMake build: `tasks/archive/2026/11/23/cmake-crossplatform-build.md`). Open: `tasks/cmake-verify-macos-windows.md`,
`tasks/glut-shim-on-glfw.md`, and the port's own:
`tasks/ports-ux-pass.md`, `tasks/pixbufobj-port-fidelity.md`, `tasks/v4-chapt14-shadowmap-fix.md`,
`tasks/curate-superbible-v4-demos.md`; the 88-demo fixes: `tasks/archive/2026/11/23/headless-demo-gaps.md`. Completed work moves to `tasks/archive/<YYYY>/<MM>/<DD>/`.

## Conventions

- It's a teaching artifact frozen at the 4th edition; **don't refactor or modernize** the C++ under `examples/`
  (formatting is Google style through `.clang-format`; `make format` applies it).
- Keep source edits minimal so the code stays like the book, but fixing a program that does not work is a valid reason to
  edit it (maintainer's rule, William Emerison Six <billsix@gmail.com>, 2026-11-23). Edits so far: `windows.h` guard in
  `chapt04/transformgl`, `GL/glx.h` and a font fallback in `chapt21/fonts`, a texture replacement for the accumulation
  buffer in `chapt06/motionblur`, CPU imaging operations in `chapt07/imaging`.
- Dependencies: GLUT (→ freeglut on Linux), GL/GLU; only `chapt21/GLXBasics` needs X libs, only
  `chapt18/texfloat` needs system OpenEXR. The CMake build compiles the shared GLTools code once into
  a static library (the old Makefiles recompiled it per demo).
- Reference container paths are sandbox-local; refer to Bill's own projects by their GitHub URL in
  any committed doc.
