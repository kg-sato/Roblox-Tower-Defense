"""Crafted 2D effect frames for Roblox flipbooks (8x8 sheet, 1024 px, RGBA): the techniques hand-made effect sheets use,
as reusable layers. Replaces the flat-shape look of tools/fx_anim.py v1 (user feedback 2026-10-28: "low effort triangle").
Techniques (sources in Roblox Dev/Research/VFX and Animation/1to1/Crafted Sheet Techniques.md):
  - 2x supersampling and antialiased polygons (cv2), so edges stay crisp at 128 px per frame
  - Voronoi cracks: cells break open one by one, light shines through, chipped dark rims at the borders
  - noise erosion (dissolve): fbm noise against a rising threshold hollows a shape from the inside, with a hot edge
  - shaded crystal shards: two-tone prisms with an edge highlight, launched, tumbling, falling under gravity
  - uneven starbursts with an overexposed core; radial speed lines; twinkling dust specks; a lens streak
  - bloom on every frame: bright pixels blurred at two radii and added back as glow
  python -I tools/fx_craft.py <name> <out.png>     names: egg_hatch, coin_drop, tower_upgrade, splash_ring, cooldown_ready, frost_nova, badge_pop"""
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


# ------------------------------------------------------------------------------------------------ tower upgrade
# Beats copied from the ParticleFX "tower upgrade" sheet's timeline (sheet_compare analyze): f2-9 a ground ring opens
# wide and flat (perspective ellipse) over an amber pool and a thin pillar; three chevrons pop in one by one (f3/f5/f7)
# stacked upward; f9-21 the ring fades while the pool stays; f17-24 a four-point star caps the stack; f20-34 the
# stack rises; f30-45 it cools to orange and fades; specks drift down until f52. Peak brightness early (League VFX
# guide via VFX Apprentice: impact in the first quarter, clean dissipation).
UP_W, UP_G, UP_O = (1.0, 0.92, 0.62), (0.95, 0.72, 0.3), (0.9, 0.5, 0.12)


def chevron(fr, cx, y, w, h, t, color, cov):
    """a solid wedge arrowhead (the reference's arrows are filled, not outlined); t sets how deep the notch is"""
    notch = h * (1 - min(t / 0.03, 1) * 0.45)
    m = mask_poly([(cx, y), (cx + w, y + h), (cx + w * 0.45, y + h), (cx, y + notch), (cx - w * 0.45, y + h), (cx - w, y + h)])
    fr.over(color, m * cov)
    return m


def star4(fr, cx, cy, r, color, cov):
    pts = []
    for k in range(8):
        a = -np.pi / 2 + k * TAU / 8
        rr = r if k % 2 == 0 else r * 0.22
        pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
    fr.add(color, mask_poly(pts) * cov)


def tower_upgrade_v1(f):
    fr = Frame(); cx, gy = 0.5, 0.74
    if 2 <= f < 46:  # amber pool on the ground
        k = ease_out(seg(f, 2, 7)) * (1 - seg(f, 30, 46))
        fr.add(tuple((np.asarray(UP_O) + np.asarray(UP_G)) / 2), np.exp(-(((XX - cx) / 0.2) ** 2 + ((YY - gy) / 0.06) ** 2)) * 0.8 * k)
    if 2 <= f < 22:  # the ring opens wide and flat, then fades
        p = ease_out(seg(f, 2, 10)); k = 1 - seg(f, 10, 22)
        rx = 0.1 + 0.2 * p; ry = rx * 0.27
        outer = mask_poly(ellipse_pts(cx, gy, rx, ry)); inner = mask_poly(ellipse_pts(cx, gy, rx * 0.94, ry * 0.86))
        ring = np.clip(outer - inner, 0, 1)
        fr.add(UP_G, ring * 0.8 * k); fr.add(UP_G, cv2.GaussianBlur(ring, (0, 0), S * 0.012) * 0.7 * k)
    if 2 <= f < 40:  # a thin light pillar
        k = ease_out(seg(f, 2, 6)) * (1 - seg(f, 18, 40))
        col = np.exp(-((XX - cx) / 0.018) ** 2) * smooth(gy + 0.02, gy - 0.1, YY) * smooth(0.05, 0.35, YY)
        fr.add(UP_G, col * 0.55 * k)
    rise = 0.2 * ease_out(seg(f, 18, 38)); gold = seg(f, 6, 14); cool = seg(f, 30, 42); fade = 1 - seg(f, 34, 46)
    for i, t0 in enumerate((3, 5, 7)):  # chevrons pop in one by one (overshoot), stacked upward
        if f < t0 or fade <= 0:
            continue
        a = seg(f, t0, t0 + 3); pop = 1 + 0.35 * np.sin(np.pi * a) * (1 - a) + 0 * a
        pop = ease_out(a) * (1 + 0.25 * np.sin(np.pi * a))
        y = gy - 0.12 - i * 0.066 - rise  # three distinct arrows with a dark gap between them
        warm = np.asarray(UP_W) * (1 - gold) + np.asarray((1.0, 0.9, 0.3)) * gold
        col = tuple(warm * (1 - cool) + np.asarray(UP_O) * cool)
        m = chevron(fr, cx, y, 0.105 * pop, 0.068 * pop, 0.03, col, fade)
        fr.add(UP_G, cv2.GaussianBlur(m, (0, 0), S * 0.022) * 0.8 * fade * (1 - 0.6 * cool))
    if 16 <= f < 44:  # a star caps the stack
        a = seg(f, 16, 20); k = ease_out(a) * (1 - seg(f, 30, 44))
        tw = 1 + 0.25 * np.sin(f * 1.3)
        sy = gy - 0.12 - 2 * 0.066 - 0.06 - rise
        star4(fr, cx, sy, 0.09 * k * tw, UP_W, k)
        fr.add(UP_G, gauss(cx, sy, 0.05) * 0.6 * k)
    if 8 <= f < 53:  # specks drift down around the pillar and twinkle
        rng = np.random.default_rng(11)
        for i in range(30):
            t0 = 6 + rng.uniform(0, 28); x0 = cx + rng.uniform(-0.09, 0.09); y0 = gy - rng.uniform(0.02, 0.4)
            if f < t0:
                continue
            s = f - t0; y = y0 + 0.004 * s; life = 1 - seg(s, 10, 18)
            if life <= 0:
                continue
            tw = 0.5 + 0.5 * np.sin(s * 1.7 + i)
            fr.add(UP_G, mask_line((x0, y - 0.022), (x0, y), 0.004) * 1.2 * life * tw)  # falling streaks, as in the reference
    fr.bloom(0.7, 0.3)
    return fr


# ------------------------------------------------------------------------------------------------ splash damage ring
# Beats from the ParticleFX "splash damage ring" timeline: f3 a red double ground ring and a white lumpy fireball appear
# at once with a soft halo (no anticipation: it is a hit); f4-12 the fireball swells and warms to yellow; f12-28 its lobes
# are pushed out to the ring and cool to orange then red, uncovering a dark scorch with embers rising; f28-50 only the
# scorch and the ring stay; f50-58 they fade.
SP_RING = (1.0, 0.28, 0.2)


def lerp_col(stops, t):
    t = min(max(t, 0.0), 1.0) * (len(stops) - 1); i = min(int(t), len(stops) - 2); u = t - i
    return tuple(np.asarray(stops[i]) * (1 - u) + np.asarray(stops[i + 1]) * u)


