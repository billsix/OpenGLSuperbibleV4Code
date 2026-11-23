# Make the three demos that did not run under Xvfb run (fonts, motionblur, imaging)

**Created:** 2026-11-23, reopened the same day. **Source:** `tasks/archive/2026/11/23/cmake-crossplatform-build.md`.

## Result

All three were fixed with source edits (allowed by the maintainer's rule in `CLAUDE.md`: fixing a program that does not
work is a valid reason to edit). The full run (`BUILD_DIR=cmake-ctr tools/run_cmake_demos_xvfb.sh`, openbox running) shows
**88 of 88 demos alive**. Each demo was also looked at in a screenshot (`motionblur` shows the sphere with its trail,
`imaging` the horse in plain, emboss and sharpen modes with the histogram line).

- **`chapt21/fonts`** (`examples/src/chapt21/fonts/font.c`): `XLoadQueryFont` for the 48-pixel Courier returned NULL and
  `SetupRC` dereferenced it. With the 75dpi font packages installed Courier bold exists only at small sizes. It now tries
  the book's pattern, then `-*-courier-bold-r-normal--*`, then `fixed`, and exits with a message if none loads.
- **`chapt06/motionblur`** (`examples/src/chapt06/motionblur/motionblur.cpp`): the demo requested `GLUT_ACCUM`, and
  freeglut aborts window creation when no GLX configuration has an accumulation buffer. `main` now asks
  `glutGet(GLUT_DISPLAY_MODE_POSSIBLE)` first (the window does not exist yet, so this is the only safe probe); when
  it is false the demo drops `GLUT_ACCUM` and sums the passes with two textures and additive blending: each pass is
  copied with `glCopyTexSubImage2D` into one texture, then the color buffer is cleared to black and rebuilt as
  `sum + weight * pass` with `glBlendFunc(GL_ONE, GL_ONE)` and `GL_MODULATE` (the weight rides on the current color), and
  copied to the other texture. The final frame is the color buffer, so `glAccum(GL_RETURN)` is skipped. The
  `glAccum` path is unchanged and still taken when the window has a buffer.
- **`chapt07/imaging`** (`examples/src/chapt07/imaging/imaging.cpp`): the demo exited 0 on its own
  `gltIsExtSupported("GL_ARB_imaging")` check. The imaging operations now run on the CPU (`Convolve3x3` with edge
  pixels repeated, a per-channel invert, `1.25` brightening, luminance with the book's 0.30/0.59/0.11 weights, a 256-bin
  histogram) and the finished pixels go out through `glDrawPixels`; the extension check and every `GL_ARB_imaging` call
  are gone. Differences from the GL pipeline: the border is repeated where GL's default `GL_REDUCE` shrinks the
  image, clamping happens once at the end of each operation, and the histogram is taken from the processed image's
  luminance. `glutInitDisplayMode(GLUT_RGB | GL_DOUBLE)` was left as written (`GL_DOUBLE` is `0x140A`, which happens to
  include the `GLUT_DOUBLE` bit).

## What was learned (and was first wrong)

- The first diagnosis called `motionblur` a Xvfb limit that "needs a real display". It does not: the maintainer ran it on
  a real AMD/Mesa desktop (2026-11-23) and got the same `FBConfig with necessary capabilities not found`. All 320 GLX
  configurations under Xvfb report accumulation size 0 (`glxinfo -v`); the cause is the driver, not the display.
- **Accumulation buffers:** OpenGL 1.0 (1992, SGI hardware) added `glAccum` (`GL_ACCUM`, `GL_LOAD`, `GL_MULT`,
  `GL_ADD`, `GL_RETURN`); the book used it for motion blur. OpenGL 3.0 (2008) deprecated it and the 3.1 core profile
  removed it; the compatibility profile keeps it, but drivers choose whether to offer an accumulation buffer in their
  window formats, and current Mesa does not on the maintainer's setup. Not confirmed: which Mesa release dropped it
  (the Mesa 21.1.0 notes mention only an unrelated accumulation alpha change). `GL_ARB_imaging` was optional even in
  the 1990s and Mesa llvmpipe 26.2.7 does not list it in `glxinfo`.
- The maintainer's Python translation had already solved both: `github.com/billsix/modelviewprojection`,
  `ports/openglsuperbiblev4/chapt06/motionblur/motionblur.py` (commit `ba922794`, 2026-11-15: texture-sum fallback when
  `GL_ACCUM_RED_BITS` is 0, host-verified) and `chapt07/imaging/imaging.py` (the same operations in numpy, then
  `glDrawPixels`). Its trap list is `tasks/reference/gl-and-imgui-gotchas.md` in that repo. This task ports those
  recipes back to the C++.
- Fedora 45's freeglut 3.8.0 links only X11, so the demos run through XWayland on a Wayland desktop. The follow-up for a
  native Wayland path is `tasks/glut-shim-on-glfw.md`.

## Decisions

- William Emerison Six <billsix@gmail.com>, 2026-11-23: one task for the three demos; a source edit is allowed for
  `fonts`; reopen it to emulate `glAccum` in `motionblur`; CPU port for `imaging`; file the GLFW shim as its own task.
- The probe packages (`xlsfonts`, `glx-utils`, font packages) were installed in throwaway containers only; the image is
  unchanged.
- `tools/run_cmake_demos_xvfb.sh` takes `BUILD_DIR` (default `cmake`) so the container can use `build/cmake-ctr` while a
  host build sits in `build/cmake` (a CMake cache cannot be shared between the two paths).

## Owed (the maintainer, high priority)

- The maintainer's check on the real desktop: `build/cmake/bin/chapt06/motionblur/motionblur` (should now show the blur
  trail) and `build/cmake/bin/chapt07/imaging/imaging` (right-click menu: emboss, sharpen, histogram).
