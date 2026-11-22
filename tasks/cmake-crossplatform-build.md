# Replace the per-platform build wrappers with one cross-platform CMake build

**Status:** proposed — needs go-ahead (the maintainer asked for this task on 2026-11-22; no work started)
**Priority:** 5
**Difficulty:** 6
**Created:** 2026-11-22

## BLUF

Keep the demo C/C++ (`examples/src/`) as close to the original as possible, and replace the three
hand-maintained build trees (Linux Makefiles, Xcode projects, Visual Studio projects) with a single
`CMakeLists.txt` tree that builds on Linux, macOS and Windows. Done means: one `cmake -B build &&
cmake --build build` builds every demo that can build on the platform; Linux is verified here in a
container; macOS and Windows are verified by the maintainer after the push, so those two get
the most careful, most conservative configuration. If a dependency is too old (GLee, the
freeglut NuGet package), the fallback is GLFW with a GLUT-shaped shim, so the demo sources keep
their `glut*` calls.

## Maintainer quote (2026-11-22)

> keep the C/C++ code as much the same as possible, but update the build system to use cmake in
> a crossplatform way. I will be able to verify on macos linux and windows, but I'll only be able
> to test the linux code before we push. I have tried in the past to make the build system work
> on modern visual studio, but I have failed. you can look through the history of the project to
> see how I update the project files. If it turns out that the glad system or whatever is too
> old, or if stuff is unsupported, we can update the C++ code to use glfw, with a GLUT like shim
> backed by glfw. A lot of this code was ported to python in modelviewprojection, so you can
> always look there to see if anything would help. You can also restructure the directory
> structure how you see fit.

## Context

Read first: `tasks/reference/build-and-imgui-fork.md` (how the three trees build today and the
full fork delta), `tasks/reference/gltools-framework.md` (the shared library every demo links),
`tasks/reference/chapter-demo-inventory.md` (every demo, one line each).

**Note on `CLAUDE.md`:** it currently says "don't refactor or modernize the C++". This task
modernizes the *build system* only, at the maintainer's request; the C++ stays as it is unless
a step below says otherwise. When the task completes, rewrite that bullet to say so.

### Current state (verified 2026-11-22)

- **Sources:** `examples/src/chapt01` to `chapt22` plus `examples/src/shared/` (GLTools 4th
  edition: `math3d.cpp`, `gltools.cpp`, `GLee.c`, `VBOMesh.cpp`, `TriangleMesh.cpp`, headers).
  One copy of the sources, shared by all platforms.
- **Build wrappers, no source in them:**
  - `examples/projects/linux/chaptNN/<demo>/Makefile` (about 95 demos) plus a `build` script
    that `cd`s into each demo and runs `make`. The recipe is one `gcc … -lglut -lGL -lGLU`
    line that recompiles the demo and `shared/{math3d,gltools}.cpp` and `GLee.c` every time.
    Include paths are 2007-era (`/usr/local/include/GL`).
  - `examples/projects/apple/chaptNN/<demo>/<demo>.xcodeproj` (91 `.pbxproj`, chapters 1 to 18
    and 20), plus `nib`, `plist` and `pch` files.
  - `examples/projects/microsoft/chaptNN/<demo>/` (94 `.vcxproj`, `.sln`, `packages.config`,
    chapters 1 to 19). These are the ones that failed on modern Visual Studio.
- **GLUT:** 94 demo sources call GLUT. The calls in use, by count: `glutPostRedisplay` 135,
  menus (`glutCreateMenu`, `glutAddMenuEntry`, `glutAttachMenu`, `glutChangeToMenuEntry`,
  `glutAddSubMenu`, `glutSetMenu`, about 290 calls together), `glutSwapBuffers`, `glutMainLoop`,
  `glutInit*`, `glutDisplayFunc`, `glutReshapeFunc`, `glutTimerFunc` 52, `glutSpecialFunc` 56,
  `glutKeyboardFunc` 20, mouse and motion callbacks (about 20), and the solid shapes
  (`glutSolidSphere` 40, `glutSolidCube`, `Cone`, `Torus`, `Teapot`, polyhedra). The picks are
  all in `freeglut`; `glutMouseWheelFunc`, `glutLeaveMainLoop` and `glutSetOption` are
  freeglut-only extensions.
