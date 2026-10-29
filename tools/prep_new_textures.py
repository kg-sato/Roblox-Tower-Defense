"""Projection images for the new human familiars (Mythic and Celestial): python tools/prep_new_textures.py [Name ...]
Front = the keyed concept image in Hunyuan3D/input_pick/<Name>.png; back = Hunyuan3D/input_new/<Name>_back_s31.png (the same character from behind, made by tools/comfy_character.py --view back),
or, where the back concept is unusable (VeilWalker: bare skin), the front's per-row median colour. Side = the front's per-row median colour (a plain column of the body colours, so no face or sash smears onto the
sides). Each image is cropped to the figure's box with the colours bled outward, as tools/prep_texture_inputs.py does, and written to Blender/tex_in/<Name>_front|side|back.png."""
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import binary_erosion, label

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from prep_texture_inputs import bleed  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "Blender" / "tex_in"
NAMES = ["CantorVesper", "DameOrrery", "TheLamplighter", "VeilWalker"]
NO_BACK = {"VeilWalker"}


def crop_fill(rgba):
    a = np.asarray(rgba)
    mask = a[..., 3] > 128
    lab, n = label(mask)  # drop stray specks: keep parts of at least 3 percent of the biggest part
    if n > 1:
        sizes = np.bincount(lab.ravel())[1:]
        keep = [i + 1 for i, sz in enumerate(sizes) if sz >= 0.03 * sizes.max()]
        mask = np.isin(lab, keep)
    ys, xs = np.where(mask)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    core = binary_erosion(mask, iterations=3)
    filled = bleed(a[..., :3], core, iters=120)
    return Image.fromarray(filled).crop(box), mask[box[1]:box[3], box[0]:box[2]]


def row_median(img, mask):
    rgb = np.asarray(img).astype(float)
    out = np.zeros_like(rgb)
    for y in range(rgb.shape[0]):
        row = rgb[y][mask[y]] if mask[y].any() else rgb[y]
        out[y, :] = np.median(row, axis=0)
    return Image.fromarray(out.astype("uint8"))


for n in sys.argv[1:] or NAMES:
    front, fmask = crop_fill(Image.open(ROOT / "Hunyuan3D" / "input_pick" / f"{n}.png").convert("RGBA"))
    front.save(OUT / f"{n}_front.png")
    side = row_median(front, fmask).resize(front.size)
    side.save(OUT / f"{n}_side.png")
    backp = ROOT / "Hunyuan3D" / "input_new" / f"{n}_back_s31.png"
    if n in NO_BACK or not backp.exists():
        row_median(front, fmask).save(OUT / f"{n}_back.png")
    else:
        back, _ = crop_fill(Image.open(backp).convert("RGBA"))
        back.save(OUT / f"{n}_back.png")
    print("prepared", n, front.size)
