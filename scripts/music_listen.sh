#!/bin/bash
# Ask Gemini (through the watch skill) to listen to one built piece as the game plays it:
# the whole Ogg, then its loop again, so the wrap is audible.
# Usage: scripts/music_listen.sh <score-name> <ogg-path> <round> "<place>" "<style>"
# Example: scripts/music_listen.sh cosmic_web assets/audio/cosmic_drift.ogg 2 "'Cosmic Web', ..." "a medium-up swing ..."
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
work="$root/builds/music"
name=$1; ogg=$2; round=$3; place=$4; style=$5
report="$work/$name-report.json"
start=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['loop_start_seconds'])" "$report")
wrap=$(python3 -c "import json,sys;s=json.load(open(sys.argv[1]))['duration_seconds'];print(f'{int(s//60)}:{s%60:04.1f}')" "$report")
mkdir -p "$work/listen"
sox "$ogg" "$work/listen/$name-loop.wav" trim "$start"
sox "$ogg" "$work/listen/$name-loop.wav" "$work/listen/$name-game.wav"
ffmpeg -y -v error -loop 1 -framerate 1 -i "$work/$name-page2.png" -i "$work/listen/$name-game.wav" \
  -t "$(soxi -D "$work/listen/$name-game.wav")" -vf "scale=1280:-2,format=yuv420p" \
  -c:v libx264 -tune stillimage -c:a aac -b:a 192k "$work/listen/$name.mp4"
question="You are a music producer reviewing background music for a video game level: $place The owner wants it really upbeat and groovy, in the samba / bossa nova / jazz family, played by a realistic jazz band with upright bass and brass. This piece: $style Judge the writing, groove, arrangement, sound and balance. This file simulates the game: a ${start}-second intro plays once, the loop runs to $wrap, then the game jumps back to the loop start, so from $wrap on you hear the loop again. Answer each separately with timestamps. (1) Upbeat and groovy? Is the style convincing, and what single change would add the most groove? (2) Mood fit for the place. (3) Melody: memorable or aimless? Any wrong-sounding notes or clashes? (4) Mix balance: what is too loud, too quiet, or masking the lead? What sounds cheap or synthetic? Would it sit under game sound effects? (5) At $wrap, any click, gap, level dip, or odd change? (6) Fatigue over eight minutes of play, and the weakest section. Be blunt and specific. Answer in text directly; do not run tools."
python3 ~/.claude/skills/watch/scripts/watch.py --via gemini "$work/listen/$name.mp4" --question "$question" \
  > "$work/listen/$name-gemini-$round.md" 2> "$work/listen/$name-gemini-$round.err"
echo "$work/listen/$name-gemini-$round.md"
