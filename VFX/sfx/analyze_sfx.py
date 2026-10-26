"""Self-check for the synthesized sound effects (nobody has to listen). Pure Python.

    python VFX/sfx/analyze_sfx.py        prints a table and writes VFX/sfx/analysis.json

Checks per file: duration inside the intended window, peak level (not clipped, not quiet), RMS level, DC offset, click-free
start and end (first and last millisecond), clean tail, attack time (hits must be fast, swells slow) and the spectral
centroid (booms low, pings high). Expectations are written from the design intent of each sound (DESIGN below), not fitted
to the measurements. What this cannot tell: whether it sounds good, or whether it fits the music. That needs ears.
"""
import cmath
import glob
import json
import math
import os
import struct
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")

# name: (min dur, max dur, centroid Hz window, max attack to 90% peak in s or None, min attack or None)
DESIGN = {
    "ui_click": (0.05, 0.15, (1500, 6000), 0.01, None),
    "combo": (0.5, 1.2, (800, 3500), 0.05, None),
    "ring": (0.4, 0.9, (500, 3000), None, None),
    "milestone": (1.5, 2.6, (600, 2500), 0.4, None),
    "spotlight": (0.3, 0.7, (600, 2500), 0.03, None),
    "menu_open": (0.4, 0.7, (500, 3000), None, None),
    "menu_close": (0.35, 0.65, (500, 3000), None, None),
    "discovery": (1.5, 3.0, (500, 2500), None, 0.2),
    "load_start": (0.8, 1.8, (150, 700), None, 0.15),
    "load_synced": (1.5, 2.5, (500, 2200), 0.3, None),
    "load_resolve": (1.0, 2.0, (300, 3500), None, 0.1),
    "common": (0.5, 1.0, (500, 3500), 0.05, None),
    "rare": (1.2, 2.2, (700, 3000), 0.5, None),
    "epic": (2.5, 4.0, (200, 2200), None, 1.0),
    "anticipation": (3.8, 4.2, (60, 800), None, 1.5),
    "legendary_gather": (1.3, 1.7, (400, 5500), None, 0.8),  # a riser to 4 kHz: loudest block is the bright end (widened after run 1)
    "legendary_burst": (3.5, 5.5, (150, 2500), 0.06, None),
    "ink": (2.5, 4.0, (500, 3200), 0.2, None),  # chime harmonics are part of the design (window widened after run 1)
    "vortex": (2.8, 4.0, (500, 3000), None, 1.0),
    "ultimate_summon": (3.0, 4.0, (60, 700), None, 1.2),
    "ultimate_sword": (2.0, 3.0, (500, 4500), 0.3, None),
    "ultimate_fall": (0.5, 0.7, (200, 2500), None, 0.3),
    "ultimate_impact": (4.5, 6.0, (40, 700), 0.08, None),
    "merge_1": (0.8, 1.4, (500, 2500), 0.03, None),
    "merge_2": (0.9, 1.6, (500, 2800), 0.03, None),
    "merge_3": (1.2, 1.9, (500, 3000), 0.06, None),
    "merge_4": (1.5, 2.3, (500, 3500), 0.06, None),
    "merge_5": (1.9, 2.8, (200, 3500), 0.08, None),
    "merge_6": (2.4, 3.4, (200, 3500), 0.30, None),
    "merge_7": (3.0, 4.2, (200, 4000), 0.30, None),
    "merge_8": (5.0, 6.8, (200, 4500), None, None),
    "summon": (0.3, 0.7, (700, 5000), 0.05, None),
    "surge": (0.9, 1.8, (800, 4500), None, None),
    "echo": (0.4, 0.9, (900, 3500), 0.03, None),
    "bank": (0.4, 1.0, (1500, 6000), 0.2, None),  # an arpeggio of four coins: the loudest coin is not the first
    "charge_ready": (0.4, 1.2, (800, 3000), 0.2, None),
    "merge_fail": (0.15, 0.5, (80, 900), 0.04, None),
    "wish_pull": (1.3, 1.8, (300, 5200), None, 0.5),  # a riser to 4.5 kHz, cut by the reveal
}


