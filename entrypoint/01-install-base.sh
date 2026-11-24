#!/usr/bin/env bash
#
# 01-install-base.sh -- install the always-needed Fedora packages for this project: the C/C++ toolchain, the
# GLUT/GL/GLU development headers every demo needs, cmake and ninja for the build-system work, clang-format
# for the formatting gate, python/git for the audit scripts, and uv for the Python port's virtual environment. One
# package group per script, no options;
# the same packages during `podman build` or on a bare Fedora host.
set -uo pipefail

if ! command -v dnf >/dev/null 2>&1; then
    echo "01-install-base.sh: needs 'dnf' (this installs Fedora packages), not found." >&2
    echo "Run on a Fedora host/guest, or inside the project's Fedora-based image." >&2
    exit 1
fi

status=0
dnf upgrade -y || status=1

# --skip-unavailable: skip a package missing from the enabled repos rather than failing the whole install.
dnf install -y --skip-unavailable \
    OpenEXR-devel \
    clang \
    clang-tools-extra \
    cmake \
    file \
    freeglut-devel \
    g++ \
    gcc \
    gdb \
    git \
    glfw-devel \
    libX11-devel \
    libXi-devel \
    libXmu-devel \
    make \
    mesa-libGL-devel \
    mesa-libGLU-devel \
    nano \
    ninja-build \
    python3 \
    ripgrep \
    SDL2-devel \
    tmux \
    uv \
    which || status=1

# Pinentry for signing commits through GPG_TTY; its own line so a missing package does not fail the group above.
dnf install -y pinentry || status=1

exit $status
