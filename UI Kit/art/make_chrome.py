"""Generates the UI "chrome" sprites (buttons, panels, headers, bars, cards, badges, icons) as transparent PNGs.

Run:  python -I "UI Kit/art/make_chrome.py"
Out:  UI Kit/art/out/<name>.png  +  UI Kit/art/out/manifest.json  +  UI Kit/art/out/_sheet.png (contact sheet)

Why this exists: the paid UI generators look good because their UI is built from real artwork (glossy bevelled
buttons, outlined panels, rendered icons), not from flat frames and emoji. This script draws that artwork
procedurally, at 4x supersampling for clean edges, so it is free, repeatable and tweakable in one place.
Everything is original; nothing is copied from the reference screenshots.

9-slice sprites list `slice` = [left, top, right, bottom] inset in source pixels (use as
ImageLabel.SliceCenter = Rect(l, t, W - r, H - b) with ScaleType = Slice).
"""
import io
import json
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)
SS = 4  # supersampling factor

OUTLINE = (18, 18, 30)

# base colours (match UITheme.Candy tokens)
COLORS = {
    "green": (92, 214, 56),
    "blue": (40, 170, 255),
    "red": (240, 62, 62),
    "yellow": (255, 214, 40),
    "orange": (255, 150, 40),
    "purple": (160, 90, 255),
    "pink": (255, 100, 190),
    "gray": (120, 124, 140),
    "dark": (46, 46, 60),
    "night": (66, 44, 124),  # deep purple, header for the Pixel and Aura themes
}


def shade(c, f):
    return tuple(int(v * (1 - f)) for v in c)


def tint(c, f):
    return tuple(int(v + (255 - v) * f) for v in c)


def vgrad(w, h, top, bottom):
    """Vertical gradient RGBA image."""
    g = Image.new("RGBA", (1, h))
    px = g.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
    return g.resize((w, h))


def alpha_grad(w, h, a_top, a_bottom, color=(255, 255, 255)):
    g = Image.new("RGBA", (1, h))
    px = g.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px[0, y] = color + (int(a_top + (a_bottom - a_top) * t),)
    return g.resize((w, h))


def rmask(w, h, r, corners=(True, True, True, True)):
    """Rounded rectangle mask at SS resolution. w,h,r in final pixels."""
    m = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], radius=r * SS, fill=255, corners=corners)
    return m


def put(canvas, layer, x, y, mask=None):
    """Alpha-composite `layer` onto `canvas` at (x,y) in SS pixels, optionally through a mask."""
    if mask is not None:
        a = layer.getchannel("A")
        a = ImageChops.multiply(a, mask)
        layer = layer.copy()
        layer.putalpha(a)
    tmp = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    tmp.paste(layer, (x, y))
    return Image.alpha_composite(canvas, tmp)


