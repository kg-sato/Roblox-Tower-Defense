"""Crafted 2D effect frames for Roblox flipbooks (8x8 sheet, 1024 px, RGBA): the techniques hand-made effect sheets use,
as reusable layers. Replaces the flat-shape look of tools/fx_anim.py v1 (user feedback 2026-10-28: "low effort triangle").
Techniques (sources in Roblox Dev/Research/VFX and Animation/1to1/Crafted Sheet Techniques.md):
  - 2x supersampling and antialiased polygons (cv2), so edges stay crisp at 128 px per frame
  - Voronoi cracks: cells break open one by one, light shines through, chipped dark rims at the borders
  - noise erosion (dissolve): fbm noise against a rising threshold hollows a shape from the inside, with a hot edge
  - shaded crystal shards: two-tone prisms with an edge highlight, launched, tumbling, falling under gravity
  - uneven starbursts with an overexposed core; radial speed lines; twinkling dust specks; a lens streak
  - bloom on every frame: bright pixels blurred at two radii and added back as glow
  python -I tools/fx_craft.py <name> <out.png>     names: egg_hatch, coin_drop"""
import sys
import cv2
import numpy as np
from PIL import Image

S = 256          # working size of one frame (2x the 128 px cell)
TAU = 2 * np.pi
YY, XX = (np.mgrid[0:S, 0:S].astype(np.float32) + 0.5) / S


