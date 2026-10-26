"""Makes the white-on-transparent VFX textures for RevealFX and copies them into Studio's local content folder.

    python VFX/make_vfx.py            make + install (dev preview only: rbxasset://textures/vfx/<name>.png)
    python VFX/make_vfx.py --remove   delete the installed folder

Textures are white so Decal.Color3 / ParticleEmitter.Color tints them per rarity. Nothing is uploaded; a published game
needs these uploaded and referenced by asset id (RevealFX.textures).
"""
import glob
import math
import os
import shutil
import sys
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))


def glow(n=256):
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    px = im.load()
    c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c) / c
            a = max(0.0, 1 - d)
            px[x, y] = (255, 255, 255, int(255 * a ** 2.2))
    return im


def ring(n=512):
    S = 2
    m = Image.new("L", (n * S, n * S), 0)
    d = ImageDraw.Draw(m)
    c = n * S / 2

    def circ(r0, r1, a):
        d.ellipse((c - r1 * c, c - r1 * c, c + r1 * c, c + r1 * c), fill=a)
        d.ellipse((c - r0 * c, c - r0 * c, c + r0 * c, c + r0 * c), fill=0)
    circ(0.60, 0.97, 40)   # soft body
    circ(0.88, 0.96, 255)  # bright rim
    circ(0.70, 0.73, 150)  # inner thin ring
    m = m.resize((n, n), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def rune(n=512):
    S = 2
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2
    R = lambda f: f * c

    def circ(f, w, a=255):
        d.ellipse((c - R(f), c - R(f), c + R(f), c + R(f)), outline=a, width=int(w * S))
    circ(0.96, 4)
    circ(0.90, 2)
    circ(0.62, 3)
    circ(0.32, 3, 200)
    for i in range(48):  # tick marks between the outer rings
        a = i * math.tau / 48
        r0, r1 = (0.90, 0.95) if i % 4 else (0.84, 0.95)
        d.line((c + R(r0) * math.cos(a), c + R(r0) * math.sin(a), c + R(r1) * math.cos(a), c + R(r1) * math.sin(a)), fill=255, width=2 * S)
    pts = [(c + R(0.62) * math.cos(i * math.tau / 6 - math.pi / 2), c + R(0.62) * math.sin(i * math.tau / 6 - math.pi / 2)) for i in range(6)]
    for tri in ((0, 2, 4), (1, 3, 5)):  # hexagram
        d.line([pts[i] for i in tri] + [pts[tri[0]]], fill=255, width=3 * S)
    for p in pts:  # nodes
        d.ellipse((p[0] - 9 * S, p[1] - 9 * S, p[0] + 9 * S, p[1] + 9 * S), outline=255, width=3 * S)
    for i in range(12):  # glyph-like triangles between the rings
        a = (i + 0.5) * math.tau / 12
        pa = [(c + R(r) * math.cos(a + da), c + R(r) * math.sin(a + da)) for r, da in ((0.80, 0), (0.72, -0.05), (0.72, 0.05))]
        d.polygon(pa, fill=210)
    m = m.resize((n, n), Image.LANCZOS)
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def streak(w=256, h=64):
    """beam texture: constant along the length (x), soft fade across the width (y)"""
    im = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    px = im.load()
    for y in range(h):
        t = abs((y + 0.5) / h * 2 - 1)
        a = (1 - t) ** 1.6
        core = max(0.0, 1 - t / 0.25) ** 2
        v = min(1.0, a * 0.8 + core)
        for x in range(w):
            px[x, y] = (255, 255, 255, int(255 * v))
    return im


def flare(n=256):
    """four-point star with a soft core, for sparkle particles"""
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    px = im.load()
    c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            dx, dy = abs(x - c) / c, abs(y - c) / c
            arm = max(0.0, 1 - max(dx, dy) * 1.0) * (math.exp(-min(dx, dy) * 22))
            core = max(0.0, 1 - math.hypot(dx, dy) / 0.35) ** 2
            v = min(1.0, arm * 1.2 + core)
            px[x, y] = (255, 255, 255, int(255 * v))
    return im


def sigil(n=768):
    """gothic rose window: ring, 12 pointed lancet petals, inner rosette, centre circle with a sword"""
    S = 2
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2
    R = lambda f: f * c

    def circ(f, w, a=255):
        d.ellipse((c - R(f), c - R(f), c + R(f), c + R(f)), outline=a, width=int(w * S))
    for f, w in ((0.97, 5), (0.92, 2), (0.54, 3), (0.30, 3), (0.12, 3)):
        circ(f, w)
    for i in range(72):
        a = i * math.tau / 72
        r0, r1 = (0.92, 0.97) if i % 6 else (0.88, 0.97)
        d.line((c + R(r0) * math.cos(a), c + R(r0) * math.sin(a), c + R(r1) * math.cos(a), c + R(r1) * math.sin(a)), fill=255, width=2 * S)

    def lens(a, r0, r1, half, width):  # pointed arch between radius r0 and r1 at angle a
        pts = []
        for k in range(0, 21):
            t = k / 20
            r = r0 + (r1 - r0) * t
            off = half * math.sin(math.pi * t) ** 0.8
            pts.append((r, off))
        left = [(c + R(r) * math.cos(a) - R(o) * math.sin(a), c + R(r) * math.sin(a) + R(o) * math.cos(a)) for r, o in pts]
        right = [(c + R(r) * math.cos(a) + R(o) * math.sin(a), c + R(r) * math.sin(a) - R(o) * math.cos(a)) for r, o in pts]
        d.line(left, fill=255, width=width * S)
        d.line(right, fill=255, width=width * S)
    for i in range(12):
        a = i * math.tau / 12
        lens(a, 0.55, 0.9, 0.11, 3)
        lens(a + math.tau / 24, 0.31, 0.53, 0.05, 2)
    for i in range(6):
        a = i * math.tau / 6
        lens(a, 0.12, 0.30, 0.07, 2)
    # sword in the centre
    d.line((c, c - R(0.10), c, c + R(0.10)), fill=255, width=3 * S)
    d.line((c - R(0.05), c - R(0.02), c + R(0.05), c - R(0.02)), fill=255, width=3 * S)
    m = m.resize((n, n), Image.LANCZOS)
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def crack(n=768):
    """jagged cracks radiating from the centre, with branches; fades towards the rim"""
    import random
    rnd = random.Random(7)
    S = 2
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2

    def branch(x, y, ang, length, w, depth):
        steps = max(4, int(length / (14 * S)))
        px, py = x, y
        for k in range(steps):
            ang += rnd.uniform(-0.35, 0.35)
            step = length / steps
            nx, ny = px + math.cos(ang) * step, py + math.sin(ang) * step
            fade = 1 - math.hypot(nx - c, ny - c) / (c * 0.96)
            if fade <= 0:
                return
            d.line((px, py, nx, ny), fill=int(255 * min(1, fade * 1.6)), width=max(1, int(w * S * (1 - k / steps * 0.6))))
            if depth < 2 and rnd.random() < 0.28:
                branch(nx, ny, ang + rnd.choice((-1, 1)) * rnd.uniform(0.5, 0.9), length * 0.45, w * 0.6, depth + 1)
            px, py = nx, ny
    for i in range(14):
        branch(c, c, i * math.tau / 14 + rnd.uniform(-0.2, 0.2), c * rnd.uniform(0.9, 1.3), 6, 0)
    m = m.resize((n, n), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.8))
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def sword(w=256, h=768):
    """smooth painted sword, tip DOWN: bevelled steel blade with a fuller, curved gold crossguard, leather grip, gem pommel, soft glow"""
    S = 3
    W, H = w * S, h * S
    cx = W / 2
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def y(f):
        return f * H

    def lerp(a, b, t):
        return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    bw = W * 0.11
    top, tip = y(0.40), y(0.965)
    # blade: left half bright, right half darker (bevel), vertical gradient, pointed tip at the bottom
    for yy in range(int(top), int(tip)):
        t = (yy - top) / (tip - top)
        half = bw * (1 - max(0.0, (t - 0.82) / 0.18) ** 1.4)
        c0 = lerp((235, 244, 255), (150, 175, 215), t * 0.8)
        d.rectangle((cx - half, yy, cx, yy + 1), fill=c0 + (255,))
        d.rectangle((cx, yy, cx + half, yy + 1), fill=lerp(c0, (95, 120, 175), 0.55) + (255,))
    d.line((cx, top, cx, tip - 4 * S), fill=(255, 255, 255, 255), width=int(2.4 * S))  # centre ridge
    fu = bw * 0.28
    d.rectangle((cx - fu, top + y(0.02), cx + fu, y(0.86)), fill=(120, 150, 205, 150))  # fuller
    # crossguard: curved gold bar with up-swept ends
    gy = y(0.385)
    pts = []
    for k in range(-30, 31):
        x = cx + k / 30 * W * 0.40
        pts.append((x, gy - (abs(k) / 30) ** 2.2 * y(0.05)))
    top_edge = pts
    bot_edge = [(x, yy + y(0.026)) for x, yy in pts]
    d.polygon(top_edge + bot_edge[::-1], fill=(255, 205, 80, 255))
    d.line(top_edge, fill=(255, 245, 190, 255), width=int(2 * S))
    d.line(bot_edge, fill=(170, 110, 20, 255), width=int(2 * S))
    for sx in (-1, 1):  # finials
        fx, fy = cx + sx * W * 0.40, gy - y(0.05)
        d.ellipse((fx - 7 * S, fy - 7 * S, fx + 7 * S, fy + 7 * S), fill=(255, 225, 120, 255))
    # grip with gold wraps, pommel with a blue gem
    d.rounded_rectangle((cx - W * 0.035, y(0.27), cx + W * 0.035, y(0.385)), radius=6 * S, fill=(96, 56, 36, 255))
    for k in range(6):
        yy = y(0.28) + k * y(0.017)
        d.line((cx - W * 0.036, yy, cx + W * 0.036, yy + 5 * S), fill=(235, 180, 60, 255), width=int(2.2 * S))
    pr = W * 0.075
    py = y(0.235)
    d.ellipse((cx - pr, py - pr, cx + pr, py + pr), fill=(255, 205, 80, 255), outline=(170, 110, 20, 255), width=int(2 * S))
    gr = pr * 0.55
    d.ellipse((cx - gr, py - gr, cx + gr, py + gr), fill=(90, 170, 255, 255))
    d.ellipse((cx - gr * 0.5, py - gr * 0.7, cx - gr * 0.05, py - gr * 0.2), fill=(220, 240, 255, 255))
    # soft outer glow
    a = im.split()[3]
    g = a.filter(ImageFilter.GaussianBlur(10 * S)).point(lambda v: int(v * 0.55))
    glow = Image.new("RGBA", (W, H), (180, 205, 255, 0))
    glow.putalpha(g)
    out = Image.alpha_composite(glow, im)
    return out.resize((w, h), Image.LANCZOS)


