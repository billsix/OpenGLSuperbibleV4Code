# Source audit: every demo, what wraps it, and whether it builds and runs on Linux

**Reference doc**, written 2026-11-23 by the audit in `tasks/archive/2026/11/23/cmake-crossplatform-build.md` (stage 1). Every
number below is measured, not read: the tables come from `tasks/adhoc/cmake-crossplatform-build/` (`inventory.py`,
`build_linux_demos.sh`, `run_demos_xvfb.sh`, `wrapper_check.py`; snapshot data in its `data/`). It corrects and
extends `tasks/reference/chapter-demo-inventory.md` (what each demo teaches) and
`tasks/reference/build-and-imgui-fork.md` (how it built); read those for the teaching content.

## Method

- **Inventory:** one row per directory `examples/src/chaptNN/<demo>` (101 demos in 22 chapters; 552 tracked files under `examples/src`, 338 of them C/C++/Objective-C sources or headers, including `shared/` and its vendored OpenEXR headers).
- **Linux build:** the repository's own per-demo Makefile (`examples/projects/linux/<chapter>/<demo>/Makefile`) run
  with `make` in a **scratch copy** of the tree (the Makefiles write the binary next to the Makefile; the
  maintainer's checkout has one stray built binary, `chapt18/pixbufobj/pixbufobj`, from such a run), inside the
  Fedora 45 container the audit added (gcc 16, freeglut 3.8, Mesa llvmpipe). 88 Makefiles exist.
- **Linux run:** each built program started under Xvfb (800x600x24, GLX) with Mesa software rendering, an
  `openbox` window manager (the first measurement ran with none: Fedora 45 has no `twm` package and the install
  skipped it silently), 5 seconds, a screenshot at 3 seconds. "alive" = still running at the timeout; the colour count
  is the number of distinct colours in the screenshot, so 1 means nothing was drawn and 2 or more means a window
  with content (a line demo legitimately has 2).
- **Not measured:** correctness of the pictures against the book, macOS and Windows builds (the audit has no
  access to either), input handling (only `imgui-retrofit-status.md` probes input).

## Results

- **101 demos; wrappers:** Linux Makefile 88, Xcode project 91, Visual Studio project 94. Four demos use Dear ImGui.
- **Linux build: 81 of 88 build, 7 fail** (details below). **Linux run: 75 of 88 stay alive for 5 seconds.** The 13
  that do not: the 7 that failed to build (no binary) and 6 that built but died or exited (below).
- **No Linux Makefile:** `chapt10/bezier` (the Linux `build` script runs `cd ../bezier; make`, the Linux readme says
  "Added missing bezier make file", and the file has been absent since the first commit), the seven Windows-only
  demos of `chapt19`, the four Carbon/Cocoa demos of `chapt20` (about 11,000 lines each: they carry a copy of the
  framework sources), and `chapt22/ES_example`.

### The 7 Linux build failures

| demo | first error | cause |
|---|---|---|
| `chapt02/bounce`, `chapt05/ambient`, `chapt08/pyramid`, `chapt15/shaders` | `contrib/imgui//imgui.cpp: No such file or directory` | the Makefiles look for ImGui **six** directories above the demo (`../../../../../../contrib/imgui/`), which is outside the repository; it is at `contrib/imgui/`, four above. With `contrib/` copied to where the Makefile looks, `bounce`, `ambient` and `pyramid` build and run. `shaders` then fails for a second reason, below |
| `chapt15/shaders` (second) | `imgui_impl_opengl3.h: Cannot detect OpenGL loader!` | this demo uses the OpenGL3 ImGui backend, which needs a loader macro (`IMGUI_IMPL_OPENGL_LOADER_*`) that the Makefile does not define |
| `chapt04/transformgl` | `windows.h: No such file or directory` | commit `b8e9cea` added an unconditional `#include <windows.h>` (the Windows fix) to the demo's own source |
| `chapt18/texfloat` | `ImfRgbaFile.h: No such file or directory` | needs OpenEXR **1.x** headers (`-I/usr/local/include/OpenEXR`, `-lIlmThread -lIlmImf`); Fedora ships OpenEXR 3, whose API differs. The repository carries OpenEXR 1.4 headers and libraries under `shared/openexr-*` for Windows and macOS |
| `chapt21/fonts` | `implicit declaration of function 'glXGetCurrentDisplay'` | GCC 14 and later reject implicit function declarations; the demo includes no GLX header (a missing `#include <GL/glx.h>`) |

### The demos that do not stay alive under Xvfb (first run: 6; with a window manager: 2 of the original 6 remain)

- `chapt11/sphereworld`, `chapt13/occquery`, `chapt18/fboenvmap`, `chapt18/pixbufobj`: die with `X Error: BadAtom
  (X_DeleteProperty)`. The common factor is `glutSetWindowTitle`. **A six-line program that only creates a window and
  calls `glutSetWindowTitle` reproduces it** with freeglut 3.8 under Xvfb **with no window manager**. With `openbox`
  running, `chapt11/sphereworld` stays alive: freeglut sets an EWMH property that needs a window manager, so this is a
  test-environment limit, not a defect (the maintainer's real desktop agrees). The first audit run believed a window
  manager was running; `twm` does not exist in Fedora 45.
- `chapt06/motionblur`: `FBConfig with necessary capabilities not found`: the demo asks for an accumulation buffer
  (`GLUT_ACCUM`); all 320 GLX configurations under Xvfb have accumulation size 0, and the maintainer's AMD/Mesa desktop
  fails the same way. The demo now probes with `glutGet(GLUT_DISPLAY_MODE_POSSIBLE)` and sums the passes with textures
  when there is no buffer (`tasks/headless-demo-gaps.md`).
- `chapt07/imaging`: it exited 0 on the book's own `GL_ARB_imaging` check, and Mesa llvmpipe does not list that
  extension. The operations now run on the CPU and are drawn with `glDrawPixels`.
- `chapt21/fonts` crashed at startup until `font.c` fell back from the 48-pixel Courier to another core font.
  With these three edits, 88 of 88 demos stay alive under Xvfb with openbox.

### `chapt08/sphereworld` and `chapt09/texgen`

They run (the first measurement picked a `.tga` file with the executable bit as "the binary"; the run script now
checks for an ELF file). Texture files in these trees carry the executable bit: git recorded it from the upstream
import, and commit `638345d` removed it only from the Makefiles.

## Platform wrappers agree on which files, but not on capitalization

`wrapper_check.py` resolved every in-tree path referenced by the 94 `.vcxproj` and 91 `project.pbxproj` files against
the disk with exact capitalization. **50 projects (22 Visual Studio, 28 Xcode) name a source path whose capitalization
differs from the file on disk** (`src/chapt04/Atom/Atom.cpp` for `src/chapt04/atom/atom.cpp`, `chapt11/thunderGL` for
`thunderGL`, and so on); all 50 resolve case-insensitively, so they build on Windows and macOS (case-insensitive by
default) and would fail on Linux. This matters for the CMake build, which must use the on-disk spelling. (Only the
first bad path of each project was recorded, so a project may have more.)

## Dead and orphaned files

- `examples/src/shared/glfrustum.h`: included by nothing, would not compile (`gltools-framework.md`).
- `gltools.h` still declares `void *gltGetExtensionPointer(const char *)`; the definition (Windows, Linux, Carbon
  code) was removed in `a9d941f` (macOS update) and nothing calls it.
- The upstream import carried `shared/freeglut.h`, `freeglut_ext.h`, `freeglut_std.h`, `glut.h` and
  `freeglut_static.lib` (Windows static freeglut); commit `8a04619` deleted them. A stray `.svn` directory and an
  `ES_example.vcproj` were deleted at the same time.
- `shared/openexr-1.4.0-vsnet2003/` and `shared/openexr-mac/`: OpenEXR 1.4 headers and libraries, used only by
  `chapt18/texfloat`.

## Per-demo table

"gt" = `gltools`, "m3d" = `math3d`. Every demo that includes anything also compiles `GLee.c`. The chapter 19 to 22
rows without a Makefile are platform-specific (Win32/MFC, Carbon/Cocoa, GLX, OpenGL ES).

| chapter / demo | lines | GLUT calls | shared | Makefile | Xcode | VS | Linux build | Linux run (5 s, Xvfb) |
|---|---:|---:|---|:-:|:-:|:-:|---|---|
| chapt01/block | 357 | 16 | gt,m3d | y | y | y | ok | alive, 3 colours |
| chapt02/bounce +ImGui | 240 | 19 | gt | y | y | y | FAIL | no-binary |
| chapt02/glrect | 73 | 7 | gt | y | y | y | ok | alive, 3 colours |
| chapt02/simple | 36 | 5 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/lines | 128 | 10 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/linesw | 122 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/lstipple | 120 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/lstrips | 117 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/points | 118 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/pointsz | 134 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/pstipple | 132 | 9 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/scissor | 65 | 8 | gt | y | y | y | ok | alive, 4 colours |
| chapt03/single | 77 | 10 | gt | y | y | y | ok | alive, 3 colours |
| chapt03/star | 205 | 21 | gt | y | y | y | ok | alive, 2 colours |
| chapt03/stencil | 140 | 11 | gt | y | y | y | ok | alive, 3 colours |
| chapt03/triangle | 217 | 15 | gt | y | y | y | ok | alive, 3 colours |
| chapt04/atom | 149 | 17 | gt | y | y | y | ok | alive, 3 colours |
| chapt04/atom2 | 141 | 17 | gt | y | y | y | ok | alive, 3 colours |
| chapt04/ortho | 248 | 10 | gt | y | y | y | ok | alive, 2 colours |
| chapt04/perspect | 246 | 10 | gt | y | y | y | ok | alive, 5 colours |
| chapt04/solar | 138 | 14 | gt | y | y | y | ok | alive, 329 colours |
| chapt04/sphereworld | 161 | 15 | gt,glframe | y | y | y | ok | alive, 3 colours |
| chapt04/transform | 134 | 11 | gt,m3d | y | y | y | ok | alive, 3 colours |
| chapt04/transformgl | 94 | 11 | gt,m3d | y | y | y | FAIL | no-binary |
| chapt05/ambient +ImGui | 264 | 20 | gt | y | y | y | FAIL | no-binary |
| chapt05/ccube | 200 | 10 | gt | y | y | y | ok | alive, 65537 colours |
| chapt05/jet | 200 | 10 | gt | y | y | y | ok | alive, 5 colours |
| chapt05/litjet | 308 | 10 | gt,m3d | y | y | y | ok | alive, 24 colours |
| chapt05/shadow | 386 | 11 | gt,m3d | y | y | y | ok | alive, 127 colours |
| chapt05/shinyjet | 316 | 10 | gt,m3d | y | y | y | ok | alive, 24 colours |
| chapt05/sphereworld | 235 | 16 | gt,m3d,glframe | y | y | y | ok | alive, 1903 colours |
| chapt05/spot | 224 | 23 | gt | y | y | y | ok | alive, 5 colours |
| chapt05/triangle | 82 | 8 | gt | y | y | y | ok | alive, 52264 colours |
| chapt06/fogged | 241 | 15 | gt,m3d,glframe | y | y | y | ok | alive, 2215 colours |
| chapt06/motionblur | 165 | 9 | gt | y | y | y | ok | crashed |
| chapt06/multisample | 237 | 16 | gt,m3d,glframe | y | y | y | ok | alive, 1643 colours |
| chapt06/reflection | 181 | 12 | gt | y | y | y | ok | alive, 324 colours |
| chapt06/smoother | 189 | 13 | gt,m3d | y | y | y | ok | alive, 2 colours |
| chapt06/sphereworld | 254 | 15 | gt,glframe | y | y | y | ok | alive, 2151 colours |
| chapt07/bitmaps | 88 | 8 | gt | y | y | y | ok | alive, 2 colours |
| chapt07/imageload | 85 | 8 | gt | y | y | y | ok | alive, 22302 colours |
| chapt07/imaging | 244 | 19 | gt | y | y | y | ok | exited |
| chapt07/operations | 204 | 20 | gt | y | y | y | ok | alive, 114882 colours |
| chapt08/pyramid +ImGui | 365 | 20 | gt,m3d | y | y | y | FAIL | no-binary |
| chapt08/sphereworld | 303 | 13 | gt,m3d,glframe | y | y | y | ok | alive, 13916 colours |
| chapt08/toon | 168 | 11 | gt,m3d | y | y | y | ok | alive, 114 colours |
| chapt08/tunnel | 257 | 19 | gt | y | y | y | ok | alive, 12798 colours |
| chapt09/anisotropic | 267 | 21 | gt | y | y | y | ok | alive, 12798 colours |
| chapt09/cubemap | 265 | 13 | gt,glframe | y | y | y | ok | alive, 35191 colours |
| chapt09/multitexture | 320 | 13 | gt,glframe | y | y | y | ok | alive, 41965 colours |
| chapt09/pointsprites | 262 | 14 | gt,glframe | y | y | y | ok | alive, 286 colours |
| chapt09/sphereworld | 305 | 13 | gt,m3d,glframe | y | y | y | ok | alive, 14902 colours |
| chapt09/texgen | 248 | 16 | gt | y | y | y | ok | alive, 8763 colours |
| chapt10/axes3d | 120 | 10 | gt | y | y | y | ok | alive, 141 colours |
| chapt10/bez3d | 117 | 8 | gt | y | y | y | ok | alive, 3 colours |
| chapt10/bezier | 113 | 8 | gt | - | y | y | - | - |
| chapt10/bezlit | 141 | 8 | gt | y | y | y | ok | alive, 130 colours |
| chapt10/florida | 230 | 15 | gt | y | y | y | ok | alive, 235 colours |
| chapt10/nurbc | 131 | 9 | gt | y | y | y | ok | alive, 4 colours |
| chapt10/nurbs | 189 | 9 | gt | y | y | y | ok | alive, 391 colours |
| chapt10/nurbt | 190 | 9 | gt | y | y | y | ok | alive, 778 colours |
| chapt10/snowman | 164 | 10 | gt | y | y | y | ok | alive, 119 colours |
| chapt11/cubedx | 124 | 10 | gt | y | y | y | ok | alive, 2 colours |
| chapt11/sphereworld | 392 | 19 | gt,m3d,stopwatch,glframe | y | y | y | ok | crashed |
| chapt11/starrynight | 280 | 14 | gt,glframe | y | y | y | ok | alive, 286 colours |
| chapt11/thunderbird | 10827 | 11 | gt | y | y | y | ok | alive, 5309 colours |
| chapt11/thundergl | 11100 | 13 | gt,TriangleMesh,glframe | y | y | y | ok | alive, 20393 colours |
| chapt11/vbo | 11100 | 13 | gt,VBOMesh,glframe | y | y | y | ok | alive, 20266 colours |
| chapt12/moons | 268 | 11 | gt | y | y | y | ok | alive, 459 colours |
| chapt12/planets | 253 | 16 | gt | y | y | y | ok | alive, 534 colours |
| chapt12/select | 362 | 10 | gt | y | y | y | ok | alive, 251 colours |
| chapt13/occquery | 538 | 61 | gt,stopwatch | y | y | y | ok | crashed |
| chapt14/shadowmap | 553 | 31 | gt,m3d | y | y | y | ok | alive, 882 colours |
| chapt15/shaders +ImGui | 587 | 49 | gt | y | y | y | FAIL | no-binary |
| chapt16/vertexblend | 553 | 21 | gt,glframe | y | y | y | ok | alive, 928 colours |
| chapt16/vertexshaders | 597 | 25 | gt,glframe | y | y | y | ok | alive, 8 colours |
| chapt17/bumpmap | 724 | 30 | gt,glframe | y | y | y | ok | alive, 474 colours |
| chapt17/fragmentshaders | 494 | 25 | gt,glframe | y | y | y | ok | alive, 1416 colours |
| chapt17/imageproc | 547 | 34 | gt,glframe | y | y | y | ok | alive, 655 colours |
| chapt17/lighting | 428 | 25 | gt,glframe | y | y | y | ok | alive, 8 colours |
| chapt17/proctex | 380 | 21 | gt,glframe | y | y | y | ok | alive, 256 colours |
| chapt18/fbodrawbuffers | 795 | 31 | gt | y | y | y | ok | alive, 20372 colours |
| chapt18/fboenvmap | 775 | 41 | gt,stopwatch | y | y | y | ok | crashed |
| chapt18/fboshadowmap | 619 | 34 | gt,m3d | y | y | y | ok | alive, 905 colours |
| chapt18/hdrbloom | 955 | 21 | gt,glframe | y | y | y | ok | alive, 6646 colours |
| chapt18/pixbufobj | 464 | 34 | gt,stopwatch,glframe | y | y | y | ok | crashed |
| chapt18/texfloat | 553 | 33 | gt,openexr | y | y | y | FAIL | no-binary |
| chapt19/GLRect | 263 | 0 |  | - | - | y | - | - |
| chapt19/GLView | 1239 | 0 |  | - | - | y | - | - |
| chapt19/RThread | 417 | 0 | gt | - | - | y | - | - |
| chapt19/SphereWorld32 | 1018 | 0 | gt,glframe | - | - | y | - | - |
| chapt19/Text2D | 371 | 0 |  | - | - | y | - | - |
| chapt19/Text3D | 392 | 0 |  | - | - | y | - | - |
| chapt19/fscreen | 269 | 0 |  | - | - | y | - | - |
| chapt20/CarbonGL | 11333 | 1 | gt,glframe | - | y | - | - | - |
| chapt20/CarbonGLFonts | 11364 | 1 | gt,glframe | - | y | - | - | - |
| chapt20/CocoGL | 11158 | 1 | gt,glframe | - | - | - | - | - |
| chapt20/FullScreen | 11392 | 1 | gt,glframe | - | y | - | - | - |
| chapt21/GLXBasics | 288 | 0 |  | y | - | - | ok | alive, 4 colours |
| chapt21/fonts | 92 | 8 |  | y | - | - | FAIL | no-binary |
| chapt22/ES_example | 189 | 0 |  | - | - | - | - | - |

