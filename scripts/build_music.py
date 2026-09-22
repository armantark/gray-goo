# /// script
# requires-python = ">=3.11"
# dependencies = ["mido==1.3.3"]
# ///
"""Engrave the four scene scores with LilyPond, render them with MuseScore 4, and cut seamless Ogg loops.

Run: uv run scripts/build_music.py [slug ...]

Each LilyPond source engraves one pass of its piece and writes MIDI of three
passes. MuseScore renders that MIDI, reverb and a limiter are added, and the
middle pass is cut out, so its start already carries the tails of the previous
pass. MuseScore's passes drift by tens of samples, so the loop head is a short
crossfade from the render's real continuation after the middle pass into the
pass's own head: the wrap then plays exactly what uninterrupted playback would.
"""

from array import array
import json
import math
from pathlib import Path
import subprocess
import sys

import mido

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/music"
OUTPUT = ROOT / "assets/audio"
WORK = ROOT / "builds/music"
MSCORE = "/Applications/MuseScore 4.app/Contents/MacOS/mscore"
RATE = 44100
PASSES = 3
TARGET_LUFS = -16.0
LIMIT = 10 ** (-2 / 20)
OGG_QUALITY = "4"
SEAM_MS = 50
CROSSFADE_MS = 60
# Ogg names are the ones src/game.gd MUSIC_TRACKS already loads.
PIECES = {
    "particle_shuffle": ("sugar_water", "Dissolve", ("reverb", "35", "60", "70", "100", "12")),
    "tidepool_bossa": ("tide_pool", "Low Tide Glimmer", ("reverb", "45", "50", "80", "100", "15")),
    "skatepark_samba": ("skatepark_bowl", "Coping Stones", ("reverb", "25", "50", "55", "80", "8")),
    "cosmic_drift": ("cosmic_web", "Filament", ("reverb", "80", "40", "100", "100", "30")),
}


def run(*command):
    return subprocess.run(command, check=True, capture_output=True, text=True)


def engrave(name):
    for stale in WORK.glob(name + "*.png"):
        stale.unlink()
    run("lilypond", "-dno-point-and-click", "--png", "-dresolution=100",
        "-o", str(WORK / name), str(SOURCE / (name + ".ly")))
    return WORK / (name + ".midi"), sorted(WORK.glob(name + "*.png"))


def pass_frames(midi_path):
    """Frames in one pass; the MIDI holds PASSES identical passes."""
    seconds = mido.MidiFile(midi_path).length / PASSES
    frames = seconds * RATE
    # Tempos are chosen so a pass is a whole number of frames; drift would move the seam.
    assert abs(frames - round(frames)) < .01, (midi_path, frames)
    return round(frames)


def loudness(path):
    report = run("ffmpeg", "-nostats", "-i", str(path), "-af", "ebur128=peak=true",
                 "-f", "null", "-").stderr
    summary = report[report.rindex("Summary:"):]
    value = lambda label: float(summary.split(label)[1].split()[0])
    return value("I:"), value("Peak:")


def run_bytes(*command):
    return subprocess.run(command, check=True, capture_output=True).stdout


def decode(path):
    return array("f", run_bytes("ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-"))


def decode_range(path, start, count):
    data = run_bytes("sox", str(path), "-t", "f32", "-", "trim", f"{start}s", f"{count}s")
    return array("f", data)


def rms_dbfs(values):
    return 20 * math.log10(math.sqrt(sum(v * v for v in values) / len(values)))


