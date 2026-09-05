# Scene catalogue contract

## Goal

Draft 240 distinct scene candidates through delegated work. Select 60 for a proposed campaign from subatomic matter to spacetime. Recommend four prototype scenes.

The catalogue is a design proposal, not approval to build 60 levels. The user owns final choices. The root coordinates and checks data; it does not draft the scene ideas.

## Shared design constraints

Use the project brief and active context as source material. The game is a top-down, smooth cartoon 3D eat-and-grow game. Gray goo is a rolling, sticky, deformable mass. Play is untimed. Do not add damage, combat, time trials, dialogue, quests, or new player abilities. World objects can move, carry food, push, collide, feed, collect, or release matter. Puddles remain coherent and translucent while the goo consumes local sections. Prefer interactions that reuse these rules.

Use meaningful relative sizes. Treat particle and spacetime depictions as cartoon abstractions. Do not invent exact scientific size measurements. Scenes within each scale range must differ in matter, layout, or causal interactions, not palette alone. Keep most scenes feasible with ordinary Godot assets and physics. Treat cosmic and spacetime scenes as stylized game ideas, not claims of physical simulation.

## Ownership and interface

The root owns this contract, project memory, checks, aggregation, review artifact, and Git. Three native Luna leaves own separate JSON files in docs/design/candidates/. No shared writes.

- micro owns micro.json, IDs 1–80. Bands: subatomic, atomic, molecular, microscopic.
- everyday owns everyday.json, IDs 81–160. Bands: miniature, tabletop, human, landscape.
- cosmos owns cosmos.json, IDs 161–240. Bands: planetary, stellar, galactic, spacetime.

Each leaf writes one JSON array with 80 objects, 20 per assigned band, in band order. Each object has exactly these fields:

```json
{"id": 1, "band": "subatomic", "title": "<concrete scene name>", "setting": "<specific place and material>", "food": "<small-to-large edible progression>", "interaction": "<what moves or affects what, and the consequence>", "reveal": "<what growth makes newly edible>", "risk": "<one concrete design weakness or production cost>"}
```

Keep each text field concise. Total prose per candidate must stay near 45–65 words. Use concrete nouns and physical cause and effect. Do not write marketing copy. Name meaningful differences rather than generate reskins. Include grounded, buildable candidates alongside unusual ones. The method is a parallel adaptation of volume generation, drawing on Bernd Rohrbach's brainwriting tradition; it is not a literal 6-3-5 workshop.

## Leaf boundaries

Write only the assigned JSON data file. Do not write application code, scripts, HTML, memory files, skills, or other outputs. Do not install or enable software, invoke models, spawn children, use browser/computer automation, inspect other conversations, edit Git config, stage, commit, push, delete, reset, or change files owned by others. Do not read or expose secrets. Existing dirty files belong to other owners. Use provided project facts; scientific verification can occur after selection. No web or broad filesystem research is needed for fictional scene ideation. Stop and report blockers through the native return channel. Do not create status artifacts or open apps.

## Acceptance and curation

CHECK: Parse all three files, count 80 candidates per leaf and 240 total, require IDs 1–240 exactly once, require 20 entries per band and nonempty schema fields. EXPECT: All checks pass. Report duplicates or weak entries to the leaf for replacement in its own file.

A separate delegated judgment pass will select 60 unique candidate IDs in campaign order and four unique prototype IDs from the selection. It must retain subatomic opening and spacetime finale, vary mechanics within scale bands, explain each selection briefly, and flag poor transitions or expensive assumptions. It must not invent additional scene candidates. The root checks references, counts, ordering, and material contradictions.

Record leaf completion and review events below. Create one review artifact after curation, not a settled implementation plan. No game code is authorized by this work.

2026-09-04: Dispatched scene_micro, scene_everyday, and scene_cosmos through native subagents, each using gpt-5.6-luna at max for JSON scene data only.

2026-09-04: Claude's fresh quota snapshot reported its shared five-hour window fully used. Kimi's reviewed network quota check passed. Route the independent curation to Kimi K3 through the installed ask-kimi resolver in one bounded pass. Give it no tools or filesystem authority. Store the response and check its references before presenting it.

