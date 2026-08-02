# Chapter 18 — advanced buffers & textures (deep dive)

**Reference doc** — the chapter the mvp Python ports are actively being debugged against.
Verified against source 2026-08-02. Sibling docs: `architecture-overview.md`,
`gltools-framework.md`, `build-and-imgui-fork.md`, `chapter-demo-inventory.md`.

**Six demos** in `examples/src/chapt18/`: `fbodrawbuffers`, `fboenvmap`, `fboshadowmap`,
`hdrbloom`, `pixbufobj`, `texfloat`. (There is **no `hdr_imaging`** dir — the EXR/HDR demo
here is `texfloat`.) All fixed-function GL + GLUT. All register `RenderScene` as both display
**and idle** (continuous animation) **except `fboshadowmap`** (display only — static until input).

---

## pixbufobj — the "one image vs. multiple spinning images" answer

**Defaults (verified):** `usePBOs = GL_FALSE` (`pixbufobj.cpp:28`), `useMotionBlur = GL_TRUE`
(`:29`), `angleIncrement = 1.0` (`:35`).

**The C++ draws exactly ONE quad per frame** — a single `glBegin(GL_QUADS)…glEnd()`
(`pixbufobj.cpp:71-80`, verified: only one `glBegin(GL_QUADS)` in the file), full-screen. That
quad is drawn with **3 texture units additively blended** (`GL_ADD`, `:202`). By default the
user sees **one rotating `reservoir.tga` with a motion-blur "comet" trail** — NOT three
independent spinning copies.

**How the trail works (the 3-frame feedback ring):**
- Rotation is applied to **`GL_TEXTURE0` only** and **accumulates** — `glActiveTexture(GL_TEXTURE0)`
  then translate·rotate·translate (`:56-59`; the comment literally says "for unit 0"); identity
  is loaded on unit 0 **once** at setup (`:210`), never per frame. Units 1 & 2 keep an
  **identity** texture matrix.
- Each frame (`:83-128`): read back the composited frame (`glReadPixels`) → attenuate it
  (`>>=2`, ÷4) → re-upload as the texture on units 1/2 (`2+lastFrame`, `2+frameBeforeThat`).
  Those units show *previous output* (rotation already baked in), not the reservoir at other
  angles. A 3-frame ring (`currentFrame`/`lastFrame`/`frameBeforeThat`, `:51-53`).
- `!useMotionBlur` branch (`:61-67`, `:205-208`): copies unit-0's rotation to unit 1, binds unit
  1 to the reservoir (texture 1), disables unit 2 → a single crisp rotating quad.

**Why the mvp Python port shows MULTIPLE spinning images (hypotheses to check in the diff):**
the additive units 1/2 become three discrete rotated copies of the reservoir if the port
(a) applies the rotating texcoord transform to more than unit 0, (b) binds the reservoir to
units 1/2 instead of the fed-back attenuated frames, or (c) omits the readback→attenuate→
re-upload feedback so units 1/2 show a static/rotating reservoir.

**Outcome of the 2026-08-02 investigation:** the port's draw-time GL state was proven
*identical* to the C++ above (units, textures, rotation, `CLAMP_TO_BORDER`, blend, viewport),
and under software GL (llvmpipe) the port renders **one clean rotating album** (corners
pixel-verified black) — the bug does **not** reproduce headless, so it appears
hardware/driver-specific to the reporter's Mesa/GPU (or interactive state). Tracked with all
findings in the mvp repo (github.com/billsix/modelviewprojection)
`tasks/pixbufobj-port-fidelity.md`; the port's separate PBO-readback crash was fixed there.

**Textures:** no `glGenTextures` (verified 0) — texture object names 1,2,3,4 used literally
(`glBindTexture(GL_TEXTURE_2D, <int>)`). Object 1 = current frame (reservoir at 50% brightness),
objects 2/3/4 = ring-buffer history (25% brightness). All `GL_LINEAR` + `GL_CLAMP_TO_BORDER`.

