# The GLTools shared framework (`examples/src/shared/`)

**Reference doc** — the library every demo builds on. Verified against source 2026-08-02.
Sibling docs: `architecture-overview.md`, `build-and-imgui-fork.md`, `chapter-demo-inventory.md`,
`chapt18-advanced-buffers.md`.

**Edition marker (verified):** this is unambiguously **4th-edition GLTools** — immediate-mode
`gltDraw*` helpers + `CVBOMesh`, ARB shader entry points, GLee for extension loading. The
5th-edition stack (`GLShaderManager`, `GLBatch`/`GLTriangleBatch`, `gltMake*`) is **absent**
repo-wide (grep confirmed empty). Don't expect 5th-ed APIs when comparing to anything.

## Live/dead verdict (the part that saves you time)

| File | Status | Evidence |
|---|---|---|
| `math3d.h`/`.cpp` | **LIVE (core)** | linked in every Makefile; 17 direct + universal transitive includes |
| `glframe.h` | **LIVE** | 28 includes; `GLFrame` used in 17 demos |
| `glfrustum.h` | **DEAD** | 0 includes (verified); calls a `m3d*f` API that **does not exist** here (only in a comment at `math3d.cpp:1024`) + case-wrong includes — a 5th-ed header orphaned in-tree; would not compile |
| `gltools.h`/`.cpp` | **LIVE (umbrella)** | 106 includes; `gltLoadTGA` in 27, `gltDrawTorus` in 12, `gltDrawSphere` in 6 |
| `GLee.c`/`.h` | **LIVE (universal)** | compiled into 86/88 Linux Makefiles; the extension loader |
| `TriangleMesh` | LIVE, marginal | 1 demo (`chapt11/thundergl`) |
| `VBOMesh` | **LIVE** | 5 demos |
| `stopwatch.h` | **LIVE** | 6 demos (animation timing) |
| `wglext.h` | LIVE, Win32-only | `#ifdef _WIN32` in `gltools.cpp`; compiled out elsewhere |
| `openexr-*/` | Vendored, single-consumer | only `chapt18/texfloat`; bundled libs for Win/Mac, **system** OpenEXR on Linux |

Also **present-but-unused**: `gltLoadShaderPair` / `bLoadShaderFile` in `gltools.cpp` — 0 demos
call them (verified); GLSL demos load shaders inline instead. Documented API, dead within the
sample set.

## `math3d.h` / `math3d.cpp` — the math core

C-array types, column-major, OpenGL-style. Vectors `M3DVector{2,3,4}{f,d}` (`math3d.h:20-27`),
matrices `M3DMatrix33{f,d}` (9) / `M3DMatrix44{f,d}` (16) (`:33-46`).

- **Inline vector ops (header):** load/copy/add/subtract/scale (`:95-265`); **cross**
  `m3dCrossProduct` `:273`; **dot** `m3dDotProduct` `:290`; angle `:301`; length/normalize
  `m3dNormalizeVector` `:338`; distance-to-plane `:702`.
- **Inline matrix ops (header):** copy/get/set column & row `:386-492`; `m3dTransformVector3/4`
  `:541-579`; `m3dRotateVector` `:583`; translation builders `:630-656`; transpose `:672-685`.
- **Out-of-line (`math3d.cpp`):** `m3dLoadIdentity33/44` `:14`; **matrix multiply**
  `m3dMatrixMultiply44/33` `:84-143`; **rotation builders** (Rodrigues) `m3dRotationMatrix33/44`
  `:145-365`; **matrix inverse** `m3dInvertMatrix44` `:367-641`; `m3dProjectXY/XYZ` (gluProject
  replacements) `:702-761`; `m3dFindNormal` `:763`; `m3dGetPlaneEquation` `:807`; Catmull-Rom
  `:857`; `m3dRaySphereTest` `:914`; `m3dCalculateTangentBasis` (normal mapping) `:966`;
  **`m3dMakePlanarShadowMatrix` `:1026`** (the planar-shadow squash used by ch05/08 sphereworld).

**Latent internal inconsistencies (flagged, verify before relying):** `m3dCatmullRom` declared
(`:740`) vs `m3dCatmullRom3` defined (`math3d.cpp:857`); `m3dProjectXY` header vs cpp signatures
differ (`math3d.h:730` vs `math3d.cpp:702`); a `m3dMatrixMultiply` (no `44`) and a mis-suffixed
multiply exist (`math3d.cpp:96,127`). They compile only because callers use the correctly-named
overloads.

