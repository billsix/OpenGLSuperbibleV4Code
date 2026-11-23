# Make the three demos that do not run under Xvfb run (fonts, motionblur, imaging)

**Status:** proposed — needs go-ahead (filed 2026-11-23)
**Priority:** 6
**Difficulty:** 3
**Created:** 2026-11-23
**Source:** `tasks/archive/2026/11/23/cmake-crossplatform-build.md` (results: 85 of 88 demos alive under Xvfb with openbox)

## BLUF

Three of the 88 CMake targets build but do not stay alive under `tools/run_cmake_demos_xvfb.sh`. Done means each one
either runs (a source edit is allowed for `chapt21/fonts`) or is documented as needing something a headless Mesa
llvmpipe session lacks, with the evidence.

## Context

- Source-edit policy (William Emerison Six <billsix@gmail.com>, 2026-11-23): keep the code as close to the book as
  possible, within reason; making a program that does not work work is a valid reason. `CLAUDE.md` records this.
- Run the demos with `make shell`, then `cmake -B build/cmake && cmake --build build/cmake`, then
  `tools/run_cmake_demos_xvfb.sh` (writes `build/cmake-run.tsv`).

## The three demos

1. **`chapt21/fonts`** (`examples/src/chapt21/fonts/font.c`, `SetupRC`): SIGSEGV. `XLoadQueryFont(dpy,
   "-*-courier-bold-r-normal--48-*-*-*-*-*-*-*")` returns NULL (modern X has no scalable core font) and the result is
   dereferenced (`xFont->fid`). Fix: try the pattern, fall back to another core font (`fixed`, or any name from
   `xlsfonts`), and fail with a message instead of a crash if none loads. Check that `fixed` exists in the image
   (`xlsfonts`; the package may need adding to `entrypoint/02-install-graphics.sh` and both sandbox lists).
2. **`chapt06/motionblur`** (`examples/src/chapt06/motionblur/motionblur.cpp`): requests `GLUT_ACCUM`; Xvfb's GLX
   visuals have no accumulation buffer. Check `glxinfo -B`/`xdpyinfo` for an accum visual, try Xvfb options, and
   otherwise confirm on a real display.
3. **`chapt07/imaging`** (`examples/src/chapt07/imaging/imaging.cpp`, `main`): exits 0 by design when
   `gltIsExtSupported("GL_ARB_imaging")` is false, which is the book's own check; the likely cause is that Mesa
   llvmpipe does not advertise `GL_ARB_imaging` (unverified: print the extension string to confirm). Probably
   closes as "needs a driver that exposes the imaging subset".

## Plan

1. Fix `fonts` and rerun it under Xvfb with openbox; screenshot it.
2. Measure `motionblur` and `imaging` as above; record the first-hand cause.
3. Update the done-record counts in `tasks/reference/source-audit.md` and `tasks/reference/audit-summary.md`, and the
   demo counts in `README.md` if they change.

## Open questions

None.
