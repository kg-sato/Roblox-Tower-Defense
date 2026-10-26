"""Measures music files with Blender's bundled audio decoder (no ffmpeg or pip needed).

    blender.exe -b --python Audio/analyze_music.py -- <audio files...>      (path to blender in Roblox Dev/Research/Blender Cinematic Pipeline.md)

Prints per file: duration, sample rate, channels, peak dBFS, RMS dBFS (loudness proxy), spectral centroid Hz (brightness),
rough tempo (autocorrelation of the onset envelope), energy variation over time (0 = constant, higher = dynamic/tense), and
loop seam jump (level difference between the last and first 0.5 s: small = loops cleanly). Writes Audio/music_analysis.json.
This cannot hear: it says nothing about melody, mood or taste. Tags come from the source pages, not from this script.
"""
import json
import os
import sys

import aud
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()


def analyze(path):
    snd = aud.Sound.file(path)
    info = snd.specs if hasattr(snd, "specs") else (44100, 2)
    sr = int(info[0])
    data = snd.data()
    if data.ndim == 2:
        mono = data.mean(axis=1)
        ch = data.shape[1]
    else:
        mono, ch = data, 1
    mono = mono.astype(np.float64)
    n = len(mono)
    dur = n / sr
    peak = float(np.max(np.abs(mono))) or 1e-9
    rms = float(np.sqrt(np.mean(mono ** 2))) or 1e-9
    # spectral centroid over 8 evenly spaced 0.5 s windows
    win = int(0.5 * sr)
    cents = []
    for k in range(8):
        s = int((n - win) * k / 7) if n > win else 0
        seg = mono[s:s + win]
        if len(seg) < 1024:
            continue
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
        freqs = np.fft.rfftfreq(len(seg), 1 / sr)
        m = (freqs > 50) & (freqs < 12000)
        cents.append(float((freqs[m] * spec[m]).sum() / max(spec[m].sum(), 1e-9)))
    # energy envelope in 50 ms frames
    hop = int(0.05 * sr)
    frames = n // hop
    env = np.sqrt(np.mean(mono[:frames * hop].reshape(frames, hop) ** 2, axis=1))
    var = float(np.std(env) / (np.mean(env) + 1e-9))
    # tempo: autocorrelation of positive onset flux, lags for 60 to 160 BPM
    flux = np.maximum(np.diff(env), 0)
    flux = flux - flux.mean()
    ac = np.correlate(flux, flux, mode="full")[len(flux) - 1:]
    best, bpm = -1, 0
    for lag in range(int(60 / 160 / 0.05) or 1, int(60 / 60 / 0.05) + 1):
        if lag < len(ac) and ac[lag] > best:
            best, bpm = ac[lag], 60 / (lag * 0.05)
    # loop seam: loudness of the last 0.5 s vs the first 0.5 s
    seam = 20 * np.log10((np.sqrt(np.mean(mono[-win:] ** 2)) + 1e-9) / (np.sqrt(np.mean(mono[:win] ** 2)) + 1e-9))
    return {"dur": round(dur, 2), "sr": sr, "channels": ch, "peak_db": round(20 * np.log10(peak), 1), "rms_db": round(20 * np.log10(rms), 1),
            "centroid_hz": round(float(np.mean(cents))), "tempo_bpm": round(bpm), "energy_variation": round(var, 2), "seam_db": round(float(seam), 1)}


if __name__ == "__main__":
    files = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = {}
    for f in files:
        try:
            r = analyze(f)
        except Exception as e:  # noqa
            r = {"error": str(e)}
        out[os.path.basename(f)] = r
        print(os.path.basename(f), r)
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(files[0])), "..", "music_analysis.json"), "w"), indent=1)
