# Active context

Last staleness sweep: 2026-09-04

The scene pool is accepted and the material prototype decisions are settled. The user approved the compact build plan on 2026-09-04 with "Go for it". Implementation is active; do not reopen the interview. Confirmed: subatomic start, variation between settings at the same scale, 1080p, smooth cartoon geometry throughout with cel shading and outlines, and gameplay similar to the original Tasty Planet.

The user prefers CLI to MCP. Blender was updated to 5.2.1 LTS for Apple Silicon at the user's explicit request. Its bundled CLI passed a headless scene save, GLB export, and render check. No MCP install is needed. The user confirmed the model setting is already correct.

Everything informs scale and diversity of themes within a scale band only. The user is discussing level-theme progression, not origin story. Do not reopen narrative framing or propose Everything-style gameplay. Low-poly and voxel art were considered and not selected.

The current four prototype recommendations are Quark Dust Ladder, Coral Colony Tide Pool, Skatepark Bowl, and Tablecloth of Everything. They cover subatomic parts, living parts and wholes, curved ground, and the spacetime endpoint. Keep future decisions focused on these scenes; do not present another full catalogue to read.

Settled: cartoon abstraction at subatomic scales; meaningful relative sizes at larger scales; untimed play only; no damage yet; roughly 3–5 minute levels. Do not reopen scientific literalism or propose timers/personal bests. The user wants movement, physics, and interconnected world behavior.

Liquid consumption means mopping a puddle locally, section by section. The remaining puddle stays coherent and translucent. The user suggested connected points underneath a continuous surface. Do not implement automatic consumption of the entire puddle or assume long-range suction.

The goo must be a rounded rolling, deformable mass with sticky-looking floor contact and physics. The user accepted responsive steering with some stopping drift and body lag/stretch/settling. The REST/ROLL/RELEASE image is generally acceptable as a loose reference, but image generation is limited; judge the actual goo in motion. Do not spend more turns refining generated reference pictures instead of the actual model.

Delegated scene generation and independent native curation are complete. The accepted pool contains 240 candidates, with 60 refined campaign selections and four prototype recommendations in docs/design/selection.json. The original game supplied research and inspiration, not a required campaign mapping. Raw alternatives remain drafts. This does not authorize a 60-level implementation. Each level starts at a size chosen for its scene; size does not carry over between levels. Food budgets remain uncalibrated.

The user accepted Godot standalone and said browser access is not important because the game is mostly for personal play. Target their local Mac first. Browser delivery is outside the proof of concept. Godot has not been installed and no game implementation has started.

Verification override: one final visual playthrough, then the user tests it. Blender inspection during asset creation is allowed. Keep only basic run/error checks during development; no automatic unit/integration/E2E suite or repeated screenshot-refinement passes. Measure the 1080p/60 fps requirement during the final visual pass.

Size jumps are optional: each level has zero, one, or two. A jump zooms the field out, reveals larger object types, and retires the smallest detail. Growth continues within each view. Do not force a jump or a three-stage template onto every scene.

Include emergent formations and edible parts that let the goo grow large enough to consume a remaining whole. User examples: coral polyps to whole coral, and quarks to protons to nuclei. The coral example is a user-supplied reference to Tasty Planet 5, not a verified fact about the original game. Parts/wholes and camera jumps are independent mechanics.

Original levels are inspiration seeds only. Do not recreate their 60-level campaign, enforce one-to-one mappings, or generate a fixed set of reskins for every original level. Use their pacing, playful arrangements, interactions, and growth payoffs to invent fresh scenes. Source references document influences, not required replicas.

Status artifacts require no visual testing. The user explicitly stopped artifact screenshot and viewport checks on 2026-09-04; mechanical preflight, the required Zen opening, and hosting still apply. This exemption is also recorded in the canonical fleet Codex rules. The game itself retains its single final visual/performance pass.

