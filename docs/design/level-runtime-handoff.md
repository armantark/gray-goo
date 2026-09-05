# Ladder data for the HUD

Each world config has `tiers` and `jumps`, with matching indices. Both lists have five entries for the demo levels. Entry zero is the initial view. Entries one through four are the four size jumps. Each jump has a `radius` and `view_size`.

`world.current_tier` is the active zero-based index. `world.config.tiers[world.current_tier]` is its display name. The game advances through all crossed thresholds, including when one meal crosses more than one threshold. The initial camera uses `jumps[0].view_size`.

`meters_per_unit`, `initial_radius`, and `goal_radius` remain available. Scene rebuilds can add `meters_per_unit` to a jump when its physical calibration changes. Root will keep world.config.meters_per_unit current at each jump. The HUD can read that field during its update.

The step-one values establish the data contract. The scene rebuilds will set final radii, view sizes, titles, and food content. The speed law and HUD source stay owned by Fable.
