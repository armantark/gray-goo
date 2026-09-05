# Prototype design frontier

This is a running interview map, not a settled implementation plan. Ask small numbered rounds of independent decisions whose prerequisites are settled, each with a recommendation. Wait for answers before moving to their dependent questions. Use the grill-me, grilling, and domain-modeling skills. Do not implement until the settled design and explicit assumptions receive final confirmation.

## Settled prerequisites

- Four representative prototype recommendations from the accepted scene pool; the full campaign remains future scope.
- Independent starting size per level, continuous growth within each level, and zero to two optional camera size jumps.
- Every consumed item contributes growth; goal size completes the level, with the milestone usually supplying the final growth.
- Untimed play and no damage; responsive rolling goo, sticky contact, stopping drift, and physical deformation.
- WASD/arrow keys and held mouse steering share movement physics.
- Engulf and shrink on contact without pausing movement; large bites stretch the goo, and puddles are consumed locally.
- Top-down smooth cartoon 3D, cel shading and outlines, standalone Mac delivery.

## Current independent frontier

1. Edibility: visible bulk versus longest dimension for elongated objects. This unblocks threshold feedback and irregular-object tuning.
2. Camera presentation: straight overhead versus tilted overhead, and fixed versus player-controlled orientation. This unblocks framing and occlusion choices.
3. Completion flow: immediate scene exit versus optional continued eating after reaching goal size. This unblocks completion UI and progression flow.

## Held for later rounds

- Edible-target feedback depends on the edibility rule and camera presentation.
- Occlusion treatment depends on camera presentation.
- Scene progression controls depend on completion flow.
- Physics implementation and performance feasibility are engineering investigations, not questions for the user.
