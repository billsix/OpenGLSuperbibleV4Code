# Replace the per-platform build wrappers with one cross-platform CMake build

**Status:** proposed — needs go-ahead (the maintainer asked for this task on 2026-11-22; no work started)
**Priority:** 5
**Difficulty:** 6
**Created:** 2026-11-22

## BLUF

Two stages. **Stage 1 is a full audit** of the source tree and of how it changed over the git
history; its deliverables are reference documents under `tasks/reference/`, not code changes.
**Stage 2 replaces the three hand-maintained build trees** (Linux Makefiles, Xcode projects,
Visual Studio projects) with one `CMakeLists.txt` tree that builds on Linux, macOS and Windows,
using the audit's findings. The demos keep the book's shape: callback-based GLUT-style programs.
Done means: the audit documents exist and are indexed from `CLAUDE.md`; one `cmake -B build &&
cmake --build build` builds every demo that can build on the platform; Linux is verified here in
a container; macOS and Windows are verified by the maintainer after the push, so those two get
the most conservative configuration.

## Maintainer's constraints (2026-11-22, second message)

> before we do it, we should do a full audit of the source code, and changes over time. for
> context, it was from a book, and I had manually updated some of the code and project files
> over time. I tried to put in some IMGUI controls to some, I don't remember if I succeeded or
> not. I want to keep as a general gist, the code as it was in the book as much as possible,
> but formatting doesn't have to stay the same (I do want consistent formatting btw), GUI
> controls don't have to stay the same, but the callback based approach does even though I
> prefer SDL/GLFW over glut. glad doesn't have to be the loader, anything else could work. But
> I will want the full repo audit, even over git commits, where the deliverables and findings
> are for reference documents, not necessarily code changes itself, but keeping in mind that our
> immediate goal is the build system update.

What that fixes, as rules for the work below:

- **Kept:** the book's program structure: `main` registers callbacks (`display`, `reshape`,
  `keyboard`, `special`, `timer`, mouse) and hands control to a loop. A backend may be GLFW or
  SDL, but the demos still read as callback programs (so a GLUT-shaped shim over GLFW or SDL is
  allowed, a rewrite into polling loops is not).
- **Free to change:** formatting (but one consistent style, enforced by a `.clang-format` and a
  check), GUI controls (the right-click GLUT menus and the ImGui retrofits may be replaced or
  completed), and the extension loader (GLee, glad, GLEW or anything else that works).
- **Audit first, and its output is documents.** Findings that suggest code changes become
  proposals in the documents or follow-on tasks; they do not change code during the audit.

## Maintainer quote (2026-11-22, first message)

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

## Stage 1: the audit (reference documents, no code changes)

Goal: know exactly what is in the tree, what the maintainer changed and when, and what state each
demo is in, before choosing a build layout. The existing `tasks/reference/` set (2026-08-02) is
the starting point and is checked against the code again, not trusted.

**Deliverables**, each a `tasks/reference/<slug>.md` file, each claim anchored to `file:line` or a
commit, and `CLAUDE.md` updated to index them:

1. **`source-audit.md`: a per-demo state table.** One row for each demo directory in
   `examples/src/chapt01` to `chapt22` (about 95 demos): what it teaches, which GLUT calls it
   uses, which extensions and shared files it needs, whether it includes `imgui`, whether it has
   a Linux Makefile, an Xcode project and a Visual Studio project, whether the three agree on
   file lists, and whether it **builds and runs on Linux today** (measured: build in a container,
   run a few frames under Xvfb with llvmpipe; record the first error for each failure).
   Include the dead and orphaned files (`shared/glfrustum.h` is already known) and files in the
   source tree that no project references.
2. **`imgui-retrofit-status.md`: did the ImGui work succeed?** For each of the four known
   retrofits (`chapt02/bounce`, `chapt05/ambient`, `chapt08/pyramid`, `chapt15/shaders`), and any
   others a search finds (`grep -rl imgui`, and the commits `d6defd8` "Updated demo with IMGUI
   controls. The glut ones were failing", `3b6f3b3` "added IMGUI controls to pyramid", `17d5297`
   "added imgui files to the project. Inputs are not working though"):
   does it build on Linux, does it run, do the controls respond (`17d5297` says inputs did not
   work at first; test whether mouse and keyboard input reach ImGui through
   `imgui_impl_glut`), and which GLUT callbacks does it replace or wrap. Include a screenshot
   or a pixel check from the Xvfb run if feasible. End with a recommendation for the build
   stage: keep, replace with a backend-independent overlay, or drop.
3. **`history-audit.md`: the change history, commit by commit.** Walk all 42 commits (`git log
   --stat --follow` per area). For each commit: date, what it changed in the sources, in each
   platform's project files, in `contrib/`, and whether it changed behavior or only build or
   format. Group into eras (the verbatim upstream import `e802274`; the VS2019/NuGet pass
   `8a04619`; the Makefile and ImGui commits; the Xcode regeneration series; the 2025 Windows
   package swap `b8e9cea`; the ImGui vendoring `c74bbd6`). Record every **source** change
   against the upstream import as a diff summary: the delta is the maintainer's work, and the
   audit separates behavior changes (the two chapt16 specular fixes, the `ortho` fix `e43b649`,
   the bounce changes) from formatting churn (clang-format and dos2unix: `eb7a0b3`, `73f58ea`,
   `638345d`, `02e83be`). Produce one table of "what a demo looked like in the book" against
   "what it does now" for each behavior change, so Stage 2 can keep the book's behavior.
