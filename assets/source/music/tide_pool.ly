\version "2.26.0"

% Low Tide Glimmer, for the tide pool: an upbeat bossa nova in F major, flute over
% a nylon-guitar batida, with a Rhodes chorus and a bridge that drifts to A-flat.
% Bossa's 2/2 is written two bars to a 4/4 measure, sixteenths at quarter = 80.
% The intro plays once; the game loops from mark A.

\header { title = "Low Tide Glimmer" subtitle = "Tide Pool" composer = "Opus 5.5" tagline = ##f }

meter = { \time 4/4 \tempo 4 = 80 }
global = { \meter \key f \major }

% Give every note of a chord one duration, so a voicing can be reused rhythmically.
hit = #(define-music-function (dur chord) (ly:duration? ly:music?)
  (let ((copy (ly:music-deep-copy chord)))
    (for-each (lambda (note) (ly:music-set-property! note 'duration dur))
              (extract-named-music copy 'NoteEvent))
    copy))
% The guitar batida, one chord per bossa bar.
batida = #(define-music-function (first second) (ly:music? ly:music?)
  #{ \hit 8 $first \hit 16 $first \hit 8 $first \hit 8 $first \hit 16 $first
     r16 \hit 16 $second \hit 8 $second \hit 8 $second \hit 8 $second #})
pad = #(define-music-function (first second) (ly:music? ly:music?)
  #{ \hit 2 $first \hit 2 $second #})
% Bossa bass: root on the beat, the fifth anticipated and held.
bossa = #(define-music-function (root fifth) (ly:pitch? ly:pitch?)
  #{ $root 8. $fifth 16~ $fifth 4 #})

gF = <a c' e' g'>
gBbt = <aes d' e' g'>
gAm = <g c' e' a'>
gDbn = <fis c' ees' a'>
gGm = <f bes d' a'>
gCt = <e bes d' a'>
gCsus = <f bes d' g'>
gBbmaj = <a d' f' c''>
gBbmsix = <g des' f' bes'>
gAbo = <f aes b d'>
gEbmaj = <g bes d' f'>
gEbt = <des g c' f'>
gAbmaj = <c' ees' g' bes'>
gDbmaj = <c' ees' f' aes'>
gBbm = <des' f' aes' c''>
gAmhd = <g c' ees' a'>

% Harmony is written once as a chord-pair function and fed to guitar and Rhodes.
formIntro = #(define-music-function (f) (procedure?)
  #{ $(f gF gF) $(f gGm gCt) $(f gF gF) $(f gGm gCt) #})
formA = #(define-music-function (f last) (procedure? ly:music?)
  #{ $(f gF gF) $(f gBbt gBbt) $(f gAm gDbn) $(f gGm gCt)
     $(f gBbmaj gBbmsix) $(f gAm gAbo) $(f gGm gCt) $(f gF last) #})
formB = #(define-music-function (f) (procedure?)
  #{ $(f gAbmaj gAbmaj) $(f gDbmaj gDbmaj) $(f gBbm gEbt) $(f gAmhd gDbn)
     $(f gGm gGm) $(f gEbmaj gEbmaj) $(f gAm gDbn) $(f gGm gCsus) #})
formOutro = #(define-music-function (f) (procedure?)
  #{ $(f gF gEbt) $(f gDbmaj gCsus) $(f gF gEbt) $(f gDbmaj gCt) #})
guitarPair = #(lambda (a b) (batida a b))
padPair = #(lambda (a b) (pad a b))

bassIntro = { \bossa f, c, \bossa f, c, \bossa g, d, \bossa c g,, \bossa f, c, \bossa f, c, \bossa g, d, \bossa c g,, }
bassAFront = {
  \bossa f, c, \bossa f, c, \bossa bes,, f, \bossa bes,, f, \bossa a,, e, \bossa d a,,
  \bossa g, d, \bossa c g,, \bossa bes,, f, \bossa bes,, f, \bossa a,, e, \bossa aes,, aes,,
  \bossa g, d, \bossa c g,,
}
bassA = { \bassAFront \bossa f, c, \bossa c g,, }
bassATurn = { \bassAFront \bossa f, c, \bossa ees, bes,, }
bassB = {
  \bossa aes,, ees, \bossa aes,, ees, \bossa des aes,, \bossa des aes,, \bossa bes,, f, \bossa ees, bes,,
  \bossa a,, ees, \bossa d a,, \bossa g, d, \bossa g, d, \bossa ees, bes,, \bossa ees, bes,,
  \bossa a,, e, \bossa d a,, \bossa g, d, \bossa c g,,
}
bassOutro = { \bossa f, c, \bossa ees, bes,, \bossa des aes,, \bossa c g,, \bossa f, c, \bossa ees, bes,, \bossa des aes,, \bossa c g,, }

melAFront = {
  c''4 a'8 c''8~ c''8 e''8 f''8 g''8~ |
  g''2~ g''8 f''8 e''8 f''8 |
  e''4 c''8 e''8~ e''8 ees''8 c''8 a'8 |
  bes'4. a'8~ a'8 g'8 f'8 e'8 |
  d''4 f''8 a''8~ a''8 g''8 f''8 des''8 |
  c''4. e''8~ e''8 d''8 b'8 d''8 |
}
melA = {
  \melAFront
  f''4 d''8 bes'8~ bes'8 a'8 g'8 e'8 |
  f'4. r8 r8 f'8 g'8 a'8 |
}
melATurn = {
  \melAFront
  f''4 d''8 bes'8~ bes'8 a'8 g'8 bes'8 |
  a'4. c''8~ c''8 bes'8 g'8 ees''8 |
}
melB = {
  ees''4 c''8 ees''8~ ees''8 f''8 g''8 bes''8~ |
  bes''2~ bes''8 aes''8 g''8 f''8 |
  des''4 c''8 f''8~ f''8 ees''8 c''8 bes'8 |
  c''4. ees''8~ ees''8 d''8 c''8 fis'8 |
  g'4 bes'8 d''8~ d''8 f''8 a''8 bes''8~ |
  bes''2~ bes''8 g''8 f''8 d''8 |
  e''4 c''8 a'8~ a'8 ees''8 d''8 c''8 |
  bes'4. a'8~ a'8 g'8 f'8 r8 |
}
% Held tones under the Rhodes chorus.
fluteChorus = {
  a''1 | g''1 | e''2 fis''2 | f''2 e''2 |
  d''2 des''2 | c''2 b'2 | bes'1 | a'2 r2 |
}
melOutro = { a''2 g''2 | f''2 g''2 | a'4. c''8~ c''2 | f''2 e''4 r4 | }

rhodesChorus = {
  r8 a'16 c'' e''8 f''16 g''~ g''8 a''16 g'' f''8 e''16 c'' |
  d''8 e''16 g''~ g''8 f''16 d''~ d''4 r8 aes'16 c'' |
  e''8 g''16 e''~ e''8 c''16 a'~ a'8 fis'16 a' c''16 ees'' d''8 |
  bes'8 d''16 f''~ f''8 a''16 g''~ g''8 e''16 d'' bes'16 a' g'8 |
  f''8 d''16 a'~ a'8 c''16 d''~ d''8 des''16 f'' g''16 f'' des''8 |
  c''4 e''16 g'' a'' c'''~ c'''8 b''16 aes'' f''16 d'' b'8 |
  a''8 g''16 f''~ f''8 d''16 bes'~ bes'8 a'16 g' e'16 g' bes'8 |
  a'4 r4 r8 f'16 g' a'16 c'' r8 |
}

% Percussion cells, one measure (two bossa bars) each.
clave = \drummode { ss16 r r ss r r ss r r r ss r r ss r r }
kick = \drummode { bd8. bd16 bd8. bd16 bd8. bd16 bd8. bd16 }
rideBossa = \drummode { \repeat unfold 4 { cymr8 cymr16 cymr } }
kitClave = \drummode { << \clave \\ \kick >> }
kitRide = \drummode { << \rideBossa \\ \kick >> }
kitSplash = \drummode { << { cyms4 r8 ss16 r r r ss r r ss r r } \\ \kick >> }
cabasa = \drummode { \repeat unfold 8 { cab16 cab-> } }

flute = {
  \global <>\mf
  R1*4
  \mark \default \melA
  \mark \default \melATurn
  \mark \default \melB
  \mark \default <>\mp \fluteChorus
  \mark \default <>\mf \melA
  \mark \default \melOutro
}
guitar = {
  \global <>\mp
  \formIntro #guitarPair
  \formA #guitarPair #gCsus
  \formA #guitarPair #gEbt
  \formB #guitarPair
  \formA #guitarPair #gCsus
  \formA #guitarPair #gCsus
  \formOutro #guitarPair
}
rhodes = {
  \global <>\p
  R1*4 R1*8
  \formA #padPair #gEbt
  \formB #padPair
  <>\mf \rhodesChorus
  <>\p R1*8
  \pad \gF \gEbt \pad \gDbmaj \gCsus \pad \gF \gEbt \hit 2 \gDbmaj r2
}
bass = {
  \global \clef bass <>\mf
  \bassIntro \bassA \bassATurn \bassB \bassA \bassA \bassOutro
}
kit = \drummode {
  \meter <>\p
  \repeat unfold 4 \kitClave
  \kitSplash \repeat unfold 7 \kitClave
  \kitSplash \repeat unfold 7 \kitClave
  \kitSplash \repeat unfold 7 \kitRide
  <>\pp \repeat unfold 8 \kitClave
  <>\p \kitSplash \repeat unfold 7 \kitClave
  \repeat unfold 3 \kitRide \kitClave
}
shaker = \drummode {
  \meter <>\ppp
  \repeat unfold 28 \cabasa
  R1*8
  \repeat unfold 12 \cabasa
}

\score {
    <<
      \new Staff \with { instrumentName = "Flute" midiInstrument = "flute" }
        { \flute }
      \new Staff \with { instrumentName = "Nylon guitar" midiInstrument = "acoustic guitar (nylon)" }
        { \guitar }
      \new Staff \with { instrumentName = "Rhodes" midiInstrument = "electric piano 1" }
        { \rhodes }
      \new Staff \with { instrumentName = "Bass" midiInstrument = "acoustic bass" }
        { \bass }
      \new DrumStaff \with { instrumentName = "Kit" }
        { \kit }
      \new DrumStaff \with { instrumentName = "Cabasa" }
        { \shaker }
    >>
  \layout { }
  \midi { }
}
