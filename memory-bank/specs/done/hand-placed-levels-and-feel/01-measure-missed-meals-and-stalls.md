# 01: Measure missed meals and stalls

**What to build:** The automatic play-through reports, for each level, the time to each size jump and to the goal, the count of contacts with edible food that did not eat on that contact, and the count and length of stalls where the goo presses into an obstacle without progress. Run it on the current game first. The owner's reports then show as measured failures: Level 1 ends in less than one minute at 200% speed, the goo misses or bumps into edible food, and collision with large objects is poor.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] The route driver writes the three new measures per level into its JSON report.
- [x] A baseline report for all four levels at 200% speed is saved under `builds/` and its numbers are recorded in `memory-bank/progress.md`, verbatim.
- [x] The baseline shows at least one of the reported failures as a nonzero count or a Level 1 time under two minutes. If it shows none, record that and describe what the driver misses.