Level entry sizing: the user confirmed on 2026-09-04 that each level starts at a size tailored to its scene, rather than carrying size over from the previous level. Growth remains continuous within each level, including across any optional camera size jumps.

The user confirmed hybrid level completion on 2026-09-04: every consumed object contributes toward the goal size; the main milestone usually pushes the goo over that goal. Completion depends on size, not a separate required-object condition.

Controls confirmed on 2026-09-04: WASD and arrow keys, plus optional mouse steering while the mouse button is held. The goo moves toward the pointer. Both input methods use the same responsive steering, stopping drift, and body deformation.

Eating presentation confirmed on 2026-09-04: edible objects are engulfed and shrink on contact without pausing movement; larger bites visibly stretch the goo. Puddles disappear only where touched. The user invoked grill-me and corrected the interview format: ask small rounds of independent frontier decisions, with recommendations, rather than isolated serial questions. The remaining design tree is in plans/prototype-frontier.md.

Camera: preserve a top-down feel with a slight overhead tilt. Players can rotate around the goo and zoom within reasonable limits, but cannot change tilt. Exact angle, zoom bounds, and control bindings remain to be tuned.

Completion presentation: reaching the goal size celebrates completion and makes Next level available while the scene remains playable. The final bite must be satisfying and visually striking. Its specific effects remain open.

Edibility is settled: use predictable, shape-aware eating thresholds with responsive engulfing visuals. Thin shapes can be easier to eat than their length alone suggests, without requiring precise approach alignment. The user suggested a possible break-in-half animation for suitable thin objects; this is optional presentation, not a separately controlled breaking mechanic. The original game's internal formula remains unverified.

Occlusion confirmed on 2026-09-04: keep foreground obstacles opaque and show a subdued outline of the goo through them when it is hidden. Do not fade the obstacle or reveal the surrounding food through it.

Food guidance: use a pointer toward the nearest edible object, following the user's stated preference for the original game's guidance rather than highlighting nearby food. Consumed food first creates a localized patch of its average color at the contact point. The patch gradually blends into the rest of the goo, leaving a lasting tint rather than briefly flashing back to gray. Exact blending strength and timing are tuning choices. Coral consists of distinct composite parts. The user confirmed separate eating thresholds for individual parts and the whole colony. Removing polyps does not automatically lower the whole threshold; the final whole-colony bite consumes only the surviving parts.

Camera controls confirmed on 2026-09-04: WASD and arrow keys move relative to the screen, independent of the goo's facing direction. The user moved camera rotation to mouse controls to keep it separate from WASD. Use right-button drag to rotate only the view for comfort or inspection, with left-button hold for steering; rotation never turns the goo for forward/backward driving. Do not bind rotation to Q/E. Scroll-wheel zoom stays within the active scale view. Invisible playfield walls constrain the goo; the camera stops following near the boundary. Keep rotation optional for ordinary play.

Winning bite confirmed on 2026-09-04: brief slow motion, exaggerated squash and stretch, and a strong color pulse through the goo. Return to normal play with Next level available. Normal bites retain uninterrupted movement.

Implementation checkpoint: Godot 4.7.2 standard is installed at /Applications/Godot.app beside the existing mono engine. Astra implemented the growing particle-shell goo and four scene worlds; root integrated keyboard/mouse camera controls, food/composite consumption, goal completion, HUD, and original audio. The Blender asset library passed a root rerun after correcting evaluated-vertex bounds and shell winding. Headless import and the initial game launch run; final playable, visual, and 1080p performance verification remain open.

2026-09-04 visual review correction: The user rejected the current art direction and edible-object formations, and said the playfields are much too small. They want the original games' more random distribution within natural, plausible formations. Do not call this build finished. Replace evenly spaced rings and lanes with larger explorable fields, irregular scene-specific patches, gaps, and formations. The precise art-direction problem is pending the user's answer; preserve the accepted smooth cartoon 3D requirement rather than guessing a new style. Final checks are paused for this revision.
