"""Iris layers for the loading screen's great brass eye (2026-10-29; the user: "the eye twitches in the middle and it
looks really unimpressive", "more rotational movement so the suck in is more immersive"). Cuts the two numeral dials out
of brass_eye.png as rings, so LoadingScreen can turn them against each other (clockwork) and spin them up during the
pull, plus a soft black pupil disc that dilates to swallow the view.
Measured from brass_eye.png: pupil centre (522, 314), pupil radius 46, inner dial 46..100, outer dial 100..172.
Output in upload_1028/r8/: iris_inner.png (208 px), iris_outer.png (352 px), pupil_disc.png (256 px).
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_iris_rings.py" """
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "upload_1028", "r8")
CX, CY = 522, 314
os.makedirs(OUT, exist_ok=True)
eye = np.array(Image.open(os.path.join(HERE, "upload_1028", "r6", "brass_eye.png")).convert("RGBA")).astype(float)


def ring(R, r0, r1, name):
    crop = eye[CY - R:CY + R, CX - R:CX + R].copy()
    yy, xx = np.mgrid[0:2 * R, 0:2 * R].astype(float)
    r = np.hypot(xx - R + 0.5, yy - R + 0.5)
    a = np.clip((r - r0) / 2 + 0.5, 0, 1) * np.clip((r1 - r) / 2 + 0.5, 0, 1)  # 2 px soft edges
    crop[..., 3] = 255 * a
    Image.fromarray(crop.astype("uint8"), "RGBA").save(os.path.join(OUT, name))
    return crop


inner = ring(104, 45, 101, "iris_inner.png")
outer = ring(176, 99, 172, "iris_outer.png")
assert inner.shape == (208, 208, 4) and outer.shape == (352, 352, 4)
assert inner[104, 104, 3] == 0 and inner[104, 104 + 70, 3] == 255 and outer[176, 176 + 130, 3] == 255

# the pupil: black, with a soft edge and a thin warm rim so it reads as a hole in brass, not a sticker
S = 256
yy, xx = np.mgrid[0:S, 0:S].astype(float)
r = np.hypot(xx - S / 2 + 0.5, yy - S / 2 + 0.5) / (S / 2)  # 0 centre .. 1 edge
disc = np.zeros((S, S, 4))
alpha = np.clip((0.92 - r) / 0.08, 0, 1)
rim = np.clip(1 - np.abs(r - 0.86) / 0.06, 0, 1) * 0.55
disc[..., 0], disc[..., 1], disc[..., 2] = 255 * rim, 150 * rim, 60 * rim
disc[..., 3] = 255 * alpha
Image.fromarray(disc.astype("uint8"), "RGBA").save(os.path.join(OUT, "pupil_disc.png"))

# preview: rings rotated 30 / -45 degrees over the eye
prev = Image.fromarray(eye.astype("uint8"), "RGBA")
prev.alpha_composite(Image.open(os.path.join(OUT, "iris_outer.png")).rotate(30, Image.BICUBIC), (CX - 176, CY - 176))
prev.alpha_composite(Image.open(os.path.join(OUT, "iris_inner.png")).rotate(-45, Image.BICUBIC), (CX - 104, CY - 104))
prev.convert("RGB").crop((300, 100, 744, 530)).save(os.path.join(OUT, "preview.jpg"))
print("wrote", OUT)
