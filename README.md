# Gray Goo

A standalone Mac eat-and-grow game with four scenes: Sugar Water, Coral Colony Tide Pool, Skatepark Bowl, and Cosmic Web. Each place has five food tiers and four size jumps. Objects belong to visible larger structures, and eating their parts changes what remains.

## Play

Open `builds/Gray Goo.app` after exporting. The game starts in the particle field. Use the Scenes menu to replay any of the four scenes.

| Control | Action |
| --- | --- |
| WASD or arrow keys | Move relative to the screen |
| Hold left mouse button | Steer toward the pointer |
| Hold right mouse button and drag | Rotate the camera |
| Scroll wheel | Zoom within the current scale |
| Escape | Open or close the scene menu |

Eat smaller objects to reach the goal size. A pointer and yellow outline identify the nearest edible object. The bottom-left portrait shows the last consumed item. Each scene has its own starting size. The HUD shows body diameter and goal diameter in metric units. The goal-reaching bite celebrates completion; the scene remains playable until you choose Next level.

Open the scene menu to adjust Movement speed from 10% to 200%. The default is 100%, and the setting applies to both keyboard and mouse steering. The game saves it between launches.

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

The editable Blender library stays in `assets/source`; Godot imports the textured GLBs. Model builders live in `scripts/asset_builders/`. The game uses the Mobile renderer at a fixed 1920 × 1080 render size.

Check that each tier can fund the next jump and each food belongs to a visible whole:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_worlds.gd
```

Require `WORLD_CHECK_OK=true` and no script errors. Godot can return exit status zero after a script parse failure.

Use `-- --trials=8 --seed=9217` for a randomized food-order sweep. Check wheel pivots and compare cached obstacle queries with the full scan:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_wheel_spin.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_obstacles.gd
```

Record complete native routes through all four levels with the saved movement speed at 100%:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/drive_levels.gd -- --output=res://builds/level-routes.json
```

The driver uses ordinary directional input. It saves progress, jump times, completion times, frame measurements, and one image per reached view. `--start=2 --last=2` selects only the skatepark. `--limit=900` sets the verification timeout in seconds; it does not add a game timer.

`--seed=439` varies target choices reproducibly. The driver retries another target if it stops moving or makes no growth for 15 seconds, so it cannot chase an inaccessible moving part forever.

For faster pacing experiments, use `--headless --fixed-fps 60` before `--script` and `--simulation-clock` after `--`. Those reports use simulation seconds and identify the headless display server. They do not establish native completion time or render performance.

Inspect untouched scenes at all five sizes and measure their uncapped render performance:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/inspect_levels.gd
```

These staged views do not consume food and are not completion-time evidence. They can retain dense colliders that a normal route has already eaten.

Use `-- --level=0 --tier=4` for a single view. Stop other simulation jobs before measuring native frame rates.

## Manual verification

Play each scene from its starting size through completion. Check keyboard and mouse steering, camera rotation and limits, object engulfing, retained food color, attached parts, and the nearest-food pointer. Watch the body reach and grip with uneven forward lobes while rear contacts stretch and peel. Release the controls for several seconds and check that it spreads into an irregular shallow puddle with unequal, slowly spreading lobes; move again and check that it gathers into a rolling mass. During keyboard steering, check that the pupils look toward the highlighted target. Hold the left mouse button to switch to cursor-following eyes, and confirm that the chosen gaze mode persists after release. After a colored bite, check that the contact patch blends slowly and leaves a lasting tint. In the tide pool, cross the water and check that only local sections disappear. In the skatepark, nudge moving boards and cross the curved ground. In spacetime, consume the final fabric and keep moving in the void. After each goal, verify continued play and Next level.

Change Movement speed in the scene menu, resume play, and check that steering responds at the selected rate. Restart the app and check that the setting remains selected.

Verification combines behavior canaries, randomized world checks, ordinary-input routes, and native visual/performance checks. In the skatepark, confirm that wheel hubs stay on their axles while the wheels spin. The build plan is under `memory-bank/status-updates` and remains unchanged for comparison with results.

## Record a motion clip

The recording driver uses ordinary directional input in the tide-pool scene, including turns, seven seconds of idle melting, and resumed movement. Godot's movie mode records fixed simulation frames; use the live game for performance measurements.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://scripts/record_motion.gd --write-movie builds/motion-capture.avi --fixed-fps 60 --quit-after 1020 --disable-vsync
ffmpeg -ss 2 -i builds/motion-capture.avi -t 15 -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -movflags +faststart builds/motion-preview.mp4
```
