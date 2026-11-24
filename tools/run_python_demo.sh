#!/usr/bin/env bash
#
# Run one demo of the Python port: tools/run_python_demo.sh chapt01/block
# Finds python/<chapter>/<demo>/<file>.py: the file named like the directory (ignoring case: block -> Block.py),
# or the only .py file there. Run inside the container (make run DEMO=chapt01/block), where /venv is active.
set -uo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
demo="${1:?usage: run_python_demo.sh <chapter>/<demo>, e.g. chapt01/block}"
dir="$repo/python/$demo"
[ -d "$dir" ] || { echo "no such demo: $demo (make list shows them)" >&2; exit 2; }
file=""
for candidate in "$dir"/*.py; do
    name="$(basename "$candidate" .py)"
    if [ "${name,,}" = "$(basename "$demo")" ] || [ "$(ls "$dir"/*.py | wc -l)" = 1 ]; then file="$candidate"; break; fi
done
[ -n "$file" ] || { echo "no .py file in $dir matches the demo name" >&2; exit 2; }
exec python "$file"
