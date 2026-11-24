# OpenGL SuperBible v4 — Python port

A faithful Python translation of every demo in **OpenGL SuperBible, 4th Edition** (Richard S. Wright Jr., 2007). The layout
mirrors `examples/src/`: each demo is `python/chaptNN/<demoName>/<File>.py` and reads alongside the C++ original in
`examples/src/chaptNN/<demoName>/`. The textures and shaders are the C++ demo's own files, read from that directory, so
nothing is duplicated.

The port began in the course repository `github.com/billsix/modelviewprojection` (second half of the course: students read the
SuperBible without learning C++) and moved here on 2026-11-24 with its history. The course's own SuperBible-derived demos
(`demo19a`–`19e`, `demo22`, `22a`, `22b`, `23`, `24`) stay there; the translations here are faithful, not re-pedagogized.

## Run a demo

```sh
make run DEMO=chapt01/block       # [HOST] the Python port, in the container, on Wayland or X11
make run-c DEMO=chapt01/block     # [HOST] the C++ original, built in the container, on X11 (or XWayland)
make list                         # [HOST] every demo that has a port
```

Both halves run from one image (`make image`). The Python demos use PyOpenGL and GLFW; the C++ demos load GL through GLX,
so `run-c` unsets `WAYLAND_DISPLAY`. Dependencies are pinned in `python/requirements.txt` and `python/constraints.txt`
(`make update-pins` re-resolves them).

## Gates

```sh
make check        # [HOST] import every module (no display): tools/check_python_imports.py
make type-check   # [HOST] every binding annotated: tools/check_local_annotations.py
make format       # [HOST] clang-format for the C++, ruff (ruff.toml) for python/ and tools/
make shell-exec SCRIPT=tools/run_python_demos_xvfb.sh   # [HOST] run every demo under Xvfb, record alive/crashed
```

`ty` is not a gate: its diagnostics are glfw and imgui stub friction. Demos run by path, so each inserts the `python/` root into `sys.path` and then runs `import _common` (hence E402 is ignored for
`python/` in `ruff.toml`); each opens its window only under `if __name__ == "__main__":`.

## Layout

| Path | Contents |
|---|---|
| `python/chaptNN/<demo>/<File>.py` | one script per demo, named like the C++ file |
| `python/_common.py` | window and fullscreen state, the Dear ImGui menubar, the walk-around `Camera`, `asset_dir()` |
| `python/_primitives.py` | precomputed tessellation replacing `glutSolid*` |
| `python/_geometry.py` | `find_normal` and `plane_equation` (frozen copy from the course repository) |
| `python/chapt11/_thunderbird_data.py` | the Thunderbird mesh shared by three chapter 11 demos |
| `python/chapt15/shaders/shaders.{vs,fs}` | the only asset files kept beside the Python: the C++ embeds this GLSL |

## Translation rules

The full rulebook (per-demo skeleton, GLUT→GLFW mapping, `GLFrame` unfolding, helper exemplars, upstream source map) is
`tasks/reference/python-port/translation-guide.md`; the GL, imgui and GLFW traps are in
`tasks/reference/python-port/gl-and-imgui-gotchas.md`. In short:

| SuperBible C++ | Python port |
|---|---|
| GLUT (`glutInit`, `glutMainLoop`, `glutDisplayFunc`, `glutReshapeFunc`, `glutTimerFunc`) | GLFW polling loop |
| `glutKeyboardFunc` / `glutSpecialFunc` | `glfw.set_key_callback` or `glfw.get_key` polling |
| `glutCreateMenu`, `glutBitmapCharacter`, GLUI | `imgui_bundle` (Dear ImGui) menubar and overlays |
| `glutSolidCube` / `glutWireCube` / `glutSolidSphere` / etc. | inline draw calls (`glBegin`/`glEnd`), no GLUT dependency |
| `M3DVector3f` / `M3DMatrix44f` | `numpy.ndarray`, or gacalc's `Vector` where vector algebra is used |
| `m3dFindNormal`, `m3dGetPlaneEquation` | `find_normal`, `plane_equation` from `_geometry` |
| `m3dMakePlanarShadowMatrix`, `m3dRotationMatrix44`, etc. | inline helper functions in the demo file |
| `gltLoadTGA` | `imageio.v3.imread` |
| `GLFrame` (camera or actor frame) | unfolded inline as `glRotatef` + `glTranslate`, no Python `GLFrame` class |

Fixed-function stays fixed-function. Shader-era chapters keep SuperBible's `.vs`/`.fs` file names so students can find the
shaders by the names in the book. Mutable state lives in one module-level `state: AppState` dataclass per demo.

## What is stubbed rather than ported

These are `.py` files that print a notice and exit, so every upstream demo has an entry:

- **chapt19/GLView, chapt19/RThread**: Win32 MFC dialog and WGL threading. The rest of chapt19 (GLRect, fscreen, SphereWorld32)
  is real, and Text2D and Text3D are redone with imgui.
- **chapt20** (all four): deprecated Apple Carbon and Cocoa.
- **chapt22/ES_example**: OpenGL ES does not map to the desktop GL stack used here.

## Status

The port is complete (2026-04-28): about 101 demo files across chapt01–chapt22 (everything real except the stubs above).
Hardware verification is ongoing and is the maintainer's: the punchlist is `tasks/superbible-full-port.md`, the walk-around
camera migration is `tasks/ports-ux-pass.md` (only the `chapt08/sphereworld` canary is wired), and a known fidelity gap is
`tasks/pixbufobj-port-fidelity.md`.
