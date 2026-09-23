# Gray Goo

An eat-and-grow game for Mac and desktop browsers with four scenes: Sugar Water, Coral Colony Tide Pool, Skatepark Bowl, and Cosmic Web. Each place has five food tiers and four size jumps. Objects belong to visible larger structures, and eating their parts changes what remains.

## Play

Download the standalone Mac app from [GitHub Releases](https://github.com/armantark/gray-goo/releases/latest), or [play in your browser](https://gray-goo.tarkavor.chatgpt.site). The browser version is public and requires no login. The Mac app is ad-hoc signed and is not notarized; macOS can require **Privacy & Security → Open Anyway** after the first launch attempt.

For a local build, open `builds/Gray Goo.app` after exporting. The game starts in the particle field. Use the Scenes menu to replay any of the four scenes.

| Control | Action |
| --- | --- |
| WASD or arrow keys | Move relative to the screen |
| Hold left mouse button | Steer toward the pointer |
| Hold right mouse button and drag | Rotate the camera |
| Scroll wheel | Zoom within the current scale |
| Escape | Open or close the scene menu |

Eat smaller objects to reach the goal size. A pointer and yellow outline identify the nearest edible object. The bottom-left portrait shows the last consumed item. Each scene has its own starting size. The HUD shows body diameter and goal diameter in metric units. The goal-reaching bite celebrates completion; the scene remains playable until you choose Next level.

Open the scene menu to adjust Movement speed from 10% to 200%. The native default is 100% and the browser default is 200%, and the setting applies to both keyboard and mouse steering. The game saves it between launches. The Body selector offers Shell and Procedural; it also persists between launches. Switching bodies keeps the current position, size, and food pigment. The Music button enables or mutes the current scene’s original music and saves the choice.

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

Change Movement speed in the scene menu, resume play, and check that steering responds at the selected rate. Restart the app and check that the setting remains selected. Switch Body in both directions during a meal, then verify position, size, color, and camera continuity. Restart once more to check the body setting. Visit all four scenes and check that each plays its own song. Mute Music, change scenes, and confirm it stays muted; enable it and restart to verify persistence.

Verification combines behavior canaries, randomized world checks, ordinary-input routes, and native visual/performance checks. In the skatepark, confirm that wheel hubs stay on their axles while the wheels spin. The build plan is under `memory-bank/status-updates` and remains unchanged for comparison with results.

## Record a motion clip

The recording driver uses the saved speed and the same input route for both bodies: move, turn, stop for six seconds, resume, and turn again. It adds one labeled plankton on resume, consumed through ordinary contact. It does not change saved settings. Movie mode supplies visual evidence; run without movie mode to measure native wall-clock performance.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/record_motion.gd --write-movie builds/goo-procedural.avi --fixed-fps 60 -- --body=procedural --duration=18 --output=builds/goo-procedural.json
ffmpeg -i builds/goo-procedural.avi -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac -movflags +faststart builds/goo-procedural.mp4
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script scripts/record_motion.gd -- --body=shell --duration=18 --output=builds/goo-shell-native.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_bodies.gd
```

Use `--body=shell` for the matching shell clip. Require `BODY_CHECK_OK=true` from the body canary. The procedural skin has an uneven idle spread and regathers on movement. Its five individual grips and rolling circulation are less distinct at game camera distance; the comparison remains an experiment.

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
