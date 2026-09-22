# Ladder data for the HUD

Each world config has `tiers` and `jumps`, with matching indices. Both lists have five entries. Entry zero is the initial view. Entries one through four are the four size jumps. Each jump has a `radius` and `view_size`.

`world.current_tier` is the active zero-based index. `world.config.tiers[world.current_tier]` is its display name. The game processes all crossed thresholds, even when one meal crosses several thresholds. The camera grows within each view and then moves to the next view.

`meters_per_unit`, `initial_radius`, and `goal_radius` remain available. A jump can specify `meters_per_unit`. `GameWorld.advance_scale()` updates the current config value. The HUD can read that value each frame.

The four scene definitions live in `src/levels/`. They contain the current names, radii, and view sizes. `src/world.gd` loads each scene. Fable owns `src/hud.gd`, `src/goo_body.gd`, and the body-length speed law. Astra did not change those files or that formula.

## Remaining HUD work

1. Read the five display names from `world.config.tiers`.
2. Read the active index from `world.current_tier`.
3. Add the specimen readout and ladder strip from the approved HUD design.
4. Show the initial Cosmic Web scale in light years. Its calibration is `9.4607e15` meters per world unit. The existing formatter shows petameters.
5. Read the current `world.config.meters_per_unit` after each jump. The existing HUD copies that value only in `configure()`.

The native view inspector stages camera views without food consumption. Its images do not establish completion times. `scripts/drive_levels.gd` uses ordinary movement input and records actual routes at 100% speed unless `--speed=` sets another speed for the run.

## Body work

The next body experiment has a separate brief in `memory-bank/plans/goo-body-brief.md`. Do not start it while the level rebuild still owns the checkout.

## Body performance finding for Fable

The expanded Sugar Water scene has a contact bottleneck during ordinary movement. This replaces the earlier staged-only characterization.

A 20-second native route at the default speed averages 7.30575653765586 frames per second, with 148.112 milliseconds at the 95th percentile. The same route with an empty obstacle callback averages 57.9811818051833 frames per second, with 18.12 milliseconds at the 95th percentile. The empty callback exists only in a temporary diagnostic script. Production collision remains enabled. The routes diverge slightly because contacts change motion; this comparison isolates contact cost, not identical positions.

The final Sugar Water camera view averages 68.6052681554562 frames per second when staged at its jump threshold. This does not establish live movement performance. The 20-second Cosmic Web native route averages 43.6035259758876 frames per second, with 47.355 milliseconds at the 95th percentile. Neither short route is a completion test.

Fable owns the body solver. Resolve the dense-contact case as part of the body work. Preserve the existing body as the requested comparison option. Do not call the rebuild performance-complete while this case remains.

Evidence: `builds/level-verification/report.json`. Reproduce the production case with:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --script scripts/drive_levels.gd -- --start=0 --last=0 --limit=20 --output=builds/sugar-contact-canary.json
```