def emblem(n=512):
    """original Guardian Grid mark: thin double ring, 16 ticks, a 3x3 grid square with a centre diamond"""
    S = 3
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2
    R = lambda f: f * c

    def circ(f, w):
        d.ellipse((c - R(f), c - R(f), c + R(f), c + R(f)), outline=255, width=int(w * S))
    circ(0.96, 3)
    circ(0.84, 1.5)
    for i in range(16):
        a = i * math.tau / 16
        r0, r1 = (0.84, 0.96) if i % 4 == 0 else (0.87, 0.93)
        d.line((c + R(r0) * math.cos(a), c + R(r0) * math.sin(a), c + R(r1) * math.cos(a), c + R(r1) * math.sin(a)), fill=255, width=2 * S)
    q = R(0.40)
    d.rectangle((c - q, c - q, c + q, c + q), outline=255, width=3 * S)
    for k in (-1 / 3, 1 / 3):  # 3x3 grid
        d.line((c + q * k, c - q, c + q * k, c + q), fill=255, width=2 * S)
        d.line((c - q, c + q * k, c + q, c + q * k), fill=255, width=2 * S)
    r = R(0.12)
    d.polygon([(c, c - r), (c + r, c), (c, c + r), (c - r, c)], fill=255)
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):  # corner nodes
        x, y = c + sx * q, c + sy * q
        d.ellipse((x - 6 * S, y - 6 * S, x + 6 * S, y + 6 * S), fill=255)
    m = m.resize((n, n), Image.LANCZOS)
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def ink(n=768):
    """organic ink splat: metaball-style blob with arms, drips and flung droplets (smooth edges)"""
    import random
    rnd = random.Random(11)
    S = 2
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2
    d.ellipse((c - N * 0.17, c - N * 0.17, c + N * 0.17, c + N * 0.17), fill=255)
    for i in range(13):
        a = i * math.tau / 13 + rnd.uniform(-0.2, 0.2)
        ln = N * rnd.uniform(0.22, 0.40)
        w = N * rnd.uniform(0.018, 0.04)
        x2, y2 = c + math.cos(a) * ln, c + math.sin(a) * ln
        d.line((c, c, x2, y2), fill=255, width=int(w * 2))
        r = w * rnd.uniform(1.3, 2.2)
        d.ellipse((x2 - r, y2 - r, x2 + r, y2 + r), fill=255)
    for i in range(90):
        a = rnd.uniform(0, math.tau)
        dist = N * rnd.uniform(0.2, 0.47) ** 1.0
        r = N * rnd.uniform(0.003, 0.014) * (1.2 - dist / (N * 0.5))
        x, y = c + math.cos(a) * dist, c + math.sin(a) * dist
        d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(9 * S)).point(lambda v: 255 if v > 90 else int(v * 255 / 90))
    m = m.filter(ImageFilter.GaussianBlur(1.2 * S)).resize((n, n), Image.LANCZOS)
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


