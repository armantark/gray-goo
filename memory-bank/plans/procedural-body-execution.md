# Procedural goo body execution

The user authorized `goo-body-brief.md` on 2026-09-05. Start from `0921cfd` on local `master`. The checkout is clean. Do not push or contact another session.

## Contract

The new `src/goo_procedural.gd` extends `GooBody`. It replaces body motion and deformation while it reuses the existing surface renderer, eyes, pigment diffusion, and public interface. `src/goo_body.gd` stays byte-for-byte unchanged. The drive formula stays at four body lengths per second, with a ramp of 6 per second.

`GameHUD.body_kind` stores `shell` or `procedural`. The new `body_requested(kind: String)` signal requests a switch. The scene menu offers Shell and Procedural and stores `controls/body` in the existing settings file. `Game._switch_body(kind: String)` replaces only the goo. It preserves position, radius, tint, growth target, and in-flight meal targets, and rebinds the existing camera subject.

The core respects terrain, obstacle callables, and field edges. Five irregular ground grips stay fixed during contact, then stretch and peel. One continuous skin changes its footprint and height as material rolls through it. At rest it spreads into unequal lobes. Movement gathers the skin again. No separate appendage meshes or soft-body node.

## Ownership

- Root owns `src/goo_procedural.gd`, `src/game.gd`, the new selector in `src/hud.gd`, project notes, native UI, clips, release export, and Git.
- Body verification leaf owns only `scripts/check_bodies.gd`, `scripts/record_motion.gd`, their generated UID files, and scratch files with the `body-verify-` prefix. No other file edits, Git, UI, external model calls, installs, or child agents.

## Verification leaf

Create a bounded body/game canary. Exercise both implementations through actual game paths: contact and growth, retained pigment, goal celebration, camera subject, field/ground constraints, and switching during an in-flight meal. Confirm that a switch preserves position, radius, tint, and growth target. Keep tests focused; do not create a standing test framework. Do not modify production code to make a check pass.

Extend `scripts/record_motion.gd` with `--body=shell|procedural`, `--output=<json>`, and `--duration=<seconds>`. Choose the body without writing the user's settings. Both recordings use the same Coral scene, input route, and seed: move, turn, six seconds of idle, resume, and ordinary contact eating. Record meal counts and phase markers. A native run records wall-clock FPS after warmup; a fixed-frame movie is visual evidence only. Do not hide a missing meal by calling `_eat` directly. If the route needs a deterministic edible fixture, place one in the real scene ahead of the resumed path and label it in the evidence.

CHECK: Godot headless canary after root signals that integration is ready. EXPECT: explicit pass/fail and no script errors. Return the exact commands and any unmet criterion. Root reruns the check and owns native recording/performance verification.

## Root completion

Run the existing shell canary before and after. Verify both bodies at 1920 × 1080 in native Coral play. Record both clips, inspect motion frames, and name the frames that show reaching, planted contact, peeling, rolling, idle spreading, regathering, and eating. Run menu persistence and swap checks. Export the app. Write one results artifact with all measured limits. If a visual criterion cannot be met, retain the implemented option and state the gap explicitly, as the brief permits.
