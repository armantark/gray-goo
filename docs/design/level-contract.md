# Level rebuild contract

Settled with the user on 2026-09-05 through a design interview. Astra implements this contract. Fable owns the speed law and the HUD, which are outside this contract.

## Goal

Each of the four demo levels is one recognizable place with a five-tier ladder, four size jumps, and about ten minutes of play. Every object belongs to a visible whole. Every model has a proper texture, and every level has a 3D background beyond the field walls.

## Context

The runtime is Godot 4.7.2 with GDScript. The four scenes are built in `src/world.gd`. Food behavior is in `src/food.gd`. Models come from `scripts/build_assets.py`, which runs inside Blender 5.2.1 and writes GLB files plus `assets/asset_manifest.json`. `src/art.gd` replaces every imported material with `shaders/toon.gdshader`, which has only a `base_color` uniform. Today the runtime supports exactly one size jump, with a boolean at `src/game.gd:114` and two entries in `camera_sizes`.

The glossary in `GLOSSARY.md` defines ladder, tier, size jump, composite, milestone, and part-to-whole progression. Use those words.

## The root rule

A level is one recognizable place, and every object in it belongs to a whole that the player can see. Nothing is loose unless something in the scene made it loose. Three patterns apply the rule:

- **Nested wholes.** Every tier of food is a visible part of the next tier. The player eats parts out of a whole, then eats the whole.
- **The whole was always there.** The largest structure is visible from the first frame, as a background or as an object the goo cannot yet eat. Growth and size jumps reveal that it is food.
- **Damage shows.** When the goo eats a part, the whole visibly changes.

The ladder rule: each tier's whole becomes ordinary food in the next tier. The last tier's whole is the milestone. Each view lasts about two minutes. The last view can last longer.

A reviewer must be able to point at any object and name the whole it belongs to. If no whole exists, the object must not exist.

## Shared mechanics

1. Replace `jump_radius` and `camera_sizes` with a `jumps` list in each scene config. Each jump has a `radius` and a `view_size`. Tier zero uses the first view size.
2. Store the ladder in each scene config as a `tiers` list of display names, in order. The HUD reads this list.
3. Keep the composite accounting in `src/food.gd`. Parts and wholes keep separate thresholds. Removed parts do not reduce the whole threshold.
4. Add a `rename` capability to composites. A whole can change its label and its color when a part count changes. Use it for the nucleus and element rule below.
5. Make the camera zoom out slowly with growth inside each view, so on-screen speed does not spike before a jump. Fable sets the speed law; do not change `src/game.gd:90` or `src/goo_body.gd`.
6. Every scene gets a 3D background beyond the field walls. Background objects are not edible and do not collide. They must move or drift where the theme calls for motion.
7. Keep play untimed and damage-free. Keep the metric HUD readout contract and `meters_per_unit`.

## Textures and art

The user rejected flat colors. Every model must get a proper texture. Keep the smooth cartoon geometry, the cel shading, and the outlines.

1. Bake a procedural albedo texture per model inside `scripts/build_assets.py`. Use Blender node textures such as noise, voronoi, and gradients, and bake them to a PNG under `assets/models/`. Do not import external texture packs.
2. Add an `albedo` sampler uniform to `shaders/toon.gdshader`. Multiply it into the existing toon lighting. Keep `base_color` as a tint for models without a texture.
3. Make `src/art.gd` pass the baked texture through when it applies the toon material.
4. Ground surfaces must also get textures: concrete for the skatepark, sand and rock for the pool, a dark spacetime fabric for the cosmos, and a soft field for the particle level.
5. The cosmos level must look like real space. Remove the shimmery purple. Use a near-black background, white and warm star points, and dust in muted browns and blues.

## Level 1: Sugar Water

The place is one drop of sugar water. The milestone is one sucrose molecule. Physical calibration stays `meters_per_unit = 1e-15` for the first view; later views rescale as needed.

