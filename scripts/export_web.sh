#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
engine="/Applications/Godot.app/Contents/MacOS/Godot"
mkdir -p "$project_root/dist"
"$engine" --headless --path "$project_root" --import --editor --quit
"$engine" --headless --path "$project_root" --export-release Web "$project_root/dist/index.html"
python3 "$project_root/scripts/web_build.py" pack
