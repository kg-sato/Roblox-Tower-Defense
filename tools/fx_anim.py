"""Colour 2D effect animations rendered to Roblox flipbook sheets (8x8, 1024 px, RGBA, straight alpha).
Built to recreate reference sheets beat by beat; check against the reference with tools/sheet_compare.py.
  python -I tools/fx_anim.py <name> <out.png>        names: egg_hatch, coin_drop
Each animation is a function of t in [0, 1) that paints one 128 px cell with the primitives below. Beats and sizes come
from the measured reference timelines (see Roblox Dev/Research/VFX and Animation/1to1 notes). All art is original."""
import sys
import numpy as np
from PIL import Image

N = 128
TAU = 2 * np.pi
Y, X = (np.mgrid[0:N, 0:N].astype(np.float32) + 0.5) / N  # 0..1, y down


class Cell:
    def __init__(self):
        self.rgb = np.zeros((N, N, 3), np.float32); self.a = np.zeros((N, N), np.float32)

    def over(self, color, alpha):  # paint colour with coverage alpha (straight-alpha "over")
        alpha = np.clip(alpha, 0, 1); c = np.asarray(color, np.float32)
        na = alpha + self.a * (1 - alpha)
        self.rgb = np.where(na[..., None] > 1e-5, (c * alpha[..., None] + self.rgb * (self.a * (1 - alpha))[..., None]) / np.maximum(na, 1e-5)[..., None], self.rgb)
        self.a = na

    def add(self, color, alpha):  # additive glow: brightens colour and raises alpha
        alpha = np.clip(alpha, 0, 1); c = np.asarray(color, np.float32)
        self.rgb = np.clip(self.rgb * self.a[..., None] + c * alpha[..., None], 0, None) / np.maximum(np.clip(self.a + alpha, 1e-5, None), 1e-5)[..., None]
        self.rgb = np.clip(self.rgb, 0, 1); self.a = np.clip(self.a + alpha, 0, 1)


def soft(d, edge=0.006):  # signed distance (negative inside) to coverage
    return np.clip(0.5 - d / edge, 0, 1)


def ellipse_d(cx, cy, rx, ry):
    rx, ry = max(rx, 1e-4), max(ry, 1e-4)
    return (np.hypot((X - cx) / rx, (Y - cy) / ry) - 1) * min(rx, ry)


def seg_d(ax, ay, bx, by):
    abx, aby = bx - ax, by - ay
    t = np.clip(((X - ax) * abx + (Y - ay) * aby) / max(abx * abx + aby * aby, 1e-9), 0, 1)
    return np.hypot(X - ax - t * abx, Y - ay - t * aby)


def radial_glow(cell, color, cx, cy, r, k):
    cell.add(color, k * np.exp(-((X - cx) ** 2 + (Y - cy) ** 2) / (r * r)))


def star_d(cx, cy, r_in, r_out, points, rot=0.0):
    A = np.arctan2(Y - cy, X - cx) - rot; R = np.hypot(X - cx, Y - cy)
    f = np.abs(((A / TAU * points) % 1) - 0.5) * 2  # 1 at spike tips, 0 between
    return R - (r_in + (r_out - r_in) * f ** 1.6)


def ease_out(x):
    x = np.clip(x, 0, 1); return 1 - (1 - x) ** 3


def seg01(t, a, b):
    return float(np.clip((t - a) / (b - a), 0, 1))


# ---------------------------------------------------------------- egg hatch (reference: ParticleFX pet-egg-hatch, 2.4 s)
EGG = (0.45, 0.9, 1.0); EGG_LINE = (0.95, 0.8, 0.35); GOLD = (1.0, 0.86, 0.25); SHELL = (0.35, 0.68, 0.86)


def egg_hatch(t, rng):
    c = Cell(); f = t * 64
    if f < 35:  # egg: idle shine, cracks, swell and warm up
        sw = 1 + 0.35 * seg01(f, 14, 35) ** 2 + 0.02 * np.sin(f * 1.7) * seg01(f, 16, 35)
        rx, ry = 0.16 * sw, 0.2 * (1 + 0.15 * seg01(f, 26, 35))
        warm = seg01(f, 28, 35)
        radial_glow(c, GOLD, 0.5, 0.5, 0.18 + 0.12 * warm, 0.15 + 0.6 * seg01(f, 10, 35))
        d = ellipse_d(0.5, 0.5, rx, ry)
        c.over(EGG_LINE, soft(d))
        fill = tuple(np.array(EGG) * (1 - warm) + np.array((1, 0.97, 0.8)) * warm)
        c.over(fill, soft(d + 0.008))
        c.add((1, 1, 1), 0.35 * soft(ellipse_d(0.5 - rx * 0.25, 0.5 - ry * 0.3, rx * 0.45, ry * 0.4), 0.05))  # top-left sheen
        if 3 <= f <= 12:  # glint stripe sweeps across
            p = (f - 3) / 9
            c.add((1, 1, 1), 0.9 * soft(seg_d(0.5 + rx * (p - 0.9), 0.5 + ry * 0.4, 0.5 + rx * (p + 0.1), 0.5 - ry * 0.5) - 0.006) * soft(d + 0.012))
        n_cr = int(seg01(f, 15, 30) * 6)
        crng = np.random.default_rng(7)
        for k in range(6):  # lightning-shaped cracks grow from the centre
            pts = [(0.5, 0.5)]
            for _ in range(3):
                x0, y0 = pts[-1]; pts.append((x0 + crng.uniform(-0.05, 0.05), y0 + crng.uniform(-0.07, 0.07)))
            if k < n_cr:
                for (ax, ay), (bx, by) in zip(pts, pts[1:]):
                    c.add((1, 0.98, 0.7), soft(seg_d(ax, ay, bx, by) - 0.004) * soft(d + 0.012))
        return c
    if f < 46:  # burst: gold spiky star with white core, shards fly
        p = ease_out((f - 35) / 3)
        fade = 1 - seg01(f, 41, 46)
        radial_glow(c, (1, 0.9, 0.55), 0.5, 0.5, 0.3, 0.6 * fade)
        c.over(GOLD, soft(star_d(0.5, 0.5, 0.2 * p + 0.05, 0.37 * p + 0.06, 16, f * 0.05)) * fade)
        c.add((1, 1, 1), np.exp(-((X - 0.5) ** 2 + (Y - 0.5) ** 2) / (0.16 * p + 0.03) ** 2) * fade * (1 - 0.6 * seg01(f, 39, 45)))
    shards(c, f, rng)
    if f >= 46:
        radial_glow(c, (1, 0.85, 0.6), 0.5, 0.5, 0.1, 0.5 * (1 - seg01(f, 46, 60)))
    return c


