# System patterns

Godot 4.7.2 uses the Mobile renderer for the four approved standalone Mac scenes. Runtime files under src separate the game loop, world construction, food, goo, camera, and HUD. Play is untimed and damage is deferred.

Liquid behavior contract: coherent translucent surface, local consumption, remaining mass persists. Connected fluid points are the user's suggested representation; choose the simplest implementation that delivers the actual behavior and allows the remaining liquid to form separate pools if cut through. The protagonist needs deformation coupled to motion and contact. The goo uses a constrained particle shell because a Godot 4.7.2 Jolt canary and source inspection showed live body scaling is discarded. Actual floor/obstacle contact and adhesion constrain shell particles and therefore move its center. Native Jolt simulates loose world objects. LocalPool uses a bounded density grid and a continuous plane with a filtered depletion texture for water and spacetime; the grid is not rendered as pellets.

Recommended scale representation: keep documented physical sizes separate from the convenient coordinate units used to render and simulate each active scale band; preserve meaningful size ratios within a scene. This avoids treating the entire growth journey as one simultaneously simulated universe. Cartoon representations at subatomic scales are accepted; do not impose scientific literalism on their appearance.

Source checks on 2026-09-04: Godot spatial shaders provide diffuse_toon and specular_toon modes. Web exports require Compatibility rendering and WebGL 2.0; Forward+/Mobile and C# web exports are not supported by the retrieved stable documentation. Browser delivery is outside the accepted proof of concept, so do not impose those web constraints on the desktop renderer. The native build uses GDScript and the Mobile renderer; rendered performance still requires the final pass.

Sources:
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html

Optional scale transitions: each level declares a `jumps` list, with ordinary growth inside each camera view. A jump reveals larger types and retires tiny detail. The demo levels use five tiers and four jumps, per `docs/design/level-contract.md`. Each scene config also carries a `tiers` list of display names for the HUD ladder strip.

Level entry sizing: the user confirmed on 2026-09-04 that each level starts at a size tailored to its scene, rather than carrying size over from the previous level. Growth remains continuous within each level, including across any optional camera size jumps.

Level structure: a level is one recognizable place, and every object belongs to a visible whole. Three patterns apply: nested wholes, the whole was always there, and damage shows. Each tier's whole becomes ordinary food in the next tier. The full contract for Astra is `docs/design/level-contract.md`.

Level completion: every consumed object contributes growth, and reaching the level goal size completes the level. Tune the food budget so the main milestone object usually supplies the growth that crosses the goal. The milestone is not a separate mandatory completion gate.

Eating presentation: engulf and shrink edible objects on contact without pausing movement. Larger bites visibly stretch the goo. Local puddle consumption preserves the untouched remainder.

Camera: preserve a top-down feel with a slight overhead tilt. Players can rotate around the goo and zoom within reasonable limits, but cannot change tilt. Exact angle, zoom bounds, and control bindings remain to be tuned.

Completion presentation: reaching the goal size celebrates completion and makes Next level available while the scene remains playable. The final bite uses brief slow motion, exaggerated body deformation, a color pulse, and a short sound.

Edibility: use predictable thresholds informed by object shape and bulk. Engulfing responds visually to shape without requiring precise alignment to eat an eligible object. Suitable thin objects may snap during engulfing; this optional animation does not introduce a separate breaking action or extra growth reward.

Occlusion: an opaque foreground obstacle hides the ordinary goo rendering, but a subdued goo outline remains visible through it. Do not make the obstacle transparent.

Food color: create a localized patch at the consumption contact point, using the food's average color. Gradually blend it through the goo to produce a lasting tint. Timing and color contribution strength are tuning choices, not fixed yet.

Composite consumption: individual parts and the whole have separate eating thresholds. Consuming parts does not automatically reduce the whole threshold. Once eligible, consuming the whole consumes only its surviving parts; previously consumed parts contribute no second growth reward.

Camera controls confirmed on 2026-09-04: WASD and arrow keys move relative to the screen, independent of the goo's facing direction. The user moved camera rotation to mouse controls to keep it separate from WASD. Use right-button drag to rotate only the view for comfort or inspection, with left-button hold for steering; rotation never turns the goo for forward/backward driving. Do not bind rotation to Q/E. Scroll-wheel zoom stays within the active scale view. Invisible playfield walls constrain the goo; the camera stops following near the boundary. Keep rotation optional for ordinary play.

Winning bite confirmed on 2026-09-04: brief slow motion, exaggerated squash and stretch, and a strong color pulse through the goo. Return to normal play with Next level available. Normal bites retain uninterrupted movement.

Pool performance: collect the weighted contact position during local consumption and upload a dirty density mask at a bounded cadence. Do not search for the nearest filled cell before every ordinary bite. Nearest-cell queries are for guidance and whole-surface contact only.

Every model gets a baked procedural albedo texture from Blender, passed through a new `albedo` uniform on the toon shader. Flat colors alone are rejected. Space must look real: near-black, warm and white stars, muted dust.

Asset colors: Blender material node inputs use linear RGB. Convert authored sRGB hex colors before assignment so exported GLBs retain the intended palette. The custom toon light divides LIGHT_COLOR by PI and applies ALBEDO once.