def seam_report(ogg, mastered, frames, period):
    """Compare the loop's opening with what the render really plays after the seam.

    Raw first/last 50 ms levels differ wherever the loop opens on a downbeat, so the
    seam test is the residual against the true continuation, which is near zero only
    when the wrap is indistinguishable from uninterrupted playback.
    """
    audio = decode(ogg)
    window = RATE * SEAM_MS // 1000 * 2
    head, tail = audio[:window], audio[-window:]
    continuation = decode_range(mastered, frames + period, window // 2)
    onset = RATE * 5 // 1000 * 2
    residual = [a - b for a, b in zip(head[:onset], continuation[:onset])]
    step = max(abs(audio[channel] - audio[-2 + channel]) for channel in range(2))
    adjacent = sorted(abs(audio[i] - audio[i - 2]) for i in range(2, len(audio), 97))
    return {"decoded_frames": len(audio) // 2, "expected_frames": period, "pass_frames": frames,
            "first_50ms_rms_dbfs": round(rms_dbfs(head), 2), "last_50ms_rms_dbfs": round(rms_dbfs(tail), 2),
            "continuation_50ms_rms_dbfs": round(rms_dbfs(continuation), 2),
            "seam_residual_5ms_db": round(rms_dbfs(residual) - rms_dbfs(continuation[:onset]), 2),
            "loop_step": round(step, 5), "adjacent_step_p99": round(adjacent[int(len(adjacent) * .99)], 5)}


def seam_images(ogg, name):
    around = WORK / (name + "-seam.wav")
    run("sox", str(ogg), str(WORK / (name + "-seam-tail.wav")), "trim", "-3")
    run("sox", str(ogg), str(WORK / (name + "-seam-head.wav")), "trim", "0", "3")
    run("sox", str(WORK / (name + "-seam-tail.wav")), str(WORK / (name + "-seam-head.wav")), str(around))
    run("sox", str(around), "-n", "spectrogram", "-x", "1200", "-y", "513", "-z", "90",
        "-t", name + " loop seam at 3 s", "-o", str(WORK / (name + "-seam.png")))
    run("sox", str(ogg), "-n", "spectrogram", "-x", "1800", "-y", "400", "-z", "90",
        "-t", name, "-o", str(WORK / (name + "-full.png")))


def drift(mastered, frames):
    """Samples by which the third pass lags the second at the seam, by cross-correlation."""
    span, reach = 4096, 400
    mono = lambda start, count: [sum(pair) for pair in zip(*[iter(decode_range(mastered, start, count))] * 2)]
    head = mono(frames, span)
    around = mono(2 * frames - reach, span + 2 * reach)
    score = lambda lag: sum(a * b for a, b in zip(head, around[reach + lag:]))
    return max(range(-reach, reach + 1), key=score)


def cut_loop(mastered, frames, name, ogg):
    """Loop the second pass, stretched by the drift so the head crossfade blends aligned audio."""
    period = frames + drift(mastered, frames)
    fade = RATE * CROSSFADE_MS // 1000
    parts = [WORK / (name + suffix) for suffix in ("-continuation.wav", "-head.wav", "-joined-head.wav", "-body.wav")]
    run("sox", str(mastered), str(parts[0]), "trim", f"{frames + period}s", f"{fade}s", "fade", "h", "0", f"{fade}s", f"{fade}s")
    run("sox", str(mastered), str(parts[1]), "trim", f"{frames}s", f"{fade}s", "fade", "h", f"{fade}s")
    run("sox", "-m", "-v", "1", str(parts[0]), "-v", "1", str(parts[1]), str(parts[2]))
    run("sox", str(mastered), str(parts[3]), "trim", f"{frames + fade}s", f"{period - fade}s")
    run("sox", str(parts[2]), str(parts[3]), "-C", OGG_QUALITY, str(ogg))
    return period


def build(slug):
    name, title, reverb = PIECES[slug]
    midi, pages = engrave(name)
    frames = pass_frames(midi)
    rendered = WORK / (name + "-render.wav")
    run(MSCORE, "-o", str(rendered), str(midi))
    wet = WORK / (name + "-wet.wav")
    # Float intermediates keep reverb overs intact until the limiter.
    run("sox", str(rendered), "-e", "floating-point", "-b", "32", str(wet), *reverb)
    middle = ("trim", f"{frames}s", f"{frames}s")
    loop = WORK / (name + "-loop.wav")
    run("sox", str(wet), "-e", "floating-point", "-b", "32", str(loop), *middle)
    lufs, _ = loudness(loop)
    # Limit all passes, then cut, so the limiter state is continuous across the seam.
    mastered = WORK / (name + "-mastered.wav")
    run("ffmpeg", "-y", "-v", "error", "-i", str(wet), "-af",
        f"volume={TARGET_LUFS - lufs:.2f}dB,alimiter=limit={LIMIT}:attack=5:release=80:level=0",
        "-c:a", "pcm_f32le", str(mastered))
    ogg = OUTPUT / (slug + ".ogg")
    period = cut_loop(mastered, frames, name, ogg)
    final_lufs, final_peak = loudness(ogg)
    seam = seam_report(ogg, mastered, frames, period)
    seam_images(ogg, name)
    assert seam["decoded_frames"] == period, seam
    assert abs(seam["first_50ms_rms_dbfs"] - seam["continuation_50ms_rms_dbfs"]) < .5, seam
    assert seam["seam_residual_5ms_db"] < -20, seam
    assert seam["loop_step"] < seam["adjacent_step_p99"], seam
    assert final_peak <= -1, (slug, "true peak", final_peak)
    report = {"title": title, "source": str((SOURCE / (name + ".ly")).relative_to(ROOT)),
              "score_pages": [str(page.relative_to(ROOT)) for page in pages],
              "duration_seconds": period / RATE, "integrated_lufs": final_lufs, "true_peak_dbfs": final_peak,
              "ogg_bytes": ogg.stat().st_size, **seam}
    (WORK / (name + "-report.json")).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({slug: report}), flush=True)
    return report


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    slugs = sys.argv[1:] or list(PIECES)
    reports = {slug: build(slug) for slug in slugs}
    if len(reports) == len(PIECES):
        spread = max(r["integrated_lufs"] for r in reports.values()) - min(r["integrated_lufs"] for r in reports.values())
        assert spread <= 2, ("loudness spread", spread)
        (WORK / "report.json").write_text(json.dumps(reports, indent=2) + "\n")
    print("MUSIC_OK", flush=True)


if __name__ == "__main__":
    main()
