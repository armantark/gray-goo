# Hand-placed levels and game feel

Settled with the owner on 2026-09-22 through a design interview. Opus 5.5 writes all code for this spec, because the work is a test of its coding ability. Other models do only research and independent review. Use the words in `GLOSSARY.md`: gray goo, tier, ladder, size jump, composite, milestone, eating threshold, placed object, spawn point, mover.

## Problem Statement

The owner plays at 200% speed and finishes Level 1, Sugar Water, in less than one minute. The food in that level gives much too much growth. The goo also bumps into food that looks edible, eats food late or not at all, and leaves parts of composites behind in odd ways. Collision with large objects feels poor in all four levels.

The levels also look generated. Code scatters objects with random offsets, random rotations, and loops that place tens or hundreds of copies. Hard-coded coordinate lists do not help, because the lists were also made by a formula. The owner played Tasty Planet 5 and saw a different method: designers place a small number of objects by hand, and moving food enters from spawn points off screen.

## Solution

The game uses the Tasty Planet eat rule. The goo eats any object that looks smaller than itself, on contact. Objects that look larger block the goo, and the goo slides along them. When an object becomes edible, it shows a clear signal. The arrow that points to the nearest edible object gets bigger when that object gives more growth.

Each level keeps its place and its five-tier ladder. Each level gets a few dozen placed objects at positions chosen by hand, plus spawn points that release small moving food. Composites stay single placed objects. Each level lasts about eight minutes at the default speed.

Every part of game feel gets attention: the eat moment, collision, composite pickups, growth pacing, the size jump, the camera, and movement. The default speed doubles. At the end, Opus 5.5 builds one new 3D model that the new layouts need, and a reviewer from a different model family scores it.

## User Stories

1. As a player, I want to eat anything that looks smaller than the goo when I touch it, so that the rule matches what I see.
2. As a player, I want objects that look larger than the goo to block me, so that I know what I cannot eat yet.
3. As a player, I want the goo to slide along a large object, so that the goo does not stick or shake against it.
4. As a player, I want an object to show a clear signal at the moment it becomes edible, so that I notice new food after I grow.
5. As a player, I want many objects to signal together when one meal lets me eat a whole class of objects, so that the growth step feels like a reward.
6. As a player, I want the arrow to point to the nearest edible object, so that I always know where food is.
7. As a player, I want a larger arrow when its target gives more growth, so that I can choose between a small near meal and a large one.
8. As a player, I want each meal to pull into the goo with a sound, a pulse, and a small burst, so that each meal feels satisfying.
9. As a player, I want larger meals to make a larger sound, pulse, and burst than small meals, so that big meals feel big.
10. As a player, I want food to disappear on the first contact that eats it, so that I never pass over food and leave it.
11. As a player, I want edible food never to act as a wall, so that I never bump into a meal.
12. As a player, I want the parts of a composite to act as their own objects until I eat the whole, so that I can take a wheel off a board and then eat the board.
13. As a player, I want the whole composite, and every part that is left on it, to go when I eat it, so that no stray parts stay behind.
14. As a player, I want to lose no part of a composite through the ground or into the air, so that the composite looks solid.
15. As a player, I want growth to feel steady, so that I do not wait a long time between meals and I do not grow very fast from one meal.
16. As a player, I want Level 1 to take about eight minutes at the default speed, so that it does not end in one minute.
17. As a player, I want every level to take about eight minutes at the default speed, so that the four levels have the same length.
18. As a player, I want the default speed to be twice the old default, so that the game feels fast without a change in settings.
19. As a player, I want the speed slider to still let me play slower or faster, so that I can choose my pace.
20. As a player, I want a size jump to have a short slow moment, a smooth zoom out, and the name of the new tier, so that each jump feels like an event.
21. As a player, I want the camera to look a little ahead in the direction I move, so that I see food before I reach it.
22. As a player, I want the camera to follow smoothly without shaking, so that movement feels good.
23. As a player, I want each level to look like one place that a person designed, so that it does not look random.
24. As a player, I want objects to form groups with a visible reason, such as litter at the low point of a bowl, so that the place feels real.
25. As a player, I want clear paths and open space between groups, so that I can move freely and plan a route.
26. As a player, I want small moving food to enter from the edges and from fixed places, so that the first tier never runs out of food.
27. As a player, I want spawned food to leave the level after some time when I do not eat it, so that the level does not fill up.
28. As a player, I want spawned food to fit the place, such as plankton in a current or photons in straight lines, so that the movers look natural.
29. As a player, I want spawn points to release larger movers after each size jump, so that each tier has moving food of the right size.
30. As a player, I want the largest objects visible from the start, so that I see my goal and want to grow.
31. As a player, I want the milestone of each level in a place that a person chose, so that the last meal feels planned.
32. As a player, I want the game to hold 60 frames per second at 1920 × 1080, so that the new movers and effects do not slow it down.
33. As a player, I want the browser build and the macOS build to have the same changes, so that I can play either.
34. As the owner, I want a new 3D model built by Opus 5.5, looked at from several angles, and changed until it passes, so that I can judge its modeling ability.
35. As the owner, I want a reviewer from a different model family to score that model, so that the score is independent.
36. As the owner, I want screenshots of every layout from the game camera, reviewed before each level is called done, so that "handmade" is checked on screen and not only in code.
37. As the owner, I want a commit and a playable build after each step, so that I can stop the work at any step and keep the value.
38. As a future designer, I want placed objects stored as a readable table per level, so that I can see and change each object.
39. As a future designer, I want a top-down layout image of each level, so that I can see the whole layout at once.

