# /// script
# requires-python = ">=3.11,<3.14"
# dependencies = ["numpy==2.2.6", "mido==1.3.3", "soundfile==0.13.1"]
# ///
"""Compose Particle Shuffle, an original 32-bar jazz loop, and render its MIDI.

Run: uv run scripts/build_music.py
No recordings or soundfonts: every sound is synthesized from these note events.
"""

from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import subprocess
import wave

import mido
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/audio"
WORK = ROOT / "builds/music"
RATE = 44100
PPQ = 960
TEMPO = mido.bpm2tempo(112)
SECONDS_PER_BEAT = TEMPO / 1_000_000
BEATS = 128
FRAMES = round(BEATS * SECONDS_PER_BEAT * RATE)
NAMES = ("Vibraphone melody", "Piano comping", "Walking upright bass", "Brush kit")
CHANNELS = (0, 1, 2, 9)
PROGRAMS = (11, 0, 32, None)
PANS = (0.22, -0.3, -0.05, 0.2)

# Root, voiced upper harmony, and bass chord tones, all in concert pitch.
CHORDS = {
    "F6": (41, (57, 62, 65, 69), (0, 4, 7, 9)),
    "D7": (38, (54, 60, 64, 69), (0, 4, 7, 10)),
    "Gm9": (43, (58, 62, 65, 69), (0, 3, 7, 10)),
    "C9": (36, (58, 62, 64, 67), (0, 4, 7, 10)),
    "Am7": (45, (55, 60, 64, 67), (0, 3, 7, 10)),
    "Bb6": (46, (55, 60, 62, 65), (0, 4, 7, 9)),
    "Bdim": (47, (56, 59, 62, 65), (0, 3, 6, 9)),
}
FORM = (
    ["F6", "D7", "Gm9", "C9", "F6", "D7", "Gm9", "C9"]
    + ["F6", "D7", "Gm9", "C9", "Am7", "D7", "Gm9", "C9"]
    + ["Bb6", "Bdim", "F6", "D7", "Gm9", "C9", "Am7", "D7"]
    + ["F6", "D7", "Gm9", "C9", "F6", "D7", "Gm9", "C9"]
)
# (straight eighth-grid beat, MIDI pitch, gate length); the clock adds swing.
THEME = [
    [(0, 81, .7), (.5, 84, .4), (1, 81, .7), (2, 79, .4), (2.5, 77, .4), (3, 81, .6)],
    [(.5, 78, .4), (1, 81, .7), (2, 84, .4), (2.5, 83, .4), (3, 81, .6)],
    [(0, 79, .7), (.5, 82, .4), (1, 81, .7), (2, 77, 1.2)],
    [(.5, 76, .4), (1, 79, .7), (2, 74, .4), (2.5, 76, .4), (3, 79, .6)],
    [(0, 81, .7), (.5, 84, .4), (1, 86, .6), (2, 84, .4), (2.5, 81, .4), (3, 79, .6)],
    [(.5, 78, .4), (1, 81, .7), (2, 78, .4), (2.5, 76, .4), (3, 74, .6)],
    [(0, 77, .7), (1, 79, .4), (1.5, 81, .4), (2, 82, .7), (3, 81, .5)],
    [(0, 79, .6), (1, 76, .6), (2, 74, .4), (2.5, 76, .4)],
]
BRIDGE = [
    [(0, 86, 1.1), (1.5, 84, .4), (2, 82, .7), (3, 79, .6)],
    [(.5, 80, .4), (1, 83, .7), (2, 86, .6), (3, 89, .5)],
    [(0, 88, .6), (.5, 86, .4), (1, 84, 1.0), (3, 81, .6)],
    [(.5, 81, .4), (1, 78, .7), (2, 76, .6), (3, 74, .6)],
    [(0, 77, .6), (1, 79, .6), (2, 82, 1.1)],
    [(.5, 81, .4), (1, 79, .7), (2, 76, 1.0)],
    [(0, 79, .6), (.5, 81, .4), (1, 84, .7), (2.5, 83, .4), (3, 81, .6)],
    [(0, 78, .6), (1, 76, .6), (2, 74, .4), (2.5, 76, .4), (3, 78, .5)],
]