4. **`windows-build-history.md`: what was tried and why it failed.** From the Visual Studio
   commits (`8a04619`, `498c5ca`, `bb01dd2`, `b8e9cea`): the toolsets, NuGet packages and versions
   used in each project file, how project files were edited (by hand or by bulk script), which
   packages are dead, and what the maintainer reports about the current failure (ask for the
   first error message from a modern Visual Studio, and record it; this is the one fact the
   audit cannot get from the repository).
5. **`dependency-and-portability-audit.md`: what the code needs from the platform.** The GLUT
   calls with counts and which are freeglut-only (a first table exists in this task's Context;
   the audit rechecks it with `rg`), the OpenGL features and extensions used (fixed function
   against GLSL, which extensions GLee must provide, which GL version the demos need), the
   platform headers and `#ifdef` branches (`__APPLE__`, `WIN32`, X11), the use of `GLee`
   across the shared library, deprecated or non-portable C++ (VLAs, `windows.h` order,
   `<glut.h>` against `<GL/freeglut.h>`, `gl\gl.h` backslashes, `long` sizes), and
   **a candidate list of loaders** (GLee, glad, GLEW, libepoxy, `glbinding`, GLFW's own
   function loading) with what each would need changed in `gltools.h`.
6. **`formatting-audit.md`: current formatting state.** Which files are clang-format clean under
   which style, which are not, line endings and tabs, and a proposed `.clang-format` plus how to
   enforce it (a `make format-check` target). Formatting may change; the audit decides one style.
7. **A short `audit-summary.md`**: the findings that change Stage 2's plan, and a revised
   Stage 2 plan if the audit contradicts anything below. The audit is not finished until the
   maintainer has read this and answered its numbered questions.

**Method.** The tree is large (2066 tracked files, mostly Xcode, Visual Studio, textures
and `contrib/imgui`), so fan out readers by area (chapters 1 to 6, 7 to 12, 13 to 18, 19 to 22,
`shared/`, the three project trees, `contrib/`, and the git history) and have them return
structured, `file:line`-anchored reports; synthesize the documents from those. Verify by running
anything a document claims about "builds" or "runs": that is a measurement, not a reading.

**Container first (maintainer's answer, 2026-11-22).** The repo has no `Dockerfile`, `Makefile` or
`entrypoint/` yet. Before any measurement, add the maintainer's container-per-project template
(Fedora, Podman, `make image`, `make shell`, `make shell-exec`, `make format`, with `-it` only on
the targets that need a terminal) and run every Linux build and Xvfb run through it, nested, so no
build output lands in the tree. The image carries the build dependencies (`freeglut-devel`,
`mesa-libGL-devel`, `mesa-libGLU-devel`, `OpenEXR-devel`, X11 headers, `xorg-x11-server-Xvfb`,
`mesa-dri-drivers`, `cmake`, `ninja-build`, `clang-tools-extra`). This is a prerequisite of the audit
and the first commit of the task's work. The template is `ai-coding-conventions.personal.template.md`
("Makefile contract", "Dockerfile contract", "entrypoint contract", "Quick conformance check");
follow it rather than inventing a layout. The untracked binary at
`examples/projects/linux/chapt18/pixbufobj/pixbufobj` is the maintainer's; leave it alone.

## Stage 2: the CMake build (starting after the audit summary is answered)

1. **Baseline from the audit.** `source-audit.md` records which of the ~95 demos build and run on
   Linux today. After CMake, the same set must still build and run.
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
   Windows or macOS, replace it behind the same header name with a loader chosen from the audit's candidate list (`glad` generated for GL 2.1 compatibility is the default guess; GLEW or libepoxy are as good)
   (GL 2.1 compatibility profile plus the extensions the demos use), so no demo source changes.
   A `glad` generated in the container and committed under `examples/src/shared/` is acceptable;
   record the generator version and command.
6. **The GLUT shim, only if freeglut is not workable.** The shim may sit on GLFW or SDL (the maintainer prefers either to GLUT; decide by the audit's portability findings), and it must keep the callback model. A header `glut_shim.h` plus
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

None blocking. Answered 2026-11-22: the Linux measurements run in the project's container (the
normal Makefile/Dockerfile contract, added as the task's first step); the first error from a modern
Visual Studio build is requested when the audit reaches `windows-build-history.md`, not before.

Not blocking either: The GLUT-vs-GLFW choice and GLee-vs-glad choice are decided by what fails in
steps 4 and 5, not by a preference now.

## History

- 2026-11-22: created at the maintainer's request.
- 2026-11-22: the maintainer answered two questions (use the normal Makefile/Dockerfile contract for
  the Linux runs; give the Visual Studio error when the audit gets there) and committed the task.
- 2026-11-22: the maintainer added a second message: do a full audit of the source and of the git
  history first, with reference documents as the deliverables; keep the callback-based book
  structure, allow consistent reformatting, free GUI controls and any extension loader. The task
  was split into Stage 1 (audit) and Stage 2 (CMake).
