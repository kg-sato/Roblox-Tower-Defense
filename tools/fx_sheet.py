"""Procedural flipbook sheets for Roblox ParticleEmitter / UI flipbooks. Local only, original art, no downloads.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_sheet.py build <effect> [--grid 8] [--frame 128] [--out VFX/flipbooks]
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_sheet.py verify <sheet.png> [--loop] [--grid 8]
Effects: arcane_burst (one-shot, charge -> hit -> ring, streaks, sparks, smoke aftermath), ground_sigil (seamless loop).
Writes <effect>_<g>x<g>.png (violet-gold-white gradient map) and <effect>_<g>x<g>_mono.png (white, tint with ParticleEmitter.Color).
Frames run row by row from the top left, with transparent margins (no square haze). Roblox: FlipbookLayout Grid<g>x<g>,
FlipbookMode OneShot, Lifetime = the effect length, Rate 0, Emit(1)."""
import json, sys
from pathlib import Path
import cv2, numpy as np
from PIL import Image

SS = 2  # supersample


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def fbm(seed, n, octaves=4, base=4):
    rng = np.random.default_rng(seed)
    out, amp, tot = np.zeros((n, n), np.float32), 1.0, 0.0
    for o in range(octaves):
        g = rng.random((base * 2 ** o, base * 2 ** o)).astype(np.float32)
        out += cv2.resize(g, (n, n), interpolation=cv2.INTER_CUBIC) * amp
        tot += amp
        amp *= 0.5
    return out / tot


def seg_dist(X, Y, a, b):
    px, py, bx, by = X - a[0], Y - a[1], b[0] - a[0], b[1] - a[1]
    h = np.clip((px * bx + py * by) / (bx * bx + by * by + 1e-9), 0, 1)
    return np.hypot(px - bx * h, py - by * h)


RAMP = [(0.0, (40, 10, 90)), (0.35, (150, 60, 220)), (0.65, (255, 190, 90)), (1.0, (255, 250, 235))]


def color(I):
    xs = [s for s, _ in RAMP]
    return np.stack([np.interp(I, xs, [c[i] for _, c in RAMP]) for i in range(3)], -1).astype(np.float32) / 255.0


def grid(n):
    ax = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    X, Y = np.meshgrid(ax, -ax)
    return X, Y, np.hypot(X, Y), np.arctan2(Y, X)


def burst_frame(t, n, ctx):
    X, Y, R, TH = ctx["grid"]
    ease = lambda x: 1 - (1 - x) ** 3
    hit = 0.12
    if t < hit:  # anticipation: a small core charges up
        cr, ci, k = 0.04 + 0.08 * (t / hit), 0.4 + 0.6 * (t / hit), 0.0
        for d, v in ctx["sparks"][:12]:  # gathering: motes are pulled into the core
            q = d * (1.0 - 0.9 * (t / hit)) * (0.5 + 0.4 * v)
            I0 = np.exp(-(np.hypot(X - q[0], Y - q[1]) / 0.014) ** 2) * (t / hit) * 0.8
            ctx["_gather"] = ctx.get("_gather", 0) + I0
    else:
        k = (t - hit) / (1 - hit)
        cr, ci = 0.30 * np.exp(-k * 14) + 0.10 * np.exp(-k * 3) + 0.01, np.exp(-k * 6) * 0.9 + 0.1 * (1 - k) ** 2
    I = np.exp(-(R / cr) ** 2) * ci + np.exp(-(R / (cr * 2.0 + 0.04)) ** 2) * 0.32 * ci
    if t < hit:
        I = I + ctx.pop("_gather", 0)
    if t >= hit:
        warp = (cv2.resize(ctx["n0"], (n, n)) - 0.5) * 0.14 * k
        rr, w = 0.12 + 0.78 * ease(k), 0.075 * (1 - k) + 0.012
        I += np.exp(-((R + warp - rr) / w) ** 2) * (1 - k) ** 1.5 * 0.9
        k2 = max(k - 0.1, 0)
        I += np.exp(-((R + warp * 0.5 - (0.1 + 0.55 * ease(k2))) / (0.05 * (1 - k2) + 0.01)) ** 2) * (1 - k2) ** 2 * 0.5 * (k > 0.1)
        ang = np.interp((TH + 0.4 * k) % (2 * np.pi), ctx["ax"], ctx["av"], period=2 * np.pi)
        streak = np.clip((ang - 0.66) / 0.22, 0, 1) ** 1.3
        I += streak * np.exp(-((R - (0.15 + 0.7 * ease(k))) / 0.2) ** 2) * (1 - k) ** 2 * 0.85
        for d, v in ctx["sparks"]:  # sparks with a short trail, drag slows them
            p = lambda tt: d * v * (1 - np.exp(-2.2 * tt)) / 2.2 * 1.6
            I += np.exp(-(seg_dist(X, Y, p(max(k - 0.13, 0)), p(k)) / 0.013) ** 2) * (1 - k) ** 1.1 * 1.0
        n0, n1 = ctx["n0"], ctx["n1"]
        dens = ((1 - k) * n0 + k * n1) * np.clip(1 - R / (0.25 + 0.6 * ease(k)), 0, 1)
        I += np.clip((dens - 0.18) * 2.2, 0, 1) * 0.55 * np.sin(np.pi * min(1, k * 1.15)) * (1 - k * 0.5)
    return np.clip(I, 0, 1) * (1 - smooth(0.80, 0.97, R))


