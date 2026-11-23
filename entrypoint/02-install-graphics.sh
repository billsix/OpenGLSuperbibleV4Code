#!/usr/bin/env bash
#
# 02-install-graphics.sh -- a software OpenGL stack and a virtual X server, so every demo can be started
# without a display (llvmpipe through Mesa, Xvfb) and its window captured. No options.
set -uo pipefail

dnf install -y --skip-unavailable \
    ImageMagick \
    mesa-dri-drivers \
    mesa-demos \
    xdpyinfo \
    xwd \
    xorg-x11-server-Xvfb \
    xdotool \
    twm