- **Extension loader:** `GLee.c`/`GLee.h` (about 17k lines, 2007). Every demo compiles it.
  `gltools.h` includes `windows.h` first on Windows (`b8e9cea`), `<Carbon/Carbon.h>` on Apple.
- **Dear ImGui** is vendored in `contrib/imgui/` and used by four demos (`chapt02/bounce`,
  `chapt05/ambient`, `chapt08/pyramid`, `chapt15/shaders`) through `imgui_impl_glut` plus
  `imgui_impl_opengl2` (or `opengl3` for `shaders`).
- **Platform-specific chapters that cannot be portable:** `chapt19` (Win32/MFC: GLRect, GLView,
  RThread, SphereWorld32, Text2D, Text3D, fscreen), `chapt20` (Carbon/Cocoa), `chapt21`
  (`GLXBasics`, raw GLX; `fonts`), `chapt22` (OpenGL ES example, readme only). Only `chapt21/fonts`
  has a plausible generic build.
- **Extra dependencies:** OpenEXR only for `chapt18/texfloat`.

### How the maintainer updated the project files (from `git log`)

- **`8a04619` "Visual Studio 2019/Nuget updates":** converted the original VS2003/2005 projects
  to VS2019 with NuGet. Project files were hand-edited and bulk-edited.
- **`498c5ca`** added ImGui to `chapt02/bounce` (VS2019 Community + Linux Makefile).
- **`b8e9cea` (2025-05-11):** per project, in the NuGet console: uninstall the dead
  `nupengl.core` and `nupengl.core.redist`, install `freeglut.3.0.0.v140` 1.0.2, `glfw`,
  `glew`, `freeglut`; PlatformToolset v142 to v143; `windows.h` first in `gltools.h`.
  Maintainer says it still did not give a build on modern Visual Studio.
- **macOS:** `698760e`, `7b874d4`, `3d9d61c`, `a9d941f`, `2d05a12`, `c5dc7ca` series:
  regenerated the Xcode projects through chapter 5 and then all of them, adding `libstdc++`
  to every project (`523eaa1`).
- **Linux:** `4536bd7`, `fixed build of pyramid on linux`, `5f39bd0` (`__cxa_guard_acquire` /
  DSO link failure fixed by adding `-lstdc++`), `a9660cb`.

Whoever implements this should read these commits (`git show <sha> --stat`) before choosing
dependency versions, because they record which Windows packages were already tried.

### The Python port as a source of answers

`/mnt/sda1/modelviewprojection/modelviewprojection/ports/openglsuperbiblev4/` (README there)
translates every demo to Python with GLFW and `imgui_bundle`. Its rules are the model for the
shim: `glutCreateMenu` becomes ImGui; `glutSolid*` become inline draw calls with no GLUT
dependency; the GLUT loop becomes a GLFW polling loop. Its `_primitives.py` has working
`glutSolidSphere`-style geometry that can be translated back to C++ for the shim; `_common.py`
has the shared window and timer plumbing. In committed docs refer to it as
`github.com/billsix/modelviewprojection` (the mount name `modelviewprojection` matches the repo).

## Proposed approach

1. **Inventory what builds today on Linux.** Run the existing `build` script in a container and
   record which of the ~95 demos compile and run headless-ish (Xvfb + llvmpipe). That is the
   baseline: after CMake, the same set must still build. Record it in this task.
2. **Layout.** One top-level `CMakeLists.txt`, a `cmake/` directory for find-modules, and
   `examples/CMakeLists.txt` that does `add_subdirectory` per chapter, each with an
   `add_demo(name SOURCES … [IMGUI] [OPENEXR])` helper. A static library target `gltools`
   built once from `shared/` replaces the recompile-everything link line. Demo data files
   (`.tga`, `.exr`, `.vs`, `.fs`, `.BMP`) are copied next to the binary at build time, since the
   demos open them by relative name. The three per-platform trees under `examples/projects/`
   are deleted at the end, after the CMake build is verified on all three platforms (they stay
   in history). Demo directories under `examples/src/` stay put, so the C++ diff is nearly empty.
3. **Dependencies through CMake, no system paths.** `find_package(OpenGL)`; GLUT through
   `find_package(GLUT)` on Linux and macOS (freeglut / the system framework); GLFW through
   `FetchContent` pinned to a release tag if the shim route is needed. Decide GLUT-vs-shim in
   step 4, not up front.
