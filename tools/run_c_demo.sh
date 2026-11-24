#!/usr/bin/env bash
#
# Build and run one C++ demo on X11: tools/run_c_demo.sh chapt01/block
# Builds only that CMake target into build/cmake-ctr (a container-only tree: a host build in build/cmake has a
# different CMake cache), then runs it from its own directory with WAYLAND_DISPLAY and XDG_SESSION_TYPE unset, because the demos'
# GLee loader goes through GLX (X11 or XWayland). Run inside the container (make run-c DEMO=chapt01/block).
set -uo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
demo="${1:?usage: run_c_demo.sh <chapter>/<demo>, e.g. chapt01/block}"
chapter="${demo%%/*}"
name="${demo#*/}"
build="$repo/build/cmake-ctr"
cmake -S "$repo" -B "$build" >/dev/null || exit 1
cmake --build "$build" --target "${chapter}_${name}" -j"$(nproc)" || exit 1
cd "$build/bin/$chapter/$name" || exit 1
exec env -u WAYLAND_DISPLAY -u XDG_SESSION_TYPE "./$name"
