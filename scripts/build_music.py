# /// script
# requires-python = ">=3.11,<3.14"
# dependencies = ["numpy==2.2.6", "mido==1.3.3", "soundfile==0.13.1"]
# ///
"""Render four original sax-led scene scores into MIDI and seamless stereo Ogg.

Run: uv run scripts/build_music.py
All tones, breath, and percussion are synthesized; no recordings or soundfonts.
"""

from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import subprocess
import wave

import mido
import numpy as np
import soundfile as sf

from music_scores import CHORDS, SONGS

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/audio"
WORK = ROOT / "builds/music"
RATE = 44100
PPQ = 960
CHANNELS = (0, 1, 2, 9)
PANS = (.12, -.3, -.05, .27)
COMP = {
    "swing": (((.5, .65), (2, .8)), ((0, .8), (2.5, .55))),
    "bossa": (((0, .5), (1.5, .5), (2.5, .6)), ((.5, .5), (2, .5), (3.5, .3))),
    "samba": (((.5, .24), (1.25, .24), (2.5, .24), (3.25, .24)),
              ((0, .24), (.75, .24), (2, .24), (3.5, .24))),
    "spacious": (((0, 1.6), (2.5, .9)), ((.5, 2.6),)),
}
BASS = {
    "swing": ((0, 0, .86, 76), (1, 1, .86, 69), (2, 2, .86, 76), (3, 3, .86, 69)),
    "bossa": ((0, 0, 1.25, 71), (1.5, 2, .35, 60), (2, 0, 1.25, 75), (3.5, 2, .35, 61)),
    "samba": ((0, 0, .5, 77), (.75, 2, .35, 65), (1.5, 0, .35, 74),
              (2.5, 1, .35, 69), (3.5, 3, .35, 67)),
    "spacious": ((0, 0, 1.8, 65), (2.5, 2, 1.1, 54)),
}


@dataclass(frozen=True)
class Note:
    track: int
    beat: float
    pitch: int
    length: float
    velocity: int


def clock(song, beat):
    whole = int(beat)
    fraction = beat - whole
    part = fraction * 2 * song.swing if fraction <= .5 else song.swing + (fraction - .5) * 2 * (1 - song.swing)
    return whole + part


def track_names(song):
    comp = {"bossa": "Nylon guitar comping", "spacious": "Soft electric piano"}
    return ("Synthesized saxophone", comp.get(song.style, "Piano comping"), "Acoustic bass", "Percussion")


def compose(song):
    assert len(song.melody) == len(song.harmony)
    notes = []
    for bar, phrase in enumerate(song.melody):
        for index, (beat, pitch, gate) in enumerate(phrase):
            notes.append(Note(0, bar * 4 + clock(song, beat), pitch, gate, 75 + (index % 3) * 4))
        notes.extend(rhythm_section(song, bar))
        notes.extend(drum_bar(song, bar))
    # Quantize once so MIDI and PCM use precisely the same event clock.
    return [Note(n.track, round(n.beat * PPQ) / PPQ, n.pitch,
                 round(n.length * PPQ) / PPQ, n.velocity) for n in notes]


def rhythm_section(song, bar):
    root, voicing, intervals = CHORDS[song.harmony[bar]]
    notes = []
    for beat, gate in COMP[song.style][bar % 2]:
        for index, pitch in enumerate(voicing):
            notes.append(Note(1, bar * 4 + clock(song, beat) + index * .009,
                              pitch, gate, 52 + index * 2 + (bar % 3) * 2))
    next_root = CHORDS[song.harmony[(bar + 1) % len(song.harmony)]][0]
    approach = next_root - 1 if next_root >= root else next_root + 1
    pitches = [root, root + intervals[1], root + intervals[2], approach]
    if song.style == "swing" and bar % 4 == 2:
        pitches[1:3] = pitches[2:0:-1]
    for beat, degree, gate, velocity in BASS[song.style]:
        notes.append(Note(2, bar * 4 + beat, pitches[degree], gate, velocity))
    return notes


