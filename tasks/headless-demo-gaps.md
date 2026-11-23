# Make the three demos that did not run under Xvfb run (fonts, motionblur, imaging)

**Created:** 2026-11-23. **Source:** `tasks/archive/2026/11/23/cmake-crossplatform-build.md`.

## Result

`chapt21/fonts` was fixed; `chapt06/motionblur` and `chapt07/imaging` are limits of the headless environment, not
defects. The full run (`tools/run_cmake_demos_xvfb.sh`, openbox running) now shows 86 of 88 demos alive.

- **`chapt21/fonts`:** `XLoadQueryFont` for the 48-pixel Courier returned NULL and `SetupRC` dereferenced it. With the
  75dpi font packages installed, Courier bold exists only at small sizes. `examples/src/chapt21/fonts/font.c` now tries
  the book's pattern, then `-*-courier-bold-r-normal--*`, then `fixed`, and exits with a message if none loads. It stays
  alive under Xvfb. This is a third source edit, allowed by the maintainer's rule recorded in `CLAUDE.md` (fixing a
  program that does not work is a valid reason to edit).
- **`chapt06/motionblur`:** the demo requests `GLUT_ACCUM`; all 320 GLX configurations under Xvfb report accumulation
  size 0 (`glxinfo -v`), so freeglut fails with `FBConfig with necessary capabilities not found`. Xvfb has no option to
  add one. Needs a real display.
- **`chapt07/imaging`:** `main` returns 0 when `gltIsExtSupported("GL_ARB_imaging")` is false; Mesa llvmpipe 26.2.7 does
  not list that extension. Needs a driver that exposes the imaging subset, or a real display.

## Decisions

- William Emerison Six <billsix@gmail.com>, 2026-11-23: one task for the three demos; a source edit is allowed for
  `fonts`.
- The probe packages (`xlsfonts`, `glx-utils`, font packages) were installed in throwaway containers only; the image is
  unchanged. `fixed` is in `xorg-x11-fonts-misc`, which the fallback relies on only if the Courier patterns fail; the
  image's own run found a loadable font.

## Owed

- Archive move to `tasks/archive/2026/11/23/headless-demo-gaps.md` once the work commit exists.
- On a real display: confirm `motionblur` and `imaging` (the maintainer's run; no task needed unless one fails).
