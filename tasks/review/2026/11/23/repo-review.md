# Repository review, 2026-11-23 (stage 1 audit of `tasks/cmake-crossplatform-build.md`)

**Frozen record. Do not edit; act on it through tasks.** Written 2026-11-23 for William Emerison Six
<billsix@gmail.com>. This is a **scoped review**: it covers the build, the source delta against the book, and the
git history, because those decide the CMake plan. It is not a full ten-dimension deep review. The method was
measurement (build every Makefile, run every binary under Xvfb, normalize formatting and diff against the upstream
import) rather than reading; the detail lives in the seven documents under `tasks/reference/` (start with
`tasks/reference/audit-summary.md`), and the snapshot data in `tasks/adhoc/cmake-crossplatform-build/data/` (removed
when the task archives; the reference documents carry the results).

## Coverage by dimension

| # | Dimension | Covered | What was done |
|---|---|---|---|
| 1 | Docs to docs | partly | `tasks/reference/build-and-imgui-fork.md` against the audit; `CLAUDE.md` index updated |
| 2 | Docs to code | partly | claims in `build-and-imgui-fork.md` (builds from a fresh clone, 42 commits) checked by building and counting |
| 3 | Product content | N/A | the product is the book's example code; behavior was probed only by running each demo 5 s |
| 4 | Code quality | not covered | no C checkers (`c_dispatch_check.py`, `c_designated_init_check.py`) were run; source is third-party and frozen |
| 5 | Generators and tools | N/A | none in the repo |
| 6 | Tests | N/A | none in the repo |
| 7 | Proofs | N/A | none |
| 8 | Build, container, CI | covered | all 88 Linux Makefiles built and run; 94 Visual Studio and 91 Xcode projects inventoried by reading (not built: no Windows or macOS machine) |
| 9 | Open-task backlog | covered | one open task, the CMake task |
| 10 | Archive hygiene | not covered | the 2026-08-02 study task was not re-read against the tree |

A clean result in a "not covered" row proves nothing.

## Findings, ranked by what changes the next action

### HIGH

1. **A reference doc says a fresh clone builds; four demos do not.** `tasks/reference/build-and-imgui-fork.md` credits the
   2025 vendoring of ImGui with a working fresh-clone build. Every Makefile and Visual Studio project of the four ImGui
   demos points at `contrib/imgui` six directories up, outside the repo; the tree is four up. Evidence: the build logs of the four ImGui
   demos (including `bounce`, `pyramid` and `shaders`) show the missing include (`source-audit.md`,
   `imgui-retrofit-status.md`). VERIFIED (built).
2. **`chapt08/toon` no longer shows the book's cel bands.** A 2020 commit ("messed up toon on purpose") changed the
   table values 128 and 192 to 127 and the filters to linear (`history-audit.md`). VERIFIED (diff); the visual result was
   not compared against the book's figures.
3. **The Windows tree is half converted.** The 2025 NuGet change reached 30 of 94 Visual Studio projects (chapters 1 to 5);
   64 still use `nupengl.core`, 62 of them on the v142 toolset (`windows-build-history.md`). VERIFIED (read the project
   files). Not built: the first Visual Studio error message is still owed by the maintainer.

### MEDIUM

4. **Seven of 88 Linux builds fail**, and none is a demo defect: four ImGui include paths (finding 1), `shaders` also
   lacks an OpenGL3 loader define, `transformgl` has an unconditional `#include <windows.h>`, `fonts` lacks
   `#include <GL/glx.h>`, `texfloat` needs OpenEXR 1.x. VERIFIED (build logs).
5. **Six of the 81 demos that build do not stay alive under Xvfb**: four die in `glutSetWindowTitle` (`BadAtom`, a
   freeglut 3.8 failure reproduced by a six-line program), `motionblur` needs an accumulation buffer, `imaging` exits 0.
   The maintainer reports the Makefile build and run work on a real Linux desktop, so the `BadAtom` crash is specific to
   Xvfb. VERIFIED under Xvfb; the desktop result is the maintainer's.
6. **50 Visual Studio and Xcode projects name source paths with the wrong capitalization.** Harmless on Windows and
   macOS, fatal on Linux. VERIFIED (absolute-path check, all 50 are case-only).
7. **No `.clang-format` is committed**, but the code is Google style (the nearest of eight styles by a factor of two)
   (`formatting-audit.md`). VERIFIED.
8. **The history is 45 commits; the docs say 42.** Only 15 source files differ from the book after formatting is
   normalized (`history-audit.md`). VERIFIED.

### LOW

9. `examples/projects/linux/chapt10/bezier` has no Makefile. VERIFIED.
10. The old Linux Makefiles write per-demo binaries into the source tree; `.gitignore` now ignores them.
11. macOS (91 Xcode projects) was not built or run. NOT COVERED.

## Actions taken during the review

Added a container (`Dockerfile`, `Makefile`, `entrypoint/`, `.dockerignore`, `.gitignore`), the measuring scripts and
snapshot data, seven reference documents, and edits to `CLAUDE.md`, `tasks/reference/build-and-imgui-fork.md` and the
task document. No C or C++ source was changed.

## Follow-up

All findings are inputs to stage 2 of `tasks/cmake-crossplatform-build.md`, which carries the maintainer's answers of
2026-11-23. Dimensions 4 and 10 remain open if a full deep review is wanted.
