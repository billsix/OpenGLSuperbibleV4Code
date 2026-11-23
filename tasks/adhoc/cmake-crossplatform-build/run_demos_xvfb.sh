#!/usr/bin/env bash
#
# Start every demo built by build_linux_demos.sh under Xvfb with Mesa's software renderer, let it run a few
# seconds, capture the screen, and record whether it stayed alive and drew something. Run inside the container
# after the build:   make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/run_demos_xvfb.sh
# Writes data/linux-run.tsv: chapter, demo, result (alive/exited/crashed/no-binary), exit code, distinct
# colours in the capture, stderr first line. "alive" = still running when the timeout fired.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
scratch="${SCRATCH:-$repo/build/sb4}"
secs="${SECS:-5}"
export LIBGL_ALWAYS_SOFTWARE=1
export DISPLAY=:99
Xvfb :99 -screen 0 800x600x24 +extension GLX >/dev/null 2>&1 &
xvfb=$!
sleep 2
# A window manager: freeglut's glutSetWindowTitle asks the X server for EWMH atoms and dies with BadAtom
# without one.
if [ "${WM:-1}" = 1 ] && command -v twm >/dev/null; then twm >/dev/null 2>&1 & wm=$!; sleep 1; fi
mkdir -p "$here/data/shots"
out="$here/data/linux-run.tsv"
printf 'chapter\tdemo\tresult\texit\tcolours\tstderr\n' > "$out"
cd "$scratch/examples/projects/linux" || exit 1
for dir in $(find chapt* -mindepth 2 -maxdepth 2 -name Makefile -printf '%h\n' | sort); do
    chapter="${dir%%/*}"; demo="${dir#*/}"
    prog=""
    for candidate in $(find "$dir" -maxdepth 1 -type f -executable ! -name '*.o'); do
        if file -b "$candidate" | grep -q '^ELF'; then prog="$candidate"; break; fi
    done
    if [ -z "$prog" ]; then
        printf '%s\t%s\tno-binary\t-\t-\t\n' "$chapter" "$demo" >> "$out"
        continue
    fi
    (cd "$dir" && timeout "$secs" "./$(basename "$prog")" >/dev/null 2>"$scratch/err.txt") &
    pid=$!
    sleep $(( secs - 2 ))
    import -window root "$here/data/shots/$chapter-$demo.png" 2>/dev/null
    wait "$pid"; code=$?
    colours=$(identify -format %k "$here/data/shots/$chapter-$demo.png" 2>/dev/null || echo 0)
    case "$code" in
        124) result=alive ;;
        0) result=exited ;;
        *) result=crashed ;;
    esac
    err=$(head -1 "$scratch/err.txt" | tr '\t' ' ' | cut -c1-160)
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$chapter" "$demo" "$result" "$code" "$colours" "$err" >> "$out"
done
kill "${wm:-0}" "$xvfb" 2>/dev/null
echo "run table: $(grep -c $'\talive\t' "$out") alive of $(($(wc -l < "$out") - 1))"