def brush_bar(song, bar):
    notes = []
    for beat in range(4):
        notes.append(Note(3, bar * 4 + beat, 51, .12, 35 if beat % 2 == 0 else 42))
        if beat in (1, 3):
            notes.append(Note(3, bar * 4 + beat, 38, .13, 39))
            notes.append(Note(3, bar * 4 + clock(song, beat + .5), 51, .1, 25))
        else:
            notes.append(Note(3, bar * 4 + beat, 36, .14, 38))
    if bar % 8 == 7:
        notes.append(Note(3, bar * 4 + clock(song, 3.5), 38, .1, 26))
    return notes


def drum_bar(song, bar):
    if song.style == "swing":
        return brush_bar(song, bar)
    if song.style == "spacious":
        return [Note(3, bar * 4 + beat, pitch, .12, velocity)
                for beat, pitch, velocity in ((0, 36, 22), (1, 42, 23), (3, 38, 20))]
    subdivisions = 8 if song.style == "bossa" else 16
    notes = [Note(3, bar * 4 + step * 4 / subdivisions, 70, .08, 27 + (step % 2) * 7)
             for step in range(subdivisions)]
    accents = ((0, 36, 34), (2, 36, 42), (.5, 67, 31), (2.75, 68, 30))
    if song.style == "bossa":
        rim = ((0, 37, 39), (1.5, 37, 34), (3, 37, 37))
        accents = ((0, 36, 29), (2, 36, 33)) + rim
    else:
        accents += tuple((beat, 65, 36) for beat in (.75, 1.5, 2.5, 3.25, 3.75))
    notes.extend(Note(3, bar * 4 + beat, pitch, .12, velocity) for beat, pitch, velocity in accents)
    return notes


def write_midi(song, notes, path):
    midi = mido.MidiFile(type=1, ticks_per_beat=PPQ)
    conductor = mido.MidiTrack([
        mido.MetaMessage("track_name", name=song.title + " | original scene score"),
        mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(song.bpm)),
        mido.MetaMessage("time_signature", numerator=4, denominator=4),
        mido.MetaMessage("key_signature", key=song.key),
    ])
    midi.tracks.append(conductor)
    previous = 0
    for bar, name in song.sections:
        tick = bar * 4 * PPQ
        conductor.append(mido.MetaMessage("marker", text=name, time=tick - previous))
        previous = tick
    end_tick = len(song.harmony) * 4 * PPQ
    conductor.append(mido.MetaMessage("end_of_track", time=end_tick - previous))
    comp_program = {"bossa": 24, "spacious": 4}.get(song.style, 0)
    programs = (song.sax_program, comp_program, 32, None)
    for track, channel in enumerate(CHANNELS):
        events = []
        target = mido.MidiTrack([mido.MetaMessage("track_name", name=track_names(song)[track])])
        if programs[track] is not None:
            target.append(mido.Message("program_change", channel=channel, program=programs[track]))
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
        target.append(mido.MetaMessage("end_of_track", time=end_tick - previous))
        midi.tracks.append(target)
    midi.save(path)


def saxophone(note, time, rng, style):
    frequency = 440 * 2 ** ((note.pitch - 69) / 12)
    delayed_vibrato = 1 - np.exp(-np.maximum(time - .18, 0) / .18)
    phase = 2 * np.pi * frequency * time
    phase += frequency * .0045 / 5.2 * np.sin(2 * np.pi * 5.2 * time) * delayed_vibrato
    phase -= 2 * np.pi * frequency * .009 * .025 * (1 - np.exp(-time / .025))
    tone = np.zeros_like(time)
    brightness = {"swing": 1.0, "bossa": .78, "samba": 1.12, "spacious": .7}[style]
    for harmonic in range(1, 15):
        formant = .45 + .9 * np.exp(-((harmonic * frequency - 1050) / 850) ** 2)
        weight = formant / harmonic ** 1.05 * brightness ** (harmonic / 3)
        tone += weight * np.sin(phase * harmonic)
    breath = np.convolve(rng.standard_normal(len(time)), np.ones(5) / 5, mode="same")
    tone += .035 * breath
    tone *= (.95 + .05 * np.cos(2 * np.pi * 4.9 * time)) * (.84 + .16 * np.exp(-time * 4))
    return tone


