# Dependency and portability audit: what the code needs from the platform

**Reference doc**, 2026-11-23 (audit, stage 1 of `tasks/archive/2026/11/23/cmake-crossplatform-build.md`). Counts come from `git grep`
over `examples/src` (the 101 demos and `shared/`), the audit's `data/demos.tsv`, and the container build
(`source-audit.md`). Companion docs: `gltools-framework.md` (the shared library), `chapter-demo-inventory.md`.

## 1. The windowing layer: GLUT, classic subset, callback style

Every demo is a callback program: `main` calls `glutInit`, `glutInitDisplayMode`, `glutInitWindowSize`,
`glutCreateWindow`, registers callbacks, then `glutMainLoop`. The whole GLUT surface the demos use (counts are call
sites in `examples/src`, number of demos in brackets):

| group | functions | calls [demos] |
|---|---|--:|
| setup | `glutInit`, `glutInitDisplayMode`, `glutInitWindowSize`, `glutCreateWindow`, `glutMainLoop` | 87 each |
| display | `glutDisplayFunc` 87, `glutReshapeFunc` 86, `glutSwapBuffers` 94, `glutPostRedisplay` 135 [72] | |
| input | `glutSpecialFunc` 56 [56], `glutKeyboardFunc` 20, `glutMouseFunc` 7, `glutMotionFunc` 6, `glutPassiveMotionFunc` 4, `glutKeyboardUpFunc` 4, `glutSpecialUpFunc` 4, `glutMouseWheelFunc` 6 [5] | |
| time | `glutTimerFunc` 52 [26], `glutIdleFunc` 5 [5] | |
| menus | `glutCreateMenu` 45 [29], `glutAddMenuEntry` 120, `glutAttachMenu` 29, `glutChangeToMenuEntry` 64 [8], `glutAddSubMenu` 16, `glutChangeToSubMenu` 19, `glutSetMenu` 11 | about 290 |
| window | `glutSetWindowTitle` 17 [10] | |
| shapes | `glutSolidSphere` 40, `glutSolidCube` 19, `glutSolidCone` 10, `glutSolidTorus` 9, `glutSolidTeapot` 6, `glutSolidOctahedron` 6, one each of tetrahedron, icosahedron, dodecahedron, `glutWireCube` | 25 demos |
| freeglut only | `glutMouseWheelFunc` 6, `glutLeaveMainLoop` 1, `glutSetOption` 2 (`GLUT_ACTION_ON_WINDOW_CLOSE`); three of the four ImGui demos reach `glutMouseWheelFunc` through the ImGui backend | 8 |

Not used anywhere: `glutGet`, `glutBitmapCharacter`, `glutFullScreen`, game mode, `glutInitContextVersion`. The display
modes requested: `GLUT_RGB` 83, `GLUT_DOUBLE` 81, `GLUT_DEPTH` 73, `GLUT_MULTISAMPLE` 10, `GLUT_STENCIL` 5, `GLUT_SINGLE`
2, `GLUT_ACCUM` 1 (`motionblur`; Xvfb cannot provide an accumulation buffer).

Consequences for a replacement backend (GLFW or SDL behind a GLUT-shaped shim): the surface to implement is about 35
functions; the **menus** are the bulk (about 290 call sites in 29 demos) and have no GLFW or SDL equivalent, so the
shim renders them as a pop-up (ImGui, as the Python port does) or as a documented loss; `glutSolid*` need geometry (the
Python port's README says it replaced them with inline draw calls; freeglut also has them, so the shim
can omit them only if freeglut is linked); `glutTimerFunc` needs a timer queue serviced in the loop; `glutPostRedisplay`
a dirty flag.

## 2. Header forms (a portability bug list)

Including the demos and `gltools.h`: `<GL/gl.h>` 7, `<GL/glu.h>` 3, **`<gl\gl.h>` 6 and `<gl\glu.h>` 6 and
`<gl\glut.h>` 1** (Windows backslash paths), `<GLUT/glut.h>` 3 and `<OpenGL/gl.h>` 2 (macOS), `<GL/freeglut.h>` 2,
`"GLee.h"` 2 against `"..\..\shared\glee.h"` 2 (lowercase `glee.h`, which does not exist on a case-sensitive file
system) and `<glut.h>` 1. `gltools.h` picks the set with `#ifdef WIN32`, `__APPLE__` and a Linux default and includes
`<Carbon/Carbon.h>` on Apple, a framework macOS no longer ships for 64-bit programs. `chapt04/transformgl.cpp` includes `<windows.h>` unconditionally.

## 3. The extension loader: GLee

`GLee.c`/`GLee.h` (GLee 5.21, 17,324 lines) is compiled into every demo. The macros the demos query (the interface any
replacement loader must offer):

`GLEE_VERSION_1_3` 5, `_1_4` 5, `_1_5` 1, `_2_0` 12, `_2_1` 1; `GLEE_ARB_shader_objects` 10,
`_shading_language_100` 9, `_fragment_shader` 8, `_vertex_shader` 7, `_texture_non_power_of_two` 8, `_multitexture` 5,
`_texture_cube_map` 4, `_texture_float` 2, `_texture_env_add` 2, `_shadow` 2, `_shadow_ambient` 2, `_draw_buffers` 2,
`_pixel_buffer_object` 1, `_occlusion_query` 1; `GLEE_EXT_framebuffer_object` 4, `GLEE_EXT_secondary_color` 1.

