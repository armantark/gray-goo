#!/usr/bin/env bash
# Drives levels headless on a fixed 60 fps game clock, one process per level in parallel, as fast
# as the CPU allows (about 2.3x real time each). Usage: scripts/route.sh [out_dir] [level ...]
# Extra driver flags go in ROUTE_FLAGS, e.g. ROUTE_FLAGS="--route-seed=21".
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
out="${1:-builds/routes/latest}"
shift || true
levels=("$@")
[ ${#levels[@]} -eq 0 ] && levels=(0 1 2 3)
mkdir -p "$out"
for level in "${levels[@]}"; do
  # shellcheck disable=SC2086
  /Applications/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy --fixed-fps 60 --path . \
    --script scripts/drive_levels.gd -- --simulation-clock --start="$level" --last="$level" \
    --output="$out/level-$level.json" ${ROUTE_FLAGS:-} > "$out/level-$level.log" 2>&1 &
done
wait
for level in "${levels[@]}"; do
  grep -h "^ROUTE_RESULT " "$out/level-$level.log" | sed 's/^ROUTE_RESULT //' | python3 -c '
import json, sys
for line in sys.stdin:
    d = json.loads(line)
    print("%s: won=%s %.1f s, missed=%s, stalls>2s=%s, longest meal gap=%.1f s" % (d["title"], d["won"],
          d["play_seconds"], d["missed_edible_contacts"], d["stalls_over_two_seconds"], d.get("longest_meal_gap", 0)))'
done