@dataclass(frozen=True)
class Note:
    track: int
    beat: float
    pitch: int
    length: float
    velocity: int


def swing(beat):
    whole = int(beat)
    fraction = beat - whole
    return whole + (fraction * 1.24 if fraction <= .5 else .62 + (fraction - .5) * .76)


def compose():
    notes = []
    for bar, chord in enumerate(FORM):
        phrase = BRIDGE[bar % 8] if 16 <= bar < 24 else THEME[bar % 8]
        for index, (beat, pitch, gate) in enumerate(phrase):
            # Reprise answers the opening phrase lower; the last bar turns home.
            pitch -= 12 if bar in (12, 13) else 0
            notes.append(Note(0, bar * 4 + swing(beat), pitch, gate, 70 + (index % 3) * 4))
        if bar in (15, 31):
            notes.append(Note(0, bar * 4 + swing(3.5), 76, .25, 61))
        notes.extend(rhythm_section(bar, chord))
    # Quantize once so MIDI and PCM share precisely the same timing.
    return [Note(n.track, round(n.beat * PPQ) / PPQ, n.pitch,
                 round(n.length * PPQ) / PPQ, n.velocity) for n in notes]


def rhythm_section(bar, chord):
    notes = []
    root, voicing, intervals = CHORDS[chord]
    comp = ((.5, .65), (2, .8)) if bar % 2 == 0 else ((0, .8), (2.5, .55))
    if 16 <= bar < 20:
        comp = ((0, 1.2), (2.5, .55))
    for beat, gate in comp:
        for index, pitch in enumerate(voicing):
            notes.append(Note(1, bar * 4 + swing(beat) + index * .009,
                              pitch, gate, 51 + index * 2 + (bar % 3) * 2))
    next_root = CHORDS[FORM[(bar + 1) % 32]][0]
    approach = next_root - 1 if next_root >= root else next_root + 1
    bass = [root, root + intervals[1], root + intervals[2], approach]
    if bar % 4 == 2:
        bass[1:3] = [root + intervals[2], root + intervals[1]]
    for beat, pitch in enumerate(bass):
        notes.append(Note(2, bar * 4 + beat, pitch, .86, 76 if beat in (0, 2) else 69))
    return notes + brush_bar(bar)


def brush_bar(bar):
    notes = []
    for beat in range(4):
        notes.append(Note(3, bar * 4 + beat, 51, .12, 35 if beat % 2 == 0 else 42))
        if beat in (1, 3):
            notes.append(Note(3, bar * 4 + beat, 38, .13, 39))
            notes.append(Note(3, bar * 4 + swing(beat + .5), 51, .1, 25))
        else:
            notes.append(Note(3, bar * 4 + beat, 36, .14, 38))
    if bar % 8 == 7:
        notes.append(Note(3, bar * 4 + swing(3.5), 38, .1, 26))
    return notes


def write_midi(notes, path):
    midi = mido.MidiFile(type=1, ticks_per_beat=PPQ)
    conductor = mido.MidiTrack([
        mido.MetaMessage("track_name", name="Particle Shuffle | original 32-bar AABA"),
        mido.MetaMessage("set_tempo", tempo=TEMPO),
        mido.MetaMessage("time_signature", numerator=4, denominator=4),
        mido.MetaMessage("key_signature", key="F"),
    ])
    midi.tracks.append(conductor)
    for index, name in enumerate(("A", "A variation", "B bridge", "A return")):
        conductor.append(mido.MetaMessage("marker", text=name, time=0 if index == 0 else 32 * PPQ))
    conductor.append(mido.MetaMessage("end_of_track", time=32 * PPQ))
    for track, channel in enumerate(CHANNELS):
        events = []
        target = mido.MidiTrack([mido.MetaMessage("track_name", name=NAMES[track])])
        if PROGRAMS[track] is not None:
            target.append(mido.Message("program_change", channel=channel, program=PROGRAMS[track]))
        target.append(mido.Message("control_change", channel=channel, control=10,
                                   value=round(64 + 63 * PANS[track])))
        for note in (n for n in notes if n.track == track):
            start = round(note.beat * PPQ)
            stop = round((note.beat + note.length) * PPQ)
            events.extend([(start, 1, mido.Message("note_on", channel=channel, note=note.pitch, velocity=note.velocity)),
                           (stop, 0, mido.Message("note_off", channel=channel, note=note.pitch))])
        previous = 0
        for tick, _, message in sorted(events, key=lambda e: (e[0], e[1])):
            target.append(message.copy(time=tick - previous))
            previous = tick
        target.append(mido.MetaMessage("end_of_track", time=BEATS * PPQ - previous))
        midi.tracks.append(target)
    midi.save(path)


