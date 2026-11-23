# A GLUT-shaped shim on GLFW, so the C++ demos run natively on Wayland

**Status:** proposed — needs go-ahead (filed 2026-11-23)
**Priority:** 7
**Difficulty:** 5
**Created:** 2026-11-23
**Source:** the maintainer's question (William Emerison Six <billsix@gmail.com>, 2026-11-23): how hard is a GLUT-like wrapper
on GLFW (SDL3 only if needed), with Wayland preferred over X; findings from the session that also produced
`tasks/headless-demo-gaps.md`.

## BLUF

Write a small `glut.h`-compatible library over GLFW that implements the GLUT subset these demos use (about 35 functions),
selectable with a CMake option beside freeglut, so the unmodified C++ demos open a native Wayland window. Done means:
every demo that runs under freeglut runs under the shim on a Wayland session (`GLFW_PLATFORM=wayland`) and under X11,
with the menus drawn by Dear ImGui and the loader replaced. Estimate: 1,000 to 1,500 lines, about two sessions. The
loader swap and the menus are most of the work, not the window and callback code.

## Context (read first)

- Today the demos run through freeglut 3.8.0, which Fedora builds against X11 only (`ldd /usr/lib64/libglut.so.3` shows
  `libX11` and no `libwayland`), so on a Wayland desktop they run under XWayland. The freeglut README lists Wayland among
  its supported platforms (`github.com/FreeGLUTProject/freeglut`); whether its Wayland backend is mature, and whether
  building it (rather than using GLFW) is the cheaper route, was not checked. Check that first: if freeglut's Wayland
  backend works, this task may shrink to a CMake option (`SB4_FETCH_FREEGLUT` already fetches freeglut 3.8.0 from source).
- The GLUT surface the demos use is counted in `tasks/reference/dependency-and-portability-audit.md` (section 1): setup,
  display, input (`glutSpecialFunc` 56 call sites, `glutKeyboardFunc` 20, mouse and motion callbacks, mouse wheel),
  `glutTimerFunc` 52, `glutIdleFunc` 5, menus (about 290 call sites in 29 demos), `glutSetWindowTitle`, and the solid
  and wire shapes (25 demos). Not used: `glutGet`-based sizing, bitmap fonts, full screen, game mode, context version.
- The demos need an OpenGL 2.1-level compatibility profile (fixed function plus GLSL 1.10 to 1.20 and EXT framebuffer
  objects). GLFW's default hints give that on Mesa; confirm on Wayland.

## What the Python ports already taught (do not rediscover)

The maintainer's Python translation, `github.com/billsix/modelviewprojection` under `ports/openglsuperbiblev4/`
(104 files, all 22 chapters; chapters 19, 20 and 22 partly stubs), is a per-demo GLFW translation, not a shim, and it ran
on the maintainer's Wayland desktop. Its guide is `tasks/reference/superbible-ports-guide.md` in that repo and its trap
list is `tasks/reference/gl-and-imgui-gotchas.md`. What carries over:

- **GLUT menus become an ImGui menubar** (`_common.py` there: `draw_menubar`, `menu_action`). The shim has to draw a
  pop-up on right button instead (`glutAttachMenu`), handle sub-menus (`glutAddSubMenu`) and live edits
  (`glutChangeToMenuEntry`, 64 call sites in 8 demos).
- **The loader is the Wayland hazard.** GLee 5.21 resolves entry points through `glXGetProcAddress`; a GLFW window on
  Wayland has an EGL context and no GLX. The Python side hit the mirror image: PyOpenGL picks its EGL backend from
  `WAYLAND_DISPLAY`, and a GLX context from imgui-bundle's X11-only `libglfw.so.3` leaves it with no current context
  (`NullFunctionError` on every GL 4.2+ alias). Its rule: `import glfw` before `import imgui_bundle`; the `make shell`
  Makefile there exports `PYGLFW_LIBRARY` to the distribution's dual X11/Wayland build. For C++: use GLFW's own
  `glfwGetProcAddress` through a compatibility-profile loader (GLEW with EGL, or glad `gl:compatibility`) behind the
  `GLEE_*` macros listed in `tasks/reference/dependency-and-portability-audit.md` (section 3). `SB4_LOADER` already exists
  as the CMake switch for this.
- **A single-buffered window may never appear** on the maintainer's host (the Python `single` port had to be
  double-buffered and redraw what the original left in the front buffer). Two C++ demos ask for `GLUT_SINGLE`.
- **No accumulation buffer on Mesa:** the Python `motionblur` and this repo's `chapt06/motionblur` now sum with two
  textures and additive blending; the shim does not change that.
- `GLX`-only code (`chapt21/GLXBasics`, and `chapt21/fonts`' `glXUseXFont`) cannot run in a Wayland-native process; keep
  those two on the X11 path.
- Git history in that repo worth reading before writing a line: `e1affef3` (2026-04-28, first all-chapter port),
  `b31601eb` (an agent change undone: "what claude did was not helpful"), `3539ab30` (Wayland environment-variable
  checks removed because they "cause it not to work"), `ba922794` (2026-11-15, the host-found fixes: single-buffer,
  motionblur texture fallback, hdrbloom, fonts), `d35b73c5` (pixbufobj punted). The Python approach duplicated every demo
  and then needed per-demo fixes; a shim keeps one set of C++ demos.

## Plan

1. Check whether freeglut 3.8.0 built with its Wayland option runs these demos on the maintainer's desktop; if yes, stop
   and add the CMake option instead.
2. Core: `glutInit`, display mode, window creation, the main loop, `glutPostRedisplay` as a dirty flag,
   `glutTimerFunc` as a queue serviced in the loop, `glutIdleFunc`, keyboard, special keys (with up callbacks), mouse,
   motion, wheel, `glutSwapBuffers`, `glutSetWindowTitle`, `glutLeaveMainLoop`, `glutSetOption`.
3. Shapes: lift the `glutSolid*`/`glutWire*` geometry from freeglut (MIT licensed; keep its notice).
4. Menus: ImGui pop-up on the attached button, with sub-menus and `glutChangeToMenuEntry`.
5. Loader: replace GLee behind the `GLEE_*` macros, or keep GLee on X11 only.
6. CMake: `SB4_GLUT=freeglut|glfw`, default freeglut; build the 85+ demos both ways.
7. Verify headless on Wayland if the image can run a headless compositor (for example `weston --backend=headless`), and on
   the maintainer's desktop; compare against `tools/run_cmake_demos_xvfb.sh` results.

## Open questions

1. Is a freeglut-with-Wayland build acceptable instead, if it works (plan step 1)? Recommend: yes, try it first.
2. Should the shim live in this repo (`examples/glut_shim/`) or its own repository? Recommend: this repo, since only these
   demos need it.
