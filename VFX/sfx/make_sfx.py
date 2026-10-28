"""Procedural sound effects for the VFX modules. Pure Python (stdlib only), original synthesis: no samples, no downloads.

    python VFX/sfx/make_sfx.py            write WAVs to VFX/sfx/out/ and copy to Studio's local content/sounds/vfx/
    python VFX/sfx/make_sfx.py --remove   delete the installed folder
    python VFX/sfx/make_sfx.py --only lampwick   only the Lampwick Lane game sounds (or a comma list of names)

16-bit mono 44.1 kHz, peak normalised to about -3 dBFS, 5 ms fade in and out so nothing clicks. Loaded in Studio from
rbxasset://sounds/vfx/<name>.wav (dev preview only; a published game needs these uploaded: owner's OK).
Verify with python VFX/sfx/analyze_sfx.py (levels, clipping, clicks, duration, attack, spectral centroid).
"""
import glob
import math
import os
import random
import shutil
import struct
import sys
import wave

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
TAU = math.tau


def n_of(dur):
    return int(dur * SR)


def zeros(dur):
    return [0.0] * n_of(dur)


def sine(freq, dur, amp=1.0, phase=0.0, sweep_to=None, curve=1.0):
    n = n_of(dur)
    out = [0.0] * n
    ph = phase
    for i in range(n):
        f = freq if sweep_to is None else freq + (sweep_to - freq) * (i / n) ** curve
        ph += TAU * f / SR
        out[i] = math.sin(ph) * amp
    return out


def noise(dur, seed=1, amp=1.0):
    r = random.Random(seed)
    return [(r.random() * 2 - 1) * amp for _ in range(n_of(dur))]


class Biquad:
    def __init__(self, kind, freq, q=0.707):
        w = TAU * freq / SR
        a = math.sin(w) / (2 * q)
        c = math.cos(w)
        if kind == "lp":
            b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
        elif kind == "hp":
            b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
        else:  # bp (constant 0 dB peak)
            b0, b1, b2 = a, 0, -a
        a0 = 1 + a
        self.b = (b0 / a0, b1 / a0, b2 / a0)
        self.a = (-2 * c / a0, (1 - a) / a0)
        self.z1 = self.z2 = 0.0

    def run(self, x):
        b0, b1, b2 = self.b
        a1, a2 = self.a
        z1, z2 = self.z1, self.z2
        y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        self.z1, self.z2 = z1, z2
        return y


def filt(sig, kind, freq, q=0.707):
    f = Biquad(kind, freq, q)
    return [f.run(x) for x in sig]


def swept_bp(sig, f0, f1, q=2.0, curve=1.0, block=64):
    """band-pass whose centre frequency sweeps f0 -> f1 (recomputed every `block` samples)"""
    n = len(sig)
    out = [0.0] * n
    f = None
    for s in range(0, n, block):
        fc = f0 + (f1 - f0) * (s / n) ** curve
        keep = (f.z1, f.z2) if f else (0.0, 0.0)
        f = Biquad("bp", max(40.0, fc), q)
        f.z1, f.z2 = keep
        for i in range(s, min(n, s + block)):
            out[i] = f.run(sig[i])
    return out