def pitched(note, time):
    frequency = 440 * 2 ** ((note.pitch - 69) / 12)
    phase = 2 * np.pi * frequency * time
    gate = note.length * SECONDS_PER_BEAT
    release = np.exp(-np.maximum(time - gate, 0) / (.32 if note.track == 0 else .095))
    attack = 1 - np.exp(-time / (.007 if note.track == 2 else .002))
    if note.track == 0:
        tone = np.sin(phase) * np.exp(-time / 1.5)
        tone += .17 * np.sin(phase * 3.99) * np.exp(-time / .22)
        tone += .025 * np.sin(phase * 9.98) * np.exp(-time / .06)
        tone *= .94 + .06 * np.cos(2 * np.pi * 4.8 * time)
    elif note.track == 1:
        tone = np.zeros_like(time)
        for partial, weight in enumerate((.8, .37, .16, .08, .045, .022), 1):
            ratio = partial * np.sqrt(1 + .00015 * partial * partial)
            tone += weight * np.sin(phase * ratio) * np.exp(-time * (.9 + partial * .65))
    else:
        tone = np.sin(phase) * np.exp(-time * 1.4)
        tone += .38 * np.sin(phase * 2) * np.exp(-time * 4)
        tone += .13 * np.sin(phase * 3) * np.exp(-time * 8)
    return tone * attack * release


def percussion(note, time, rng):
    noise = rng.standard_normal(len(time))
    hiss = np.concatenate(([0.0], np.diff(noise))) * .22
    if note.pitch == 36:
        phase = 2 * np.pi * (48 * time + 2.6 * (1 - np.exp(-time * 28)))
        tone = np.sin(phase) * np.exp(-time * 28)
    elif note.pitch == 38:
        tone = hiss * np.exp(-time * 25) + .12 * np.sin(2 * np.pi * 180 * time) * np.exp(-time * 35)
    else:
        tone = hiss * np.exp(-time * 40)
        for frequency in (4310, 5723, 6871):
            tone += .035 * np.sin(2 * np.pi * frequency * time) * np.exp(-time * 18)
    return tone * (1 - np.exp(-time / .002))


def render(notes):
    audio = np.zeros((FRAMES, 2), dtype=np.float64)
    rng = np.random.default_rng(5092026)
    gains = (.21, .18, .38, .2)
    for note in notes:
        length = note.length * SECONDS_PER_BEAT + (2.7 if note.track == 0 else .9)
        time = np.arange(round(length * RATE)) / RATE
        tone = percussion(note, time, rng) if note.track == 3 else pitched(note, time)
        # The very quiet tail ends smoothly, including when it crosses the loop.
        tone[-256:] *= np.linspace(1, 0, 256)
        tone *= gains[note.track] * (note.velocity / 100) ** 1.4
        pan = PANS[note.track]
        stereo = tone[:, None] * np.sqrt([(1 - pan) / 2, (1 + pan) / 2])
        start = round(note.beat * SECONDS_PER_BEAT * RATE)
        count = min(len(stereo), FRAMES - start)
        audio[start:start + count] += stereo[:count]
        audio[:len(stereo) - count] += stereo[count:]
    # Circular early reflections preserve the steady-state room across wraps.
    dry = audio.copy()
    for delay, gain in ((.071, .11), (.113, .08), (.173, .05), (.251, .025)):
        audio += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    audio -= audio.mean(axis=0)
    audio *= 10 ** (-4 / 20) / np.max(np.abs(audio))
    return audio


