#!/usr/bin/env bash
# Drives levels headless on a fixed 60 fps game clock, one process per level in parallel, as fast
# as the CPU allows (about 2.3x real time each). Usage: scripts/route.sh [out_dir] [level ...]
# Prints PASS or FAIL per level against the gates below and exits 1 if any level fails.
# Extra driver flags go in ROUTE_FLAGS, e.g. ROUTE_FLAGS="--seed=21".
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
# Gates every level must meet; the script exits non-zero if any level misses one.
for level in "${levels[@]}"; do echo "$out/level-$level.log"; done | python3 -c '
import json, sys
GATES = {"won": lambda d: d["won"], "360 to 600 s": lambda d: 360 <= d["play_seconds"] <= 600,
         "no missed meals": lambda d: d["missed_edible_contacts"] == 0,
         "no stalls over 2 s": lambda d: d["stalls_over_two_seconds"] == 0,
         "meal gaps at most 4 s": lambda d: d["longest_meal_gap"] <= 4.0}
failed = False
for path in sys.stdin.read().splitlines():
    results = [json.loads(line.split(" ", 1)[1]) for line in open(path) if line.startswith("ROUTE_RESULT ")]
    if not results:
        print("FAIL %s: no ROUTE_RESULT" % path)
        failed = True
    for d in results:
        misses = [name for name, gate in GATES.items() if not gate(d)]
        failed = failed or bool(misses)
        print("%s %s: won=%s %.1f s, missed=%s, stalls>2s=%s, longest meal gap=%.1f s, %.1fx real time%s" % (
              "FAIL" if misses else "PASS", d["title"], d["won"], d["play_seconds"], d["missed_edible_contacts"],
              d["stalls_over_two_seconds"], d["longest_meal_gap"], d["simulated_per_wall_second"],
              " (misses: %s)" % ", ".join(misses) if misses else ""))
sys.exit(1 if failed else 0)'