## `glframe.h` — the camera / actor frame (`GLFrame`)

An orthonormal reference frame (`glframe.h:13`): members `vOrigin`, `vForward` (-Z look),
`vUp` (+Y) (`:15-17`); the X axis is derived (`up × forward`), not stored. This is the core
placement abstraction (sphereworld camera, jet, etc.).

- Movement: `TranslateWorld/Local`, `MoveForward/Up/Right` (`:97-135`).
- **Matrix assembly:** `GetMatrix` `:138`; `GetCameraOrientation` (transposed, translation-free)
  `:169`; **`ApplyCameraTransform`** `:212` (`glMultMatrixf`+`glTranslatef`, the fast `gluLookAt`
  replacement); **`ApplyActorTransform`** `:236` (object placement).
- Rotations `RotateLocalX/Y/Z` `:246`; `Normalize` (re-orthonormalize) `:305`; `RotateWorld/Local`
  `:320-352`; conversions `LocalToWorld` `:359` / `WorldToLocal` `:380` (uses `m3dInvertMatrix44`).

## `gltools.h` / `gltools.cpp` — the umbrella utility header

`gltools.h` is the master include (106 demos) — brings in the platform GL/GLU/GLUT headers +
`GLee.h` (`:17-47`, per-platform blocks). `MAX_SHADER_LENGTH 8192` `:74`; endian swap helpers.

- **Geometry (immediate-mode `glBegin`/`glEnd`):** `gltDrawTorus` `gltools.cpp:180` (12 demos),
  `gltDrawSphere` `:227` (6), `gltDrawUnitAxes` `:114` (GLU-quadric RGB axis gizmo). These are
  the 4th-ed `gltDraw*` helpers — no `gltMake*`, no `GLBatch`.
- **Texture loader:** `gltLoadTGA` `:382` (8/24/32-bit TGA, no RLE) — the primary texture path,
  27 demos; `gltWriteTGA` `:298` (screenshot).
- **Shader helpers (present, unused):** `bLoadShaderFile` `:465`, `gltLoadShaderPair` `:506`
  (ARB entry points) — 0 callers.
- **Extension/version:** `gltGetOpenGLVersion` `:22`, `gltIsExtSupported` `:43`,
  `gltIsWGLExtSupported` (Win32) `:69`.

## `GLee.c` / `GLee.h` — extension loader (universal)

Third-party **GLee v5.21 © 2006 Ben Woodhouse** (elf-stone.com/glee.php). `GLee.h` ~12.5k lines
of extension/function-pointer decls; `GLee.c` ~18.5k lines of runtime `wglGetProcAddress`/
`glXGetProcAddress` loading; `GLeeInit()` `GLee.h:12481`. Pulled in via `gltools.h` and compiled
into 86/88 Linux demos — this is what lets 4th-ed demos call post-1.1 GL (VBOs, shaders, FBOs)
portably. There is no GLEW in this tree.

## Mesh classes & timing

- **`CTriangleMesh`** (`TriangleMesh.h:21`) — indexed-triangle container; `AddTriangle` dedups
  verts/normals/texcoords (ε=1e-6) building an index array; `Draw()` via client-side vertex
  arrays. Used by 1 demo (precursor to VBOMesh).
- **`CVBOMesh`** (`VBOMesh.h:31`) — same API/dedup, but `EndMesh()` uploads to **VBOs**
  (`glGenBuffers`/`glBufferData`, `VBOMesh.cpp:129-165`) and draws from GPU. 5 demos.
- **`CStopWatch`** (`stopwatch.h:24`) — high-res timer (`QueryPerformanceCounter` / `gettimeofday`).

## OpenEXR (vendored)

Full bundled **OpenEXR 1.4.0** with prebuilt Windows `.lib` + Mac `.a`. **Only
`chapt18/texfloat` uses it** (`#include <ImfRgbaFile.h>` `texfloat.cpp:8`, loads
`openexr-images/*.exr`). Nuance: the **Linux** Makefile links *system* OpenEXR
(`-I/usr/local/include/OpenEXR -lIlmImf -lIlmThread`), not these subtrees — the bundled libs
exist to satisfy the Windows/Mac projects that have no system package. See
`chapt18-advanced-buffers.md`.
