# /// script
# requires-python = ">=3.11"
# dependencies = ["mido==1.3.3"]
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
"""

import argparse
from array import array
import json
import math
from pathlib import Path
import re
import subprocess

import mido

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
    """Frames at the first rehearsal mark, where the loop starts, and at the end of the score."""
    elapsed, start = 0.0, None
    for message in mido.MidiFile(midi_path):
        elapsed += message.time
        if message.type == "marker" and start is None:
            start = elapsed
    frames = [seconds * RATE for seconds in (start, elapsed)]
    # Tempos are chosen so both points fall on whole frames.
    assert all(abs(value - round(value)) < .01 for value in frames), (midi_path, frames)
    return [round(value) for value in frames]


def render(midi, wav, sounds):
    profile, final = SOUNDS[sounds]
    if final:
        roots = (Path("/Library/Application Support"), Path.home() / "Library/Application Support")
        assert any((root / MUSE_SAMPLER).exists() for root in roots), "Muse Sounds is not installed"
    job = WORK / (midi.stem + "-job.json")
    job.write_text(json.dumps([{"in": str(midi), "out": str(wav)}]))
    run(MSCORE, "--sound-profile", profile, "-j", str(job))


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
    run("sox", str(parts[3]), str(parts[2]), "-C", OGG_QUALITY, str(ogg))
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
    so the Ogg's end must converge on exactly that audio: the residual against it
    over the final 5 ms is near zero only when the wrap sounds like uninterrupted playback.
    """
    audio = decode(ogg)
    window, onset = RATE * SEAM_MS // 1000 * 2, RATE * 5 // 1000 * 2
    head, tail = audio[start * 2:start * 2 + window], audio[-window:]
    predecessor = decode_range(mastered, start - window // 2, window // 2)
    residual = [a - b for a, b in zip(tail[-onset:], predecessor[-onset:])]
    step = max(abs(audio[-2 + channel] - audio[start * 2 + channel]) for channel in range(2))
    adjacent = sorted(abs(audio[i] - audio[i - 2]) for i in range(2, len(audio), 97))
    return {"decoded_frames": len(audio) // 2, "expected_frames": end,
            "loop_start_seconds": round(start / RATE, 6), "loop_seconds": round((end - start) / RATE, 6),
            "loop_first_50ms_rms_dbfs": round(rms_dbfs(head), 2), "loop_last_50ms_rms_dbfs": round(rms_dbfs(tail), 2),
            "pre_loop_50ms_rms_dbfs": round(rms_dbfs(predecessor), 2),
            "seam_residual_5ms_db": round(rms_dbfs(residual) - rms_dbfs(predecessor[-onset:]), 2),
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
    start, end = timeline(midi)
    rendered = WORK / (name + "-render.wav")
    render(midi, rendered, sounds)
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
    assert seam["seam_residual_5ms_db"] < -20, seam
    assert seam["loop_step"] < seam["adjacent_step_p99"], seam
    assert final_peak <= -1, (slug, "true peak", final_peak)
    report = {"title": title, "sounds": SOUNDS[sounds][0], "ogg": str(ogg.relative_to(ROOT)),
              "source": str((SOURCE / (name + ".ly")).relative_to(ROOT)),
              "score_pages": [str(page.relative_to(ROOT)) for page in pages],
              "duration_seconds": end / RATE, "integrated_lufs": final_lufs, "true_peak_dbfs": final_peak,
              "ogg_bytes": ogg.stat().st_size, **seam}
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
        (output / "report.json").write_text(json.dumps(reports, indent=2) + "\n")
    print("MUSIC_OK", flush=True)


if __name__ == "__main__":
    main()
