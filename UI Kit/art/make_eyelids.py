"""Brass eyelids for the loading screen's great eye (2026-10-28, the user: "Yes, eyelids"; review: the eye opened as a
straight slit, not lids parting). Draws an upper and a lower lid: dark bronze skin with engraved hatching that follows
the curved edge, a brass rim on the edge and lashes, fading out away from the edge. Run with the Hunyuan3D venv:
   Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_eyelids.py"
Output: UI Kit/art/upload_1028/r5/eyelid_upper.png and eyelid_lower.png (1024 x 544, alpha).
Geometry (LoadingScreen uses the same numbers): the edge is y = H - 8 - D * (1 - u^2), u = -1..1 across the width,
D = 150 px for the upper lid and 107 px for the lower (which is drawn the same way, then flipped)."""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

W, H, S = 1024, 544, 2  # S: supersampling
OUT = os.path.join(os.path.dirname(__file__), "upload_1028", "r5")


def lid(D, lashes, seed):
    random.seed(seed)
    w, h = W * S, H * S
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    edge = lambda x: (H - 8 - D * (1 - (2 * x / w - 1) ** 2)) * S  # edge y at pixel column x
    # skin: dark bronze, opaque above the edge, fading out over the top 18%
    skin = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = skin.load()
    for x in range(w):
        ey = int(edge(x))
        for y in range(min(ey, h)):
            a = min(1.0, y / (h * 0.18))
            # round falloff away from the edge's middle, so the lid never shows as a rectangle (review r1)
            e = ((x / w - 0.5) / 0.56) ** 2 + ((y - h) / (h * 1.05)) ** 2
            a *= min(1.0, max(0.0, (1.15 - e) / 0.35))
            shade = 1 - 0.35 * (ey - y) / h  # a little lighter near the edge
            px[x, y] = (int(22 * shade), int(17 * shade), int(13 * shade), int(255 * a))  # near the backdrop's dark
    img = Image.alpha_composite(img, skin)
    d = ImageDraw.Draw(img)
    # engraved hatching: curves parallel to the edge, brass, fainter further away
    for k in range(1, 14):
        off = k * 14 * S
        pts = [(x, edge(x) - off) for x in range(0, w + 1, 8 * S)]
        d.line(pts, fill=(200, 160, 95, max(0, 90 - k * 6)), width=S)
    # short cross-strokes near the edge (the engraving's texture)
    for _ in range(260):
        x = random.uniform(0.04, 0.96) * w
        y0 = edge(x) - random.uniform(10, 120) * S
        d.line([(x, y0), (x + 6 * S, y0 - 10 * S)], fill=(210, 170, 100, 50), width=S)
    # brass rim along the edge, and a thin highlight
    pts = [(x, edge(x)) for x in range(0, w + 1, 4 * S)]
    d.line(pts, fill=(196, 150, 80, 255), width=9 * S)
    d.line([(x, y - 4 * S) for x, y in pts], fill=(255, 225, 160, 200), width=2 * S)
    # lashes: curved strokes from the rim outward past the edge, longest in the middle
    n = lashes
    for i in range(n):
        t = (i + 0.5) / n
        x = t * w
        if not 0.06 < t < 0.94:
            continue
        y = edge(x)
        u = 2 * t - 1
        L = (14 + 26 * (1 - u * u)) * S * random.uniform(0.55, 1.25)
        ang = math.radians(90 + u * 55 + random.uniform(-14, 14))  # point down and out from the edge
        seg = []
        for j in range(6):
            s = j / 5
            a2 = ang - (u * 0.6 + 0.25 * (1 if u >= 0 else -1)) * s * s  # curl outward
            seg.append((x + math.cos(a2) * L * s, y + math.sin(a2) * L * s))
        d.line(seg, fill=(235, 215, 175, 230), width=2 * S)
    # the same round falloff for the hatching, so no line runs out into a corner
    import numpy as np
    arr = np.array(img).astype(float)
    yy, xx = np.mgrid[0:h, 0:w]
    e = ((xx / w - 0.5) / 0.56) ** 2 + ((yy - h) / (h * 1.05)) ** 2
    arr[..., 3] *= np.clip((1.15 - e) / 0.35, 0, 1)
    img = Image.fromarray(arr.astype("uint8"))
    return img.resize((W, H), Image.LANCZOS).filter(ImageFilter.SMOOTH)


os.makedirs(OUT, exist_ok=True)
lid(150, 70, 1).save(os.path.join(OUT, "eyelid_upper.png"))
lid(107, 40, 2).transpose(Image.FLIP_TOP_BOTTOM).save(os.path.join(OUT, "eyelid_lower.png"))
print("wrote", OUT)
