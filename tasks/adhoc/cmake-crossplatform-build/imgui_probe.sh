#!/usr/bin/env bash
#
# Probe the four ImGui retrofits (chapt02/bounce, chapt05/ambient, chapt08/pyramid, chapt15/shaders): build each
# with contrib/ placed where its Makefile looks for it (six directories above the demo, which is NOT where the
# repository keeps it), run it under Xvfb, capture the window, then move the pointer over the ImGui window and
# capture again. A changed capture means the pointer reached ImGui through imgui_impl_glut.
# Run in the container after build_linux_demos.sh:
#   make shell-exec SCRIPT=tasks/adhoc/cmake-crossplatform-build/imgui_probe.sh
# Writes data/imgui-probe.tsv and data/imgui-shots/.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
scratch="${SCRATCH:-$repo/build/sb4}"
rm -rf "$repo/build/contrib"
cp -r "$repo/contrib" "$repo/build/contrib"   # six levels above build/sb4/examples/projects/linux/<chapt>/<demo>
export LIBGL_ALWAYS_SOFTWARE=1 DISPLAY=:97
Xvfb :97 -screen 0 800x600x24 +extension GLX >/dev/null 2>&1 &
xvfb=$!
sleep 2
mkdir -p "$here/data/imgui-shots"
out="$here/data/imgui-probe.tsv"
printf 'demo\tbuild\trun\tcolours_before\tcolours_after_hover\tcapture_changed_after_hover\n' > "$out"
for d in chapt02/bounce chapt05/ambient chapt08/pyramid chapt15/shaders; do
    name="${d#*/}"
    dir="$scratch/examples/projects/linux/$d"
    rm -f "$dir/$name"
    if make -C "$dir" >"$scratch/logs/imgui-$name.log" 2>&1; then built=ok; else built=FAIL; fi
    prog=$(find "$dir" -maxdepth 1 -type f -executable | while read -r f; do file -b "$f" | grep -q '^ELF' && echo "$f" && break; done)
    if [ -z "$prog" ]; then printf '%s\t%s\tno-binary\t-\t-\t-\n' "$name" "$built" >> "$out"; continue; fi
    (cd "$dir" && timeout 9 "$prog" >/dev/null 2>&1) &
    pid=$!
    sleep 3
    import -window root "$here/data/imgui-shots/$name-1.png" 2>/dev/null
    # sweep the pointer over the top-left quadrant, where ImGui puts its first window
    for pos in "60 60" "120 100" "180 140" "240 180"; do xdotool mousemove $pos; sleep 0.4; done
    xdotool mousemove 120 100 mousedown 1; sleep 0.3; xdotool mouseup 1; sleep 0.6
    import -window root "$here/data/imgui-shots/$name-2.png" 2>/dev/null
    wait "$pid"
    c1=$(identify -format %k "$here/data/imgui-shots/$name-1.png"); c2=$(identify -format %k "$here/data/imgui-shots/$name-2.png")
    if compare -metric AE "$here/data/imgui-shots/$name-1.png" "$here/data/imgui-shots/$name-2.png" null: 2>/dev/null | grep -q '^0$'; then ch=no; else ch=yes; fi
    printf '%s\t%s\talive\t%s\t%s\t%s\n' "$name" "$built" "$c1" "$c2" "$ch" >> "$out"
done
kill "$xvfb" 2>/dev/null
cat "$out"
