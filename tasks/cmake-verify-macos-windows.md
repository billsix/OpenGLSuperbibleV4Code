# Verify the CMake build on macOS and Windows, then delete the old project trees

**Status:** proposed — needs the maintainer to run the commands on a Mac and a Windows machine (filed 2026-11-23)
**Priority:** 5
**Difficulty:** 4 (the maintainer's runs; fixes depend on what they print)
**Created:** 2026-11-23
**Depends on:** merge of branch `cmake-stage2` (the CMake build, archived task `tasks/archive/2026/11/23/cmake-crossplatform-build.md`)

## BLUF

The CMake build was built and run only on Linux. Done means: `cmake -B build/cmake && cmake --build build/cmake` builds and
`chapt01/block` runs on macOS and on Windows (Visual Studio 2022), then the other chapters are widened, and the
per-platform trees under `examples/projects/` (Makefiles, Xcode, Visual Studio: about 280 files) are deleted.

## Context

- `README.md` has the commands. On Windows, freeglut 3.8.0 is downloaded and built static by CMake
  (`SB4_FETCH_FREEGLUT`, default ON there); this configure path was exercised on Linux but not MSVC. On macOS the system
  GLUT framework is used; `gltools.h` includes `<Carbon/Carbon.h>` on Apple, which a current SDK may reject.
- `tasks/reference/windows-build-history.md` records how the old Visual Studio projects failed (NuGet `nupengl.core`) and
  `tasks/reference/audit-summary.md` the plan and findings. The first error message is wanted verbatim, not summarized.
- Fallbacks, in the order the original plan gave: `SB4_LOADER` is GLee only (a GLEW or glad header would map the `GLEE_*`
  macros); a GLFW-backed GLUT shim with ImGui menus is the last resort (about 290 menu call sites; `github.com/billsix/
  modelviewprojection`'s `ports/openglsuperbiblev4/` has the Python equivalent).
- Chapters 19 (Win32/MFC), 20 (Carbon/Cocoa) and 22 are not in the CMake build.

## Plan

1. Maintainer: macOS `cmake -B build/cmake && cmake --build build/cmake`, run `chapt01/block`, `chapt02/bounce`,
   `chapt15/shaders`, `chapt18/hdrbloom`. Report the first error.
2. Maintainer: the same on Windows with Visual Studio 2022, `chapt01/block` first (`--config Release`).
3. Fix what fails, one platform at a time, widening after `block` works.
4. When both platforms build, delete `examples/projects/` and the `.gitignore` entries for the per-demo Linux binaries,
   and update `CLAUDE.md` and `tasks/reference/build-and-imgui-fork.md` (which still describes the old layout).

## Open questions

None.

## History

- 2026-11-23: filed when the Linux half of the CMake task was archived, at the maintainer's request.