def sigil_frame(t, n, ctx):
    X, Y, R, TH = ctx["grid"]
    rot = 2 * np.pi / 5 * t  # 72 degrees per loop = one pentagram step = 2 tick slots of 10 = 4 rune slots of 20: seamless
    c, s = np.cos(rot), np.sin(rot)
    Xr, Yr = X * c + Y * s, -X * s + Y * c
    I = np.exp(-((R - 0.78) / 0.014) ** 2) + 0.5 * np.exp(-((R - 0.78) / 0.07) ** 2) * 0.5
    I += 0.8 * np.exp(-((R - 0.62) / 0.009) ** 2)
    pts = [(0.62 * np.cos(2 * np.pi * i / 5 + np.pi / 2), 0.62 * np.sin(2 * np.pi * i / 5 + np.pi / 2)) for i in range(5)]
    for i in range(5):  # pentagram, rotating with the ring
        a, b = pts[i], pts[(i + 2) % 5]
        I += 0.9 * np.exp(-(seg_dist(Xr, Yr, a, b) / 0.012) ** 2) + 0.25 * np.exp(-(seg_dist(Xr, Yr, a, b) / 0.05) ** 2)
    ang = (np.arctan2(Yr, Xr) % (2 * np.pi)) / (2 * np.pi) * 10 % 1
    I += 0.8 * np.exp(-((R - 0.86) / 0.02) ** 2) * (np.abs(ang - 0.5) < 0.07)  # 10 rune ticks outside the ring
    I += 0.5 * np.exp(-((R - 0.70) / 0.012) ** 2) * (np.abs(((np.arctan2(Y, X) / (2 * np.pi)) * 20 - 4 * t) % 1 - 0.5) < 0.22)
    I *= 0.85 + 0.15 * np.cos(2 * np.pi * t)
    return np.clip(I * 0.9, 0, 1) * (1 - smooth(0.88, 0.99, R))


EFFECTS = {"arcane_burst": (burst_frame, False), "ground_sigil": (sigil_frame, True)}


def build(name, g, frame, out):
    fn, loop = EFFECTS[name]
    n = frame * SS
    rng = np.random.default_rng(7)
    av = cv2.resize(rng.random((1, 48)).astype(np.float32), (96, 1), interpolation=cv2.INTER_CUBIC)[0]
    av = np.concatenate([av, av[:1]])
    ctx = {"grid": grid(n), "n0": fbm(11, n), "n1": fbm(23, n), "ax": np.linspace(0, 2 * np.pi, len(av)), "av": av,
           "sparks": [(np.array([np.cos(a), np.sin(a)], np.float32), rng.uniform(0.7, 1.35)) for a in rng.uniform(0, 2 * np.pi, 26)]}
    total = g * g
    sheet, mono = np.zeros((g * frame, g * frame, 4), np.float32), np.zeros((g * frame, g * frame, 4), np.float32)
    for i in range(total):
        t = i / total if loop else i / (total - 1)
        I = cv2.resize(fn(t, n, ctx), (frame, frame), interpolation=cv2.INTER_AREA)
        A = np.clip(I * 1.5, 0, 1) ** 0.8
        y, x = divmod(i, g)
        sl = (slice(y * frame, (y + 1) * frame), slice(x * frame, (x + 1) * frame))
        sheet[sl] = np.dstack([color(I), A])
        mono[sl] = np.dstack([np.ones((frame, frame, 3), np.float32), A])
    out.mkdir(parents=True, exist_ok=True)
    for arr, suffix in ((sheet, ""), (mono, "_mono")):
        Image.fromarray((arr * 255 + 0.5).astype(np.uint8), "RGBA").save(out / f"{name}_{g}x{g}{suffix}.png", optimize=True)
    print("wrote", out / f"{name}_{g}x{g}.png")


