# Papercuts

- 2026-09-04: `pinchtab instances` in the isolated scene-atlas session returned `Error 403: {"code":"session_scope_forbidden","details":{"safeControlledEnvironmentOnly":true},"error":"agent session is not allowed to access this endpoint"}`. Use only the session's own navigation and tab-scoped operations; do not remove session scoping to reach the global inventory.

- 2026-09-04: Scene-curation preparation searched the nonexistent `/Users/ArmanTarkhanian1/.codex/skills/ask-kimi/scripts/kimi_client.py`; the installed wrapper actually invokes `kimi_direct.py`.
- 2026-09-04: The Kimi quota probe failed its network refresh in the restricted sandbox with `Kimi quota refresh failed after 3 attempts: <urlopen error [Errno 8] nodename nor servname provided, or not known>`; requested reviewed network access before selecting the curator.

- 2026-09-04: After the workspace switched to managed permissions, committing the design updates failed with `fatal: Unable to create '/Users/ArmanTarkhanian1/Desktop/tasty planet clone/.git/index.lock': Operation not permitted`; the .git directory is read-only under the default sandbox, so the authorized commit needs a reviewed escalation.

- 2026-09-04: Tried to inspect the current Codex model/reasoning selector with cua.getApp("Codex"). Tool refused: `Computer Use is not allowed to use the app 'com.openai.codex' for safety reasons.` No setting was changed; native subagents can still be dispatched explicitly with gpt-6-astra and high reasoning.
- 2026-09-04: Blender discovery leaf's application glob failed with `zsh:1: no matches found: /Users/ArmanTarkhanian1/Applications/Blender*`; a pathlib directory scan resolved the discovery.
- 2026-09-04: Official Blender documentation opens through web returned `(402) Payment Required` for https://www.blender.org/releases/, https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html, and https://docs.blender.org/api/current/info_overview.html; direct curl retrieval worked. Initial HTML lookup for `id="cmdoption-python"` found no match, so inspected the literal command flags instead.

2026-09-04: Original-level research: web.open StrategyWiki returned `(403) Forbidden`; sandbox curl failed `curl: (6) Could not resolve host: strategywiki.org`. Reviewed network curl succeeded.

2026-09-04: Source retrieval: Fandom original-game overview curl returned `curl: (56) The requested URL returned error: 403`. Use retrieved StrategyWiki chapters and official game material; do not invent absent chapter walkthroughs.

2026-09-04: Official `/tastyplanet/downloadmac.htm` returns a binary download, not HTML. `file` reported `zlib compressed data`, unzip exited 9, and sandbox `hdiutil imageinfo` returned `Device not configured`; inspect download headers/types before text parsing.

2026-09-04: Local commit rejected by slop-gate: `scripts/scene_catalogue.py: render 22 (new)` cyclomatic; `candidates 19 (new)` and `render 35 (new)` cognitive. Split scene validation, scene markup and selection validation into their distinct responsibilities before retrying.

2026-09-04: Retry of local commit rejected by slop-gate for `scripts/scene_catalogue.py: E303 x1 (was 0)` after responsibility split; removed the extra blank line.

2026-09-04: Preparing the proposal visual check: sandbox PinchTab session call failed `dial tcp 127.0.0.1:9867: connect: operation not permitted`; reviewed localhost access succeeded. Keep subsequent browser calls scoped to a newly created task tab.

2026-09-04: Candidate aggregation failed with `AssertionError: Duplicate scene titles`: IDs126and153 both used `Wetland Boardwalk`. Renamed153to `Lily Pad Culvert` to describe its distinct stream-blocking interaction; curator must avoid selecting both near-overlapping settings.

2026-09-04: Auto-review rejected the Kimi selection call before execution: `This sends the project’s private 240-scene design corpus and prompt to the external Kimi API, but the user authorized curation in substance—not disclosure of that payload to that destination.` Continue through a native Codex reviewer; no Kimi retry or external transfer.