def swirl(n=768):
    """spiral vortex: five tapering arms that fade outward"""
    S = 2
    N = n * S
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    c = N / 2
    for arm in range(5):
        a0 = arm * math.tau / 5
        prev = None
        for k in range(0, 241):
            t = k / 240
            r = (0.04 + 0.92 * t) * c
            a = a0 + t * 3.4
            x, y = c + r * math.cos(a), c + r * math.sin(a)
            if prev:
                v = int(255 * (1 - t) ** 0.7 * min(1, t * 9))
                d.line((prev[0], prev[1], x, y), fill=v, width=max(2, int((16 - 12 * t) * S)))
            prev = (x, y)
    m = m.filter(ImageFilter.GaussianBlur(2.2 * S)).resize((n, n), Image.LANCZOS)
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(m)
    return im


if __name__ == "__main__":
    versions = os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "Versions")
    targets = [os.path.join(os.path.dirname(e), "content", "textures", "vfx") for e in glob.glob(os.path.join(versions, "version-*", "RobloxStudioBeta.exe"))]
    if "--remove" in sys.argv:
        for t in targets:
            shutil.rmtree(t, ignore_errors=True)
            print("removed", t)
        sys.exit()
    save(glow(), "vfx_glow")
    save(ring(), "vfx_ring")
    save(rune(), "vfx_rune")
    save(streak(), "vfx_streak")
    save(flare(), "vfx_flare")
    save(sigil(), "vfx_sigil")
    save(crack(), "vfx_crack")
    save(sword(), "vfx_sword")
    save(emblem(), "vfx_emblem")
    save(ink(), "vfx_ink")
    save(swirl(), "vfx_swirl")
    for t in targets:
        os.makedirs(t, exist_ok=True)
        for f in glob.glob(os.path.join(OUT, "*.png")):
            shutil.copy2(f, t)
        print("installed", len(os.listdir(t)), "textures to", t)
