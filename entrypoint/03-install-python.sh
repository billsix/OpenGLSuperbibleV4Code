#!/usr/bin/env bash
#
# 03-install-python.sh -- create the Python virtual environment for the port and install its pinned dependencies.
# Every package goes into the venv (never the distro copies), constrained by the resolved lock file, so the venv
# scripts (ruff, ty, python) see exactly the packages that were pinned. Needs `uv` (01-install-base.sh installs it).
#
#     03-install-python.sh [requirements.txt [constraints.txt]]     VENV=/path overrides the default /venv
set -uo pipefail

venv="${VENV:-/venv}"
requirements="${1:-python/requirements.txt}"
constraints="${2:-python/constraints.txt}"

if ! command -v uv >/dev/null 2>&1; then
    echo "03-install-python.sh: needs 'uv' (installed by 01-install-base.sh), not found." >&2
    exit 1
fi

status=0
uv venv --quiet "$venv" || status=1
uv pip install --quiet --python "$venv/bin/python" -c "$constraints" -r "$requirements" || status=1
exit $status
