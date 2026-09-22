# 14: New soundtrack

**What to build:** The owner does not like the current four scene tracks. Opus 5.5 writes four new original pieces, one per level, and each piece loops without a seam. The owner wants every piece to sound really upbeat and groovy and to stay within samba, bossa nova, or jazz, with Opus's own spin inside those styles. The scores are written in LilyPond and rendered to audio through MuseScore 4 with its best installed sounds. The current approach, which synthesizes every instrument in numpy, is retired. Each piece must fit its place: a drop of sugar water, a tide pool, a skatepark bowl, and the cosmic web. The pieces do not need to be sax-led.

**Blocked by:** None (can start immediately).

**Status:** blocked: MuseScore cannot initialize Muse Sounds (`Could not init MuseSampler`, 0.105.8), so no final Ogg can be rendered; scores, build and previews are done (see progress.md)

- [ ] Each piece has a LilyPond source in the repository, an engraved score image that Opus looked at, and a rendered Ogg that the game plays.
- [ ] The loop point of each Ogg has no audible click or gap: the last and first 50 milliseconds match in level, and a spectrogram image across the loop shows no break.
- [ ] A listener from a different model family (Gemini through the `watch` route, which hears audio) comments on each piece, and Opus records the comments and what it changed.
- [ ] Each Ogg is under the browser build's 25 MiB per-file limit, and the loudness of the four pieces is within 2 LU of each other.
- [ ] The old numpy synthesis script and its score file are deleted, and `memory-bank/techContext.md` describes the new build command.