Core entry points by number of demos: `glGenTextures` 25, `glActiveTexture` 15, `glMultiTexCoord*` 13,
`glCreateShader`/`glCreateProgram` 13 (GLSL 1.x), `glGenFramebuffersEXT`/`glGenRenderbuffersEXT` 5, `glGenBuffers` 3,
`glDrawBuffers` 3, `glGenerateMipmap` 4, `glGenQueries` 2, `glTexImage3D` 1, `glGenProgramsARB` 1, `glAccum` 1. The demos
use the **fixed-function pipeline plus GLSL 1.10 to 1.20 shaders and EXT framebuffer objects: a compatibility
profile, OpenGL 2.1 level.** None needs a core profile; none can run on one. A modern replacement loader therefore
has to load a **compatibility** profile (GLEW: yes; glad: generate `gl:compatibility`; libepoxy: yes; GLFW alone:
no function loading).

| candidate | fit | what `gltools.h` and the demos would need |
|---|---|---|
| keep GLee 5.21 | builds today on Linux (81 of 88 demos) | nothing; unknown on current Windows and macOS drivers (2007-era lazy `__stdcall` stubs) |
| GLEW | same macro family: `GLEW_VERSION_2_0`, `GLEW_ARB_shader_objects` | `#define GLEE_X GLEW_X` shim header; `glewInit()` call after window creation (GLee initializes lazily) |
| glad (compatibility 2.1 plus the extensions above) | `GLAD_GL_ARB_...` flags | a header that maps the `GLEE_*` names; `gladLoadGL` call |
| libepoxy | no extension macros | rewrite the 12-odd `GLEE_*` checks as `epoxy_has_gl_extension` |

## 4. Platform-specific code outside the demos' common core

- `chapt19` (Win32/MFC: GLRect, GLView, RThread, SphereWorld32, Text2D, Text3D, fscreen: WGL, `windows.h`, resources):
  not portable; 7 demos; no Linux or macOS wrapper.
- `chapt20` (Carbon and Cocoa: CarbonGL, CarbonGLFonts, CocoGL, FullScreen): about 11,000 lines per demo (each carries
  the framework sources); Carbon is gone from macOS.
- `chapt21`: `GLXBasics` (raw GLX, builds and runs under Xvfb) and `fonts` (needs an added `#include <GL/glx.h>` on
  GCC 14 and later).
- `chapt22/ES_example`: OpenGL ES, a `readme` only.
- `shared/gltools.cpp` has two platform branches left: `#ifdef _WIN32` (line 69, a WGL extension check) and
  `#ifdef __APPLE__` (line 346, the TGA header byte-swap in `gltWriteTGA`); the same byte-swap in `gltLoadTGA` and the
  Carbon `gltGetExtensionPointer` were deleted in `a9d941f`.

## 5. Non-portable C++ and layout

- Binary-name and directory conventions: demos open textures and shaders by **relative name from the working
  directory** (`block` opens `floor.tga`, `Block4.tga`, ...; 70 `.tga`, 38 `.fs`, 24 `.vs`, 8 `.exr` files are copied
  into each Linux wrapper directory beside the Makefile, and a second copy lives under `examples/src/<demo>/`). A
  CMake build must put each demo's data beside the binary (or set the working directory), per demo.
- The Linux Makefiles hardcode `-I /usr/local/include/GL`, `-L /usr/local/lib` and, for `GLXBasics`, `/usr/X11R6/lib`:
  2007 paths; they build today because the package headers are found by default.
- Every Makefile recompiles the demo, `math3d.cpp`, `gltools.cpp` and `GLee.c` into one binary (`gcc -lstdc++`):
  no library target, so 88 builds compile `GLee.c` 88 times.
- `-lstdc++` on the link line of a `gcc` driver is the 2019 fix for a link error; `g++` as driver removes it.
- Case-sensitivity of project paths: `source-audit.md` (50 Visual Studio and Xcode projects).
- `chapt18/texfloat` is the only user of OpenEXR 1.x; the repository carries its headers, and `hdrbloom` needs none.
- Compiler warnings under GCC 16 (default flags): the 81 builds succeed; implicit function declaration is the one hard
  error (`chapt21/fonts`).

## 6. What this means for a CMake build

1. One `gltools` static library (math3d, gltools, loader) replaces 88 recompilations.
2. The GLUT layer is a **target** with two implementations (system freeglut/GLUT; the GLFW-backed shim), chosen by
   a CMake option; the demo sources keep their `glut*` calls.
3. A compatibility-profile loader; GLee works on Linux today, and a replacement behind the same header name needs only
   the `GLEE_*` macro names above.
4. A per-demo data-copy rule.
5. ImGui: `contrib/imgui` as an interface library with the include path fixed once.
6. `chapt19`, `chapt20`, `chapt22` stay out (platform APIs); `chapt21/GLXBasics` and `fonts` are Linux-only targets.
