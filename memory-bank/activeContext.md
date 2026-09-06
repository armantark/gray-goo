# Active context

Last staleness sweep: 2026-09-05

The second goo body is implemented and exported to `builds/Gray Goo.app`. The Body menu switches between Shell and Procedural and preserves the current game state. Both native Coral routes run near 60 FPS at 1920 × 1080 with the user's saved 200% speed. Shell behavior is unchanged. Procedural grip/peel and rolling circulation remain less visually distinct than requested; do not claim full visual acceptance. Evidence is in `builds/body-verification/report.json` and `progress.md`.

The user requested this final sequence: complete the body experiment, refine a few models through MCP in live Blender with a separate multi-angle critic scoring above 8, fix the reported start-molecule, tiny-food visibility, gray remnants, and eating-threshold issues, add jazzy MIDI music, publish GitHub source plus a downloadable standalone app, publish a playable GPT Sites browser build, and shelve the project. GitHub publishing is authorized for that final result. The user approved project-only MCP installation conditional on avoiding context bloat; setup and canary verification are complete. The fixed critic rubric and scope are in `plans/final-shipping.md`.

The live model and texture pass is complete. Independent scores exceed 8 for hermit crab, skater, and skateboard, with no confirmed geometry/export blocker. The gameplay repair is complete, including the later board-to-rider scale correction. The current slice is original jazzy MIDI music, followed by publishing. The user rejected generic cloud-noise textures; all model atlases now preserve clean color regions, and only explicit grip/sand/concrete surfaces receive fine grain. Both the generic bake noise and the ground shader mottling are removed. See `progress.md` and `builds/model-review/clean-materials/` for current evidence.

## Current scope

The user approved the four-scene plan with "Go for it" on 2026-09-04. Sugar Water, Coral Colony Tide Pool, Skatepark Bowl, and Cosmic Web are implemented per `docs/design/level-contract.md`, each with five tiers and four jumps in `src/levels/`. The accepted catalogue in `docs/design/selection.json` is inspiration for future scope, not authorization to build the 60-level campaign. Do not reopen the design interview or present another full catalogue.

Godot 4.7.2 standard supplies the native runtime, with the Mobile renderer and a 1920 × 1080 render size. Blender 5.2.1 LTS supplies editable source assets. The live refinement pass uses the isolated project MCP connection with three allowed tools and telemetry disabled. The final shipping scope includes a playable browser export in addition to the Mac app. Everything informs scale and theme diversity, not gameplay or origin story.

## Settled behavior

Use smooth cartoon forms, bright colors, cel shading, and outlines. Original Tasty Planet references contain both irregular scatter and meaningful order: groups, chains, rows, roads, and tracks. Avoid evenly spaced generic rings and lanes. Fields are larger explorable spaces, with irregular scene-specific formations and gaps. The user said the revised art looked better, but has not accepted the scene design as final.

The goo is one continuous rolling, sticky, gooey mass. Its own material circulates and flows into temporary extensions; floor contacts stretch and peel. The user now accepts feet-like reaching when it uses four or five irregular anchors rather than two alternating ones. Preserve the trailing stickiness and add forward reaching and grip. At rest, it should slowly melt into a broad, shallow, irregular puddle with unequal slowly spreading lobes, then gather again when movement resumes. Separate filament meshes and meaty Carrion appendages remain rejected. Keep cartoon pigment and googly eyes. Native motion takes precedence over generated references.

The drive speed is a constant four body lengths per second at every size, with the drive ramp at 6 per second to match the reach cycle. The user tunes the default by feel. Movement speed in the scene menu adjusts keyboard and mouse steering from 10% to 200%, with 100% as the new baseline. Saved percentages remain valid. Physical travel is approximate because acceleration, traction, and turns affect it.

WASD and arrows move relative to the screen. Hold the left mouse button to steer toward the pointer. Right-button drag rotates only the camera; scrolling changes zoom within the active scale view. Keep the camera tilt fixed. Do not bind rotation to Q/E or use tank controls. Invisible field walls constrain the goo, and the camera stops following near the boundary.

Eye whites spring, lag on turns, and settle after stopping. Pupils follow the arrow’s edible target after keyboard steering and the cursor after mouse steering; the latest steering mode persists at rest and keyboard input takes priority. Pupils are painted on each eye surface to prevent clipping from overlapping pupil geometry. Food creates a localized color patch at contact and blends slowly, leaving a lasting tint. Diffusion is 0.07.

The nearest edible object has both an arrow and a yellow outline, including its surviving parts when the whole is selected. This supersedes the original arrow-only decision. A named portrait of the last consumed object appears at bottom left. Water and spacetime also update that portrait.

Play is untimed and damage is deferred. Each scene starts at its own size. The HUD shows central body diameter and goal diameter in metric units; extended strands do not affect it. Per-scene physical calibrations are illustrative, not empirical object measurements. A scene can have zero or more camera size jumps; the demo levels now target about ten minutes with several jumps. Growth continues within each view.

Food is engulfed and shrinks on contact without pausing movement. Shape-aware thresholds do not require precise approach alignment. Parts and wholes have separate thresholds; removed parts do not lower the whole threshold or count twice. Board snapping is optional presentation. Puddles are consumed locally, leaving a coherent translucent remainder; do not add remote ingestion through strands or whole-pool suction. A sufficiently large goo can consume the final spacetime surface.

