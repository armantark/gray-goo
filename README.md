# Gray Goo

A standalone Mac eat-and-grow game with four scenes: Quark Dust Ladder, Coral Colony Tide Pool, Skatepark Bowl, and Tablecloth of Everything.

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

The editable Blender library stays in `assets/source`; Godot imports the exported GLBs. The game uses the Mobile renderer at a fixed 1920 × 1080 render size.

## Manual verification

Play each scene from its starting size through completion. Check keyboard and mouse steering, camera rotation and limits, object engulfing, retained food color, attached parts, and the nearest-food pointer. Watch the tendrils plant and pull as you move, then release the controls and check that the body and eyes settle. Move the cursor around the goo and check that both pupils follow it. After a colored bite, check that the contact patch blends slowly and leaves a lasting tint. In the tide pool, cross the water and check that only local sections disappear. In the skatepark, nudge moving boards and cross the curved ground. In spacetime, consume the final fabric and keep moving in the void. After each goal, verify continued play and Next level.

Change Movement speed in the scene menu, resume play, and check that steering responds at the selected rate. Restart the app and check that the setting remains selected.

The project follows the requested basic launch checks and one final visual/performance pass rather than a separate unit/integration/end-to-end test suite. The build plan is under `memory-bank/status-updates` and remains unchanged for comparison with results.
