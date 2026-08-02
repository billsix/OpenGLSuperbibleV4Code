# Chapter & demo inventory (the jump table)

**Reference doc** — every demo in `examples/src/`, what it teaches, and where. Use it to find
the C++ original of an mvp Python port. Verified against source 2026-08-02. Sibling docs:
`architecture-overview.md`, `gltools-framework.md`, `build-and-imgui-fork.md`,
`chapt18-advanced-buffers.md` (ch18 is its own deep-dive).

**Pipeline:** **ch01–14 are all fixed-function / immediate-mode** (verified: no
`glUseProgram`/`glCreateShader` in ch01–06, 07–12; ch13 occquery + ch14 shadowmap are FF too).
**GLSL starts at ch15**; ch15–17 are shader-based. **ch18** is mixed (see its doc). **ch19–22**
are platform-integration chapters, all FF, mostly non-GLUT/non-portable.

**Standard skeleton (all GLUT demos):** `SetupRC()` (init, *not* a callback, called from `main`)
+ `glutDisplayFunc(RenderScene)`, `glutReshapeFunc(ChangeSize)`, and usually
`glutSpecialFunc(SpecialKeys)` / `glutKeyboardFunc(KeyPressFunc)` / `glutTimerFunc(TimerFunction)`.
Only **bounce, ambient, pyramid, shaders** add Dear ImGui callbacks.

Path prefix for all: `examples/src/`.

## Ch01 — first program
- **block** — textured lit 3D block on a floor; the complete first program · `chapt01/block/Block.cpp` (lighting `SetupRC:243`, TGA textures).

## Ch02 — basics / animation
- **simple** — minimal GLUT clear · `chapt02/simple/simple.cpp:11`.
- **glrect** — a rectangle + 2D ortho with aspect correction · `chapt02/glrect/glrect.cpp:51`.
- **bounce** — timer animation (bouncing rect) · `chapt02/bounce/bounce.cpp:94`. **[ImGui]**

## Ch03 — primitives / raster ops
- **points** `:30`, **pointsz** (glPointSize) `:49`, **lines** `:30`, **linesw** (glLineWidth) `:38`,
  **lstrips** (GL_LINE_STRIP) `:30`, **lstipple** (dashed) `:34`, **triangle** (cull/depth/polygonmode)
  `:53`, **star** (polygon modes) `:60`, **pstipple** (polygon stipple) `:73`, **scissor**
  (scissor test) `:17`, **stencil** (stencil mask) `:33`, **single** (single-buffered anim) `:21`.
  All in `chapt03/<demo>/<demo>.cpp`.

## Ch04 — transforms / viewing
- **atom** `:29` / **atom2** `:32` — nested modelview push/pop. **ortho** (ortho jet) `:40` /
  **perspect** (gluPerspective jet) `:28`. **solar** — sun/earth/moon hierarchy `:36`. **transform**
  (manual torus matrix) `:32` / **transformgl** (`gltDrawTorus`) `:33`. **sphereworld** — navigable
  sphere field, GLFrame camera `:22`.

## Ch05 — color / materials / lighting
- **triangle** (Gouraud) `:17`, **ccube** (color cube) `:23`, **jet** (flat/unlit) `:26`, **litjet**
  (diffuse + normals) `:29`, **shinyjet** (specular) `:29`, **ambient** `:150` **[ImGui]**, **spot**
  (spotlight) `:76`, **sphereworld** (lit) `:33`, **shadow** (`m3dMakePlanarShadowMatrix`) `:324`.

## Ch06 — blending / buffer effects
- **smoother** (AA via blend) `:33`, **fogged** (depth fog) `:44`, **motionblur** (accumulation
  buffer: `glAccum`) `:117`, **multisample** (`GL_MULTISAMPLE_ARB`) `:33`, **reflection** (stencil
  mirror floor) `:108`, **sphereworld** (multisample+fog+stencil capstone) `:36`.

## Ch07 — imaging / raster (all 2D)
- **bitmaps** (`glBitmap`) `:67`, **imageload** (`glDrawPixels` a TGA) `:41`, **imaging**
  (`glPixelZoom`) `:96`, **operations** (`glPixelTransfer` channel/luminance/invert) `:80`.

## Ch08 — texture mapping
- **pyramid** (2D texture, filter menu) `:85` **[ImGui]**, **sphereworld** (planar shadows + stencil)
  `:74`, **toon** (1D cel-shading texture, L·N) `:116`, **tunnel** (mipmaps `gluBuild2DMipmaps`) `:90`.

## Ch09 — advanced texturing
- **anisotropic** (`GL_TEXTURE_MAX_ANISOTROPY_EXT`) `:60`, **cubemap** (reflection map) `:59`,
  **multitexture** (base × cube reflection) `:87`, **pointsprites** (`GL_POINT_SPRITE`) `:88`,
  **sphereworld** (`GL_SEPARATE_SPECULAR_COLOR`) `:71`, **texgen** (object/eye-linear, sphere-map) `:28`.

