#!/usr/bin/env bash
#
# Build every demo that has a Linux Makefile, in a scratch COPY of the tree so the checkout stays clean (the
# Makefiles write the binary next to the Makefile). Run inside the container:
#   make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/build_linux_demos.sh
# Writes data/linux-build.tsv: chapter, demo, status (ok/fail), seconds, first error line.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
scratch="${SCRATCH:-$repo/build/sb4}"
jobs="${JOBS:-$(nproc)}"
rm -rf "$scratch"
mkdir -p "$scratch"
cp -r "$repo/examples" "$repo/contrib" "$scratch"/
cd "$scratch/examples/projects/linux" || exit 1
build_one() {
    dir="$1"
    start=$(date +%s)
    log="$scratch/logs/${dir//\//_}.log"
    if make -C "$dir" >"$log" 2>&1; then status=ok; else status=fail; fi
    secs=$(( $(date +%s) - start ))
    err=$(grep -m1 -E "error|Error|undefined reference|No such file" "$log" | tr '\t' ' ' | cut -c1-200)
    printf '%s\t%s\t%s\t%s\t%s\n' "${dir%%/*}" "${dir#*/}" "$status" "$secs" "$err"
}
export -f build_one
export scratch
mkdir -p "$scratch/logs"
find chapt* -mindepth 2 -maxdepth 2 -name Makefile -printf '%h\n' | sort \
    | xargs -P "$jobs" -I{} bash -c 'build_one {}' > "$scratch/linux-build.raw"
{ printf 'chapter\tdemo\tstatus\tseconds\tfirst_error\n'; sort "$scratch/linux-build.raw"; } > "$here/data/linux-build.tsv"
cp -r "$scratch/logs" "$here/data/linux-build-logs" 2>/dev/null || true
echo "built: $(grep -c $'\tok\t' "$here/data/linux-build.tsv") ok, $(grep -c $'\tfail\t' "$here/data/linux-build.tsv") failed"