2026-09-04: Artifact preflight rejected source citation hyperlinks with `FAIL A5 remote src/href asset (artifact must be self-contained)`. Replaced remote anchors with internal source references and a plain-text URL index before opening or publishing.

2026-09-04: After Codex restarted, the old preview listener returned curl error `52` (empty reply) and the old PinchTab session returned `401`; a fresh task-owned preview listener and session restored access. The user then stopped status-artifact visual QA as unnecessary; added a permanent fleet rules exemption instead of repeating browser checks.

2026-09-04: Engine research found /Applications/Godot_mono.app 4.4.1, but its sandbox `--version` invocation exited `134` with no output. The verified official 4.7.2 standard engine ran `--headless --version` successfully under reviewed execution.

2026-09-04: Native goo canary found that `SoftBody3D.scale = Vector3.ONE * 1.7` at tick 90 was reset to `(1, 1, 1)` by tick 100 on Godot `4.7.2.stable.official.ed1daf0bf` with Jolt. Current source discards scaling because it cannot update edge rest lengths; use evidence from this canary when choosing the growing-body solver.

2026-09-04: Goo leaf's temporary headless canary hit editor settings access outside the sandbox without a project; an absolute `custom_user_dir_name` was appended under Application Support. Use an explicit project and `--log-file /tmp/...` for headless checks. Its first driver also set `global_position` before `add_child`, causing `!is_inside_tree()`; attach nodes before assigning global transforms.

2026-09-04: Asset leaf's sandboxed Blender exited `139` in `blender::gpu::supports_barycentric_whitelist` / `MTLBackend::metal_is_supported`; reviewed headless execution succeeded. Blender 5.2.1 rejected `BLENDER_EEVEE_NEXT` with `enum "BLENDER_EEVEE_NEXT" not found in ('BLENDER_EEVEE', 'BLENDER_WORKBENCH', 'CYCLES')`; use `BLENDER_EEVEE`.

2026-09-04: Blender returned exit `0` despite a generator Python exception unless invoked with `--python-exit-code 1`. The generator's documented invocation now includes that switch. `export_apply=True` also mutated a selected source transform during sequential GLB export; omit it to preserve the source transforms.

2026-09-04: Blender curve control bounds differed from exported plankton geometry by `0.04` units. Convert curves to meshes before measuring export bounds. Blender additionally emits `DeprecationWarning: 'Material.use_nodes' is expected to be removed in Blender 6.0`; the final generator still runs successfully.

2026-09-04: Goo leaf's first movement canary exposed an adhesion defect: center X advanced only `0.118` after `2 s` of +X input. A generic success label did not assert travel; the leaf added a travel assertion and is repairing traction-driven anchor release before returning.

2026-09-04: Asset review found bounding-box corner measurements overestimated rotated geometry; the rock base was at least `0.22078745425148416` above ground. Use transformed evaluated vertices for bounds. The shell outline signed area was `-5.371682980870516`, producing inward faces; reverse its outline before extrusion. Root regenerated all assets successfully.

2026-09-04: Initial Godot import stalled on the editable .blend with `Blender path is invalid or not set, check your Editor Settings. Cannot configure blender path in headless mode.` Added assets/source/.gdignore; the production GLB import then completed.

2026-09-04: Game integration sampled pool.closest_point after consume_whole, yielding `Vector3(INF, INF, INF)`. Capture the contact before removal and use it for localized pigment.

2026-09-04: Headless shutdown leaked `AudioStreamWAV` and `AudioStreamPlaybackWAV` for `res://assets/audio/bite.wav` while a bite sound was active. Added explicit audio stop/stream release on game exit; verification follows.

2026-09-04: First game commit rejected by slop-gate: `scripts/build_assets.py: verify_exported_glbs 23 (new)` cyclomatic and `verify_exported_glbs 30 (new)` cognitive. Separate geometry/material verification from bounds verification and import orchestration before retrying; no amend.

2026-09-04: macOS export rejected: `Cannot export for universal or arm64 if ETC2 ASTC texture format is disabled. Enable it in the Project Settings (Rendering > Textures > VRAM Compression > Import ETC2 ASTC).` Enabled `textures/vram_compression/import_etc2_astc=true`.