## Ch10 — curves / surfaces / quadrics / tessellation
- **axes3d** (`gltDrawUnitAxes`) `:99`, **bez3d** (Bezier surface, evaluators) `:47`, **bezier**
  (Bezier curve) `:39`, **bezlit** (lit Bezier, `GL_AUTO_NORMAL`) `:47`, **florida** (GLU tessellator)
  `:89`, **nurbc** (NURBS curve) `:72`, **nurbs** (NURBS surface) `:95`, **nurbt** (trimmed NURBS)
  `:107`, **snowman** (GLU quadrics) `:107`.

## Ch11 — vertex arrays / VBO / models
- **cubedx** (indexed client arrays, `glDrawElements`) `:52`, **sphereworld** (stencil reflection +
  shadows) `:74`, **starrynight** (`glDrawArrays` + point sprites) `:106`, **thunderbird** (F-16,
  immediate-mode w/ index lookups; +`body.cpp`/`glass.cpp`) `:37`, **thundergl** (F-16 via
  `CTriangleMesh`) `:325`, **vbo** (same via `CVBOMesh`) `chapt11/vbo/thundergl.cpp:28`.

## Ch12 — selection & feedback (picking)
- **moons** (hierarchical name-stack picking) `:154`, **planets** (flat picking) `:141`, **select**
  (selection + feedback mode) `:174`.

## Ch13 — `occquery` — occlusion queries (`glBeginQuery(GL_SAMPLES_PASSED)`) · `chapt13/occquery/occquery.cpp:108`. FF.

## Ch14 — `shadowmap` — depth-texture shadow mapping (`glCopyTexImage2D(…GL_DEPTH_COMPONENT…)`, `GL_TEXTURE_COMPARE_MODE`, `glTexGen`) · `chapt14/shadowmap/shadowmap.cpp:134`. FF.

## Ch15 — `shaders` — **first GLSL**: full compile/link pipeline (`glCreateShader`→…→`glUseProgram`) · `chapt15/shaders/shaders.cpp:332`. **[GLSL, ImGui, timer]**

## Ch16 — GLSL (vertex)
- **vertexblend** — vertex skinning, custom `weight` attrib (`glVertexAttrib1f`) · `chapt16/vertexblend/vertexblend.cpp:189`. **[GLSL]**
- **vertexshaders** — gallery of 9 vertex-shader effects (`#define SIMPLE…PTSIZE`) · `chapt16/vertexshaders/vertexshaders.cpp:405`. **[GLSL]** *(the `3lights.vs`/`sepspec.vs`/`specular.vs` half-angle fix is a fork commit — see build doc)*

## Ch17 — GLSL (fragment / combined)
- **bumpmap** (tangent-space normal mapping) `:570`, **fragmentshaders** (grayscale/sepia/heat/fog/invert)
  `:369`, **imageproc** (convolution kernels: blur/sharpen/sobel/…) `:246`, **lighting** (per-pixel
  diffuse/specular/3-lights) `:311`, **proctex** (procedural checker/beachball/toyball) `:262`. All
  `chapt17/<demo>/<demo>.cpp`. **[GLSL]**

## Ch18 — advanced buffers & textures → **see `chapt18-advanced-buffers.md`**
`fbodrawbuffers`, `fboenvmap`, `fboshadowmap`, `hdrbloom` (all FBO+GLSL), **pixbufobj** (FF, PBO/
motion-blur — the current debugging focus), **texfloat** (float texture + tone-map fragment shader).

## Ch19 — OpenGL on Windows (WGL, MSVC-only, `WinMain`/`WndProc`, no GLUT)
- **GLRect** (WGL bootstrap) `:137`, **GLView** (GL in an MFC window) `:212`, **RThread** (render
  thread, `_beginthread`) `:308`, **SphereWorld32** (WGL_ARB_pixel_format, MSAA, vsync, fullscreen)
  `:907`, **Text2D** (`wglUseFontBitmaps`) `:87`, **Text3D** (`wglUseFontOutlines`) `:98`, **fscreen**
  (`ChangeDisplaySettings`) `:135`. All Win32-only.

## Ch20 — OpenGL on macOS (Apple, Xcode-only) — shared scene `thundergl.cpp` (cube-map reflective thunderbird)
- **CarbonGL** (Carbon+AGL) `main.cpp:41`, **CarbonGLFonts** (`aglUseFont`) `:69`, **CocoGL**
  (Cocoa `NSOpenGLView`, Obj-C) `ThunderGLView.m:42`, **FullScreen** (CGDisplay + `aglSetFullScreen`)
  `main.cpp:93`. Carbon ones use deprecated APIs (won't build on modern macOS).

## Ch21 — OpenGL on Linux (X11/GLX)
- **GLXBasics** (raw GLX + own X event loop, no GLUT) · `chapt21/GLXBasics/GLXBasics.c:79`.
- **fonts** (`glXUseXFont`; **the only GLUT demo in ch19–22**) · `chapt21/fonts/font.c:53`.

## Ch22 — OpenGL ES (EGL)
- **ES_example** — ES 1.x via EGL + client vertex arrays · `chapt22/ES_example/ES_example.c:75`.
  **Non-buildable as-is** — needs the Rasteroid Windows ES emulator (`chapt22/ReadMe.txt`).
