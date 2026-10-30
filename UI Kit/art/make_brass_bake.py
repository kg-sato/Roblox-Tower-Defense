"""Baked brass HUD plates (hud-design, 2026-10-30). Procedural, no GPU: a height field per piece (bevelled rim, twisted rope,
Art Nouveau whiplash coils in the corners, domed rivets, recessed enamel or amber glass), lit from the top left with
diffuse + specular + ambient occlusion, rendered at 2x and downsampled. Outputs UI Kit/art/hud_art/final/b_*.png.
Run with the Hunyuan3D venv (numpy, scipy, Pillow): Hunyuan3D/.venv/Scripts/python -I "UI Kit/art/make_brass_bake.py"
Pieces: b_plate (9-slice, corners 80 px of 512x192: SliceCenter 80,80,432,112), b_roll (stretch 640x248, amber glass),
b_disc (512 round medallion, dark enamel centre), b_panel (9-slice 512x512, corners 120: SliceCenter 120,120,392,392)."""
import os, math
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hud_art", "final")
SS = 2  # supersample
rng = np.random.default_rng(7)


def rrect_sdf(w, h, m, r):
    """signed distance inside a rounded rect (positive inside), in pixels"""
    y, x = np.mgrid[0:h, 0:w].astype(np.float32) + 0.5
    cx, cy = w / 2, h / 2
    qx = np.abs(x - cx) - (w / 2 - m - r)
    qy = np.abs(y - cy) - (h / 2 - m - r)
    out = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
    return -out, x, y


def circle_sdf(w, h, r):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32) + 0.5
    return r - np.hypot(x - w / 2, y - h / 2), x, y