def verify(path, g, loop):
    im = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255.0
    f = im.shape[0] // g
    A = [im[(i // g) * f:(i // g + 1) * f, (i % g) * f:(i % g + 1) * f, 3] for i in range(g * g)]
    E = np.array([a.sum() for a in A])
    res, bad = {}, []
    res["frames"], res["frame_px"] = g * g, f
    edge = max(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()) for a in A)
    res["edge_alpha_max"] = round(float(edge), 4)
    if edge > 1 / 255:
        bad.append("alpha touches the cell edge (faint square haze)")
    res["peak_frame"] = int(E.argmax())
    res["peak_coverage_pct"] = round(float((A[int(E.argmax())] > 0.1).mean() * 100), 1)
    H = np.array([(a > 0.9).sum() for a in A], np.float32)
    hit = int(np.argmax(H > 0.5 * H.max())) if H.max() > 0 else 0
    res["hit_frame"] = hit
    d = np.abs(np.diff(E)) / max(E.max(), 1e-6)
    if not loop and hit > 0:
        d[hit - 1] = 0  # the hit onset is meant to be sharp
    res["max_energy_jump"] = round(float(d.max()), 3)
    if d.max() > 0.35:
        bad.append("energy jumps more than 35% of peak between two frames (stutter)")
    if loop:
        wrap = abs(E[0] - E[-1]) / max(E.max(), 1e-6)
        step = float(np.abs(np.diff(E)).mean()) / max(E.max(), 1e-6)
        pix = float(np.abs(A[0] - A[-1]).mean())
        step_pix = float(np.mean([np.abs(A[i] - A[i + 1]).mean() for i in range(len(A) - 1)]))
        res["loop_energy_gap"], res["loop_seam_vs_step"] = round(float(wrap), 3), round(pix / max(step_pix, 1e-9), 2)
        if wrap > 0.1 or pix > 1.6 * step_pix:
            bad.append("last frame jumps more than a normal step to the first (visible loop seam)")
    else:
        if not 3 <= hit <= g * g * 0.3:
            bad.append("hit is not early (should land in the first 30% of frames)")
        post = E[hit:]
        if post.max() > 0 and E[min(hit + 4, len(E) - 1)] > 1.6 * E[hit]:
            bad.append("effect keeps growing after the hit (flash should pop, then fall)")
        if E[-1] / E.max() > 0.03:
            bad.append("last frame still visible (effect should end clean)")
    res["verdict"] = "PASS" if not bad else "FAIL"
    res["problems"] = bad
    print(json.dumps(res, indent=1))
    return not bad


if __name__ == "__main__":
    a = sys.argv[1:]
    opt = lambda k, d: type(d)(a[a.index(k) + 1]) if k in a else d
    if a[0] == "build":
        build(a[1], opt("--grid", 8), opt("--frame", 128), Path(opt("--out", "VFX/flipbooks")))
    elif a[0] == "verify":
        sys.exit(0 if verify(a[1], opt("--grid", 8), "--loop" in a) else 1)
    elif a[0] == "verify-all":  # every non-mono sheet in a folder; loops are named *_loop, *sigil* or *aura*
        ok = True
        for f in sorted(Path(a[1]).glob("*_[0-9]x[0-9].png")):
            g = int(f.stem.rsplit("_", 1)[1][0])
            print("==", f.name)
            ok &= verify(str(f), g, any(k in f.stem for k in ("_loop", "sigil", "aura")))
        print("PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)
    else:
        sys.exit(__doc__)
