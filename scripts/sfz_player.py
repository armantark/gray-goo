"""Play MIDI notes through the subset of SFZ the upright bass library uses.

MuseScore cannot load SFZ, so the bass is rendered here from the same MIDI
events and mixed with MuseScore's render of the rest of the band. Supported:
<global>/<group>/<region> headers; key, lokey, hikey, lovel, hivel, sample,
pitch_keycenter, tune, volume, ampeg_attack, ampeg_release, trigger=release,
and locc64/hicc64 (the sustain pedal is never pressed, so only regions that
accept CC64 = 0 play). Samples do not loop.
"""

from dataclasses import dataclass
from pathlib import Path
import re

import numpy as np
import soundfile as sf

RATE = 44100
ATTACK_LEVEL = .2


@dataclass(frozen=True)
class Region:
    lokey: int
    hikey: int
    lovel: int
    hivel: int
    sample: Path
    keycenter: int
    tune: float
    volume: float
    attack: float
    release: float
    on_release: bool


@dataclass(frozen=True)
class Note:
    start: float
    stop: float
    pitch: int
    velocity: int


def load(path):
    """Regions that can sound with the pedal up, de-duplicated.

    The library repeats some release regions verbatim four times; a literal
    player would stack them 12 dB too loud.
    """
    text = re.sub(r"//[^\n]*", "", Path(path).read_text(errors="replace"))
    scopes = {"global": {}, "group": {}}
    regions = []
    for header, body in re.findall(r"<(\w+)>([^<]*)", text):
        opcodes = dict(re.findall(r"(\w+)=(\S+)", body))
        if header in scopes:
            scopes[header] = opcodes
            if header == "global":
                scopes["group"] = {}
        elif header == "region":
            merged = {**scopes["global"], **scopes["group"], **opcodes}
            if int(merged.get("locc64", 0)) > 0:
                continue
            regions.append(region(merged, Path(path).parent))
    return list(dict.fromkeys(regions))


def region(opcodes, root):
    key = opcodes.get("key")
    lokey = int(opcodes.get("lokey", key))
    hikey = int(opcodes.get("hikey", key))
    return Region(lokey, hikey, int(opcodes.get("lovel", 0)), int(opcodes.get("hivel", 127)),
                  root / opcodes["sample"], int(opcodes.get("pitch_keycenter", key if key else lokey)),
                  float(opcodes.get("tune", 0)), float(opcodes.get("volume", 0)),
                  float(opcodes.get("ampeg_attack", 0)), float(opcodes.get("ampeg_release", 0)),
                  opcodes.get("trigger") == "release")


def matching(regions, key, velocity, on_release):
    return [r for r in regions if r.on_release == on_release
            and r.lokey <= key <= r.hikey and r.lovel <= velocity <= r.hivel]


class Player:
    def __init__(self, sfz_path, transpose):
        """transpose: semitones added to MIDI pitch to reach the library's key numbers."""
        self.regions = load(sfz_path)
        self.transpose = transpose
        self.samples = {}

    def sample(self, path):
        """Audio and attack time: frames until the sample first reaches a fifth of its peak."""
        if path not in self.samples:
            audio, rate = sf.read(path, dtype="float32", always_2d=True)
            assert rate == RATE, (path, rate)
            level = np.abs(audio).max(axis=1)
            self.samples[path] = audio, int(np.argmax(level >= ATTACK_LEVEL * level.max()))
        return self.samples[path]

    def voice(self, region, key, velocity, length):
        """One region's audio for a note, repitched, enveloped and gained; length None plays it out."""
        source, _ = self.sample(region.sample)
        ratio = 2 ** ((key - region.keycenter) / 12 + region.tune / 1200)
        count = int((len(source) - 1) / ratio)
        where = np.arange(count) * ratio
        audio = np.stack([np.interp(where, np.arange(len(source)), source[:, c]) for c in range(2)], axis=1)
        envelope = np.ones(count, dtype=np.float32)
        attack = int(region.attack * RATE)
        if attack:
            envelope[:attack] = np.linspace(0, 1, min(attack, count))[:min(attack, count)]
        if length is not None and length < count:
            release = max(int(region.release * RATE), 1)
            tail = np.clip(1 - np.arange(count - length) / release, 0, 1)
            envelope[length:] *= tail
            audio, envelope = audio[:length + release], envelope[:length + release]
        # SFZ amp_veltrack=100: gain follows the square of velocity.
        gain = 10 ** (region.volume / 20) * (velocity / 127) ** 2
        return audio * (envelope[:, None] * gain)

    def attack(self, region, key):
        ratio = 2 ** ((key - region.keycenter) / 12 + region.tune / 1200)
        return round(self.sample(region.sample)[1] / ratio)

    def render(self, notes, frames):
        out = np.zeros((frames, 2), dtype=np.float32)
        for note in notes:
            key = note.pitch + self.transpose
            start, stop = round(note.start * RATE), round(note.stop * RATE)
            # Start each sample early by its attack time, so the attack lands on the note.
            layers = [(start - self.attack(r, key), self.voice(r, key, note.velocity, stop - start))
                      for r in matching(self.regions, key, note.velocity, False)]
            layers += [(stop, self.voice(r, key, note.velocity, None))
                       for r in matching(self.regions, key, note.velocity, True)]
            assert layers, ("no SFZ region for", note)
            for offset, audio in layers:
                skip = max(-offset, 0)
                count = min(len(audio) - skip, frames - offset - skip)
                if count > 0:
                    out[offset + skip:offset + skip + count] += audio[skip:skip + count]
        return out
