# 03: Smooth collision with large objects

**What to build:** The goo slides along objects that it cannot eat. It does not stick, shake, or push through them. Diagnose the cause first; the food physics bodies that also collide with the ground and each other are the first place to look. The goo's shape and motion model stay.

**Blocked by:** 02 Tasty Planet eat rule.

**Status:** done

- [x] A command reproduces the poor collision before the fix and passes after it.
- [x] The route driver reports no stall longer than two seconds in any level.
- [x] A native clip or frame series of the goo along a large object shows no jitter.
