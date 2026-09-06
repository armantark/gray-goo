#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
engine="/Applications/Godot.app/Contents/MacOS/Godot"
mkdir -p "$project_root/builds"
"$engine" --headless --path "$project_root" --import --editor --quit
"$engine" --headless --path "$project_root" --export-release macOS "$project_root/builds/Gray Goo.app"
mkdir -p "$project_root/builds/Gray Goo.app/Contents/Resources/licenses"
cp "$project_root"/licenses/*.txt "$project_root/builds/Gray Goo.app/Contents/Resources/licenses/"
codesign --force --deep --sign - "$project_root/builds/Gray Goo.app"
codesign --verify --deep --strict "$project_root/builds/Gray Goo.app"