Every consumed item contributes to goal size. Completion depends on size, not a separate required-object flag. The final bite uses brief slow motion, squash/stretch, and a color pulse, then permits continued play and Next level. Opaque foreground objects stay opaque; only a subdued goo outline shows through them.

## Settled 2026-09-05 design interview

The interview settled: the root structure rule, five tiers and four jumps per demo level at about ten minutes each, Sugar Water (sucrose in water) as the subatomic level, tide pool, skatepark, and cosmic web ladders, textures on every model, 3D backgrounds, realistic space, a constant body-length speed law with smoothing, and the specimen readout HUD with a ladder strip. The contract for Astra is `docs/design/level-contract.md`. Fable owns speed and HUD. The user dispatched Astra with the plan on 2026-09-05. The speed law landed first so Astra's playthrough timings use it. Astra completed the level rebuild and released the checkout on 2026-09-05; the runtime hand-off is `docs/design/level-runtime-handoff.md` and results are at https://2c8gwk9dw7m5.postplan.dev . Fable rebuilt the HUD and fixed the Sugar Water contact bottleneck on 2026-09-05.

## Goo body second option

The user judges the simulated shell semi-decent but glitchy and wants a procedural skin over a simple core as a second body, with a `Body` toggle in the settings menu so both can be compared in game. The brief for Astra's next round is `plans/goo-body-brief.md`. It runs after the level rebuild, in the same checkout, one owner at a time.

## Performance after the grid fix

Ordinary Sugar Water movement ran at `10.9985906405953` FPS (`131.81` ms p95) on this machine because every physics substep scanned all 2687 foods for obstacles and for eating, and Godot's physics catch-up multiplied the slow ticks. `GameWorld.nearby()` now answers both queries from a placement grid (cell 8, wander margin 8 plus the widest collider). The same 20-second route runs at `58.6667332703374` FPS (`17.744` ms p95); Cosmic Web runs at `58.727833018453` FPS. Rendering alone in the Sugar Water first view costs about 15 ms per frame (staged `68.0` FPS), so any new per-tick cost above about 2 ms will push it under 60 again. Human pacing at about ten minutes is unverified; the four headless routes took 509, 455, 469, and 670 simulation seconds.

## HUD

The specimen readout HUD is live: paper slide label with a log-scale dial that flashes on calibration jumps, five-rung ladder strip from `config.tiers` and `world.current_tier`, specimen card for the last meal, light-year units from a tenth of a light year up, and a slide-tray menu. `scripts/capture_hud.gd` captures the meal, completion, and menu states; `scripts/inspect_levels.gd` captures the twenty tier views. The `Body` toggle from `plans/goo-body-brief.md` is implemented.

## Verification and communication boundaries

The user explicitly requested basic run/error checks during development and one final visual/performance pass, followed by their own play. Do not add a permanent unit/integration/E2E suite or repeated screenshot-polish loops. The final bounded native motion routes, release-start sample, speed-persistence check, and prior completion evidence are recorded with exact measurements in `progress.md`.

Keep `memory-bank/status-updates/prototype-build-plan-2026-09-04.html` unchanged. It is hosted at https://o4ptlfljz57n.postplan.dev . The single results artifact summarizes this build and the remaining scene review. Status artifacts require mechanical checks, one Zen opening, and mobile hosting, but no visual QA; the user explicitly exempted them.

The user approved the file-specific, read-only Kimi review of this game's world, goo, material/shader, and Blender generator source. It completed. Do not repeat the same review or broaden external source transmission without authorization. Root rejected the blanket color conversion because shader uniforms already use `source_color`; remaining non-blocking observations are in `progress.md`.

## Current review

The user reviewed the September 4 ten-second clip and requested slower movement, five irregular forward anchors, control-dependent gaze, and idle melting. This revision is implemented and the native app and comparison clip are ready. The user called the motion/build "Pretty good" and "pretty decent", but rejected the subatomic scene’s lack of structure. The design interview in `plans/subatomic-system-interview.md` now covers all four levels, ends at a whole molecule for the subatomic level, and must produce a contract for Astra with new model requests. Fable owns the speed-scaling and HUD revamp work after the interview settles.

## Final release state, 2026-09-05

The final shipping slice is complete in source. The procedural body remains an optional comparison; do not claim that its grip motion was accepted. Live Blender refinement covers the hermit crab, skater, and skateboard. Runtime board assemblies now use a uniform 0.5 deck scale with the rider’s feet lowered to match. The eating repair removes the initial miniature molecule, retires tiny targets, gives equal-size particles equal thresholds, and collects depleted sugar structures through their last visible constituent.

Each level now has its own original MIDI/Ogg song: Particle Shuffle (sax-led swing), Tidepool Bossa, Skatepark Samba, and Cosmic Drift (slower sax). The Music switch persists across launches and scene changes. The renderer synthesizes the instruments and uses no third-party soundfont. The Mac app preserves the saved movement speed; fresh browser settings default to 200%. The browser uses Compatibility without sun cast shadows because its additive shadow pass bleached the custom toon materials. Native Mobile keeps shadows. Small landscape canvas and menu were checked after reload; phone controls are not verified.

Publish the standalone Mac app and source to https://github.com/armantark/gray-goo and the playable owner-only site to https://gray-goo.tarkavor.chatgpt.site, then shelve. Publication state and final measured evidence belong in progress.md. Do not create a future iteration or automation.
