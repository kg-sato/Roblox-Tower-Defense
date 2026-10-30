"""Overnight cue set (T604 UI sounds, T603 enemy/boss/trainer, T155 familiar cues). Synthesised from code, no samples.

    Hunyuan3D/.venv/Scripts/python.exe VFX/sfx/make_cues.py     write VFX/sfx/out/*.wav, check them, write MANIFEST.md,
                                                                  spectrograms in Overnight/captures/, prints the evidence text
Reuses the synthesis helpers of make_sfx.py. Ear quality is UNVERIFIED (nobody listened); the checks below are machine checks only.
"""
import math
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_sfx as M  # noqa: E402
from make_sfx import (env_curve, env_exp, filt, mix, mul, noise, place, reverb, sine, swept_bp, vibrato_sine, zeros)  # noqa: E402

ROOT = os.path.abspath(os.path.join(M.HERE, "..", ".."))
os.makedirs(M.OUT, exist_ok=True)


def bell(f, d, dec=6.0, g=1.0):
    """glass/brass bell: fundamental plus two inharmonic partials"""
    return mix(mul(sine(f, d), env_exp(d, dec)), mul(sine(f * 2.76, d), env_exp(d, dec * 1.8)), mul(sine(f * 5.4, d), env_exp(d, dec * 3)), gains=[g, 0.3 * g, 0.12 * g])


def at(sig, t, total):
    return place(sig, t, total)


def choir(freqs, d, swell=0.4, rate=4.2):
    return mix(*[mul(vibrato_sine(f, d, 1, rate + i * 0.37, 0.006), env_curve(d, [(0, 0), (swell, 1), (d, 0)])) for i, f in enumerate(freqs)], gains=[1 / (1 + 0.3 * i) for i in range(len(freqs))])


SOUNDS = {}  # name -> (fn returning (signal, finish kwargs), purpose, (min dur, max dur))


def reg(name, purpose, lo, hi, rms=None, peak=0.45):
    def deco(fn):
        SOUNDS[name] = (fn, purpose, (lo, hi), rms, peak)
        return fn
    return deco


# ---- T604 UI set: short, soft, dark brass and glass --------------------------------------------------------------------
@reg("ui_click_soft", "primary button press (felted brass tick)", 0.07, 0.16, peak=0.4)
def _():
    d = 0.1
    return mix(mul(sine(1250, d), env_exp(d, 60)), mul(sine(430, d, sweep_to=300), env_exp(d, 70, 0.001)), mul(filt(noise(d, 101), "hp", 4500), env_exp(d, 200)), gains=[0.5, 0.6, 0.12])


@reg("ui_hover", "pointer over a control (tiny glass tick, quiet)", 0.04, 0.12, peak=0.25)
def _():
    d = 0.07
    return mix(mul(sine(2300, d), env_exp(d, 75)), mul(sine(3100, d), env_exp(d, 95)), gains=[0.6, 0.25])


@reg("ui_error", "action refused (two low, slightly detuned brass thumps)", 0.2, 0.45, peak=0.45)
def _():
    d = 0.3
    one = mix(mul(sine(196, 0.16, sweep_to=170), env_exp(0.16, 22, 0.002)), mul(sine(207, 0.16, sweep_to=178), env_exp(0.16, 22, 0.002)), mul(filt(noise(0.16, 102), "lp", 700), env_exp(0.16, 40)), gains=[0.7, 0.6, 0.3])
    return mix(at(one, 0, d), at(one, 0.12, d), gains=[0.9, 1.0])


@reg("ui_buy", "purchase confirmed (purse chink plus a warm bell)", 0.4, 0.8, peak=0.45)
def _():
    d = 0.6
    a = mix(mul(sine(3150, d), env_exp(d, 30)), mul(sine(4730, d), env_exp(d, 42)), gains=[0.5, 0.3])
    b = mix(mul(sine(3480, d), env_exp(d, 32)), mul(sine(5210, d), env_exp(d, 46)), gains=[0.45, 0.25])
    return reverb(mix(at(a, 0, d), at(b, 0.05, d), at(bell(659.25, d, 7), 0.09, d), gains=[0.6, 0.5, 0.55]), 0.15, 0.2)


@reg("ui_quest", "quest accepted or progressed (three rising bell notes)", 0.8, 1.5, peak=0.45)
def _():
    d = 1.0
    return reverb(mix(*[at(bell(f, 0.7, 6), 0.11 * i, d) for i, f in enumerate((392.0, 493.88, 587.33))], gains=[0.8, 0.8, 0.9]), 0.2, 0.35)


