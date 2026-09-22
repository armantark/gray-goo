\version "2.26.0"

% Coping Stones, for the skatepark bowl: a soul-jazz boogaloo blues in F at
% quarter = 120. Trumpet, tenor sax and trombone carry the head over Hammond,
% jazz guitar and a pushing upright bass riff; the organ sings the stop-time
% bridge and solos, and the shout chorus trades horn riffs with the guitar.
% The intro plays once; the game loops from mark A, and the tag's last bar
% matches the intro's so the wrap joins like to like.

\header { title = "Coping Stones" subtitle = "Skatepark Bowl" composer = "Opus 5.5" tagline = ##f }

meter = { \time 4/4 \tempo 4 = 120 }
global = { \meter \key f \major }

% Give every note of a chord one duration, so a voicing can be reused rhythmically.
hit = #(define-music-function (dur chord) (ly:duration? ly:music?)
  (let ((copy (ly:music-deep-copy chord)))
    (for-each (lambda (note) (ly:music-set-property! note 'duration dur))
              (extract-named-music copy 'NoteEvent))
    copy))

% Boogaloo bass riffs, built on F or G and moved to each chord's root.
dom = #(define-music-function (root) (ly:pitch?)
  #{ \transpose f, $root { f,8 r16 f,16 aes,8 a,8 c8 r8 ees8 c8 } #})
minor = #(define-music-function (root) (ly:pitch?)
  #{ \transpose g, $root { g,8 r16 g,16 bes,8 d8 f8 r8 d8 bes,8 } #})
halfDom = #(define-music-function (root) (ly:pitch?)
  #{ \transpose f, $root { f,8 r16 f,16 a,8 c8 } #})
halfMinor = #(define-music-function (root) (ly:pitch?)
  #{ \transpose g, $root { g,8 r16 g,16 bes,8 d8 } #})
% Stop-time hits on the downbeat and the and of two.
stop = #(define-music-function (root) (ly:pitch?)
  #{ $root 8 r8 r8 $root 8 r2 #})

bassBlues = {
  \dom f, \dom bes,, \dom f, \dom f, \dom bes,, \dom bes,, \dom f, \dom d,
  \minor g, \dom c, \halfDom f, \halfDom des, \halfMinor g, \halfDom c,
}
% Walking quarters under the organ solo, for contrast with the riff.
walkDom = #(define-music-function (root) (ly:pitch?)
  #{ \transpose f, $root { f,4 a, c ees } #})
walkMinor = #(define-music-function (root) (ly:pitch?)
  #{ \transpose g, $root { g,4 bes, d f } #})
halfWalkDom = #(define-music-function (root) (ly:pitch?)
  #{ \transpose f, $root { f,4 a, } #})
halfWalkMinor = #(define-music-function (root) (ly:pitch?)
  #{ \transpose g, $root { g,4 bes, } #})
bassWalkBlues = {
  \walkDom f, \walkDom bes,, \walkDom f, \walkDom f, \walkDom bes,, \walkDom bes,, \walkDom f, \walkDom d,
  \walkMinor g, \walkDom c, \halfWalkDom f, \halfWalkDom des, \halfWalkMinor g, \halfWalkDom c,
}
bassIntro = { \dom f, \dom f, \dom f, \halfMinor g, \halfDom c, }
bassBridge = { \stop des, \stop c, \stop des, \stop c, \stop bes,, \stop ees, \stop a,, \stop g,, }

% Guitar chank on two and four, with a sixteenth push into the backbeat.
chank = #(define-music-function (chord) (ly:music?)
  #{ r4 \hit 8 $chord r16 \hit 16 $chord r4 \hit 8 $chord r8 #})
chankSplit = #(define-music-function (first second) (ly:music? ly:music?)
  #{ r4 \hit 8 $first r8 r4 \hit 8 $second r8 #})
stab = #(define-music-function (chord) (ly:music?)
  #{ \hit 8 $chord r8 r8 \hit 8 $chord r2 #})

gF = <ees' g' a'>
gBb = <d' aes' c''>
gDsharp = <fis' c'' f''>
gGm = <f' bes' d''>
gC = <e' bes' d''>
gDb = <f' ces'' ees''>
gDbmaj = <f' aes' c''>
gCsharp = <e' bes' dis''>
gBbm = <des' f' aes'>
gEb = <des' f' g'>
gAm = <g' c'' e''>
gD = <fis' c'' e''>

guitarBlues = {
  \chank \gF \chank \gBb \chank \gF \chank \gF \chank \gBb \chank \gBb \chank \gF \chank \gDsharp
  \chank \gGm \chank \gC \chankSplit \gF \gDb \chankSplit \gGm \gC
}
guitarBridge = {
  \stab \gDbmaj \stab \gCsharp \stab \gDbmaj \stab \gCsharp \stab \gBbm \stab \gEb \stab \gAm \stab \gGm
}
guitarIntroTag = { \chank \gF \chank \gF \chank \gF \chankSplit \gGm \gC }

oF = <ees' g' a' c''>
oGm = <f' bes' d''>
oC = <e' bes' d''>
oBb = <d' f' aes' c''>
oD = <fis' c'' f''>
oDb = <f' ces'' ees''>
organPad = { \hit 1 \oF | \hit 1 \oF | \hit 1 \oF | \hit 2 \oGm \hit 2 \oC | }
organBlues = {
  \hit 1 \oF | \hit 1 \oBb | \hit 1 \oF | \hit 1 \oF | \hit 1 \oBb | \hit 1 \oBb |
  \hit 1 \oF | \hit 1 \oD | \hit 1 \oGm | \hit 1 \oC | \hit 2 \oF \hit 2 \oDb | \hit 2 \oGm \hit 2 \oC |
}

riffOne = { f''8 r16 f''16 aes''8 a''8~ a''4 c'''8 a''8 | }
headFront = {
  \riffOne
  ees''8 f''8 r8 c''8~ c''2 |
  \riffOne
  ees''8 f''8 r8 aes''8~ aes''8 g''8 f''8 d''8 |
  f''8 r16 f''16 aes''8 f''8~ f''4 d''8 f''8 |
  aes''8 bes''8 r8 f''8~ f''2 |
  \riffOne
  f''8 fis''8 r8 c''8~ c''2 |
}
headEnd = {
  r8 d''16 f'' bes''8 a''8~ a''4 g''8 f''8 |
  e''8 g''8 r8 bes''8~ bes''4 a''8 g''8 |
  f''8 r16 f''16 aes''8 a''8 r8 aes''8~ aes''8 f''8 |
}
head = { \headFront \headEnd g''8 f''8 d''8 c''8 bes'8 g'8 r4 | }
headToBridge = { \headFront \headEnd g''8 f''8 d''8 c''8 r2 | }

bridge = {
  f''2. ees''8 des''8 | ees''2 e''4 g''4 | aes''2. g''8 f''8 | e''2 ees''4 c''4 |
  des''4. f''8~ f''4 aes''4 | g''4. f''8~ f''4 des''4 |
  c''8 e''8 g''8 a''8 fis''8 a''8 c'''8 d'''8 | bes''8 a''8 g''8 f''8 e''4 r4 |
}
organSolo = {
  c''8 ees''16 f'' aes''8 a''8 c'''4 a''8 f''8 |
  aes''8 f''8 d''8 f''8 aes''4. r8 |
  r8 f''16 g'' aes''16 a'' c'''8 ees'''8 c'''8 a''8 f''8 |
  ees''8 c''8 a'8 c''8 ees''4 f''4 |
  d''8 f''8 aes''8 bes''8 d'''4 bes''8 aes''8 |
  f''8. d''16 f''8 aes''8~ aes''2 |
  a''8 c'''8 a''8 f''8 ees''8 c''8 a'8 f'8 |
  fis'8 a'8 c''8 f''8~ f''4 d''4 |
  bes'8 d''8 f''8 a''8 bes''4 a''8 g''8 |
  e''8 g''8 bes''8 d'''8 c'''4 bes''8 g''8 |
  a''8 f''8 c''8 ees''8 f''8 aes''8 b''8 aes''8 |
  g''8 f''8 d''8 bes'8 c''4 r4 |
}
% Horn backgrounds behind the organ solo: a blue-note push and a hit, every four bars.
soloBacks = {
  r2 r8 aes'8-> a'8-> r8 | c''4-> r4 r2 | R1*2 |
  r2 r8 des''8-> d''8-> r8 | f''4-> r4 r2 | R1*2 |
  r2 r8 bes'8-> b'8-> r8 | c''4-> r4 r2 | R1*2 |
}
% Shout chorus: the horns call with the head riffs, the guitar answers.
shoutCalls = {
  \riffOne ees''8 f''8 r8 c''8~ c''2 | R1*2
  f''8 r16 f''16 aes''8 f''8~ f''4 d''8 f''8 | aes''8 bes''8 r8 f''8~ f''2 | R1*2
  \headEnd g''8 f''8 d''8 c''8 bes'8 g'8 r4 |
}
guitarShout = {
  R1*2 c'8 ees'16 e' g'8 a'8 c''8 a'8 g'8 ees'8 | f'4 r4 r2 |
  R1*2 a'8 c''8 ees''8 f''8 ees''8 c''8 a'8 f'8 | fis'8 a'8 c''8 f''8~ f''4 r4 |
  \transpose c c, { \headEnd g''8 f''8 d''8 c''8 bes'8 g'8 r4 | }
}
hornTag = { f'1~ | f'2 r2 | R1*2 }

% Drum cells, one measure each.
groove = \drummode {
  << { hh8 hh hh hh hh hh hh hho } \\ { bd8. bd16 sn8 bd8 bd8. ss16 sn8. bd16 } >>
}
crash = \drummode {
  << { cymc8 hh hh hh hh hh hh hho } \\ { bd8. bd16 sn8 bd8 bd8. ss16 sn8. bd16 } >>
}
fill = \drummode {
  << { hh4 r2. } \\ { bd8. bd16 sn16 sn sn sn tommh8 tommh tomfl8 tomfl } >>
}
stopTime = \drummode {
  << { cymr8 cymr cymr cymr cymr cymr cymr cymr } \\ { bd8 r8 r8 sn8 r2 } >>
}
bluesKit = \drummode { \crash \repeat unfold 10 \groove \fill }
hands = \drummode { << { \repeat unfold 8 tamb8 } \\ { r4 hc4 r4 hc4 } >> }

organ = {
  \global <>\p
  R1*2 \hit 1 \oF | \hit 2 \oGm \hit 2 \oC |
  \mark \default \organBlues
  \mark \default \organBlues
  \mark \default <>\mf \bridge
  \mark \default <>\f \organSolo
  \mark \default <>\p \organBlues
  \mark \default \organBlues
  \mark \default \organPad
}
% Trumpet and tenor sax in unison, with the trombone an octave below. Every head has the
% same texture, so the wrap from the last head through the tag into the first adds no cliff.
horns = { \transpose c c, { \head \headToBridge } R1*8 \soloBacks \transpose c c, { \shoutCalls \head } \hornTag }
trumpet = { \global <>\mp R1*4 \horns }
tenor = { \global <>\mp R1*4 \horns }
trombone = {
  \global \clef bass <>\mp
  R1*4 \transpose c c,, { \head \headToBridge } R1*8 \transpose c c, \soloBacks
  \transpose c c,, { \shoutCalls \head } \transpose c c, \hornTag
}
guitar = {
  \global <>\mp
  R1*2 \chank \gF \chankSplit \gGm \gC
  \guitarBlues
  \guitarBlues
  \guitarBridge
  \guitarBlues
  <>\mf \guitarShout
  <>\mp \guitarBlues
  \guitarIntroTag
}
bass = {
  \global \clef bass <>\f
  \bassIntro \bassBlues \bassBlues \bassBridge \bassWalkBlues \bassBlues \bassBlues \bassIntro
}
kit = \drummode {
  \meter <>\mf
  \groove \groove \groove \fill
  \bluesKit \bluesKit
  \repeat unfold 7 \stopTime \fill
  \bluesKit \bluesKit \bluesKit
  \groove \groove \groove \fill
}
clapping = \drummode {
  \meter <>\pp
  R1*4 \repeat unfold 24 \hands R1*8 R1*12 \repeat unfold 24 \hands R1*4
}
% Boogaloo conga tumbao: slap on two, open tones pushing into the next bar.
tumbao = \drummode { r8 cgh cghm4 r8 cgh cgl cgl }
congas = \drummode {
  \meter <>\mp
  R1*4 \repeat unfold 24 \tumbao R1*8 \repeat unfold 36 \tumbao R1*4
}

\score {
  <<
    \new Staff \with { instrumentName = "Trumpet" midiInstrument = "trumpet" }
      { \trumpet }
    \new Staff \with { instrumentName = "Tenor sax" midiInstrument = "tenor sax" }
      { \tenor }
    \new Staff \with { instrumentName = "Trombone" midiInstrument = "trombone" }
      { \trombone }
    \new Staff \with { instrumentName = "Organ" midiInstrument = "drawbar organ" }
      { \organ }
    \new Staff \with { instrumentName = "Jazz guitar" midiInstrument = "electric guitar (jazz)" }
      { \guitar }
    \new Staff \with { instrumentName = "Upright bass" midiInstrument = "acoustic bass" }
      { \bass }
    \new DrumStaff \with { instrumentName = "Kit" }
      { \kit }
    \new DrumStaff \with { instrumentName = "Congas" }
      { \congas }
    \new DrumStaff \with { instrumentName = "Hands" }
      { \clapping }
  >>
  \layout { }
  \midi { }
}
