# SuperBible v4 Python port — source map & translation guide

**Reference document** — the upstream C++ (`examples/src/`), the settled C++→Python translation rules, and the state of
the `python/` tree. Read this before porting, re-porting, or bulk-editing anything there. Not a task; update in place.
Moved here from `github.com/billsix/modelviewprojection` (`tasks/reference/superbible-ports-guide.md`) on 2026-11-24.

The port itself is **complete** (2026-04-28, ~101 demo files, all chapters); the live work is the UX pass
(`tasks/ports-ux-pass.md`) and the maintainer's hardware verification (first-run risks in `tasks/archive/2026/11/25/superbible-full-port.md`).
GL failure modes learned during the port are in `tasks/reference/python-port/gl-and-imgui-gotchas.md`. The upstream C++
is mapped in this repository's other `tasks/reference/` docs (start with `architecture-overview.md`).

**Where things are:** each demo is `python/chaptNN/<demo>/<File>.py`, next to nothing: its textures and shaders are the C++
demo's own, read from `examples/src/chaptNN/<demo>/` through `_common.asset_dir`. The one exception is
`python/chapt15/shaders/shaders.{vs,fs}`, which exist only for the Python demo (the C++ original embeds the GLSL).

Citations of the form `tasks/archive/...` and `tasks/<name>.md` that this repository does not have name
documents in `github.com/billsix/modelviewprojection` (kept unchanged for history and no longer maintained; its successor is
`github.com/billsix/Programming3DComputerGraphics`); the open ones moved here with the port.

---


## 0. Port fidelity — NOT every port renders identically to the C++ original

The `ports/` demos are faithful translations, but a few do **not** reproduce the original's
on-screen behaviour yet. Track each as its own task; known cases:

