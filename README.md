# OpenGL SuperBible 4th edition, example code

The book's example programs (chapters 1 to 22), built with CMake. The C and C++ stay as the book has them
(GLUT callbacks, the GLTools 4th-edition library, the GLee loader); formatting is Google style (`.clang-format`).

## Build

```sh
# [LINUX] needs cmake, a C/C++ compiler, freeglut, Mesa and GLU development packages (Fedora: freeglut-devel mesa-libGLU-devel)
cmake -B build/cmake && cmake --build build/cmake
build/cmake/bin/chapt01/block/block

# [MACOS] system GLUT framework
cmake -B build/cmake && cmake --build build/cmake

# [WINDOWS, Visual Studio 2022] freeglut is downloaded and built by CMake (needs network on first configure)
cmake -B build/cmake && cmake --build build/cmake --config Release
```

Each demo lands in `build/cmake/bin/<chapter>/<demo>/` with its texture and shader files beside it, so run it from
that directory. Options: `-DSB4_FETCH_FREEGLUT=ON` builds freeglut from source on any platform;
`-DSB4_LOADER=GLEE` is the extension loader (the only one implemented).

## Container (Linux, no host packages)

```sh
make image                                   # [HOST] Fedora image with the toolchain, Mesa and Xvfb
make shell-exec CMD='cmake -B build/cmake -G Ninja && cmake --build build/cmake'
make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/run_cmake_demos_xvfb.sh   # run every demo headless
make format                                  # clang-format the first-party sources
```

## Which demos build

Every chapter 1 to 18 and chapter 21 demo that had a Linux Makefile. `chapt18/texfloat` is built only when OpenEXR
is installed. Chapters 19 and 20 (Win32 and Cocoa programs), chapter 22 and `chapt10/bezier` (no Makefile) are not
in the CMake build. The older per-platform trees under `examples/projects/` remain until the CMake build has been
verified on macOS and Windows.

Where things stand and why: `tasks/cmake-crossplatform-build.md`, `tasks/reference/audit-summary.md`.
