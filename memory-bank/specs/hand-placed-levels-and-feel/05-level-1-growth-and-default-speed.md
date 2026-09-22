# 05: Level 1 growth bug and double default speed

**What to build:** The base movement speed doubles, so 100% on the slider equals the old 200%, on native and browser builds. Find why Sugar Water food gives too much growth, and fix the cause. Sugar Water then takes about eight minutes at the default speed.

**Blocked by:** 02 Tasty Planet eat rule.

**Status:** open

- [ ] The cause of the fast Level 1 finish is named in `memory-bank/progress.md` with the numbers that show it.
- [ ] The route driver finishes Sugar Water in 6 to 10 minutes at 100%.
- [ ] The settings menu shows 100% as the default, with no truncation.
