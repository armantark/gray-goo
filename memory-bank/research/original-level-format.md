# Original Tasty Planet level data

Read-only survey of the 64 XML files in `/Applications/Tasty Planet.app/Contents/Resources/assets/levels/`, done by GPT-6 Luna on 2026-09-22. Inspiration only; the level contract forbids copying the original's assets or level data.

## Structure

Every object is an `<emitter>`. A fixed placement is a `spot` emitter with a `stationary` controller and one scheduled emission at time 0:

```xml
<emitter type="spot" entitydef="dirt" minarea="500.0" maxarea="500.0" posx="100.0" posy="325.0">
  <controller type="stationary" />
  <scheduledemit><emit time="0.0" /></scheduledemit>
</emitter>
```

Emitter types across all files: 1,639 `spot`, 214 `side`, 13 `shot`. `side` emitters spawn from level edges within `left`/`right`/`top`/`bottom` ranges. Controllers: `stationary`, `movedirection`, `pathfollow`, `avoid`, `evade`, `attack`, `leavelevel`. Targets filter with `affect`/`dontaffect` and conditions `larger`, `largerequal`, `smaller`, `smallerequal`, `none`. Example: an amoeba attacks smaller entities, evades the goo when the goo is `largerequal`, and leaves the level after `leavetime="20.0"`.

Damage attributes exist on emitters (`absdamage`, `fracdamage`, e.g. a city1 car has `fracdamage="0.05"` and `fracdamageta="0.075"`); the data does not show the runtime effect.

## Counts

| Level | Size | Start area | Victory size | Fixed placements | Emitters |
|---|---:|---:|---:|---:|---:|
| amoeba | 1400×1200 | 301 | 20,400 | 0 | 8 |
| bugs1 | 1600×1400 | 504 | 37,001 | 58 | 60 |
| bugs5 | 1600×1400 | 501 | 44,300 | 81 | 82 |
| city1 | 1600×1400 | 501 | 64,801 | 18 | 25 |
| city8 | 2000×2000 | 501 | 74,701 | 46 | 62 |
| fish1 | 1600×1400 | 500 | 10,000 | 0 | 6 |
| grass1 | 1600×1400 | 501 | 12,100 | 34 | 36 |
| sky1 | 1600×1400 | 500 | 22,501 | 0 | 5 |
| end | 3000×3000 | 15,001 | 312,490 | 270 | 270 |

Victory size is 20× to 130× the start area. Fixed placements per level run from 0 to 81 in ordinary levels; some levels (fish1, sky1, amoeba) have none and run entirely on spawns.

## Placement notes

- bugs1: 35 small dirt pieces (area 200–500, below start size) average 639.1 units from the start; 21 large dirt pieces (1,400–2,600) average 680.6; two bonsai leaves (30,000) average 431.4. Size does not grow with distance. Positions mix round and irregular numbers, with dense perimeter clusters.
- city1: 4 stop signs (250) cluster southwest of the start; 13 trees (25,000) sit in rows; one large tree (50,000). The early food comes mostly from emitters, not placements.
- city1 repeats the tree position `(-410,-550)` twice.