| Tier | Food | Visible whole | Damage shows |
| --- | --- | --- | --- |
| 1 Particle soup | Free quarks in three colors, gluons, photons, electrons, positrons | Quarks drift into trios and pairs | None |
| 2 Formations | Pions, then protons and neutrons | Nucleons clump into small nuclei | A nucleon that loses a quark collapses |
| 3 Small nuclei | Electrons, and nucleons pulled from hydrogen and helium nuclei | Carbon and oxygen nuclei form | Nucleus renames by proton count |
| 4 Atoms | Whole hydrogen, carbon, and oxygen atoms with textbook rings | Water molecules and the two sucrose rings | Rings lose electrons |
| 5 Molecules | Water molecules | Sucrose molecule, milestone | None |

Rules:

- Protons and neutrons have a fixed size in every view. A nucleus is a cluster of counted nucleons, not a single scaled model. Oxygen has 8 protons and 8 neutrons. Carbon has 6 and 6. Helium has 2 and 2. Hydrogen has 1 proton.
- Electrons orbit on textbook rings at readable speed. Hydrogen has one ring with one electron. Carbon has rings of 2 and 4. Oxygen has rings of 2 and 6.
- When the goo pulls a proton from a nucleus, the nucleus takes the name and color of the element with that proton count. Oxygen becomes nitrogen, then carbon, then boron, and so on down to hydrogen, then nothing. Losing a neutron only shrinks the cluster. Losing an electron does not rename the atom.
- Photons move fast in straight lines. Gluons move between quarks. Positrons and electrons drift.
- The sucrose molecule has 45 atoms in two linked rings. Build it from atom instances, not as one model.
- The background shows more water and sucrose molecules that drift. They are not edible.
- Loose quarks appear only in tier 1. From tier 2 on, every quark belongs to a nucleon or a pion.

New models: gluon, photon, electron, positron, pion, neutron. Replace `nucleus.glb` with a procedural cluster of nucleon instances. Keep `quark.glb` and `proton.glb`, with textures.

## Level 2: Tide Pool

The place is one rock pool at low tide. The milestone is the great coral crown in the deep end. Physical calibration starts at `meters_per_unit = 0.01`.

| Tier | Food | Visible whole | Damage shows |
| --- | --- | --- | --- |
| 1 Plankton and polyps | Drifting plankton in a current, polyps on branches | Coral branches | A branch that loses polyps turns white and bare |
| 2 Branches and shells | Bare branches, snails, periwinkles | Coral heads, a hermit crab that drags a shell | A head that loses branches shows its base |
| 3 Pool animals | Coral heads, hermit crabs, anemones, sea stars, a small fish that hides under a rock | The rock rim of the pool | An anemone closes when touched |
| 4 Rocks and water | The pool water as a puddle, boulders, the anemone-covered rim | The coral crown in the deep end | The water level drops as the goo mops it |
| 5 The pool | The coral crown, milestone | The beach and other pools beyond the rim | None |

Rules:

- The pool is a real basin. Use the ground height to shape it, with a rim and a deep end. Water is one local puddle inside the basin.
- Plankton drift in one current that follows the basin's shape. Animals move: the crab walks, the fish hides and darts, the sea star creeps.
- The background shows the beach, the rim rocks, and two other pools with their own water.

New models: snail, periwinkle, hermit crab with shell, anemone, sea star, small fish, boulder. Keep plankton, polyp, coral branch, coral fan, rock, and shell, with textures.

## Level 3: Skatepark Bowl

The place is one concrete bowl with a fence and a street beyond it. The milestone is the big quarter pipe. Physical calibration starts at `meters_per_unit = 0.25`.

| Tier | Food | Visible whole | Damage shows |
| --- | --- | --- | --- |
| 1 Litter in the gutter | Bolts, bearings, bottle caps, pebbles in the bowl's low point | Skateboards with two trucks and four wheels | A board that loses a wheel tips over |
| 2 Boards and gear | Whole boards that roll down the bowl walls, helmets, shoes, water bottles on the rim | Skaters on boards | A skater who loses a board stands still |
| 3 Skaters and furniture | Cartoon skaters, benches, cones, trash cans | Rails and quarter pipes | A rail that loses a post tilts |
| 4 Rails and pipes | Rails, the smaller quarter pipes | The big bowl | None |
| 5 The park | The big quarter pipe, milestone | The fence and the street | None |