@reg("ui_achievement", "achievement unlocked (four-note bell arpeggio with shimmer)", 1.4, 2.6, peak=0.5)
def _():
    d = 1.7
    notes = [523.25, 659.25, 783.99, 1046.5]
    arp = mix(*[at(bell(f, 1.2, 4.5), 0.12 * i, d) for i, f in enumerate(notes)], gains=[0.7, 0.7, 0.75, 0.9])
    shim = at(mul(swept_bp(noise(1.0, 103), 3000, 7000, 2.0), env_curve(1.0, [(0, 0), (0.15, 0.4), (1.0, 0)])), 0.3, d)
    return reverb(mix(arp, shim, gains=[1, 0.18]), 0.28, 0.7)


@reg("ui_levelup", "trainer level up (pentatonic run into a warm open chord)", 1.8, 3.0, peak=0.55)
def _():
    d = 2.0
    run = mix(*[at(bell(f, 0.6, 7), 0.07 * i, d) for i, f in enumerate((392.0, 440.0, 523.25, 587.33, 659.25, 783.99))], gains=[0.5] * 6)
    pad = at(mix(*[mul(vibrato_sine(f, 1.6, 1, 4.5, 0.004), env_curve(1.6, [(0, 0), (0.25, 1), (1.6, 0)])) for f in (261.63, 392.0, 523.25, 659.25)], gains=[0.6, 0.5, 0.4, 0.3]), 0.4, d)
    top = at(bell(1046.5, 1.4, 3.5), 0.42, d)
    return reverb(mix(run, pad, top, gains=[0.8, 0.55, 0.7]), 0.28, 0.8)


# ---- T603 enemy families (Config/Enemy Bible), trainer, bosses ---------------------------------------------------------
@reg("step_trainer", "trainer footstep (leather boot on cobble)", 0.08, 0.22, peak=0.4)
def _():
    d = 0.16
    return mix(mul(sine(150, d, sweep_to=90, curve=0.5), env_exp(d, 38, 0.001)), mul(filt(noise(d, 110), "lp", 1800), env_exp(d, 55)), mul(filt(noise(d, 111), "hp", 3500), env_exp(d, 220)), gains=[0.8, 0.5, 0.12])


@reg("step_parishioner", "Hollow Parishioner footstep (soft hooded shuffle)", 0.12, 0.3, peak=0.35)
def _():
    d = 0.22
    return mix(mul(filt(noise(d, 112), "bp", 700, 0.9), env_curve(d, [(0, 0), (0.05, 1), (d, 0)])), mul(sine(110, d, sweep_to=80), env_exp(d, 24, 0.004)), gains=[0.8, 0.4])


@reg("step_wisp", "Fog Wisp drift (airy rustle, almost no impact)", 0.18, 0.4, peak=0.3)
def _():
    d = 0.3
    return mix(mul(swept_bp(noise(d, 113), 2600, 1100, 1.2), env_curve(d, [(0, 0), (0.1, 1), (d, 0)])), mul(sine(880, d, sweep_to=640), env_curve(d, [(0, 0), (0.12, 0.12), (d, 0)])), gains=[0.8, 0.5])


@reg("step_sentinel", "Brass Sentinel footstep (heavy iron thud with a brass ring)", 0.3, 0.7, peak=0.55)
def _():
    d = 0.4
    thud = mul(sine(75, d, sweep_to=42, curve=0.45), env_exp(d, 11, 0.001))
    ring = mix(mul(sine(420, d), env_exp(d, 14)), mul(sine(905, d), env_exp(d, 20)), gains=[0.35, 0.2])
    return reverb(mix(thud, ring, mul(filt(noise(d, 114), "lp", 600), env_exp(d, 30)), gains=[1.0, 0.7, 0.5]), 0.12, 0.2)


@reg("step_crow", "Clockwork Crow wingbeat (two ratcheting flaps)", 0.15, 0.35, peak=0.35)
def _():
    d = 0.25
    flap = mul(swept_bp(noise(0.09, 115), 500, 1700, 1.3), env_curve(0.09, [(0, 0), (0.02, 1), (0.09, 0)]))
    tick = mul(sine(2400, 0.04), env_exp(0.04, 120))
    return mix(at(flap, 0, d), at(flap, 0.11, d), at(tick, 0, d), at(tick, 0.11, d), gains=[0.8, 0.7, 0.3, 0.3])


