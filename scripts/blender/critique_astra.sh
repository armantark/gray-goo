#!/usr/bin/env bash
# Ask GPT-6 Astra to score one revision's renders on the fixed model rubric.
# Usage: scripts/blender/critique_astra.sh <model> <revision dir> "<what the model is and where it appears>"
# Writes <revision dir>/astra.md. A critic from another model family is required for Opus-made models.
set -euo pipefail
model="$1"
dir="$2"
context="$3"
images=()
for view in front side back elevated_threequarter game-x4; do
	images+=(-i "$dir/$model-$view.png")
done
prompt="You are the independent art critic for a cartoon 3D game asset. Inspect every attached image yourself.
<context>$context
Images, in order: front (toe-on), side (outer profile), back (heel), elevated three-quarter, and the game view: the game's 70 degree orthographic camera at the model's real on-screen size (about 50 px across in a 1920x1080 frame), enlarged 4x with nearest-neighbour. All renders reproduce the game shading: three flat light bands on a baked color atlas and a 2.5 px inverted-hull ink outline.</context>
<rubric>Score each dimension 0-10: recognition and silhouette (25%), proportion and construction (20%), useful detail at game size (20%), material and texture quality (15%), cohesion with the game's cartoon style (20%).
Anchors: 0 missing or broken; 3 crude placeholder; 5 recognizable with obvious flaws; 7 solid but visibly unfinished; 8 release quality with minor flaws; 9 polished from all tested angles and at game size; 10 exceptional with no actionable defect. Geometry defects (holes, floating parts, interpenetration that reads as an error, broken normals) block acceptance regardless of score.</rubric>
<output>Return: the five scores, the weighted score to two decimals, any blocking defect, then the defects ranked by how much they cost the score, each with the concrete edit you would make. Be strict and specific; do not be generous.</output>"
/Applications/ChatGPT.app/Contents/Resources/codex exec -m gpt-6-astra -c model_reasoning_effort=xhigh -s read-only \
	-o "$dir/astra.md" "${images[@]}" -- "$prompt" < /dev/null > "$dir/astra.log" 2>&1
cat "$dir/astra.md"
