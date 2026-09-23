# 06: Eat moment, edible signal, and arrow

**What to build:** Each meal pulls into the goo with a sound, a goo pulse, and a burst, and all three scale with the meal's reward relative to the goo's volume. An object that changes from blocked to edible plays one short signal, such as a bounce and a flash. The arrow to the nearest edible object grows with that object's reward, between a minimum and a maximum size.

**Blocked by:** 02 Tasty Planet eat rule.

**Orchestrator addition:** the HUD still shows all-caps eyebrow labels such as "SPECIMEN SLIDE" and "NEAREST FOOD". The owner wants decorative all-caps eyebrow labels and subtitle taglines stripped. Remove them in `src/hud.gd` where they are decorative, and keep the information that the player needs.

**Status:** done

- [x] Native frame series show a small meal and a large meal with a clearly different response.
- [x] A native frame series shows objects signal at the moment the goo grows past their size.
- [x] Native screenshots show a small arrow for a small target and a large arrow for a large target.
- [x] Each level's 20-second native route still averages at least 58 frames per second at 1920 × 1080.