def pitched(song, note, time, rng, seconds_per_beat):
    phase = 2 * np.pi * 440 * 2 ** ((note.pitch - 69) / 12) * time
    gate = note.length * seconds_per_beat
    release = np.exp(-np.maximum(time - gate, 0) / .075)
    attack = 1 - np.exp(-time / (.026 if note.track == 0 else .005))
    if note.track == 0:
        tone = saxophone(note, time, rng, song.style)
    elif note.track == 1:
        tone = chord_tone(song.style, phase, time)
    else:
        tone = np.sin(phase) * np.exp(-time * 1.4)
        tone += .38 * np.sin(phase * 2) * np.exp(-time * 4)
        tone += .13 * np.sin(phase * 3) * np.exp(-time * 8)
    return tone * attack * release


def chord_tone(style, phase, time):
    weights = {"bossa": (1, .31, .13, .04, .012), "spacious": (1, .24, .035)}
    tone = np.zeros_like(time)
    for partial, weight in enumerate(weights.get(style, (.8, .37, .16, .08, .045, .022)), 1):
        ratio = partial * np.sqrt(1 + .00015 * partial * partial)
        decay = .55 + partial * .28 if style == "spacious" else .9 + partial * .65
        tone += weight * np.sin(phase * ratio) * np.exp(-time * decay)
    return tone


def percussion(note, time, rng):
    noise = rng.standard_normal(len(time))
    hiss = np.concatenate(([0.0], np.diff(noise))) * .22
    if note.pitch == 36:
        phase = 2 * np.pi * (48 * time + 2.6 * (1 - np.exp(-time * 28)))
        tone = np.sin(phase) * np.exp(-time * 23)
    elif note.pitch == 38:
        tone = hiss * np.exp(-time * 25) + .12 * np.sin(2 * np.pi * 180 * time) * np.exp(-time * 35)
    elif note.pitch in (37, 65):
        frequency = 830 if note.pitch == 37 else 390
        tone = (.5 * np.sin(2 * np.pi * frequency * time) + .24 * np.sin(2 * np.pi * frequency * 1.57 * time))
        tone *= np.exp(-time * (75 if note.pitch == 37 else 35))
    elif note.pitch in (67, 68):
        frequency = 810 if note.pitch == 67 else 590
        tone = (.4 * np.sin(2 * np.pi * frequency * time) + .2 * np.sin(2 * np.pi * frequency * 2.76 * time))
        tone *= np.exp(-time * 21)
    else:
        tone = hiss * np.exp(-time * 45)
        for frequency in (4310, 5723, 6871):
            tone += .035 * np.sin(2 * np.pi * frequency * time) * np.exp(-time * 23)
    return tone * (1 - np.exp(-time / .002))


def render_stem(song, notes, track, frames, seconds_per_beat):
    stem = np.zeros((frames, 2), dtype=np.float64)
    rng = np.random.default_rng(5092026 + song.bpm + track)
    gains = (.23, .17, .3, .19)
    pan = np.sqrt([(1 - PANS[track]) / 2, (1 + PANS[track]) / 2])
    for note in (n for n in notes if n.track == track):
        time = np.arange(round((note.length * seconds_per_beat + 1.1) * RATE)) / RATE
        tone = percussion(note, time, rng) if track == 3 else pitched(song, note, time, rng, seconds_per_beat)
        tone[-256:] *= np.linspace(1, 0, 256)
        tone *= gains[track] * (note.velocity / 100) ** 1.4
        stereo = tone[:, None] * pan
        start = round(note.beat * seconds_per_beat * RATE)
        count = min(len(stereo), frames - start)
        stem[start:start + count] += stereo[:count]
        stem[:len(stereo) - count] += stereo[count:]
    return stem


