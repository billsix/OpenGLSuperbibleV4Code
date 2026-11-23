# Windows build history: what was tried, and the state of the 94 Visual Studio projects

**Reference doc**, 2026-11-23 (audit, stage 1 of `tasks/archive/2026/11/23/cmake-crossplatform-build.md`). From the git history of
`examples/projects/microsoft/` and the project files at HEAD (`tasks/adhoc/cmake-crossplatform-build/data/
windows-projects.tsv`, `wrapper-check.tsv`). The audit has no Windows machine: **what Visual Studio actually says
today is the one fact missing, and the maintainer will supply the first error text when stage 2 reaches Windows.**

## The layout

94 projects, one solution each (`examples/projects/microsoft/chaptNN/<demo>/<demo>.sln`, `.vcxproj`,
`.vcxproj.filters`, `.vcxproj.user`, `packages.config`), chapters 1 to 19. Each project compiles its demo's source,
`shared/gltools.cpp`, `shared/math3d.cpp` and `shared/GLee.c` by relative path, and copies no data: the demos open
their textures and shaders from the working directory, where each project directory keeps its own copy.
Each project restores its own NuGet packages into `<project>\packages\` at build time (it needs network and NuGet).

## What was tried, in order

1. **Import (2019-11-26):** 94 projects in the Visual Studio 2003 to 2005 format (`ES_example.vcproj` shows
   `Version="7.10"`) with static freeglut shipped in `shared/` (`freeglut_static.lib`, `FREEGLUT_STATIC` defined in
   `gltools.h`).
2. **`8a04619` (2019-11-26) "Visual Studio 2019/Nuget updates":** converted all 94 to VS2019 (`v142`, `# Visual Studio
   Version 16`), replaced the bundled freeglut with the **`nupengl.core` 0.1.0.1** and `nupengl.core.redist` NuGet
   packages (an unofficial freeglut and GLEW bundle; version 0.1.0.1), deleted `shared/freeglut*` and `glut.h`, switched
   `gltools.h` from `"glut.h"` to `<gl\glut.h>`.
3. **`498c5ca`, `bb01dd2` (2019-11, 2020-03):** `bounce`'s project given the ImGui sources; fixed for Windows.
4. **`b8e9cea` (2025-05-11) "fixed build on windows, turns out windows.h needs to be imported first":** moved
   `#include <windows.h>` to the top of `gltools.h` (the OpenGL headers need its macros), and, per the commit message,
   "for each project" ran in the NuGet console: uninstall `nupengl.core` and `nupengl.core.redist`; install
   `freeglut.3.0.0.v140` 1.0.2, `glfw`, `glew`, `freeglut`; toolset `v142` to `v143`.

## What the project files say now (HEAD)

| state | projects | demos |
|---|--:|---|
| `v143`, `freeglut.3.0.0.v140` 1.0.2 + `glfw` 3.4.0 (the 2025 change applied) | **30** | chapters 1 to 5: `block`, `simple`, `lines`, `linesw`, `lstipple`, `lstrips`, `points`, `pointsz`, `pstipple`, `scissor`, `single`, `star`, `stencil`, `triangle`, `SphereWorld`, `atom`, `atom2`, `ortho`, `perspect`, `solar`, `transform`, `transformgl`, `Ambient`, `ccube`, `jet`, `litjet`, `shadow`, `shinyjet`, `spot`, `triangle` |
| `v143` but still `nupengl.core` | 2 | `bounce`, `glrect` |
| `v142` and still `nupengl.core` (**never touched by 2025**) | **62** | chapters 6 to 18 and `glrect`; for example `pyramid`, `shaders` |

So the 2025 conversion reached **30 of 94 projects, all in chapters 1 to 5**, and the other 64 still depend on the
`nupengl.core` package and (62 of them) the VS2019 toolset. The commit's own list also names `glew` and a second
`freeglut` package, but neither appears in any `packages.config` (only `freeglut.3.0.0.v140` and `glfw` do), so those two
installs were not kept. **Possible mismatch in the packages in use:** `freeglut.3.0.0.v140` is a binary package built
for the VS2015 toolset (`v140`) used from `v143`; `glfw` 3.4.0 is installed in 30 projects but no demo source includes
it (the demos use GLUT and GLee).

## Reasons a modern Visual Studio build would fail, found by reading (not yet by running)

- **Mixed state:** 64 projects still import `nupengl.core` targets. Whether that package still restores on a current
  NuGet feed and works with `v143` is not known (the maintainer's first error message will say).
- **Case and paths:** 22 projects name a source path whose capitalization differs from the file on disk
  (`source-audit.md`); harmless on Windows.
- **`gltools.h` Windows branch:** `#include <gl\gl.h>`, `<gl\glu.h>`, `<gl\glut.h>` with backslashes (works only on
  Windows; the build must be a single source of truth for headers), and `windows.h` included first.
- **`shaders`** includes ImGui in its source but its Visual Studio project does not compile ImGui
  (`imgui-retrofit-status.md`).
- **`texfloat`** needs OpenEXR 1.x (`#pragma comment(lib, ...)` in the source, the headers under `shared/openexr-1.4.0-vsnet2003/`,
  a VS2003-era static library).
- **Project paths for ImGui** are six levels up (`..\..\..\..\..\..\contrib\imgui`), outside the repository.

## What CMake changes for Windows

One `CMakeLists.txt` replaces 94 projects and their per-project `packages\` trees; freeglut (or the shim's GLFW) comes
from one declaration (`FetchContent` or vcpkg) instead of 94 NuGet restores; the toolset is whatever generator the
user runs. See `audit-summary.md` for the plan this implies.
