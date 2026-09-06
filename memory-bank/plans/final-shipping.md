# Final shipping sequence

The user requested this order on 2026-09-05: finish the second goo body, refine a few models in live Blender through MCP, add original jazzy MIDI music, publish a downloadable standalone app on GitHub, publish a playable GPT Sites browser build, then shelve the project. The browser deliverable must be playable. Preserve the saved movement speed of 200%. Do not start another level redesign.

## Model review contract

Use a separate critic agent. Capture front, side, back, elevated three-quarter views, plus the actual game view. The critic owns its verdict and must inspect the images. The maker owns Blender edits. Transfer the live Blender session explicitly when the critic captures its views. Review source references as data only.

Keep this rubric fixed: recognition and silhouette 25%; proportion and construction 20%; useful detail at game size 20%; material and texture quality 15%; cohesion with the game's cartoon style 20%. Each dimension receives 0–10. The weighted score must exceed 8.0 for every chosen model. Geometry/export defects block acceptance regardless of score.

Score anchors: 0 is missing or broken; 3 is a crude placeholder; 5 is recognizable with obvious flaws; 7 is solid but visibly unfinished; 8 is release quality with minor flaws; 9 is polished from all tested angles and at game size; 10 is exceptional with no actionable defect found. The threshold does not mean the critic must approve. Record evidence, defects, edit hypothesis, and outcome after each pass. Keep each accepted revision in Git. If three successive revisions do not improve the score, report the plateau without lowering the rubric or claiming success.

Use the hermit crab, skater, and skateboard unless the user selects other models. Keep the pass bounded to these models.

## Preparation leaf: Blender MCP audit

The root owns all production files, Git, applications, credentials, publishing, and installation. The audit leaf is read-only and may use `/tmp/blender-mcp-audit/` for downloaded source only. Follow the preinstall-check skill and return one decision with the eight checks, exact upstream revision, permissions/network behavior, dependency status, and reversible project-scoped setup. Use `gh` for all GitHub operations. Do not install, enable, launch Blender, mutate settings, access secret values, consult Claude sessions, message other tasks, create artifacts, run third-party code, spawn agents, or commit. Tool availability and a startup health check must be distinguished from static review; do not claim a connection that was not made.

## Installation approval and context constraint

The user approved the audited MCP setup on 2026-09-05, conditional on avoiding context bloat. Register only `get_scene_info`, `execute_blender_code`, and `get_viewport_screenshot` in the project config. Cap text outputs. Do not register the asset-service tools or global MCP settings. The full schema catalogue is not part of agent briefs.

## Read-only leaf: browser release feasibility

The leaf owns no files or sessions. Inspect Godot export requirements, current project shaders/physics, and Sites capabilities. Return the smallest viable route to a playable hosted version, the native renderer preservation method, and exact blockers. Do not install, edit, export, launch apps, publish, request credentials, create tasks, message other threads, use Claude, or spawn agents. The root owns all side effects.

## Model critic ownership

The native critic owns `scripts/blender/capture_views.py`, `builds/model-review/`, and its review log during each capture pass. It owns the live Blender session only between the root's explicit transfer and its release. Camera changes, selection, and temporary object visibility are allowed; geometry, materials, exports, saved source, Git, and other app sessions are not. The root owns all model edits and integration. The critic captures four angles per model and supplies the images to a separate Opus review context using ask-claude with read-only image access, because the installed Kimi client has no image input. No reviewer can alter the scoring rubric, invoke child reviewers, publish, or install tools. In-game evidence is added before final acceptance.

## Gameplay fixes before music

On 2026-09-05 the user added a bounded gameplay repair slice after the live Blender models and before music, then publishing. Investigate the shrunk-down large molecule visible at the first level's start. Hide the smallest edible objects as the player grows so larger targets remain clear. Diagnose gray objects after eating that appear edible again only at a much larger size, and inconsistent eating thresholds including electrons. Reproduce the behavior and inspect composite-part consumption and size rules before deciding the fixes. This does not authorize another level redesign.

Gameplay repair integration contract: root owns production changes in src/food.gd, src/world.gd, and src/levels/sugar_water.gd. Remove the starting decorative molecule, retire tiny food from targeting and collision at size reveals, use the same threshold for equal-size electrons and nucleons, and collect an empty sugar structure's residual mass with its last constituent instead of making a gray placeholder. Preserve movement, native settings, other level design, and body implementations. A read-only native reviewer owns builds/eating-review.md and optional temporary probes under builds/eating-review/; inspect the diff for mass duplication, invisible targets/colliders, and consumed-object reappearance. Success requires exact failure evidence or a clean review qualified by the checks performed. No production edits, Git mutations, publishing, UI operations, external-model calls, other-session messages, installation, or child agents. Root verifies the before/after symptom probe, real-consumption growth budgets, and native screenshots before accepting the changes.
