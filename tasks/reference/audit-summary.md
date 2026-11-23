# Audit summary: what changes the CMake plan

**Reference doc**, 2026-11-23. The end of stage 1 of `tasks/archive/2026/11/23/cmake-crossplatform-build.md`. The six audit documents it
summarizes are `source-audit.md`, `imgui-retrofit-status.md`, `history-audit.md`, `windows-build-history.md`,
`dependency-and-portability-audit.md` and `formatting-audit.md`. Stage 2 ran afterwards (archived task `tasks/archive/2026/11/23/cmake-crossplatform-build.md`). The scripts named in
these documents (`tasks/adhoc/cmake-crossplatform-build/`) were removed at archive and are in git history.

## What the audit found

1. **The Linux baseline is good.** 81 of the 88 per-demo Makefiles build with GCC 16 and freeglut 3.8 in a Fedora 45
   container, and 75 of the 88 programs stay alive for 5 seconds under Xvfb with Mesa software rendering. The CMake
   build must reproduce exactly that set, then add the seven failures' fixes where they are build-system problems
   (`source-audit.md`).
2. **The source is the book's, almost untouched.** After formatting is normalized away, **15 files differ** from the
   upstream import (`history-audit.md`): the four ImGui retrofits (~400 changed lines), `atom` (`glOrtho` fix), `toon`
   (the book's cel bands changed: table values 128 and 192 became 127 and the filters became linear, "on purpose"),
   three chapter 16 shaders (the specular half-vector fix), and `gltools.h`/`gltools.cpp`/`transformgl.cpp` portability
   edits. Nothing else.
3. **The failures are not about the demos.** Of the seven build failures: four are one wrong include path to ImGui (six
   directories up instead of four), one is the OpenGL3 ImGui backend lacking a loader define, one is an unconditional
   `#include <windows.h>` in `transformgl`, one a missing `#include <GL/glx.h>` in `fonts` (GCC 14 rejects implicit
   declarations), one is OpenEXR 1.x (`texfloat`).
4. **ImGui works** (clicks reach it in `bounce` and `pyramid`), through `imgui_impl_glut` with callbacks installed by
   hand, so it fits the callback model the maintainer wants kept (`imgui-retrofit-status.md`).
5. **The Windows tree is half converted.** The 2025 NuGet change reached 30 of 94 projects (chapters 1 to 5); 64 projects
   still use the `nupengl.core` package (62 on the VS2019 toolset). The audit has no Windows machine: the maintainer's
   first error message is still needed (`windows-build-history.md`).
6. **The GLUT surface is small and classic:** about 35 functions in 87 callback programs, plus ~290 menu call sites in
   29 demos (the real cost of any non-GLUT backend), and three freeglut-only calls (`dependency-and-portability-
   audit.md`).
7. **`glutSetWindowTitle` needs a window manager:** under Xvfb with none it dies with `BadAtom` (10 demos call it; 4
   died); with `openbox` running they stay alive. The first run wrongly believed a window manager was running (`twm` is
   not in Fedora 45, and `--skip-unavailable` hid it); the container now installs `openbox`. Not a freeglut defect.
8. **The demos are fixed-function plus GLSL 1.x: an OpenGL 2.1 compatibility profile**, so the loader must load a
   compatibility profile and no demo can move to core.
9. **Case:** 50 Visual Studio and Xcode projects reference source paths with the wrong capitalization (fine on Windows
   and macOS, fatal on Linux); CMake must use the on-disk spelling.
10. **Formatting:** no `.clang-format` is committed, but the code is Google style (the closest of eight styles by a
    factor of two), so one config and one reformatting commit make it consistent (`formatting-audit.md`).
11. **Corrections** to the 2026-08-02 reference set: `build-and-imgui-fork.md` said the 2025 vendoring commit made a fresh
    clone build and counted 42 commits (it is 45; the vendoring did not fix the paths).

## The container that the audit added

`Dockerfile`, `Makefile` (`image`, `shell`, `shell-exec`, `format`, `image-export`/`image-import`, `help`),
`entrypoint/` (`01-install-base.sh`, `02-install-graphics.sh`, `shell.sh`, `format.sh`), `.dockerignore`, `.gitignore`
(which also ignores the per-demo binaries the old Makefiles write into the tree). The source is bind-mounted; the
measurements wrote to the ignored `build/`. Reproduce: `make shell-exec CMD='bash tasks/adhoc/cmake-crossplatform-
build/build_linux_demos.sh && bash tasks/adhoc/cmake-crossplatform-build/run_demos_xvfb.sh'`.

## Revised stage 2 plan

The plan in the task stands; these are the changes the audit forces:

- **Step 1 (baseline)** is done: `data/linux-build.tsv` and `data/linux-run.tsv` are the regression targets.
- **Loader (step 5):** keep GLee as the default (zero source change, proved on Linux) behind a CMake cache option
  `SB4_LOADER` so a GLEW- or glad-backed header of the same name can be tried on macOS or Windows without editing
  files; the demos' `GLEE_*` macros map one to one onto GLEW's `GLEW_*` and glad's `GLAD_GL_*`.
- **Windows (step 4):** because NuGet is the part that fails, the default is freeglut built from source by CMake
  (`FetchContent`, static), which also removes 94 per-project `packages\` restores; the GLFW shim is the second option.
  Only if `chapt01/block` builds there do the other demos matter.
- **GLUT shim (step 6):** needed only if freeglut cannot be had on a platform; the audit shows the exact surface
  (35 functions, menus as the bulk). Decide after the Windows and macOS first-build results.
- **ImGui (step 7):** one interface library with the right include path; give `shaders` a loader define for the OpenGL3
  backend; keep `imgui_impl_glut` unless the shim lands.
- **New step: data files.** One CMake rule per demo copies its textures and shaders next to the binary (the demos open
  them by relative name).
- **New step: the two portability edits** (`transformgl`'s `windows.h` guard and `fonts`' `glx.h` include) if the
  maintainer allows two one-line source changes (question 3).
- **Formatting:** `.clang-format` (Google) plus one reformatting commit before the CMake commits, so the later diffs are
  only build files.
- **Out of scope as before:** `chapt19`, `chapt20`, `chapt22`; `chapt21` Linux only.

## Questions for the maintainer

1. For `chapt08/toon`: keep the demo as it is now (table `127, 127` and linear filters, your 2020 "messed up toon on
   purpose" commit), or restore the book's values (`128`, `192`, nearest filtering) during stage 2? The audit
   recommends keeping it unless you want it restored, since you made the change deliberately.
2. Does `chapt11/sphereworld` (or any demo that calls `glutSetWindowTitle`) run on your real Linux desktop? The audit
   reproduced a freeglut crash only under Xvfb; a yes means the shim need not implement the title call differently.
3. May stage 2 make two one-line source edits that only matter for portability, `#ifdef _WIN32` around the
   `windows.h` include in `chapt04/transformgl.cpp` and `#include <GL/glx.h>` in `chapt21/fonts/font.c`? (Everything else
   in the demos stays as is.)
4. Is keeping GLee as the default loader (behind an option) acceptable, to be replaced only if it fails on macOS or Windows?
5. Is one reformatting commit with a committed Google-style `.clang-format` acceptable before the CMake work?
