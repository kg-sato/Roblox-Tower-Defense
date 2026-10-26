"""Levels the downloaded music and writes game-ready Ogg Vorbis files (Blender's bundled audio library; no pip or ffmpeg).

    blender.exe -b --python Audio/prepare_music.py

For each track in Audio/Music/raw: decode, scale to a common loudness (target RMS -18 dBFS), soft-limit so the sample peak stays
at or below -1 dBFS (the raw MP3 "Shinsei" decodes to +13 dBFS and would clip), apply a 40 ms fade-in and a 200 ms fade-out
(removes clicks at the cut points), and encode 128 kbps Vorbis into Audio/Music/game/. Originals are untouched.
Then re-run analyze_music.py on the output to confirm the levels.
"""
import os

import aud
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
RAW = os.path.join(HERE, "Music", "raw")
OUT = os.path.join(HERE, "Music", "game")
TARGET_RMS_DB = -18.0
CEIL = 10 ** (-1.0 / 20)
os.makedirs(OUT, exist_ok=True)


def soft_limit(x, ceil):
    """tanh knee above 70% of the ceiling; below that the signal is untouched"""
    knee = 0.7 * ceil
    a = np.abs(x)
    over = a > knee
    y = x.copy()
    y[over] = np.sign(x[over]) * (knee + (ceil - knee) * np.tanh((a[over] - knee) / (ceil - knee)))
    return y


for name in sorted(os.listdir(RAW)):
    src = os.path.join(RAW, name)
    snd = aud.Sound.file(src)
    sr = int(snd.specs[0])
    data = snd.data().astype(np.float64)
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    rms = float(np.sqrt(np.mean(data ** 2))) or 1e-9
    gain = 10 ** (TARGET_RMS_DB / 20) / rms
    y = soft_limit(data * gain, CEIL)
    n = len(y)
    fi, fo = int(0.04 * sr), int(0.2 * sr)
    y[:fi] *= np.linspace(0, 1, fi)[:, None]
    y[-fo:] *= np.linspace(1, 0, fo)[:, None]
    out = os.path.join(OUT, os.path.splitext(name)[0] + ".ogg")
    s = aud.Sound.buffer(y.astype(np.float32), sr)
    s.write(out, sr, 2, aud.FORMAT_FLOAT32, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 128)
    print("%-20s gain %+5.1f dB -> %s (%d bytes)" % (name, 20 * np.log10(gain), os.path.basename(out), os.path.getsize(out)))
