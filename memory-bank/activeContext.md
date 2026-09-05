# Active context

Last staleness sweep: 2026-09-04

The updated four-scene Mac build is exported to `builds/Gray Goo.app` and open for personal play. Source is committed locally; do not push without a request. Native motion, HUD, eye rendering, and saved speed were checked. The user still finds scene design inconsistent and plans an in-depth change list. Do not call the overall game visually accepted or fully balanced.

## Current scope

The user approved the four-scene plan with "Go for it" on 2026-09-04. Quark Dust Ladder, Coral Colony Tide Pool, Skatepark Bowl, and Tablecloth of Everything are implemented. The accepted catalogue in `docs/design/selection.json` is inspiration for future scope, not authorization to build the 60-level campaign. Do not reopen the design interview or present another full catalogue.

Godot 4.7.2 standard supplies the native runtime, with the Mobile renderer and a 1920 × 1080 render size. Blender 5.2.1 LTS supplies editable source assets through its CLI; no MCP was installed. The user prefers personal Mac play; browser delivery is outside this build. Everything informs scale and theme diversity, not gameplay or origin story.

## Settled behavior

Use smooth cartoon forms, bright colors, cel shading, and outlines. Original Tasty Planet references contain both irregular scatter and meaningful order: groups, chains, rows, roads, and tracks. Avoid evenly spaced generic rings and lanes. Fields are larger explorable spaces, with irregular scene-specific formations and gaps. The user said the revised art looked better, but has not accepted the scene design as final.

The goo stays round and soft. A few thin, temporary filaments reach unevenly, grip the ground, pull the actual body, then retract into it. Filose amoebae and Venom symbiotes inform this motion. The user rejected meaty Carrion appendages and a regular gait that looked like quick feet. Keep cartoon pigment and googly eyes; do not use black symbiote skin, teeth, or a branching network simulation. The actual model in motion takes precedence over generated reference images.

The default requested drive speed is ten times the original parameter. Movement speed in the scene menu adjusts both keyboard and mouse steering from 10% to 200%, with 100% as the faster default. It persists across scene changes and app restarts. Physical travel is approximate because acceleration, traction, and turns affect it.

WASD and arrows move relative to the screen. Hold the left mouse button to steer toward the pointer. Right-button drag rotates only the camera; scrolling changes zoom within the active scale view. Keep the camera tilt fixed. Do not bind rotation to Q/E or use tank controls. Invisible field walls constrain the goo, and the camera stops following near the boundary.

Eye whites spring, lag on turns, and settle after stopping. Pupils follow the cursor and are painted on each eye surface to prevent clipping from overlapping pupil geometry. Food creates a localized color patch at contact and blends slowly, leaving a lasting tint. Diffusion is 0.07.

The nearest edible object has both an arrow and a yellow outline, including its surviving parts when the whole is selected. This supersedes the original arrow-only decision. A named portrait of the last consumed object appears at bottom left. Water and spacetime also update that portrait.

Play is untimed and damage is deferred. Each scene starts at its own size. The HUD shows central body diameter and goal diameter in metric units; extended strands do not affect it. Per-scene physical calibrations are illustrative, not empirical object measurements. A scene can have zero, one, or two optional camera size jumps. Growth continues within each view.

Food is engulfed and shrinks on contact without pausing movement. Shape-aware thresholds do not require precise approach alignment. Parts and wholes have separate thresholds; removed parts do not lower the whole threshold or count twice. Board snapping is optional presentation. Puddles are consumed locally, leaving a coherent translucent remainder; do not add remote ingestion through strands or whole-pool suction. A sufficiently large goo can consume the final spacetime surface.

Every consumed item contributes to goal size. Completion depends on size, not a separate required-object flag. The final bite uses brief slow motion, squash/stretch, and a color pulse, then permits continued play and Next level. Opaque foreground objects stay opaque; only a subdued goo outline shows through them.

## Animation remains unresolved

The user rejected the thin-filament animation after the final rendered pass: "bruh this is still not the tendril animation I want. Why is it so hard to describe". Mechanical traction, thin geometry, and FPS checks do not establish the desired motion. Pause animation edits and clarify the motion itself before another implementation. The distinction between separate strands pulling a body and the body flowing into its extensions is a candidate clarification, not a confirmed requirement.

## Next design review

The user wants protons and neutrons to keep constant sizes. Different elements use different constituent counts, with visibly orbiting electrons in the old textbook diagram style. Loose-quark scatter is a poor fit. Other subatomic types can move at readable game speeds. Hold the particle-scene rewrite for the user's consolidated change list. Do not dismiss these consistency requirements as scientific literalism.

The desired typical duration is roughly 3–5 minutes, but human pacing and final balance remain unverified. The new movement speed changes travel time; do not reuse old completion times as evidence of current pacing.

## Verification and communication boundaries

The user explicitly requested basic run/error checks during development and one final visual/performance pass, followed by their own play. Do not add a permanent unit/integration/E2E suite or repeated screenshot-polish loops. The final bounded native motion routes, release-start sample, speed-persistence check, and prior completion evidence are recorded with exact measurements in `progress.md`.

Keep `memory-bank/status-updates/prototype-build-plan-2026-09-04.html` unchanged. It is hosted at https://o4ptlfljz57n.postplan.dev . The single results artifact summarizes this build and the remaining scene review. Status artifacts require mechanical checks, one Zen opening, and mobile hosting, but no visual QA; the user explicitly exempted them.

The user approved the file-specific, read-only Kimi review of this game's world, goo, material/shader, and Blender generator source. It completed. Do not repeat the same review or broaden external source transmission without authorization. Root rejected the blanket color conversion because shader uniforms already use `source_color`; remaining non-blocking observations are in `progress.md`.