Metric HUD contract: world config declares `meters_per_unit`; displayed size is `2 * radius * meters_per_unit`, including the goal, and scale reveals never reset it. Current authored calibrations are Quark `1e-15`, Coral `0.01`, Skatepark `0.25`, Cosmos `1e21` metres per world unit. These calibrate the cartoon scenes, not empirical object measurements. Prefixes follow SI casing, including `fm` (femtometre) and `Zm` (zettametre); reference https://www.nist.gov/pml/owm/metric-si-prefixes .

The scene menu owns a saved movement-speed preference in `user://settings.cfg`, under `controls/movement_speed`. Its 10–200% range scales both keyboard and mouse steering around the authored default speed. Scene changes retain the same preference.

Target guidance reuses the existing nearest-edible lookup. Only the selected object and its surviving composite parts receive a depth-tested yellow outline; consumption clears it. The last-meal portrait uses an isolated 192-pixel SubViewport, refreshed only when the displayed item changes. Liquids display a colored puddle.

Pupils are a gaze-controlled color region on each eye mesh, using `shaders/eye.gdshader`. There is no overlapping pupil geometry to clip against the eyeball. The eye whites retain independent body-driven spring motion.

Continuous rolling uses exact rotation of the shell material plus forward flow. Each particle stores its previous prescribed flow separately from its residual deformation velocity; do not mix retained tangential inertia into a partially relaxed rotation target. Adhesive floor bonds age with normalized travel and release asymmetrically. At the invisible field boundary, block outward propulsion so the body cannot roll up that edge.

Keyboard and mouse gaze share the movement mode owned by `GooCamera.mouse_steering`. Keyboard input wins when both are active; idle retains the most recent mode. `game.gd` projects its existing edible target for keyboard gaze or supplies the cursor for mouse gaze through `GooBody.gaze_screen_position`; the eye shader remains responsible for clipping-free pupils.

Five irregular forward caps share the continuous shell and feed its existing adhesive contacts. At idle, a volume-preserving anisotropic rest metric flattens and spreads the shell; three fixed randomized angular phases with distinct smoothing rates make the footprint uneven. Slow idle bond aging permits spreading. Resume restores the rolling metric and clears the idle shape smoothly.

The four level layouts now live in `src/levels/`. Each RefCounted layout supplies `definition`, `ground_height`, `build`, and `step`. GameWorld owns shared terrain, lighting, food lookup, and the active tier. Configs expose five `tiers` and five `jumps`; index 0 is the first view. A jump can replace `meters_per_unit`. The game preserves the existing four-body-length speed law and enlarges the camera view continuously between jumps.

A Food has a structural `parent_food` or a visible `context_whole`. Scene callbacks use `part_consumed` and `touched` for local consequences. Consumed Food nodes retain scene identity, become inactive, hide, and stop processing after their meal animation; the world frees them with the level. Do not queue_free each meal while typed scene registries retain those nodes. Parts have separate fixed thresholds, and their volume is removed from the remaining whole exactly once.

LocalPool gates consumption by tier and radius. Tide water samples the basin terrain, masks dry cells, and lowers its surface as water disappears. Keep the remaining growth volume constant when the depth mask changes. Cosmic fabric unlocks after the supercluster is consumed and stays a local mopping surface.

Blender model families live in `scripts/asset_builders/`. Each model has one 512-pixel albedo atlas and a textured GLB. GLB imports use `gltf/embedded_image_handling=3` to avoid redundant extracted PNG files. Space dust uses soft additive materials and vertex opacity; exported COLOR_0 must survive the bake/join/export path. Non-wisp parts must keep opacity 1 when meshes join. Texture verification follows graph connections because the GLB importer can insert a vertex-color multiply between the texture and Base Color.

Use `scripts/check_worlds.gd` for real-consumption budget closure and visible-whole membership. Require `WORLD_CHECK_OK=true` and no script errors; Godot can return exit 0 after a parse error. `scripts/drive_levels.gd` records ordinary-input routes and screenshots with checkpointed output. `scripts/inspect_levels.gd` stages untouched scenes for view/render stress measurements; it is not completion-time evidence. Dense untouched colliders can make a staged growth view harsher than a real route.

GameWorld caches obstacle eligibility until player radius or tier changes, or `_add_food` adds a new object. Food thresholds stay fixed after scene construction. Queries keep original food order and read active state, collider size, height, and position live. This avoids repeated full-food scans in the body's substeps without caching a stale spatial result. `scripts/check_obstacles.gd` compares this path with the uncached scan through growth, movement, addition, and removal.

Food enables its own physics callback only for drifting physics bodies, polyp/plankton sway, and an active meal animation. Scripted scene motion still runs through each layout's `step`. `consume()` must enable the meal callback before the next physics frame. Sugar batches each electron position and each whole transform into one write, preserving the same motion within float precision.

Camera clipping grows with its orthographic view: its far plane must stay beyond the camera-to-ground distance in the largest cosmic view. The viewport inspector supports a selected level/tier for focused rechecks.
