#!/usr/bin/env bash
#
# The real source delta between the verbatim upstream import (e802274) and HEAD: format both trees with the same
# clang-format style (after stripping carriage returns), then diff, so formatting churn drops out and what is left
# is the maintainer's behavior and portability changes. Run in the container:
#   make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/semantic_delta.sh
# Writes data/semantic-delta.stat and data/semantic-delta.patch (files that differ after normalization).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
work="$repo/build/semantic"
rm -rf "$work"; mkdir -p "$work/orig" "$work/head"
git -C "$repo" archive e802274 examples/src | tar -x -C "$work/orig"
git -C "$repo" archive HEAD examples/src | tar -x -C "$work/head"
norm() {
    find "$1/examples/src" \( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.vs' -o -name '*.fs' \) \
        -not -path '*openexr*' -not -name 'GLee.*' -print0 |
    while IFS= read -r -d '' f; do
        tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        case "$f" in *.vs|*.fs) ;; *) clang-format --style=Google -i "$f" 2>/dev/null ;; esac
    done
}
norm "$work/orig"; norm "$work/head"
cd "$work" || exit 1
diff -ruwB orig/examples/src head/examples/src > "$here/data/semantic-delta.patch"
diffstat_out=$(diff -rq -w orig/examples/src head/examples/src | grep -v "Only in" | wc -l)
diff -rq orig/examples/src head/examples/src | grep "^Only in" > "$here/data/semantic-delta.only-in" || true
{ echo "files differing after normalization: $diffstat_out"; grep -c '^[-+][^-+]' "$here/data/semantic-delta.patch" | sed 's/^/changed lines: /'; } | tee "$here/data/semantic-delta.stat"
