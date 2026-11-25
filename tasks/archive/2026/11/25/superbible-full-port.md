# Port every SuperBible v4 demo to Python under `python/` (done)

*Moved here on 2026-11-24 from `github.com/billsix/modelviewprojection` with the Python port (`tasks/archive/2026/11/24/python-port-into-master.md`); earlier history is in that repository's git log and archive.*

The port is complete: about 101 demo files across chapt01-chapt22. chapt01-18 are real ports, chapt19 is mostly real plus Win32-MFC stubs, and the chapt20 (Apple) and chapt22 (GL ES) stubs print a notice and stand as the final form. The port was finished 2026-04-28; the maintainer (William Emerison Six <billsix@gmail.com>) marked the task done 2026-11-24.

The translation rulebook, per-demo skeleton, helper-replacement table, GLFrame unfolding rules, math3d tier catalog and chapter inventory are in `tasks/reference/python-port/translation-guide.md`. GL and imgui failure modes are in `tasks/reference/python-port/gl-and-imgui-gotchas.md`.

## Verification on host GL

Run on the maintainer's display: the chapt01 and chapt02 demos, chapt03/single, chapt06/motionblur, chapt18/hdrbloom, chapt18/texfloat, chapt18/pixbufobj (2026-08-31) and chapt21/fonts. The four 2026-11-15 fixes (single, motionblur, hdrbloom, fonts) are in the gotchas doc. The rest were syntax-checked and run headless, not on a display.

## First-run risks for the demos not yet seen on a display

1. `chapt04/sphereworld`: `forward = (sin(yaw), 0, -cos(yaw))`, derived from `glRotatef(yaw, 0,1,0)` applied to (0,0,-1). If the arrow keys feel inverted, flip the sign in `handle_camera_keys()`.
2. `chapt04/transform`: `rotation_matrix_about_axis` is standard Rodrigues; if the rotation looks reversed, transpose it.
3. `chapt01/block` step 5 draws only the front, top and right faces, as the C++ does.
4. `glRotatef` angles: wrap in `float()` if PyOpenGL raises `TypeError`.
5. `glLightfv` buffers: tuples work elsewhere; switch to numpy arrays if PyOpenGL complains.

The follow-on UX work is `tasks/ports-ux-pass.md`.
