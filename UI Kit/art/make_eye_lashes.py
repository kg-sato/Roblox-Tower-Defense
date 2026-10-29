"""Etched eyelashes and crease lines for the loading screen's great eye (2026-10-29; the user: "the eyelashes are why
the original model was so defined and detailed"). The etched eye they liked has a fringe of long curling lashes along
the upper lid, shorter ones below, and thin engraved arcs (the lid crease) above and below. This draws the same around
the brass eye's rim, in the etched gold-ink palette (each stroke: a dark engraved outline, then a cream-gold stroke
that tapers to a point).
Rim edge: measured per column from r9/brass_eye.png alpha (outer edge of the brass frame).
Output: upload_1028/r10/eye_lashes.png, 1024 x 1024; the eye's 1024 x 640 canvas sits at y offset 192, so in Studio
the layer is Size (1, 1.6), Position (0, -0.3) inside the great eye's frame.
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_eye_lashes.py" """
import math
import os
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "upload_1028")
OUT = os.path.join(UP, "r10")
os.makedirs(OUT, exist_ok=True)
S, W, H, OY = 3, 1024, 1024, 192  # supersample, canvas, eye canvas offset
DARK, BASE, TIP = (22, 17, 10, 255), (150, 120, 70, 255), (236, 214, 166, 255)

alpha = np.array(Image.open(os.path.join(UP, "r9", "brass_eye.png")))[..., 3]
cols = [x for x in range(W) if (alpha[:, x] > 128).any()]
X0, X1 = cols[0], cols[-1]
top = np.full(W, np.nan)
bot = np.full(W, np.nan)
for x in cols:
    r = np.where(alpha[:, x] > 128)[0]
    top[x], bot[x] = r.min(), r.max()
k = np.ones(15) / 15  # smooth the measured edge
valid = np.arange(X0 + 7, X1 - 7)
top_s = np.convolve(np.nan_to_num(top), k, "same")
bot_s = np.convolve(np.nan_to_num(bot), k, "same")


def edge(x, upper):
    x = int(min(max(x, valid[0]), valid[-1]))
    return (top_s[x] if upper else bot_s[x]) + OY


def normal(x, upper):  # outward unit normal of the edge at x (screen coords, y down)
    dy = (edge(x + 3, upper) - edge(x - 3, upper)) / 6
    nx, ny = (dy, -1) if upper else (-dy, 1)
    l = math.hypot(nx, ny)
    return nx / l, ny / l


img = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)


def stroke(pts, w0, col, w1=0.6):
    """Tapered stroke along pts: a chain of quads whose width falls from w0 to w1 (px, before supersampling)."""
    n = len(pts)
    for i in range(n - 1):
        (xa, ya), (xb, yb) = pts[i], pts[i + 1]
        wa = (w0 + (w1 - w0) * i / (n - 1)) * S / 2
        wb = (w0 + (w1 - w0) * (i + 1) / (n - 1)) * S / 2
        dx, dy = xb - xa, yb - ya
        l = math.hypot(dx, dy) or 1
        px, py = -dy / l, dx / l
        d.polygon([(xa * S + px * wa, ya * S + py * wa), (xb * S + px * wb, yb * S + py * wb),
                   (xb * S - px * wb, yb * S - py * wb), (xa * S - px * wa, ya * S - py * wa)], fill=col)


def lash_path(x, upper, length, rnd):
    u = (x - (X0 + X1) / 2) / ((X1 - X0) / 2)  # -1 .. 1 across the eye
    nx, ny = normal(x, upper)
    ang = math.atan2(ny, nx) + u * 0.55 * (1 if upper else -1) + rnd.uniform(-0.12, 0.12)  # fan outward at the ends
    curl = (0.8 if upper else 0.45) * u * (1 if upper else -1)  # smooth: none in the middle, so the fringe never parts
    x0, y0 = x, edge(x, upper) - ny * 4  # start just under the rim's edge so the root hides
    pts = []
    for j in range(9):
        s = j / 8
        a = ang + curl * s * s  # curl toward the outer corner, more at the tip
        pts.append((x0 + math.cos(a) * length * s, y0 + math.sin(a) * length * s))
    return pts, u