# ------------------------------------------------------------------------------------------------ canvas and layers
class Frame:
    """Premultiplied RGBA canvas in 0..1 frame units (x right, y down)."""
    def __init__(self):
        self.c = np.zeros((S, S, 3), np.float32)  # premultiplied colour
        self.a = np.zeros((S, S), np.float32)

    def over(self, color, cov):
        cov = np.clip(cov, 0, 1)[..., None]; col = np.asarray(color, np.float32)
        self.c = col * cov + self.c * (1 - cov); self.a = cov[..., 0] + self.a * (1 - cov[..., 0])

    def add(self, color, amt):  # additive light; alpha grows with brightness so it shows on dark and light backgrounds
        amt = np.clip(amt, 0, None)[..., None]; col = np.asarray(color, np.float32)
        self.c = self.c + col * amt
        self.a = np.clip(self.a + amt[..., 0] * float(max(col)), 0, 1)

    def bloom(self, threshold=0.55, strength=0.7):
        lum = (self.c * [0.3, 0.59, 0.11]).sum(2)
        bright = self.c * np.clip((lum - threshold) / (1 - threshold), 0, 1)[..., None]
        glow = 0.6 * cv2.GaussianBlur(bright, (0, 0), S * 0.02) + 0.4 * cv2.GaussianBlur(bright, (0, 0), S * 0.06)
        self.c += glow * strength
        self.a = np.clip(self.a + (glow * strength).max(2), 0, 1)

    def rgba(self):
        a = np.clip(self.a, 0, 1)
        rgb = np.where(a[..., None] > 1e-4, self.c / np.maximum(a, 1e-4)[..., None], 0)
        m = np.maximum(rgb.max(2, keepdims=True), 1.0)  # overexposed light: keep the hue, push toward white
        rgb = rgb / m + (1 - 1 / m) * 0.9
        out = np.dstack([np.clip(rgb, 0, 1), a])
        return cv2.resize(out, (S // 2, S // 2), interpolation=cv2.INTER_AREA)


def mask_poly(pts):
    m = np.zeros((S, S), np.uint8)
    p = (np.asarray(pts, np.float32) * S * 16).astype(np.int32)
    cv2.fillPoly(m, [p], 255, lineType=cv2.LINE_AA, shift=4)
    return m.astype(np.float32) / 255


def mask_line(p0, p1, width):
    m = np.zeros((S, S), np.uint8)
    a = (np.asarray(p0) * S * 16).astype(int); b = (np.asarray(p1) * S * 16).astype(int)
    cv2.line(m, tuple(a), tuple(b), 255, max(1, int(width * S)), lineType=cv2.LINE_AA, shift=4)
    return m.astype(np.float32) / 255


def gauss(cx, cy, r):
    return np.exp(-((XX - cx) ** 2 + (YY - cy) ** 2) / (r * r))


def fbm(seed, octaves=4, base=4):
    rng = np.random.default_rng(int(seed)); n = np.zeros((S, S), np.float32); amp, tot = 1.0, 0.0
    for o in range(octaves):
        g = base * 2 ** o
        n += amp * cv2.resize(rng.random((g, g)).astype(np.float32), (S, S), interpolation=cv2.INTER_CUBIC); tot += amp; amp *= 0.5
    n /= tot
    return (n - n.min()) / (n.max() - n.min() + 1e-6)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)


def ease_out(x):
    x = min(max(x, 0.0), 1.0); return 1 - (1 - x) ** 3


def seg(f, a, b):
    return min(max((f - a) / (b - a), 0.0), 1.0)


def ellipse_pts(cx, cy, rx, ry, rot=0.0, n=64):
    a = np.linspace(0, TAU, n, endpoint=False)
    x, y = rx * np.cos(a), ry * np.sin(a)
    return np.stack([cx + x * np.cos(rot) - y * np.sin(rot), cy + x * np.sin(rot) + y * np.cos(rot)], 1)


def voronoi(cx, cy, rx, ry, seed, n=14):
    """Cell id and distance-to-border fields inside an ellipse; returns (cell, border, seeds)."""
    rng = np.random.default_rng(seed)
    pts = []
    while len(pts) < n:
        p = rng.uniform(-1, 1, 2)
        if p @ p < 1: pts.append(p)
    pts = np.array(pts); sx, sy = cx + pts[:, 0] * rx, cy + pts[:, 1] * ry
    d = np.stack([np.hypot(XX - x, YY - y) for x, y in zip(sx, sy)])
    order = np.argsort(d, 0)
    d1 = np.take_along_axis(d, order[:1], 0)[0]; d2 = np.take_along_axis(d, order[1:2], 0)[0]
    return order[0], d2 - d1, np.stack([sx, sy], 1)


def starburst(fr, cx, cy, r_in, r_out, spikes, seed, color, rot=0.0, cov=1.0):
    rng = np.random.default_rng(seed)
    lens = rng.uniform(0.6, 1.0, spikes)
    pts = []
    for k in range(spikes):
        a0 = rot + k / spikes * TAU
        pts.append((cx + np.cos(a0) * r_out * lens[k], cy + np.sin(a0) * r_out * lens[k]))
        a1 = a0 + TAU / spikes / 2
        pts.append((cx + np.cos(a1) * r_in, cy + np.sin(a1) * r_in))
    m = mask_poly(pts)
    fr.over(color, m * cov)
    return m


def shard(fr, x, y, ang, length, width, light, dark, cov):
    """Crystal prism: a pointed hexagon split along its length, light half and dark half, white edge."""
    c, s = np.cos(ang), np.sin(ang)
    def P(u, v): return (x + c * u - s * v, y + s * u + c * v)
    hl, hw = length / 2, width / 2
    top = [P(-hl, 0), P(-hl * 0.6, -hw), P(hl * 0.6, -hw), P(hl, 0)]
    bot = [P(hl, 0), P(hl * 0.6, hw), P(-hl * 0.6, hw), P(-hl, 0)]
    fr.over(light, mask_poly(top) * cov); fr.over(dark, mask_poly(bot) * cov)
    fr.add((0.9, 1, 1), mask_line(P(-hl * 0.6, -hw), P(hl * 0.6, -hw), 0.004) * cov * 0.5)


# ------------------------------------------------------------------------------------------------ egg hatch
CYAN, CYAN_D, RIM = (0.45, 0.88, 1.0), (0.2, 0.62, 0.9), (1.0, 0.82, 0.35)
GOLD, AMBER = (1.0, 0.82, 0.25), (0.85, 0.5, 0.12)
SH_L, SH_D = (0.62, 0.9, 1.0), (0.25, 0.55, 0.85)


def egg_hatch(f):
    fr = Frame(); cx, cy = 0.5, 0.5
    if f < 36:
        swell = 1 + 0.12 * seg(f, 26, 35) ** 2
        wob = 0.07 * np.sin(f * 1.9) * seg(f, 16, 34)
        rx, ry = 0.15 * swell, 0.19 * swell
        heat = seg(f, 27, 35)
        fr.add(GOLD, gauss(cx, cy, 0.2 + 0.1 * heat) * (0.12 + 0.5 * seg(f, 10, 35)))
        outline = mask_poly(ellipse_pts(cx, cy, rx + 0.012, ry + 0.012, wob))
        body = mask_poly(ellipse_pts(cx, cy, rx, ry, wob))
        fr.over(RIM, outline)
        # body: vertical gradient, darker lower-right inner shadow, sheen; warms to white near the burst
        shade = np.clip(0.5 + (YY - cy) / ry * 0.5 + (XX - cx) / rx * 0.2, 0, 1)[..., None]
        col = np.asarray(CYAN) * (1 - shade * 0.45) + np.asarray(CYAN_D) * shade * 0.45
        col = col * (1 - 0.7 * heat) + np.asarray((1, 0.95, 0.75)) * 0.7 * heat
        fr.c = fr.c * (1 - body[..., None]) + col * body[..., None]; fr.a = np.maximum(fr.a, body)
        fr.add((1, 1, 1), mask_poly(ellipse_pts(cx - rx * 0.3, cy - ry * 0.4, rx * 0.35, ry * 0.22, wob - 0.5)) * 0.35 * body)
        if 3 <= f <= 12:  # glint band sweep
            p = (f - 3) / 9; band = np.exp(-(((XX - cx) * 0.7 + (YY - cy) * 0.7) - (p * 2 - 1) * rx * 1.4) ** 2 / 0.0006)
            fr.add((1, 1, 1), band * body * 0.8)
        if f >= 14:  # Voronoi cracks: cells open from the top-left, light through, chipped rims
            cell, border, seeds = voronoi(cx, cy, rx, ry, 21, 16)
            open_n = int(9 * seg(f, 14, 34) ** 1.6)  # sparse fissures like the reference, not a tiled shell
            order = np.argsort(np.hypot(seeds[:, 0] - (cx - rx * 0.4), seeds[:, 1] - (cy - ry * 0.3)))
            opened = np.isin(cell, order[:open_n])
            noise = fbm(f // 2 + 3, 3, 6)
            hole = opened & (border > 0.012 + 0.016 * noise) & (body > 0.5)
            rim_px = opened & (border <= 0.012 + 0.016 * noise) & (border > 0.004) & (body > 0.5)
            fr.over((0.45, 0.25, 0.08), rim_px.astype(np.float32) * 0.9)
            fr.add((1, 0.8, 0.35), hole.astype(np.float32) * (0.65 + 0.3 * heat))
        if f >= 22:  # speed lines flicker around the shaking egg
            rng = np.random.default_rng(int(f) * 7)
            for _ in range(10):
                a = rng.uniform(0, TAU); r0 = rng.uniform(0.25, 0.3); L = rng.uniform(0.04, 0.08)
                fr.add((1, 0.95, 0.75), mask_line((cx + np.cos(a) * r0, cy + np.sin(a) * r0), (cx + np.cos(a) * (r0 + L), cy + np.sin(a) * (r0 + L)), 0.006) * 0.7 * seg(f, 22, 30))
        fr.bloom(0.65, 0.35 + 0.5 * heat)
        return fr
    # burst
    p = ease_out((f - 35) / 3)
    fade = 1 - seg(f, 44, 52)
    if f < 52:
        hollow = seg(f, 40, 50)
        st = Frame()  # star layers on their own canvas so erosion cuts only them, not the glow
        star = starburst(st, cx, cy, 0.15 * p + 0.04, 0.36 * p + 0.06, 22, 9, GOLD, rot=0.02 * f)
        inner = starburst(Frame(), cx, cy, 0.08 * p + 0.03, 0.22 * p + 0.04, 22, 9, (1, 1, 1), rot=0.02 * f)
        st.add((1, 0.95, 0.75), inner * 0.8 * (1 - hollow))
        st.add((1, 1, 1), gauss(cx, cy, 0.1 * p + 0.03) * 1.2 * (1 - hollow))
        if hollow > 0:  # noise erosion from the centre: the star becomes a hot-edged ring, then gone
            n = fbm(5, 4, 5); rr = np.hypot(XX - cx, YY - cy) / 0.42 + 0.35 * (n - 0.5)
            th = hollow * 1.15
            keep = smooth(th - 0.04, th + 0.04, rr)
            st.c *= keep[..., None]; st.a *= keep
            st.add(AMBER, np.exp(-(rr - th) ** 2 / 0.002) * star * 0.9)
        fr.add((1, 0.88, 0.55), gauss(cx, cy, 0.34) * 0.55 * fade)
        fr.c = st.c * fade + fr.c * (1 - st.a[..., None] * fade); fr.a = st.a * fade + fr.a * (1 - st.a * fade)
    if 40 <= f < 47:  # lens streak
        k = 1 - seg(f, 40, 47)
        fr.add((1, 0.95, 0.8), mask_line((0.12, 0.72), (0.88, 0.28), 0.006) * k * 0.9)
    if 36 <= f < 60:  # shards
        rng = np.random.default_rng(4)
        for i in range(24):
            a = rng.uniform(0, TAU); v = rng.uniform(0.3, 0.5); spin = rng.uniform(-0.25, 0.25); L = rng.uniform(0.05, 0.085)
            t = (f - 36) / 24
            x = cx + np.cos(a) * v * ease_out(t * 1.7) * 0.85
            y = cy + np.sin(a) * v * ease_out(t * 1.7) * 0.7 + 0.22 * t * t
            cov = 1 - seg(f, 52, 60)
            shard(fr, x, y, a + spin * (f - 36), L, L * 0.38, SH_L, SH_D, cov)
    if 38 <= f < 58:  # dust specks
        rng = np.random.default_rng(12)
        for i in range(30):
            a = rng.uniform(0, TAU); v = rng.uniform(0.1, 0.4); tw = 0.5 + 0.5 * np.sin(f * 1.3 + i)
            t = (f - 38) / 20
            x, y = cx + np.cos(a) * v * ease_out(t), cy + np.sin(a) * v * ease_out(t) + 0.05 * t
            fr.add(GOLD, gauss(x, y, 0.006) * tw * (1 - t))
    if f >= 46:
        fr.add((1, 0.85, 0.6), gauss(cx, cy, 0.1) * 0.45 * (1 - seg(f, 46, 61)))
    fr.bloom(0.7, 0.45 * fade + 0.15)
    return fr


# ------------------------------------------------------------------------------------------------ coin drop
PUFF_L, PUFF_D = (0.86, 0.82, 1.0), (0.5, 0.44, 0.75)
COIN_F, COIN_E, COIN_D = (1.0, 0.82, 0.25), (0.95, 0.6, 0.1), (0.6, 0.32, 0.05)


def coin(fr, x, y, s, turn, cov):
    w = abs(np.cos(turn)); rx = s * (0.25 + 0.75 * w)
    fr.over(COIN_D, mask_poly(ellipse_pts(x + s * 0.12 * np.sign(np.cos(turn)) * (1 - w), y, rx, s)) * cov)  # coin edge
    fr.over(COIN_E, mask_poly(ellipse_pts(x, y, rx, s)) * cov)
    fr.over(COIN_F, mask_poly(ellipse_pts(x, y, rx * 0.78, s * 0.78)) * cov)
    fr.add((1, 1, 0.9), gauss(x - rx * 0.3, y - s * 0.35, s * 0.3) * 0.8 * cov)


def puff(fr, cx, cy, r, f, seed, light, dark, cov):
    """Cartoon smoke: lumpy noise-edged blob, lit top-left, eroding as it fades."""
    r = max(r, 1e-3)
    n = fbm(seed + int(f // 3), 4, 5)
    d = np.hypot((XX - cx) / r, (YY - cy) / (r * 0.85)) + 0.6 * (n - 0.5)
    body = smooth(1.1, 0.7, d) * (0.45 + 0.55 * fbm(seed + 50 + int(f // 2), 3, 8))  # wispy: noisy edge and see-through inside
    lit = np.clip(0.55 - ((XX - cx) + (YY - cy)) / r * 0.5, 0, 1)[..., None]
    col = np.asarray(dark) * (1 - lit) + np.asarray(light) * lit
    erode = smooth((1 - cov) - 0.08, (1 - cov) + 0.08, n)  # dissolve with noise instead of a flat fade; cov 1 keeps all
    m = body * erode
    fr.c = fr.c * (1 - m[..., None]) + col * m[..., None]; fr.a = m + fr.a * (1 - m)


def coin_drop(f):
    fr = Frame(); cx, cy = 0.48, 0.46
    if f < 8:  # flash: uneven white star plus bloom
        p = ease_out(f / 3); k = 1 - seg(f, 4, 8)
        fr.add((1, 1, 1), gauss(cx, cy, 0.18) * 0.6 * k)
        m = starburst(Frame(), cx, cy, 0.08 + 0.03 * p, 0.2 + 0.08 * p, 14, 3, (1, 1, 1), 0.2)
        fr.add((1, 1, 1), m * k)
    if 4 <= f < 44:  # puff lobes; the middle splits and drifts apart
        p = ease_out((f - 4) / 8); split = seg(f, 16, 36); life = 1 - seg(f, 20, 38)
        for k, (ox, oy, rs) in enumerate([(-0.08, 0.0, 0.14), (0.08, 0.01, 0.14), (0, -0.06, 0.15), (-0.04, 0.06, 0.12), (0.05, 0.07, 0.12)]):
            puff(fr, cx + ox * (p + split * 1.2), cy - 0.03 + oy * p - 0.02 * split, rs * p * (1 + 0.2 * split), f, 30 + k, PUFF_L, PUFF_D, 0.15 + 0.85 * life)
        fr.add((1, 1, 1), gauss(cx, cy, 0.12 * p + 0.01) * 1.4 * (1 - seg(f, 8, 22)))
        if f < 22:  # sparks shoot up from the puff
            rng = np.random.default_rng(2)
            for i in range(8):
                a = -np.pi / 2 + rng.uniform(-0.9, 0.9); v = rng.uniform(0.15, 0.3) * ease_out((f - 4) / 10)
                x0, y0 = cx + np.cos(a) * v, cy + np.sin(a) * v
                fr.add((1, 1, 0.95), mask_line((x0, y0), (x0 - np.cos(a) * 0.04, y0 - np.sin(a) * 0.04), 0.005) * (1 - seg(f, 12, 22)))
    rng = np.random.default_rng(5)
    for k in range(6):  # coins pop high, spin, arc wide, land and settle
        t0 = 8 + k * 1.6; side = 1 if k % 2 else -1
        vx = side * rng.uniform(0.005, 0.013); vy = -rng.uniform(0.036, 0.041); gy = 0.0016
        if f < t0:
            continue
        s = f - t0; x = 0.49 + vx * s; y = 0.35 + vy * s + gy * s * s; spin = s * 0.45 + k
        if y > 0.75:
            tl = (-vy + np.sqrt(vy * vy + 4 * gy * 0.4)) / (2 * gy); sb = s - tl
            y = 0.75 - max(0.0, 0.012 * sb - 0.0011 * sb * sb); x = 0.49 + vx * tl + vx * 0.3 * sb; spin = tl * 0.45 + k
        coin(fr, x, y, 0.042, spin, 1 - seg(f, 54, 63))
    fr.bloom(0.65, 0.5)
    return fr


def render(fn, out):
    sheet = np.zeros((1024, 1024, 4), np.float32)
    for i in range(64):
        r, c = divmod(i, 8)
        sheet[r * 128:(r + 1) * 128, c * 128:(c + 1) * 128] = fn(float(i)).rgba()
    Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8), "RGBA").save(out)


if __name__ == "__main__":
    render({"egg_hatch": egg_hatch, "coin_drop": coin_drop}[sys.argv[1]], sys.argv[2])
    print("wrote", sys.argv[2])
