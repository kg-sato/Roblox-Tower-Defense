"""Layers for the loading screen's great brass eye (2026-10-28 night; review: "a human-eye engraving, not brass
clockwork", "the lids look like flat cards"). Input: menu_art/brasseye_s43_a.png (ComfyUI, make_menu_art.py brasseye)
and menu_art/brassplate_s44.png (texture). Output in upload_1028/r6/:
  brass_eye.png   the whole eye (eyeball, clock iris, brass rim), 1024 x 640
  brass_rim.png   the same with the eye opening cut out, drawn on top of the lids
  brass_lid_up.png / brass_lid_down.png   riveted brass shutters the size of the opening's box (744 x 460)
The opening (aperture) is an almond: centre (516, 325), half width 372, half heights 228 up / 232 down, profile
(1 - u^2)^0.8. Its box is x 144..888, y 97..557; LoadingScreen places the lids' clip box with those numbers.
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_brass_eye.py" """
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "upload_1028", "r6")
CX, CY, HW, HT, HB, P = 516, 325, 372, 228, 232, 0.8
BX0, BY0, BW, BH = CX - HW, CY - HT - 0, 2 * HW, HT + HB  # 144, 97, 744, 460

os.makedirs(OUT, exist_ok=True)
eye = Image.open(os.path.join(HERE, "menu_art", "brasseye_s43_a.png")).convert("RGBA")
eye.save(os.path.join(OUT, "brass_eye.png"))

# the opening as a soft mask
W, H = eye.size
yy, xx = np.mgrid[0:H, 0:W].astype(float)
u = (xx - CX) / HW
f = np.clip(1 - u * u, 0, 1) ** P
inside = (yy > CY - HT * f) & (yy < CY + HB * f)
mask = Image.fromarray((inside * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.5))
rim = np.array(eye).astype(float)
rim[..., 3] *= 1 - np.array(mask) / 255.0
# an occluder in the backdrop's dark fills the lids' box outside the opening, so a shutter never shows outside the
# rim; it fades out softly past the box so it reads as the eye's shadow
dx = np.maximum(np.maximum(BX0 - xx, xx - (BX0 + BW)), 0)
dy = np.maximum(np.maximum(BY0 - yy, yy - (BY0 + BH)), 0)
# polish (review: "a hard dark rectangular backing"): an elliptical soft shadow instead of a box
e = ((xx - CX) / (HW + 40)) ** 2 + ((yy - CY) / (HT + 80)) ** 2
occ_a = np.clip((1.25 - e) / 0.35, 0, 1) * (1 - np.array(mask) / 255.0)
occ = np.dstack([np.full((H, W), 14.0), np.full((H, W), 12.0), np.full((H, W), 16.0), occ_a * 255])
ra = rim[..., 3:4] / 255.0
out_rgb = rim[..., :3] * ra + occ[..., :3] * (1 - ra)
out_a = np.maximum(rim[..., 3], occ[..., 3])
Image.fromarray(np.dstack([out_rgb, out_a]).astype("uint8"), "RGBA").save(os.path.join(OUT, "brass_rim.png"))

# the lids: brass plate texture, a seam that curves gently down, a bevelled edge with rivets, shading away from the edge
tex = Image.open(os.path.join(HERE, "menu_art", "brassplate_s44.png")).convert("RGB").resize((BW, BW))


def lid(upper):
    t = tex.crop((0, 0, BW, BH)) if upper else tex.crop((0, BW - BH, BW, BW)).transpose(Image.FLIP_LEFT_RIGHT)
    a = np.array(t).astype(float)
    ly, lx = np.mgrid[0:BH, 0:BW].astype(float)
    lu = (lx - BW / 2) / (BW / 2)
    seam = BH / 2 + 18 * (1 - lu * lu)  # the closed seam
    dist = (seam - ly) if upper else (ly - seam)  # >0 on the lid
    alpha = np.clip(dist / 2 + 0.5, 0, 1)
    alpha *= np.clip((0.97 - np.abs(lu)) / 0.2, 0, 1)  # thin out at the tips, where the opening is narrow
    shade = 0.55 + 0.45 * np.clip(1 - dist / (BH * 0.5), 0, 1)  # brighter near the edge: light catches the bevel
    a *= shade[..., None]
    img = Image.fromarray(np.dstack([a, alpha * 255]).astype("uint8"), "RGBA")
    d = ImageDraw.Draw(img)
    pts = [(x, (BH / 2 + 18 * (1 - ((x - BW / 2) / (BW / 2)) ** 2))) for x in range(int(BW * 0.03), int(BW * 0.97), 4)]
    off = -1 if upper else 1
    d.line([(x, y - off * 3) for x, y in pts], fill=(255, 226, 150, 255), width=3)  # highlight on the edge
    d.line([(x, y - off * 9) for x, y in pts], fill=(70, 40, 15, 200), width=3)  # the bevel's shadow line
    for x in range(60, BW - 59, 56):  # a row of rivets
        y = BH / 2 + 18 * (1 - ((x - BW / 2) / (BW / 2)) ** 2) - off * 20
        d.ellipse((x - 6, y - 6, x + 6, y + 6), fill=(150, 100, 40, 255))
        d.ellipse((x - 4, y - 5, x + 2, y + 1), fill=(255, 220, 140, 255))
    return img


lid(True).save(os.path.join(OUT, "brass_lid_up.png"))
lid(False).save(os.path.join(OUT, "brass_lid_down.png"))

# light rays for the dive's bloom: gold streaks from a hot centre, fading outward
R = 512
rays = Image.new("RGBA", (R, R), (0, 0, 0, 0))
rd = ImageDraw.Draw(rays)
import math, random
random.seed(7)
for i in range(44):
    ang = i / 44 * 2 * math.pi + random.uniform(-0.04, 0.04)
    wid = random.uniform(0.012, 0.045)
    ln = random.uniform(0.55, 1.0) * R / 2
    pts = [(R / 2, R / 2), (R / 2 + math.cos(ang - wid) * ln, R / 2 + math.sin(ang - wid) * ln), (R / 2 + math.cos(ang + wid) * ln, R / 2 + math.sin(ang + wid) * ln)]
    rd.polygon(pts, fill=(255, 205, 120, random.randint(120, 230)))
ra = np.array(rays.filter(ImageFilter.GaussianBlur(2))).astype(float)
ry, rx = np.mgrid[0:R, 0:R].astype(float)
rr = np.hypot(rx - R / 2, ry - R / 2) / (R / 2)
ra[..., 3] *= np.clip(1 - rr, 0, 1) ** 1.4
Image.fromarray(ra.astype("uint8")).save(os.path.join(OUT, "bloom_rays.png"))

# preview: closed, half, open
prev = Image.new("RGB", (W, H * 3))
for i, k in enumerate((0, 0.5, 1)):
    fr = Image.new("RGBA", (W, H), (14, 12, 16, 255))
    fr.alpha_composite(eye)
    box = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    box.alpha_composite(lid(True), (0, int(-0.62 * BH * k)))
    box.alpha_composite(lid(False), (0, int(0.62 * BH * k)))
    fr.alpha_composite(box, (BX0, BY0))
    fr.alpha_composite(Image.open(os.path.join(OUT, "brass_rim.png")))
    prev.paste(fr.convert("RGB"), (0, H * i))
prev.resize((W // 2, H * 3 // 2)).save(os.path.join(OUT, "preview.jpg"))
print("wrote", OUT)
