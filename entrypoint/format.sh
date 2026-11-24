#!/usr/bin/env bash
#
# Format the first-party C/C++ with clang-format (the demo sources, the shared GLTools library; the vendored
# GLee.c and contrib/ are left alone) and the Python port and tools with ruff (ruff.toml). Portable: runs in the container (source mounted at /superbible4) and on
# the host from anywhere. Exits nonzero if clang-format failed on any file.
if [ -d /superbible4/examples ]; then
    cd /superbible4
else
    root=$(git rev-parse --show-toplevel 2>/dev/null) && [ -n "$root" ] && cd "$root"
fi
status=0
while IFS= read -r -d '' file; do
    clang-format -i "$file" || status=1
done < <(find examples/src \( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
             -not -name 'GLee.*' -not -path '*openexr*' -print0)
# ruff is in the venv; every step runs and any failure is remembered, so one run reports all the red.
[ -f /venv/bin/activate ] && source /venv/bin/activate
ruff check python tools --fix || status=1
ruff format python tools || status=1
exit $status