**PBO path (opt-in):** buffer names 1,2,3 used **literally without `glGenBuffers`** (`:84` etc.).
`glReadPixels`→PBO (`:85`), `glMapBuffer(GL_PIXEL_UNPACK_BUFFER…)` to attenuate (`:99-110`),
`glTexImage2D` from the bound unpack buffer (`:118,123`). *(This literal-name pattern is exactly
what the mvp port's item-11 fix replaced with `glGenBuffers` — see the mvp
`ports-pbo-floattex-runtime-crashes` task.)*

## texfloat — float texture setup (the exact recipe)

Renders one full-screen quad showing an OpenEXR HDR image, tone-mapped by a fragment shader.
Defaults: shader **TRIVIAL** (`:46`, `rgb/(rgb+1)`), image **Blobbies.exr** (`:398`), window
1024×768.

**Float-texture creation (`texfloat.cpp:335-342`, verified):**
- internal format **`GL_RGB16F_ARB`** (half-float), format `GL_RGB`, type `GL_FLOAT` (CPU data
  is 32-bit float).
- **`glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, 1)`** ON, min filter
  `GL_LINEAR_MIPMAP_LINEAR`.
- **No `glGenTextures` and no `glBindTexture`** (verified 0/0) — uses the **default texture
  object (name 0)**. A port must replicate binding to the default 2D texture (or generate/bind one).
- EXR loaded via OpenEXR `RgbaInputFile` (`:285`), **flipped vertically** (`:323`), padded to POT
  if NPOT unsupported. `fTexels` is also the CPU array the IRIS/WHITEBALANCE shaders scan — there
  is **no `glReadPixels`** in this demo (despite a misleading comment).

*(Relevant to the mvp texfloat segfault: the C++ sets `GL_GENERATE_MIPMAP` before the
`RGB16F`/`GL_FLOAT` upload on the default texture — the mvp instrumentation traces exactly this
call sequence.)*

## The other four (FBO family — briefer)

- **hdrbloom** — spinning HDR sphere with bloom + temporal afterglow. The **only chapt18 demo
  that calls `glGenBuffers`** (1 PBO for the afterglow feedback, `:671`). 7 textures
  (`glGenTextures(7)` `:511`): 2×`RGB16F` (scene + bright pass), 4×`RGBA8` blur LODs, 1×`RGB8`
  afterglow. 5 FBOs; FBO0 has 2 color attachments (`glDrawBuffers(2,…)`). Afterglow = read
  window→PBO (`glReadPixels`, `:496`) then upload PBO→texture next frame (`:315`).
- **fbodrawbuffers** — textured room + spinning models; one shader writes **4 filtered outputs
  simultaneously** to 4 render targets (`glDrawBuffers(…,{ATTACH0..3})`, `:341`), tiled back as
  quadrants. `useDrawBuffers`/`doProcessing` default ON. `glGenTextures` at `:435,:475`.
- **fboenvmap** — reflective (cube-map) teapot reflecting the room; regenerates the cube map
  each frame from 6 views. **`useFBO = GL_FALSE`** default → builds the cube map with
  `glCopyTexImage2D` (`:260`); FBO path opt-in. Uses `glGetTexImage` in show-envmap mode.
- **fboshadowmap** — depth-texture projected shadows. **`useFBO = GL_FALSE`** default → shadow
  map via `glCopyTexImage2D(…GL_DEPTH_COMPONENT…)` (`:141`). Depth-compare via
  `GL_COMPARE_R_TO_TEXTURE` + eye-linear texgen. **Only demo with no idle callback** — regenerates
  the shadow map only when the light moves.

## Cross-demo notes for port work

- Only `hdrbloom` uses `glGenBuffers`; `pixbufobj` uses PBO names 1–3 literally.
- `fboenvmap`/`fboshadowmap` build their maps with `glCopyTexImage2D` by default (FBO opt-in).
- `fboshadowmap` alone has no idle func.
- The mvp port cross-references live in the mvp repo's `ports/openglsuperbiblev4/chapt18/` and the
  `ports-pbo-floattex-runtime-crashes` task.
