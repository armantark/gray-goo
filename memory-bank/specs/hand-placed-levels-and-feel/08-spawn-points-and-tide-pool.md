# 08: Spawn points and the first hand-placed level, Tide Pool

**What to build:** The full layout method, used on Tide Pool. Placed objects live in a table in the level definition, one row per object, with positions and rotations chosen by hand. Spawn points release small moving food that fits the place, sized to the current tier, up to a live limit, and each mover leaves after its lifetime. A top-down capture shows the whole field with placed objects and spawn points. All scatter code for Tide Pool goes, including background loops with random offsets.

**Blocked by:** 03 Smooth collision with large objects; 04 Clean composite pickups; 05 Level 1 growth bug and double default speed.

**Status:** open

- [ ] The world check shows that two builds with different seeds place identical objects, and that every placed object names a whole.
- [ ] The growth-budget check includes spawn points and passes for every tier.
- [ ] Opus reviews the top-down image and every tier view, and writes what it changed after each review in `memory-bank/progress.md`.
- [ ] The route driver finishes Tide Pool in 6 to 10 minutes at 100%, with zero missed edible contacts and no stall over two seconds.
- [ ] The 20-second native route averages at least 58 frames per second at 1920 × 1080.
