"""Compares our blur-resolve curves with the Rivals ramp, using measured stills. Pillow-free: numbers only.

The Rivals ramp is the sharpness series from Roblox Dev/Research/VFX and Animation/Video Reference Analysis.md (frames 20.0..21.0 s, every 0.2 s):
683, 1270, 2027, 2795, 3559, 4133. Our side: sharpness measured in Studio on the same grass region at fixed BlurEffect sizes
(the transfer function), pushed through each candidate size-versus-time curve. Both are normalised to 0..1 and compared at
the same fractions of the resolve. RMSE below 0.12 counts as the same shape. Limits: sharpness is scene dependent, the
Rivals frames contain UI, and one resolve was measured for each side; this compares SHAPE, not look.
"""
import json
import math

RIVALS = [683, 1270, 2027, 2795, 3559, 4133]
# measured 2026-10-25 (VFX/verify_stills.py, region 100,620,700,840): BlurEffect.Size -> sharpness
TF = [(0.0, 556.1), (3.6, 385.0), (7.2, 273.9), (10.8, 233.5), (14.4, 232.9), (18.0, 233.2)]


def transfer(size):
    if size <= TF[0][0]:
        return TF[0][1]
    for (a, sa), (b, sb) in zip(TF, TF[1:]):
        if size <= b:
            return sa + (sb - sa) * (size - a) / (b - a)
    return TF[-1][1]


def norm(v):
    lo, hi = min(v), max(v)
    return [(x - lo) / (hi - lo) for x in v]


def quad_out(f, peak):
    return peak * (1 - f) ** 2


def expo_out(f, peak):
    return peak * (1 - (1 - 2 ** (-10 * f))) if f > 0 else peak  # remaining blur under Exponential Out


def linear(f, peak):
    return peak * (1 - f)


def curve(fn, peak):
    fr = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
    return norm([transfer(fn(f, peak)) for f in fr])


def rmse(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)) / len(a))


if __name__ == "__main__":
    ref = norm(RIVALS)
    out = {"rivals_norm": ref, "candidates": {}}
    print("Rivals normalised sharpness ramp: " + " ".join("%.2f" % v for v in ref))
    for name, fn, peak in [("Quad Out 18 (shipped)", quad_out, 18), ("Quad Out 11", quad_out, 11), ("Exponential Out 18 (playbook)", expo_out, 18), ("Linear 18", linear, 18), ("Quad Out 10 (touch)", quad_out, 10), ("Quad Out 8 (soft)", quad_out, 8)]:
        c = curve(fn, peak)
        e = rmse(c, ref)
        out["candidates"][name] = {"curve": c, "rmse": e}
        print("%-32s %s   RMSE %.3f %s" % (name, " ".join("%.2f" % v for v in c), e, "same shape" if e < 0.12 else "different shape"))
    json.dump(out, open("VFX/verify_curves.json", "w"), indent=1)
