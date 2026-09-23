# /// script
# requires-python = ">=3.11"
# dependencies = ["mido==1.3.3", "numpy==2.2.6", "soundfile==0.13.1"]
# ///
"""Engrave the four scene scores with LilyPond, render them with MuseScore 4, and cut seamless Ogg loops.

Run: uv run scripts/build_music.py [--sounds muse-sounds|ms-basic] [slug ...]

Only final sounds write the game's Oggs in assets/audio. MS Basic is General MIDI,
which the owner rejected, so it renders previews under builds/music/preview for
arranging and listening checks only.

Each piece plays its intro once and then loops from its first rehearsal mark,
through the Ogg's Godot loop_offset. The last moments before the loop end are
crossfaded into the audio that really precedes that mark, so the first pass out
of the intro and every later wrap reach the loop start through the same sound.

MuseScore cannot load the SFZ upright bass, so each score's bass track is
rendered by sfz_player from the same MIDI and mixed with MuseScore's render of
the rest of the band. MuseScore sounds events a few milliseconds late, drifting
across a piece, so a click at every bass note is rendered through MuseScore and
the bass follows the fitted lateness.
"""

import argparse
from array import array
import json
import math
from pathlib import Path
import re
import subprocess
import time
import zipfile

import mido
import numpy as np
import soundfile as sf

import sfz_player

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/music"
OUTPUT = ROOT / "assets/audio"
WORK = ROOT / "builds/music"
MSCORE = "/Applications/MuseScore 4.app/Contents/MacOS/mscore"
# MuseScore sound profiles, keyed by the --sounds name, with whether they may ship.
SOUNDS = {"muse-sounds": ("MuseSounds", True), "ms-basic": ("MuseScore Basic", False)}
# MuseScore silently falls back to MS Basic when this library is missing.
MUSE_SAMPLER = "MuseSampler/lib/libMuseSamplerCoreLib.dylib"
RATE = 44100
# The Larry Seyer Upright Acoustic Bass (Pianobook, SFZ), unpacked outside git.
UPRIGHT_BASS = ROOT / ".tooling/upright-bass/sfz/Larry Seyer Upright Acoustic Bass SFZ Format Ver 1.0/0000 - Larry Seyer Upright Acoustic Bass.sfz"
# The library keys its samples an octave above sounding pitch (key 40 sounds E1).
UPRIGHT_TRANSPOSE = 12
BASS_PROGRAM = 32
# Bass stem loudness relative to the rest of the band, in LU.
BASS_RELATIVE_LU = -7.0
# Tames the uneven low notes that masked the kick and adds fingerboard definition.
BASS_EQ = ("equalizer", "110", "1q", "-3", "equalizer", "1400", "1.2q", "+3")
ATTACK_LEVEL = .2
PROBE_REACH_MS = 15
PROBE_OUTLIER_MS = 3
TARGET_LUFS = -16.0
# Vorbis adds intersample overshoot, so the limiter sits below the -1 dBTP ceiling.
LIMIT = 10 ** (-2 / 20)
OGG_QUALITY = "4"
SEAM_MS = 50
CROSSFADE_MS = 60
HOLD_MS = 10
# Ogg names are the ones src/game.gd MUSIC_TRACKS already loads.
PIECES = {
    "particle_shuffle": ("sugar_water", "Dissolve", ("reverb", "35", "60", "70", "100", "12")),
    "tidepool_bossa": ("tide_pool", "Low Tide Glimmer", ("reverb", "45", "50", "80", "100", "15")),
    "skatepark_samba": ("skatepark_bowl", "Coping Stones", ("reverb", "25", "50", "55", "80", "8")),
    "cosmic_drift": ("cosmic_web", "Filament", ("reverb", "80", "40", "100", "100", "30")),
}
# Imported templates that Muse Sounds does not play, and the template that it does.
RETARGET = {
    "orff-alto-glockenspiel": ("glockenspiel", "pitched-percussion.glockenspiel"),
    "percussion-synthesizer": ("congas", "drum.group.congas"),
}
# Templates whose default Muse sound is wrong or missing: (pack, sound, Muse Hub id, playback setup).
OVERRIDES = {
    "electric-piano": ("Muse Keys", "Suitcase Piano", "172", "keyboards.piano.electric"),
    "agogo-bells": ("Muse Percussion", "Agogos", "192", "percussion.agogo"),
}


