# History audit: 45 commits, 2019 to 2026

**Reference doc**, 2026-11-23 (audit, stage 1 of `tasks/archive/2026/11/23/cmake-crossplatform-build.md`). Built from `git log --numstat`
(`tasks/adhoc/cmake-crossplatform-build/history_table.py`) and from the diffs of every commit that changed behavior.
The root commit `e802274` is the verbatim upstream import, so **the whole history is the maintainer's delta**. Its
author date and commit date are both 2019-11-26 (the day it was imported into git). The repository has 45 commits, not
the 42 `build-and-imgui-fork.md` counted: it missed the three 2026 task commits.

## The eras

1. **Import and first Linux and Windows pass, 2019-11.** `e802274` (import); `638345d` dos2unix; `4536bd7`, `5f39bd0`,
   `523eaa1` the Linux Makefile fixes (`-lstdc++` everywhere); `8a04619` Visual Studio 2003/2005 to 2019; `498c5ca`
   ImGui in `bounce`; `d4820a0` the first behavior change.
2. **macOS and the ImGui retrofits, 2020-01 to 2020-04.** `a9d941f` and `2d05a12` regenerate the Xcode projects;
   `acdbe02`, `3b6f3b3`, `d6defd8` add ImGui to `ambient`, `pyramid` and `shaders`; `e43b649` fixes `atom`'s `glOrtho`;
   `12b37fb` changes `toon`'s filters.
3. **clang-format and macOS 11, 2021-10 to 2022-04.** `eb7a0b3`, `73f58ea`, `02e83be` format the whole tree
   (about 100,000 lines of churn in the second commit alone); `698760e`, `7b874d4`, `3d9d61c`, `c5dc7ca` update the
   Xcode projects; `8d0bd63` and `6092828` fix the chapter 16 specular shaders.
4. **Formatting again, 2024-11.** `6f8a3ed` and `0b6affa`.
5. **Windows packages, 2025-05.** `b8e9cea`: the commit message says that for each project the maintainer ran
   `NuGet\Uninstall-Package nupengl.core`, `Install-Package freeglut.3.0.0.v140` and `glfw`; **only 32 of the 94
   projects were touched** (`windows-build-history.md`).
6. **ImGui vendored and the study, 2025-12 to 2026-08**, then the task commits of 2026-11.

## What changed in the sources against the book

`semantic_delta.sh` formats the upstream import and HEAD with the same clang-format style (carriage returns stripped)
and diffs them, so formatting drops out. Excluding the vendored `GLee.*` and OpenEXR headers, **15 files differ
and almost all of the difference is ImGui**; the full patch is `data/semantic-delta.patch`.

| area | files | change |
|---|---|---|
| ImGui retrofits | `bounce`, `ambient`, `pyramid`, `shaders` (about 400 changed lines) | controls added; for `shaders` and `pyramid` the original GLUT menu and keyboard behavior is reduced |
| behavior | `chapt04/atom/atom.cpp` | `glOrtho` bottom/top swapped (`e43b649`) |
| behavior | `chapt08/toon/toon.cpp` | two table entries 128 and 192 became 127 and 127 (`d4820a0`); both filters NEAREST became LINEAR (`12b37fb`, "messed up toon on purpose"). **The book's cel-shading bands are not what the demo shows now** |
| behavior | `chapt16/vertexshaders/shaders/{3lights,sepspec,specular}.vs` | half-angle vector uses `normalize(-V.xyz)` instead of `vec3(0,0,1)` (`8d0bd63`, `6092828`): a correctness fix to Wright's shader (the viewer direction is `-V` in eye space, not +z) |
| portability | `shared/gltools.h` | include forms: `GLee.h`, `<GLUT/glut.h>`, `<gl\glut.h>`, `windows.h` first (`c14074a`, `b8e9cea`); the upstream `FREEGLUT_STATIC` define and `"glut.h"` include of the bundled freeglut removed (`8a04619`) |
| portability | `shared/gltools.cpp` | `gltGetExtensionPointer` (Windows, Linux, Carbon) and the Apple TGA byte-swap in `gltLoadTGA` removed (`a9d941f`) |
| portability | `chapt04/transformgl/transformgl.cpp` | unconditional `#include <windows.h>` (`b8e9cea`); breaks Linux and macOS |
| portability | `chapt15/shaders/shaders.cpp` | freeglut or GLUT include (`70a39bd`) |
| removed files | `shared/` | the bundled `freeglut.h`, `freeglut_ext.h`, `freeglut_std.h`, `glut.h` and `freeglut_static.lib` (`8a04619`), `.svn`, `ES_example.vcproj` |
| no behavior | `nurbs.cpp` (a comment), `hdrbloom.cpp` (a string split), `math3d.h` (reflow), `bounce.cpp` (`88101c8`) | clang-format residue and an expression cleanup |

