# Replace the per-platform build wrappers with one CMake build (Linux done)

**Done 2026-11-23** for Linux. Requested by William Emerison Six <billsix@gmail.com> on 2026-11-22; the macOS and
Windows verification and the deletion of the old project trees moved to `tasks/cmake-verify-macos-windows.md`.

## What was done

**Stage 1, the audit.** Seven reference documents in `tasks/reference/` (start with `audit-summary.md`), a scoped review
record (`tasks/review/2026/11/23/repo-review.md`), and the container (`Dockerfile`, `Makefile`, `entrypoint/`). Findings
that shaped stage 2: 81 of 88 Makefiles built and 75 programs stayed alive under Xvfb; the real source delta against the
book is 15 files; the four ImGui demos failed only on a wrong include path; 64 of 94 Visual Studio projects were never
converted from NuGet's `nupengl.core`; the demos are an OpenGL 2.1 compatibility profile; the code is Google style.

**Maintainer's answers to the audit (William Emerison Six <billsix@gmail.com>, 2026-11-23).** `chapt08/toon` keeps its
current values (the 2020 change was deliberate); the `glutSetWindowTitle` crash is Xvfb-only (the demos run on a real
Linux desktop); the two one-line portability edits were allowed; GLee stays the default loader behind `SB4_LOADER`; one
reformatting commit with a committed `.clang-format` (spimulator's config: `BasedOnStyle: google`, `SortIncludes: Never`)
came before the CMake work.

**Stage 2, the CMake build (Linux).**
- `.clang-format` plus one reformat commit (115 files, 6 of them with more than whitespace changes; idempotent).
- Root `CMakeLists.txt` and `examples/CMakeLists.txt`: a `gltools` static library (`math3d`, `gltools`, GLee), an `imgui`
  static library over `contrib/imgui`, and `add_demo(<chapter> <demo> SOURCES ... [SHARED ...] [LIBS ...] [IMGUI]
  [OPENEXR])`. Targets are named `<chapter>_<demo>` (names repeat across chapters); binaries go to
  `build/cmake/bin/<chapter>/<demo>/` with the demo's data files and `shaders/` directory copied beside them.
- `examples/cmake/chaptNN.cmake` are generated from the Makefiles' dry-run link lines by `tools/gen_chapter_cmake.py`
  (idempotent). All 88 demos that had a Linux Makefile are targets; `texfloat` only when `OpenEXR::OpenEXR` is found.
- Source edits: `windows.h` guarded by `_WIN32` in `chapt04/transformgl`, `#include <GL/glx.h>` in `chapt21/fonts`.
- Options: `SB4_LOADER` (only `GLEE`), `SB4_FETCH_FREEGLUT` (default ON on Windows: freeglut 3.8.0 built static; tested on
  Linux with it ON, all 88 build). macOS uses the system GLUT with `GL_SILENCE_DEPRECATION`.
- `README.md` with the commands for the three platforms; `tools/run_cmake_demos_xvfb.sh` runs every demo headless.

## Results (Linux, Fedora 45 container, GCC 16, freeglut 3.8, Mesa llvmpipe)

88 of 88 targets build. With an `openbox` window manager running, 85 stay alive for 5 seconds under Xvfb. The three
that do not: `motionblur` (Xvfb has no accumulation-buffer GLX configuration), `imaging` (exits 0), and `chapt21/fonts`
(below); all three were fixed afterwards, giving 88 of 88 alive (`tasks/archive/2026/11/23/headless-demo-gaps.md`). The first run had no window manager (Fedora 45 has no `twm` package, and `--skip-unavailable` hid that), which
made four `glutSetWindowTitle` demos die with `BadAtom` (81 alive); the Makefile baseline had the same flaw (75 alive of
81 built). The container now installs `openbox`.

## Findings and decisions to keep

- **GLVND:** CMake's `OpenGL::GL` picks `libOpenGL` by default, which lacks the ARB entry points `gltools.cpp` calls;
  `OpenGL_GL_PREFERENCE LEGACY` selects `libGL`, as the Makefiles' `-lGL` did.
- **Header form:** `gltools.h` includes the bare `<glut.h>`, so the `GL/` header directory goes on the include path.
- **OpenGL3 ImGui backend:** needs `IMGUI_IMPL_OPENGL_LOADER_CUSTOM`, because the vendored backend includes `GLee.h` itself.
- **OpenEXR:** `texfloat` compiles unchanged against OpenEXR 3.x.
- **`chapt21/fonts` crashes** (SIGSEGV in `SetupRC`): `XLoadQueryFont` for `-*-courier-bold-r-normal--48-*` returns NULL
  and the code dereferences it. Modern X servers ship no scalable core font, and even with the 75 and 100 dpi font
  packages there is no 48-pixel Courier. Not a build problem; the source was left as the book has it.
- **`OpenEXR-devel`** stays in `entrypoint/01-install-base.sh` (maintainer's decision, 2026-11-23), so all 88 demos build in
  the container; on a host without OpenEXR, `texfloat` drops out of the build instead of failing it.
- **The one-shot audit scripts and snapshot data** were removed at archive; they are in git history at the commit before
  the archive commit, under `tasks/adhoc/cmake-crossplatform-build/`. The reusable pair was promoted to `tools/`.

## History

- 2026-11-22: created; split into a stage 1 audit and a stage 2 CMake build.
- 2026-11-23: audit done and committed; answers given; reformat committed; CMake build for all 88 Linux demos; archived.