def run(*command):
    return subprocess.run(command, check=True, capture_output=True, text=True)


def run_bytes(*command):
    return subprocess.run(command, check=True, capture_output=True).stdout


def engrave(name):
    for stale in [*WORK.glob(name + "-page*.png"), WORK / (name + ".png")]:
        stale.unlink(missing_ok=True)
    run("lilypond", "-dno-point-and-click", "--png", "-dresolution=100",
        "-o", str(WORK / name), str(SOURCE / (name + ".ly")))
    pages = sorted(WORK.glob(name + "-page*.png"), key=lambda page: int(page.stem.rsplit("page", 1)[1]))
    return WORK / (name + ".midi"), pages or [WORK / (name + ".png")]


def timeline(midi_path):
    """Nominal seconds at the first rehearsal mark, where the loop starts, and at the end of the score."""
    elapsed, start = 0.0, None
    for message in mido.MidiFile(midi_path):
        elapsed += message.time
        if message.type == "marker" and start is None:
            start = elapsed
    return start, elapsed


def render(midi, wav, sounds, retarget=None, overrides=None):
    """Render a MIDI file with MuseScore and return the sound each part played.

    The MIDI is imported to a score that keeps the sound profile, parts that import
    as the wrong instrument are retargeted, and parts with several Muse sounds get
    an explicit one. The render runs without --sound-profile, because that flag
    would replace the explicit choices.
    """
    profile, final = SOUNDS[sounds]
    if final:
        roots = (Path("/Library/Application Support"), Path.home() / "Library/Application Support")
        assert any((root / MUSE_SAMPLER).exists() for root in roots), "Muse Sounds is not installed"
    score = WORK / (midi.stem + ".mscz")
    run(MSCORE, "--sound-profile", profile, "-o", str(score), str(midi))
    retune(score, retarget or {}, (overrides or {}) if final else {})
    mapping = sound_map(score, profile)
    if final:
        stray = {part: sound for part, sound in mapping.items() if sound[2] != "muse_sampler_sound_pack"}
        assert not stray, ("parts not on Muse Sounds", stray)
    job = WORK / (midi.stem + "-job.json")
    job.write_text(json.dumps([{"in": str(score), "out": str(wav)}]))
    began = time.time()
    run(MSCORE, "-j", str(job))
    if final:
        assert_sampler_log(began)
    return mapping


def retune(score, retarget, overrides):
    """Patch the imported score: retarget instrument templates and pin explicit Muse sounds."""
    with zipfile.ZipFile(score) as archive:
        files = {name: archive.read(name) for name in archive.namelist()}
    [name] = [name for name in files if name.endswith(".mscx")]
    text = files[name].decode()
    for old, (new, sound) in retarget.items():
        text = re.sub(rf'<Instrument id="{old}">(.*?)<instrumentId>[^<]*',
                      lambda m: f'<Instrument id="{new}">{m.group(1)}<instrumentId>{sound}', text, flags=re.S)
    settings = json.loads(files["audiosettings.json"])
    for part, template in re.findall(r'<Part id="(\d+)">.*?<Instrument id="([^"]+)">', text, flags=re.S):
        if template in overrides:
            pack, sound, uid, setup = overrides[template]
            meta = {"attributes": {"museCategory": pack, "museName": sound, "musePack": pack, "museUID": uid,
                                   "museVendorName": "", "playbackSetupData": setup},
                    "hasNativeEditorSupport": False, "id": f"{pack}\\{sound}\\{uid}",
                    "type": "muse_sampler_sound_pack", "vendor": "MuseSounds"}
            settings["tracks"].append({"instrumentId": template, "partId": part,
                                       "in": {"resourceMeta": meta, "unitConfiguration": {}}})
    files[name], files["audiosettings.json"] = text.encode(), json.dumps(settings).encode()
    with zipfile.ZipFile(score, "w", zipfile.ZIP_DEFLATED) as archive:
        for file, data in files.items():
            archive.writestr(file, data)


