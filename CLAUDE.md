# OpenGLSuperBibleV4Code — context for Claude

**Third-party code, vendored as a fork.** This is the example code for *OpenGL SuperBible, 4th
edition* (Richard S. Wright Jr. et al., ~2007), **© the authors** — not Bill's original work.
This checkout is Bill's fork (`origin` = a self-hosted Pi git remote): the root commit is the
verbatim upstream import; everything since is Bill's revival work (build fixes on
Linux/macOS/Windows, a Dear ImGui retrofit into 4 demos, a Windows include-order fix, two GLSL
specular fixes, clang-format hygiene). Do not treat it as a maintained product or "modernize" it.

**Why it's mounted here:** it's the C++ source the mvp book's `ports/openglsuperbiblev4/` Python
demos are ported from. We consult it to compare the original C++ behavior against the (diverged)
Python ports — e.g. the `chapt18/pixbufobj` "one image vs. multiple spinning images" issue.

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
- **`chapt18-advanced-buffers.md`** — deep-dive on the chapter under active debugging (pixbufobj's
  motion-blur feedback ring — the multi-image answer — and texfloat's float-texture setup).

## Tasks

Work lives in `tasks/` (see `tasks/study-the-source.md`, the study that produced the reference
set). Completed work moves to `tasks/archive/<YYYY>/<MM>/<DD>/`.

## Conventions

- It's a teaching artifact frozen at the 4th edition; **don't refactor or modernize** the C++.
- Dependencies: GLUT (→ freeglut on Linux), GL/GLU; only `chapt21/GLXBasics` needs X libs, only
  `chapt18/texfloat` needs system OpenEXR. The Linux build recompiles everything from source each
  time (see the build doc).
- Reference container paths are sandbox-local; refer to Bill's own projects by their GitHub URL in
  any committed doc.
