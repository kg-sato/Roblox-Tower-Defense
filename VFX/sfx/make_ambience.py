"""Ambient loops per stage set and lobby, plus caption and set-morph cues (T166). numpy only (use Hunyuan3D/.venv/Scripts/python.exe).

    Hunyuan3D/.venv/Scripts/python.exe VFX/sfx/make_ambience.py     writes VFX/sfx/out/amb_*.wav, caption_tick.wav, set_morph.wav,
                                                                    checks loop seams, prints the manifest rows to append to MANIFEST.md
Loops are built in the frequency domain and with whole-cycle modulation, so the end meets the start with no click (checked: seam jump vs typical
sample step). Ear quality is UNVERIFIED: nobody listened; only the machine checks below ran.
"""
import os
import wave

import numpy as np

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
LOOP = 24.0
N = int(LOOP * SR)
T = np.arange(N) / SR
rng = np.random.default_rng(166)


def shaped_noise(lo, hi, slope=0.0, seed=0):
    """periodic noise: random phase, magnitude 1 between lo..hi Hz, tilted by f^slope (slope -1 = pink, -2 = brown)"""
    r = np.random.default_rng(seed)
    f = np.fft.rfftfreq(N, 1 / SR)
    mag = np.where((f >= lo) & (f <= hi), np.maximum(f, 20.0) ** slope, 0.0)
    spec = mag * np.exp(1j * r.uniform(0, 2 * np.pi, f.size))
    x = np.fft.irfft(spec, N)
    return x / (np.abs(x).max() + 1e-9)


def lfo(cycles, phase=0.0, depth=1.0, floor=0.0):
    """0..1 wave with an integer number of cycles in the loop (seamless)"""
    return floor + (1 - floor) * (0.5 + 0.5 * depth * np.sin(2 * np.pi * (cycles * T / LOOP + phase)))


def tone(f, g=1.0, cycles_wobble=0, wob=0.0):
    f = round(f * LOOP) / LOOP  # whole cycles per loop
    ph = 2 * np.pi * f * T + (wob * np.sin(2 * np.pi * cycles_wobble * T / LOOP) if cycles_wobble else 0)
    return g * np.sin(ph)


