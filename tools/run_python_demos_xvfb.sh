#!/usr/bin/env bash
#
# Start every Python demo under Xvfb with Mesa's software renderer, let it run a few seconds, capture the screen,
# and record whether it stayed alive and drew something. The Python twin of run_cmake_demos_xvfb.sh. Run inside the
# container:   make shell-exec SCRIPT=tools/run_python_demos_xvfb.sh      (ONLY=chapt01 limits it; SECS=5 per demo)
# Writes build/python-run.tsv and build/python-shots/: chapter, demo, result (alive/exited/crashed), exit code,
# distinct colours in the capture, stderr first line. "alive" = still running when the timeout fired.
set -uo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
secs="${SECS:-5}"
export LIBGL_ALWAYS_SOFTWARE=1
export DISPLAY=:98
unset WAYLAND_DISPLAY
Xvfb :98 -screen 0 800x600x24 +extension GLX >/dev/null 2>&1 &
xvfb=$!
sleep 2
if command -v openbox >/dev/null; then openbox >/dev/null 2>&1 & wm=$!; sleep 1; fi
mkdir -p "$repo/build/python-shots"
out="$repo/build/python-run.tsv"
printf 'chapter\tdemo\tresult\texit\tcolours\tstderr\n' > "$out"
cd "$repo/python" || exit 1
for dir in $(find chapt* -mindepth 1 -maxdepth 1 -type d ! -name __pycache__ | sort); do
    case "$dir" in *"${ONLY:-}"*) ;; *) continue ;; esac
    chapter="${dir%%/*}"; demo="${dir#*/}"
    shot="$repo/build/python-shots/$chapter-$demo.png"
    (timeout "$secs" "$repo/tools/run_python_demo.sh" "$dir" >/dev/null 2>"$repo/build/python-err.txt") &
    pid=$!
    sleep $(( secs - 2 ))
    import -window root "$shot" 2>/dev/null
    wait "$pid"; code=$?
    colours=$(identify -format %k "$shot" 2>/dev/null || echo 0)
    case "$code" in
        124) result=alive ;;
        0) result=exited ;;
        *) result=crashed ;;
    esac
    err=$(tail -1 "$repo/build/python-err.txt" | tr '\t' ' ' | cut -c1-160)
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$chapter" "$demo" "$result" "$code" "$colours" "$err" >> "$out"
done
kill "${wm:-0}" "$xvfb" 2>/dev/null
echo "run table: $(grep -c $'\talive\t' "$out") alive of $(($(wc -l < "$out") - 1))"