4. **Windows is where the risk is.** The old project files depend on NuGet packages that no
   longer match the toolset. Try, in order, on a Linux cross-check where possible and by the
   maintainer on Windows: (a) freeglut through `FetchContent` or vcpkg manifest mode, built as a
   static library with `FREEGLUT_BUILD_SHARED_LIBS=OFF`; (b) if (a) fails, the GLFW-backed
   GLUT shim (below). Keep each attempt a CMake option so the maintainer can flip it without
   editing files. Do not guess at Visual Studio generator behavior: write the smallest possible
   first target (`chapt01/block`), have the maintainer build it, then widen.
5. **The extension loader.** `GLee` predates core profiles and may not load on current drivers
   or compile on current compilers. Check on Linux first (it builds today). If GLee fails on
   Windows or macOS, replace it behind the same header name with a generated `glad` loader
   (GL 2.1 compatibility profile plus the extensions the demos use), so no demo source changes.
   A `glad` generated in the container and committed under `examples/src/shared/` is acceptable;
   record the generator version and command.
6. **The GLUT shim, only if freeglut is not workable.** A header `glut_shim.h` plus
   `glut_shim.cpp` exposing the `glut*` functions listed under Context on top of GLFW, with
   menus rendered by ImGui (the Python port does exactly this) and `glutSolid*` ported from
   the Python `_primitives.py`. Put it behind `-DUSE_GLFW_GLUT_SHIM=ON`, and include it through the
   same `#include <GL/freeglut.h>` lines the sources already use, by making the shim's include
   directory shadow them, so demo sources do not change. Menu calls are the largest part (about
   290 call sites): the right-click menu becomes an ImGui popup.
7. **ImGui demos.** `imgui_impl_glut.cpp` works only with real GLUT. Under the shim it is
   replaced by `imgui_impl_glfw.cpp` (vendor it into `contrib/imgui/`; it is part of Dear ImGui
   upstream). Keep this to the four demos that already use ImGui.
8. **Platform-only chapters.** `chapt19` (Win32/MFC) and `chapt20` (Carbon/Cocoa) are left out of
   the CMake build with a comment explaining why, unless a chapter turns out to build with a
   few lines (`chapt19/SphereWorld32` and `fscreen` use WGL directly and will not move to GLFW
   without changing source). `chapt21/GLXBasics` builds only on Linux through
   `if(UNIX AND NOT APPLE)`. `chapt22` is out.
9. **CI for Linux only.** A `Dockerfile`/`Makefile` target that configures, builds, and runs
   each demo for a few frames under Xvfb to catch crashes at startup. macOS and Windows gates
   are the maintainer's manual check, listed below.
10. **Docs.** Update `CLAUDE.md` (the "don't modernize" bullet and the build-system pointer),
    `readme.txt` or a new `README.md` with the build commands, and rewrite
    `tasks/reference/build-and-imgui-fork.md` to describe the CMake layout. Add the history of
    this change to that doc's fork-delta section.

## What the maintainer verifies after the push

- **macOS:** `cmake -B build && cmake --build build`; run `chapt01/block`, `chapt02/bounce`,
  `chapt15/shaders` (the ImGui ones), `chapt18/hdrbloom`.
- **Windows (Visual Studio 2022):** same commands with the default generator; run
  `chapt01/block` first. Report the first error text, not a summary; steps 4 and 5 are
  written so each failure has a next option.

## Decisions made now, with rationale (revisit if wrong)

- **Source tree stays; build trees go.** Rationale: the maintainer asked for the C/C++ to stay
  the same and allowed restructuring directories, and the three project trees duplicate each
  other (about 280 files of generated project XML and plists) while the sources are already
  shared.
- **One CMake build, not three native project generators.** Rationale: `.vcxproj` and
  `.pbxproj` can be generated from CMake, which removes the maintenance the history shows (every
  toolset bump touched ~90 files).
- **Shim is the fallback, not the first move.** Rationale: the demos already work with real GLUT
  on Linux, so changing 94 files' backend before knowing Windows needs it is the larger risk.

## Open questions

None blocking. The GLUT-vs-GLFW choice and GLee-vs-glad choice are decided by what fails in
steps 4 and 5, not by a preference now.

## History

- 2026-11-22: created at the maintainer's request.