2026-09-04: micro returned 80 rows. Root found the molecular and microscopic blocks reversed and excessive miniature-machine metaphors. Returned one bounded repair to its author. The data checker now verifies band order as well as counts.

## 2026-09-04: Source-grounded replacement contract

The user rejected the unsourced scene direction. All earlier generation allocations, equal-band quotas, and curation instructions above are superseded. The original outputs are parked under docs/design/rejected and cannot enter curation. Restart from actual original Tasty Planet level references. Do not confuse later-game or remake additions with original-level evidence.

New invariants: zero to two optional camera size jumps per level; ordinary growth also occurs without jumps. Include emergent object formations and edible parts leading to edible wholes. Part-to-whole progression does not require a jump. Never count consumed parts twice in the remaining whole; deleting tiny detail during a camera jump grants no growth. These last two rules are proposed implementation accounting, pending design confirmation.

Source collection first: scene_micro owns docs/design/sources/ground-levels.json, using the six downloaded StrategyWiki chapters in /tmp/tasty-planet-sources and /tmp/tasty-laboratory.html. Extract each numbered level as a factual seed, with id, chapter, level, source URL and concise paraphrased objects/layout observations. Include source limits rather than inventing missing facts. Exclude struck-out entities from edible claims. No ideation in this pass. Root owns source retrieval, all other documents, and Git. CHECK: parse JSON, unique level IDs, all six assigned chapters represented; EXPECT: concrete, traceable observations and explicit missing details. All earlier leaf prohibitions remain in force except reading the named downloaded HTML is now required.

2026-09-04: Found a primary source: the official Mac demo at https://www.dingogames.com/tastyplanet/downloadmac.htm includes readable level XML. Mounted read-only at /tmp/tasty-planet-demo, without installing or launching. Its bundle identifies Tasty Planet 1.4.1, a current distribution of the first game, not proof of byte-identical 2006 levels. Use this edition label throughout. scene_cosmos owns docs/design/sources/upper-levels.json: summarize sky/orbit/cosmos level XML into id/chapter/level/source/objects/layout/limits plus filename. CHECK unique numbered seeds and exact source filename; EXPECT object and controller facts grounded in XML, no imagined visible arrangement. No copied assets or XML in deliverables. Root handles retrieval and later unmount.

## Replacement generation interface

The verified source index is docs/design/sources/original-levels.json: 60 numbered levels extracted from the official first-game Mac demo 1.4.1. It contains entity/controller labels and source file hashes, not copied level definitions. Human-readable source notes supplement this index.

Generate four distinct adaptations per source seed, 240 total. This keeps the pool anchored in actual first-game levels. It does not require selecting one adaptation per seed. Preserve concrete original objects, layouts, and growth payoffs where useful. Clearly describe newly proposed mechanics as adaptations, never historical facts. No equal quota per scale band.

New candidate fields: id (1–240), source_id (existing source index id), band (one of subatomic, atomic, molecular, microscopic, miniature, tabletop, human, landscape, planetary, stellar, galactic, spacetime), title, setting, food, interaction, jumps (array of zero to two short descriptions), parts (string or null), risk. All fields except id, jumps, and parts are nonempty strings. Prose is concise, approximately 45–70 words per candidate. Each candidate must preserve an identifiable source ingredient or level arrangement. All new behavior is a proposal.

Ownership: scene_micro writes candidates/micro.json for laboratory and outside, 36 rows IDs1–36. Adapt laboratory seeds to supply subatomic/atomic/molecular openings as well as actual microscopic environments. scene_everyday writes candidates/everyday.json for picnic table/ocean/park/city, 96 rows IDs37–132. scene_cosmos writes candidates/cosmos.json for sky/orbit/cosmos, 108 rows IDs133–240. Four variants of each source_id stay adjacent in source order. A zero-jump level has an empty jumps array. Include simple single-view stages alongside wider reveals; do not force every scene into a formation or a multi-jump template. Parts can be null.