## Implementation Decisions

**Eat rule**

- An object is edible when its visible footprint radius is smaller than the goo radius times one global margin. The margin is one constant, set by play and screenshots.
- The eating threshold becomes the visible size. The separate threshold argument goes. The tier number controls only which objects are shown and which small objects are hidden after a size jump.
- The eat check and the blocking check use the same edibility function. An edible object never enters the obstacle list.
- Contact eats on the first touch of the goo surface with the object footprint. The current deep-overlap test goes.
- Composite parts and wholes keep separate sizes and separate edibility. The rules in `memory-bank/systemPatterns.md` for composite consumption stay: removed parts do not reduce the whole's size, and eating the whole takes all surviving parts once.

**Collision**

- The goo body's custom obstacle projection is the only thing that blocks the goo. Diagnose the current poor collision before any change. Food objects are also physics bodies that collide with the ground and with each other, and that second system is a first place to look.
- Keep the goo's shape and motion model. Change only how it responds to obstacles.

**Edible signal and arrow**

- When an object changes from blocked to edible, it plays a short signal, such as a bounce and a flash. It plays once per change.
- The arrow keeps its target rule, the nearest edible object. Its size grows with the target's growth reward relative to the goo's current volume, between a minimum and a maximum size.

**Eat moment and size jump**

- The existing meal animation, bite sound, and burst stay. Their strength scales with the meal's reward relative to the goo's volume.
- The goo pulses on each meal.
- A size jump gets a short slow moment, an eased zoom out, and a display of the new tier name. The HUD already reads the tier names from each level's `tiers` list.

**Speed and camera**

- The base speed constant doubles, so 100% on the slider equals the old 200%. The native default and the browser default are both 100%. The slider range stays the same.
- The camera looks ahead in the direction of movement, by a fraction of the view size, with smoothing.

**Level layout**

- Each level's placed objects are a table in its level definition. One row holds the object kind, the position, the rotation, the size, the tier, and an optional parent whole. Positions and rotations are chosen by hand.
- The build path for placed objects uses no random numbers. Two builds with different seeds give the same placed objects.
- Composites are built by their own functions from their parts, and each is placed as one row. Their internal structure, such as the counted nucleons of a nucleus, stays exact.
- Ground shape functions, backgrounds, and the level's local motion rules stay in the level scripts. Background objects also get placed by hand, not in loops with random offsets.
- A new top-down capture renders each level's whole field with its placed objects and spawn points. It is the main layout tool.

**Spawn points**

