#!/usr/bin/env bash
set -e
cd /superbible4/
# The Python port's virtual environment (ruff, ty, python with every pinned dependency).
# Keep the venv's name out of the prompt (.extrabashrc sets the prompt).
export VIRTUAL_ENV_DISABLE_PROMPT=1
[ -f /venv/bin/activate ] && source /venv/bin/activate
exec bash "$@"
