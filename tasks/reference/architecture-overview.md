# Architecture overview — OpenGL SuperBible v4 source

**Anchor reference doc.** Start here. Verified against source + git history 2026-08-02.
Siblings: `gltools-framework.md`, `build-and-imgui-fork.md`, `chapter-demo-inventory.md`,
`chapt18-advanced-buffers.md`.

## What this repo is

The example code for **OpenGL SuperBible, 4th edition** (Richard S. Wright Jr. et al., ~2007),
**© the authors** — a teaching codebase, one small demo per concept. This checkout is **Bill's
fork** (`origin` = a self-hosted Pi git remote, not GitHub): the root commit is the verbatim
upstream import, and every commit since is Bill's work to make the 2007 code build/run today
(Linux/macOS/Windows revival, Dear ImGui retrofit into 4 demos, a Windows include-order fix, two
GLSL specular fixes, clang-format hygiene). See `build-and-imgui-fork.md` for the full delta.

**Why it's here:** it's the C++ source the mvp book's `ports/openglsuperbiblev4/` Python demos
are ported from. The goal of this reference set is to make "what does the C++ original do here,
and how has the Python port diverged?" a lookup instead of a re-read (immediate trigger: the
`chapt18/pixbufobj` port shows multiple spinning images where the C++ shows one — answered in
`chapt18-advanced-buffers.md`).

## Layout

- **`examples/src/`** — the actual sources: `chapt01`–`chapt22` (one dir per demo) + **`shared/`**
  (the GLTools framework). One platform-agnostic copy.
- **`examples/projects/{linux,apple,microsoft}/`** — per-platform build wrappers only (Makefiles /
  Xcode / VS projects), referencing back into `examples/src/`. See `build-and-imgui-fork.md`.
- **`contrib/imgui/`** — vendored Dear ImGui (added in `c74bbd6` to make the build self-contained).
- **`readme.txt`** — upstream readme.

## The teaching arc (FF → GLSL → platform)

Every demo follows one skeleton: an init `SetupRC()` (called from `main`, not a callback) plus
GLUT callbacks `RenderScene`/`ChangeSize`/`SpecialKeys`/etc. The chapters progress:

- **ch01–14 — fixed-function / immediate-mode** (`glBegin`/`glEnd`, the matrix stack,
  fixed-function lighting/texturing, evaluators, GLU quadrics/NURBS, selection). Verified: no GLSL
  anywhere in these chapters.
- **ch15 — first GLSL** (`shaders`), then **ch16 (vertex)** and **ch17 (fragment/combined)** shader
  galleries.
- **ch18 — advanced buffers & textures** (PBOs, FBOs, float/HDR textures) — mixed FF + GLSL. Its
  own deep-dive doc; it's where the current port debugging lives.
- **ch19–22 — platform integration** (Windows/WGL, macOS/Carbon+Cocoa, Linux/GLX, OpenGL ES/EGL).
  All FF, mostly native-windowed (not GLUT), largely non-portable by design.

Per-demo details: `chapter-demo-inventory.md`.

## The shared framework (GLTools) — the substrate

Every demo links `math3d` (vector/matrix math), `gltools` (TGA loader, immediate-mode
`gltDraw*` geometry, extension helpers), and `GLee` (extension loader); most use `glframe.h`
(the `GLFrame` camera). This is **4th-edition GLTools** — the 5th-ed `GLShaderManager`/`GLBatch`/
`gltMake*` stack is absent (verified). Full API map + a live/dead table: `gltools-framework.md`.

## Dead / vestigial code (verified — the traps)

- **`shared/glfrustum.h` is DEAD** — 0 includes; it calls a `m3d*f` math API that doesn't exist
  in this edition (a 5th-ed header orphaned in-tree; won't compile). Don't reference it.
- **`gltLoadShaderPair` / `bLoadShaderFile`** in `gltools.cpp` — 0 callers; GLSL demos load
  shaders inline. Documented but unused.
- Later platform chapters lack build wrappers on some platforms; `chapt22/ES_example` needs an
  external ES emulator (non-buildable as-is).

## Dependencies (the practical bit)

GLUT (→ **freeglut** on Linux — the reason freeglut/-devel were added to the sandbox +
runClaudeInContainer), GL/GLU/libm everywhere; X libs only for `chapt21/GLXBasics`; **system
OpenEXR only for `chapt18/texfloat`** (the bundled `shared/openexr-*` serves the Win/Mac projects).
Details: `build-and-imgui-fork.md`.

## Correspondence to the mvp Python ports (the end goal)

The mvp repo (`github.com/billsix/modelviewprojection`) ports these demos to Python under
`ports/openglsuperbiblev4/`, with **deliberate divergences** (GLFW+imgui instead of GLUT menus,
Python idioms, and the occasional behavior/bug difference — e.g. the pixbufobj multi-image issue,
the pixbufobj `glGenBuffers` fix, the texfloat float-texture path). When comparing, this source is
ground truth; the port is where the changes live. Use `chapter-demo-inventory.md` to find a demo's
C++ original and `chapt18-advanced-buffers.md` for the chapter under active debugging.
