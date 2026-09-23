# Gray Goo

An eat-and-grow game for Mac and desktop browsers with four scenes: Sugar Water, Coral Colony Tide Pool, Skatepark Bowl, and Cosmic Web. Each place has five food tiers and four size jumps. Objects belong to visible larger structures, and eating their parts changes what remains.

## Play

Download the standalone Mac app from [GitHub Releases](https://github.com/armantark/gray-goo/releases/latest). The [browser version](https://gray-goo.tarkavor.chatgpt.site) is public and requires no login, but it still runs the 2026-09-05 release, before the tech demo below. The Mac app is ad-hoc signed and is not notarized; macOS can require **Privacy & Security → Open Anyway** after the first launch attempt.

For a local build, open `builds/Gray Goo.app` after exporting. The game starts in the particle field. Use the Scenes menu to replay any of the four scenes.

| Control | Action |
| --- | --- |
| WASD or arrow keys | Move relative to the screen |
| Hold left mouse button | Steer toward the pointer |
| Hold right mouse button and drag | Rotate the camera |
| Scroll wheel | Zoom within the current scale |
| Escape | Open or close the scene menu |

Eat smaller objects to reach the goal size. A pointer and yellow outline identify the nearest edible object. The bottom-left portrait shows the last consumed item. Each scene has its own starting size. The HUD shows body diameter and goal diameter in metric units. The goal-reaching bite celebrates completion; the scene remains playable until you choose Next level.

Open the scene menu to adjust Movement speed from 10% to 200%. The default of 100% is twice the speed of the 2026-09-05 release, and the setting applies to both keyboard and mouse steering. The game saves it between launches. The Music button enables or mutes the current scene’s original music and saves the choice.

## Tech demo: Opus 5.5 in 24 hours

GPT-6 Astra built the game up to the 2026-09-05 release. From 2026-09-22 15:11 to 2026-09-23 14:40, Claude Opus 5.5 continued that work as a test of its coding ability: one orchestrator session dispatched one Opus 5.5 agent per ticket, often four at a time in separate worktrees, and merged their branches. Other models only reviewed (GPT-6 Astra, Kimi K3, GLM 5.3 Flash). The owner gave direction and played the builds. The result is 131 commits.

### What changed

- **Hand-placed levels.** Code no longer scatters thousands of objects. Each level places 172 to 230 objects by hand, in groups that follow the level's story, with no rings, rows, or even spacing. About 80% of each view's growth comes from placed food, and the world check fails a level outside 70% to 90%.
- **Spawn points.** Moving food enters from outside the camera view: particles in Sugar Water, plankton and fish in the tide pool, caps, boards, skaters and vehicles in the skatepark, and stars and galaxies along the cosmic filaments.
- **Tasty Planet eat rule.** The goo eats anything that looks smaller than itself on first contact, and larger objects block it. The goo slides along what it cannot eat. Edible food never acts as a wall.
- **Pacing.** Each level takes about 7 to 9 minutes, and the goo always has food in reach. A per-level growth scale makes each meal feed less. Before, Sugar Water took less than one minute.
- **Feel.** The default speed is twice the old default, and the goo reaches it. Meals pull in with a sound, a pulse, and a burst that grow with the meal. Food flashes when it becomes edible, and the arrow to the nearest meal grows with its reward. A size jump has a short slow moment, an eased zoom out, and the new tier's name. The camera looks ahead.
- **Simple shapes.** After late size jumps, small composites draw as one shape: a proton as one sphere, a skateboard as one board.
- **New music.** Four upbeat samba, bossa nova, and jazz pieces for a jazz band, rendered with Muse Sounds and a sampled upright bass.
- **One goo body.** The experimental procedural body is removed; the shell body remains.
- **Models.** A new skate shoe, built and revised in Blender by Opus 5.5.

### Findings

1. **A target without the experience in it gets gamed.** The first "6 to 10 minutes per level" target was met by releasing food slowly from spawn points, so the player waited for food at the end of each view. The owner found it boring. The fix was a measure of the experience itself, the longest gap between meals, and a rule that length comes from smaller meals.
2. **The route driver is not a player.** Automatic play-throughs found real bugs (missed meals, stalls, a food grid that lost drifting plankton, molecules that paid growth twice). But about 90 s of one level's time was the driver waiting at a gate for skaters it could not reach, and its stall timer counted waits as stalls. Automated times need their own audit.
3. **Measure the test harness.** For most of the demo, a "simulated" route ran at real-time speed, because headless Godot sleeps about 6.9 ms after each frame. Nobody timed the harness until the owner asked. With the sleep off, a fixed 60 fps clock, and one process per level, a check of all four levels takes about 4 to 5 minutes; before, one run of all four levels with both bodies took about 20.
4. **A probe must measure everything a fix can change.** A fix that made the goo reach its commanded speed measured speed only. The goo also stretched to 3.3 to 4.3 times its width, and the owner saw it at once. A second measure, body length, and one screenshot would have caught it.
5. **Retire failed experiments early.** Two goo bodies doubled every route run, and their speeds differed by 1.5 to 1.8 times, so no level length could suit both. Removing the weaker body made every check faster and simpler.
6. **3D modeling reached recognizable, not great.** Opus 5.5 built a skate shoe and a table coral, looked at renders from several angles after each revision, and revised. Both stopped below the 8.0 rubric bar (7.08 and 6.05 from GPT-6 Astra). The critic's scores moved by about 0.2 on unchanged parts, and the game camera's silhouette mattered more than model detail. The shoe shipped; the coral did not.
7. **Parallel agents work when shared files are few.** Four agents at a time in pooled worktrees merged with conflicts only on one-line lists and notes. The costly failures were outside the code: a quota limit and a session restart stopped agents mid-task, and one wrong flag in a shared brief (`--route-seed` for `--seed`) silently made four agents repeat the same seed.
8. **Agents report misses honestly, but they stop at limits.** Opus 5.5 agents stated plateaus, failed gates, and their own mistakes without prompting. They also obeyed pass limits and old rules literally, so the orchestrator had to resume them to finish.

## Run from the project

Use Godot 4.7.2 with its standard macOS export template. Run these commands from the repository root.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Export the standalone app:

```sh
./scripts/export_macos.sh
```

Regenerate the original assets:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python-exit-code 1 --python scripts/build_assets.py
python3 scripts/build_audio.py
```

The editable Blender library stays in `assets/source`; Godot imports the textured GLBs. Model builders live in `scripts/asset_builders/`. The Mac app uses the Mobile renderer. The web build uses Compatibility without cast shadows to prevent its separate shadow pass from bleaching colors. The game scales its 1920 × 1080 design to the window. Browser controls target a keyboard and mouse; phone play has not been verified.

Check that each tier can fund the next jump and each food belongs to a visible whole:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_worlds.gd
```

Require `WORLD_CHECK_OK=true` and no script errors. Godot can return exit status zero after a script parse failure.

Every tool script that takes flags rejects one it does not know, or a value of the wrong type, and exits with status 2 after listing the flags it accepts.

Use `-- --trials=8 --seed=9217` for a randomized food-order sweep. Check wheel pivots and compare cached obstacle queries with the full scan:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_wheel_spin.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_obstacles.gd
```

Record complete native routes through all four levels at 100% movement speed:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/drive_levels.gd -- --output=res://builds/level-routes.json
```

The driver uses ordinary directional input. It saves progress, jump times, completion times, frame measurements, and one image per reached view. `--start=2 --last=2` selects only the skatepark. `--limit=900` sets the verification timeout in seconds; it does not add a game timer.

`--speed=2.0` drives at 200% for that run without changing the saved slider.

Each level result also counts missed edible contacts (the goo touches food the game calls edible and the food survives that tick), edible-looking contacts (a visible object smaller than the goo that the game will not eat, split into blocked and passed-through), and stalls (drive input into a touched obstacle with smoothed forward speed under 10% of the commanded speed for at least half a second).

`--seed=439` varies target choices reproducibly. The driver retries another target if it stops moving or makes no growth for 15 seconds, so it cannot chase an inaccessible moving part forever. After 30 seconds without growth it ends the level and reports it as `stuck`.

For routine eat-rule and timing runs, use `scripts/route.sh <out_dir> [level ...]`. It runs one headless process per level in parallel on a fixed 60 fps game clock, about 2.3 times faster than real time, and prints each level's time, missed meals, stalls, and longest gap between meals. Add `ROUTE_FLAGS="--seed=21"` for another seed. Those reports use simulation seconds, and each result's `simulated_per_wall_second` shows how much faster than real time the run went. The driver refuses `--simulation-clock` without the engine's `--fixed-fps 60`, which `route.sh` passes. They do not establish native completion time or render performance.

Inspect untouched scenes at all five sizes and measure their uncapped render performance:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/inspect_levels.gd
```

These staged views do not consume food and are not completion-time evidence. They can retain dense colliders that a normal route has already eaten.

Use `-- --level=0 --tier=4` for a single view. Stop other simulation jobs before measuring native frame rates.

## Manual verification

Play each scene from its starting size through completion. Check keyboard and mouse steering, camera rotation and limits, object engulfing, retained food color, attached parts, and the nearest-food pointer. Watch the body reach and grip with uneven forward lobes while rear contacts stretch and peel. Release the controls for several seconds and check that it spreads into an irregular shallow puddle with unequal, slowly spreading lobes; move again and check that it gathers into a rolling mass. During keyboard steering, check that the pupils look toward the highlighted target. Hold the left mouse button to switch to cursor-following eyes, and confirm that the chosen gaze mode persists after release. After a colored bite, check that the contact patch blends slowly and leaves a lasting tint. In the tide pool, cross the water and check that only local sections disappear. In the skatepark, nudge moving boards and cross the curved ground. After each goal, verify continued play and Next level.

Change Movement speed in the scene menu, resume play, and check that steering responds at the selected rate. Restart the app and check that the setting remains selected. Visit all four scenes and check that each plays its own song. Mute Music, change scenes, and confirm it stays muted; enable it and restart to verify persistence.

Verification combines behavior canaries, randomized world checks, ordinary-input routes, and native visual/performance checks. In the skatepark, confirm that wheel hubs stay on their axles while the wheels spin. The build plan is under `memory-bank/status-updates` and remains unchanged for comparison with results.

## Record a motion clip

The recording driver uses the saved speed and a fixed input route: move, turn, stop for six seconds, resume, and turn again. It adds one labeled plankton on resume, consumed through ordinary contact. It does not change saved settings. Movie mode supplies visual evidence; run without movie mode to measure native wall-clock performance.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/record_motion.gd --write-movie builds/goo-shell.avi --fixed-fps 60 -- --duration=18 --output=builds/goo-shell.json
ffmpeg -i builds/goo-shell.avi -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac -movflags +faststart builds/goo-shell.mp4
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/record_motion.gd -- --duration=18 --output=builds/goo-shell-native.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_bodies.gd
```

Require `BODY_CHECK_OK=true` from the body canary.

## Browser build and music

Install the matching Godot 4.7.2 web export templates, then run:

```sh
./scripts/export_web.sh
python3 scripts/web_build.py serve
```

Open http://127.0.0.1:8064/ and press Play. The export compresses WebAssembly and game data in place. Godot’s preloader decompresses them in the browser, so ordinary static servers work without custom response headers.

Each level has its own original jazz-band piece, written in LilyPond under `assets/source/music/`. Sugar Water plays a bright samba-jazz, the tide pool an upbeat bossa nova, the skatepark a soul-jazz boogaloo blues, and Cosmic Web a medium-up swing. The band is flute, trumpet, trombone, saxophones, piano, Rhodes, Hammond organ, guitars, mallets, drums and Latin percussion. MuseScore 4 renders it with Muse Sounds, and the free Larry Seyer Upright Acoustic Bass (Pianobook, SFZ) plays the upright bass through a small sample player. Each Ogg plays its intro once, then loops from its first rehearsal mark without an audible seam. The mute setting remains in effect when scenes change.

Rebuild the music with MuseScore 4, Muse Sounds, LilyPond, sox and FFmpeg installed, and with the bass library unpacked under `.tooling/upright-bass/`:

```sh
uv run scripts/build_music.py
```

Godot’s license and third-party notices are included under `licenses/` and in both exports. All models, textures, sound effects, and music were generated for this project; the music uses sampled instruments from Muse Sounds and the Larry Seyer upright bass. The project is shelved after this release.
