# Build system & the fork delta

**Reference doc** — how this tree builds, its exact dependencies, and everything this
**fork** changed from Richard S. Wright Jr.'s original SuperBible 4e code. Verified against
the source + git history 2026-08-02. Sibling docs: `architecture-overview.md`,
`gltools-framework.md`, `chapter-demo-inventory.md`, `chapt18-advanced-buffers.md`.

## The fork question, settled

The root commit **`e802274` "from http://www.openglsuperbible.com/previous-editions/"** is
the verbatim import of Wright's original code (1777 files, ~209k insertions). **Every commit
after it is authored by billsix — so the entire history *is* the fork delta.** `origin` is a
self-hosted Pi remote (`pi@192.168.0.186:…`), not GitHub.

## Layout: one source tree, per-platform build wrappers

- **`examples/src/`** — the actual demo `.cpp`/shader sources: `chapt01`–`chapt22` + `shared/`
  (the GLTools framework). Platform-agnostic; **one copy**, shared by all platforms.
- **`examples/projects/{linux,apple,microsoft}/`** — build wrappers only, one subdir per demo,
  **no source** — they reference `../../../../src/...`. ~19 chapters' worth of demos wrapped
  per platform (not every chapter on every platform; the higher platform-integration chapters
  are uneven).
  - **linux/**: a hand-written `Makefile` per demo + a top-level `build` script
    (`examples/projects/linux/build`) that `cd`s into each demo and runs `make`.
  - **apple/**: Xcode `.xcodeproj` bundles.
  - **microsoft/**: Visual Studio `.vcxproj` + NuGet `packages.config`.

## How a Linux demo compiles (canonical `chapt01/block/Makefile`)

- Compiler **`gcc`** with `-DGL_GLEXT_PROTOTYPES -lstdc++` (C++ via libstdc++ despite the gcc
  driver). Include path adds `../../../../src/shared` and 2007-era `/usr/local/include/GL`.
- The real recipe is a **single one-shot link line** that recompiles the demo **plus three
  shared sources every build** — the `.o` rules are vestigial:
  ```
  gcc $(CFLAGS) -o Block  <demo>.cpp  shared/math3d.cpp  shared/gltools.cpp  shared/GLee.c  $(LIBS)
  ```
  (This is why the hardcoded 2007 paths still work — nothing is cached; every build is from
  source.)

## Exact dependencies (Linux)

- **GLUT** — `-lglut` on every demo; the source picks **freeglut** on non-Apple
  (`bounce.cpp:15-19`: `<GLUT/glut.h>` on `__APPLE__`, else `<GL/freeglut.h>`). *(This is why
  we added `freeglut`/`freeglut-devel` to the sandbox + runClaudeInContainer Dockerfile.)*
- **GL / GLU / libm** — `-lGL -lGLU -lm` everywhere.
- **X libs** — only `chapt21/GLXBasics` (raw GLX): `-lX11 -lXi -lXmu`.
- **OpenEXR** — **only `chapt18/texfloat`**: `-lIlmThread -lIlmImf` + `-I/usr/local/include/OpenEXR`
  (verified). **`hdrbloom` does NOT use OpenEXR** (plain `-lm`) — the readme's blanket
  "chapter 18 needs OpenEXR" overstates it.
- **Shared GLTools** — `math3d.cpp`, `gltools.cpp`, `GLee.c` compiled into *every* demo (see
  `gltools-framework.md`).
- **imgui** — integrated into exactly **4 Linux demos** (verified via `grep -l IMGUI_SRC`):
  `chapt02/bounce`, `chapt05/ambient`, `chapt08/pyramid`, `chapt15/shaders`.

## How imgui is wired in (Linux)

Per-demo Makefile additions (e.g. `chapt02/bounce/Makefile`): an include path to
`contrib/imgui/`, an `IMGUI_SRC` var listing six vendored `.cpp` (imgui core +
`imgui_impl_glut` + the renderer backend — `imgui_impl_opengl2` for the FF demos,
`imgui_impl_opengl3` for `chapt15/shaders`), prepended to the link line; `bounce` also adds
`-fno-threadsafe-statics -fno-exceptions`. Source side includes `imgui.h`/backends and drives
the standard imgui loop.

## The fork delta — what Bill changed to revive 2007 code (git history)

- **`c74bbd6` "add imgui, to fix build"** (origin/HEAD) — vendors 17 Dear ImGui files into
  `contrib/imgui/` (~39k insertions), touching nothing under `examples/`. "To fix build" =
  the Makefiles had referenced `contrib/imgui/` since 2019–2020 but the library was never
  in-tree, so a fresh clone couldn't build the imgui demos. This makes the build self-contained.
- **imgui was retrofitted into the demos earlier**, not in `c74bbd6`: `498c5ca` (2019,
  bounce, first), then pyramid/`chapt15 shaders`/ambient (2020) — the original GLUT menu/keyboard
  UI was replaced with imgui because "the glut ones were failing."
- **`b8e9cea` "fixed build on windows… windows.h needs to be imported first"** — the titular
  fix moved `#include <windows.h>` to be first inside `#ifdef WIN32` in
  `examples/src/shared/gltools.h:17-18` (GL headers need its macros first) + a bare include in
  `transformgl.cpp`; the same commit bulk-modernized ~30 microsoft demos (dead `nupengl.core`
  NuGet → `freeglut.3.0.0.v140` + `glfw`, PlatformToolset v142→v143).
- **GLSL correctness fixes** — `8d0bd63` "fix vector from object to viewer" and `6092828`
  "normalize these vectors" fixed the half-angle vector in chapt16 `3lights.vs`/`sepspec.vs`/
  `specular.vs` (hardcoded `vec3(0,0,1)` → `normalize(-V.xyz)`).
- **Hygiene / revival** — clang-format sweep + dos2unix (`eb7a0b3`→`73f58ea`, `638345d`); Linux
  build fixes (libstdc++ linkage, Arch/DSO — `5f39bd0`); macOS/Xcode + Windows/VS2019→v143
  modernization.

**One line:** Bill imported Wright's 2007 code, then (2019–2025) got it compiling on modern
Linux/macOS/Windows, replaced the broken legacy GLUT UI in four demos with Dear ImGui (finally
vendoring imgui in `c74bbd6`), fixed the Windows include-ordering bug, corrected two specular
shaders, and imposed clang-format/dos2unix hygiene.

## Gotchas worth recording

- Not every chapter has a build wrapper on every platform — the platform-integration chapters
  (19 Windows / 20 Apple / 21 Linux / 22 ES) are inherently uneven and mostly non-portable.
- Linux Makefiles hardcode `-I/usr/local/include/GL` and `/usr/X11R6/lib` (2007 paths) — they
  work only because the link line recompiles everything from source each build.