def env_exp(dur, decay, attack=0.002):
    n = n_of(dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        a = min(1.0, t / attack) if attack > 0 else 1.0
        out[i] = a * math.exp(-t * decay)
    return out


def env_curve(dur, points):
    """piecewise-linear envelope; points = [(time_s, level), ...]"""
    n = n_of(dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        lvl = points[-1][1]
        for k in range(len(points) - 1):
            t0, a0 = points[k]
            t1, a1 = points[k + 1]
            if t0 <= t <= t1:
                lvl = a0 + (a1 - a0) * ((t - t0) / (t1 - t0) if t1 > t0 else 1)
                break
        else:
            if t < points[0][0]:
                lvl = points[0][1]
        out[i] = lvl
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def mix(*sigs, gains=None):
    n = max(len(s) for s in sigs)
    out = [0.0] * n
    for k, s in enumerate(sigs):
        g = gains[k] if gains else 1.0
        for i, v in enumerate(s):
            out[i] += v * g
    return out


def place(sig, at, total):
    out = [0.0] * n_of(total)
    o = n_of(at)
    for i, v in enumerate(sig):
        if o + i < len(out):
            out[o + i] = v
    return out


def reverb(sig, wet=0.25, tail=1.2, size=1.0):
    """small Schroeder reverb: 4 combs + 2 all-passes, extends the signal by `tail` seconds"""
    n = len(sig) + n_of(tail)
    x = sig + [0.0] * (n - len(sig))
    out = [0.0] * n
    for d_ms, fb in ((29.7, 0.80), (37.1, 0.78), (41.1, 0.76), (43.7, 0.74)):
        d = int(SR * d_ms * size / 1000)
        buf = [0.0] * d
        idx = 0
        for i in range(n):
            y = buf[idx]
            buf[idx] = x[i] + y * fb
            idx += 1
            if idx == d:
                idx = 0
            out[i] += y * 0.25
    for d_ms, g in ((5.0, 0.7), (1.7, 0.7)):
        d = int(SR * d_ms / 1000)
        buf = [0.0] * d
        idx = 0
        for i in range(n):
            y = buf[idx]
            v = out[i] + y * g
            buf[idx] = v
            out[i] = y - v * g
            idx += 1
            if idx == d:
                idx = 0
    return [x[i] * (1 - wet) + out[i] * wet * 2.2 for i in range(n)]


def vibrato_sine(freq, dur, amp=1.0, rate=5.0, depth=0.01):
    n = n_of(dur)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        f = freq * (1 + depth * math.sin(TAU * rate * i / SR))
        ph += TAU * f / SR
        out[i] = math.sin(ph) * amp
    return out


def finish(sig, name, peak=0.7, trim_to=None):
    """fade 5 ms in and 30 ms out, normalise, write 16-bit WAV"""
    n = len(sig)
    f = int(0.005 * SR)
    for i in range(min(f, n)):
        sig[i] *= i / f
    f = int(0.03 * SR)
    for i in range(min(f, n)):
        sig[n - 1 - i] *= i / f
    m = max(abs(v) for v in sig) or 1.0
    k = peak / m
    data = b"".join(struct.pack("<h", max(-32767, min(32767, int(v * k * 32767)))) for v in sig)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print("%-18s %.2fs" % (name, n / SR))


def finish_rms(sig, name, rms_db, ceiling=0.85):
    """fade, scale to a target RMS (dBFS), soft-limit above `ceiling`, write. Used where loudness must escalate."""
    n = len(sig)
    f = int(0.005 * SR)
    for i in range(min(f, n)):
        sig[i] *= i / f
    f = int(0.03 * SR)
    for i in range(min(f, n)):
        sig[n - 1 - i] *= i / f
    rms = math.sqrt(sum(v * v for v in sig) / n) or 1.0
    k = (10 ** (rms_db / 20)) / rms
    knee = 0.7 * ceiling
    out = []
    for v in sig:
        v *= k
        a = abs(v)
        if a > knee:
            v = math.copysign(knee + (ceiling - knee) * math.tanh((a - knee) / (ceiling - knee)), v)
        out.append(v)
    data = b"".join(struct.pack("<h", max(-32767, min(32767, int(v * 32767)))) for v in out)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print("%-18s %.2fs" % (name, n / SR))


# ---- the sounds ---------------------------------------------------------------------------------------------------------
def ui_click():
    s = mix(mul(sine(1800, 0.09), env_exp(0.09, 55)), mul(filt(noise(0.09, 3), "hp", 4000), env_exp(0.09, 140)), gains=[0.8, 0.25])
    finish(s, "ui_click", 0.6)


def combo():
    e = env_exp(0.4, 9, 0.003)
    s = mix(mul(sine(880, 0.4, sweep_to=990), e), mul(sine(1320, 0.4, sweep_to=1485), e), mul(sine(2640, 0.4), env_exp(0.4, 18)), gains=[0.6, 0.45, 0.18])
    finish(reverb(s, 0.18, 0.4), "combo", 0.62)


def ring():
    n = noise(0.55, 5)
    sw = swept_bp(n, 400, 2000, 1.4)
    hump = env_curve(0.55, [(0, 0), (0.18, 1), (0.55, 0)])
    s = mix(mul(sw, hump), mul(sine(600, 0.55, sweep_to=900), env_exp(0.55, 6)), gains=[0.9, 0.25])
    finish(s, "ring", 0.55)


def milestone():
    notes = [523.25, 659.25, 783.99, 1046.5]
    parts = []
    for k, f in enumerate(notes):
        t = mix(mul(sine(f, 1.0), env_exp(1.0, 4.5)), mul(sine(f * 2, 1.0), env_exp(1.0, 8)), gains=[1.0, 0.25])
        parts.append(place(t, k * 0.09, 1.3))
    pad = mul(sine(261.6, 1.3), env_curve(1.3, [(0, 0), (0.25, 0.4), (1.3, 0)]))
    s = mix(*parts, pad, gains=[0.6, 0.6, 0.6, 0.75, 0.25])
    finish(reverb(s, 0.25, 0.8), "milestone", 0.65)


def spotlight():
    e = env_exp(0.45, 8, 0.002)
    s = mix(mul(sine(660, 0.45), e), mul(sine(1320, 0.45), env_exp(0.45, 14)), mul(sine(1980, 0.45), env_exp(0.45, 22)), gains=[0.7, 0.3, 0.12])
    finish(s, "spotlight", 0.5)


def menu_open():
    sw = swept_bp(noise(0.5, 7), 220, 1300, 2.0)
    s = mix(mul(sw, env_curve(0.5, [(0, 0), (0.2, 1), (0.5, 0)])), mul(sine(500, 0.5, sweep_to=900, curve=1.5), env_curve(0.5, [(0, 0), (0.15, 0.6), (0.5, 0)])), gains=[0.8, 0.3])
    finish(s, "menu_open", 0.5)


def menu_close():
    sw = swept_bp(noise(0.45, 8), 1300, 220, 2.0)
    s = mix(mul(sw, env_curve(0.45, [(0, 0), (0.1, 1), (0.45, 0)])), mul(sine(900, 0.45, sweep_to=450), env_curve(0.45, [(0, 0), (0.08, 0.6), (0.45, 0)])), gains=[0.8, 0.28])
    finish(s, "menu_close", 0.5)


def discovery():
    dur = 1.7
    stack = mix(*[mul(vibrato_sine(f, dur, 1.0, 4.5 + i, 0.004), env_curve(dur, [(0, 0), (0.5, 1), (dur, 0)])) for i, f in enumerate([523.25, 659.25, 784, 1046.5, 1318.5])], gains=[0.5, 0.45, 0.4, 0.3, 0.2])
    air = mul(filt(noise(dur, 9), "hp", 5000), env_curve(dur, [(0, 0), (0.6, 0.12), (dur, 0)]))
    finish(reverb(mix(stack, air, gains=[1.0, 0.5]), 0.3, 0.9), "discovery", 0.6)


def load_start():
    dur = 0.9
    s = mix(mul(sine(220, dur), env_curve(dur, [(0, 0), (0.4, 0.7), (dur, 0)])), mul(sine(330, dur), env_curve(dur, [(0, 0), (0.45, 0.4), (dur, 0)])), gains=[0.7, 0.4])
    finish(reverb(s, 0.2, 0.6), "load_start", 0.4)


def load_synced():
    a = mul(sine(659.25, 0.9), env_exp(0.9, 5))
    b = place(mul(sine(987.77, 0.9), env_exp(0.9, 4.5)), 0.12, 1.1)
    s = mix(place(a, 0, 1.1), b, mul(sine(1319, 1.1), env_exp(1.1, 9)), gains=[0.8, 0.7, 0.15])
    finish(reverb(s, 0.3, 0.9), "load_synced", 0.55)


def load_resolve():
    dur = 1.15
    sw = filt(swept_bp(noise(dur, 10), 2200, 300, 2.2, 1.3), "lp", 2200)
    s = mix(mul(sw, env_curve(dur, [(0, 0), (0.25, 1), (dur, 0)])), mul(sine(880, dur, sweep_to=330), env_curve(dur, [(0, 0), (0.2, 0.5), (dur, 0)])), gains=[0.9, 0.22])
    finish(reverb(s, 0.2, 0.5), "load_resolve", 0.5)


def common():
    pop = mul(sine(520, 0.25, sweep_to=240, curve=0.5), env_exp(0.25, 22))
    ping = mul(sine(2000, 0.5), env_exp(0.5, 9))
    finish(reverb(mix(place(pop, 0, 0.55), place(ping, 0.03, 0.55), gains=[0.8, 0.3]), 0.15, 0.3), "common", 0.55)


def rare():
    parts = []
    for k, f in enumerate([783.99, 1174.66, 1567.98]):
        parts.append(place(mix(mul(sine(f, 0.9), env_exp(0.9, 5)), mul(sine(f * 2, 0.9), env_exp(0.9, 10)), gains=[1, 0.2]), k * 0.12, 1.2))
    sw = place(mul(swept_bp(noise(0.5, 11), 500, 3500, 1.3), env_curve(0.5, [(0, 0), (0.3, 1), (0.5, 0)])), 0, 1.2)
    finish(reverb(mix(*parts, sw, gains=[0.7, 0.7, 0.7, 0.35]), 0.25, 0.7), "rare", 0.6)


def epic():
    dur = 2.4
    swell = mix(*[mul(vibrato_sine(f, dur, 1.0, 5, 0.005), env_curve(dur, [(0, 0), (1.4, 0.8), (1.5, 1.0), (dur, 0)])) for f in (220, 330.0, 440, 554.4)], gains=[0.5, 0.4, 0.35, 0.25])
    riser = mul(swept_bp(noise(dur, 12), 300, 3200, 1.4, 1.6), env_curve(dur, [(0, 0), (1.4, 0.8), (1.5, 0.1), (dur, 0)]))
    hit = place(mix(mul(sine(110, 1.0, sweep_to=70), env_exp(1.0, 5)), mul(sine(1760, 0.9), env_exp(0.9, 6)), gains=[0.9, 0.2]), 1.45, dur)
    finish(reverb(mix(swell, riser, hit, gains=[0.5, 0.5, 0.9]), 0.3, 1.0), "epic", 0.7)


def anticipation():
    dur = 4.0
    drone = mix(mul(vibrato_sine(55, dur, 1, 0.3, 0.004), env_curve(dur, [(0, 0), (3.2, 0.9), (dur, 0)])), mul(vibrato_sine(110, dur, 1, 0.5, 0.005), env_curve(dur, [(0, 0), (3.0, 0.5), (dur, 0)])), gains=[0.9, 0.5])
    thin = mul(sine(400, dur, sweep_to=1500, curve=2.2), env_curve(dur, [(0, 0), (1.5, 0.05), (3.6, 0.35), (dur, 0.25)]))
    trem = [1.0 - 0.25 * (0.5 + 0.5 * math.sin(TAU * (3 + 4 * (i / n_of(dur))) * i / SR)) for i in range(n_of(dur))]
    finish(mul(mix(drone, thin, gains=[1.0, 0.4]), trem), "anticipation", 0.5)


def legendary_gather():
    dur = 1.5
    riser = mul(swept_bp(noise(dur, 13), 250, 4200, 1.3, 1.8), env_curve(dur, [(0, 0), (dur, 1)]))
    tone = mul(sine(200, dur, sweep_to=900, curve=2.0), env_curve(dur, [(0, 0), (dur, 0.8)]))
    finish(mix(riser, tone, gains=[0.8, 0.4]), "legendary_gather", 0.6)


def legendary_burst():
    dur = 3.2
    thump = mul(sine(140, 0.9, sweep_to=45, curve=0.4), env_exp(0.9, 3.6, 0.001))
    body = mul(filt(noise(0.6, 14), "lp", 900), env_exp(0.6, 6))
    crack = mul(filt(noise(0.12, 15), "hp", 3000), env_exp(0.12, 40))
    shimmer = mix(*[mul(sine(f, 2.4), env_exp(2.4, 2.2 + i * 0.4)) for i, f in enumerate([1318.5, 1760, 2093, 2637, 3520])], gains=[0.3, 0.25, 0.22, 0.16, 0.1])
    s = mix(place(thump, 0, dur), place(body, 0, dur), place(crack, 0, dur), place(shimmer, 0.03, dur), gains=[1.0, 0.7, 0.35, 0.55])
    finish(reverb(s, 0.3, 1.4), "legendary_burst", 0.75)


def ink():
    dur = 2.5
    splash = mul(swept_bp(noise(0.45, 16), 1200, 600, 0.9), env_exp(0.45, 9))
    plop = mul(sine(190, 0.35, sweep_to=85, curve=0.6), env_exp(0.35, 11))
    runes = [place(mix(mul(sine(f, 1.4), env_exp(1.4, 3.5)), mul(sine(f * 2, 1.4), env_exp(1.4, 7)), gains=[1, 0.2]), 0.5 + k * 0.22, dur) for k, f in enumerate([1318.5, 1568, 1975.5])]
    finish(reverb(mix(place(splash, 0, dur), place(plop, 0, dur), *runes, gains=[0.7, 0.7, 0.4, 0.4, 0.4]), 0.28, 1.0), "ink", 0.62)


def vortex():
    dur = 2.7
    sw1 = swept_bp(noise(dur, 17), 500, 3200, 1.6, 1.0)
    swirl = mul(sw1, [0.55 + 0.45 * math.sin(TAU * (1.5 + 3.5 * i / n_of(dur)) * i / SR) ** 2 for i in range(n_of(dur))])
    swirl = mul(swirl, env_curve(dur, [(0, 0), (1.9, 1), (2.0, 0.5), (dur, 0)]))
    rise = mul(sine(300, dur, sweep_to=1100, curve=1.4), env_curve(dur, [(0, 0), (1.9, 0.7), (2.0, 0), (dur, 0)]))
    gold = place(mix(mul(sine(1046.5, 0.8), env_exp(0.8, 4)), mul(sine(1568, 0.8), env_exp(0.8, 5)), mul(sine(2093, 0.8), env_exp(0.8, 6)), gains=[1, 0.6, 0.3]), 1.95, dur)
    finish(reverb(mix(swirl, rise, gold, gains=[0.7, 0.4, 0.8]), 0.25, 1.0), "vortex", 0.62)


def ultimate_summon():
    dur = 2.5
    d = mix(*[mul(vibrato_sine(f, dur, 1, 4.0 + k * 0.6, 0.006), env_curve(dur, [(0, 0), (1.9, 0.9), (dur, 0.3)])) for k, f in enumerate((55, 82.4, 110, 164.8, 220))], gains=[0.7, 0.55, 0.5, 0.35, 0.25])
    air = mul(filt(noise(dur, 18), "hp", 2500), env_curve(dur, [(0, 0), (1.9, 0.18), (dur, 0.05)]))
    finish(reverb(mix(d, air, gains=[1, 0.08]), 0.25, 1.0), "ultimate_summon", 0.6)


def ultimate_sword():
    dur = 1.7
    partials = [1, 2.76, 5.4, 8.93]
    m = mix(*[mul(sine(880 * r, dur), env_exp(dur, 2.8 + k * 1.3, 0.04)) for k, r in enumerate(partials)], gains=[0.6, 0.4, 0.25, 0.15])
    sp = mul(filt(noise(dur, 19), "hp", 6000), env_curve(dur, [(0, 0), (0.3, 0.2), (dur, 0)]))
    finish(reverb(mix(m, sp, gains=[1, 0.4]), 0.3, 0.8), "ultimate_sword", 0.5)


def ultimate_fall():
    dur = 0.6
    sw = mul(filt(swept_bp(noise(dur, 20), 2400, 260, 3.5, 0.8), 'lp', 1800), env_curve(dur, [(0, 0.1), (dur, 1)]))
    fall = mul(sine(700, dur, sweep_to=90, curve=0.7), env_curve(dur, [(0, 0.1), (dur, 0.9)]))
    finish(mix(sw, fall, gains=[0.8, 0.45]), "ultimate_fall", 0.6)


def ultimate_impact():
    dur = 3.6
    boom = mul(sine(120, 1.4, sweep_to=34, curve=0.35), env_exp(1.4, 2.4, 0.001))
    punch = mul(sine(70, 0.8, sweep_to=40, curve=0.5), env_exp(0.8, 3.0, 0.001))
    body = mul(filt(noise(1.4, 21), "lp", 260), env_exp(1.4, 2.6, 0.001))
    crack = mul(filt(noise(0.1, 22), "hp", 2500), env_exp(0.1, 45))
    metal = mix(*[mul(sine(330 * r, 2.4), env_exp(2.4, 2.2 + k)) for k, r in enumerate([1, 2.76, 5.4])], gains=[0.3, 0.16, 0.08])
    s = mix(place(boom, 0, dur), place(punch, 0, dur), place(body, 0, dur), place(crack, 0, dur), place(metal, 0.02, dur), gains=[1.0, 0.8, 1.0, 0.1, 0.18])
    finish(filt(reverb(s, 0.22, 1.8, 1.3), "lp", 2600), "ultimate_impact", 0.85)


# ---- merge game cues: the merge ladder escalates with every tier (pitch, layers, length, weight) ----------------------------
NOTES = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51]  # C major pentatonic, C5 to E6
LADDER_DUR = [0.55, 0.6, 0.8, 1.0, 1.3, 1.7, 2.2, 3.6]
LADDER_RMS = [-26.0, -25.0, -24.0, -23.0, -21.8, -20.6, -19.4, -18.0]


def merge_tier(k):
    f = NOTES[k - 1]
    dur = LADDER_DUR[k - 1]
    layers = []
    gains = []
    # pluck with a click transient: every tier has this
    pluck = mix(mul(sine(f, dur), env_exp(dur, 7 - k * 0.45, 0.002)), mul(sine(f * 2, dur), env_exp(dur, 11 - k * 0.5)), mul(sine(f * 3, dur), env_exp(dur, 16)), gains=[1.0, 0.3, 0.1])
    click = mul(filt(noise(0.012, 30 + k), "hp", 3500), env_exp(0.012, 200))
    layers += [pluck, place(click, 0, dur)]
    gains += [1.0, 0.25]
    if k >= 3:  # a fifth above, a touch later: the chord opens
        layers.append(place(mul(sine(f * 1.5, dur), env_exp(dur, 6 - k * 0.3)), 0.045, dur))
        gains.append(0.5)
    if k >= 4:  # shimmer tail
        layers.append(mix(*[mul(sine(f * m, dur), env_exp(dur, 3.0 + i)) for i, m in enumerate((2, 3, 4))], gains=[0.4, 0.25, 0.15]))
        gains.append(0.6)
    if k >= 5:  # weight: a sub-bass thump that grows with the tier
        layers.append(mix(mul(sine(110, dur, sweep_to=45, curve=0.45), env_exp(dur, 3.2, 0.002)), mul(filt(noise(dur, 60 + k), "lp", 220), env_exp(dur, 4.5)), gains=[1.0, 0.5]))
        gains.append(1.2 + 0.35 * (k - 5))
    if k >= 6:  # a pad swells in under the pluck
        layers.append(mix(mul(vibrato_sine(f * 0.5, dur, 1, 4.5, 0.005), env_curve(dur, [(0, 0), (0.35, 0.9), (dur, 0)])), mul(vibrato_sine(f * 0.75, dur, 1, 5.1, 0.005), env_curve(dur, [(0, 0), (0.4, 0.7), (dur, 0)])), gains=[0.7, 0.5]))
        gains.append(0.55)
    if k >= 7:  # bell stack
        layers.append(mix(*[mul(sine(f * r, dur), env_exp(dur, 2.2 + i * 0.8)) for i, r in enumerate((1.0, 2.76, 5.4))], gains=[0.5, 0.3, 0.15]))
        gains.append(0.5)
    if k == 8:  # the ascension: riser first, then a big hit with a choir
        total = dur + 0.5
        riser = mul(swept_bp(noise(0.5, 40), 400, 4200, 1.4, 1.5), env_curve(0.5, [(0, 0), (0.48, 1.0), (0.5, 0.0)]))
        choir = mix(*[mul(vibrato_sine(fr, 2.6, 1, 4.0 + i * 0.5, 0.006), env_curve(2.6, [(0, 0), (0.3, 1), (2.6, 0)])) for i, fr in enumerate((220, 330, 440, 554.4, 660))], gains=[0.6, 0.5, 0.45, 0.3, 0.25])
        hit = mul(sine(70, 1.0, sweep_to=30, curve=0.4), env_exp(1.0, 3.2, 0.001))
        shell = [place(l, 0.5, total) for l in layers]
        layers = shell + [place(riser, 0, total), place(choir, 0.5, total), place(hit, 0.5, total)]
        gains = [g for g in gains] + [0.6, 0.55, 0.9]
        dur = total
    wet = 0.12 + 0.02 * k
    finish_rms(reverb(mix(*layers, gains=gains), wet, 0.3 + 0.1 * k), "merge_%d" % k, LADDER_RMS[k - 1])


def summon():
    pop = mul(sine(700, 0.2, sweep_to=300, curve=0.4), env_exp(0.2, 24))
    sp = mul(swept_bp(noise(0.25, 50), 1200, 4000, 1.6), env_curve(0.25, [(0, 0), (0.05, 1), (0.25, 0)]))
    finish(reverb(mix(place(pop, 0, 0.3), place(sp, 0, 0.3), gains=[0.8, 0.45]), 0.12, 0.25), "summon", 0.5)


def surge():
    dur = 1.2
    up = mul(sine(500, dur, sweep_to=2400, curve=1.3), env_curve(dur, [(0, 0), (0.1, 0.8), (0.7, 0.6), (dur, 0)]))
    glit = mix(*[place(mul(sine(1800 + 330 * i, 0.5), env_exp(0.5, 8)), 0.08 * i, dur) for i in range(6)], gains=[0.4] * 6)
    air = mul(swept_bp(noise(dur, 51), 800, 5000, 1.3), env_curve(dur, [(0, 0), (0.3, 0.8), (dur, 0)]))
    finish(reverb(mix(up, glit, air, gains=[0.5, 0.7, 0.4]), 0.25, 0.6), "surge", 0.7)


def echo():
    a = mul(sine(1568, 0.4), env_exp(0.4, 12))
    b = place(mul(sine(1568, 0.4), env_exp(0.4, 14)), 0.11, 0.55)
    finish(reverb(mix(place(a, 0, 0.55), b, gains=[0.8, 0.45]), 0.2, 0.3), "echo", 0.45)


def bank():
    parts = [place(mix(mul(sine(2093 + 140 * i, 0.3), env_exp(0.3, 20)), mul(sine(3140 + 210 * i, 0.3), env_exp(0.3, 30)), gains=[1, 0.4]), 0.05 * i, 0.5) for i in range(4)]
    finish(reverb(mix(*parts, gains=[0.5, 0.5, 0.5, 0.5]), 0.15, 0.3), "bank", 0.45)


def charge_ready():
    a = mul(sine(1046.5, 0.4), env_exp(0.4, 9))
    b = place(mul(sine(1568, 0.4), env_exp(0.4, 9)), 0.1, 0.55)
    finish(reverb(mix(place(a, 0, 0.55), b, gains=[0.7, 0.7]), 0.2, 0.4), "charge_ready", 0.42)


def merge_fail():
    thud = mul(sine(150, 0.25, sweep_to=75, curve=0.5), env_exp(0.25, 16, 0.002))
    buzz = mul(filt(noise(0.18, 52), "lp", 700), env_exp(0.18, 22))
    finish(mix(place(thud, 0, 0.3), place(buzz, 0, 0.3), gains=[0.9, 0.35]), "merge_fail", 0.5)


def wish_pull():
    dur = 1.5
    ris = mul(swept_bp(noise(dur, 53), 250, 4500, 1.5, 1.7), env_curve(dur, [(0, 0), (dur, 1)]))
    tone = mul(sine(180, dur, sweep_to=1400, curve=2.2), env_curve(dur, [(0, 0), (dur, 0.7)]))
    beats = mix(*[place(mul(sine(60, 0.18, sweep_to=45), env_exp(0.18, 18, 0.002)), 0.15 * i + (0.0 if i < 6 else 0), dur) for i in range(10) if 0.15 * i < dur - 0.2], gains=[0.5] * 10)
    finish(mix(ris, tone, beats, gains=[0.7, 0.35, 0.6]), "wish_pull", 0.65)



# ---- Lampwick Lane game sounds (2026-10-28): the game itself was nearly silent between cutscenes ------------------------
def brass_click():
    """a brass control pressed: two inharmonic metal partials and a small low tick"""
    d = 0.14
    s = mix(mul(sine(2380, d), env_exp(d, 38)), mul(sine(3910, d), env_exp(d, 55)), mul(sine(320, d, sweep_to=220), env_exp(d, 60, 0.001)),
            mul(filt(noise(d, 61), "hp", 5000), env_exp(d, 160)), gains=[0.5, 0.3, 0.6, 0.25])
    finish(s, "brass_click", 0.55)


def card_flip():
    """a tarot card snapped off the deck: two quick paper flicks"""
    d = 0.2
    a = mul(swept_bp(noise(0.09, 62), 1800, 6500, 1.8), env_curve(0.09, [(0, 0), (0.015, 1), (0.09, 0)]))
    b = mul(swept_bp(noise(0.08, 63), 2500, 5000, 1.8), env_curve(0.08, [(0, 0), (0.01, 0.7), (0.08, 0)]))
    finish(mix(place(a, 0, d), place(b, 0.07, d), gains=[1, 0.7]), "card_flip", 0.55)


def bell_toll():
    """a deep street bell: minor-third bell partials with long decays and a strike"""
    d = 2.6
    f = 196.0
    parts = [(0.5, 1.4, 0.5), (1.0, 1.8, 0.8), (1.19, 2.4, 0.45), (1.5, 2.8, 0.35), (2.0, 3.2, 0.4), (2.52, 4.5, 0.2), (3.0, 5.5, 0.15), (4.07, 7, 0.1)]
    tones = [mul(vibrato_sine(f * r, d, 1, 1.3 + i * 0.4, 0.0015), env_exp(d, dec, 0.002)) for i, (r, dec, g) in enumerate(parts)]
    strike = mul(filt(noise(0.06, 64), "bp", 1500, 1.2), env_exp(0.06, 60))
    s = mix(*tones, place(strike, 0, d), gains=[g for (_, _, g) in parts] + [0.5])
    finish(reverb(s, 0.3, 1.0), "bell_toll", 0.7)


def coin_clink():
    """coins dropped in a purse: two bright pings"""
    d = 0.3
    a = mix(mul(sine(3150, d), env_exp(d, 28)), mul(sine(4730, d), env_exp(d, 40)), gains=[0.6, 0.35])
    b = mix(mul(sine(3480, d), env_exp(d, 30)), mul(sine(5210, d), env_exp(d, 45)), gains=[0.5, 0.3])
    finish(reverb(mix(place(a, 0, 0.36), place(b, 0.045, 0.36), gains=[1, 0.8]), 0.1, 0.2), "coin_clink", 0.5)


def enemy_hit():
    """a soft body hit: low thud and a puff of noise"""
    d = 0.16
    thud = mul(sine(190, d, sweep_to=85, curve=0.5), env_exp(d, 22, 0.001))
    puff = mul(filt(noise(d, 65), "lp", 1400), env_exp(d, 35))
    finish(mix(thud, puff, gains=[0.85, 0.4]), "enemy_hit", 0.5)


def enemy_poof():
    """an enemy dissolving into lamp smoke: a downward whoosh with a small pop"""
    d = 0.42
    whoosh = mul(swept_bp(noise(d, 66), 3200, 500, 1.5, 0.7), env_curve(d, [(0, 0), (0.05, 1), (d, 0)]))
    pop = mul(sine(520, 0.12, sweep_to=980, curve=0.6), env_exp(0.12, 30))
    finish(reverb(mix(whoosh, place(pop, 0, d), gains=[0.8, 0.45]), 0.15, 0.3), "enemy_poof", 0.5)


def glass_crack():
    """the crystal cracking: a crackle of tiny clicks, a high ring and a thud"""
    d = 0.6
    r = random.Random(67)
    crack = zeros(d)
    for _ in range(26):
        t = r.random() ** 1.7 * 0.28
        i0 = int(t * SR)
        for j in range(int(0.003 * SR)):
            if i0 + j < len(crack):
                crack[i0 + j] += (r.random() * 2 - 1) * math.exp(-j / 30) * (0.5 + r.random() * 0.5)
    crack = filt(crack, "hp", 2500)
    ring_ = mix(mul(sine(5200, d), env_exp(d, 9)), mul(sine(7900, d), env_exp(d, 14)), gains=[0.4, 0.2])
    thud = mul(sine(120, 0.25, sweep_to=60), env_exp(0.25, 18, 0.001))
    finish(reverb(mix(crack, ring_, place(thud, 0, d), gains=[1, 0.5, 0.7]), 0.15, 0.3), "glass_crack", 0.6)


def clock_tick():
    """a pocket-watch tick (play at pitch 0.8 for the tock)"""
    d = 0.08
    s = mix(mul(filt(noise(d, 68), "bp", 3200, 3), env_exp(d, 120)), mul(sine(1250, d), env_exp(d, 90)), gains=[1, 0.5])
    finish(s, "clock_tick", 0.5)


def place_thud():
    """a familiar set down on the cobbles: a wooden knock"""
    d = 0.2
    s = mix(mul(sine(210, d, sweep_to=170), env_exp(d, 28, 0.001)), mul(sine(445, d), env_exp(d, 45)), mul(filt(noise(d, 69), "lp", 900), env_exp(d, 50)), gains=[0.7, 0.35, 0.4])
    finish(s, "place_thud", 0.5)


def iron_clank():
    """an iron sign swinging into place on its chains (the boss plate)"""
    d = 0.8
    parts = [(310, 6), (847, 9), (1432, 12), (2213, 16), (3050, 22)]
    s = mix(*[mul(sine(f, d), env_exp(d, dec, 0.001)) for f, dec in parts], mul(filt(noise(0.1, 70), "bp", 2000, 1.0), env_exp(0.1, 40)), gains=[0.6, 0.45, 0.35, 0.25, 0.15, 0.5])
    rattle = mix(*[place(mul(filt(noise(0.04, 71 + i), "bp", 2600 + 300 * i, 2), env_exp(0.04, 70)), 0.12 + 0.07 * i, d) for i in range(4)], gains=[0.3] * 4)
    finish(reverb(mix(s, rattle, gains=[1, 1]), 0.2, 0.5), "iron_clank", 0.6)


LAMPWICK = [brass_click, card_flip, bell_toll, coin_clink, enemy_hit, enemy_poof, glass_crack, clock_tick, place_thud, iron_clank]

MERGE_GAME = [lambda k=k: merge_tier(k) for k in range(1, 9)] + [summon, surge, echo, bank, charge_ready, merge_fail, wish_pull]

ALL = [ui_click, combo, ring, milestone, spotlight, menu_open, menu_close, discovery, load_start, load_synced, load_resolve, common, rare, epic,
       anticipation, legendary_gather, legendary_burst, ink, vortex, ultimate_summon, ultimate_sword, ultimate_fall, ultimate_impact]

if __name__ == "__main__":
    versions = os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "Versions")
    targets = [os.path.join(os.path.dirname(e), "content", "sounds", "vfx") for e in glob.glob(os.path.join(versions, "version-*", "RobloxStudioBeta.exe"))]
    if "--remove" in sys.argv:
        for t in targets:
            shutil.rmtree(t, ignore_errors=True)
            print("removed", t)
        sys.exit()
    os.makedirs(OUT, exist_ok=True)
    only = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else None  # e.g. --only lampwick
    todo = LAMPWICK if only == ["lampwick"] else [f for f in ALL + MERGE_GAME + LAMPWICK if not only or f.__name__ in only]
    for fn in todo:
        fn()
    for t in targets:
        os.makedirs(t, exist_ok=True)
        for f in glob.glob(os.path.join(OUT, "*.wav")):
            shutil.copy2(f, t)
        print("installed", len(os.listdir(t)), "sounds to", t)