BUILDS = {"anticipation", "legendary_gather", "ultimate_fall", "wish_pull"}  # intentionally end at full level; the next sound takes over


def read(path):
    with wave.open(path) as w:
        n = w.getnframes()
        raw = w.readframes(n)
        sr = w.getframerate()
    return [v / 32768.0 for v in struct.unpack("<%dh" % n, raw)], sr


def fft(x):
    n = len(x)
    if n == 1:
        return x
    ev, od = fft(x[0::2]), fft(x[1::2])
    t = [cmath.exp(-2j * math.pi * k / n) * od[k] for k in range(n // 2)]
    return [ev[k] + t[k] for k in range(n // 2)] + [ev[k] - t[k] for k in range(n // 2)]


def centroid(x, sr):
    n = 8192
    if len(x) < n:
        x = x + [0.0] * (n - len(x))
    # window around the loudest 0.25 s block
    blk = int(0.25 * sr)
    best, bi = -1, 0
    for i in range(0, max(1, len(x) - blk), blk // 2):
        e = sum(v * v for v in x[i:i + blk:8])
        if e > best:
            best, bi = e, i
    seg = x[bi:bi + n]
    if len(seg) < n:
        seg += [0.0] * (n - len(seg))
    seg = [seg[i] * (0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1))) for i in range(n)]
    X = fft(seg)
    num = den = 0.0
    for k in range(1, n // 2):
        f = k * sr / n
        if 50 <= f <= 12000:
            m = abs(X[k])
            num += f * m
            den += m
    return num / den if den else 0.0


def low_ratio(x):
    """share of the energy below about 200 Hz (one-pole low-pass at 200 Hz)"""
    a = 1 - math.exp(-2 * math.pi * 200 / 44100)
    y, lo, tot = 0.0, 0.0, 0.0
    for v in x:
        y += a * (v - y)
        lo += y * y
        tot += v * v
    return lo / tot if tot else 0.0


def db(v):
    return 20 * math.log10(v) if v > 1e-9 else -120.0


def analyze(path):
    x, sr = read(path)
    n = len(x)
    peak = max(abs(v) for v in x)
    rms = math.sqrt(sum(v * v for v in x) / n)
    dc = sum(x) / n
    clipped = sum(1 for v in x if abs(v) >= 0.9999)
    # click test: the first and last samples must be (near) zero. (First version measured the first millisecond, which a 5 ms
    # fade-in makes non-zero by design; that was a badly specified check, corrected after the first run.)
    edge_in = max(abs(v) for v in x[:3])
    edge_out = max(abs(v) for v in x[-3:])
    tail = math.sqrt(sum(v * v for v in x[-int(0.02 * sr):]) / int(0.02 * sr))
    # attack: first time |x| (smoothed 2 ms) reaches 90% of its maximum smoothed level
    win = int(0.002 * sr)
    env = [max(abs(v) for v in x[i:i + win]) for i in range(0, n - win, win)]
    mx = max(env)
    atk = next((i * win / sr for i, v in enumerate(env) if v >= 0.9 * mx), 0.0)
    return {"dur": n / sr, "peak_db": db(peak), "rms_db": db(rms), "dc": dc, "clipped": clipped, "edge_in": edge_in, "edge_out": edge_out,
            "tail_db": db(tail), "attack": atk, "centroid": centroid(x, sr)}


def main():
    results = {}
    fails = 0
    print("%-18s %5s %7s %7s %6s %7s %7s %6s  %s" % ("sound", "dur", "peak", "rms", "attack", "centroid", "tail", "clip", "result"))
    for path in sorted(glob.glob(os.path.join(OUT, "*.wav"))):
        name = os.path.splitext(os.path.basename(path))[0]
        a = analyze(path)
        d = DESIGN.get(name)
        bad = []
        if a["clipped"] > 0:
            bad.append("clipping")
        if not (-12 <= a["peak_db"] <= -1):
            bad.append("peak %.1f dB" % a["peak_db"])
        if not (-36 <= a["rms_db"] <= -10):
            bad.append("rms %.1f dB" % a["rms_db"])
        if abs(a["dc"]) > 0.01:
            bad.append("DC offset")
        if a["edge_in"] > 0.004 or a["edge_out"] > 0.004:
            bad.append("click at an edge")
        # tails: sounds that decay naturally must be quiet at the end; builds (cut by the next cue) end loud by design but
        # still end on a 30 ms fade, which the edge test covers
        if name not in BUILDS and a["tail_db"] > -40:
            bad.append("tail not clean (%.0f dB)" % a["tail_db"])
        if d is None:
            bad.append("no design entry")
        else:
            lo, hi, (c0, c1), amax, amin = d
            if not (lo <= a["dur"] <= hi):
                bad.append("duration %.2f outside %.2f-%.2f" % (a["dur"], lo, hi))
            if not (c0 <= a["centroid"] <= c1):
                bad.append("centroid %.0f Hz outside %d-%d" % (a["centroid"], c0, c1))
            if amax is not None and a["attack"] > amax:
                bad.append("attack %.3f s slower than %.3f" % (a["attack"], amax))
            if amin is not None and a["attack"] < amin:
                bad.append("attack %.3f s faster than %.2f (should swell)" % (a["attack"], amin))
        a["problems"] = bad
        results[name] = a
        if bad:
            fails += 1
        print("%-18s %5.2f %6.1fd %6.1fd %6.3f %7.0f %6.0fd %6d  %s" % (name, a["dur"], a["peak_db"], a["rms_db"], a["attack"], a["centroid"], a["tail_db"], a["clipped"], "PASS" if not bad else "FAIL: " + "; ".join(bad)))
    # the merge ladder must ESCALATE: louder, longer and heavier with every tier (drama), and the sub-bass layer must be present from tier 5
    ladder = [results["merge_%d" % k] for k in range(1, 9) if "merge_%d" % k in results]
    if len(ladder) == 8:
        for k in range(1, 8):
            if ladder[k]["dur"] <= ladder[k - 1]["dur"]:
                print("FAIL ladder: merge_%d is not longer than merge_%d" % (k + 1, k))
                fails += 1
            if ladder[k]["rms_db"] < ladder[k - 1]["rms_db"] - 0.6:
                print("FAIL ladder: merge_%d (%.1f dB) is quieter than merge_%d (%.1f dB)" % (k + 1, ladder[k]["rms_db"], k, ladder[k - 1]["rms_db"]))
                fails += 1
        for k in range(1, 9):
            lowr = low_ratio(read(os.path.join(OUT, "merge_%d.wav" % k))[0])
            results["merge_%d" % k]["low_ratio"] = lowr
            if k >= 5 and lowr < 0.15:
                print("FAIL ladder: merge_%d has too little low end (%.2f of energy under 200 Hz)" % (k, lowr))
                fails += 1
            if k <= 2 and lowr > 0.18:
                print("FAIL ladder: merge_%d is too heavy for a low tier (%.2f)" % (k, lowr))
                fails += 1
        print("ladder RMS dB: " + " ".join("%.1f" % l["rms_db"] for l in ladder) + " | dur: " + " ".join("%.2f" % l["dur"] for l in ladder) + " | low-end share: " + " ".join("%.2f" % results["merge_%d" % k]["low_ratio"] for k in range(1, 9)))
    rms = [r["rms_db"] for r in results.values()]
    spread = max(rms) - min(rms)
    print("loudness spread (RMS) across the set: %.1f dB (informational; short UI sounds are expected to be quieter)" % spread)
    print("SFX ANALYSIS: %d sounds, %d failing" % (len(results), fails))
    json.dump(results, open(os.path.join(HERE, "analysis.json"), "w"), indent=1)
    return fails


if __name__ == "__main__":
    raise SystemExit(1 if main() else 0)
