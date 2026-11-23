#!/usr/bin/env bash
#
# Formatting state of the first-party C/C++ sources: for each file, its line endings, whether it uses tabs, and
# whether clang-format with each candidate style would change it. Run in the container:
#   make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/formatting_audit.sh
# Writes data/formatting.tsv.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
cd "$repo"
out="$here/data/formatting.tsv"
printf 'file\tcrlf\ttabs\tgoogle_diff\tllvm_diff\tmozilla_diff\n' > "$out"
while IFS= read -r -d '' f; do
    crlf=$(grep -c $'\r' "$f")
    tabs=$(grep -c $'\t' "$f")
    row="$f\t$crlf\t$tabs"
    for style in Google LLVM Mozilla; do
        n=$(clang-format --style="$style" "$f" 2>/dev/null | diff -q - "$f" >/dev/null && echo 0 || echo 1)
        row="$row\t$n"
    done
    printf "$row\n" >> "$out"
done < <(find examples/src contrib/imgui \( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 | sort -z)
echo "files: $(($(wc -l < "$out") - 1))"