- **chapt18/pixbufobj — "multiple spinning images" on some hardware.** The C++ shows one
  motion-blurred rotating album; on the maintainer's hardware (Mesa/GPU) the port appears to show
  multiple overlapping copies. **Does NOT reproduce under the sandbox's software GL
  (llvmpipe)** — there the port renders one clean rotating album (window corners
  pixel-verified black, `CLAMP_TO_BORDER` working), and its draw-time GL state (units,
  bound textures, texture-matrix rotation, wrap mode, border colour, blend, viewport) is
  provably identical to the C++. So it looks **hardware/driver-specific** (a texture-matrix
  + multitexture + `CLAMP_TO_BORDER` edge case llvmpipe doesn't hit) or tied to interactive
  state. Tracked in `tasks/pixbufobj-port-fidelity.md`. (Its *separate* PBO-readback crash
  is already fixed — see `tasks/archive/2026/11/15/ports-pbo-floattex-runtime-crashes.md`.)

Add to this list as more divergences surface.


## 1. What this tree is (and its twin in the course repository)

| | course demos (`github.com/billsix/modelviewprojection`, `src/modelviewprojection/demos/`) | `python/` (this repository) |
|---|---|---|
| Audience | first half of the course, the maintainer's arc | students reading the SuperBible book |
| Style | `InvertibleFunction`, Cayley graphs | faithful 1:1 translation of the C++ |
| Scene | the Pong scene throughout | whatever the SuperBible demo draws |

Nine of the course's demos are SuperBible material re-pedagogized *into* the course; the translations here are separate
and faithful. Don't conflate same-named demos (Block, sphereworld, atom, solar) across the two repositories. The course
repository keeps its own copies, with their own shaders and textures, so nothing here is read by it:

| Course demo | SuperBible original | Translation here |
|---|---|---|
| `demo19a` | `axes3d` | `chapt10/axes3d` |
| `demo19b` | `atom` | `chapt04/atom` |
| `demo19c` | `solar` | `chapt04/solar` |
| `demo19d` | chapt12 `moons` | `chapt12/moons` |
| `demo19e` | chapt04 `sphereworld` (fixed-function, GLU spheres) | `chapt04/sphereworld` |
| `demo22`, `demo22b` | `Block` | `chapt01/block` |
| `demo22a` | `pyramid` | `chapt08/pyramid` |
| `demo23` | `litjet` | `chapt05/litjet` |
| `demo24` | `sphereworld` modernized (3.3 Core, lit) | `chapt09/sphereworld` |

## 2. The upstream source (`examples/src/`, next to this tree)

- Layout: `examples/src/chaptNN/<demo>/<demo>.cpp` — one 200–400-line cpp per
  demo, no per-demo headers. `shared/` holds the support library every demo
  links: `math3d.{h,cpp}`, `gltools.{h,cpp}` (TGA loader, `gltDrawTorus`/
  `gltDrawSphere`/`gltDrawUnitAxes`, shader loader), `glframe.h` (`GLFrame`),
  `glfrustum.h`, `GLee` (pre-GLEW extension loader). Linux builds are one
  plain Makefile per demo.
- **Era split: chapt01–16 pure fixed-function; chapt17 is the first shader
  chapter** (adds `shaders/<name>.vs`/`.fs`); chapt19 is SuperBible's own
  "modern" Win32 port; chapt20 macOS; chapt22 GL ES.
- **`GLFrame` is the crux abstraction**: an orthonormal frame (origin +
  forward + up) used as both camera and per-object placement
  (`ApplyActorTransform`/`ApplyCameraTransform`). the course has no analogue and
  the maintainer's pedagogy avoids unified frame abstractions — **unfold it** into the
  state the demo actually uses (position + yaw globals + an inline
  `apply_camera_transform()`; see `chapt04/sphereworld`). math3d has **no
  quaternions** (GLFrame's forward+up dodges gimbal lock), no `lookAt`, no
  standalone frustum builder — so nothing upstream forces those on us.
  (`tasks/archive/2026/04/28/notes-superbible-structure.md`)

### The math3d catalog

- **Ported and shared:** `m3dFindNormal`/`m3dGetPlaneEquation`/
  `m3dGetDistanceToPlane` → `mathutils.find_normal`/`plane_equation`/
  `distance_to_plane`.
- **Tier 2 — port with the demo that needs it, not before:**
  `m3dCalculateTangentBasis` → chapt17/bumpmap; `GLFrustum.TestSphere` →
  chapt19/SphereWorld32; `m3dRaySphereTest`/`m3dClosestPointOnRay` → picking.
  `m3dSmoothStep`/`m3dCatmullRom` judged not worth a CPU-side port.
- **Tier 3 — inline translations:** `m3dGetVectorLength` → `abs(v)`,
  `m3dNormalizeVector` → `v * (1/abs(v))`, matrix ops → numpy
  (`np.matmul`/`np.transpose` on plain `ndarray`s — **not** `np.matrix`).
  (`tasks/archive/2026/04/28/notes-superbible-math-diff.md`)

### The winding decision (why signs differ from the book)

SuperBible is internally inconsistent: `m3dGetPlaneEquation` winds **CW**,
`m3dFindNormal` winds **CCW** — a one-to-one port had to pick. the port picked
**CCW everywhere** (matching `glFrontFace(GL_CCW)`). Consequences:
`find_normal` is deliberately unnormalized (length = 2× triangle area,
mirroring upstream); `plane_equation` normalizes; a plane is a bare
`(normal, d)` **tuple** by decision (not a `Plane` dataclass — "a normal and
an offset", revisit only if a third caller appears). And the CW/CCW flip is
exactly what makes the planar-shadow matrix produce negative clip-space `w`
with this plane convention — **the shadow matrix is NOT sign-invariant**; see
`gl-and-imgui-gotchas.md` §3 (this corrects
`tasks/archive/2026/04/28/plane-and-normal-helpers.md`, which recorded the
sign-invariance belief before it was disproven).

## 3. Translation rules (the settled patterns)

Mechanical, uniform — new ports match these so students can read across demos.

- **Window/loop:** GLUT callbacks → GLFW polling loop. `glutDisplayFunc` →
  call per iteration; `glutSpecialFunc` → poll `glfw.get_key` per frame;
  `glutKeyboardFunc` → `glfw.set_key_callback` (PRESS vs REPEAT
  distinguishable); `glutTimerFunc(ms,…)` → a `time.monotonic()` tick loop
  (`tick()` on interval, render every iteration); `GLUT_SINGLE` →
  double-buffer and redraw what the original accumulated in the front
  buffer (single-buffered windows may never show; chapt03/single); `GLUT_STENCIL` →
  `window_hint(STENCIL_BITS, 8)`; `GLUT_MULTISAMPLE` →
  `window_hint(SAMPLES, 4)`.
- **GUI:** GLUT right-click menus / bitmap text → imgui via `_common`
  (menubar convention — see `gl-and-imgui-gotchas.md` §1).
- **Fixed-function stays fixed-function** (chapt01–16): `glPushMatrix`,
  `glRotatef`, `glBegin/glEnd` exactly as upstream — no VAO/VBO-ification, no
  display lists unless the C++ used them (the maintainer's constraint; `_primitives.py`
  only moves *when the tessellation trig runs*, not how drawing happens).
- **Shader era** (chapt17+): shader files keep the book's `.vs`/`.fs` names
  (students read along; the course's `.vert`/`.frag` convention does not apply here).
- **Vectors:** the lit/shadow ports use gacalc's `Vector` and the plane helpers in `_geometry.py`, importing
  `from gacalc.g3 import Vector` **directly**.
- **Per-demo skeleton:** header comment (name, one-liner, "OpenGL SuperBible,
  Chapter NN", "Python port of <X>.cpp by Richard S. Wright Jr."), the `sys.path`
  insert and `import _common` (then `ASSET_DIR` for demos that read files),
  an `AppState` dataclass for the mutable state (below),
  `render_scene`/`setup_rc`/`change_size`, polling `handle_special_keys`,
  `main()` with the GLFW boilerplate, `__main__` guard. Procedural: functions,
  no other classes.
- **Mutable state lives in one `AppState` dataclass per app** (William Emerison
  Six <billsix@gmail.com>, 2026-11-14): `@dataclasses.dataclass class
  AppState` with annotated, defaulted fields (mutable defaults through
  `dataclasses.field(default_factory=...)`), one module-level
  `state: AppState = AppState()`, and every function reads and writes
  `state.<field>` — no `global`/`nonlocal`. GLFW callbacks keep their fixed
  signatures and reach `state` directly; the window handle is `state.window`.
  State = anything rebound or mutated in place at run time (GL ids from setup,
  lists filled in `setup_rc`, nudged camera positions); values never changed
  after import stay module-level annotated constants under their own names.
  Model: `chapt02/bounce/bounce.py`. This applies to `python/` only; the course demos keep
  procedural globals.
- **Annotate every binding, including unpacks and loop targets:** a tuple
  result goes through an annotated intermediate read by index
  (`size: tuple[int, int] = glfw.get_framebuffer_size(window)`, then `size[0]`;
  imgui's `(changed, value)` the same way), and a `for`/`with` target gets a bare
  declaration on the line above. Exempt: `_`, comprehension and `except ... as`
  targets. 

### Helper-replacement exemplars (copy from these files)

| Upstream call | Inline helper — exemplar |
|---|---|
| `glutSolidCube`/`glutWireCube` | `draw_solid_cube`/`draw_wire_cube` — `chapt01/block/Block.py` |
| `glutSolidSphere` | `draw_solid_sphere` — `chapt04/atom/atom.py` (QUAD_STRIP latitude bands) |
| `gltDrawTorus` | `draw_torus` — `chapt04/transformgl/transformgl.py` |
| `gltLoadTGA` | `load_tga_texture` (imageio + `np.flipud` + `ascontiguousarray`) — `chapt01/block/Block.py` |
| `m3dRotationMatrix44` | `rotation_matrix_about_axis` (direct Rodrigues) — `chapt04/transform/transform.py`. The *curriculum* side deliberately differs: the course's `matrix_stack` plans a `rotate_around_axis` that is a decomposition into axis-aligned rotations |
| `m3dTransformVector3` | `transform_vector3` — `chapt04/transform/transform.py` |
| `m3dMakePlanarShadowMatrix` | `make_planar_shadow_matrix` (with the sign fix) — `chapt01/block/Block.py` |
| GLUT menus → imgui | `chapt03/star/star.py`, `chapt03/triangle/triangle.py` |
| NURBS / tessellation | PyOpenGL's `GLU.gluNurbsCurve`/`gluNurbsSurface` auto-derive sizes from numpy shapes; `gluNewTess` + callbacks — `chapt10/` |

Helpers stay **inlined per demo** (not shared) so each port reads
top-to-bottom — the deliberate exception is `_primitives.py`'s precomputed
tessellations and `_common.py`'s window/UI machinery.

## 4. State of the tree (measured 2026-07-30, carried over 2026-11-24)

~101 demo `.py` files + `_common.py`, `_geometry.py` and `_primitives.py`. Per chapter:
chapt01:1, 02:3, 03:12, 04:8, 05:9, 06:6, 07:4, 08:4, 09:6, 10:9, 11:7,
12:3, 13:1, 14:1, 15:1, 16:2, 17:5, 18:6, 19:7, 20:4, 21:2, 22:1.

- **Stub status:** chapt19 is mixed — `GLView` and `RThread` are
  print-a-notice stubs (Win32 MFC / WGL threading), `Text2D`/`Text3D` redone
  via imgui, `GLRect`/`fscreen`/`SphereWorld32` real ports. **chapt20: all 4
  are stubs** (deprecated Apple Carbon/Cocoa). **chapt22: the single
  `ES_example` is a stub** (GL ES). Everything else is a real port.
- **Adoption:** 95 files `import _common`; 30 use `_primitives`; 12 demos
  carry a `shaders/` subfolder.
- **Camera wiring:** `_common` now carries the full walk-around/orbit
  `Camera` (the course repository's `notable-subsystems.md` §4b), but only the canary
  (`chapt08/sphereworld`) is wired to it — the other 3D ports still have
  per-demo camera code. That migration is `tasks/ports-ux-pass.md` Phase 2;
  read `tasks/archive/2026/04/28/postmortem-phase2-attempt-1.md` before any
  bulk attempt.
- **None hardware-verified except what the maintainer has run** — the first-run risks
  (camera sign, Rodrigues transpose, etc.) are in
  `tasks/archive/2026/11/25/superbible-full-port.md`.