def render(song, notes):
    seconds_per_beat = mido.bpm2tempo(song.bpm) / 1_000_000
    frames = round(len(song.harmony) * 4 * seconds_per_beat * RATE)
    audio = np.zeros((frames, 2), dtype=np.float64)
    energies = []
    for track in range(4):
        stem = render_stem(song, notes, track, frames, seconds_per_beat)
        energies.append(float(np.sqrt(np.mean(stem ** 2))))
        audio += stem
    dry = audio.copy()
    reflections = ((.071, .11), (.113, .08), (.173, .05), (.251, .025))
    if song.style == "spacious":
        reflections = ((.19, .21), (.31, .14), (.47, .1), (.73, .07), (1.1, .03))
    for delay, gain in reflections:
        audio += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    audio -= audio.mean(axis=0)
    scale = 10 ** (-4 / 20) / np.max(np.abs(audio))
    audio *= scale
    stems_dbfs = [float(20 * np.log10(energy * scale)) for energy in energies]
    return audio, dict(zip(track_names(song), stems_dbfs))


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


def validate_midi(song, path, notes):
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
        assert not active and tick == len(song.harmony) * 4 * PPQ
        counts.append(count)
    assert midi.type == 1 and len(midi.tracks) == 5 and sum(counts) == len(notes)
    return {"format": midi.type, "tracks": len(midi.tracks), "ppq": midi.ticks_per_beat,
            "note_counts": dict(zip(("Conductor",) + track_names(song), counts)), "duration_seconds": midi.length,
            "all_notes_released": True, "all_tracks_end_at_tick": len(song.harmony) * 4 * PPQ}


def write_audio(audio, wav_path, ogg_path):
    with wave.open(str(wav_path), "wb") as target:
        target.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        target.writeframes(np.round(audio * 32767).astype("<i2").tobytes())
    # libsndfile 1.2.2 crashes on one large Vorbis write; bounded blocks avoid it.
    with sf.SoundFile(ogg_path, "w", samplerate=RATE, channels=2, format="OGG",
                      subtype="VORBIS", compression_level=.2) as target:
        for start in range(0, len(audio), 8192):
            target.write(audio[start:start + 8192])
    decoded = subprocess.run(["ffmpeg", "-v", "error", "-i", str(ogg_path), "-f", "f32le", "-"],
                             check=True, capture_output=True).stdout
    return np.frombuffer(decoded, dtype="<f4").reshape(-1, 2)


def build_song(song):
    notes = compose(song)
    midi_path = OUTPUT / (song.slug + ".mid")
    ogg_path = OUTPUT / (song.slug + ".ogg")
    wav_path = WORK / (song.slug + ".wav")
    write_midi(song, notes, midi_path)
    midi_report = validate_midi(song, midi_path, notes)
    audio, stems = render(song, notes)
    decoded = write_audio(audio, wav_path, ogg_path)
    report = {"title": song.title, "bars": len(song.harmony), "sections": song.sections, "bpm": song.bpm,
              "style": song.style, "sample_rate": RATE, "channels": 2, "midi": midi_report,
              "source_pcm": measure(audio), "decoded_ogg": measure(decoded), "dry_stem_rms_dbfs": stems,
              "note_events_sha256": hashlib.sha256(json.dumps([asdict(n) for n in notes]).encode()).hexdigest(),
              "source_pcm_sha256": hashlib.sha256(wav_path.read_bytes()).hexdigest(),
              "midi_sha256": hashlib.sha256(midi_path.read_bytes()).hexdigest(),
              "ogg_sha256": hashlib.sha256(ogg_path.read_bytes()).hexdigest(),
              "encoder_padding_frames": len(decoded) - len(audio),
              "listening": "Not auditioned; timbre judgment and in-game balance require listening."}
    (WORK / (song.slug + "-report.json")).write_text(json.dumps(report, indent=2) + "\n")
    assert abs(len(decoded) - len(audio)) <= RATE // 1000
    assert report["decoded_ogg"]["clipped_samples"] == 0
    assert report["decoded_ogg"]["boundary_step"] < report["decoded_ogg"]["adjacent_step_p99"]
    assert stems["Synthesized saxophone"] > report["source_pcm"]["rms_dbfs"] - 9
    print(json.dumps({"song": song.slug, "decoded_ogg": report["decoded_ogg"], "sax_stem_dbfs": stems["Synthesized saxophone"]}), flush=True)
    return report


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    reports = {song.slug: build_song(song) for song in SONGS}
    (WORK / "report.json").write_text(json.dumps(reports, indent=2) + "\n")
    print("FOUR_SONGS_OK", flush=True)


if __name__ == "__main__":
    main()
