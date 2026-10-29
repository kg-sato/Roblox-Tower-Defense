"""Splits the etched clock iris (upload_1028/r4/eye_iris.png, 424 px) into two rings for the loading screen's great eye,
so the numeral ring and the inner dial can turn against each other (2026-10-29; the user chose the 2D etched eye over
the layered brass one: "not very refined with a lot of overlapping parts... or go to 2D").
The split is at radius 141 px: a dark gap measured between the inner dial's double border (r 124-136) and the numeral
band (r 148+). Both outputs keep the 424 px canvas, so in Studio they sit exactly where the whole iris sat.
Output: upload_1028/r11/etched_iris_outer.png, etched_iris_inner.png.
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/make_etched_iris_rings.py" """
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "upload_1028", "r11")
os.makedirs(OUT, exist_ok=True)
src = np.array(Image.open(os.path.join(HERE, "upload_1028", "r4", "eye_iris.png")).convert("RGBA")).astype(float)
yy, xx = np.mgrid[0:424, 0:424].astype(float)
r = np.hypot(xx - 211.5, yy - 211.5)
SPLIT = 141
inner_a = np.clip((SPLIT - r) / 1.5 + 0.5, 0, 1)
for name, keep in (("etched_iris_inner.png", inner_a), ("etched_iris_outer.png", 1 - inner_a)):
    o = src.copy()
    o[..., 3] *= keep
    Image.fromarray(o.astype("uint8"), "RGBA").save(os.path.join(OUT, name))
inner = np.array(Image.open(os.path.join(OUT, "etched_iris_inner.png")))
outer = np.array(Image.open(os.path.join(OUT, "etched_iris_outer.png")))
assert inner[212, 212 + 160, 3] == 0 and outer[212, 212 + 60, 3] == 0  # each ring holds only its part
assert abs(inner[..., 3].astype(int) + outer[..., 3].astype(int) - src[..., 3]).max() <= 2  # together = the whole iris
print("wrote", OUT)
