# Product context

The experience centers on eating smaller objects and growing as gray goo, with gameplay similar to the original Tasty Planet, a top-down view, and smooth cartoon 3D assets with cel shading and outlines. The four-level proof of concept must establish gameplay and visual quality before expansion toward 60 levels. Everything informs scale relationships and diversity of settings at a shared scale. Background story is not part of the current design discussion.

The user is primarily playing for themselves. Native desktop play on their Mac takes priority; browser distribution is not a proof-of-concept requirement.

Reference mechanics verified against https://www.dingogames.com/tastyplanet/instructions/gameplay.htm on 2026-09-04: mouse or arrow-key movement; eat smaller objects and grow; reach a target size to complete a level; helper arrow identifies a nearby edible target. The user chose untimed play and deferred damage. Movement, physics, and interactions should make the world interesting without combat or time pressure.

The prototype should explore a representative range of scales; its exact four-level lineup is pending. The user is comfortable with cartoon subatomic representations and expects larger scales to provide richer interactions. The target duration is roughly 3–5 minutes per typical level.

The full campaign culminates at cosmic scales and consuming spacetime. Puddle consumption is local and progressive: each contacted section disappears into the goo, leaving the rest of the translucent liquid behind. The goo's rolling, squashing, stretching, and sticky contact with the floor are central to the intended feel.

Level inspiration must come from the first Tasty Planet itself. The user rejected the initial unsourced catalogue. Retrieved StrategyWiki chapter guides provide concrete layouts: a face made from dice and dominoes, domino mazes, mice around cheese, and fish feeding chains. The official Mac demo at https://www.dingogames.com/tastyplanet/downloadmac.htm supplies primary level XML for the numbered campaign. The inspected bundle reports 1.4.1; it is the first game's current distribution, not confirmed identical to its 2006 release. docs/design/sources/original-levels.json records the source filenames, hashes, and entity/controller labels. These are data observations, not gameplay measurements. No original assets or level definitions are copied into the project.

The user wants zero, one, or two optional size jumps per level, plus emergent formations and edible part-to-whole progressions. Their examples are quarks to protons to nuclei, and coral polyps to the remaining coral. The coral example is user-supplied and is not attributed to the original game's Ocean levels.

Original levels are inspiration seeds only. Do not recreate their 60-level campaign, enforce one-to-one mappings, or generate a fixed set of reskins for every original level. Use their pacing, playful arrangements, interactions, and growth payoffs to invent fresh scenes. Source references document influences, not required replicas.

Player controls: WASD or arrow keys for directional movement; hold the mouse button to steer toward the pointer. Both methods share the same movement physics and deformation.