def fireball(fr, cx, cy, r, f, seed, col, cov):
    """A solid fire lobe: noise-edged and opaque (unlike puff's see-through smoke), hotter in the middle, eroding as it dies."""
    r = max(r, 1e-3)
    n = fbm(seed + int(f // 3), 4, 5)
    d = np.hypot((XX - cx) / r, (YY - cy) / (r * 0.9)) + 0.5 * (n - 0.5)
    body = smooth(1.05, 0.8, d)
    erode = smooth((1 - cov) - 0.08, (1 - cov) + 0.08, n)
    hot = np.clip(1.0 - d, 0, 1)[..., None]
    c = np.asarray(col) * (0.8 + 0.35 * hot)
    m = body * erode
    fr.c = fr.c * (1 - m[..., None]) + c * m[..., None]; fr.a = m + fr.a * (1 - m)


def splash_ring_v1(f):
    fr = Frame(); cx, cy = 0.5, 0.52; RX, RY = 0.34, 0.11
    if f < 3:
        return fr
    if f < 58:  # dark scorch on the ground, mottled
        k = seg(f, 10, 20) * (1 - seg(f, 46, 58))
        n = fbm(77, 4, 6)
        d = np.hypot((XX - cx) / (RX * 0.85), (YY - cy) / (RY * 0.85))
        m = smooth(1.0, 0.75, d + 0.25 * (n - 0.5)) * (0.55 + 0.45 * n) * k
        fr.over((0.17, 0.11, 0.1), m * 0.85)
    if f < 58:  # the red double ring
        k = (1 - 0.8 * seg(f, 20, 32)) * (1 - seg(f, 46, 58)); w = 1 + 0.04 * ease_out(seg(f, 3, 12))
        for sc, a in ((1.0, 1.0), (0.86, 0.45)):
            o = mask_poly(ellipse_pts(cx, cy, RX * w * sc, RY * w * sc)); i = mask_poly(ellipse_pts(cx, cy, RX * w * sc * 0.95, RY * w * sc * 0.86))
            ring = np.clip(o - i, 0, 1)
            fr.add(SP_RING, ring * a * k * 1.1); fr.add(SP_RING, cv2.GaussianBlur(ring, (0, 0), S * 0.01) * a * k * 0.8)
    if f < 14:  # soft white halo of the blast
        fr.add((1, 0.95, 0.85), np.exp(-(((XX - cx) / 0.3) ** 2 + ((YY - cy + 0.02) / 0.2) ** 2)) * 0.25 * (1 - seg(f, 4, 14)))
    if f < 34:  # fireball lobes: start as one white ball, get pushed out to the ring, cool and erode
        out = ease_out(seg(f, 5, 22)); col = lerp_col([(1, 1, 0.92), (1, 0.9, 0.45), (1, 0.6, 0.12), (0.85, 0.25, 0.06)], seg(f, 3, 20))
        life = 1 - seg(f, 20, 34); grow = ease_out(seg(f, 3, 9))
        rng = np.random.default_rng(9)
        for k in range(9):
            a = k / 9 * TAU + rng.uniform(-0.2, 0.2)
            drift = (0.07 if k % 3 == 0 else (-0.05 if k % 3 == 1 else 0)) * seg(f, 8, 30)  # some lobes fall, some float up
            x = cx + np.cos(a) * RX * 0.95 * out; y = cy - 0.03 + np.sin(a) * RY * 1.2 * out - 0.02 * (1 - out) + drift
            r = (0.1 + 0.035 * rng.random()) * grow * (1 - 0.3 * out)
            fireball(fr, x, y, r, f, 90 + k, col, life)
            fr.add(col, gauss(x, y, r * 1.1 + 1e-3) * 0.3 * life)  # the lobes glow, they are fire not smoke
        if f < 16:  # the white-hot core
            fr.add((1, 1, 0.95), gauss(cx, cy - 0.03, 0.08 * grow + 0.01) * 0.8 * (1 - seg(f, 5, 14)))
    if 10 <= f < 46:  # embers rise from the scorch
        rng = np.random.default_rng(13)
        for i in range(22):
            t0 = 10 + rng.uniform(0, 20); x0 = cx + rng.uniform(-RX * 0.7, RX * 0.7); y0 = cy + rng.uniform(-RY * 0.5, RY * 0.6)
            if f < t0:
                continue
            s = f - t0; life = 1 - seg(s, 6, 14)
            if life > 0:
                fr.add((1, 0.55, 0.2), mask_line((x0, y0 - 0.006 * s), (x0, y0 - 0.006 * s - 0.018), 0.004) * life)
    fr.bloom(0.7, 0.3)
    return fr


# ------------------------------------------------------------------------------------------------ cooldown ready
# Beats from the ParticleFX "cooldown ready" timeline: f0 a faint dotted square; f1-26 a bright comet runs clockwise
# round it from the top middle (one lap); f27-33 the slot flashes full, the dotted border lights, sparks fly out and
# READY pops in above with an overshoot; f34-54 border and label hold; f55-56 the label shrinks away; then the faint
# dotted square stays.
CD_C, CD_W = (0.55, 0.85, 1.0), (0.9, 0.97, 1.0)
CD_BOX = (0.27, 0.27, 0.72, 0.72)


def perim(t):
    """point on the square's perimeter, t in 0..1 clockwise from the top middle"""
    x0, y0, x1, y1 = CD_BOX; w, h = x1 - x0, y1 - y0; L = 2 * (w + h)
    d = (t % 1.0) * L + w / 2
    for (ax, ay, bx, by, ln) in ((x0, y0, x1, y0, w), (x1, y0, x1, y1, h), (x1, y1, x0, y1, w), (x0, y1, x0, y0, h)):
        if d <= ln:
            u = d / ln; return ax + (bx - ax) * u, ay + (by - ay) * u
        d -= ln
    return x0, y0


def ready_text(fr, cx, cy, h, cov):
    m = np.zeros((S, S), np.uint8)
    txt = "READY"; font = cv2.FONT_HERSHEY_DUPLEX; scale = h * S / 20.0; th = max(1, int(scale * 3.2))
    (tw, tht), _ = cv2.getTextSize(txt, font, scale, th)
    cv2.putText(m, txt, (int(cx * S - tw / 2), int(cy * S + tht / 2)), font, scale, 255, th, cv2.LINE_AA)
    mm = m.astype(np.float32) / 255
    fr.add(CD_C, cv2.GaussianBlur(mm, (0, 0), S * 0.012) * 0.9 * cov)
    fr.over(CD_W, mm * cov)


def cooldown_ready_v1(f):
    fr = Frame()
    rng = np.random.default_rng(21)
    ts = rng.random(260); jit = rng.normal(0, 0.007, (260, 2)); br = rng.uniform(0.3, 1.0, 260)
    lit = seg(f, 27, 29) * (1 - seg(f, 54, 57)); faint = 0.35 if (f < 1 or f >= 55) else 0.0
    level = max(faint, lit)
    if level > 0:  # the dotted border
        dots = np.zeros((S, S), np.float32)
        for t, (jx, jy), b in zip(ts, jit, br):
            x, y = perim(t); xi, yi = int((x + jx) * S), int((y + jy) * S)
            if 0 <= xi < S and 0 <= yi < S:
                dots[yi, xi] += b
        dots = cv2.GaussianBlur(dots, (0, 0), 1.2) * 9
        fr.add(CD_C, dots * level)
        fr.add(CD_W, dots * level * (0.5 if lit > 0 else 0))
    if 1 <= f < 27:  # the comet: one clockwise lap with a short fading tail
        p = seg(f, 1, 27)
        head = np.zeros((S, S), np.float32)
        for k in range(28):
            x, y = perim(p - k * 0.0045)
            head = np.maximum(head, gauss(x, y, 0.009 - k * 0.0002) * (1 - k / 28) ** 1.5)
        fr.add(CD_W, head * 2.0); fr.add(CD_C, cv2.GaussianBlur(head, (0, 0), S * 0.01) * 0.8)
    if 27 <= f < 34:  # the flash: the slot fills, sparks fly out
        k = 1 - seg(f, 29, 34)
        x0, y0, x1, y1 = CD_BOX
        pd = 0.03  # the flash fills a little past the dotted border
        box = mask_poly([(x0 - pd, y0 - pd), (x1 + pd, y0 - pd), (x1 + pd, y1 + pd), (x0 - pd, y1 + pd)])
        fr.over((0.36, 0.47, 0.53), box * 0.75 * k)
        for i in range(26):
            t = rng.random(); x, y = perim(t); cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            d = np.array([x - cx, y - cy]); d /= np.linalg.norm(d) + 1e-6
            r0 = 0.01 + 0.05 * seg(f, 27, 33); r1 = r0 + 0.03
            fr.add(CD_W, mask_line((x + d[0] * r0, y + d[1] * r0), (x + d[0] * r1, y + d[1] * r1), 0.0035) * k)
    if 27 <= f < 57:  # READY pops in above, holds, shrinks away
        a = seg(f, 27, 31); pop = ease_out(a) * (1 + 0.2 * np.sin(np.pi * a)); out = seg(f, 53, 57)
        ready_text(fr, 0.5, 0.165 + 0.03 * (1 - ease_out(a)), 0.08 * pop * (1 - 0.6 * out) + 1e-3, 1 - out)
    fr.bloom(0.7, 0.35)
    return fr


# ------------------------------------------------------------------------------------------------ frost nova
# Beats from the ParticleFX "frost nova" timeline: f0 a white spark; f2-8 a flat frost disc opens with two white rings
# racing out; f4-9 a crown of ice spikes shoots up round the rim (front ones larger: perspective); f9-36 everything holds
# while the frost swirls and dark-blue mist breathes; f36-46 the spikes shatter into shards that scatter and fall;
# f46-60 the frost erodes away.
FN_L, FN_D, FN_W = (0.75, 0.96, 1.0), (0.35, 0.68, 0.95), (0.94, 0.99, 1.0)


def frost_nova_v1(f):
    fr = Frame(); cx, cy = 0.5, 0.5; RX, RY = 0.3, 0.11
    if f < 5:  # the spark
        fr.add(FN_W, gauss(cx, cy, 0.035 + 0.02 * seg(f, 0, 3)) * 1.4 * (1 - seg(f, 2, 5)))
    if 2 <= f < 60:  # the frost disc: textured, swirling, eroding at the end
        g = ease_out(seg(f, 2, 8)); n = fbm(41 + int(f // 4), 4, 6)
        d = np.hypot((XX - cx) / (RX * g + 1e-3), (YY - cy) / (RY * g + 1e-3))
        e = 1.15 * seg(f, 38, 52)
        erode = smooth(e - 0.1, e + 0.05, n)
        disc = smooth(1.05, 0.85, d + 0.2 * (n - 0.5)) * erode
        fr.over((0.12, 0.27, 0.42), disc * (0.55 + 0.3 * n))  # misty, uneven frost, darker than the ice
        ang = np.arctan2((YY - cy) / RY, (XX - cx) / RX)
        swirl = (0.5 + 0.5 * np.sin(ang * 3 + d * 9 - f * 0.25)) * smooth(0.95, 0.2, d) * (0.4 + 0.6 * n)
        fr.add(FN_L, swirl * disc * 0.45 * (1 - 0.5 * seg(f, 30, 50)))
        rings = (0.5 + 0.5 * np.cos(d * 18)) ** 6 * smooth(0.9, 0.3, d)  # bright inner rings early on
        fr.add(FN_W, rings * disc * 0.5 * (1 - seg(f, 6, 16)))
        fr.add(FN_W, gauss(cx, cy, 0.05) * 0.45 * (1 - seg(f, 10, 36)))
    if 2 <= f < 9:  # two rings race out
        for k, t0 in enumerate((2, 3.5)):
            p = ease_out(seg(f, t0, t0 + 5)); a = 1 - seg(f, t0 + 2, t0 + 5.5)
            if a <= 0:
                continue
            o = mask_poly(ellipse_pts(cx, cy, RX * 1.1 * p + 1e-3, RY * 1.1 * p + 1e-3))
            i = mask_poly(ellipse_pts(cx, cy, RX * 1.1 * p * 0.9 + 1e-3, RY * 1.1 * p * 0.82 + 1e-3))
            fr.add(FN_W, np.clip(o - i, 0, 1) * a * (1 - 0.3 * k))
    if 4 <= f < 40:  # dark-blue mist breathing round the rim
        k = seg(f, 4, 10) * (1 - seg(f, 30, 40))
        haze = np.exp(-(((XX - cx) / (RX * 1.2)) ** 2 + ((YY - cy + 0.02) / (RY * 2.4)) ** 2)) * (0.6 + 0.4 * fbm(57 + int(f // 5), 3, 5))
        fr.over((0.1, 0.22, 0.42), haze * 0.45 * k)  # a tall dark-blue frost haze behind the crown
    rng = np.random.default_rng(31)
    N = 14
    for i in range(N):  # the crown of spikes
        a = i / N * TAU + rng.uniform(-0.08, 0.08)
        bx, by = cx + np.cos(a) * RX * 0.95, cy + np.sin(a) * RY * 0.95
        front = 0.75 + 0.35 * (np.sin(a) + 1) / 2  # spikes nearer the viewer are taller and brighter
        L = rng.uniform(0.11, 0.17) * front; W = 0.016 * front  # thin needles
        t0 = 4 + rng.uniform(0, 3); tilt = rng.uniform(-0.15, 0.15)
        if f < t0:
            continue
        if f < 37:
            u = seg(f, t0, t0 + 3); grow = ease_out(u) * (1 + 0.2 * np.sin(np.pi * u))
            shard(fr, bx, by - L * grow / 2, -np.pi / 2 + tilt, L * grow + 1e-3, W, FN_L, FN_D, 1.0)
            shard(fr, bx + W * 0.9, by - L * grow * 0.3, -np.pi / 2 + tilt + 0.45, L * grow * 0.55 + 1e-3, W * 0.7, FN_L, FN_D, 1.0)  # a smaller leaning shard beside it
            fr.add(FN_W, mask_line((bx, by - L * grow * 0.15), (bx, by - L * grow * 0.95), 0.005) * 0.7 * front)  # white-hot spine and tip
        elif f < 52:  # shatter: three pieces scatter out and fall
            s = f - 37; life = 1 - seg(s, 6, 15)
            for j in range(3):
                vx = np.cos(a) * 0.004 + (j - 1) * 0.002; vy = -0.008 + j * 0.001
                x = bx + vx * s * 2; y = by - L * (0.25 + 0.3 * j) + vy * s + 0.0011 * s * s
                shard(fr, x, y, s * 0.5 + j, L * 0.2, W * 0.7, FN_L, FN_D, life)
    if 34 <= f < 60:  # specks drift up as it melts
        for i in range(24):
            x0 = cx + rng.uniform(-RX, RX); y0 = cy + rng.uniform(-RY, RY); t0 = 34 + rng.uniform(0, 14)
            if f >= t0:
                s = f - t0; life = 1 - seg(s, 4, 12)
                if life > 0:
                    fr.add(FN_W, gauss(x0, y0 - 0.004 * s, 0.004) * 1.2 * life)
    fr.bloom(0.7, 0.3)
    return fr


# ------------------------------------------------------------------------------------------------ notification badge pop
# Beats from the ParticleFX "notification badge pop" timeline: f0-3 dust gathers; f4-5 a white disc flashes; f6 the red
# badge with "1" overshoots in with a pink glow ring racing out and a dark halo; f17 and f30 it pops again (white flash,
# overshoot, ring) to "2" and "3"; holds; f55-57 it shrinks and bursts back into dust.
BG_L, BG_D = (1.0, 0.56, 0.62), (0.9, 0.24, 0.34)
BG_POPS = ((4, "1"), (17, "2"), (30, "3"))


def badge_digit(fr, cx, cy, h, txt, cov):
    m = np.zeros((S, S), np.uint8)
    font = cv2.FONT_HERSHEY_DUPLEX; scale = h * S / 21.0; th = max(1, int(scale * 3.6))
    (tw, tht), _ = cv2.getTextSize(txt, font, scale, th)
    cv2.putText(m, txt, (int(cx * S - tw / 2), int(cy * S + tht / 2)), font, scale, 255, th, cv2.LINE_AA)
    mm = m.astype(np.float32) / 255
    fr.over((0.45, 0.06, 0.12), cv2.GaussianBlur(mm, (0, 0), 1.5) * 0.6 * cov)
    fr.over((1, 1, 1), mm * cov)


def badge_pop_v1(f):
    fr = Frame(); cx, cy = 0.5, 0.49; R = 0.25
    rng = np.random.default_rng(17)
    if f < 5 or f >= 56:  # dust gathering in / bursting out
        for i in range(20):
            a = rng.uniform(0, TAU); r0 = rng.uniform(0.12, 0.3); sz = 0.006 + 0.004 * rng.random()
            t = (1 - seg(f, 0, 5)) if f < 5 else seg(f, 56, 63)
            r = r0 * (0.3 + 0.7 * t); life = (1 - seg(f, 3, 5)) if f < 5 else (1 - seg(f, 60, 63))
            fr.add(BG_L if i % 2 else (1, 1, 1), gauss(cx + np.cos(a) * r, cy + np.sin(a) * r * 0.9, sz) * 1.2 * life)
    if not (4 <= f < 57):
        fr.bloom(0.7, 0.3)
        return fr
    pop_t, digit = BG_POPS[0]
    for t0, dg in BG_POPS:
        if f >= t0:
            pop_t, digit = t0, dg
    s = f - pop_t
    over = ease_out(seg(s, 0, 3)) * (1 + 0.18 * np.sin(np.pi * seg(s, 0, 4)) * (1 - seg(s, 3, 6)))
    if pop_t > 4:
        over = max(over, 0.85)  # later pops start from the badge already there
    shrink = 1 - 0.35 * seg(f, 54, 57)
    r = max(R * over * shrink, 1e-3)
    dist = np.hypot(XX - cx, YY - cy)
    if s < 9:  # dark halo and the pink ring racing out
        k = 1 - seg(s, 4, 9)
        fr.add(BG_L, smooth(R * 1.6, R * 1.15, dist) * 0.45 * k)  # soft pink glow
        fr.over((0.1, 0.06, 0.08), smooth(R * 1.3, R * 1.22, dist) * 0.85 * k)  # thick dark halo
        fr.add((1, 0.85, 0.88), smooth(0.012, 0.0, np.abs(dist - R * 1.08)) * (1 - seg(s, 1, 4)))  # white rim at the pop
    d = dist / r  # the badge: a lit red sphere with a soft top highlight and a darker rim
    body = smooth(1.0, 0.94, d)
    lit = np.clip(1.0 - np.hypot(XX - (cx - r * 0.3), YY - (cy - r * 0.35)) / (r * 1.6), 0, 1)[..., None]
    col = np.asarray(BG_D) * (1 - lit) + np.asarray(BG_L) * lit
    fr.c = fr.c * (1 - body[..., None]) + col * body[..., None]; fr.a = body + fr.a * (1 - body)
    fr.over((0.55, 0.08, 0.16), smooth(1.0, 0.9, d) * smooth(0.8, 0.95, d) * 0.5)
    badge_digit(fr, cx, cy + 0.005, r * 1.0, digit, 1.0)
    if s < 2:  # the white flash of each pop (full size even while the badge itself is still growing in)
        flash = smooth(R * 1.0, R * 0.94, dist) if pop_t == 4 else body
        fr.over((1, 1, 1), flash * (1 - seg(s, 0.8, 2)) * (1.0 if pop_t == 4 else 0.7))
    if s < 7:  # a few sparkles thrown off
        for i in range(6):
            a = rng.uniform(0, TAU); rr = R * (1.1 + 0.6 * seg(s, 0, 6))
            fr.add((1, 0.85, 0.6), gauss(cx + np.cos(a) * rr, cy + np.sin(a) * rr, 0.006) * (1 - seg(s, 3, 7)) * 1.4)
    fr.bloom(0.75, 0.3)
    return fr



# ------------------------------------------------------------------------------------------------ painted-field fire (v2)
# Quality rebuild 2026-10-28 (user: "none of them have the same quality as the examples"). The research
# (Roblox Dev/Research/VFX and Animation/Effect Quality.md) says hand-made fire flipbooks are painted as a grey
# DENSITY/TEMPERATURE field and coloured by a GRADIENT MAP, and they dissipate by ALPHA EROSION of that field.
# So: fire lobes are summed into one field (they merge, cores where they overlap are hottest), colour comes from the
# temperature ramp per pixel, and the shape breaks up from its thin parts inward instead of fading.
FIRE_RAMP = [(0.0, (0.45, 0.08, 0.04)), (0.22, (0.82, 0.17, 0.05)), (0.45, (0.96, 0.36, 0.06)),
             (0.68, (1.0, 0.66, 0.05)), (0.88, (1.0, 0.88, 0.3)), (1.0, (1.0, 1.0, 0.85))]


def ramp(t, stops=FIRE_RAMP):
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    for (t0, c0), (t1, c1) in zip(stops[:-1], stops[1:]):
        m = ((t >= t0) & (t <= t1))[..., None]
        u = ((t - t0) / max(t1 - t0, 1e-6))[..., None]
        out = np.where(m, np.asarray(c0, np.float32) * (1 - u) + np.asarray(c1, np.float32) * u, out)
    return out


def warp(seed, amp):
    """domain-warp offsets so lobe edges become cauliflower bumps instead of circles"""
    return (fbm(seed, 3, 5) - 0.5) * amp, (fbm(seed + 1, 3, 5) - 0.5) * amp


def fire_field(lobes, f, seed):
    """lobes: [(x, y, r, heat)] -> (density, temperature). Density is a soft union; temperature is the
    density-weighted heat, so overlaps glow hottest and thin edges cool toward red."""
    wx, wy = warp(seed + int(f // 4), 0.05 * (0.4 + 0.6 * seg(f, 5, 12)))  # slow re-seed; a calmer warp while it is still a dome
    X, Y = XX + wx, YY + wy
    D = np.zeros((S, S), np.float32); H = np.zeros((S, S), np.float32)
    for li, (x, y, r, heat) in enumerate(lobes):
        if r <= 1e-3:
            continue
        # each lobe is a cluster of small puffs (fixed per lobe), so the union gets cauliflower bumps, not a balloon
        rng = np.random.default_rng(seed * 7 + li)
        puffs = [(0.0, 0.0, 0.72)] + [(np.cos(a) * 0.58, np.sin(a) * 0.5, rng.uniform(0.38, 0.52)) for a in rng.uniform(0, TAU, 7)]
        for ox, oy, sr in puffs:
            rr = r * sr
            k = np.exp(-(((X - x - ox * r) ** 2 + (Y - y - oy * r) ** 2) / (rr * rr)) * 1.5)
            D += k; H += k * heat
    heat = np.where(D > 1e-4, H / np.maximum(D, 1e-4), 0)
    D = D / 2.4  # the puff cluster sums to ~2.4 at a lobe's heart: back to ~1
    bump = fbm(seed + 7 + int(f // 5), 4, 7)
    # temperature follows density: hearts hottest, thin edges cooler, plus painted unevenness
    T = 0.98 * heat * (0.28 + 0.85 * smooth(0.1, 1.6, D)) + 0.2 * (bump - 0.5)  # yellow-orange body, white only in dense hearts, darker painted patches
    return D * (0.75 + 0.5 * bump), T


def paint_fire(fr, D, T, erode, seed, f):
    """gradient-map the temperature, cut alpha from the density with a rising erosion threshold (noise-broken)"""
    n = fbm(seed + 13 + int(f // 5), 4, 6)
    a = smooth(erode, erode + 0.4, D * (0.7 + 0.6 * n))  # wide band: soft, feathered edges
    col = ramp(T)
    sm = smooth(0.06, -0.25, T)[..., None]  # cold fire turns to dark smoke (grey-brown), not to a red blob
    smoke = np.asarray((0.2, 0.13, 0.11), np.float32) + 0.12 * n[..., None]
    col = col * (1 - sm) + smoke * sm
    fr.c = fr.c * (1 - a[..., None]) + col * a[..., None]
    fr.a = a + fr.a * (1 - a)
    glow = cv2.GaussianBlur(col * (a * (1 - sm[..., 0]))[..., None], (0, 0), S * 0.022)  # fire (not smoke) lights the air around it
    fr.c = fr.c + glow * 0.2
    fr.a = np.clip(fr.a + glow.max(2) * 0.2, 0, 1)
    return a


def splash_ring(f):
    """Splash Damage Ring v2 (painted-field rebuild). Beats from the dense frame study of the reference:
    f3-6 white mushroom dome under a big soft halo inside a double ring; f7-9 it swells, a lobe drops below; f10-14 it
    splits into two hot masses on the ring's left/right ends, a cooler cap on top and a lobe below, the middle clears to
    dark smoke with ember streaks; f15-28 everything cools along the ramp and erodes into pieces, bits drift up and down;
    f29+ only the ring and the dark smoke stay, dimming."""
    fr = Frame(); cx, cy = 0.5, 0.53; RX, RY = 0.36, 0.115
    if f < 3:
        return fr
    # soft white halo of the blast
    if f < 11:
        fr.add((1, 0.95, 0.85), np.exp(-(((XX - cx) / 0.34) ** 2 + ((YY - cy + 0.04) / 0.22) ** 2)) * 0.5 * (1 - seg(f, 6, 12)))
    # dark smoke settling inside the ring (grey tops, brown undersides), appears as the middle clears
    if 9 <= f < 60:
        k = seg(f, 9, 15) * (1 - seg(f, 28, 52))  # fades out like the reference's
        n = fbm(61 + min(int(f // 6), 3), 4, 6)  # the settled smoke stops changing (the reference holds these frames)
        d = np.hypot((XX - cx) / (RX * 0.82), (YY - cy + 0.025) / (RY * 1.35))  # a low dome of smoke, rising above the ring line
        cloud = fbm(66 + min(int(f // 8), 2), 4, 7)
        dens = smooth(1.0, 0.55, d + 0.35 * (n - 0.5)) * (0.45 + 0.55 * smooth(0.25, 0.65, cloud))
        shade = np.clip(0.55 - (YY - cy) / RY * 0.5 + 1.2 * (cloud - 0.5), 0, 1)[..., None]
        col = np.asarray((0.15, 0.1, 0.09)) * (1 - shade) + np.asarray((0.42, 0.34, 0.32)) * shade  # visible grey-brown clouds, lit from above
        a = np.clip(dens * 1.4, 0, 1) * 0.72 * k
        fr.c = fr.c * (1 - a[..., None]) + col * a[..., None]; fr.a = a + fr.a * (1 - a)
    # the double ring: thick soft outer, faint inner; grows a little, dims once the fire is gone
    w = 1 + 0.06 * ease_out(seg(f, 3, 12)); k = (1 - 0.55 * seg(f, 20, 34)) * (1 - seg(f, 50, 60))
    for sc, amt in ((1.0, 1.0), (0.84, 0.35)):
        o = mask_poly(ellipse_pts(cx, cy, RX * w * sc, RY * w * sc)); i = mask_poly(ellipse_pts(cx, cy, RX * w * sc * 0.93, RY * w * sc * 0.8))
        ring = np.clip(o - i, 0, 1)
        fr.add((0.95, 0.24, 0.1), ring * amt * k * 0.45)
        fr.add((0.95, 0.22, 0.08), cv2.GaussianBlur(ring, (0, 0), S * 0.022) * amt * k * 0.95)
    # the fireball: one painted field
    if f < 36:
        e = ease_out(seg(f, 9, 21))          # dome -> split (the reference is still one mass at ~f11)
        cool = seg(f, 7, 30) ** 1.35          # global cooling: white-yellow at f11, yellow f15, orange f20, red f26 (reference)
        def L(x0, y0, x1, y1, r0, r1, h0, h1, rise=0.0, fast=False):
            x = x0 + (x1 - x0) * e; y = y0 + (y1 - y0) * e - rise * seg(f, 14, 32)
            c = seg(f, 9, 19) if fast else cool  # the top cap cools to smoke much sooner than the side masses
            return (cx + x, cy + y, r0 + (r1 - r0) * e, h0 + (h1 - h0) * c)
        grow = (ease_out(seg(f, 3, 6)) * 0.55 + 0.45) * 1.55
        lobes = [
            # dome core and cap (white-hot) -> left mass
            L(-0.045, -0.07, -0.29, -0.04, 0.085 * grow, 0.115, 1.2, 0.2),
            L(-0.06, -0.11, -0.25, -0.13, 0.06 * grow, 0.095, 1.0, 0.12),
            L(-0.02, 0.0, -0.32, 0.04, 0.045 * grow, 0.085, 1.1, 0.15),
            # -> right mass
            L(0.045, -0.07, 0.29, -0.03, 0.085 * grow, 0.115, 1.2, 0.22),
            L(0.06, -0.11, 0.26, -0.12, 0.06 * grow, 0.09, 1.0, 0.12),
            L(0.02, 0.0, 0.33, 0.05, 0.045 * grow, 0.08, 1.1, 0.16),
            # cap on top: cools first and rises as dark smoke
            L(0.0, -0.14, -0.02, -0.15, 0.07 * grow, 0.095, 1.0, -0.6, 0.08, True),
            L(-0.07, -0.15, -0.08, -0.17, 0.05 * grow, 0.06, 1.0, -0.6, 0.1, True),
            L(0.07, -0.15, 0.07, -0.18, 0.05 * grow, 0.055, 1.0, -0.6, 0.12, True),
            # inner bridges: keep it one connected mass until ~f15, then they burn away first
            L(-0.02, -0.09, -0.15, -0.1, 0.06 * grow, 0.09 * (1 - seg(f, 14, 21)), 1.0, -0.2),
            L(0.02, -0.09, 0.15, -0.09, 0.06 * grow, 0.09 * (1 - seg(f, 14, 21)), 1.0, -0.2),
            L(0.0, -0.04, 0.0, -0.06, 0.07 * grow, 0.09 * (1 - seg(f, 13, 20)), 1.1, 0.0),  # the heart, last to clear
            # wider dome: two shoulder lobes that exist only while it is a dome
            L(-0.1, -0.09, -0.14, -0.08, 0.07 * grow, 0.0, 1.05, 0.6),
            L(0.1, -0.09, 0.14, -0.08, 0.07 * grow, 0.0, 1.05, 0.6),
            L(0.0, -0.1, 0.0, -0.1, 0.07 * grow, 0.0, 1.1, 0.6),
            # the lobe that drops below the ring
            L(0.0, 0.03, 0.0, 0.15, 0.05 * grow, 0.07, 1.15, 0.1, -0.05),
        ]
        D, T = fire_field(lobes, f, 300)
        erode = 0.04 + 1.15 * seg(f, 17, 34) ** 1.2   # thin parts break off first, the cores last
        paint_fire(fr, D, T, erode, 300, f)
        # embers: short streaks rising from the cleared middle, flickering
        if 9 <= f < 30:
            rng = np.random.default_rng(13)
            for i in range(64):
                t0 = 9 + rng.uniform(0, 14); x0 = cx + rng.uniform(-RX * 0.6, RX * 0.6); y0 = cy + rng.uniform(-RY * 0.5, RY * 0.6)
                if f < t0:
                    continue
                s = f - t0; life = 1 - seg(s, 5, 11)
                if life > 0 and (i + int(f)) % 3:
                    fr.add((1, 0.55, 0.2), mask_line((x0, y0 - 0.007 * s), (x0, y0 - 0.007 * s - 0.024), 0.003) * life * 0.9)
        # small torn-off bits drifting up from the cap and down from the bottom lobe
        if 15 <= f < 34:
            rng = np.random.default_rng(23)
            bits = []
            for i in range(6):
                bx = rng.uniform(-0.2, 0.2); up = 1 if i < 4 else -1
                s = f - 15
                bits.append((cx + bx + 0.002 * s * np.sign(bx), cy - 0.2 * up - 0.006 * s * up, 0.028 * (1 - seg(f, 24, 34)) + 1e-3, 0.25 - 0.3 * seg(f, 15, 30)))
            D2, T2 = fire_field(bits, f, 400)
            paint_fire(fr, D2, T2, 0.3 + 0.5 * seg(f, 22, 34), 400, f)
    fr.bloom(0.8, 0.15)  # light bloom: heavy bloom turned the fire pastel
    return fr



# ------------------------------------------------------------------------------------------------ frost nova v2
# Quality rebuild 2026-10-28 from a dense frame study of the reference (see Effect Quality.md): f0-2 a white orb
# flattens into an ellipse in a big soft halo; f3-4 a bright disc with ripple rings in blue mist; f5-9 a crown of
# CRYSTAL CLUSTERS (2-3 jagged blades each, white spine -> cyan -> blue edge, front ones bigger) round the rim under a
# dark-blue haze wider than the disc; f10-30 hold, the centre glows cyan with swirl, ripples fade; f30-36 the crystals
# cool from white to blue (the value ramp slides down); f38-46 they shatter into many TINY specks; then mist and
# specks fade. Ice is gradient-mapped like fire: value field per blade (bright spine, darker edge) -> ICE_RAMP.
ICE_RAMP = [(0.0, (0.1, 0.25, 0.55)), (0.35, (0.25, 0.55, 0.95)), (0.65, (0.55, 0.85, 1.0)), (0.85, (0.85, 0.97, 1.0)), (1.0, (1.0, 1.0, 1.0))]


def blade_field(fr, bx, by, h, w, tilt, value, cov, seed):
    """one jagged ice blade standing on (bx, by): a narrow pointed polygon with a notched edge; colour from a value
    field that is brightest on the spine and darker at the edges (gradient-mapped through ICE_RAMP)"""
    rng = np.random.default_rng(seed)
    c, s = np.cos(tilt), np.sin(tilt)
    def P(u, v):  # u along the blade (0 base .. 1 tip), v across (-1 .. 1)
        return (bx + (v * w) * c + (u * h) * s * 0.0 + (v * w) * 0, by - u * h)
    pts_l, pts_r = [], []
    for k in range(6):
        u = k / 5
        half = np.sin(np.pi * (0.15 + 0.85 * u) ** 0.6) * (1 - u) ** 0.4 * (1 + 0.35 * (rng.random() - 0.5)) if k < 5 else 0.0  # slender: widest just above the base
        x_off = np.sin(tilt) * u * h + np.sin(tilt * 3 + seed % 7) * 0.35 * w * np.sin(u * np.pi)  # lean and a flame-like S-curve
        pts_l.append((bx + x_off - half * w, by - u * h))
        pts_r.append((bx + x_off + half * w * (0.7 + 0.4 * rng.random()), by - u * h))
    m = mask_poly(pts_l + pts_r[::-1])
    if m.max() <= 0:
        return
    # value: distance from the spine (the lean line), normalised by the local half width
    u = np.clip((by - YY) / max(h, 1e-4), 0, 1)
    spine_x = bx + np.sin(tilt) * u * h
    half = np.maximum(np.sin(np.pi * (0.15 + 0.85 * u) ** 0.6) * (1 - u) ** 0.4 * w, 1e-4)
    v = 1 - np.clip(np.abs(XX - spine_x) / half, 0, 1)
    V = np.clip(value * (0.45 + 0.65 * v ** 0.8) + 0.1 * u, 0, 1)
    col = ramp(V, ICE_RAMP)
    a = m * cov
    fr.c = fr.c * (1 - a[..., None]) + col * a[..., None]; fr.a = a + fr.a * (1 - a)


def frost_nova(f):
    fr = Frame(); cx, cy = 0.5, 0.52; RX, RY = 0.31, 0.105
    # the orb: white, flattening into an ellipse, big soft halo
    if f < 6:
        sq = ease_out(seg(f, 0, 3))
        rx, ry = 0.045 + 0.06 * sq, 0.045 - 0.018 * sq
        fr.add((0.95, 0.98, 1.0), np.exp(-(((XX - cx) / rx) ** 2 + ((YY - cy) / ry) ** 2)) * 1.6 * (1 - seg(f, 3, 6)))
        fr.add((0.6, 0.8, 1.0), np.exp(-(((XX - cx) / 0.14) ** 2 + ((YY - cy) / 0.11) ** 2)) * 0.45 * (1 - seg(f, 2, 6)))
    if f < 3:
        fr.bloom(0.7, 0.3)
        return fr
    # dark-blue haze, wider than the disc, textured, slow
    k = seg(f, 3, 7) * (1 - seg(f, 46, 60))
    n = fbm(201 + min(int(f // 8), 4), 4, 6)
    d = np.hypot((XX - cx) / (RX * 1.35), (YY - cy + 0.015) / (RY * 2.4))
    haze = smooth(1.0, 0.4, d + 0.55 * (n - 0.5)) * (0.45 + 0.55 * n)  # rough, cloudy edge
    fr.over((0.12, 0.22, 0.38), np.clip(haze * 1.2, 0, 1) * 0.8 * k)  # darker, so it reads as mist, not glow
    # the frost disc: bright at first, then a cyan glowing centre with swirl, dimming over life
    g = ease_out(seg(f, 3, 7)); dk = 1 - seg(f, 40, 58)
    dd = np.hypot((XX - cx) / (RX * g + 1e-3), (YY - cy) / (RY * g + 1e-3))
    ang = np.arctan2((YY - cy) / RY, (XX - cx) / RX)
    swirl = 0.5 + 0.5 * np.sin(ang * 2 + dd * 7 - f * 0.12) * (0.5 + 0.5 * n)
    centre = smooth(1.0, 0.0, dd) ** 1.5
    centre = smooth(1.25, 0.0, dd) ** 1.3
    fr.add((0.55, 0.85, 1.0), centre * (0.55 + 0.35 * swirl) * 0.9 * dk * (1 - 0.7 * seg(f, 16, 40)))  # the glowing cyan heart of the disc
    fr.add((1, 1, 1), smooth(0.7, 0.0, dd) * 0.9 * (1 - seg(f, 4, 10)))  # white flash of the disc
    # ripple rings: concentric, drifting outward, fading by ~f20
    if f < 22:
        for kk in range(3):
            p = (0.25 + 0.3 * kk + 0.035 * (f - 3)) % 1.0
            if p < 0.12:
                continue
            o = mask_poly(ellipse_pts(cx, cy, RX * p * g + 1e-3, RY * p * g + 1e-3))
            i = mask_poly(ellipse_pts(cx, cy, RX * p * g * 0.93 + 1e-3, RY * p * g * 0.85 + 1e-3))
            fr.add((0.85, 0.97, 1.0), np.clip(o - i, 0, 1) * 0.8 * (1 - seg(f, 6, 14)) * (1 - p * 0.5))
    # frost specks scattered round the rim during the hold (the reference's crown is full of tiny glints)
    if 4 <= f < 40:
        rs = np.random.default_rng(91)
        for j in range(60):
            a = rs.uniform(0, TAU); rr = rs.uniform(0.85, 1.1)
            x = cx + np.cos(a) * RX * rr; y = cy + np.sin(a) * RY * rr - rs.uniform(0, 0.08)
            tw = 0.5 + 0.5 * np.sin(f * 0.9 + j * 1.7)
            sz = rs.uniform(0.002, 0.004)
            fr.add((0.85, 0.97, 1.0), mask_poly([(x - sz, y - sz), (x + sz, y - sz), (x + sz, y + sz), (x - sz, y + sz)]) * tw * seg(f, 4, 7) * (1 - seg(f, 30, 40)))
    # the crown: crystal clusters round the rim
    rng = np.random.default_rng(77)
    N = 13
    cool = seg(f, 28, 38)                       # white -> blue late in life (the reference is still white-cyan at f32)
    for i in range(N):
        a = i / N * TAU + rng.uniform(-0.12, 0.12)
        bx, by = cx + np.cos(a) * RX * 0.98, cy + np.sin(a) * RY * 0.98
        front = 0.8 + 0.25 * (np.sin(a) + 1) / 2  # nearer the viewer = a little bigger
        t0 = 4 + rng.uniform(0, 2.5)
        nb = 2 + int(rng.random() < 0.5)
        blades = [(rng.uniform(-0.012, 0.012), rng.uniform(0.6, 1.0), rng.uniform(-0.35, 0.35), rng.integers(1 << 30)) for _ in range(nb)]
        if f < t0:
            continue
        t_sh = 37 + rng.uniform(0, 6)  # crystals shatter one after another, not all at once
        if f < t_sh:
            u = seg(f, t0, t0 + 2.5); grow = ease_out(u) * (1 + 0.15 * np.sin(np.pi * u))
            for ox, hs, tilt, sd in blades:
                h = 0.16 * front * hs * grow; w = 0.012 * front
                value = (1.05 - 0.4 * cool) * (0.9 + 0.1 * hs)
                blade_field(fr, bx + ox * front, by, h, w, tilt, value, 1.0, int(sd))
        elif f < 56:  # shatter into many tiny specks scattered along where the crystal stood, drifting and twinkling
            s = f - t_sh; life = 1 - seg(s, 6, 15)
            for j in range(10):
                ux = rng.uniform(-0.03, 0.03) * front; uy = -rng.uniform(0, 0.12) * front
                vx = rng.uniform(-0.002, 0.002) + np.cos(a) * 0.0012; vy = rng.uniform(-0.002, 0.0015)
                x = bx + ux + vx * s; y = by + uy + vy * s + 0.0002 * s * s
                tw = 0.6 + 0.4 * np.sin(s * 1.9 + j)
                sz = rng.uniform(0.002, 0.0038)
                col = (0.85, 0.97, 1.0) if j % 3 else (0.45, 0.8, 1.0)
                if life > 0:
                    fr.add(col, mask_poly([(x - sz, y - sz), (x + sz, y - sz), (x + sz, y + sz), (x - sz, y + sz)]) * life * tw * 0.9)
    fr.bloom(0.75, 0.3)
    return fr



# ------------------------------------------------------------------------------------------------ tower upgrade v2
# Quality rebuild 2026-10-28 from a dense frame study (every frame f2-f49) of the reference:
#  f2-12  a cream double ring opens over an amber dish of light; a soft amber flame-pillar rises from the centre
#  f5     the first arrow pops up just above the ring; f10 and f15 new arrows push in UNDER it, so the stack grows from
#         the bottom and rises; arrows are chunky chevrons, white-hot core -> yellow edge (gradient-mapped value field)
#  f8-45  sparks drip DOWN from the arrows as short falling streaks (many, flickering)
#  f15-24 the arrows warm from white to yellow; the ring fades out by f22, the dish becomes a soft spot
#  f25-33 a four-point star flares on top with a round glow halo
#  f33-38 the stack collapses into one arrow (the lower arrows merge up), which turns gold, then orange, and fades by f44
UP_RAMP = [(0.0, (0.55, 0.25, 0.04)), (0.35, (0.95, 0.6, 0.1)), (0.6, (1.0, 0.85, 0.25)), (0.82, (1.0, 0.96, 0.62)), (1.0, (1.0, 1.0, 0.95))]


def arrow_field(fr, cx, y, w, h, t, value, cov):
    """a chunky chevron whose colour comes from a value field: hottest along its centre line, cooler at the edges"""
    if cov <= 0 or w <= 1e-4:
        return
    notch = h * 0.45  # shallow notch: a thick, almost solid arrowhead like the reference (not a thin chevron)
    m = mask_poly([(cx, y), (cx + w, y + h), (cx + w * 0.3, y + h), (cx, y + h + notch * 0.0 - (h - notch)), (cx - w * 0.3, y + h), (cx - w, y + h)])
    # distance from the chevron's centre line: the V from (cx-w*0.72, y+h) through (cx, y + notch*0.5) to (cx+w*0.72, y+h)
    mid_y = y + notch * 0.45 + np.abs(XX - cx) / max(w, 1e-4) * (h - notch * 0.45) * 0.95
    v = 1 - np.clip(np.abs(YY - mid_y) / max(h * 0.32, 1e-4), 0, 1)
    V = np.clip(value * (0.55 + 0.5 * v), 0, 1)
    col = ramp(V, UP_RAMP)
    a = m * cov
    fr.c = fr.c * (1 - a[..., None]) + col * a[..., None]; fr.a = a + fr.a * (1 - a)
    glow = cv2.GaussianBlur(m, (0, 0), S * 0.02)
    fr.add((1.0, 0.75, 0.25), glow * 0.55 * cov * value)


def tower_upgrade(f):
    fr = Frame(); cx, gy = 0.5, 0.7
    # the dish of amber light inside the ring, then a soft spot
    if 2 <= f < 52:
        g = ease_out(seg(f, 2, 12)); k = 1 - seg(f, 34, 44)
        rx = 0.1 + 0.26 * g - 0.12 * seg(f, 18, 26); ry = rx * 0.3
        dish = np.exp(-(((XX - cx) / max(rx, 1e-3)) ** 2 + ((YY - gy) / max(ry, 1e-3)) ** 2) * 2.2)  # hot middle, dark toward the rim
        fr.add((1.0, 0.62, 0.12), dish * 0.95 * k)
    # the cream double ring
    if 2 <= f < 24:
        g = ease_out(seg(f, 2, 12)); k = 1 - seg(f, 13, 21)
        for sc, amt in ((1.0, 1.0), (0.88, 0.4)):
            rx = (0.12 + 0.25 * g) * sc; ry = rx * 0.27
            o = mask_poly(ellipse_pts(cx, gy, rx, ry)); i = mask_poly(ellipse_pts(cx, gy, rx * 0.95, ry * 0.84))
            ring = np.clip(o - i, 0, 1)
            fr.add((1.0, 0.92, 0.7), ring * amt * k * 0.4)
            fr.add((1.0, 0.78, 0.35), cv2.GaussianBlur(ring, (0, 0), S * 0.016) * amt * k * 0.35)
    # the soft amber flame pillar
    if 2 <= f < 46:
        k = ease_out(seg(f, 2, 7)) * (1 - seg(f, 30, 42))
        top = gy - 0.45
        col = np.exp(-((XX - cx) / (0.035 + 0.03 * smooth(gy, top, YY))) ** 2) * smooth(top - 0.02, gy - 0.12, YY) * smooth(gy + 0.02, gy - 0.05, YY)
        fr.add((1.0, 0.65, 0.15), col * 0.45 * k)
    # the arrow stack: arrows born at the bottom push the earlier ones up; then the stack collapses into one
    births = (4, 9, 13)
    rise = 0.03 * seg(f, 8, 22) + 0.1 * ease_out(seg(f, 22, 29))  # creeps up while stacking, then lifts
    merge = seg(f, 33, 38)
    warm = seg(f, 14, 24); cool = seg(f, 35, 41); fade = 1 - seg(f, 37, 42)
    base_y = gy - 0.19
    born = [b for b in births if f >= b]
    for idx, b in enumerate(born):
        order = len(born) - 1 - idx         # 0 = the newest (lowest)
        a = seg(f, b, b + 2.5); pop = ease_out(a) * (1 + 0.22 * np.sin(np.pi * a))
        slot = order * 0.07 * (1 - merge)   # spacing collapses as they merge
        y = base_y - slot - rise - 0.02 * (1 - ease_out(a))
        value = (1.05 - 0.25 * warm - 0.55 * cool) * fade
        cov = fade * (1.0 if order == len(born) - 1 else 1 - merge)  # the top arrow survives the merge
        hw = 0.07 + 0.04 * seg(f, 6, 24)  # half-width: arrows start small and grow (reference full width 0.15 -> 0.23)
        arrow_field(fr, cx, y, hw * pop, (0.075 + 0.02 * seg(f, 6, 24)) * pop, 0.03, value, cov)  # about as tall as half its width: a solid ^, not a flat wing
    # the star with its round halo
    if 24 <= f < 40:
        a = seg(f, 24, 27); k = ease_out(a) * (1 - seg(f, 31, 40))
        sy = base_y - 0.07 * 2 * (1 - merge) - rise - 0.04
        fr.add((1.0, 0.85, 0.45), gauss(cx, sy, 0.11) * 0.7 * k)
        star4(fr, cx, sy, (0.06 + 0.012 * np.sin(f * 1.4)) * k + 1e-3, (1, 1, 0.95), k)
        fr.add((1, 1, 0.95), gauss(cx, sy, 0.012) * 1.6 * k)
    # dripping sparks: short streaks falling from the arrows, flickering
    if 7 <= f < 44:
        rng = np.random.default_rng(29)
        for i in range(90):
            t0 = 7 + rng.uniform(0, 32); x0 = cx + rng.uniform(-0.08, 0.08)
            y0 = base_y + 0.06 - rng.uniform(0, 0.14) - 0.12 * ease_out(seg(t0, 20, 32))
            if f < t0:
                continue
            s = f - t0; life = 1 - seg(s, 7, 15)  # drips fall all the way to the ring
            if life <= 0 or (i + int(f)) % 4 == 0:
                continue
            y = y0 + 0.006 * s + 0.0006 * s * s
            if i % 3 == 0:  # a third are round glints, the rest falling streaks
                fr.add((1.0, 0.9, 0.5), gauss(x0, y, 0.0045) * life * 1.4)
            else:
                fr.add((1.0, 0.85, 0.4), mask_line((x0, y - 0.03), (x0, y), 0.006) * life * 0.9 * (1 - seg(f, 34, 42)))
    fr.bloom(0.8, 0.15)
    return fr



# ------------------------------------------------------------------------------------------------ cooldown ready v2
# Quality rebuild 2026-10-28 from a dense frame study of the reference:
#  f0-2   a faint dotted square, fading away
#  f1-26  the comet: a SHARP LINE SEGMENT (about a fifth of a side long, white core, cyan fringe) runs one lap
#         clockwise from the top middle; it bends round corners as an L
#  f27    the slot flashes as a solid blue-grey tile, sparks shoot out as short radial lines
#  f28-33 the tile darkens and fades while the dotted border lights (cyan dashes with white highlights)
#  f28-30 READY pops in above with a big overshoot, bold white with a soft glow; holds
#  f34-53 border dashes SHIMMER every frame (the reference has almost no held frames); READY holds
#  f54-56 READY squashes into a thin line and vanishes; f57+ the faint dotted square stays
CD_BOX2 = (0.27, 0.29, 0.73, 0.75)  # measured on the reference's f27 tile; READY sits above it
CD_RAMP = [(0.0, (0.1, 0.35, 0.6)), (0.5, (0.35, 0.75, 0.95)), (0.85, (0.8, 0.95, 1.0)), (1.0, (1.0, 1.0, 1.0))]


def perim2(t, box=CD_BOX2):
    x0, y0, x1, y1 = box; w, h = x1 - x0, y1 - y0; L = 2 * (w + h)
    d = ((t % 1.0) * L + w / 2) % L  # wraps, so points just before the start sit on the left of the top edge
    for (ax, ay, bx, by, ln) in ((x0, y0, x1, y0, w), (x1, y0, x1, y1, h), (x1, y1, x0, y1, w), (x0, y1, x0, y0, h)):
        if d <= ln:
            u = d / ln; return ax + (bx - ax) * u, ay + (by - ay) * u
        d -= ln
    return x0, y0


def dashes(f, level, hot, box=CD_BOX2, seed=5, n=190):
    """the dotted border: short dashes along the edges; a third of them re-roll every frame (shimmer)"""
    m = np.zeros((S, S), np.float32)
    rng = np.random.default_rng(seed); fl = np.random.default_rng(seed * 100 + int(f))
    for i in range(n):
        t = rng.random(); x, y = perim2(t, box)
        on = fl.random() < (0.6 if i % 3 else 0.45)  # every dash flickers a little each frame: the reference has almost no holds
        if not on:
            continue
        L = 0.003 + 0.007 * rng.random()  # specks and short dashes with gaps (a solid line read as a box outline)
        x0, y0, x1, y1 = box
        horiz = abs(y - y0) < 1e-3 or abs(y - y1) < 1e-3
        p0 = (x - L, y) if horiz else (x, y - L); p1 = (x + L, y) if horiz else (x, y + L)
        m = np.maximum(m, mask_line(p0, p1, 0.008) * (0.6 + 0.4 * fl.random()))
    V = np.clip(m * (0.7 + 0.5 * hot), 0, 1)
    col = ramp(np.clip(V, 0, 1), CD_RAMP)
    a = np.clip(m, 0, 1) * level
    fr_c, fr_a = col * a[..., None], a
    return fr_c, fr_a


def bold_text(txt, cx, cy, h):
    m = np.zeros((S, S), np.uint8)
    font = cv2.FONT_HERSHEY_DUPLEX; scale = h * S / 20.0; th = max(2, int(scale * 4.2))
    (tw, tht), _ = cv2.getTextSize(txt, font, scale, th)
    cv2.putText(m, txt, (int(cx * S - tw / 2), int(cy * S + tht / 2)), font, scale, 255, th, cv2.LINE_AA)
    return m.astype(np.float32) / 255


def cooldown_ready(f):
    fr = Frame(); x0, y0, x1, y1 = CD_BOX2
    # the comet: a sharp line segment with a short soft tail, one clockwise lap
    if 1 <= f < 27:
        p = seg(f, 1, 33)  # the reference ends its run on the left edge (~0.86 of a lap), not back at the start
        seglen = min(0.13, 0.008 + p * 0.9)  # the line grows out of a point at the start
        pts = [perim2(p - k * seglen / 40) for k in range(41)]
        core = np.zeros((S, S), np.float32)
        for k in range(40):
            w = 0.014 * (1 - k / 40) ** 0.5 + 0.004
            core = np.maximum(core, mask_line(pts[k], pts[k + 1], w) * (1 - k / 44))
        tail = [perim2(p - seglen - k * 0.004) for k in range(12)]
        for k in range(11):
            core = np.maximum(core, mask_line(tail[k], tail[k + 1], 0.003) * 0.35 * (1 - k / 11))
        fr.add((0.7, 0.92, 1.0), cv2.GaussianBlur(core, (0, 0), S * 0.012) * 1.2)
        fr.over((1, 1, 1), core)
    # the flash: a solid blue-grey tile that darkens and fades; sparks shoot out
    if 27 <= f < 35:
        k = 1 - seg(f, 30, 35)
        tile = mask_poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])
        shade = 0.42 - 0.17 * seg(f, 27, 32)
        top = np.clip((y1 - YY) / (y1 - y0), 0, 1)[..., None]
        col = np.asarray((0.36, 0.48, 0.55)) * shade / 0.42 * (0.85 + 0.25 * top)
        a = tile * (0.95 if f < 28 else 0.85) * k
        fr.c = fr.c * (1 - a[..., None]) + col * a[..., None]; fr.a = a + fr.a * (1 - a)
        rng = np.random.default_rng(41)
        for i in range(40):
            t = rng.random(); x, y = perim2(t); cx_, cy_ = (x0 + x1) / 2, (y0 + y1) / 2
            d = np.array([x - cx_, y - cy_]); d /= np.linalg.norm(d) + 1e-6
            r0 = 0.005 + 0.04 * seg(f, 27, 32); r1 = r0 + 0.02
            fr.add((0.85, 0.95, 1.0), mask_line((x + d[0] * r0, y + d[1] * r0), (x + d[0] * r1, y + d[1] * r1), 0.003) * (1 - seg(f, 29, 33)) * 0.9)
    # the dotted border (drawn over the tile, so it lights through it)
    faint = (1 - seg(f, 0, 2.5)) if f < 3 else (0.4 * seg(f, 55, 58) if f >= 55 else 0)
    lit = seg(f, 27, 29) * (1 - seg(f, 54, 57))
    level = max(faint * 0.45, lit)
    if level > 0:
        c, a = dashes(f, level, lit)
        fr.c = fr.c * (1 - a[..., None]) + c; fr.a = a + fr.a * (1 - a)
        fr.add((0.35, 0.75, 1.0), cv2.GaussianBlur(a, (0, 0), S * 0.008) * 0.6 * lit)
    # READY: pops in with a big overshoot, holds, squashes into a line at the end
    if 28 <= f < 57:
        a = seg(f, 28, 31); pop = ease_out(a) * (1 + 0.35 * np.sin(np.pi * a))
        squash = seg(f, 53, 56.5)
        h = 0.085 * pop * (1 - 0.85 * squash) + 1e-3
        m = bold_text("READY", 0.5, 0.2, h)
        if squash > 0:  # flatten vertically toward a thin line
            ys = int(S * 0.2); sc = max(1 - 0.9 * squash, 0.08)
            M = np.float32([[1 - 0.5 * squash, 0, S * 0.5 * 0.5 * squash], [0, sc, ys * (1 - sc)]])
            m = cv2.warpAffine(m, M, (S, S))
        fr.add((0.75, 0.9, 1.0), cv2.GaussianBlur(m, (0, 0), S * 0.018) * 0.9)
        fr.over((1, 1, 1), m)
    fr.bloom(0.75, 0.25)
    return fr



# ------------------------------------------------------------------------------------------------ badge pop v2
# Quality rebuild 2026-10-28 from a dense frame study of the reference:
#  f0-3   pink dust specks fading in place (the gather)
#  f4     a pure white disc
#  f5     overshoot: pale pink disc with a white ring just inside its rim, "1" appears
#  f6     red badge, the white ring now on the rim, gold sparkles
#  f7-13  a THICK DARK HALO opens round the badge with a soft pink glow outside it; it widens and fades by ~f14
#  f14-17 plain badge (no halo), lit top-left
#  f18-19 next pop: the badge flashes pale pink (digit morphs) and overshoots; same ring/halo sequence -> "2"; f31 -> "3"
#  f56-57 the badge shrinks; f58 it bursts into pink/white specks that drift out and twinkle until f63
BG2_RED, BG2_LIGHT, BG2_PALE = (0.98, 0.22, 0.33), (1.0, 0.5, 0.56), (1.0, 0.76, 0.8)  # saturated red, as the reference
BG2_POPS = ((4, "1"), (18, "2"), (31, "3"))


def sparkle4(fr, x, y, r, color, cov):
    if cov <= 0 or r <= 1e-4:
        return
    fr.add(color, (mask_line((x - r, y), (x + r, y), r * 0.3) + mask_line((x, y - r), (x, y + r), r * 0.3)) * cov)


def badge_pop(f):
    fr = Frame(); cx, cy = 0.5, 0.49; R = 0.26  # measured: the reference badge is ~0.52 of the cell wide
    dist = np.hypot(XX - cx, YY - cy)
    rng = np.random.default_rng(23)
    dust = [(rng.uniform(0, TAU), rng.uniform(0.08, 0.3), rng.uniform(0.004, 0.008), i % 3) for i in range(22)]
    if f < 4:  # the gather: specks fading where they are
        for a, r0, sz, kind in dust:
            col = (1, 0.9, 0.92) if kind == 0 else BG2_LIGHT
            fr.add(col, gauss(cx + np.cos(a) * r0, cy + np.sin(a) * r0 * 0.8, sz) * 1.3 * (1 - seg(f, 0, 3.5)))
    if f >= 58:  # the burst: specks thrown out from the badge, drifting and twinkling
        s = f - 57.5
        for i, (a, r0, sz, kind) in enumerate(dust):
            r = R * 0.3 + (r0 + 0.04) * ease_out(seg(s, 0, 3))
            tw = 0.55 + 0.45 * np.sin(s * 1.8 + i)
            col = (1, 0.9, 0.92) if kind == 0 else BG2_LIGHT
            fr.add(col, gauss(cx + np.cos(a) * r, cy + np.sin(a) * r * 0.8 + 0.003 * s, sz) * 1.4 * tw * (1 - seg(s, 3, 6.5)))
    if not (4 <= f < 59):
        fr.bloom(0.75, 0.25)
        return fr
    pop_t, digit = BG2_POPS[0]
    for t0, dg in BG2_POPS:
        if f >= t0:
            pop_t, digit = t0, dg
    s = f - pop_t
    first = pop_t == 4
    # size: overshoot then settle; the end shrink
    size = {0: 1.0, 1: 1.2, 2: 1.06}.get(int(s), 1.0) if s < 3 else 1.0
    size *= 1 - 0.55 * seg(f, 55, 58.5)
    r = R * size
    # the dark halo with the pink glow outside it, opening and fading after each pop
    if 2.5 <= s < 12:
        h = seg(s, 2.5, 7); k = 1 - seg(s, 7, 10)
        inner, outer = r * 1.02, r * (1.14 + 0.12 * h)
        fr.add((1.0, 0.45, 0.55), smooth(outer + 0.06, outer, dist) * smooth(inner, outer, dist) * 0.45 * k)
        fr.over((0.1, 0.06, 0.07), smooth(inner - 0.005, inner + 0.008, dist) * smooth(outer + 0.006, outer - 0.01, dist) * 0.88 * k)
    # the badge body: red, lit top-left, darker rim; pale during a pop
    body = smooth(r + 0.004, r - 0.004, dist)
    lit = np.clip(1.0 - np.hypot(XX - (cx - r * 0.35), YY - (cy - r * 0.4)) / (r * 1.7), 0, 1)[..., None]
    pale = 1.0 if s < 1 else (0.75 if s < 2 else (0.2 if s < 3 else 0.0))
    if first and s < 1:
        col = np.ones((S, S, 3), np.float32)  # the very first frame is a pure white disc
    else:
        base = np.asarray(BG2_RED) * (1 - lit) + np.asarray(BG2_LIGHT) * lit
        rim = smooth(r * 0.82, r, dist)[..., None]
        base = base * (1 - 0.18 * rim)
        col = base * (1 - pale) + np.asarray(BG2_PALE) * pale
    fr.c = fr.c * (1 - body[..., None]) + col * body[..., None]; fr.a = body + fr.a * (1 - body)
    # the white ring inside the rim (s1) then on the rim (s2)
    if s < 3:  # the pop lights the air round the badge pink (outside the body only, or the pale disc blows out)
        fr.add((1.0, 0.5, 0.6), smooth(r * 1.35, r, dist) * (1 - body) * (0.5 if s < 2 else 0.25))
    if 1 <= s < 3:
        rr = r * (0.84 if s < 2 else 0.98)
        fr.add((1, 1, 1), smooth(0.012, 0.0, np.abs(dist - rr)) * (1.0 if s < 2 else 0.7))
    # the digit (not on the pure white frame); morphs through pale during a pop
    if not (first and s < 1):
        shown = digit
        if s < 1 and not first:  # on the pale flash frame the old digit breaks up (the reference's glitch morph)
            shown = BG2_POPS[[t for t, _ in BG2_POPS].index(pop_t) - 1][1]
        m = bold_text(shown, cx + 0.004, cy + 0.006, r * 0.95)
        if s < 1 and not first:
            m = m * (np.random.default_rng(int(f)).random((S, S)) > 0.45).astype(np.float32)
        m = cv2.dilate(m, np.ones((3, 3), np.uint8))  # blocky, heavy numerals like the reference
        fr.over((0.55, 0.1, 0.16), cv2.GaussianBlur(m, (0, 0), 1.6) * 0.5 * (1 - pale))
        fr.over((1, 1, 1), m * (0.8 + 0.2 * (1 - pale)))
    # gold sparkles round the badge just after each pop
    if 1 <= s < 9:
        rs = np.random.default_rng(int(pop_t) * 7)
        for i in range(8):
            a = rs.uniform(0, TAU); rr = r * rs.uniform(1.12, 1.35)
            tw = 0.5 + 0.5 * np.sin(f * 2.1 + i * 1.3)
            sparkle4(fr, cx + np.cos(a) * rr, cy + np.sin(a) * rr, 0.009, (1, 0.9, 0.55), (1 - seg(s, 5, 9)) * tw)
    fr.bloom(0.8, 0.2)
    return fr


def render(fn, out):
    sheet = np.zeros((1024, 1024, 4), np.float32)
    for i in range(64):
        r, c = divmod(i, 8)
        sheet[r * 128:(r + 1) * 128, c * 128:(c + 1) * 128] = fn(float(i)).rgba()
    Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8), "RGBA").save(out)


if __name__ == "__main__":
    render({"egg_hatch": egg_hatch, "coin_drop": coin_drop, "tower_upgrade": tower_upgrade, "tower_upgrade_v1": tower_upgrade_v1, "splash_ring": splash_ring, "splash_ring_v1": splash_ring_v1, "cooldown_ready": cooldown_ready, "cooldown_ready_v1": cooldown_ready_v1, "frost_nova": frost_nova, "frost_nova_v1": frost_nova_v1, "badge_pop": badge_pop, "badge_pop_v1": badge_pop_v1}[sys.argv[1]], sys.argv[2])
    print("wrote", sys.argv[2])
