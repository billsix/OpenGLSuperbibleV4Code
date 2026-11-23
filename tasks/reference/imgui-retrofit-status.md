# Dear ImGui in four demos: did the retrofit succeed?

**Reference doc**, 2026-11-23 (audit, stage 1 of `tasks/cmake-crossplatform-build.md`). Measured on Linux in the
audit's container (Xvfb, Mesa software GL, freeglut 3.8); macOS and Windows were not available. Probe script:
`tasks/adhoc/cmake-crossplatform-build/imgui_probe.sh`; screenshots in its `data/imgui-shots/`.

## Short answer

**It works on Linux in three of the four demos, once the Makefile finds ImGui; the fourth does not build.** The
Linux Makefiles as committed cannot find ImGui at all (below), so on a fresh clone none of the four builds.

| demo | commit | backend | builds as committed | builds with `contrib/` where the Makefile looks | runs, draws ImGui | input reaches ImGui |
|---|---|---|---|---|---|---|
| `chapt02/bounce` | `498c5ca` (2019-11) | GLUT + OpenGL2 | no | yes | yes (Hello window and the ImGui demo window) | **yes**: three clicks on "Button" made `counter = 3` |
| `chapt05/ambient` | `acdbe02` (2020-03) | GLUT + OpenGL2 | no | yes | yes (the "Set Ambient Light" window) | not exercised decisively (the window is small and the pointer sweep did not hit a widget) |
| `chapt08/pyramid` | `3b6f3b3` (2020-03) | GLUT + OpenGL2 | no | yes | yes (combo boxes, slider) | **yes**: one click opened the "Texture Env Mode" combo list |
| `chapt15/shaders` | `d6defd8` (2020-04) | GLUT + **OpenGL3** | no | **no**: `imgui_impl_opengl3.h: Cannot detect OpenGL loader!` | not built | not built |

So the maintainer's doubt ("I don't remember if I succeeded") has this answer: bounce and pyramid are proved working
by clicks; ambient is very likely working (same wiring, window drawn); shaders never built on this tree. The commit
message of `d6defd8`, "The glut ones were failing", refers to GLUT's own menus and keyboard handling: that commit
added ImGui controls to `shaders`, which still also has a GLUT right-click menu (`glutCreateMenu`/`glutAttachMenu`).

## How ImGui is wired in

- Vendored version: **Dear ImGui 1.76 WIP** (`IMGUI_VERSION_NUM 17502`) in `contrib/imgui/` (17 files, added to this
  repository only in `c74bbd6`, 2025-12-06); backends `imgui_impl_glut.cpp`, `imgui_impl_opengl2.cpp` and
  `imgui_impl_opengl3.cpp`.
- In each demo's `main`: `ImGui::CreateContext()`, `ImGui_ImplGLUT_Init()`, then the **callbacks are installed by
  hand** (the body of `ImGui_ImplGLUT_InstallFuncs`, copied inline): `glutMotionFunc`, `glutPassiveMotionFunc`,
  `glutMouseWheelFunc`, `glutMouseFunc`, `glutKeyboardFunc`/`glutKeyboardUpFunc`, `glutSpecialFunc`/
  `glutSpecialUpFunc` all point at ImGui's handlers. The demo's own `ChangeSize` calls
  `ImGui_ImplGLUT_ReshapeFunc`; where the demo has its own key handling (`ambient`, `pyramid`: `SpecialKeys`;
  `shaders`: `KeyPressFunc`, `SpecialKeys`) the demo's handler forwards to ImGui's.
- Per frame: `ImGui_ImplOpenGL2_NewFrame()` (or `3`), `ImGui_ImplGLUT_NewFrame()`, widgets, `ImGui::Render()`,
  `ImGui_ImplOpenGL2_RenderDrawData(...)`, drawn after the scene inside `RenderScene`.
- So ImGui here is **fully callback-based**: it needs a backend that offers GLUT's callback model, which is also what
  the maintainer wants kept.

## Why the committed Makefiles cannot find ImGui

Every ImGui Makefile uses `../../../../../../contrib/imgui/` (**six** levels up from the demo). The demo directory
`examples/projects/linux/chapt02/bounce` is four levels below the repository root, so six levels up is the
directory *above* the repository. The Visual Studio project of `bounce` uses the same six-level path
(`..\..\..\..\..\..\contrib\imgui`). The paths were written when ImGui sat **beside** the repository, outside it;
`c74bbd6` ("add imgui, to fix build") vendored ImGui at `contrib/imgui/` inside it **without changing the paths**, so
the commit did not make a fresh clone build.

## Other states

- **Windows:** only `bounce` (v143, `nupengl.core`), `Ambient` (v143, freeglut NuGet package) and `Pyramid` (v142,
  `nupengl.core`) list the ImGui sources; the `shaders` Visual Studio project has no ImGui reference although its
  source includes `imgui.h`, so it cannot build there (`windows-build-history.md`).
- **macOS:** the four Xcode projects reference ImGui (`17d5297`, "added imgui files to the project. Inputs are not
  working though", 2020-02-01, was the first on `bounce`). Not testable by the audit; whether the inputs problem
  was fixed is the maintainer's to confirm with `chapt02/bounce`.
- The demos draw ImGui windows at a fixed position (60, 60), narrower than their content in 800x600 (`ambient`'s
  window shows `25!` for `255`): cosmetic.

## Recommendation for the build stage

Keep ImGui as the GUI layer (the maintainer allowed any GUI controls; it works). Pin the choice of backend to
whichever window/callback layer the build ends up on: with real GLUT or freeglut keep `imgui_impl_glut`; with a
GLFW- or SDL-backed GLUT shim either keep `imgui_impl_glut` (the shim exports the same `glut*Func` entry points) or
switch the four demos to `imgui_impl_glfw`/`imgui_impl_sdl2`. Either way: (1) fix the include path (one CMake
`target_include_directories` replaces six Makefiles, two project trees and four Xcode projects); (2) give `shaders` a
loader define so the OpenGL3 backend compiles (`IMGUI_IMPL_OPENGL_LOADER_CUSTOM` with GLee's header, or the
replacement loader); (3) decide whether the retrofitted demos keep their GLUT menus (only `shaders` has both).
