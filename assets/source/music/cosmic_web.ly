\version "2.26.0"

% Filament, for the cosmic web: a medium-up swing in D-flat, trumpet and alto
% sax in unison, a trombone bridge, celesta starlight, a piano solo chorus and a
% four-horn shout. The A section leaps from Dbmaj9 to Amaj7#11, a chromatic
% mediant, like a jump between galaxies. Swing is written exactly in 12/8 at
% dotted quarter = 125. The intro plays once; the game loops from mark A, and
% the intro is a verbatim copy of the tag so the wrap blends identical music.

\header { title = "Filament" subtitle = "Cosmic Web" composer = "Opus 5.5" tagline = ##f }

meter = { \time 12/8 \tempo 4. = 125 }
global = { \meter \key des \major }

% Give every note of a chord one duration, so a voicing can be reused rhythmically.
hit = #(define-music-function (dur chord) (ly:duration? ly:music?)
  (let ((copy (ly:music-deep-copy chord)))
    (for-each (lambda (note) (ly:music-set-property! note 'duration dur))
              (extract-named-music copy 'NoteEvent))
    copy))
% Swing comping: a short chord on the last triplet of beat two, a longer one on four.
comp = #(define-music-function (chord) (ly:music?)
  #{ r4. r4 \hit 8 $chord r4. \hit 4 $chord r8 #})
compSplit = #(define-music-function (first second) (ly:music? ly:music?)
  #{ r4. r4 \hit 8 $first r4. \hit 4 $second r8 #})
walk = #(define-music-function (a b c d) (ly:pitch? ly:pitch? ly:pitch? ly:pitch?)
  #{ $a 4. $b 4. $c 4. $d 4. #})

pDb = <f' aes' c'' ees''>
pA = <e' gis' b' dis''>
pEbm = <ges' bes' des'' f''>
pAb = <ges' bes' c'' f''>
pGb = <f' aes' bes' des''>
pCb = <ees' ges' a' des''>
pFm = <ees' f' aes' c''>
pBb = <d' f' aes' b'>
pE = <dis' gis' ais' cis''>

compIntro = { \comp \pDb \comp \pA \comp \pEbm \comp \pAb }
compA = { \comp \pDb \comp \pDb \comp \pA \comp \pA \comp \pEbm \comp \pAb \comp \pDb \compSplit \pEbm \pAb }
compB = { \comp \pGb \comp \pCb \comp \pFm \comp \pBb \comp \pEbm \comp \pE \comp \pEbm \comp \pAb }

bassIntro = { \walk des f aes bes \walk a cis' e' d' \walk ees ges bes a \walk aes c' ees' d' }
bassFront = {
  \walk des ees f aes \walk des' c' aes bes \walk a gis fis e \walk dis e fis d
  \walk ees f ges a \walk aes ges f d \walk des f aes e
}
bassA = { \bassFront \walk ees bes, aes, d }
bassAToB = { \bassFront \walk ees bes, aes, g, }
bassB = {
  \walk ges, bes, des c \walk ces ees ges e \walk f aes c' b \walk bes, d f e
  \walk ees ges bes f \walk e gis b d \walk ees des bes, a, \walk aes, c ees d
}

melFront = {
  r4. aes'4 bes'8 c''4. f''4 ees''8 | c''2.~ c''4. r4. |
  r4. e''4 fis''8 gis''4. dis''4 cis''8 | b'2.~ b'4. r4. |
  r4 ges'8 bes'4 des''8 f''4. ees''4 des''8 | c''4. f''4 ees''8 c''4. r4. |
  r4 aes'8 c''4 ees''8 f''4. aes''4 f''8 |
}
melA = { \melFront ees''4. des''4 c''8 bes'4. r4. | }
melAToB = { \melFront ees''4. c''4 aes'8 des''2. | }
melB = {
  bes'4. des''4 f''8 aes''2. | a'4. des''4 ees''8 ges''2. |
  f''4. ees''4 c''8 aes'2. | aes'4. b'4 d''8 f''2. |
  ges''4. f''4 des''8 bes'2. | gis'4. ais'4 b'8 dis''2. |
  ees''4. ges''4 bes''8 des'''2. | c'''4. bes''4 f''8 ees''2. |
}
% Pads above the trombone's bridge: trumpet on the upper guide tone, alto a third below.
padHigh = { f''1. | ees''1. | ees''1. | d''1. | des''1. | dis''1. | des''1. | c''1. | }
padLow = { des''1. | a'1. | c''1. | aes'1. | bes'1. | b'1. | bes'1. | ges'1. | }
tromGuide = { f1. | f1. | gis1. | gis1. | ges1. | ges1. | f1. | ges2. ges2. | }
shout = {
  r4 bes'8 des''4 f''8 aes''4.-> f''4 des''8 | ees''4.-> des''4 a'8 ges'4. r4. |
  r4 c''8 ees''4 f''8 aes''4.-> g''4 f''8 | f''4.-> d''4 b'8 aes'4. r4. |
  r4 ges'8 bes'4 des''8 f''4.-> ees''4 des''8 | dis''4.-> b'4 gis'8 ais'4. r4. |
  ges''4-> f''8 ees''4 des''8 bes'4-> ges'8 f'4 ees'8 | c''4.-> ees''4.-> f''4.-> r4. |
}
pianoSolo = {
  aes'4 bes'8 c''4 ees''8 f''4 aes''8 g''4 f''8 | ees''4 c''8 aes'4 f'8 aes'4. r4. |
  r4 e''8 gis''4 b''8 dis'''4 cis'''8 b''4 gis''8 | fis''4 e''8 dis''4 b'8 cis''4. r4. |
  r4 bes'8 des''4 f''8 ges''4 f''8 ees''4 des''8 | c''4 ees''8 f''4 aes''8 ges''4. r4. |
  f''4 ees''8 c''4 aes'8 bes'4 c''8 ees''4 f''8 | ges''4 f''8 ees''4 des''8 c''4 bes'8 aes'4 r8 |
  r4. f''4 aes''8 c'''4. bes''4 aes''8 | g''4 f''8 ees''4 c''8 des''4. r4. |
  b'4 cis''8 dis''4 e''8 fis''4 gis''8 b''4 dis'''8 | cis'''4 b''8 gis''4 fis''8 e''4. r4. |
  ges''4 bes''8 des'''4 bes''8 f''4 ges''8 f''4 ees''8 | c''4 f''8 aes''4 f''8 ges''4 ees''8 c''4 r8 |
  aes'4 c''8 f''4 aes''8 c'''4. aes''4 f''8 | ees''4 des''8 bes'4 ges'8 c''4 ees''8 aes''4 r8 |
}
% Soft horn pads behind the piano solo: thirds and sevenths of each A chord.
soloPadHigh = { c''1. | c''1. | gis'1. | gis'1. | des''1. | c''1. | c''1. | des''2. c''2. | }
soloPadLow = { f'1. | f'1. | cis'1. | cis'1. | ges'1. | ges'1. | f'1. | ges'2. ges'2. | }
% Starlight: celesta twinkles in the held bars of each A.
twinkleA = {
  R1. | r2. r4 c'''8 f'''4 aes'''8 | R1. | r2. r4 dis'''8 gis'''4 b'''8 |
  R1. | R1. | R1. | R1. |
}
twinkleIntro = { r2. r4 c'''8 f'''4 aes'''8 | r2. r4 dis'''8 gis'''4 b'''8 | R1. | R1. | }

% Drum cells, one measure each.
swing = \drummode { << { cymr4. cymr4 cymr8 cymr4. cymr4 cymr8 } \\ { bd4. hhp4. bd4. hhp4. } >> }
crash = \drummode { << { cymc4. cymr4 cymr8 cymr4. cymr4 cymr8 } \\ { bd4. hhp4. bd4. hhp4. } >> }
fill = \drummode { << { cymr4. cymr4 cymr8 r2. } \\ { bd4. hhp4. sn8 sn sn tomh8 tommh tomfl } >> }
% The heads ride a closed hi-hat with cross-stick; the ride cymbal is saved for bridge, solo and shout.
hatSwing = \drummode { << { hh4. hh4 hh8 hh4. hh4 hh8 } \\ { bd4. ss4. bd4. ss4. } >> }
eight = \drummode { \crash \repeat unfold 6 \swing \fill }
eightHat = \drummode { \crash \repeat unfold 6 \hatSwing \fill }

trumpet = {
  \global <>\mf
  R1.*4
  \mark \default \melA
  \mark \default \melAToB
  \mark \default <>\p \padHigh
  \mark \default <>\mf \melA
  \mark \default <>\pp \soloPadHigh \soloPadHigh
  \mark \default <>\f \shout
  \mark \default <>\mf \melA
  \mark \default R1.*4
}
alto = {
  \global <>\mf
  R1.*4 \melA \melAToB <>\p \padLow <>\mf \melA <>\pp \soloPadLow \soloPadLow
  <>\f \shout <>\mf \melA R1.*4
}
tenor = {
  \global <>\f
  R1.*4 R1.*32 R1.*16
  \transpose c c, \shout <>\mf \transpose c c, \melA R1.*4
}
trombone = {
  \global \clef bass <>\p
  R1.*4 R1.*8 \tromGuide <>\mf \transpose c c, \melB <>\p \tromGuide R1.*16
  <>\mf \transpose c c, \padLow <>\p \tromGuide R1.*4
}
celesta = {
  \global <>\p
  \twinkleIntro \twinkleA \twinkleA R1.*8 \twinkleA R1.*16 R1.*8 \twinkleA \twinkleIntro
}
pianoUpper = {
  \global <>\p
  \compIntro \compA \compA \compB \compA
  <>\f \pianoSolo
  <>\p \compB \compA \compIntro
}
pianoLower = {
  \global \clef bass <>\p
  R1.*4 R1.*32
  \transpose c c, { \compA \compA }
  R1.*8 R1.*8 R1.*4
}
bass = {
  \global \clef bass <>\mf
  \transpose c c, {
    \bassIntro \bassA \bassAToB \bassB \bassA \bassA \bassA \bassB \bassA \bassIntro
  }
}
kit = \drummode {
  \meter <>\p
  \swing \swing \swing \fill
  \eightHat \eightHat \eight \eightHat
  \eight \eight
  <>\mp \eight <>\p \eightHat
  \swing \swing \swing \fill
}

\score {
  <<
    \new Staff \with { instrumentName = "Trumpet" midiInstrument = "trumpet" }
      { \trumpet }
    \new Staff \with { instrumentName = "Alto sax" midiInstrument = "alto sax" }
      { \alto }
    \new Staff \with { instrumentName = "Tenor sax" midiInstrument = "tenor sax" }
      { \tenor }
    \new Staff \with { instrumentName = "Trombone" midiInstrument = "trombone" }
      { \trombone }
    \new Staff \with { instrumentName = "Celesta" midiInstrument = "celesta" }
      { \celesta }
    \new PianoStaff \with { instrumentName = "Piano" } <<
      \new Staff \with { midiInstrument = "acoustic grand" } { \pianoUpper }
      \new Staff \with { midiInstrument = "acoustic grand" } { \pianoLower }
    >>
    \new Staff \with { instrumentName = "Upright bass" midiInstrument = "acoustic bass" }
      { \bass }
    \new DrumStaff \with { instrumentName = "Kit" }
      { \kit }
  >>
  \layout { }
  \midi { }
}
