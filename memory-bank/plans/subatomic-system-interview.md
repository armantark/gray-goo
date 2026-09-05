# Subatomic system interview

The user finds the subatomic scene structurally incoherent and explicitly requests a proposed system, a grill-me design interview, and approval before implementation. No gameplay, asset, control, UI, or running-game changes are authorized during this interview. The recent motion pass received positive feedback; the user may separately use Fable for controls/UI, but has not requested dispatch to Fable.

Previously stated constraints remain: fixed sizes for protons and neutrons, elements distinguished by constituent counts, visible orbiting electrons in the textbook-diagram style, no arbitrary loose-quark scatter, and readable particle motion. The remaining design concerns composition, organization, progression, and consequences of eating constituents.

Read-only world leaf owns fact-finding in existing world, food/composite, art/model, and asset-generation source. Return concise evidence of current contradictions and reusable mechanisms, with paths and lines; no edits, external calls, git, UI, new agents, or implementation. Root owns this interview record, glossary/decisions as they settle, and the user questions. The leaf report is evidence, not a design decision or implementation authorization.

Open decision tree: choose the physical setting and endpoint; then define which constituents are available to eat and why; then define what happens to a structure when a constituent is eaten; then settle scale presentation and encounter/progression layout. The first round must put a concrete recommended system in front of the user, not ask them to invent the design.

Root verified the leaf's central findings in source: `scripts/build_assets.py:313` defines one nine-lobe nucleus, and `src/world.gd:151` scales/repositions quark/proton/nucleus food with no electron creation. Larger nucleus names do not encode different compositions. Existing parent/parts growth accounting is reusable, but does not implement identity changes when constituents are removed.

Candidate for user review, not approved: nested matter. Fixed-size nucleons compose explicitly counted nuclei; nuclei and orbiting electrons compose atoms; atoms belong to a larger material arrangement. Placement/movement variation applies to those coherent structures. Growth reveals the larger structure already surrounding the player. Begin within a nucleon/nucleus and progress to whole atoms; defer whole-molecule consumption unless the user chooses a wider endpoint. First decision: whether this level ends at nuclei, whole atoms, or molecules. Recommendation: whole atoms, with molecules/material as the surrounding context. Later decisions depend on that endpoint: material composition, starter food, consequences of constituent removal, and scale presentation.

## 2026-09-05 round 1 (Fable takes over the interview)

The user answered the endpoint question: the subatomic level ends at a whole molecule, with other molecules visible and drifting in the background. Not to scale; cartoon presentation is explicit. The user called the nested-matter candidate a good starting point and asked to dig further.

The user widened the interview: all four demo levels read as structurally nonsensical, and the output of this interview is a contract for Astra to rebuild the four level designs, including requests for new 3D models. The user also assigned Fable the controls and UI work: movement speed must scale with size (too fast at the start, too slow after growth), and the HUD needs a from-scratch revamp.

Fact for the speed question, from `src/game.gd:90`: drive speed is `(2.8 + radius * 0.8) * 3.7 * slider`. In body diameters per second this is about 11.8 at the Quark start (radius 0.5) and about 2.8 at the Quark goal (radius 3.85), a four-fold drop across one level. Camera views are fixed per size band (`camera_sizes` 14 then 26), so on-screen speed jumps at each reveal.

## Round 1 answers (2026-09-05)

Q1 accepted: one recognizable place, nested wholes, the whole was always there, damage shows. The user adds the original game's recycling progression: each level's whole becomes the next tier's ordinary food. In this clone that progression happens inside a level through size jumps. Levels should run about ten minutes with more than two size jumps. The subatomic start is free particles (quarks, positrons, photons), then quarks in formations that form other particles, then protons, neutrons, and electrons, then compound nuclei, then whole atoms, and so on.

Q2: sucrose in water. Q3: see Q1. Q4: constant body-length speed with a smoothing curve matched to the animation; the slider stays. Q5: specimen readout HUD.

Facts: `docs/design/sources/original-levels.json` confirms the recycling pattern (mouse, rat, cat, dog, person, car, house, train). The runtime supports exactly one jump: `src/game.gd:114` uses a boolean `_revealed` and `camera_sizes[1]`. The contract must generalize to a list of jumps.