def sparse(rate_hz, seed, decay_ms=6.0, lo=1200, hi=6000):
    """periodic crackle: random clicks (wrapped) shaped by a short decaying filter"""
    r = np.random.default_rng(seed)
    out = np.zeros(N)
    k = int(rate_hz * LOOP)
    for pos, amp in zip(r.integers(0, N, k), r.uniform(0.2, 1.0, k)):
        L = int(decay_ms / 1000 * SR * 6)
        env = np.exp(-np.arange(L) / (decay_ms / 1000 * SR)) * amp * r.choice([-1, 1])
        idx = (pos + np.arange(L)) % N
        out[idx] += env * r.uniform(-1, 1, L)
    spec = np.fft.rfft(out)
    f = np.fft.rfftfreq(N, 1 / SR)
    spec[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(spec, N)


def beds():
    b = {}
    # lane: night wind in a street, a faint low hum, slow gusts
    b["amb_lane"] = 0.9 * shaped_noise(120, 900, -1.0, 1) * lfo(3, 0.1, 0.8, 0.25) + 0.25 * shaped_noise(900, 2200, -1.5, 2) * lfo(5, 0.4, 0.7, 0.1) + 0.12 * tone(55)
    # harbour: slow swells, creaking timber, gull-free
    swell = lfo(3, 0.0, 1.0, 0.1) ** 2
    b["amb_harbour"] = 1.0 * shaped_noise(60, 700, -2.0, 3) * swell + 0.4 * shaped_noise(500, 2500, -1.0, 4) * np.roll(swell, int(0.9 * SR)) * 0.6 + 0.05 * tone(180, 1, 4, 3) * lfo(2, 0.3, 1, 0.0)
    # cathedral: stone room drone with a slow beat, thin air on top
    b["amb_cathedral"] = 0.5 * tone(55) + 0.35 * tone(82.5, 1, 2, 0.4) + 0.25 * tone(110.4) * lfo(2, 0.2, 0.8, 0.3) + 0.2 * shaped_noise(1500, 5000, -1.0, 5) * lfo(4, 0.6, 0.6, 0.2) + 0.25 * shaped_noise(80, 300, -2, 6)
    # foundry: furnace rumble, mains hum with harmonics, a soft tick every half second
    tick = sparse(2.0, 7, 4.0, 400, 3000) * 0.0
    pulse = np.zeros(N)
    for k in range(int(LOOP * 2)):
        p = int(k * 0.5 * SR)
        L = int(0.04 * SR)
        pulse[p:p + L] += np.exp(-np.arange(L) / (0.008 * SR)) * np.sin(2 * np.pi * 520 * np.arange(L) / SR) * (0.8 if k % 4 == 0 else 0.5)
    b["amb_foundry"] = 0.9 * shaped_noise(30, 200, -2.0, 8) * lfo(4, 0.2, 0.5, 0.5) + 0.3 * (tone(60) + 0.5 * tone(120) + 0.25 * tone(180)) + 0.28 * pulse + tick
    # veil: airy shimmer and a soft pad
    b["amb_veil"] = 0.6 * shaped_noise(1500, 5500, -0.5, 9) * lfo(2, 0.3, 0.9, 0.15) + 0.25 * (tone(220.5, 1, 3, 1.5) + 0.8 * tone(330.75, 1, 5, 1.0) + 0.5 * tone(440)) * lfo(1, 0.0, 0.7, 0.4) + 0.3 * shaped_noise(200, 800, -1.5, 10)
    # lobby: warm room tone and a fire's crackle
    b["amb_lobby"] = 0.5 * shaped_noise(60, 500, -2.0, 11) + 0.18 * (tone(98.1) + 0.6 * tone(147.2)) * lfo(2, 0.0, 0.5, 0.5) + 0.55 * sparse(7, 12) + 0.1 * shaped_noise(900, 2500, -1.0, 13)
    return b


def write(name, x, peak=0.5):
    x = x / (np.abs(x).max() + 1e-9) * peak
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return pcm.astype(float) / 32767


def cues():
    t = np.arange(int(0.35 * SR)) / SR
    tick = np.exp(-t / 0.05) * (np.sin(2 * np.pi * 1760 * t) * 0.6 + np.sin(2 * np.pi * 2637 * t) * 0.3) + 0.25 * np.exp(-t / 0.006) * np.random.default_rng(1).uniform(-1, 1, t.size)
    t2 = np.arange(int(2.4 * SR)) / SR
    env = np.sin(np.pi * np.clip(t2 / 2.4, 0, 1)) ** 2
    nz = np.random.default_rng(2).uniform(-1, 1, t2.size)
    spec = np.fft.rfft(nz)
    f = np.fft.rfftfreq(t2.size, 1 / SR)
    spec *= (f > 200) & (f < 3000)
    air = np.fft.irfft(spec, t2.size)
    sweep = np.sin(2 * np.pi * np.cumsum(180 - 100 * t2 / 2.4) / SR)
    morph = env * (0.6 * air / np.abs(air).max() + 0.5 * sweep)
    return {"caption_tick": tick, "set_morph": morph}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    rows = []
    for name, x in beds().items():
        pcm = write(name, x, 0.5)
        seam = abs(pcm[0] - pcm[-1])
        step = np.abs(np.diff(pcm)).mean()
        rms = 20 * np.log10(np.sqrt((pcm ** 2).mean()))
        ok = seam <= 6 * step + 0.01
        print(f"{name:14s} {LOOP:.2f}s peak {20 * np.log10(np.abs(pcm).max()):.1f} dBFS rms {rms:.1f} seam {seam:.4f} (mean step {step:.4f}) {'PASS' if ok else 'FAIL'}")
        rows.append(f"| {name} | {LOOP:.2f} | looping ambience bed | {20 * np.log10(np.abs(pcm).max()):.1f} | {rms:.1f} | {rms:.1f} |")
    for name, x in cues().items():
        pcm = write(name, x, 0.5)
        L = len(pcm) / SR
        print(f"{name:14s} {L:.2f}s")
        rows.append(f"| {name} | {L:.2f} | one-shot cue | {20 * np.log10(np.abs(pcm).max()):.1f} | {20 * np.log10(np.sqrt((pcm ** 2).mean())):.1f} | {20 * np.log10(np.sqrt((pcm ** 2).mean())):.1f} |")
    print("\n".join(rows))