@reg("step_thief", "Lantern Thief footstep (light creeping pad)", 0.06, 0.2, peak=0.3)
def _():
    d = 0.12
    return mix(mul(filt(noise(d, 116), "lp", 1300), env_exp(d, 60, 0.002)), mul(sine(190, d, sweep_to=140), env_exp(d, 45, 0.001)), gains=[0.7, 0.4])


@reg("hit_parishioner", "Hollow Parishioner takes a hit (cloth thump, hollow exhale)", 0.12, 0.3, peak=0.45)
def _():
    d = 0.2
    return mix(mul(sine(160, d, sweep_to=90, curve=0.5), env_exp(d, 24, 0.001)), mul(filt(noise(d, 120), "bp", 500, 0.8), env_exp(d, 18)), gains=[0.8, 0.5])


@reg("hit_wisp", "Fog Wisp takes a hit (breathy pop, falling whistle)", 0.2, 0.6, peak=0.4)
def _():
    d = 0.3
    return reverb(mix(mul(sine(950, d, sweep_to=320, curve=0.6), env_exp(d, 14, 0.002)), mul(swept_bp(noise(d, 121), 3500, 900, 1.4), env_exp(d, 16)), gains=[0.5, 0.7]), 0.12, 0.2)


@reg("hit_sentinel", "Brass Sentinel takes a hit (dull brass clang)", 0.3, 0.9, peak=0.55)
def _():
    d = 0.42
    return reverb(mix(*[mul(sine(f, d), env_exp(d, dec, 0.001)) for f, dec in ((520, 9), (1180, 14), (1910, 20), (2790, 28))], mul(filt(noise(0.06, 122), "bp", 1800, 1.0), env_exp(0.06, 60)), gains=[0.7, 0.45, 0.3, 0.18, 0.5]), 0.15, 0.3)


@reg("hit_crow", "Clockwork Crow takes a hit (spring twang and a metal ping)", 0.15, 0.4, peak=0.4)
def _():
    d = 0.25
    return mix(mul(sine(1500, d, sweep_to=640, curve=0.4), env_exp(d, 16, 0.001)), mul(sine(3200, d), env_exp(d, 30)), mul(filt(noise(0.03, 123), "hp", 3000), env_exp(0.03, 120)), gains=[0.6, 0.3, 0.3])


@reg("hit_thief", "Lantern Thief takes a hit (lantern glass rattle and a thud)", 0.12, 0.3, peak=0.4)
def _():
    d = 0.2
    return mix(mul(sine(2850, d), env_exp(d, 30)), mul(sine(4100, d), env_exp(d, 44)), mul(sine(180, d, sweep_to=100), env_exp(d, 30, 0.001)), gains=[0.35, 0.2, 0.7])


@reg("boss_intro_unbound", "stinger: The Unbound (stage 5): fog drone, cold whisper, soft bell", 2.4, 4.0, rms=-24.0)
def _():
    d = 3.0
    drone = mul(vibrato_sine(73.4, d, 1, 0.3, 0.006), env_curve(d, [(0, 0), (1.5, 0.8), (d, 0)]))
    whisper = mul(swept_bp(noise(d, 130), 1800, 700, 2.0), env_curve(d, [(0, 0), (1.3, 0.6), (d, 0)]))
    return reverb(mix(drone, whisper, at(bell(293.66, 1.6, 2.6), 1.4, d), gains=[0.9, 0.35, 0.6]), 0.3, 1.0)


@reg("boss_intro_automaton", "stinger: Clockmaker's Automaton (stage 10): accelerating gear ticks, brass clank", 2.4, 4.0, rms=-22.5)
def _():
    d = 3.0
    tick = mul(filt(noise(0.04, 131), "bp", 3000, 3), env_exp(0.04, 120))
    t, gap, ticks = 0.0, 0.42, []
    while t < 1.9:
        ticks.append(at(tick, t, d))
        t += gap
        gap = max(0.07, gap * 0.82)
    drone = mul(vibrato_sine(98, d, 1, 0.4, 0.005), env_curve(d, [(0, 0), (1.9, 0.7), (d, 0)]))
    clank = at(mix(*[mul(sine(f, 1.1), env_exp(1.1, dec, 0.001)) for f, dec in ((310, 5), (847, 8), (1432, 11), (2213, 15))], gains=[0.6, 0.45, 0.3, 0.2]), 1.95, d)
    sub = at(mul(sine(65, 1.0, sweep_to=38, curve=0.4), env_exp(1.0, 4, 0.002)), 1.95, d)
    return reverb(mix(*ticks, drone, clank, sub, gains=[0.5] * len(ticks) + [0.7, 0.7, 0.9]), 0.25, 0.8)