Leaf CHECK: parse own JSON, exact assigned IDs, four rows per assigned source_id, 0–2 jumps, all schema fields valid. EXPECT grounded variety in food/layout/behavior, with no timers, damage, combat, quests, dialogue, or new player abilities. All previous leaf side-effect prohibitions persist; reading named source data and source XML is permitted. No agents generate images or implement the game.

Root checks provenance and sample quality before the independent curator selects60 and recommends4. Source chapter is separate from adapted scale band. Curation must include levels with zero jumps and cannot prescribe mandatory jumps. Retain a subatomic start and spacetime end, without requiring all12 bands equally. Exact size continuity remains open.

## 2026-09-04: Inspiration, not replicas

User clarified that the original game is only a seed. The four-variants-per-original-level rule is withdrawn. Do not enforce source coverage or adjacency. Keep current leaf row/ID allocations only to avoid overlapping writes. Each author can freely repeat or skip source influences, and use source_id=null when no single level is the direct influence. Source index is research background, not a campaign blueprint. Create fresh settings, layouts, situations, and combinations based on the original's design principles. Reject carbon copies and trivial reskins. The curator selects on quality and coherence, not original-level representation.

2026-09-04: Source checks passed: 33 unique lower-world walkthrough notes and27 unique upper-world XML summaries. Root verified source samples for the dice face, cheese/mice progression, Orbit1 emitters, giant amoeba, and final fabric/time entities. Source observations remain distinct from proposed game mechanics.

2026-09-04: Micro replacement verified:36rows with valid IDs/fields/jump bounds. One bounded revision replaced four forced biological-at-particle metaphors and four inherited object-placement designs. Source references can be null, and candidate1 now explicitly supports edible quarks to intact protons to nuclei.

2026-09-04: Cosmos draft verified108unique IDs and schema. Root found raw jump descriptions that meant occlusion reveals rather than actual scale jumps. Independent curation will return final jumps and parts per selected scene: clear incidental reveals, describe actual zoom-out/larger-tier/tiny-detail retirement where useful, and make edible subparts-to-whole payoffs explicit. These are bounded refinements, not new scenes. The final catalogue and artifact apply those selected-scene refinements; raw leaf files remain input drafts.

2026-09-04: All240drafts pass structural aggregation after resolving one duplicate title. Everyday drafts include forced miniature/resin versions of real settings and some backward food-size order. Expand the single Kimi curation pass to finalize each selected scene's existing core idea, including setting, food, interaction, jumps and parts. Do not leave known draft defects in the selected60. Preserve selected candidate IDs for traceability; return full final scene fields in structured output. Avoid further Luna repair loops: design judgment belongs to the independent editor, while the bulk drafts remain idea inputs.

2026-09-04: Automatic approval review rejected sending the240-scene corpus to Kimi: `This sends the project’s private 240-scene design corpus and prompt to the external Kimi API, but the user authorized curation in substance—not disclosure of that payload to that destination.` No model call ran. Use a separate native Astra-high curator inside the existing Codex task instead; do not retry or indirectly invoke Kimi. Curator owns docs/design/curation.native.json only, matching curation.schema.json. It reads the prepared prompt and candidates, writes the structured result, and has no external-service authority. Root retains Git, publishing and artifact ownership.

2026-09-04: Unmounted the reference demo after all source-reading leaves finished. Source notes and metadata remain available in the repository. Native Astra selection is underway; no external model received the catalogue.

2026-09-04: Native curation completed and passed structural checks: 240 candidates, 60 unique selected scenes, and four unique prototype recommendations drawn from the selection. Selected scenes have 41 zero-jump, 18 one-jump, and one two-jump entries. Root checked selected food chains and all four prototype entries. The user accepted the pool for now and said it was too much to read at once. Stop broad catalogue review and focus later decisions on the four prototypes. The results artifact was mechanically checked and opened in Zen. The user explicitly stopped visual testing of status artifacts; no further screenshot or viewport checks are required. No game code has been built.
