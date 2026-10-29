"""Eyelid flipbook for the loading screen's great brass eye (2026-10-28 night; the user: "the eyelid opening is really
unnatural"; review: "shutters spill outside the rim", "flat slabs"). Instead of two plates sliding apart, every frame
draws the lids the way an eye opens: closed, the lids meet along a low curved seam; as it opens, the upper lid's edge
lifts and bends to follow the top of the opening, and the lower lid drops a little. Each lid is a brass shell (rounded
shading, a bright bevel, rivets along the edge) and casts a soft shadow on the eyeball. Everything is masked to the
eye's opening, so nothing shows outside the rim.
Frames: 18 (k = 0 closed .. 1 open), each 512 x 316, six per sheet (2 columns x 3 rows, 1024 x 948), 3 sheets:
upload_1028/r7/lids_0.png .. lids_2.png. The opening's box in brass_eye.png is x 144..888, y 97..557 (744 x 460).
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_eye_lids_flip.py" """
import os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "upload_1028", "r7")
BW, BH = 744, 460
N, FW, FH = 18, 512, 316
os.makedirs(OUT, exist_ok=True)

tex = np.array(Image.open(os.path.join(HERE, "menu_art", "brassplate_s44.png")).convert("RGB").resize((BW, BW * 2 // 1))).astype(float)
ly, lx = np.mgrid[0:BH, 0:BW].astype(float)
u = (lx - BW / 2) / (BW / 2)
f = np.clip(1 - u * u, 0, 1) ** 0.8
top = 228 - 228 * f  # the opening's edges (box coordinates)
bot = 228 + 232 * f
inside = np.clip(np.minimum(ly - top, bot - ly) / 1.5 + 0.5, 0, 1)  # soft mask of the opening
seam = 228 + 0.42 * 232 * f  # closed: the lids meet low, along a curve that dips in the middle
shell = 0.78 + 0.22 * np.cos(u * np.pi / 2)  # a rounded shell: lighter in the middle


def frame(k):
    e = 1 - (1 - k)  # progress
    yU = seam + (top - seam) * e  # upper lid edge: from the seam up to the top of the opening
    yL = seam + (bot - seam) * e  # lower lid edge: from the seam down to the bottom
    out = np.zeros((BH, BW, 4))
    # cast shadows on the eyeball, just past each lid edge
    dU, dL = ly - yU, yL - ly
    sh = np.clip(1 - dU / 34, 0, 1) * (dU > 0) * 0.55 + np.clip(1 - dL / 16, 0, 1) * (dL > 0) * 0.35
    out[..., 3] = np.clip(sh, 0, 1) * 255
    for upper in (True, False):
        dist = (yU - ly) if upper else (ly - yL)  # > 0 on the lid
        a = np.clip(dist / 1.5 + 0.5, 0, 1)
        shift = int((yU[0, BW // 2] - seam[0, BW // 2])) if upper else int(yL[0, BW // 2] - seam[0, BW // 2])
        ty = np.clip((ly - shift).astype(int) + (0 if upper else BH), 0, tex.shape[0] - 1)  # texture rides with the lid
        rgb = tex[ty, lx.astype(int)]
        light = 0.5 + 0.5 * np.clip(1 - dist / 140, 0, 1)  # brighter towards the edge
        rgb = rgb * (light * shell)[..., None]
        bevel = np.clip(1 - np.abs(dist - 4) / 3, 0, 1)  # a bright bevel line just inside the edge
        rgb = rgb * (1 - bevel[..., None]) + np.array([255, 228, 160]) * bevel[..., None]
        dark = np.clip(1 - np.abs(dist - 11) / 3, 0, 1) * 0.6  # its shadow line
        rgb = rgb * (1 - dark[..., None])
        out[..., :3] = out[..., :3] * (1 - a[..., None]) + rgb * a[..., None]
        out[..., 3] = np.maximum(out[..., 3], a * 255)
        # rivets along the edge, 20 px in
        for x in range(70, BW - 69, 52):
            ye = (yU if upper else yL)[0, x]
            yr = ye - 20 if upper else ye + 20
            rr = np.hypot(lx - x, ly - yr)
            m = (rr < 6) & (a > 0.5)
            out[m, :3] = [150, 100, 40]
            hl = (np.hypot(lx - x + 1.5, ly - yr + 1.5) < 3) & m
            out[hl, :3] = [255, 222, 150]
    out[..., 3] *= inside
    return Image.fromarray(np.clip(out, 0, 255).astype("uint8"), "RGBA")


frames = [frame(i / (N - 1)) for i in range(N)]
for s in range(3):
    sheet = Image.new("RGBA", (2 * FW, 3 * FH), (0, 0, 0, 0))
    for j in range(6):
        sheet.paste(frames[s * 6 + j].resize((FW, FH), Image.LANCZOS), ((j % 2) * FW, (j // 2) * FH))
    sheet.save(os.path.join(OUT, "lids_%d.png" % s))

# preview over the eye: frames 0, 4, 8, 12, 17
eye = Image.open(os.path.join(HERE, "upload_1028", "r6", "brass_eye.png"))
prev = Image.new("RGB", (1024, 640 * 5))
for i, n in enumerate((0, 4, 8, 12, 17)):
    fr = Image.new("RGBA", (1024, 640), (20, 18, 24, 255))
    fr.alpha_composite(eye)
    fr.alpha_composite(frames[n], (144, 97))
    prev.paste(fr.convert("RGB"), (0, 640 * i))
prev.resize((512, 1600)).save(os.path.join(OUT, "preview.jpg"))
print("wrote", OUT)