def smooth(a, b, t):
    t = np.clip((t - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def whiplash(draw, ox, oy, sx, sy, s, width):
    """one Art Nouveau whiplash: an S-curve leaving the corner that ends in a tight coil; (sx, sy) mirror the corner"""
    pts = []
    for i in range(60):  # the long S
        t = i / 59
        x = t * 1.0
        y = 0.18 * math.sin(t * math.pi * 1.15) + 0.04 * t
        pts.append((x, y))
    cx, cy = pts[-1][0] + 0.0, pts[-1][1] + 0.16  # coil centre below the end
    a0 = math.atan2(pts[-1][1] - cy, pts[-1][0] - cx)
    for i in range(1, 70):  # inward spiral
        t = i / 69
        a = a0 - t * math.pi * 2.3
        rr = 0.16 * (1 - 0.78 * t)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    P = [(ox + sx * px * s, oy + sy * py * s) for px, py in pts]
    draw.line(P, fill=255, width=width, joint="curve")
    # a second, shorter tendril branching back toward the corner
    Q = []
    for i in range(40):
        t = i / 39
        Q.append((0.05 + 0.5 * t, 0.42 - 0.22 * math.sin(t * math.pi * 0.9) - 0.1 * t))
    bx, by = Q[-1][0] + 0.0, Q[-1][1] - 0.08
    a0 = math.atan2(Q[-1][1] - by, Q[-1][0] - bx)
    for i in range(1, 40):
        t = i / 39
        a = a0 + t * math.pi * 1.9
        rr = 0.08 * (1 - 0.7 * t)
        Q.append((bx + rr * math.cos(a), by + rr * math.sin(a)))
    Q = [(ox + sx * px * s, oy + sy * py * s) for px, py in Q]
    draw.line(Q, fill=255, width=max(2, int(width * 0.75)), joint="curve")
    # rotate the whole thing so it hugs both edges: mirror along the diagonal too
    P2 = [(ox + sx * py * s, oy + sy * px * s) for px, py in pts]
    draw.line(P2, fill=255, width=width, joint="curve")


def wire_height(mask, rad):
    """round profile for a drawn wire mask"""
    d = nd.distance_transform_edt(mask > 127)
    return np.sqrt(np.clip(1 - (1 - np.clip(d / rad, 0, 1)) ** 2, 0, 1))


def shade(H, albedo, spec_k, rough, alpha, ao_r=6, light=(-0.55, -0.7, 0.75)):
    gy, gx = np.gradient(H)
    n = np.dstack([-gx, -gy, np.ones_like(H)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    L = np.array(light, np.float32)
    L /= np.linalg.norm(L)
    V = np.array([0, 0, 1.0], np.float32)
    Hh = (L + V) / np.linalg.norm(L + V)
    diff = np.clip((n * L).sum(2), 0, 1)
    sp = np.clip((n * Hh).sum(2), 0, 1) ** rough
    # ambient occlusion: lower than the local average = darker
    ao = np.clip(1 - 2.2 * np.clip(nd.gaussian_filter(H, ao_r) - H, 0, None), 0.25, 1)
    # environment band reflection (fake studio strip) for metal: depends on normal y
    env = 0.35 + 0.65 * smooth(-0.6, 0.4, -n[..., 1])
    col = albedo * (0.22 + 0.78 * diff[..., None] * env[..., None]) * ao[..., None]
    col += spec_k[..., None] * sp[..., None] * np.array([1.0, 0.93, 0.78]) * ao[..., None]
    rgb = np.clip(col, 0, 1)
    return np.dstack([rgb, alpha])


def brass_albedo(shape, x, y):
    base = np.array([0.80, 0.60, 0.30], np.float32)
    brushed = nd.gaussian_filter(rng.standard_normal(shape).astype(np.float32), (0.6, 9))
    blot = nd.gaussian_filter(rng.standard_normal(shape).astype(np.float32), 18)
    a = base[None, None, :] * (1 + 0.10 * brushed[..., None] / brushed.std() * 0.5)
    patina = smooth(0.6, 1.6, blot / blot.std())  # darker aged patches
    a = a * (1 - 0.10 * patina[..., None]) + np.array([0.25, 0.20, 0.12]) * 0.28 * patina[..., None] * 0.4
    return np.clip(a, 0, 1)


def frame(w, h, margin, radius, rim, corner, interior="enamel", coil_s=None, rivets=True, coil_w=None):
    W, Hh = w * SS, h * SS
    m, r, rim, = margin * SS, radius * SS, rim * SS
    d, x, y = rrect_sdf(W, Hh, m, r)
    alpha = smooth(-1.0 * SS, 0.6 * SS, d)
    # rim: rounded bevel 0..rim, a groove, twisted rope, a step down into the recess
    Hm = np.zeros_like(d)
    t = np.clip(d / rim, 0, 1)
    Hm += np.where(d < rim, 0.55 + 0.45 * np.sin(t * math.pi * 0.5) - 0.35 * smooth(0.75, 1.0, t), 0)
    rope_in, rope_w = rim + 2 * SS, 9 * SS
    on_rope = (d >= rope_in) & (d < rope_in + rope_w)
    u = (d - rope_in) / rope_w
    phase = (x + y) * (2 * math.pi / (11 * SS)) + u * 5.0
    rope = np.sqrt(np.clip(1 - (2 * u - 1) ** 2, 0, 1)) * (0.55 + 0.45 * np.cos(phase) ** 2)
    Hm = np.where(on_rope, 0.35 + 0.5 * rope, Hm)
    groove = (d >= rim) & (d < rope_in)
    Hm = np.where(groove, 0.25, Hm)
    inner = d >= rope_in + rope_w
    # recess: a short inner slope then flat
    k = np.clip((d - rope_in - rope_w) / (4 * SS), 0, 1)
    Hm = np.where(inner, 0.32 - 0.24 * k, Hm)
    metal = ~inner
    # corner coils (raised brass wire on the enamel)
    cm = Image.new("L", (W, Hh), 0)
    dr = ImageDraw.Draw(cm)
    inset = rope_in + rope_w + 3 * SS
    s = (coil_s or (corner - inset / SS - 6)) * SS
    cw = (coil_w or 3) * SS
    if s > 6 * SS:
        for sx, sy, ox, oy in ((1, 1, inset, inset), (-1, 1, W - inset, inset), (1, -1, inset, Hh - inset), (-1, -1, W - inset, Hh - inset)):
            whiplash(dr, ox, oy, sx, sy, s, cw)
    cmask = np.array(cm)
    wire = wire_height(cmask, cw / 2) * inner
    Hm = Hm + 0.42 * wire
    metal = metal | (wire > 0.02)
    # rivets on the rim at the corner diagonals and mid edges
    if rivets:
        rr = max(4, rim / SS * 0.36) * SS
        cd = m + r * (1 - 1 / math.sqrt(2)) + rim * 0.55 / math.sqrt(2) + rim * 0.2
        spots = [(cd, cd), (W - cd, cd), (cd, Hh - cd), (W - cd, Hh - cd)]
        for cx, cy in spots:
            q = np.hypot(x - cx, y - cy) / rr
            dome = np.sqrt(np.clip(1 - q ** 2, 0, 1))
            Hm = np.maximum(Hm, np.where(q < 1, 0.75 + 0.55 * dome, -1))
    H = nd.gaussian_filter(Hm, 0.8 * SS) * 9 * SS
    alb = brass_albedo(H.shape, x, y)
    spec = np.where(metal, 0.85, 0.25).astype(np.float32)
    if interior == "enamel":
        vig = smooth(0, 60 * SS, d - inset)
        en = np.array([0.105, 0.070, 0.062]) * (0.75 + 0.35 * vig[..., None])
        en = en + 0.025 * nd.gaussian_filter(rng.standard_normal(H.shape), 1.2)[..., None]
        alb = np.where(metal[..., None], alb, en)
        spec = np.where(metal, 0.85, 0.12)
    elif interior == "glass":
        # amber glass: dark rim, glowing lower centre (light through the glass), a sharp highlight band on top
        gd = np.clip((d - rope_in - rope_w) / ((h / 2 - margin - rim - 11) * SS), 0, 1)
        vy = (y - (m + rope_in + rope_w)) / (Hh - 2 * (m + rope_in + rope_w))
        dome = np.sqrt(np.clip(1 - (1 - gd) ** 2, 0, 1))
        core = np.array([1.0, 0.68, 0.20]); body = np.array([0.88, 0.38, 0.06]); edge = np.array([0.30, 0.07, 0.02])
        g = body * (1 - smooth(0.2, 0.9, gd))[..., None] + core * smooth(0.2, 0.9, gd)[..., None]
        g = g * (0.8 + 0.25 * vy[..., None])  # lit from inside, warmer low
        e = 1 - smooth(0.0, 0.4, gd)
        g = g * (1 - 0.85 * e[..., None]) + edge * 0.85 * e[..., None]
        GLASS = np.clip(g, 0, 1)
        alb = np.where(metal[..., None], alb, GLASS)
        spec = np.where(metal, 0.85, 0.0)
    img = shade(H, alb, np.asarray(spec, np.float32), 40, alpha)
    if interior == "glass":  # emissive glass, a crisp highlight band on top, a caustic line low
        band = smooth(0.15, 0.45, gd) * smooth(0.02, 0.07, vy) * (1 - smooth(0.2, 0.34, vy))
        caus = smooth(0.25, 0.6, gd) * smooth(0.78, 0.86, vy) * (1 - smooth(0.88, 0.95, vy))
        gl = GLASS + 0.45 * band[..., None] * np.array([1.0, 0.97, 0.9]) + 0.25 * caus[..., None] * np.array([1.0, 0.9, 0.5])
        img[..., :3] = np.where(metal[..., None], img[..., :3], np.clip(gl, 0, 1))
    if interior == "clear":
        img[..., 3] = np.where(metal, img[..., 3], 0)
    im = Image.fromarray((img * 255).astype(np.uint8), "RGBA").resize((w, h), Image.LANCZOS)
    return im


def disc(size, rim):
    W = size * SS
    d, x, y = circle_sdf(W, W, W / 2 - 3 * SS)
    alpha = smooth(-1.0 * SS, 0.6 * SS, d)
    R = rim * SS
    t = np.clip(d / R, 0, 1)
    Hm = np.where(d < R, 0.55 + 0.45 * np.sin(t * math.pi * 0.5) - 0.3 * smooth(0.75, 1, t), 0)
    rope_in, rope_w = R + 2 * SS, 10 * SS
    on = (d >= rope_in) & (d < rope_in + rope_w)
    u = (d - rope_in) / rope_w
    ang = np.arctan2(y - W / 2, x - W / 2)
    rope = np.sqrt(np.clip(1 - (2 * u - 1) ** 2, 0, 1)) * (0.55 + 0.45 * np.cos(ang * 36 + u * 5) ** 2)
    Hm = np.where(on, 0.35 + 0.5 * rope, Hm)
    Hm = np.where((d >= R) & (d < rope_in), 0.25, Hm)
    inner = d >= rope_in + rope_w
    Hm = np.where(inner, 0.3 - 0.22 * np.clip((d - rope_in - rope_w) / (4 * SS), 0, 1), Hm)
    metal = ~inner
    for i in range(8):  # rivets around the rim
        a = i * math.pi / 4 + math.pi / 8
        cr = W / 2 - 3 * SS - R * 0.5
        cx, cy = W / 2 + cr * math.cos(a), W / 2 + cr * math.sin(a)
        q = np.hypot(x - cx, y - cy) / (R * 0.3)
        Hm = np.maximum(Hm, np.where(q < 1, 0.75 + 0.5 * np.sqrt(np.clip(1 - q ** 2, 0, 1)), -1))
    H = nd.gaussian_filter(Hm, 0.8 * SS) * 9 * SS
    alb = brass_albedo(H.shape, x, y)
    vig = smooth(0, W * 0.3, d - rope_in - rope_w)
    en = np.array([0.10, 0.065, 0.075]) * (0.7 + 0.4 * vig[..., None])
    alb = np.where(metal[..., None], alb, en)
    img = shade(H, alb, np.where(metal, 0.85, 0.15).astype(np.float32), 40, alpha)
    return Image.fromarray((img * 255).astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    pieces = {
        "b_plate": frame(512, 192, 4, 34, 16, 80),
        "b_panel": frame(512, 512, 4, 46, 20, 120, coil_s=82, coil_w=4),
        "b_roll": frame(640, 248, 4, 60, 22, 0, interior="glass", coil_s=1),
        "b_disc": disc(512, 30),
    }
    for k, im in pieces.items():
        p = os.path.join(OUT, k + ".png")
        im.save(p)
        print(p, im.size)
    # contact sheet on a dark board for review
    sheet = Image.new("RGBA", (1300, 820), (30, 34, 44, 255))
    sheet.alpha_composite(pieces["b_plate"], (20, 20))
    sheet.alpha_composite(pieces["b_roll"], (560, 20))
    sheet.alpha_composite(pieces["b_panel"].resize((380, 380)), (20, 300))
    sheet.alpha_composite(pieces["b_disc"].resize((300, 300)), (440, 300))
    wide = pieces["b_plate"]  # 9-slice preview stretched to a long strip
    sheet.alpha_composite(nine(wide, (80, 80, 432, 112), (520, 90), 80), (760, 300))
    sheet.alpha_composite(nine(wide, (80, 80, 432, 112), (140, 360), 50), (780, 420))
    sheet.save(os.path.join(OUT, "b_sheet.png"))


def nine(im, c, size, corner_px):
    """quick 9-slice preview: corners scaled to corner_px"""
    l, t, r, b = c
    W, H = im.size
    sw, sh = size
    s = corner_px / l
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    xs = [(0, l, 0, int(l * s)), (l, r, int(l * s), sw - int((W - r) * s)), (r, W, sw - int((W - r) * s), sw)]
    ys = [(0, t, 0, int(t * s)), (t, b, int(t * s), sh - int((H - b) * s)), (b, H, sh - int((H - b) * s), sh)]
    for x0, x1, X0, X1 in xs:
        for y0, y1, Y0, Y1 in ys:
            if X1 > X0 and Y1 > Y0:
                out.alpha_composite(im.crop((x0, y0, x1, y1)).resize((X1 - X0, Y1 - Y0), Image.LANCZOS), (X0, Y0))
    return out


if __name__ == "__main__":
    main()
