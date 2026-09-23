# 05: Level 1 growth bug and double default speed

**What to build:** The base movement speed doubles, so 100% on the slider equals the old 200%, on native and browser builds. Find why Sugar Water food gives too much growth, and fix the cause. Sugar Water then takes about eight minutes at the default speed.

**Blocked by:** 02 Tasty Planet eat rule.

**Scope extension (orchestrator, 2026-09-22):** after the Level 1 fix, tune Sugar Water so the route takes 6 to 10 simulated minutes at 100%, with jumps spread roughly evenly and a longer last view. Restore winnability of Skatepark Bowl and Cosmic Web under the eat rule with the smallest content change that makes sense, without redoing their layouts (tickets 10 and 11) or tuning their pacing. Every level must be winnable and `scripts/check_worlds.gd` must pass. Route runs are headless and muted; native windows only for required screenshots.

**Status:** claimed by opus-5.5 ticket agent

- [ ] The cause of the fast Level 1 finish is named in `memory-bank/progress.md` with the numbers that show it.
- [ ] The route driver finishes Sugar Water in 6 to 10 minutes at 100%.
- [ ] The settings menu shows 100% as the default, with no truncation.
