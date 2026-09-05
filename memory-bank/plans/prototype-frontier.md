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
- Food color leaves a lasting impression on the goo; exact mixing and persistence remain open.
- Coral consists of distinct composite parts; continuous erosion is not the model.

## Current independent frontier

1. Food color: decide whether consumed colors accumulate and persist until displaced by later food, or gradually return toward gray over time.
2. Composite thresholds: clarify whether distinct parts and the remaining whole have separate authored eating thresholds. The previous proposal to reduce the whole threshold as remaining bulk shrinks was not accepted. Preserve the already requested parts-to-whole payoff; do not reopen it as whether whole consumption exists.

## Held for later rounds

- Camera bindings, movement relative to camera rotation, and zoom limits remain lower-priority frontier items.
- The final bite needs a strong visual payoff; specific effects remain open and must preserve readable play.
- Physics implementation and performance feasibility are engineering investigations, not questions for the user.
