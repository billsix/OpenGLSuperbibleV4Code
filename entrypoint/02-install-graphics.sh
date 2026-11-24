#!/usr/bin/env bash
#
# 02-install-graphics.sh -- a software OpenGL stack and a virtual X server, so every demo can be started
# without a display (llvmpipe through Mesa, Xvfb) and its window captured, plus the Wayland and EGL client libraries
# the Python port's GLFW and PyOpenGL load. No options.
set -uo pipefail

dnf install -y --skip-unavailable \
    ImageMagick \
    libdecor \
    libwayland-client \
    libwayland-cursor \
    libwayland-egl \
    libxkbcommon \
    mesa-dri-drivers \
    mesa-libEGL \
    mesa-demos \
    xdpyinfo \
    xwd \
    xorg-x11-server-Xvfb \
    xdotool \
    openbox