def sound_map(score, profile):
    """{part: (template, sound, resource type)}: the profile's choice unless the score pins one."""
    report = score.with_suffix(".tracks.json")
    run(MSCORE, "--sound-profile", profile, "--tracks-diff", str(report), "-o", str(score.with_suffix(".mp3")), str(score))
    tracks = json.loads(report.read_text())
    chosen = {t["partId"]: t for t in tracks["newTracks"] if t["partId"] != "999"}
    chosen.update({t["partId"]: t for t in tracks["oldTracks"] if t["partId"] in chosen})
    return {part: (t["instrumentId"], t["name"], t["type"]) for part, t in sorted(chosen.items(), key=lambda i: int(i[0]))}


def assert_sampler_log(began):
    """MuseScore writes one log per run; the render's must show Muse Sounds starting."""
    logs = Path.home() / "Library/Application Support/MuseScore/MuseScore4/logs"
    latest = max((log for log in logs.glob("*.log") if log.stat().st_mtime >= began), key=lambda log: log.stat().st_mtime)
    text = latest.read_text(errors="replace")
    assert "MuseSampler successfully inited" in text and "Successfully initialized sampler" in text, latest


def track_notes(track):
    """(start tick, stop tick, pitch, velocity) for every note in a MIDI track."""
    notes, held, tick = [], {}, 0
    for message in track:
        tick += message.time
        if message.type == "note_on" and message.velocity:
            held[message.note] = (tick, message.velocity)
        elif message.type in ("note_on", "note_off") and message.note in held:
            begin, velocity = held.pop(message.note)
            notes.append((begin, tick, message.note, velocity))
    return notes


def split_bass(midi_path, name):
    """Write the band without its bass track, and the bass alone; return the bass notes in seconds."""
    midi = mido.MidiFile(midi_path)
    tempos = [m.tempo for m in midi.tracks[0] if m.type == "set_tempo"]
    assert len(set(tempos)) == 1, ("one tempo per score", tempos)
    programs = [{m.program for m in track if m.type == "program_change"} for track in midi.tracks]
    [bass] = [i for i, found in enumerate(programs) if BASS_PROGRAM in found]
    band, alone = (mido.MidiFile(type=1, ticks_per_beat=midi.ticks_per_beat) for _ in range(2))
    band.tracks.extend(t for i, t in enumerate(midi.tracks) if i != bass)
    alone.tracks.extend([midi.tracks[0], midi.tracks[bass]])
    paths = WORK / (name + "-band.midi"), WORK / (name + "-bass.midi")
    band.save(paths[0])
    alone.save(paths[1])
    seconds = lambda tick: mido.tick2second(tick, midi.ticks_per_beat, tempos[0])
    notes = [sfz_player.Note(seconds(begin), seconds(stop), pitch, velocity)
             for begin, stop, pitch, velocity in track_notes(midi.tracks[bass])]
    return *paths, notes


