# 12: 3D model test

**What to build:** Opus 5.5 builds one new model that the hand-placed layouts need, through Blender, and sees it after each revision in renders from four angles and at game size. It revises until a critic from a different model family scores it above 8.0 on the fixed rubric in `memory-bank/plans/final-shipping.md`. The model then appears in its level.

**Blocked by:** 08 Spawn points and the first hand-placed level, Tide Pool.

**Status:** claimed by opus-5.5 ticket-12 agent

- [ ] Four-angle renders exist for each revision, and each revision has a short note of what Opus saw and changed.
- [ ] GPT-6 Astra scores the final revision above 8.0, and GLM 5.3 Flash gives a second vote. No Opus critic is used.
- [ ] The export check passes for the new GLB, and a native game screenshot shows the model in place.
- [ ] If three successive revisions do not raise the score, the plateau is reported with no lower rubric.
