"""Create original, short eating sounds with the Python standard library."""
from pathlib import Path
import math
import struct
import wave

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 44100


def write_sound(name, duration, sample):
    frames = bytearray()
    for index in range(int(duration * RATE)):
        value = max(-1.0, min(1.0, sample(index / RATE)))
        frames.extend(struct.pack("<h", int(value * 24000)))
    with wave.open(str(OUTPUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(frames)


def bite(time):
    envelope = min(1.0, time * 150) * math.exp(-time * 22)
    phase = 2 * math.pi * (240 * time - 230 * time * time)
    return envelope * (math.sin(phase) * 0.7 + math.sin(phase * 1.5) * 0.2)


def completion(time):
    total = 0.0
    for index, pitch in enumerate([261.63, 329.63, 392.0, 523.25]):
        age = time - index * 0.085
        if age >= 0:
            envelope = min(1.0, age * 90) * math.exp(-age * 4)
            total += math.sin(age * pitch * 2 * math.pi) * envelope * 0.22
    return total


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    write_sound("bite.wav", 0.28, bite)
    write_sound("complete.wav", 1.1, completion)
