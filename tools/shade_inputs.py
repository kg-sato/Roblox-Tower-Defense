"""Make Hunyuan3D input images look like rendered 3D objects instead of flat clip art (T089).
Flat-colour drawings come out of the model as thin extruded plates. This adds a fake height field from the alpha mask (blurred), computes
normals from it, and multiplies Lambert shading plus edge darkening onto the colours.
Usage (Hunyuan3D venv python): python tools/shade_inputs.py <in_dir> <out_dir> [Name ...]"""
import os, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
names = sys.argv[3:]
files = [src / f"{n}.png" for n in names] if names else sorted(src.glob("*.png"))
for f in files:
    im = Image.open(f).convert("RGBA")
    a = im.getchannel("A")
    w, h = im.size
    sigma = max(w, h) * float(os.environ.get('SHADE_SIGMA', '0.035'))
    height = np.asarray(a.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32) / 255.0
    height = np.sqrt(height)  # fatter, rounder profile
    gy, gx = np.gradient(height * (max(w, h) * float(os.environ.get('SHADE_GAIN', '0.12'))))
    nz = np.ones_like(gx)
    n = np.stack([-gx, -gy, nz], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    light = np.array([-0.4, -0.6, 0.7], dtype=np.float32)
    light /= np.linalg.norm(light)
    lam = np.clip(n @ light, 0, 1)
    shade = 0.45 + 0.75 * lam
    edge = np.clip(height * 1.4, 0, 1)  # darken towards the silhouette edge
    shade = shade * (0.55 + 0.45 * edge)
    rgb = np.asarray(im.convert("RGB"), dtype=np.float32) * shade[..., None]
    out = np.dstack([np.clip(rgb, 0, 255).astype(np.uint8), np.asarray(a)])
    Image.fromarray(out, "RGBA").save(dst / f.name)
    print("shaded", f.name, im.size)