Rules:

- Use the existing bowl terrain. Litter collects at the low point. Boards roll under gravity along the bowl walls and are moving food.
- Skaters are cartoon figures with no gore. They ride boards along the bowl in loops until eaten.
- The background shows the fence, a street with parked cars, and trees.

New models: bolt, bearing, bottle cap, pebble, truck, helmet, shoe, water bottle, skater, bench, cone, trash can, fence section, parked car, tree. Keep wheel, board, skateboard, rail, and ramp, with textures. Rebuild the skateboard from deck, truck, and wheel parts so wheels are removable parts.

## Level 4: Cosmic Web

The place is one filament of the cosmic web on the spacetime fabric. The milestone is the supercluster, and the fabric puddle is the final meal. Physical calibration starts at `meters_per_unit = 1e21`; adjust it so that the star view reads in light years.

| Tier | Food | Visible whole | Damage shows |
| --- | --- | --- | --- |
| 1 Stars | Red dwarfs, yellow stars, blue giants in one open cluster | The nebula around the cluster | None |
| 2 Nebulae and clusters | Nebulae, star clusters, a black hole with a visible disk | A spiral galaxy | A spiral that loses an arm shows a bare bulge |
| 3 Galaxies | Spirals, ellipticals, dwarf galaxies | A galaxy group | None |
| 4 Groups and clusters | Groups strung along the filament | The supercluster knot | None |
| 5 The web | The supercluster, milestone, then the fabric puddle | The rest of the web | The fabric shows eaten trails |

Rules:

- Spiral galaxies are composites: arms are parts, the bulge is the remainder. Stars in tier 1 are parts of the cluster, and the cluster is a part of the nebula.
- Galaxies and groups lie along a visible filament. The web pattern replaces the random pockets.
- Space looks real. Near-black sky, white and warm star points, muted dust. No purple shimmer.
- The background shows the other filaments of the web and distant galaxies.

New models: red dwarf, yellow star, blue giant, nebula, black hole with disk, elliptical galaxy, dwarf galaxy, galaxy group. Rebuild the spiral galaxy with removable arms. Keep the fabric puddle.

## Non-goals

- Do not change the goo body in `src/goo_body.gd`.
- Do not change the speed formula in `src/game.gd:90`. Fable owns it.
- Do not change the HUD in `src/hud.gd` beyond reading `tiers`. Fable rebuilds it.
- Do not add timers, damage, or difficulty systems.
- Do not copy assets or level data from the original game.

## Steps

1. Generalize size jumps to the `jumps` list and add the `tiers` list. Update the headless world check.
2. Add texture baking and the albedo uniform. Regenerate the existing models with textures. Verify in the running game that textures show.
3. Build the new models for Level 1 and rebuild the Sugar Water ladder. Run it.
4. Build the new models for Level 2 and rebuild the Tide Pool ladder. Run it.
5. Build the new models for Level 3 and rebuild the Skatepark ladder. Run it.
6. Build the new models for Level 4 and rebuild the Cosmic Web ladder. Run it.
7. Add the four backgrounds.
8. Do the final native pass and the export.

Commit after each step.

## Verification

1. Run `scripts/build_assets.py` through Blender with `--python-exit-code 1`. Expect `ASSET_BUILD_OK` and one PNG per model.
2. Run the headless world check for all four scenes. Expect growth-budget closure for each tier, so the food in each view can carry the goo to the next jump.
3. Drive each level with the native motion driver for a full route. Record the time to each jump and to the goal. Expect about ten minutes per level with the default speed.
4. Inspect each level in the native window at 1920 × 1080. Expect textures on every model, a visible background, no purple shimmer in space, and no text truncation.
5. Point at ten random objects per level and name their whole. Expect ten answers.

## Risks and open questions

- Ten minutes per level with five tiers is untested. The food budget per tier is tuning work. Owner: Astra, report the measured times.
- The sucrose molecule has 45 atom instances with rings. Instance count in view five must stay above 60 fps. Owner: Astra, measure it.
- Texture baking adds build time to `scripts/build_assets.py`. Keep the bake resolution at 512 pixels unless a model needs more.