2026-09-04: Sandboxed packaged GUI launch failed with `NSOSStatusErrorDomain Code=-10827 kLSNoExecutableErr` despite a present executable and valid codesign; direct sandbox launch exited `134` with no log. Running the same signed bundle executable outside the shell sandbox opened the game successfully. First CUA path selection returned `timeoutReached`; selecting `com.armantarkhanian.graygoo` after launch succeeded.

2026-09-04: Final native graphics pass showed washed-out coral, water, and skatepark colors with sun energy `1.4`, fill `0.55`, and ambient `0.62`. Reduced those values to `0.7`, `0.2`, and `0.25`; native screenshots preserve color and shape. The orthographic reveal exceeded the field width, exposing terrain edges; cap the rotated viewport footprint to the field and anchor camera height to the ground.

2026-09-04: The first rendered steering driver's initial frame included shader startup, so its quark result `52.9001687448162 average_fps` is not a steady-state measurement. Subsequent coral result was `59.970235691817 average_fps`, `17.359 p95_ms` at `(1920.0, 1080.0)`. Final measurement must exclude the full startup frame and use wall-clock intervals. Two launch methods briefly made separate game instances; close the CUA instance and terminate only the identified shell-launched test PID `38391` before measuring.

2026-09-04: The temporary straight-line steering driver stalled in Skatepark Bowl at radius `1.14886466400894`, near `(6.91396, 1.265403, 1.399892)`, while pursuing a skate deck; this is not evidence that the entire level is blocked. A driver must try another route around solid obstacles before declaring food inaccessible. Packaged release launch with `--script /tmp/tasty-physical-playthrough.gd -- --start=2` started the normal Quark scene instead; do not attribute external-driver measurements to the release app.

2026-09-04: Blender asset colors were authored as display sRGB but passed directly into linear shader inputs. `Constituent coral` intended `#F26B6B` imported into Godot as `f9adadff`. Convert in rgba() before Blender material assignment; regeneration and Godot import now return `f26b6bff` exactly.

2026-09-04: Enlarging fabric to extent `(44, 42)` made a fixed 64-cell surface too coarse. Replaced marching-triangle remeshing with a continuous plane and filtered depletion texture at ~0.25-unit spacing. Temporary large-pool check returned `resolution=352`, `spacing=(0.25, 0.238636)`, `changed_cells=45`, `local_volume=0.00980295808264`; nearest-cell search matched brute force. GPU appearance remains to verify.

2026-09-04: Automatic approval review rejected the read-only Kimi visual-code review because it would transmit private project source to an external service without file-specific approval. An explicit approval question is pending; no source was sent. Continue local work without bypassing the rejection.

2026-09-04: Larger tide pools exposed an integration hot path: game._physics_process called closest_point on every pool every frame before attempting a local bite. Native run fell to `27.4260548947516 average_fps` with `181.505 p95_frame_ms`. Capture the weighted consumed contact during consume_at, reject out-of-bounds whole-pool contact, and avoid guidance searches for ordinary bites. Bound nearest-cell search by actual unsearched regions instead of a loose distance-from-origin estimate.

2026-09-04: Kimi's first approved read-only source review failed with `error: tool loop exceeded 24 turns` and returned no findings. Retried the same approved files directly in one prompt with filesystem tools disabled; do not treat the failed call as a completed review. The first rejection prevented the whole shell command, including creation of `/tmp/tasty-art-review-prompt.txt`; recreating that prompt was required before the approved retry.

2026-09-04: A follow-up source read assumed `src/goo.gd`; the actual implementation is `src/goo_body.gd`. Check the tracked file inventory before guessing a path.

2026-09-04: Checking a long-running review with `ps -axo pid,etime,pcpu,command` failed with `zsh:1: operation not permitted: ps` inside the sandbox. Use the existing exec session and output files for progress instead.

2026-09-04: Native eye inspection showed cursor offsets could be overpowered by the eye's body-facing neutral direction. Base the pupil ray on the camera direction, then add the bounded screen-space cursor offset.