@reg("boss_intro_echo", "stinger: The Star Choir's Echo (stage 15): minor choir swell, star-bell cluster", 3.4, 5.0, rms=-22.0)
def _():
    d = 3.4
    ch = choir((146.83, 220.0, 293.66, 349.23, 440.0), d, 1.6)
    stars = mix(*[at(bell(f, 1.6, 3.2), 1.6 + 0.09 * i, d) for i, f in enumerate((1174.66, 1396.9, 1760.0, 2093.0))], gains=[0.35] * 4)
    return reverb(mix(ch, stars, at(mul(sine(73.4, 1.2, sweep_to=48), env_exp(1.2, 4)), 1.55, d), gains=[0.7, 0.8, 0.7]), 0.3, 1.2)


@reg("boss_intro_regent", "stinger: Hollow Court Regent (stage 20): two deep bell tolls over a dark pad", 3.8, 5.5, rms=-21.5)
def _():
    d = 3.8
    parts = [(0.5, 1.2, 0.5), (1.0, 1.5, 0.8), (1.19, 1.9, 0.5), (1.5, 2.2, 0.35), (2.0, 2.6, 0.4), (2.52, 3.6, 0.2)]

    def toll():
        return mix(*[mul(sine(98 * r, 2.4), env_exp(2.4, dec, 0.002)) for r, dec, _ in parts], gains=[g for _, _, g in parts])
    pad = mul(choir((65.4, 98.0, 130.8, 155.6), d, 1.4, 3.6), env_curve(d, [(0, 0), (1.4, 0.7), (d, 0)]))
    return reverb(mix(at(toll(), 0.3, d), at(toll(), 1.5, d), pad, gains=[0.8, 0.95, 0.5]), 0.3, 1.3)


@reg("boss_intro_clockmaker", "stinger: The Clockmaker (stage 25): tick-tock slows to a stop, silence, one deep hit", 4.2, 5.6, rms=-20.5)
def _():
    d = 4.2
    tk = mix(mul(filt(noise(0.05, 132), "bp", 2600, 3), env_exp(0.05, 100)), mul(sine(1250, 0.05), env_exp(0.05, 90)), gains=[1, 0.4])
    tok = mix(mul(filt(noise(0.05, 133), "bp", 2000, 3), env_exp(0.05, 100)), mul(sine(940, 0.05), env_exp(0.05, 90)), gains=[1, 0.4])
    t, gap, ticks, k = 0.0, 0.3, [], 0
    while t < 2.3:
        ticks.append(at(tk if k % 2 == 0 else tok, t, d))
        t += gap
        gap *= 1.22
        k += 1
    hit = at(mix(mul(sine(62, 1.6, sweep_to=30, curve=0.4), env_exp(1.6, 2.6, 0.001)), mul(sine(124, 1.0), env_exp(1.0, 5)), gains=[1.0, 0.4]), 2.9, d)
    ch = at(choir((130.8, 196.0, 261.63, 329.63), 1.3, 0.1), 2.9, d)
    return reverb(mix(*ticks, hit, ch, gains=[0.5] * len(ticks) + [1.0, 0.45]), 0.3, 1.0)


# ---- T155 familiar cues: placement and a reveal per rarity (merge tiers 1 to 8 already exist as merge_1..merge_8) -----------
@reg("familiar_place", "familiar set down on its slot (wood knock with a soft bell)", 0.3, 0.7, peak=0.45)
def _():
    d = 0.4
    return reverb(mix(at(mix(mul(sine(210, 0.2, sweep_to=165), env_exp(0.2, 28, 0.001)), mul(sine(445, 0.2), env_exp(0.2, 45)), gains=[0.7, 0.3]), 0, d), at(bell(880, 0.35, 9), 0.03, d), gains=[1, 0.35]), 0.12, 0.2)


RAR = ["common", "rare", "epic", "legendary", "mythic", "celestial"]
RAR_DUR = [0.9, 1.5, 2.3, 3.3, 4.1, 5.0]
RAR_RMS = [-27.0, -25.0, -23.0, -21.0, -19.5, -18.5]


