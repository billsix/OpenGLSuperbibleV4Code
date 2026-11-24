#!/usr/bin/env bash
set -e
cd /superbible4/
# The Python port's virtual environment (ruff, ty, python with every pinned dependency).
[ -f /venv/bin/activate ] && source /venv/bin/activate
exec bash "$@"
