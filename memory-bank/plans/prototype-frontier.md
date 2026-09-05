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
- Goal-size completion uses brief slow motion, exaggerated squash and stretch, and a strong color pulse. Normal play resumes with Next level available.

- Predictable shape-aware eating thresholds; no precise approach alignment requirement. Suitable thin objects may snap as part of engulfing presentation.
- Opaque foreground obstacles with a subdued goo outline visible through them.

- A nearest-edible pointer supplies food guidance rather than nearby-object highlights.
- Food color starts as a localized patch at the contact point, then gradually blends throughout the goo to leave a lasting tint.
- Coral consists of distinct composite parts with their own thresholds plus a separate whole-colony threshold. Eating parts does not automatically lower the whole threshold. The final bite consumes only surviving parts.

- Screen-relative movement is independent of body facing. Right-button drag rotates only the view; left-button hold steers, and scroll-wheel zoom stays within the active scale view. Do not bind rotation to Q/E. Camera rotation is optional for comfort and inspection.
- Invisible playfield walls constrain movement. The camera stops following near the boundary.

## Frontier status

The current material gameplay decisions are settled. Present the compact build plan and explicit tuning assumptions for confirmation before implementation. The user is not being asked to choose engine internals.

## Engineering and tuning assumptions to surface at confirmation

- Exact camera tilt, zoom bounds, color mixing strength and timing, food budgets, and size thresholds need tuning in the playable prototype.
- Use the four proposed scenes from the accepted pool. Their budgets and object arrangements can change to satisfy the agreed gameplay.
- For the final spacetime scene, propose an invisible movement surface after the last visible fabric disappears so post-completion control remains available.
- Physics implementation and performance feasibility require engineering evidence. A rigid sphere with cosmetic wobble does not satisfy the goo requirement.
- Preserve the agreed single final visual/performance pass. No game implementation has begun.