def measure(audio):
    peak = float(np.max(np.abs(audio)))
    rms = float(np.sqrt(np.mean(audio ** 2)))
    delta = np.abs(np.diff(audio, axis=0))
    return {"frames": len(audio), "duration_seconds": len(audio) / RATE,
            "peak_dbfs": float(20 * np.log10(peak)), "rms_dbfs": float(20 * np.log10(rms)),
            "clipped_samples": int(np.count_nonzero(np.abs(audio) >= 1)),
            "boundary_step": float(np.max(np.abs(audio[0] - audio[-1]))),
            "adjacent_step_p99": float(np.quantile(delta, .99)),
            "boundary_10ms_max_step": float(np.max(np.abs(np.diff(np.concatenate((audio[-441:], audio[:441])), axis=0)))),
            "dc_per_channel": audio.mean(axis=0).tolist()}


def validate_midi(path, notes):
    midi = mido.MidiFile(path)
    counts = []
    for track in midi.tracks:
        active = set()
        count = tick = 0
        for message in track:
            tick += message.time
            if message.type == "note_on" and message.velocity:
                key = (message.channel, message.note)
                assert key not in active, ("overlapping MIDI note", key, tick)
                active.add(key)
                count += 1
            elif message.type == "note_off" or message.type == "note_on":
                active.remove((message.channel, message.note))
        assert not active and tick == BEATS * PPQ
        counts.append(count)
    assert midi.type == 1 and len(midi.tracks) == 5 and sum(counts) == len(notes)
    return {"format": midi.type, "tracks": len(midi.tracks), "ppq": midi.ticks_per_beat,
            "note_counts": dict(zip(("Conductor",) + NAMES, counts)), "duration_seconds": midi.length,
            "all_notes_released": True, "all_tracks_end_at_tick": BEATS * PPQ}


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    notes = compose()
    midi_path = OUTPUT / "particle_shuffle.mid"
    ogg_path = OUTPUT / "particle_shuffle.ogg"
    wav_path = WORK / "particle_shuffle.wav"
    write_midi(notes, midi_path)
    audio = render(notes)
    with wave.open(str(wav_path), "wb") as target:
        target.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        target.writeframes(np.round(audio * 32767).astype("<i2").tobytes())
    # libsndfile 1.2.2 crashes on one large Vorbis write; bounded blocks avoid it.
    with sf.SoundFile(ogg_path, "w", samplerate=RATE, channels=2, format="OGG",
                      subtype="VORBIS", compression_level=.2) as target:
        for start in range(0, FRAMES, 8192):
            target.write(audio[start:start + 8192])
    decoded = subprocess.run(["ffmpeg", "-v", "error", "-i", str(ogg_path), "-f", "f32le", "-"],
                             check=True, capture_output=True).stdout
    decoded = np.frombuffer(decoded, dtype="<f4").reshape(-1, 2)
    report = {"title": "Particle Shuffle", "bars": 32, "form": "AABA", "bpm": 112,
              "sample_rate": RATE, "channels": 2, "midi": validate_midi(midi_path, notes),
              "source_pcm": measure(audio), "decoded_ogg": measure(decoded),
              "source_pcm_sha256": hashlib.sha256(wav_path.read_bytes()).hexdigest(),
              "midi_sha256": hashlib.sha256(midi_path.read_bytes()).hexdigest(),
              "ogg_sha256": hashlib.sha256(ogg_path.read_bytes()).hexdigest(),
              "encoder_padding_frames": len(decoded) - FRAMES,
              "listening": "Not auditioned; musical taste and in-game balance require listening."}
    (WORK / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    # Sub-millisecond codec padding is harmless; the decoded join must stay clean.
    assert abs(len(decoded) - FRAMES) <= RATE // 1000
    assert report["decoded_ogg"]["clipped_samples"] == 0
    assert report["decoded_ogg"]["boundary_step"] < report["decoded_ogg"]["adjacent_step_p99"]


if __name__ == "__main__":
    main()
