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

The native view inspector stages camera views without food consumption. Its images do not establish completion times. `scripts/drive_levels.gd` uses ordinary movement input and records actual routes at the saved default speed of 100%.

## Body work

The next body experiment has a separate brief in `memory-bank/plans/goo-body-brief.md`. Do not start it while the level rebuild still owns the checkout.

## Body performance finding for Fable

The probe enlarged the goo to radius 0.38 in an untouched Sugar Water view. The obstacle query returned 11 nearby solids.

| Callback | Average frames per second |
| --- | ---: |
| Original, first sample | 6.68771649664844 |
| Empty obstacle list | 114.355885488537 |
| Original, restored | 6.67880466819408 |

This comparison establishes contact cost in a dense untouched scene. The normal route averaged 56.6764528868166 frames per second, with 18.005 milliseconds at the 95th percentile. It did not show a sustained seven-frame-per-second failure.

Fable owns the body solver. Preserve this case for the proposed body comparison. Evidence: `/tmp/level-root-staged-contact-check.log` and `/tmp/level-final-routes.json`.