So **nothing else in the demos differs from the book** after formatting. The platform work is almost entirely in the
build files. The import had 232 files in the Linux wrapper tree (88 Makefiles plus the textures, shaders and
OpenEXR images each demo opens from its working directory, copied beside the Makefile), 640 in the Apple tree and
333 in the Microsoft tree; the Linux tree still has 232.

## Every commit

Columns: files touched in `examples/src`, the Linux, Apple and Microsoft wrapper trees.

| commit | date | kind | what | src | linux | apple | ms |
|---|---|---|---|--:|--:|--:|--:|
| `e802274` | 2019-11-26 | import | verbatim upstream code, 1,777 files (Subversion metadata included) | 571 | 232 | 640 | 333 |
| `638345d` | 2019-11-26 | format | line endings (dos2unix) and executable bits removed from the Makefiles | 68 | 86 | 0 | 0 |
| `4536bd7` | 2019-11-26 | build/linux | whitespace in all 88 Linux Makefiles (`.cpp.o :` trailing space); the build "fix" | 0 | 88 | 0 | 0 |
| `8a04619` | 2019-11-26 | build/windows | every Visual Studio project converted from VS2003/2005 (`Version="7.10"`) to VS2019 (v142) with the `nupengl.core` NuGet package; static freeglut headers and library deleted from `shared/` | 7 | 0 | 0 | 565 |
| `498c5ca` | 2019-11-26 | feature | ImGui added to `chapt02/bounce` (source, Linux Makefile, VS project) | 1 | 1 | 0 | 2 |
| `d4820a0` | 2019-11-26 | behavior | `toon.cpp`: table value 128 and 192 changed to 127 (GCC on Arch rejected the `GLbyte` initializers) | 1 | 0 | 0 | 0 |
| `5f39bd0` | 2019-11-26 | build/linux | `-lstdc++` added to a few Makefiles (`__cxa_guard_acquire` link failure) | 0 | 5 | 0 | 0 |
| `523eaa1` | 2019-11-30 | build/linux | `-lstdc++` added to every Linux Makefile | 0 | 83 | 0 | 0 |
| `a9d941f` | 2020-01-29 | build/macos | Xcode projects regenerated through chapter 5; `gltools.cpp`: Carbon `gltGetExtensionPointer` and the Apple TGA byte-swap in `gltLoadTGA` removed | 1 | 0 | 67 | 0 |
| `2d05a12` | 2020-02-01 | build/macos | remaining Xcode projects updated to the newer project format | 0 | 0 | 108 | 0 |
| `e8e7750` | 2020-02-01 | build/macos | `bounce` Xcode project | 0 | 0 | 2 | 0 |
| `48900a8` | 2020-02-01 | build/macos | a header search path | 0 | 0 | 1 | 0 |
| `17d5297` | 2020-02-01 | build/macos | ImGui files added to the `bounce` Xcode project, "inputs are not working though" | 0 | 0 | 1 | 0 |
| `e43b649` | 2020-03-04 | behavior | `atom.cpp`: `glOrtho` bottom and top swapped (the picture was upside down) | 1 | 0 | 0 | 0 |
| `acdbe02` | 2020-03-22 | feature | ImGui ambient-light control added to `chapt05/ambient` | 1 | 1 | 0 | 0 |
| `bb01dd2` | 2020-03-23 | build/windows | `bounce` VS project fixed for Windows | 0 | 0 | 0 | 2 |
| `3b6f3b3` | 2020-03-29 | feature | ImGui controls added to `chapt08/pyramid` (texture environment, filters) | 1 | 0 | 0 | 2 |
| `12b37fb` | 2020-03-29 | behavior | `toon.cpp`: 1D texture filters NEAREST changed to LINEAR ("messed up toon on purpose"; removes the book's hard cel bands) | 1 | 0 | 0 | 0 |
| `22cf6f6` | 2020-03-29 | build/linux | `pyramid` Makefile | 0 | 1 | 0 | 0 |
| `d6defd8` | 2020-04-07 | feature | ImGui controls added to `chapt15/shaders` | 1 | 1 | 0 | 0 |
| `eb7a0b3` | 2021-10-22 | format | preparation for a whole-tree clang-format | 83 | 0 | 0 | 0 |
| `73f58ea` | 2021-10-22 | format | first whole-tree clang-format (Google style) | 123 | 0 | 0 | 0 |
| `c14074a` | 2021-10-22 | build/macos | `gltools.h`: `glee.h` to `GLee.h`, `Glut/glut.h` to `GLUT/glut.h` (case, for macOS 11) | 1 | 0 | 0 | 0 |
| `698760e` | 2021-10-22 | build/macos | Xcode projects updated (175 files) | 0 | 0 | 175 | 0 |
| `7b874d4` | 2021-11-09 | build/macos | Xcode projects updated (100 files) | 0 | 0 | 100 | 0 |
| `3d9d61c` | 2021-11-13 | build/macos | Xcode projects updated (130 files) | 0 | 0 | 130 | 0 |
| `c5dc7ca` | 2022-02-21 | build/macos | one Xcode project | 0 | 0 | 1 | 0 |
| `88101c8` | 2022-02-22 | behavior | `bounce.cpp`: window half-size computed from `windowWidth` rather than 100 (an expression cleanup that keeps the value) | 1 | 0 | 0 | 0 |
| `02e83be` | 2022-03-20 | format | second whole-tree clang-format | 226 | 0 | 0 | 0 |
| `70a39bd` | 2022-04-06 | build/linux | `shaders.cpp`: `<GL/freeglut.h>` or `<GLUT/glut.h>` include added | 1 | 0 | 0 | 0 |
| `a9660cb` | 2022-04-10 | build/linux | a Linux Makefile | 0 | 1 | 0 | 0 |
| `7fadda7` | 2022-04-06 | build/linux | the same `shaders.cpp` include (rebased duplicate of `70a39bd`) | 1 | 0 | 0 | 0 |
| `8611346` | 2022-04-11 | merge | merge of the GitHub remote | 0 | 0 | 0 | 0 |
| `8d0bd63` | 2022-04-18 | behavior | chapter 16 shaders: half-angle vector `vec3(0,0,1)` replaced by `-V.xyz` in `3lights.vs`, `sepspec.vs`, `specular.vs` | 3 | 0 | 0 | 0 |
| `6092828` | 2022-04-24 | behavior | the same three shaders: `normalize(-V.xyz)` | 3 | 0 | 0 | 0 |
| `6f8a3ed` | 2024-11-16 | format | clang-format again (2024; 104 files) | 104 | 0 | 0 | 0 |
| `0b6affa` | 2024-11-16 | format | header files reformatted (2024; 21 files) | 21 | 0 | 0 | 0 |
| `b8e9cea` | 2025-05-11 | build/windows | `windows.h` moved first in `gltools.h`, bare include in `transformgl.cpp`; 32 VS projects moved to the freeglut NuGet package (30) or v143 (2) | 2 | 0 | 0 | 63 |
| `c74bbd6` | 2025-12-06 | build | Dear ImGui 1.76 vendored in `contrib/imgui/` (include paths not changed) | 0 | 0 | 0 | 0 |
| `c461a2f` | 2026-08-02 | docs | study task and reference docs | 0 | 0 | 0 | 0 |
| `0d78d5d` | 2026-08-02 | docs | task priority fields | 0 | 0 | 0 | 0 |
| `8643375` | 2026-08-02 | docs | study task archived | 0 | 0 | 0 | 0 |
| `e1c9bb9` | 2026-11-22 | docs | CMake task added | 0 | 0 | 0 | 0 |
| `8f53347` | 2026-11-22 | docs | CMake task updated | 0 | 0 | 0 | 0 |
| `122abd3` | 2026-11-22 | docs | CMake task updated | 0 | 0 | 0 | 0 |

## Corrections to earlier reference docs

- `tasks/reference/build-and-imgui-fork.md` says `c74bbd6` made "a fresh clone [able to] build the imgui demos". It does
  not (the include paths are wrong, `imgui-retrofit-status.md`); it also counts 42 commits (45 now) and attributes
  the 32-project Windows change to "~30 microsoft demos bulk-modernized" (`windows-build-history.md` gives the
  exact numbers).
- The same doc's statement that the Linux build "works because nothing is cached" holds for 81 of the 88 demos
  (`source-audit.md`).