2026-09-04: Reference lookup encountered `403 Forbidden` on Devolver's game page and a reCAPTCHA on PMC; public search results provided alternative official trailer and university microscopy sources. Watch first failed under sandbox DNS (`Failed to resolve www.youtube.com`) and the free transcript fallback hit the uv cache restriction; retried the public trailer fetch with network permission.

2026-09-04: The permitted Carrion watch retry obtained metadata but failed to download media with `HTTP Error 403: Forbidden`; no video frames were inspected. Do not claim to have watched it. Final pupil headless import exited 0 with only the known sandbox certificate/editor-settings errors, including `Cannot save file /Users/ArmanTarkhanian1/Library/Application Support/Godot/editor_settings-4.7.tres`.

2026-09-04: Microworld's embedded reference video fetch was throttled (`Online fetch throttled`); its primary microscopy photographs and written observations remain available.

2026-09-04: CUA stopped a window-enlarge action with `The user changed /Applications/Godot.app. Re-query the latest state with get_app_state before sending more actions.` Refreshed the native state and left the user-controlled game running rather than overriding their interaction.

2026-09-04: Metric-scope search included nonexistent `docs/design/scenes.json`; the accepted catalogue lives in `docs/design/selection.json`. Runtime scene configuration remains in `src/world.gd`.

2026-09-04: The user's deliberate turn interruption also left `goo_body` interrupted. Root sent `send_message` updates, which queue text but do not restart an interrupted agent, and mistakenly waited for implementation progress. `interrupt_agent` returned `previous_status: interrupted`; `followup_task` resumed it. Leaf confirmed no filament files or new travel results existed at that point. After a turn-abort, inspect agent status and use followup_task to resume unfinished work.
- 2026-09-04: Opening the native Godot UI through `cua.getApp('/Applications/Godot.app')` failed after 124.1357 seconds with `Sky Computer Use request timed out`; no screenshot or UI state was returned.
- 2026-09-04: Native UI retry using `org.godotengine.godot` was rejected as ambiguous because `/Applications/Godot.app` and `/Applications/Godot_mono.app` share the bundle ID; selecting `/Applications/Godot.app` succeeded.
- 2026-09-04: The last-meal HUD canary failed at `/tmp/tasty-hud-check.gd:26` with `SCRIPT ERROR: Assertion failed.` because the running Cosmos scene consumed fabric during the awaited frame and correctly replaced the test portrait. Paused world simulation before testing the explicit HUD values; this was a harness race, not a portrait defect.
- 2026-09-04: Root and the goo leaf independently chose `/tmp/tasty-filament-final.gd`; the leaf's geometry canary overwrote root's unrun visual driver. Detected before native launch. Root now owns `/tmp/tasty-root-rendered.gd` and `/tmp/tasty-root-rendered-results.json`; task-specific ownership prefixes avoid evidence-file collisions.
- 2026-09-04: `check_artifact.py` rejected an ordinary reference link to the approved Postplan plan with `FAIL A5 remote src/href asset (artifact must be self-contained)`. Removed the external anchor from the results artifact; the plan URL remains in the project notes.
- 2026-09-04: A native CUA click supplied `{x:398,y:281}` and returned `elementIndex must be an integer`; the documented coordinate tuple `[398,281]` succeeded.
- 2026-09-04: The first continuous-rolling motor circulated material but failed the independent speed-64/radius-0.55 canary: maximum shell extent `7035.628995` radii and stop drift `801.1463` units, while volume stayed near its target. A finite rotation chord blended with retained tangential velocity still injected expansion. Separated exact prescribed material flow from residual deformation velocity instead of hiding the failure behind a volume-only check.

- 2026-09-04: The first exact-advection slow-motion probe remained finite but ended at `(99.72793, 34.63086, 0.000739)` against the +100 field edge. Volume and finite-position checks missed boundary climbing. Blocked outward propulsion at the invisible boundary and added center-height/extent assertions to the existing root canary; the final center stayed at Y `0.823191`.
