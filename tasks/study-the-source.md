# Study & map the OpenGL SuperBible v4 source (produce a reference set)

**Status:** complete (study + reference set) — 2026-08-02. The follow-on **C++-vs-mvp-port
comparison** (starting with `chapt18/pixbufobj`) is the enabled next step, tracked separately.
**Priority:** 10
**Difficulty:** 7
**Created:** 2026-08-02

## Done 2026-08-02 — the reference set

Executed the fan-out (7 parallel readers: framework, build/fork, chapters 01–06/07–12/13–17/
19–22, chapt18 deep-dive). Every load-bearing claim was independently grep-verified before it
entered a doc. Produced in `tasks/reference/`:

- `architecture-overview.md` (anchor) · `gltools-framework.md` · `build-and-imgui-fork.md` ·
  `chapter-demo-inventory.md` · `chapt18-advanced-buffers.md`; plus a repo-root `CLAUDE.md` index.

**Verified findings worth calling out:** it's **4th-ed GLTools** (no 5th-ed
`GLShaderManager`/`GLBatch`); **`shared/glfrustum.h` is dead** (0 includes, needs a `m3d*f` API
that doesn't exist); the whole git history *is* the fork delta (root commit = verbatim upstream);
imgui is wired into exactly 4 Linux demos; only `chapt18/texfloat` needs system OpenEXR.

**The pixbufobj answer (the trigger):** the C++ draws ONE quad with motion blur ON by default;
the "trail" is a 3-frame readback→attenuate→re-upload feedback ring on texture units 1/2 (identity
texcoords) while only unit 0 carries the accumulating rotation. Multiple spinning copies in the
port = rotation/reservoir applied to more than unit 0, or the feedback omitted. Details in
`chapt18-advanced-buffers.md`; the actual diff is the next task.

## Why

This is the C++ source the mvp book's `ports/openglsuperbiblev4/` demos are ported from.
We keep needing the C++ original to reason about the ports (the immediate trigger: the
`chapt18/pixbufobj` port shows *multiple* spinning images where the C++ shows *one*). Rather
than re-read the tree ad hoc each time, do one thorough pass and leave a durable, navigable
map so any future "what does the C++ original do here?" is a lookup, not a re-read.

This is a **third-party** codebase — OpenGL SuperBible, 4th ed., © Richard S. Wright Jr.
et al. — vendored as **Bill's fork** (`origin` = the Pi remote; HEAD `c74bbd6` "add imgui,
to fix build", plus Windows build fixes). We are mapping it, not owning it.

## Method (the unknown-codebase procedure)

1. **Fan out one reader per subsystem, in parallel** (subagents), each returning a
   **structured, `file:line`-anchored report**, not prose. I synthesize the reports into the
   docs myself and verify as I go. The seams here: the shared **GLTools framework**, the
   **build/platform-projects + imgui fork delta**, and the **22 chapters** (split into a few
   batches).
2. **Verify any claim before it enters a durable doc** — especially "X is dead / unused /
   vestigial" (grep for refs; confirm the build actually excludes it). Candidates to check
   here: `GLee` (extension loader — still used, or superseded?), the bundled `openexr-*`
   trees (used by the HDR/float demos, or dead weight?), `wglext.h` (Windows-only).
3. **Distinguish live vs dead/vestigial code explicitly** — the highest-value thing the map
   records.
4. **Git history answers why/when/who, not what-is-true-now.** Use it for the **fork delta**
   (the imgui integration and the build fixes that make 2007-era code compile today);
   reconstruct current architecture from current code.
5. **Every claim `file:line`-anchored** so the docs let you jump, not re-search.

## Deliverables — the reference set (in `tasks/reference/`)

- **`architecture-overview.md`** (anchor) — what the repo is (third-party + fork), the
  teaching structure (one demo per concept, chapt01→22), the fixed-function→GLSL arc, the
  standard demo skeleton (`RenderScene`/`SetupRC`/`ChangeSize` + GLUT `main` callbacks), the
  GLUT/freeglut windowing dependency, and links to the docs below.
- **`gltools-framework.md`** — the `examples/src/shared/` library every demo builds on:
  `math3d` (M3D vector/matrix types + ops), `glframe.h` (GLFrame camera), `glfrustum.h`,
  `gltools` (GLShaderManager stock shaders, GLBatch/GLTriangleBatch, `gltMake*` geometry),
  `GLee` (extension loading), `TriangleMesh`/`VBOMesh`, `stopwatch`, bundled `openexr`.
- **`build-and-imgui-fork.md`** — how it builds (`examples/projects/{linux,apple,microsoft}/`
  per-demo project files, the GLUT/freeglut dep — the reason we added `freeglut`/`-devel`),
  and the **fork delta** from git history (imgui add, Windows `windows.h`-ordering fix).
- **`chapter-demo-inventory.md`** — per-chapter map (chapt01–22): what each demo teaches,
  its key source file, FF vs shader, and the mvp-port cross-reference where one exists. This
  is the jump table for finding the C++ original of any Python port.

Plus a lean **`CLAUDE.md`** at the repo root indexing the set (so future sessions orient),
noting the third-party-fork status. (This repo has no `CLAUDE.md` today.)

## Scale / cost

~130 `.cpp` + ~218 `.h`. Roughly 4–6 parallel readers (framework, build/fork, and the
chapters in 2–3 batches), then synthesis + verification. One phase; I stay in the loop and
verify claims before they land in the docs.

## Not in scope

Fixing or modernizing the C++, or building it — this is a *read-and-map* task. (The current
`pixbufobj` C++-vs-port diff is separate; it can start before or after this, and this map
makes it and every later port comparison cheaper.)
