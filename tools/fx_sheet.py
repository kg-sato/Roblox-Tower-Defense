"""Procedural flipbook sheets for Roblox ParticleEmitter / UI flipbooks. Local only, original art, no downloads.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_sheet.py build <effect> [--grid 8] [--frame 128] [--out VFX/flipbooks]
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_sheet.py verify <sheet.png> [--loop] [--grid 8]
Effects: see EFFECTS (one-shots and seamless loops). build-all writes every sheet.
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


GOLD = [(0.0, (90, 50, 10)), (0.4, (220, 150, 40)), (0.75, (255, 220, 120)), (1.0, (255, 255, 240))]
CYAN = [(0.0, (10, 40, 90)), (0.4, (40, 160, 230)), (0.75, (150, 230, 255)), (1.0, (245, 255, 255))]
GREEN = [(0.0, (10, 60, 20)), (0.4, (60, 200, 90)), (0.75, (170, 255, 170)), (1.0, (245, 255, 240))]
FROST = [(0.0, (20, 40, 100)), (0.4, (80, 150, 240)), (0.75, (180, 225, 255)), (1.0, (250, 255, 255))]
SMOKE = [(0.0, (40, 36, 48)), (0.5, (110, 104, 120)), (1.0, (200, 196, 210))]


def color(I, ramp=RAMP):
    xs = [s for s, _ in ramp]
    return np.stack([np.interp(I, xs, [c[i] for _, c in ramp]) for i in range(3)], -1).astype(np.float32) / 255.0


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


def gauss(d, w):
    return np.exp(-(d / w) ** 2)


def edge(R, a=0.80, b=0.97):
    return 1 - smooth(a, b, R)


def ease_out(x):
    return 1 - (1 - x) ** 3


def phases(t, hit):
    """One-shot timing: (p, None) while charging (p 0..1), (None, k) after the hit (k 0..1)."""
    return (t / hit, None) if t < hit else (None, (t - hit) / (1 - hit))


def rot(X, Y, a):
    c, s = np.cos(a), np.sin(a)
    return X * c + Y * s, -X * s + Y * c


def star4(X, Y, w, L):
    """Four-point twinkle centred on the origin."""
    return gauss(np.abs(X), w) * gauss(Y, L) + gauss(np.abs(Y), w) * gauss(X, L) + gauss(np.hypot(X, Y), w * 2.5)


def flash_frame(t, n, ctx):  # hit flash: a star pops, spikes shoot out and the core blooms away
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.2)
    if k is None:
        return np.clip(gauss(R, 0.04 + 0.06 * p) * 0.5 * p, 0, 1) * edge(R)
    a = np.exp(-k * 3.5) * (1 - k)
    Xd, Yd = rot(X, Y, np.pi / 4)
    spikes = star4(X, Y, 0.025, 0.55 + 0.3 * k) * (1 - k) + 0.45 * star4(Xd, Yd, 0.02, 0.3 + 0.2 * k) * (1 - k)
    I = (gauss(R, 0.10 + 0.25 * k) * 1.2 + spikes * 0.9) * a
    return np.clip(I, 0, 1) * edge(R)


def slash_frame(t, n, ctx):  # slash arc: a crescent is drawn fast, then thins and erases from its tail
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.2)
    start, full = np.pi * 0.95, np.pi * 1.1
    a = (start - TH) % (2 * np.pi)  # angle travelled clockwise from the start
    if k is None:
        lo, hi, w, amp = 0.0, full * p, 0.05, 0.45
    else:
        lo, hi, w, amp = full * ease_out(k), full, 0.07 * (1 - k) + 0.008, (1 - k) ** 1.4
    span = np.clip((a - lo) / max(hi - lo, 1e-4), 0, 1)
    inside = smooth(lo - 0.05, lo + 0.05, a) * (1 - smooth(hi - 0.02, hi + 0.08, a))
    taper = np.clip(np.sin(np.pi * span), 0, 1) ** 0.6  # float sin(pi) can dip below 0 and give NaN
    I = (gauss(R - 0.6, w * taper + 1e-3) + 0.35 * gauss(R - 0.6, (w * 3 + 0.02))) * inside * amp
    return np.clip(I * 1.2, 0, 1) * edge(R)


def shock_frame(t, n, ctx):  # shockwave ring: a dot charges, pops, and a thinning ring races out
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.1)
    if k is None:
        return np.clip(gauss(R, 0.03 + 0.05 * p) * 0.5 * p, 0, 1) * edge(R)
    r, w = 0.1 + 0.78 * ease_out(k), 0.07 * (1 - k) + 0.01
    I = gauss(R, 0.2 * (1 - k) + 0.02) * np.exp(-k * 10) * 1.3
    I += gauss(R - r, w) * (1 - k) ** 1.5 + 0.4 * gauss(R - r * 0.7, w * 1.5) * (1 - k) ** 2
    return np.clip(I, 0, 1) * edge(R, 0.85, 0.98)


def hex_sigil_frame(t, n, ctx):  # ground sigil variant: hexagram + 12 ticks, 60 degrees per loop (seamless)
    X, Y, R, TH = ctx["grid"]
    Xr, Yr = rot(X, Y, 2 * np.pi / 6 * t)
    I = gauss(R - 0.80, 0.014) + 0.25 * gauss(R - 0.80, 0.07) + 0.7 * gauss(R - 0.64, 0.01)
    pts = [(0.64 * np.cos(2 * np.pi * i / 6), 0.64 * np.sin(2 * np.pi * i / 6)) for i in range(6)]
    for i in range(6):  # two triangles
        a, b = pts[i], pts[(i + 2) % 6]
        I += 0.85 * gauss(seg_dist(Xr, Yr, a, b), 0.011) + 0.2 * gauss(seg_dist(Xr, Yr, a, b), 0.045)
    ang = (np.arctan2(Yr, Xr) % (2 * np.pi)) / (2 * np.pi) * 12 % 1
    I += 0.8 * gauss(R - 0.88, 0.02) * (np.abs(ang - 0.5) < 0.08)
    I += 0.6 * gauss(R, 0.08)
    I *= 0.85 + 0.15 * np.cos(2 * np.pi * t)
    return np.clip(I * 0.9, 0, 1) * edge(R, 0.9, 0.99)


def frost_sigil_frame(t, n, ctx):  # ground sigil variant: six-armed snowflake inside a ring, 60 degrees per loop
    X, Y, R, TH = ctx["grid"]
    Xr, Yr = rot(X, Y, 2 * np.pi / 6 * t)
    I = gauss(R - 0.82, 0.012) + 0.25 * gauss(R - 0.82, 0.06)
    for i in range(6):
        a = 2 * np.pi * i / 6
        d = np.array([np.cos(a), np.sin(a)])
        I += 0.9 * gauss(seg_dist(Xr, Yr, d * 0.08, d * 0.7), 0.012)
        for f in (0.35, 0.55):  # side branches
            for s in (1, -1):
                b = np.array([np.cos(a + s * 0.6), np.sin(a + s * 0.6)])
                I += 0.6 * gauss(seg_dist(Xr, Yr, d * f, d * f + b * 0.14), 0.01)
        I += 0.8 * gauss(np.hypot(Xr - d[0] * 0.82, Yr - d[1] * 0.82), 0.03)
    I *= 0.85 + 0.15 * np.cos(2 * np.pi * t)
    return np.clip(I * 0.9, 0, 1) * edge(R, 0.9, 0.99)


def beam_frame(t, n, ctx):  # loot beam column: bands climb one period per loop, soft base ring, gentle pulse
    X, Y, R, TH = ctx["grid"]
    vert = smooth(-0.85, -0.55, Y) * (1 - smooth(0.4, 0.9, Y))
    bands = 0.5 + 0.5 * np.cos(2 * np.pi * (Y * 1.5 - t))
    I = (gauss(X, 0.05) * 1.1 + gauss(X, 0.17) * (0.25 + 0.3 * bands)) * vert
    I += 0.8 * gauss(np.hypot(X, (Y + 0.68) * 3.2) - 0.32, 0.035)
    I *= 0.9 + 0.1 * np.cos(2 * np.pi * t)
    return np.clip(I, 0, 1) * edge(R, 0.85, 0.98)


def wisps_frame(t, n, ctx):  # aura wisps loop: six wisps orbit with short tails, one wisp spacing per loop
    X, Y, R, TH = ctx["grid"]
    I = 0.22 * gauss(R - 0.5, 0.18)
    for j in range(6):
        phi = 2 * np.pi * j / 6 + 2 * np.pi * t / 6
        r = 0.55 + 0.05 * np.sin(3 * phi + 2 * np.pi * t)  # tied to the wisp's angle so wisp j at t=1 matches wisp j+1 at t=0
        da = (TH - phi + np.pi) % (2 * np.pi) - np.pi  # angle from the wisp head, negative = behind
        tail = np.where(da < 0, np.exp(da / 0.45), np.exp(-(da / 0.05) ** 2))
        I += gauss(R - r, 0.035) * tail * 0.95
    return np.clip(I, 0, 1) * edge(R, 0.85, 0.98)


def sparkle_frame(t, n, ctx, diamond=False):  # coin / gem sparkle: one big glint pops, small glints twinkle after
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.12)
    shape = (lambda x, y, w, L: star4(*rot(x, y, np.pi / 4), w, L)) if diamond else star4
    if k is None:
        I = gauss(R, 0.03 + 0.05 * p) * 0.5 * p
    else:
        I = shape(X, Y, 0.03, 0.5 * (1 - 0.4 * k)) * np.exp(-k * 5) * (1 - k) * 1.3
        for (x, y), s0, size in ctx["glints"]:
            s = (k - s0) / 0.3
            if 0 < s < 1:
                I += shape(X - x, Y - y, 0.015, size) * np.sin(np.pi * s) * 0.7
    return np.clip(I, 0, 1) * edge(R)


def heal_frame(t, n, ctx):  # heal: a soft ring and a cross bloom, then little crosses rise and fade
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.12)

    def cross(x, y, w, L):
        return gauss(np.abs(x), w) * (1 - smooth(L * 0.8, L, np.abs(y))) + gauss(np.abs(y), w) * (1 - smooth(L * 0.8, L, np.abs(x)))

    if k is None:
        return np.clip(cross(X, Y, 0.03, 0.08 + 0.12 * p) * 0.5 * p, 0, 1) * edge(R)
    I = cross(X, Y, 0.05 * (1 - k) + 0.01, 0.22) * np.exp(-k * 4) * 1.2
    I += gauss(R - (0.3 + 0.4 * ease_out(k)), 0.05 * (1 - k) + 0.01) * (1 - k) ** 1.5 * 0.8
    for (x, y), s0, size in ctx["glints"][:6]:
        s = (k - s0 * 0.6) / 0.5
        if 0 < s < 1:
            I += cross(X - x * 0.6, Y - (y * 0.4 - 0.2 + 0.5 * s), 0.015, 0.06 + size * 0.1) * np.sin(np.pi * s) * 0.75
    return np.clip(I, 0, 1) * edge(R)


def nova_frame(t, n, ctx):  # frost nova: ring plus eight ice shards that shoot out and melt
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.1)
    if k is None:
        return np.clip(gauss(R, 0.03 + 0.06 * p) * 0.5 * p, 0, 1) * edge(R)
    r = 0.12 + 0.7 * ease_out(k)
    I = gauss(R, 0.22 * (1 - k) + 0.02) * np.exp(-k * 9) * 1.3
    I += gauss(R - r, 0.06 * (1 - k) + 0.01) * (1 - k) ** 1.6 * 0.9
    for i in range(8):
        a = 2 * np.pi * i / 8 + 0.2
        d = np.array([np.cos(a), np.sin(a)])
        L = 0.15 + 0.55 * ease_out(min(1, k * 1.6))
        dist = seg_dist(X, Y, d * 0.05, d * L)
        along = np.clip((X * d[0] + Y * d[1]) / L, 0, 1)
        I += gauss(dist, 0.03 * (1 - along) + 0.004) * (1 - k) ** 1.3 * 0.9
    return np.clip(I, 0, 1) * edge(R)


def smoke_frame(t, n, ctx):  # smoke puff (LightEmission 0): a dense puff that billows out and thins
    X, Y, R, TH = ctx["grid"]
    p, k = phases(t, 0.1)
    n0, n1 = ctx["n0"], ctx["n1"]
    if k is None:
        rad, dens = 0.1 + 0.2 * p, 0.55 * p
        noise = n0
    else:
        rad, dens = 0.3 + 0.38 * ease_out(k), (1 - k) ** 1.3
        noise = (1 - k) * n0 + k * n1
    body = 1 - smooth(rad * 0.55, rad, R + (noise - 0.5) * 0.25)
    I = body * (0.55 + 0.9 * (noise - 0.3)) * dens
    return np.clip(I * 1.25, 0, 1) * edge(R)


# name: (frame function, loop, colour ramp, grid). Loops are named *_loop, *sigil* or *aura* so verify-all knows them.
EFFECTS = {
    "arcane_burst": (burst_frame, False, RAMP, 8),
    "ground_sigil": (sigil_frame, True, RAMP, 8),
    "hit_flash": (flash_frame, False, GOLD, 4),
    "slash_arc": (slash_frame, False, RAMP, 4),
    "shockwave_ring": (shock_frame, False, RAMP, 8),
    "ground_sigil_hex": (hex_sigil_frame, True, GOLD, 8),
    "ground_sigil_frost": (frost_sigil_frame, True, FROST, 8),
    "loot_beam_loop": (beam_frame, True, GOLD, 8),
    "aura_wisps_loop": (wisps_frame, True, RAMP, 8),
    "coin_sparkle": (sparkle_frame, False, GOLD, 8),
    "gem_sparkle": (lambda t, n, ctx: sparkle_frame(t, n, ctx, True), False, CYAN, 8),
    "heal": (heal_frame, False, GREEN, 8),
    "frost_nova": (nova_frame, False, FROST, 8),
    "smoke_puff": (smoke_frame, False, SMOKE, 8),
}


def build(name, g, frame, out):
    fn, loop, ramp, gdef = EFFECTS[name]
    g = g or gdef
    n = frame * SS
    rng = np.random.default_rng(7)
    av = cv2.resize(rng.random((1, 48)).astype(np.float32), (96, 1), interpolation=cv2.INTER_CUBIC)[0]
    av = np.concatenate([av, av[:1]])
    ctx = {"grid": grid(n), "n0": fbm(11, n), "n1": fbm(23, n), "ax": np.linspace(0, 2 * np.pi, len(av)), "av": av,
           "sparks": [(np.array([np.cos(a), np.sin(a)], np.float32), rng.uniform(0.7, 1.35)) for a in rng.uniform(0, 2 * np.pi, 26)],
           "glints": [((rng.uniform(-0.55, 0.55), rng.uniform(-0.55, 0.55)), rng.uniform(0.05, 0.6), rng.uniform(0.12, 0.25)) for _ in range(8)]}
    total = g * g
    sheet, mono = np.zeros((g * frame, g * frame, 4), np.float32), np.zeros((g * frame, g * frame, 4), np.float32)
    for i in range(total):
        t = i / total if loop else i / (total - 1)
        I = cv2.resize(fn(t, n, ctx), (frame, frame), interpolation=cv2.INTER_AREA)
        A = np.clip(I * 1.5, 0, 1) ** 0.8
        y, x = divmod(i, g)
        sl = (slice(y * frame, (y + 1) * frame), slice(x * frame, (x + 1) * frame))
        sheet[sl] = np.dstack([color(I, ramp), A])
        mono[sl] = np.dstack([np.ones((frame, frame, 3), np.float32), A])
    out.mkdir(parents=True, exist_ok=True)
    for arr, suffix in ((sheet, ""), (mono, "_mono")):
        Image.fromarray((arr * 255 + 0.5).astype(np.uint8), "RGBA").save(out / f"{name}_{g}x{g}{suffix}.png", optimize=True)
    print("wrote", out / f"{name}_{g}x{g}.png")


def load_frames(path):
    """Cells of a sheet as float RGBA arrays, row by row; the grid comes from the file name (_8x8)."""
    g = int(Path(path).stem.split("_")[-1][0]) if "_mono" not in Path(path).stem else int(Path(path).stem.split("_")[-2][0])
    im = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255.0
    f = im.shape[0] // g
    return [im[(i // g) * f:(i // g + 1) * f, (i % g) * f:(i % g + 1) * f] for i in range(g * g)], g


def over(top, bottom):
    """Straight-alpha 'over' for two RGBA frames."""
    a = top[..., 3:4] + bottom[..., 3:4] * (1 - top[..., 3:4])
    rgb = (top[..., :3] * top[..., 3:4] + bottom[..., :3] * bottom[..., 3:4] * (1 - top[..., 3:4])) / np.maximum(a, 1e-6)
    return np.concatenate([rgb, a], -1)


# Layered effects: our procedural sheets stacked with the ingested CC0 layers (VFX/flipbooks/ul_*). Each layer is
# (sheet, start frame, alpha, envelope) and is drawn bottom first. Envelope "after" fades a loop layer in after the hit
# and out before the end so the stack still behaves as a one-shot; "full" keeps the layer as it is.
COMPOSITES = {
    "shockwave_smoke": [("ul_wispysmoke01_loop_8x8", 0, 0.55, "after"), ("shockwave_ring_8x8", 0, 1.0, "full")],
    "ember_burst": [("ul_flame03_loop_8x8", 0, 0.8, "after"), ("hit_flash_4x4", 0, 1.0, "stretch")],
    "ember_aura_loop": [("ul_flame03_loop_8x8", 0, 0.45, "full"), ("aura_wisps_loop_8x8", 0, 1.0, "full")],
}


def compose(name, out=Path("VFX/flipbooks")):
    layers = COMPOSITES[name]
    total = 64
    frames = [np.zeros((128, 128, 4), np.float32) for _ in range(total)]
    for sheet, start, alpha, env in layers:
        src, g = load_frames(out / f"{sheet}.png")
        for i in range(total):
            if env == "stretch":  # a 4x4 one-shot spread over the 64 frames
                j = min(int(i * len(src) / total), len(src) - 1)
            else:
                j = (i - start) % len(src)
            fr = src[j].copy()
            if fr.shape[0] != 128:
                fr = cv2.resize(fr, (128, 128), interpolation=cv2.INTER_AREA)
            k = i / (total - 1)
            e = 1.0
            if env == "after":
                e = smooth(0.2, 0.45, k) * (1 - smooth(0.65, 0.95, k))  # after the hit settles, gone before the end
            fr[..., 3] *= alpha * e
            frames[i] = over(fr, frames[i])
    g = 8
    sheet_arr = np.zeros((g * 128, g * 128, 4), np.float32)
    for i, fr in enumerate(frames):
        y, x = divmod(i, g)
        sheet_arr[y * 128:(y + 1) * 128, x * 128:(x + 1) * 128] = fr
    mono = sheet_arr.copy()
    mono[..., :3] = 1.0
    for arr, suffix in ((sheet_arr, ""), (mono, "_mono")):
        Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(out / f"{name}_{g}x{g}{suffix}.png", optimize=True)
    print("wrote", out / f"{name}_{g}x{g}.png")


RARITY_TINTS = {"Common": (200, 205, 215), "Rare": (80, 175, 255), "Epic": (186, 128, 255), "Legendary": (255, 208, 96), "Mythic": (255, 76, 90)}


def recolor_test(mono_path, out_png):
    """Runtime-style tint (Roblox multiplies the texture by ParticleEmitter.Color): one mono sheet, five rarity tints.
    Checks that the tinted mean colour over visible pixels equals the tint, and writes a strip of the peak frame."""
    frames, g = load_frames(mono_path)
    peak = max(range(len(frames)), key=lambda i: frames[i][..., 3].sum())
    fr = frames[peak]
    tiles, ok = [], True
    for name, rgb in RARITY_TINTS.items():
        tint = np.array(rgb, np.float32) / 255.0
        t = fr.copy()
        t[..., :3] *= tint
        vis = t[..., 3] > 0.2
        mean = t[..., :3][vis].mean(0)
        err = float(np.abs(mean - tint * fr[..., :3][vis].mean(0)).max())
        ok &= err < 2 / 255
        bg = np.zeros_like(t)
        bg[..., :3], bg[..., 3] = (0.07, 0.06, 0.11), 1.0
        tiles.append(over(t, bg))
        print(f"{name:10s} tint {rgb} mean {tuple(int(v * 255) for v in mean)} error {err * 255:.2f}/255")
    strip = np.concatenate(tiles, 1)
    Image.fromarray((np.clip(strip, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(out_png)
    print("recolor test", "PASS" if ok else "FAIL", "->", out_png)
    return ok


def contact(folder, out_png, cols=8):
    """One row per effect (every 8th frame of an 8x8 sheet, every 2nd of a 4x4) on a dark background, with its name."""
    from PIL import ImageDraw
    sheets = sorted(f for f in Path(folder).glob("*_[0-9]x[0-9].png"))
    cell, label = 96, 210
    img = Image.new("RGB", (label + cols * cell, len(sheets) * cell), (18, 16, 28))
    d = ImageDraw.Draw(img)
    for r, f in enumerate(sheets):
        frames, g = load_frames(f)
        step = max(1, len(frames) // cols)
        d.text((8, r * cell + cell // 2 - 6), f.stem, fill=(220, 215, 235))
        for c in range(cols):
            fr = frames[min(c * step, len(frames) - 1)]
            tile = Image.fromarray((np.clip(fr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((cell, cell))
            bg = Image.new("RGBA", (cell, cell), (18, 16, 28, 255))
            bg.alpha_composite(tile)
            img.paste(bg.convert("RGB"), (label + c * cell, r * cell))
    img.save(out_png)
    print("contact sheet", len(sheets), "effects ->", out_png)


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
        build(a[1], opt("--grid", 0), opt("--frame", 128), Path(opt("--out", "VFX/flipbooks")))
    elif a[0] == "compose":  # compose <name> | compose all
        for name in (COMPOSITES if a[1] == "all" else [a[1]]):
            compose(name)
    elif a[0] == "recolor-test":  # recolor-test <mono sheet> <out.png>
        sys.exit(0 if recolor_test(a[1], a[2]) else 1)
    elif a[0] == "contact":  # contact <folder> <out.png>
        contact(a[1], a[2])
    elif a[0] == "build-all":
        for name in EFFECTS:
            build(name, 0, opt("--frame", 128), Path(opt("--out", "VFX/flipbooks")))
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
