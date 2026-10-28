"""Abstract shape sprites for the HUD (2026-10-28, user: "research abstract works and make it abstract").
After Hilma af Klint's temple paintings (overlapping circles / vesica piscis, spirals, orbits) and Kandinsky's point-line-plane.
White on transparent so Roblox tints them with ImageColor3. Drawn at 4x and downsampled for clean edges.

    python "UI Kit/art/abstract_shapes.py"      -> UI Kit/art/out/abs_*.png (512 px)
"""
import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
N = 512
K = 4  # supersampling
S = N * K


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def save(img, name):
    img.resize((N, N), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    print("wrote", name)


def ring(d, cx, cy, r, w, a=255):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, a), width=w)


def vesica():
    """two overlapping circle outlines; the almond where they meet is filled (af Klint: 'development toward unity')"""
    r = S * 0.3
    off = r * 0.55
    cy = S / 2
    a = Image.new("L", (S, S), 0)
    b = Image.new("L", (S, S), 0)
    ImageDraw.Draw(a).ellipse([S / 2 - off - r, cy - r, S / 2 - off + r, cy + r], fill=255)
    ImageDraw.Draw(b).ellipse([S / 2 + off - r, cy - r, S / 2 + off + r, cy + r], fill=255)
    both = Image.composite(a, Image.new("L", (S, S), 0), b)  # the almond: inside both circles
    img = canvas()
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 235)), mask=both)
    d = ImageDraw.Draw(img)
    ring(d, S / 2 - off, cy, r, 10 * K, 210)
    ring(d, S / 2 + off, cy, r, 10 * K, 210)
    save(img, "abs_vesica")


def spiral():
    """an outward spiral, thick at the heart and tapering (af Klint: evolution)"""
    img = canvas()
    d = ImageDraw.Draw(img)
    turns = 3.2
    steps = 1400
    pts = []
    for i in range(steps):
        t = i / steps
        ang = t * turns * math.tau
        rad = S * 0.03 + S * 0.43 * t ** 1.15
        pts.append((S / 2 + rad * math.cos(ang), S / 2 + rad * math.sin(ang), t))
    for i in range(1, len(pts)):
        x0, y0, _ = pts[i - 1]
        x1, y1, t = pts[i]
        w = int((14 - 9 * t) * K)
        d.line([x0, y0, x1, y1], fill=(255, 255, 255, 255), width=w)
        d.ellipse([x1 - w / 2, y1 - w / 2, x1 + w / 2, y1 + w / 2], fill=(255, 255, 255, 255))
    save(img, "abs_spiral")


def orbits():
    """concentric orbits with a 'planet' point on each (Kandinsky: the point at rest and in tension)"""
    img = canvas()
    d = ImageDraw.Draw(img)
    for i, (rf, ang, pr) in enumerate([(0.18, 0.6, 0.026), (0.31, 2.4, 0.034), (0.45, 4.3, 0.022)]):
        r = S * rf
        ring(d, S / 2, S / 2, r, (5 - i) * K, 200)
        px, py = S / 2 + r * math.cos(ang), S / 2 + r * math.sin(ang)
        p = S * pr
        d.ellipse([px - p, py - p, px + p, py + p], fill=(255, 255, 255, 255))
    p = S * 0.04
    d.ellipse([S / 2 - p, S / 2 - p, S / 2 + p, S / 2 + p], fill=(255, 255, 255, 255))
    save(img, "abs_orbits")


def eye():
    """an almond eye with a round pupil: the seer's eye, for ODDS"""
    img = canvas()
    d = ImageDraw.Draw(img)
    w, h = S * 0.44, S * 0.24
    top, bot = [], []
    for i in range(201):
        x = -w + 2 * w * i / 200
        y = h * (1 - (x / w) ** 2)
        top.append((S / 2 + x, S / 2 - y))
        bot.append((S / 2 + x, S / 2 + y))
    d.line(top + bot[::-1] + [top[0]], fill=(255, 255, 255, 255), width=12 * K, joint="curve")
    ring(d, S / 2, S / 2, S * 0.13, 10 * K)
    p = S * 0.06
    d.ellipse([S / 2 - p, S / 2 - p, S / 2 + p, S / 2 + p], fill=(255, 255, 255, 255))
    save(img, "abs_eye")


def sunrays():
    """thin radial lines of uneven length (a quiet halo behind the main action)"""
    img = canvas()
    d = ImageDraw.Draw(img)
    for i in range(36):
        a = i / 36 * math.tau
        r0 = S * 0.22
        r1 = S * (0.36 + 0.12 * ((i * 7) % 5) / 4)
        d.line([S / 2 + r0 * math.cos(a), S / 2 + r0 * math.sin(a), S / 2 + r1 * math.cos(a), S / 2 + r1 * math.sin(a)], fill=(255, 255, 255, 200), width=(4 if i % 3 else 7) * K)
    save(img, "abs_rays")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    vesica()
    spiral()
    orbits()
    eye()
    sunrays()