def down(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


# ---------------------------------------------------------------------------------------------
# glossy rounded button / header / bar
# ---------------------------------------------------------------------------------------------
def glossy(W, H, r, base, outline=OUTLINE, o=8, lip=14, corners=(True, True, True, True), gloss=0.5, lip_on=True):
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = put(canvas, Image.new("RGBA", canvas.size, outline + (255,)), 0, 0, rmask(W, H, r, corners))
    iw, ih = W - 2 * o, H - 2 * o
    ir = max(r - o, 2)
    inner = Image.new("RGBA", (iw * SS, ih * SS), shade(base, 0.38) + (255,))
    lip_h = lip if lip_on else 0
    fh = ih - lip_h
    face = vgrad(iw * SS, fh * SS, tint(base, 0.36), shade(base, 0.06))
    inner = put(inner, face, 0, 0, rmask(iw, fh, ir, (corners[0], corners[1], True, True) if lip_on else corners))
    if gloss > 0:
        gh = int(fh * gloss)
        gl = alpha_grad((iw - 14) * SS, gh * SS, 105, 10)
        gm = rmask(iw - 14, gh, max(ir - 4, 2), (corners[0], corners[1], False, False))
        inner = put(inner, gl, 7 * SS, 5 * SS, gm)
    canvas = put(canvas, inner, o * SS, o * SS, rmask(iw, ih, ir, corners))
    return down(canvas, W, H)


def panel(W, H, r, body_top, body_bottom, border=(18, 18, 30), o=12, rim=(255, 255, 255, 40), corners=(True,) * 4):
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = put(canvas, Image.new("RGBA", canvas.size, border + (255,)), 0, 0, rmask(W, H, r, corners))
    iw, ih = W - 2 * o, H - 2 * o
    ir = max(r - o, 2)
    body = vgrad(iw * SS, ih * SS, body_top, body_bottom)
    canvas = put(canvas, body, o * SS, o * SS, rmask(iw, ih, ir, corners))
    # thin light rim just inside the border
    ring = Image.new("L", (iw * SS, ih * SS), 0)
    d = ImageDraw.Draw(ring)
    d.rounded_rectangle([0, 0, iw * SS - 1, ih * SS - 1], radius=ir * SS, outline=255, width=3 * SS, corners=corners)
    rimlayer = Image.new("RGBA", (iw * SS, ih * SS), rim)
    canvas = put(canvas, rimlayer, o * SS, o * SS, ring)
    return down(canvas, W, H)


def pill_dark(W, H):
    base = (30, 30, 44)
    img = glossy(W, H, H // 2, base, o=6, lip=0, gloss=0.0, lip_on=False)
    return img


def bar_track(W, H):
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = put(canvas, Image.new("RGBA", canvas.size, OUTLINE + (255,)), 0, 0, rmask(W, H, H // 2))
    o = 6
    iw, ih = W - 2 * o, H - 2 * o
    inner = vgrad(iw * SS, ih * SS, (14, 14, 22), (46, 46, 62))
    canvas = put(canvas, inner, o * SS, o * SS, rmask(iw, ih, ih // 2))
    return down(canvas, W, H)


def bar_fill(W, H, base):
    return glossy(W, H, H // 2, base, o=5, lip=0, gloss=0.55, lip_on=False)


def close_button(S):
    img = glossy(S, S, int(S * 0.26), COLORS["red"], o=9, lip=12, gloss=0.5)
    big = img.resize((S * SS, S * SS), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    c = S * SS // 2
    arm = int(S * SS * 0.2)
    wth = int(S * SS * 0.13)
    for sign in (1, -1):
        d.line([(c - arm, c - sign * arm - 6 * SS), (c + arm, c + sign * arm - 6 * SS)], fill=OUTLINE + (255,), width=wth + 10 * SS)
    for sign in (1, -1):
        d.line([(c - arm, c - sign * arm - 6 * SS), (c + arm, c + sign * arm - 6 * SS)], fill=(255, 255, 255, 255), width=wth)
    return down(big, S, S)


def badge(S):
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    d.ellipse([0, 0, S * SS - 1, S * SS - 1], fill=OUTLINE + (255,))
    b = int(S * SS * 0.06)
    d.ellipse([b, b, S * SS - 1 - b, S * SS - 1 - b], fill=(255, 255, 255, 255))
    b2 = int(S * SS * 0.11)
    inner = vgrad(S * SS - 2 * b2, S * SS - 2 * b2, tint(COLORS["red"], 0.3), shade(COLORS["red"], 0.12))
    m = Image.new("L", inner.size, 0)
    ImageDraw.Draw(m).ellipse([0, 0, inner.width - 1, inner.height - 1], fill=255)
    canvas = put(canvas, inner, b2, b2, m)
    gl = alpha_grad(inner.width - 20 * SS, int(inner.height * 0.42), 120, 5)
    gm = Image.new("L", gl.size, 0)
    ImageDraw.Draw(gm).ellipse([0, 0, gl.width - 1, gl.height * 2 - 1], fill=255)
    gm = gm.crop((0, 0, gl.width, gl.height))
    canvas = put(canvas, gl, b2 + 10 * SS, b2 + 6 * SS, gm)
    return down(canvas, S, S)


def slot(S):
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    canvas = put(canvas, Image.new("RGBA", canvas.size, OUTLINE + (255,)), 0, 0, rmask(S, S, 30))
    o = 8
    iw = S - 2 * o
    inner = vgrad(iw * SS, iw * SS, (16, 16, 28), (36, 36, 54))
    canvas = put(canvas, inner, o * SS, o * SS, rmask(iw, iw, 24))
    # inset shadow along the top
    sh = alpha_grad(iw * SS, 22 * SS, 130, 0, (0, 0, 0))
    canvas = put(canvas, sh, o * SS, o * SS, rmask(iw, 22, 14, (True, True, False, False)))
    return down(canvas, S, S)


def card_frame(W, H, base):
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = put(canvas, Image.new("RGBA", canvas.size, OUTLINE + (255,)), 0, 0, rmask(W, H, 52))
    o1 = 10
    iw, ih = W - 2 * o1, H - 2 * o1
    col = vgrad(iw * SS, ih * SS, tint(base, 0.3), shade(base, 0.12))
    canvas = put(canvas, col, o1 * SS, o1 * SS, rmask(iw, ih, 44))
    o2 = 26
    jw, jh = W - 2 * o2, H - 2 * o2
    body = vgrad(jw * SS, jh * SS, (36, 36, 52), (22, 22, 34))
    canvas = put(canvas, body, o2 * SS, o2 * SS, rmask(jw, jh, 30))
    # glossy light on the coloured rim (top only)
    gl = alpha_grad(iw * SS, 26 * SS, 100, 0)
    canvas = put(canvas, gl, o1 * SS, o1 * SS, rmask(iw, 26, 14, (True, True, False, False)))
    return down(canvas, W, H)


# ---------------------------------------------------------------------------------------------
# soft effects
# ---------------------------------------------------------------------------------------------
def glow_soft(S):
    img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    px = img.load()
    c = (S - 1) / 2
    for y in range(S):
        for x in range(S):
            d = math.hypot(x - c, y - c) / c
            a = max(0.0, 1 - d)
            px[x, y] = (255, 255, 255, int(255 * a * a))
    return img


def sunburst(S, rays=14):
    canvas = Image.new("RGBA", (S * 2, S * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    c = S
    for i in range(rays):
        a0 = math.radians(i * 360 / rays)
        a1 = math.radians((i + 0.5) * 360 / rays)
        d.polygon([(c, c), (c + S * 1.6 * math.cos(a0), c + S * 1.6 * math.sin(a0)), (c + S * 1.6 * math.cos(a1), c + S * 1.6 * math.sin(a1))], fill=(255, 255, 255, 255))
    canvas = canvas.resize((S, S), Image.LANCZOS)
    # fade towards the edge
    fade = glow_soft(S).getchannel("A").point(lambda v: int(v ** 0.5) if v else 0)
    a = ImageChops.multiply(canvas.getchannel("A"), fade)
    canvas.putalpha(a.point(lambda v: int(v * 0.55)))
    return canvas


# ---------------------------------------------------------------------------------------------
# vector icons (3D-ish: outline, gradient, gloss)
# ---------------------------------------------------------------------------------------------
def scale_pts(pts, s, cx=0.5, cy=0.5):
    return [(cx + (x - cx) * s, cy + (y - cy) * s) for x, y in pts]


def icon_from_polys(S, polys, top, bottom, inner_scale=0.86, outline=OUTLINE, extras=None):
    """polys: list of normalised point lists (0..1). Draws outline, gradient body, gloss."""
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    mask_in = Image.new("L", canvas.size, 0)
    d_in = ImageDraw.Draw(mask_in)
    mask_out = Image.new("L", canvas.size, 0)
    d_out = ImageDraw.Draw(mask_out)
    for pts in polys:
        d_out.polygon([(x * S * SS, y * S * SS) for x, y in pts], fill=255)
        d_in.polygon([(x * S * SS, y * S * SS) for x, y in scale_pts(pts, inner_scale)], fill=255)
    canvas = put(canvas, Image.new("RGBA", canvas.size, outline + (255,)), 0, 0, mask_out)
    body = vgrad(S * SS, S * SS, top, bottom)
    canvas = put(canvas, body, 0, 0, mask_in)
    # gloss band across the upper third, clipped to the body
    gl = alpha_grad(S * SS, int(S * SS * 0.45), 110, 0)
    gmask = Image.new("L", canvas.size, 0)
    gmask.paste(mask_in.crop((0, 0, S * SS, int(S * SS * 0.45))), (0, 0))
    canvas = put(canvas, gl, 0, 0, gmask)
    if extras:
        canvas = extras(canvas, S)
    return down(canvas, S, S)


def circle_pts(cx, cy, r, n=64):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def icon_coin(S):
    def extras(canvas, S):
        d = ImageDraw.Draw(canvas)
        c = S * SS / 2
        r = S * SS * 0.30
        d.ellipse([c - r, c - r, c + r, c + r], outline=shade((255, 190, 30), 0.35) + (255,), width=int(S * SS * 0.045))
        # simple star embossed in the middle
        pts = []
        for i in range(10):
            ang = -math.pi / 2 + i * math.pi / 5
            rad = S * SS * (0.16 if i % 2 == 0 else 0.07)
            pts.append((c + rad * math.cos(ang), c + rad * math.sin(ang)))
        d.polygon(pts, fill=shade((255, 190, 30), 0.3) + (255,))
        return canvas
    return icon_from_polys(S, [circle_pts(0.5, 0.5, 0.46)], (255, 236, 110), (240, 160, 20), 0.9, extras=extras)


def icon_gem(S):
    pts = [(0.5, 0.06), (0.88, 0.34), (0.5, 0.94), (0.12, 0.34)]

    def extras(canvas, S):
        d = ImageDraw.Draw(canvas)
        k = S * SS
        light = (190, 240, 255, 255)
        dark = (30, 120, 210, 255)
        d.polygon([(0.5 * k, 0.12 * k), (0.78 * k, 0.34 * k), (0.5 * k, 0.34 * k)], fill=light)
        d.polygon([(0.5 * k, 0.12 * k), (0.22 * k, 0.34 * k), (0.5 * k, 0.34 * k)], fill=(120, 205, 255, 255))
        d.polygon([(0.22 * k, 0.34 * k), (0.78 * k, 0.34 * k), (0.5 * k, 0.86 * k)], fill=(70, 170, 245, 255))
        d.polygon([(0.5 * k, 0.34 * k), (0.78 * k, 0.34 * k), (0.5 * k, 0.86 * k)], fill=dark)
        return canvas
    return icon_from_polys(S, [pts], (150, 225, 255), (40, 130, 230), 0.88, extras=extras)


def star_pts(n=5, outer=0.48, inner=0.2, cx=0.5, cy=0.52):
    pts = []
    for i in range(n * 2):
        ang = -math.pi / 2 + i * math.pi / n
        r = outer if i % 2 == 0 else inner
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


def icon_star(S):
    return icon_from_polys(S, [star_pts()], (255, 240, 120), (250, 170, 20), 0.82)


def heart_pts():
    pts = []
    for i in range(80):
        t = math.pi * 2 * i / 80
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((0.5 + x / 38, 0.46 - y / 38))
    return pts


def icon_heart(S):
    return icon_from_polys(S, [heart_pts()], (255, 130, 140), (210, 30, 60), 0.86)


def icon_bolt(S):
    pts = [(0.58, 0.04), (0.2, 0.55), (0.46, 0.55), (0.36, 0.96), (0.8, 0.4), (0.54, 0.4), (0.66, 0.04)]
    return icon_from_polys(S, [pts], (255, 245, 130), (255, 170, 20), 0.84)


def icon_plus(S):
    a, b, c = 0.12, 0.38, 0.62
    pts = [(b, a), (c, a), (c, b), (1 - a, b), (1 - a, c), (c, c), (c, 1 - a), (b, 1 - a), (b, c), (a, c), (a, b), (b, b)]
    return icon_from_polys(S, [pts], (150, 245, 110), (50, 170, 40), 0.82)


def icon_check(S):
    pts = [(0.1, 0.55), (0.24, 0.41), (0.42, 0.6), (0.78, 0.18), (0.92, 0.32), (0.42, 0.88)]
    return icon_from_polys(S, [pts], (150, 245, 110), (50, 170, 40), 0.84)


def icon_crown(S):
    pts = [(0.08, 0.78), (0.1, 0.3), (0.3, 0.52), (0.5, 0.16), (0.7, 0.52), (0.9, 0.3), (0.92, 0.78)]
    return icon_from_polys(S, [pts], (255, 235, 110), (240, 150, 20), 0.86)


def icon_lock(S):
    def extras(canvas, S):
        d = ImageDraw.Draw(canvas)
        k = S * SS
        d.arc([0.28 * k, 0.06 * k, 0.72 * k, 0.56 * k], 180, 360, fill=OUTLINE + (255,), width=int(0.1 * k))
        d.arc([0.32 * k, 0.1 * k, 0.68 * k, 0.54 * k], 180, 360, fill=(200, 205, 220, 255), width=int(0.05 * k))
        d.ellipse([0.44 * k, 0.5 * k, 0.56 * k, 0.62 * k], fill=OUTLINE + (255,))
        d.rectangle([0.485 * k, 0.58 * k, 0.515 * k, 0.74 * k], fill=OUTLINE + (255,))
        return canvas
    rect = [(0.2, 0.42), (0.8, 0.42), (0.8, 0.94), (0.2, 0.94)]
    return icon_from_polys(S, [rect], (255, 225, 110), (235, 150, 20), 0.9, extras=extras)


def icon_arrow_up(S):
    pts = [(0.5, 0.06), (0.92, 0.5), (0.66, 0.5), (0.66, 0.94), (0.34, 0.94), (0.34, 0.5), (0.08, 0.5)]
    return icon_from_polys(S, [pts], (150, 245, 110), (50, 170, 40), 0.84)




def arc_arrow(canvas, S, a0, a1, r, w, fill, ow):
    d = ImageDraw.Draw(canvas)
    k = S * SS
    c = k / 2
    for width, col, grow in ((w + ow * 2, OUTLINE, ow), (w, fill, 0)):
        d.arc([c - r, c - r, c + r, c + r], a0, a1, fill=col + (255,), width=int(width))
        ang = math.radians(a1)
        px, py = c + r * math.cos(ang), c + r * math.sin(ang)
        tx, ty = -math.sin(ang), math.cos(ang)
        nx, ny = math.cos(ang), math.sin(ang)
        hl, hw = w * 1.5 + grow, w * 1.15 + grow
        d.polygon([(px + tx * hl, py + ty * hl), (px + nx * hw, py + ny * hw), (px - nx * hw, py - ny * hw)], fill=col + (255,))


def icon_rebirth(S):
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    k = S * SS
    arc_arrow(canvas, S, 205, 335, k * 0.30, k * 0.13, (70, 175, 255), k * 0.035)
    arc_arrow(canvas, S, 25, 155, k * 0.30, k * 0.13, (60, 150, 245), k * 0.035)
    d = ImageDraw.Draw(canvas)
    for a0, a1, col in ((212, 328, (170, 225, 255)), (32, 148, (150, 205, 255))):
        d.arc([k / 2 - k * 0.30, k / 2 - k * 0.30 - k * 0.025, k / 2 + k * 0.30, k / 2 + k * 0.30 - k * 0.025], a0, a1, fill=col + (255,), width=int(k * 0.035))
    return down(canvas, S, S)


def icon_trade(S):
    def arrow(flip, top, bottom, dy):
        pts = [(0.08, 0.2), (0.54, 0.2), (0.54, 0.08), (0.92, 0.3), (0.54, 0.52), (0.54, 0.4), (0.08, 0.4)]
        pts = [((1 - x) if flip else x, y + dy) for x, y in pts]
        return icon_from_polys(S, [pts], top, bottom, 0.9)
    a = arrow(False, (255, 200, 110), (240, 120, 20), 0.08)
    b = arrow(True, (150, 215, 255), (40, 130, 235), 0.42)
    a.alpha_composite(b)
    return a


# ---------------------------------------------------------------------------------------------
# build everything
# ---------------------------------------------------------------------------------------------
manifest = {}


def save(name, img, slice_=None, cap=None):
    path = os.path.join(OUT, name + ".png")
    img.save(path, optimize=True)
    entry = {"file": name + ".png", "w": img.width, "h": img.height}
    if slice_:
        entry["slice"] = list(slice_)
    if cap:
        entry["cap"] = cap  # max SliceScale so big panels keep modest corners
    manifest[name] = entry
    return img


def main():
    # buttons (9-slice). 384x160, corner radius 44, outline 8 -> corner region about 56
    for cname in ("green", "blue", "red", "yellow", "orange", "purple", "pink", "gray", "dark"):
        save("btn_" + cname, glossy(384, 160, 44, COLORS[cname]), (56, 56, 56, 56))
        save("pill_btn_" + cname, glossy(384, 128, 64, COLORS[cname], o=8, lip=12), (66, 64, 66, 64))
    # panels and headers
    save("panel_dark", panel(512, 512, 56, (52, 52, 70), (30, 30, 44)), (72, 72, 72, 72), cap=0.36)
    save("panel_light", panel(512, 512, 56, (74, 74, 98), (46, 46, 66)), (72, 72, 72, 72), cap=0.36)
    for cname in ("green", "blue", "orange", "purple", "red", "pink", "yellow", "night"):
        save("header_" + cname, glossy(512, 168, 52, COLORS[cname], corners=(True, True, False, False), lip=0, lip_on=False, gloss=0.5), (64, 64, 64, 8), cap=0.4)
    # pills and bars
    save("pill_dark", pill_dark(320, 112), (56, 50, 56, 50))
    save("bar_track", bar_track(384, 96), (46, 44, 46, 44))
    for cname in ("green", "blue", "orange", "red", "purple", "yellow", "pink"):
        save("bar_fill_" + cname, bar_fill(384, 96, COLORS[cname]), (46, 44, 46, 44))
    # misc chrome
    save("close_x", close_button(176))
    save("badge_red", badge(128))
    save("slot_dark", slot(256), (48, 48, 48, 48), cap=0.4)
    for cname in ("blue", "orange", "purple", "green", "pink", "yellow", "red"):
        save("card_" + cname, card_frame(384, 512, COLORS[cname]), (80, 80, 80, 80), cap=0.4)
    save("glow_soft", glow_soft(256))
    save("sunburst", sunburst(512))
    # icons
    for name, fn in (("icon_coin", icon_coin), ("icon_gem", icon_gem), ("icon_star", icon_star), ("icon_heart", icon_heart),
                     ("icon_bolt", icon_bolt), ("icon_plus", icon_plus), ("icon_check", icon_check), ("icon_crown", icon_crown),
                     ("icon_lock", icon_lock), ("icon_arrow_up", icon_arrow_up), ("icon_rebirth", icon_rebirth), ("icon_trade", icon_trade)):
        save(name, fn(256))
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    make_sheet()
    print("wrote", len(manifest), "sprites to", OUT)


def make_sheet():
    names = list(manifest)
    cell = 190
    cols = 9
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (88, 120, 170, 255))
    for i, n in enumerate(names):
        im = Image.open(os.path.join(OUT, manifest[n]["file"])).convert("RGBA")
        sc = min((cell - 16) / im.width, (cell - 30) / im.height, 1.0)
        im = im.resize((max(1, int(im.width * sc)), max(1, int(im.height * sc))), Image.LANCZOS)
        x = (i % cols) * cell + (cell - im.width) // 2
        y = (i // cols) * cell + 4
        sheet.alpha_composite(im, (x, y))
        ImageDraw.Draw(sheet).text(((i % cols) * cell + 4, (i // cols) * cell + cell - 18), n, fill=(255, 255, 255, 255))
    sheet.convert("RGB").save(os.path.join(OUT, "_sheet.png"))


if __name__ == "__main__":
    main()
