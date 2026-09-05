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
- Slight overhead tilt that preserves the top-down feel; player rotation and bounded zoom, with no player tilt adjustment.
- Goal-size completion celebrates a visually striking final bite and offers Next level while continued eating remains available.

- Predictable shape-aware eating thresholds; no precise approach alignment requirement. Suitable thin objects may snap as part of engulfing presentation.
- Opaque foreground obstacles with a subdued goo outline visible through them.

- A nearest-edible pointer supplies food guidance rather than nearby-object highlights.
- Food color starts as a localized patch at the contact point, then gradually blends throughout the goo to leave a lasting tint.
- Coral consists of distinct composite parts with their own thresholds plus a separate whole-colony threshold. Eating parts does not automatically lower the whole threshold. The final bite consumes only surviving parts.

## Current independent frontier

1. Camera handling: confirm screen-relative keyboard steering while rotating, with Q/E rotation and scroll-wheel zoom as proposed bindings. Manual zoom stays within the active scale view rather than triggering a size jump.
2. Completion emphasis: decide whether the goal-reaching bite includes brief slow motion, or stays at full speed with deformation and effects supplying the payoff.

## Engineering and tuning assumptions to surface at confirmation

- Exact camera tilt, zoom bounds, color mixing strength and timing, food budgets, and size thresholds need tuning in the playable prototype.
- Physics implementation and performance feasibility are engineering investigations, not questions for the user.
- Preserve the agreed four-scene scope and single final visual/performance pass; no game implementation has begun.