# 2026-10-29 fix (the user: "the screenshots eyelashes are pure black"): measured on the reference, the lash band is
# 62-78 % dark strokes and only 6-16 % light gaps, so the lashes are BLACK strokes over a cream lid; the cream is skin
# showing between them. So: a cream lid band hugging the rim, then dense black lashes across it.
INK_BLACK = (8, 6, 4, 255)
rnd = random.Random(7)


def band(upper, width):  # cream lid crescent from the rim outward, thinning to nothing at the corners
    inner, outer = [], []
    for x in range(X0 + 20, X1 - 19, 3):
        nx, ny = normal(x, upper)
        u = (x - (X0 + X1) / 2) / ((X1 - X0) / 2)
        w = width * max(0.0, 1 - u * u) ** 0.6
        e = edge(x, upper) - ny * 6
        inner.append((x * S, e * S))
        outer.append(((x + nx * w) * S, (e + ny * w) * S))
    d.polygon(inner + outer[::-1], fill=TIP)
    return [(x / S, y / S) for x, y in outer]


for upper, width, n, wmax in ((True, 78, 190, 9.5), (False, 30, 110, 5.5)):
    rim = band(upper, width)
    stroke(rim, 3.5, INK_BLACK, 3.5)  # the lid's outer line, engraved
    for i in range(n):
        t = (i + rnd.uniform(0.2, 0.8)) / n
        x = X0 + 30 + t * (X1 - X0 - 60)
        u = (x - (X0 + X1) / 2) / ((X1 - X0) / 2)
        L = (width * max(0.0, 1 - u * u) ** 0.6 + 8) * rnd.uniform(0.95, 1.2)  # reach just past the band's edge
        pts, _ = lash_path(x, upper, L, rnd)
        stroke(pts, wmax * rnd.uniform(0.8, 1.15), INK_BLACK, 0.8)

# a thin crease line above the lid, as in the etched eye
pts = []
for x in range(X0 + 60, X1 - 59, 4):
    nx, ny = normal(x, True)
    u = (x - (X0 + X1) / 2) / ((X1 - X0) / 2)
    o = 78 * max(0.0, 1 - u * u) ** 0.6 + 34
    pts.append((x + nx * o, edge(x, True) + ny * o))
stroke(pts, 2.6, TIP, 2.6)

out = img.resize((W, H), Image.LANCZOS)
a = np.array(out)
assert a[..., 3].max() == 255 and (a[..., 3] > 0).sum() > 20000, "lash layer looks empty"
# self-check against the reference: inside the upper lid band (opaque pixels just above the rim's middle), most
# pixels must be black lashes and some cream gaps must remain
cx = (X0 + X1) // 2
reg = a[int(edge(cx, True)) - 60:int(edge(cx, True)) - 15, cx - 150:cx + 150]
op = reg[..., 3] > 200
L = reg[..., :3].mean(-1)[op]
dark, light = (L < 60).mean(), (L > 150).mean()
print("lid band: dark %.2f light %.2f (reference 0.62-0.78 / 0.06-0.16)" % (dark, light))
assert 0.6 < dark < 0.85 and 0.04 < light < 0.25, "lash band does not match the reference's black-on-cream"
out.save(os.path.join(OUT, "eye_lashes.png"))

# preview over the recoloured eye
pv = Image.new("RGBA", (W, H), (18, 16, 20, 255))
pv.alpha_composite(out)
pv.alpha_composite(Image.open(os.path.join(UP, "r9", "brass_eye.png")), (0, OY))
pv.convert("RGB").crop((60, 60, 964, 900)).resize((678, 630)).save(os.path.join(OUT, "preview.jpg"))
print("wrote", OUT, "rim x", X0, X1)