def probe(bass_midi, name, sounds):
    """Fit MuseScore's timeline from a side-stick click at every bass note start.

    MuseScore sounds events a few milliseconds late in 4/4, and in 12/8 its clock
    runs about 0.1% fast, so nominal MIDI times drift by over 100 ms across a piece.
    Returns a function from nominal seconds to MuseScore seconds, and the fit's
    offsets at five points for the report.
    """
    midi = mido.MidiFile(bass_midi)
    tempo = next(m.tempo for m in midi.tracks[0] if m.type == "set_tempo")
    starts = sorted({begin for begin, *_ in track_notes(midi.tracks[1])})
    events = sorted([(t, 1) for t in starts] + [(t + midi.ticks_per_beat // 16, 0) for t in starts])
    clicks, previous = mido.MidiTrack(), 0
    for t, on in events:
        clicks.append(mido.Message("note_on", channel=9, note=37, velocity=110 * on, time=t - previous))
        previous = t
    probe_midi, probe_wav = WORK / (name + "-probe.midi"), WORK / (name + "-probe.wav")
    mido.MidiFile(type=1, ticks_per_beat=midi.ticks_per_beat, tracks=[midi.tracks[0], clicks]).save(probe_midi)
    render(probe_midi, probe_wav, sounds)
    audio, _ = sf.read(probe_wav, dtype="float32", always_2d=True)
    onsets = click_onsets(np.abs(audio).max(axis=1))
    nominal = [mido.tick2second(t, midi.ticks_per_beat, tempo) for t in starts]
    nearest = lambda t: onsets[np.argmin(np.abs(onsets - t))]
    # Some clicks never sound (Muse Sounds drops the first), so follow the drift from
    # onset to onset and skip any click with no onset near where the drift predicts.
    lateness = float(np.median([nearest(t) - t for t in nominal[:8]]))
    matched = []
    for t in nominal:
        found = nearest(t + lateness)
        if abs(found - t - lateness) < PROBE_REACH_MS / 1000:
            lateness = found - t
            matched.append((t, lateness))
    assert len(matched) > .8 * len(nominal), ("probe clicks found", len(matched), len(nominal))
    nominal, measured = (np.array(column) for column in zip(*matched))
    fit = np.polyfit(nominal, measured, 1)
    keep = np.abs(measured - np.polyval(fit, nominal)) < PROBE_OUTLIER_MS / 1000
    fit = np.polyfit(nominal[keep], measured[keep], 1)
    points = np.linspace(nominal[0], nominal[-1], 5)
    return (lambda t: t + np.polyval(fit, t)), [round(float(np.polyval(fit, t)) * 1000, 2) for t in points]


def click_onsets(level):
    """Seconds at which the level first crosses ATTACK_LEVEL of its peak, at least 50 ms apart."""
    above = np.flatnonzero(level >= ATTACK_LEVEL * level.max())
    firsts = above[np.insert(np.diff(above) > RATE // 20, 0, True)]
    return firsts / RATE


def mix_bass(band_wav, notes, to_mscore, name):
    """Add the SFZ upright bass on MuseScore's timeline, BASS_RELATIVE_LU below the band."""
    band, _ = sf.read(band_wav, dtype="float32", always_2d=True)
    player = sfz_player.Player(UPRIGHT_BASS, UPRIGHT_TRANSPOSE)
    moved = [sfz_player.Note(to_mscore(n.start), to_mscore(n.stop), n.pitch, n.velocity) for n in notes]
    bass = player.render(moved, len(band))
    dry, bass_wav = WORK / (name + "-upright-dry.wav"), WORK / (name + "-upright.wav")
    sf.write(dry, bass, RATE, subtype="FLOAT")
    run("sox", str(dry), "-e", "floating-point", "-b", "32", str(bass_wav), *BASS_EQ)
    bass, _ = sf.read(bass_wav, dtype="float32", always_2d=True)
    gain_db = loudness(band_wav)[0] + BASS_RELATIVE_LU - loudness(bass_wav)[0]
    mixed = WORK / (name + "-render.wav")
    sf.write(mixed, band + bass * 10 ** (gain_db / 20), RATE, subtype="FLOAT")
    return mixed, round(gain_db, 2)


def loudness(path):
    report = run("ffmpeg", "-nostats", "-i", str(path), "-af", "ebur128=peak=true",
                 "-f", "null", "-").stderr
    summary = report[report.rindex("Summary:"):]
    value = lambda label: float(summary.split(label)[1].split()[0])
    return value("I:"), value("Peak:")


def master(rendered, start, end, reverb, name):
    """Add reverb, normalize the loop to the target loudness, and limit peaks."""
    wet = WORK / (name + "-wet.wav")
    # Float intermediates keep reverb overs intact until the limiter.
    run("sox", str(rendered), "-e", "floating-point", "-b", "32", str(wet), *reverb)
    loop = WORK / (name + "-loop.wav")
    run("sox", str(wet), str(loop), "trim", f"{start}s", f"{end - start}s")
    lufs, _ = loudness(loop)
    mastered = WORK / (name + "-mastered.wav")
    run("ffmpeg", "-y", "-v", "error", "-i", str(wet), "-af",
        f"volume={TARGET_LUFS - lufs:.2f}dB,alimiter=limit={LIMIT}:attack=5:release=80:level=0",
        "-c:a", "pcm_f32le", str(mastered))
    return mastered


def mono(path, start, count):
    samples = decode_range(path, start, count)
    return [left + right for left, right in zip(samples[::2], samples[1::2])]


def best_lag(path, reference, candidate, count, reach=400):
    """Offset of candidate, within reach, whose audio best lines up with reference's."""
    fixed = mono(path, reference, count)
    moving = mono(path, candidate - reach, count + 2 * reach)
    score = lambda lag: sum(a * b for a, b in zip(fixed, moving[reach + lag:]))
    return max(range(-reach, reach + 1), key=score)


def cut_loop(mastered, start, end, name, ogg):
    """Keep intro and loop, crossfading the loop's last moments into the audio just before its start.

    MuseScore's timing wanders by a millisecond or so, and blending the two passages
    out of step cancels shared bass notes, so the outro side is shifted into line first
    and the loop absorbs that shift. The fade ends HOLD_MS early, leaving the file's
    final samples identical to the audio that precedes the loop start.
    """
    fade, hold = RATE * CROSSFADE_MS // 1000, RATE * HOLD_MS // 1000
    reference = start - fade - hold
    split = end - fade - hold + best_lag(mastered, reference, end - fade - hold, fade)
    parts = [WORK / (name + suffix) for suffix in ("-outro-end.wav", "-intro-end.wav", "-joined-end.wav", "-body.wav")]
    run("sox", str(mastered), str(parts[0]), "trim", f"{split}s", f"{fade}s",
        "fade", "h", "0", f"{fade}s", f"{fade}s", "pad", "0", f"{hold}s")
    run("sox", str(mastered), str(parts[1]), "trim", f"{reference}s", f"{fade + hold}s", "fade", "h", f"{fade}s")
    run("sox", "-m", "-v", "1", str(parts[0]), "-v", "1", str(parts[1]), str(parts[2]))
    run("sox", str(mastered), str(parts[3]), "trim", "0s", f"{split}s")
    # The owner auditions this uncompressed copy; the game plays the Ogg encoded from it.
    final = WORK / f"final-{name}.wav"
    run("sox", str(parts[3]), str(parts[2]), "-b", "24", str(final))
    run("sox", str(final), "-C", OGG_QUALITY, str(ogg))
    return split + fade + hold


def set_loop_offset(ogg, start):
    settings = ogg.with_name(ogg.name + ".import")
    text = settings.read_text()
    assert "loop_offset=" in text, settings
    settings.write_text(re.sub(r"loop_offset=.*", f"loop_offset={start / RATE:.6f}", text))


def decode(path):
    return array("f", run_bytes("ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-"))


def decode_range(path, start, count):
    return array("f", run_bytes("sox", str(path), "-t", "f32", "-", "trim", f"{start}s", f"{count}s"))


def rms_dbfs(values):
    return 20 * math.log10(math.sqrt(sum(v * v for v in values) / len(values)))


def seam_report(ogg, mastered, start, end):
    """Measure the wrap from the Ogg's end back to the loop start.

    The loop's opening follows the audio just before the loop start in the render,
    so the Ogg's end must converge on exactly that audio: its residual over the final
    5 ms should be no worse than Vorbis's own error anywhere else in the loop.
    """
    audio = decode(ogg)
    window, onset = RATE * SEAM_MS // 1000 * 2, RATE * 5 // 1000 * 2
    head, tail = audio[start * 2:start * 2 + window], audio[-window:]
    predecessor = decode_range(mastered, start - window // 2, window // 2)
    residual = [a - b for a, b in zip(tail[-onset:], predecessor[-onset:])]
    # The same residual mid-loop, where the Ogg is an untouched copy of the master: the codec's floor.
    middle = (start + end) // 2
    reference = decode_range(mastered, middle, onset // 2)
    interior = [a - b for a, b in zip(audio[middle * 2:middle * 2 + onset], reference)]
    step = max(abs(audio[-2 + channel] - audio[start * 2 + channel]) for channel in range(2))
    adjacent = sorted(abs(audio[i] - audio[i - 2]) for i in range(2, len(audio), 97))
    return {"decoded_frames": len(audio) // 2, "expected_frames": end,
            "loop_start_seconds": round(start / RATE, 6), "loop_seconds": round((end - start) / RATE, 6),
            "loop_first_50ms_rms_dbfs": round(rms_dbfs(head), 2), "loop_last_50ms_rms_dbfs": round(rms_dbfs(tail), 2),
            "pre_loop_50ms_rms_dbfs": round(rms_dbfs(predecessor), 2),
            "seam_residual_5ms_db": round(rms_dbfs(residual) - rms_dbfs(predecessor[-onset:]), 2),
            "interior_residual_5ms_db": round(rms_dbfs(interior) - rms_dbfs(reference), 2),
            "loop_step": round(step, 5), "adjacent_step_p99": round(adjacent[int(len(adjacent) * .99)], 5)}


def seam_images(ogg, start, name):
    """Spectrograms of the whole Ogg and of the 3 s either side of the wrap."""
    ends = [WORK / (name + suffix) for suffix in ("-seam-tail.wav", "-seam-head.wav", "-seam.wav")]
    run("sox", str(ogg), str(ends[0]), "trim", "-3")
    run("sox", str(ogg), str(ends[1]), "trim", f"{start}s", "3")
    run("sox", str(ends[0]), str(ends[1]), str(ends[2]))
    run("sox", str(ends[2]), "-n", "spectrogram", "-x", "1200", "-y", "513", "-z", "90",
        "-t", name + " loop wrap at 3 s", "-o", str(WORK / (name + "-seam.png")))
    run("sox", str(ogg), "-n", "spectrogram", "-x", "1800", "-y", "400", "-z", "90",
        "-t", name, "-o", str(WORK / (name + "-full.png")))


def build(slug, sounds, output):
    name, title, reverb = PIECES[slug]
    midi, pages = engrave(name)
    band_midi, bass_midi, notes = split_bass(midi, name)
    band = WORK / (name + "-band.wav")
    sound_parts = render(band_midi, band, sounds, RETARGET, OVERRIDES)
    to_mscore, lateness = probe(bass_midi, name, sounds)
    start, end = (round(to_mscore(seconds) * RATE) for seconds in timeline(midi))
    rendered, bass_gain = mix_bass(band, notes, to_mscore, name)
    mastered = master(rendered, start, end, reverb, name)
    ogg = output / (slug + ".ogg")
    end = cut_loop(mastered, start, end, name, ogg)
    if output == OUTPUT:
        set_loop_offset(ogg, start)
    final_lufs, final_peak = loudness(ogg)
    seam = seam_report(ogg, mastered, start, end)
    seam_images(ogg, start, name)
    assert seam["decoded_frames"] == end, seam
    assert abs(seam["loop_last_50ms_rms_dbfs"] - seam["pre_loop_50ms_rms_dbfs"]) < 1, seam
    assert seam["seam_residual_5ms_db"] < seam["interior_residual_5ms_db"] + 3, seam
    assert seam["loop_step"] < seam["adjacent_step_p99"], seam
    assert final_peak <= -1, (slug, "true peak", final_peak)
    report = {"title": title, "sounds": SOUNDS[sounds][0], "ogg": str(ogg.relative_to(ROOT)),
              "source": str((SOURCE / (name + ".ly")).relative_to(ROOT)),
              "score_pages": [str(page.relative_to(ROOT)) for page in pages],
              "duration_seconds": end / RATE, "integrated_lufs": final_lufs, "true_peak_dbfs": final_peak,
              "ogg_bytes": ogg.stat().st_size, **seam, "mscore_lateness_ms": lateness, "sounds_by_part": sound_parts, "bass_gain_db": bass_gain}
    (WORK / (name + "-report.json")).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({slug: report}), flush=True)
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sounds", choices=SOUNDS, default="muse-sounds")
    parser.add_argument("slugs", nargs="*", metavar="slug", help=", ".join(PIECES))
    args = parser.parse_args()
    args.slugs = args.slugs or list(PIECES)
    if unknown := set(args.slugs) - set(PIECES):
        parser.error(f"unknown pieces {sorted(unknown)}")
    WORK.mkdir(parents=True, exist_ok=True)
    output = OUTPUT if SOUNDS[args.sounds][1] else WORK / "preview"
    output.mkdir(parents=True, exist_ok=True)
    reports = {slug: build(slug, args.sounds, output) for slug in args.slugs}
    if len(reports) == len(PIECES):
        spread = max(r["integrated_lufs"] for r in reports.values()) - min(r["integrated_lufs"] for r in reports.values())
        assert spread <= 2, ("loudness spread", spread)
        (WORK / ("report.json" if output == OUTPUT else "preview/report.json")).write_text(json.dumps(reports, indent=2) + "\n")
    print("MUSIC_OK", flush=True)


if __name__ == "__main__":
    main()