def reveal(r):
    d = RAR_DUR[r - 1]
    f = [523.25, 659.25, 783.99, 1046.5, 880.0, 1174.66][r - 1]
    layers, g = [at(bell(f, d - 0.1, 5 - 0.4 * r), 0.02, d), at(mul(sine(460, 0.2, sweep_to=230, curve=0.5), env_exp(0.2, 22)), 0, d)], [1.0, 0.7]
    if r >= 2:
        layers.append(mix(*[at(bell(x, 0.9, 5), 0.1 * i, d) for i, x in enumerate((f * 1.5, f * 2))], gains=[0.6, 0.6]))
        g.append(0.8)
    if r >= 3:  # riser into a hit, sub weight
        rs = 0.7 if r == 3 else 1.0
        layers.append(at(mul(swept_bp(noise(rs, 140 + r), 400, 4200, 1.4, 1.5), env_curve(rs, [(0, 0), (rs - 0.02, 1), (rs, 0)])), 0, d))
        layers.append(at(mul(sine(90, d - rs, sweep_to=40, curve=0.4), env_exp(d - rs, 3, 0.002)), rs, d))
        g += [0.45, 0.8]
    if r >= 4:  # choir
        layers.append(at(choir([f * 0.25, f * 0.375, f * 0.5, f * 0.625], d - 0.4, 0.5), 0.4, d))
        g.append(0.6)
    if r >= 5:  # detuned shimmer, magenta-dark: beating pairs a semitone-ish apart
        layers.append(mix(*[mul(sine(x, d), env_curve(d, [(0, 0), (0.9, 0.7), (d, 0)])) for x in (f * 2, f * 2.03, f * 3, f * 3.04)], gains=[0.3, 0.3, 0.2, 0.2]))
        g.append(0.5)
    if r >= 6:  # celestial: high harp-like run over the top
        layers.append(mix(*[at(bell(f * m, 1.8, 3), 0.9 + 0.12 * i, d) for i, m in enumerate((1, 1.25, 1.5, 2, 2.5, 3))], gains=[0.4] * 6))
        g.append(0.8)
    return reverb(mix(*layers, gains=g), 0.14 + 0.03 * r, 0.3 + 0.12 * r)


for _r in range(1, 7):
    nm = "reveal_" + RAR[_r - 1]
    SOUNDS[nm] = ((lambda r=_r: reveal(r)), "familiar reveal, rarity %s (rarity %d of 6; escalating length, weight and loudness)" % (RAR[_r - 1].capitalize(), _r), (RAR_DUR[_r - 1] - 0.3, RAR_DUR[_r - 1] + 1.2), RAR_RMS[_r - 1], 0.7)

EXISTING = [("merge_%d" % k, "familiar merge tier %d (existing, make_sfx.py)" % k) for k in range(1, 9)] + [("place_thud", "familiar placement, wood knock (existing)")]
GROUPS = {"T604": [n for n in SOUNDS if n.startswith("ui_")], "T603": [n for n in SOUNDS if n.startswith(("step_", "hit_", "boss_intro"))],
          "T155": ["familiar_place"] + [n for n in SOUNDS if n.startswith("reveal_")]}


def read(name):
    with wave.open(os.path.join(M.OUT, name + ".wav")) as w:
        raw = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768
        return raw, w.getframerate()


