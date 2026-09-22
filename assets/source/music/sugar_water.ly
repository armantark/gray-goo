\version "2.26.0"

% Dissolve, for Sugar Water: a bright samba-jazz in A major, vibraphone over
% electric-piano partido alto, with a surdo-style bass and a light batucada.
% Samba's 2/4 is written two bars to a 4/4 measure, sixteenths at quarter = 100.
% The intro plays once; the game loops from mark A, and the outro's last bar
% matches the intro's so the wrap joins like to like.

\header { title = "Dissolve" subtitle = "Sugar Water" composer = "Opus 5.5" tagline = ##f }

meter = { \time 4/4 \tempo 4 = 100 }
global = { \meter \key a \major }

% Give every note of a chord one duration, so a voicing can be reused rhythmically.
hit = #(define-music-function (dur chord) (ly:duration? ly:music?)
  (let ((copy (ly:music-deep-copy chord)))
    (for-each (lambda (note) (ly:music-set-property! note 'duration dur))
              (extract-named-music copy 'NoteEvent))
    copy))
% Partido-alto comping: two half-bar cells, one chord each.
comp = #(define-music-function (first second) (ly:music? ly:music?)
  #{ r16 \hit 8 $first \hit 16 $first r8 \hit 8 $first
     r16 \hit 16 $second r8 \hit 8. $second \hit 16 $second #})
% Surdo bass: short root on the beat, a sixteenth pickup into the accented fifth.
surdo = #(define-music-function (root fifth) (ly:pitch? ly:pitch?)
  #{ $root 8. $fifth 16 $fifth 4 #})

chAmaj = <cis' e' gis' b'>
chFsm = <e' gis' a' cis''>
chBm = <d' fis' a' cis''>
chEt = <d' fis' gis' cis''>
chEbn = <d' f' gis' b'>
chCsm = <e' gis' b' dis''>
chFst = <e' gis' ais' dis''>
chAt = <g' b' cis'' fis''>
chDmaj = <cis' e' fis' a'>
chDmsix = <d' f' a' b'>
chDm = <c' e' f' a'>
chGt = <f' a' b' e''>
chFmaj = <e' g' a' c''>
chEsus = <d' e' a' b'>

epIntro = { \comp \chAmaj \chFsm \comp \chBm \chEt \comp \chAmaj \chFsm \comp \chBm \chEbn }
epA = {
  \comp \chAmaj \chAmaj \comp \chAmaj \chAmaj \comp \chCsm \chFst \comp \chBm \chEt
  \comp \chBm \chBm \comp \chEt \chEt \comp \chCsm \chFst \comp \chBm \chEt
  \comp \chAmaj \chAmaj \comp \chAt \chAt \comp \chDmaj \chDmaj \comp \chDmsix \chGt
  \comp \chCsm \chFst \comp \chBm \chEt \comp \chAmaj \chFsm \comp \chBm \chEt
}
epBFront = { \comp \chDmaj \chDmaj \comp \chDm \chGt \comp \chCsm \chCsm \comp \chFst \chFst }
epB = {
  \epBFront
  \comp \chBm \chBm \comp \chEt \chEt \comp \chCsm \chFst \comp \chBm \chEt
  \epBFront
  \comp \chFmaj \chFmaj \comp \chEsus \chEt \comp \chAmaj \chFsm \comp \chBm \chEt
}
epSolo = { \repeat unfold 4 { \comp \chAmaj \chFsm \comp \chBm \chEt } }
epOutro = { \comp \chDmaj \chDmsix \comp \chCsm \chFst \comp \chBm \chBm \comp \chBm \chEbn }

bassIntro = { \surdo a, e, \surdo fis, cis, \surdo b, fis, \surdo e, b,, \surdo a, e, \surdo fis, cis, \surdo b, fis, \surdo e, b,, }
bassA = {
  \surdo a, e, \surdo a, e, \surdo a, e, \surdo a, e, \surdo cis gis, \surdo fis, cis, \surdo b, fis, \surdo e, b,,
  \surdo b, fis, \surdo b, fis, \surdo e, b,, \surdo e, b,, \surdo cis gis, \surdo fis, cis, \surdo b, fis, \surdo e, b,,
  \surdo a, e, \surdo a, e, \surdo a, e, \surdo a, e, \surdo d a, \surdo d a, \surdo d a, \surdo g, d,
  \surdo cis gis, \surdo fis, cis, \surdo b, fis, \surdo e, b,, \surdo a, e, \surdo fis, cis, \surdo b, fis, \surdo e, b,,
}
bassBFront = { \surdo d a, \surdo d a, \surdo d a, \surdo g, d, \surdo cis gis, \surdo cis gis, \surdo fis, cis, \surdo fis, cis, }
bassB = {
  \bassBFront
  \surdo b, fis, \surdo b, fis, \surdo e, b,, \surdo e, b,, \surdo cis gis, \surdo fis, cis, \surdo b, fis, \surdo e, b,,
  \bassBFront
  \surdo f, c \surdo f, c \surdo e, b,, \surdo e, b,, \surdo a, e, \surdo fis, cis, \surdo b, fis, \surdo e, b,,
}
bassSolo = { \repeat unfold 4 { \surdo a, e, \surdo fis, cis, \surdo b, fis, \surdo e, b,, } }
bassOutro = { \surdo d a, \surdo d a, \surdo cis gis, \surdo fis, cis, \surdo b, fis, \surdo b, fis, \surdo b, fis, \surdo e, b,, }

melAFront = {
  r8 cis''16 e'' gis''8. b''16~ b''4 a''8 e''8 |
  fis''8. e''16~ e''8 cis''8 b'4 r8. cis''16 |
  e''8. gis''16~ gis''8 b''8 ais''8. fis''16~ fis''8 e''8 |
  d''8. cis''16~ cis''8 b'8 gis'8. b'16 d''8 e''8 |
  fis''8. a''16~ a''4 fis''8. d''16~ d''8 cis''8 |
  b'4 r8 gis'16 b' d''8 e''8 fis''8 gis''8 |
  b''8. gis''16~ gis''8 e''8 ais''8. fis''16~ fis''8 cis''8 |
  d''4 cis''8 b'8 gis'4 r8 e''8 |
}
melABack = {
  r8 cis''16 e'' gis''8. b''16~ b''4 cis'''8 b''8 |
  a''8. g''16~ g''8 fis''8 e''4 r8 cis''16 d'' |
  e''8. fis''16~ fis''4 a''8 fis''8 e''8 d''8 |
  f''8. e''16~ e''8 d''8 b'8. d''16~ d''8 f''8 |
  gis''8. e''16~ e''8 cis''8 ais'8. cis''16~ cis''8 e''8 |
  d''8. fis''16~ fis''8 a''8 gis''8. e''16~ e''8 d''8 |
}
melA = {
  \melAFront \melABack
  cis''4. e''8~ e''8 cis''8 a'8 cis''8 |
  b'8. cis''16~ cis''8 d''8 e''8 r8 r4 |
}
melATag = {
  \melAFront \melABack
  a''8. gis''16~ gis''8 e''8 cis'''8. a''16~ a''8 e''8 |
  fis''8 e''8 d''8 cis''8 b'8. gis'16~ gis'4 |
}
melBFront = {
  r8 a'16 cis'' e''8. fis''16~ fis''2 |
  r8 a'16 c'' e''8. f''16~ f''4 e''8 d''8 |
  gis''8. fis''16~ fis''8 e''8 b'4 r4 |
  ais'8 cis''8 e''8 fis''8 gis''8. fis''16~ fis''4 |
}
melB = {
  \melBFront
  r8 fis'16 a' cis''8. d''16~ d''2 |
  r8 gis'16 b' d''8. e''16~ e''4 fis''8 gis''8 |
  b''8. gis''16~ gis''8 e''8 ais''8. cis'''16~ cis'''4 |
  b''8 a''8 fis''8 d''8 gis''8. b''16~ b''4 |
  \melBFront
  a''8. g''16~ g''8 e''8 c''4. r8 |
  d''8. e''16~ e''8 a'8 gis'8. b'16~ b'4 |
  cis''8. e''16~ e''8 a''8 gis''8. fis''16~ fis''8 e''8 |
  d''8 cis''8 b'8 a'8 gis'4 r4 |
}
% Breakdown: the vibraphone calls, the glockenspiel answers a beat late.
callOne = { cis'''8. b''16~ b''8 a''8 fis''4 r4 | r8 d''16 fis'' a''8 cis'''8 b''4 r4 | }
callTwo = { e'''8. cis'''16~ cis'''8 a''8 gis''4 fis''4 | r8 fis''16 a'' d'''8 cis'''8 b''8. gis''16~ gis''4 | }
answerOne = { r4 cis'''8. b''16~ b''8 a''8 fis''4 | r4 r8 d''16 fis'' a''8 cis'''8 b''4 | }
answerTwo = { r4 e'''8. cis'''16~ cis'''8 a''8 gis''4 | }
together = { d'''8 cis'''8 b''8 a''8 gis''4 e''4 | }
melSolo = { \callOne R1*2 \callTwo R1 \together }
glockSolo = { R1*2 \answerOne R1*2 \answerTwo \together }
melOutro = {
  fis''8. a''16~ a''8 fis''8 f''8. d''16~ d''8 b'8 |
  e''8. gis''16~ gis''8 b''8 ais''8. fis''16~ fis''8 e''8 |
  d''2 cis''4 b'4 |
  a'8. b'16~ b'8 d''8 e''4 r4 |
}

% Percussion cells, one measure each.
% A soft kick on the beat and a floor-tom surdo carrying the heavy second beat.
kick = \drummode { bd8. bd16 tomfl4-> bd8. bd16 tomfl4-> }
teleco = \drummode { ss16 r ss ss r ss r ss r ss ss r ss r ss r }
rideSamba = \drummode { cymr8 cymr16 cymr cymr8 cymr cymr8 cymr16 cymr cymr8 cymr }
ganza = \drummode { \repeat unfold 4 { mar16 mar mar mar-> } }
agogo = \drummode { agh8.-> agh16 r8 agl8 agh8 r8 agl8 agl8 }
kitStick = \drummode { << \teleco \\ \kick >> }
kitRide = \drummode { << \rideSamba \\ \kick >> }
kitCrash = \drummode { << { cymc4 ss16 r ss ss r ss r ss r ss ss r } \\ \kick >> }

vibes = {
  \global <>\mf
  R1*4
  \mark \default \melA
  \mark \default \melATag
  \mark \default \melB
  \mark \default \melSolo
  \mark \default \melOutro
}
glock = {
  \global <>\p
  R1*4 R1*16
  \melAFront R1*8
  R1*16 \glockSolo R1*4
}
ep = {
  \global <>\mp
  \epIntro \epA \epA \epB <>\pp \epSolo <>\mp \epOutro
}
bass = {
  \global \clef bass <>\mf
  \bassIntro \bassA \bassA \bassB \bassSolo \bassOutro
}
kit = \drummode {
  \meter <>\p
  \kitStick \kitStick \kitStick \kitStick
  \kitCrash \repeat unfold 15 \kitStick
  \kitCrash \repeat unfold 15 \kitStick
  \kitCrash \repeat unfold 15 \kitRide
  <>\pp \repeat unfold 8 \kitStick
  <>\p \kitCrash \kitRide \kitRide \kitStick
}
shaker = \drummode {
  \meter <>\ppp
  \repeat unfold 64 \ganza
}
bell = \drummode {
  \meter <>\pp
  R1*4 R1*16
  \repeat unfold 16 \agogo
  R1*16 R1*8 R1*4
}

\score {
    <<
      \new Staff \with { instrumentName = "Vibraphone" midiInstrument = "vibraphone" }
        { \vibes }
      \new Staff \with { instrumentName = "Glockenspiel" midiInstrument = "glockenspiel" }
        { \glock }
      \new Staff \with { instrumentName = "Electric piano" midiInstrument = "electric piano 1" }
        { \ep }
      \new Staff \with { instrumentName = "Bass" midiInstrument = "acoustic bass" }
        { \bass }
      \new DrumStaff \with { instrumentName = "Kit" }
        { \kit }
      \new DrumStaff \with { instrumentName = "Ganzá" }
        { \shaker }
      \new DrumStaff \with { instrumentName = "Agogô" }
        { \bell }
    >>
  \layout { }
  \midi { }
}
