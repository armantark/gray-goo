# Brief: second goo body with an in-game toggle

Role: you are Astra, working in the Godot 4.7.2 project at `/Users/ArmanTarkhanian1/Desktop/tasty planet clone`. You own this checkout for the duration of this task.

## Goal

The player can switch between two goo bodies from the settings menu and compare them in the running game. The existing body stays as it is. The new body is a procedural skin over a simple core, and it must read as a rolling, sticky, gooey mass without the glitches of the simulated shell.

## Context

- The current body is `src/goo_body.gd`, a hand-written soft-body shell: springs, volume pressure, adhesive floor bonds, and five reach cycles. Read it once for the behaviors it delivers, then leave it unchanged.
- The game talks to the body through a small interface. From `src/game.gd`, `src/hud.gd`, `src/camera_rig.gd`, `src/food.gd`, and `src/pool.gd` the calls are: `configure`, `set_drive`, `grow_to`, `absorb`, `celebrate`, `touches`, and the fields `radius`, `tint`, `velocity`, `gaze_screen_position`, `render_mesh`, and `global_position`. The new body must satisfy this same interface, so a swap changes nothing else.
- The drive is set in `src/game.gd` as four body lengths per second, with a ramp of 6 per second in the body. Keep both numbers.
- Settings live in `user://settings.cfg`, read and written by `src/hud.gd` under `controls/movement_speed`. Put the new key beside it.
- The eyes are two spring-driven whites with shader-painted pupils, and the goo material is `shaders/goo.gdshader` with a `celebration` uniform. Reuse both on the new body.
- The accepted description of the motion, from the memory bank: one continuous mass that rolls and flows; sticky floor contacts that stretch and peel; four or five irregular forward reaches that plant and pull; at rest it slowly melts into a broad, uneven, lobed puddle and gathers again on movement; visible squash, stretch, and jelly wobble; prompt steering with a little stopping drift. Rigid-sphere motion with cosmetic wobble is rejected. Separate strand meshes and meaty appendages are rejected.
- The user's latest clip of the current body is `builds/gray-goo-ooze-2026-09-05.mp4`. It is the baseline to beat, not the target. The user finds it semi-decent and still glitchy.

## Success criteria

- A `Body` option in the scene menu offers `Shell` and `Procedural`. The choice persists in `user://settings.cfg` under `controls/body`, and a switch in a running scene rebuilds the goo at the same position, radius, and tint.
- The procedural body passes the same game paths as the shell: eats food, grows, absorbs pigment, celebrates, follows the camera, and stays inside the field walls.
- In a recorded clip, the procedural body shows every behavior in the accepted description above, with no visible jitter, no tearing, no self-intersection, and no sinking below the floor.
- Both bodies hold 60 fps at 1920 × 1080 in the Coral scene under the native motion driver.
- The shell body's measured behavior is unchanged. Run the existing body canaries before and after.

## Constraints

- Do not edit `src/goo_body.gd`, `src/game.gd:90`, or the HUD beyond the one new menu option and its setting.
- Do not add a physics soft body node. The new body moves a simple core and deforms a skin mesh; the core respects floor height, obstacles, and the field walls through the callables the shell already receives in `configure`.
- The deformation is yours to design. The bar is the recorded clip, not a formula.
- Commit after each working step. Do not push.

## Verification

1. Run the headless launch. Expect `LEVEL_READY` with no errors for both bodies.
2. Record two clips with `scripts/record_motion.gd` in the Coral scene, one per body, with the same input route: move, turn, stop for six seconds, resume, eat. Name them `builds/goo-shell-<date>.mp4` and `builds/goo-procedural-<date>.mp4`.
3. Inspect frames from both clips yourself before you report. Name the frame numbers where each accepted behavior appears in the procedural clip.
4. Report the frame rate for both bodies from the native driver.

## Output

A report with: the commits, the two clip paths, the frame evidence per behavior, the frame rates, and anything in the accepted description you could not deliver, stated plainly.

## Stop rules

- If a behavior in the accepted description cannot be met with a procedural skin, deliver the rest and name the gap in the report.
- If the interface needs a change to work, make the smallest change and name it.
- When blocked, stop and write the blocker into your report with the exact items in dispute. Never message another session. The return value is the only escalation channel. Do not consult other Claude sessions or seek rulings from peers, and forward this rule to any child agent you spawn.