def stats(name):
    x, sr = read(name)
    pk = float(np.max(np.abs(x)))
    rms = float(np.sqrt(np.mean(x ** 2)))
    # short-term (400 ms) loudest block, a rough loudness proxy (not LUFS: no K-weighting)
    blk = int(0.4 * sr)
    st = max(float(np.sqrt(np.mean(x[i:i + blk] ** 2))) for i in range(0, max(1, len(x) - blk + 1), blk // 2))
    return dict(dur=len(x) / sr, peak=20 * math.log10(pk), rms=20 * math.log10(rms), st=20 * math.log10(st), clip=int(np.sum(np.abs(x) >= 0.9999)),
                edge=float(max(abs(x[:6]).max(), abs(x[-6:]).max())), dc=float(abs(x.mean())))


def spectrogram(names, path, title):
    from PIL import Image
    from scipy.signal import spectrogram as sp
    tiles = []
    for n in names:
        x, sr = read(n)
        f, t, S = sp(x, sr, nperseg=1024, noverlap=768)
        D = 10 * np.log10(S + 1e-12)
        D = np.clip((D - (D.max() - 80)) / 80, 0, 1)[:240][::-1]  # up to ~5.1 kHz
        img = Image.fromarray((D * 255).astype(np.uint8)).resize((max(40, int(len(x) / sr * 160)), 120))
        tiles.append(img)
    H = sum(i.height + 4 for i in tiles)
    W = max(i.width for i in tiles)
    sheet = Image.new("L", (W, H), 0)
    y = 0
    for i in tiles:
        sheet.paste(i, (0, y))
        y += i.height + 4
    sheet.save(path)
    return "%s: %d spectrograms stacked top to bottom in this order: %s" % (title, len(names), ", ".join(names))


def main():
    only = [a for a in sys.argv[1:] if a in GROUPS]
    for name, (fn, purpose, band, rms, peak) in SOUNDS.items():
        if only and not any(name in GROUPS[g] for g in only):
            continue
        sig = fn()
        (M.finish_rms(sig, name, rms) if rms is not None else M.finish(sig, name, peak))
    cap = os.path.join(ROOT, "Overnight", "captures")
    os.makedirs(cap, exist_ok=True)
    fails, rows, report = 0, [], []
    for g, names in GROUPS.items():
        if only and g not in only:
            continue
        report.append("== %s ==" % g)
        report.append("%-22s %5s %7s %7s %8s %5s  %s" % ("name", "dur", "peak", "rms", "st400ms", "clip", "result"))
        for n in names:
            s = stats(n)
            lo, hi = SOUNDS[n][2]
            bad = []
            if s["clip"]:
                bad.append("clipping")
            if s["peak"] >= -0.5:
                bad.append("peak too hot")
            if s["peak"] < -20:
                bad.append("peak too quiet")
            if not lo <= s["dur"] <= hi:
                bad.append("duration %.2f outside %.2f-%.2f" % (s["dur"], lo, hi))
            if s["edge"] > 0.004 or s["dc"] > 0.01:
                bad.append("edge click or DC")
            fails += bool(bad)
            rows.append((n, s))
            report.append("%-22s %5.2f %6.1fd %6.1fd %7.1fd %5d  %s" % (n, s["dur"], s["peak"], s["rms"], s["st"], s["clip"], "PASS" if not bad else "FAIL " + "; ".join(bad)))
        report.append(spectrogram(names, os.path.join(cap, "audio_cues_%s_spectrogram.png" % g), "Overnight/captures/audio_cues_%s_spectrogram.png (0-5 kHz)" % g))
    # escalation checks: reveal ladder gets longer and louder; bosses louder than UI
    rv = [stats("reveal_" + r) for r in RAR] if not only or "T155" in only else []
    if rv:
        ok = all(rv[i + 1]["dur"] > rv[i]["dur"] and rv[i + 1]["rms"] > rv[i]["rms"] - 0.3 for i in range(5))
        report.append("reveal ladder escalates (longer and not quieter each rarity): %s" % ("PASS" if ok else "FAIL"))
        fails += not ok
    if not only:
        mf = ["# Sound cue manifest (T604, T603, T155)", "", "Generated by `VFX/sfx/make_cues.py` (synthesised from code, no samples). WAV 16-bit mono 44.1 kHz in `VFX/sfx/out/`.",
              "Loudness is RMS dBFS over the whole file and the loudest 400 ms block (not LUFS). Ear quality is UNVERIFIED (nobody has listened). Not yet in SoundCatalog / SoundFX (Studio wiring is a later task).",
              "Roblox asset ids for uploaded files are in `VFX/ASSETS.md`.", "", "| name | length s | purpose | peak dBFS | RMS dBFS | loudest 400 ms dBFS |", "|---|---|---|---|---|---|"]
        for n, purpose in [(n, SOUNDS[n][1]) for g in GROUPS for n in GROUPS[g]] + EXISTING:
            s = stats(n)
            mf.append("| %s | %.2f | %s | %.1f | %.1f | %.1f |" % (n, s["dur"], purpose, s["peak"], s["rms"], s["st"]))
        open(os.path.join(M.HERE, "MANIFEST.md"), "w", encoding="utf-8").write("\n".join(mf) + "\n")
        report.append("wrote VFX/sfx/MANIFEST.md (%d rows)" % (len(mf) - 8))
    print("\n".join(report))
    print("CUES: %d sounds, %d failing" % (len(rows), fails))
    return fails


if __name__ == "__main__":
    raise SystemExit(1 if main() else 0)