- A spawn point is either a fixed position or a stretch of the field edge. It has an object kind, a size range, a tier range, a release rate, a limit of live objects, a movement rule, and a lifetime after which the mover leaves the level.
- A spawn point releases only objects that belong to the current tier's size band, so movers stay the right size after each jump.
- Movement rules come from the existing level motion: drift, straight lines, currents, loops. Random timing and random paths are allowed for movers.
- The placement grid assumes that food stays within a set distance of its placement. Movers break that assumption, so movers must update the grid or be queried in a separate list.
- Spawned movers count toward the growth budget of each tier.

**Growth pacing**

- Each object gives growth equal to its volume, as now. Find why Level 1 food gives too much growth before any retune. The owner sees a finish in less than one minute.
- Tune each tier so the route driver reaches each size jump after about 90 seconds at the default speed, and the goal after about eight minutes. The last view can be longer.

**3D model test**

- Pick one new model that the new layouts need. Build it through the project Blender connection, described in `memory-bank/techContext.md`.
- Capture four angles after each revision, look at them, and revise.
- Use the fixed rubric in `memory-bank/plans/final-shipping.md`. The weighted score must exceed 8.0.
- The critic must be from a different model family and must accept images: GPT-6 Astra through Codex, with GLM 5.3 Flash as a second vote. An Opus critic is not independent for Opus work.

## Testing Decisions

A good test checks behavior that a player or the owner can see: what the goo eats, what blocks it, how long a level takes, and what the screen shows. A test must not check internal numbers that only restate the code.

Seams, from the highest layer down:

1. **Route driver, end to end.** `scripts/drive_levels.gd` plays each level with ordinary movement input at the default speed and records the time to each jump and to the goal. This seam carries the most weight. Add two measures: the count of contacts with edible objects that did not eat on that contact, and the count of frames where the goo pressed into an obstacle without progress. Expect the goal between 6 and 10 minutes for each level, zero missed edible contacts, and no stall longer than two seconds.
2. **Manual visual check.** The native view inspector `scripts/inspect_levels.gd` and the new top-down capture make images of every tier view and every layout. Opus looks at each image before a level is called done. At the end, run the browser build through Pinchtab and do one short play of each level. This seam carries the "handmade" and game feel judgment. Look for truncated text in every image.
3. **World check, integration.** `scripts/check_worlds.gd` builds all four levels. Add two checks: placed objects are identical across two seeds, and every placed object names a whole. Keep the growth-budget check, now with spawn points included.
4. **Body and eat check, integration.** `scripts/check_bodies.gd` already drives real food contact. Add three cases: a smaller object from a later tier is eaten on contact, a larger object blocks, and eating a composite whole leaves no active parts.
5. **Obstacle check.** Keep `scripts/check_obstacles.gd` as it is, updated for the new edibility function.

Do not add unit tests for the eat margin, the arrow scale, or the spawn timer. The route driver and the images cover them.

Performance stays a gate. Each level's 20-second native route must average at least 58 frames per second at 1920 × 1080, measured with the `--performance` flag.

## Out of Scope

- Hostile movers, damage, and threats. The rule that play is untimed and damage-free stays for this work.
- A fifth level.
- A custom level editor.
- Changes to the goo's shape and motion model, other than its response to obstacles.
- Changes to the places, the ladders, or the tier names.
- New music.
- Any copy of the original game's assets or level data. `memory-bank/research/original-level-format.md` is inspiration only.

## Further Notes

- Do the work in this order. The eat rule changes how every layout plays, so it comes first.
  1. The eat rule, collision, composite pickups, and the default speed.
  2. The Level 1 growth bug.
  3. The eat moment, the edible signal, the arrow, the size jump, and the camera.
  4. The spawn points, then the placed layout of each level, one level at a time.
  5. The 3D model test.
- Commit after each step to `master`. Do not push.
- The owner's saved speed setting is 200%. After the base speed doubles, that setting gives four times the old speed. The owner must set the slider to 100% once.
- Re-export the macOS app with `scripts/export_macos.sh` and the browser build with `scripts/export_web.sh` at the end.
- The original game places 0 to 81 objects by hand in ordinary levels, and spawn points supply the rest. See `memory-bank/research/original-level-format.md`.