def shards(c, f, rng):
    if f < 37 or f > 58:
        return
    r = np.random.default_rng(3)
    for k in range(22):
        a = r.uniform(0, TAU); v = r.uniform(0.32, 0.52); spin = r.uniform(-0.3, 0.3)
        tt = (f - 37) / 21
        x = 0.5 + np.cos(a) * v * ease_out(tt * 1.6) * 0.8
        y = 0.5 + np.sin(a) * v * ease_out(tt * 1.6) * 0.6 + 0.25 * tt * tt
        L = 0.045; ang = a + spin * f
        al = 1 - seg01(f, 50, 58)
        c.over(SHELL, al * soft(seg_d(x - np.cos(ang) * L, y - np.sin(ang) * L, x + np.cos(ang) * L, y + np.sin(ang) * L) - 0.009))


# ---------------------------------------------------------------- coin drop (reference: ParticleFX enemy-defeat-coin-drop, 1.3 s)
PUFF = (0.72, 0.66, 0.95); COIN = (1.0, 0.78, 0.18); COIN_RIM = (0.85, 0.5, 0.05)


def coin(c, x, y, s, a, turn):
    rx = s * (0.35 + 0.65 * abs(np.cos(turn)))
    d = ellipse_d(x, y, rx, s)
    c.over(COIN_RIM, a * soft(d)); c.over(COIN, a * soft(d + 0.006))
    c.add((1, 1, 0.85), a * 0.7 * soft(ellipse_d(x - rx * 0.3, y - s * 0.35, rx * 0.35, s * 0.25)))


def coin_drop(t, rng):
    c = Cell(); f = t * 64
    if f < 8:  # white spiky flash
        p = ease_out(f / 3); fade = 1 - seg01(f, 4, 8)
        radial_glow(c, (1, 1, 1), 0.48, 0.46, 0.2, 0.5 * fade)
        c.add((1, 1, 1), fade * soft(star_d(0.48, 0.46, 0.09 + 0.03 * p, 0.17 + 0.07 * p, 14, 0.2)))
    if 4 <= f < 44:  # puff: white-hot core, violet blobs, splits into two lobes, darkens and fades
        p = ease_out((f - 4) / 8); fade = 1 - seg01(f, 22, 44); dark = seg01(f, 16, 34); split = seg01(f, 16, 36)
        r = np.random.default_rng(11)
        col = tuple(np.array(PUFF) * (1 - 0.3 * dark))
        for k in range(9):
            a = k / 9 * TAU + 0.4; side = 1 if np.cos(a) > 0 else -1
            dist = 0.1 * p + 0.03 * split
            bx = 0.48 + np.cos(a) * dist + side * 0.06 * split; by = 0.47 + np.sin(a) * dist * 0.8
            br = (0.085 + 0.025 * r.uniform()) * p * (1 - 0.2 * split)
            c.over(col, 0.8 * fade * soft(ellipse_d(bx, by, br, br * 0.9), 0.03))
        c.add((1, 1, 1), 1.0 * fade * (1 - dark) * np.exp(-((X - 0.48) ** 2 + (Y - 0.46) ** 2) / (0.15 * p + 1e-3) ** 2))
    # coins: pop high out of the puff, arc wide, land at y 0.75 near frame 37, settle, fade at the end
    r = np.random.default_rng(5)
    for k in range(6):
        t0 = 8 + k * 1.6; side = 1 if k % 2 else -1
        vx = side * r.uniform(0.005, 0.013); vy = -r.uniform(0.036, 0.041); gy = 0.0016
        if f < t0:
            continue
        s = f - t0; x = 0.49 + vx * s; y = 0.35 + vy * s + gy * s * s
        if y > 0.75:
            tl = (-vy + np.sqrt(vy * vy + 4 * gy * 0.4)) / (2 * gy)
            sb = s - tl; y = 0.75 - max(0.0, 0.012 * sb - 0.0011 * sb * sb); x = 0.49 + vx * tl + vx * 0.3 * sb
        a = 1 - seg01(f, 54, 63)
        coin(c, x, y, 0.04, a, s * 0.5 + k)
    return c


def render(fn, out):
    rng = np.random.default_rng(1)
    sheet = np.zeros((8 * N, 8 * N, 4), np.float32)
    for i in range(64):
        cell = fn(i / 64, rng)
        r, col = divmod(i, 8)
        sheet[r * N:(r + 1) * N, col * N:(col + 1) * N] = np.dstack([cell.rgb, cell.a])
    Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8), "RGBA").save(out)


if __name__ == "__main__":
    render({"egg_hatch": egg_hatch, "coin_drop": coin_drop}[sys.argv[1]], sys.argv[2])
    print("wrote", sys.argv[2])
