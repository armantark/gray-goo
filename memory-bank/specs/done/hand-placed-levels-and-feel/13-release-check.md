# 13: Release check

**What to build:** The macOS app and the browser build contain all the work. Each level passes a performance check and a short play in the browser.

**Blocked by:** 06 Eat moment, edible signal, and arrow; 07 Size jump and camera; 09 Hand-placed Sugar Water; 10 Hand-placed Skatepark Bowl; 11 Hand-placed Cosmic Web; 12 3D model test; 14 New soundtrack.

**Status:** done

- [x] The macOS export and the browser export complete without engine errors.
- [x] Each level's 20-second native route averages at least 58 frames per second at 1920 × 1080.
- [x] A Pinchtab session plays each level in the browser build, and its screenshots show no truncation.
- [ ] The results artifact is written, and the spec directory moves to `specs/done/`.
