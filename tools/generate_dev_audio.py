"""Generate the deterministic development-only rhythm test WAV."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22_050
DURATION_SECONDS = 24
OUTPUT = Path(__file__).resolve().parents[1] / "content/songs/dev-test-song/audio.wav"


def sample_at(index: int) -> int:
    time = index / SAMPLE_RATE
    beat_phase = time % 0.5
    kick = math.sin(2.0 * math.pi * 70.0 * time) * math.exp(-18.0 * beat_phase)
    accent = 1.0 if int(time / 0.5) % 4 == 0 else 0.65
    tone = 0.08 * math.sin(2.0 * math.pi * 220.0 * time)
    value = max(-1.0, min(1.0, 0.72 * accent * kick + tone))
    return round(value * 32767)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for index in range(SAMPLE_RATE * DURATION_SECONDS):
            frames.extend(struct.pack("<h", sample_at(index)))
        output.writeframes(frames)


if __name__ == "__main__":
    main()
