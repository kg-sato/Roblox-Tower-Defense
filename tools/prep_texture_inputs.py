"""Prepare projection images for the familiar texture bake (T091). Hunyuan3D venv python (PIL, numpy).
Crops the front, side and back colour views from each design sheet to the figure's silhouette box and bleeds the colours outward over the
background so that edges do not pick up the beige sheet colour. Writes Blender/tex_in/<Name>_front.png, _side.png, _back.png.
Usage: python tools/prep_texture_inputs.py [Name ...]"""
import pathlib, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHEETS = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"
OUT = ROOT / "Blender" / "tex_in"
OUT.mkdir(parents=True, exist_ok=True)
CAST = ["Ember", "MothLantern", "BrassHound", "Sentinel", "Frostling", "Gargoyle", "Ward", "Archivist", "Mourner", "MirrorChorister", "StarDrake", "GreyVeilWraith"]
PANEL_X = [20, 20 + 400, 20 + 800]  # front, side, back on the colour sheet (380 wide panels, 56 px from the top)


def bleed(rgb, mask, iters=24):
    rgb = rgb.astype(np.float32)
    valid = mask.copy()
    for _ in range(iters):
        if valid.all():
            break
        acc = np.zeros_like(rgb)
        cnt = np.zeros(valid.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                v = np.roll(np.roll(valid, dy, 0), dx, 1)
                c = np.roll(np.roll(rgb, dy, 0), dx, 1)
                acc += c * v[..., None]
                cnt += v
        new = (~valid) & (cnt > 0)
        rgb[new] = acc[new] / cnt[new][..., None]
        valid = valid | new
    return rgb.astype(np.uint8)


def main(names):
    for n in names:
        sheet = Image.open(SHEETS / f"{n}_sheet.png").convert("RGB")
        sil = Image.open(SHEETS / f"{n}_silhouette.png").convert("L")
        for i, label in enumerate(("front", "side", "back")):
            panel = sheet.crop((PANEL_X[i], 56, PANEL_X[i] + 380, 56 + 460))
            mask = np.asarray(sil.crop((i * 380, 0, (i + 1) * 380, 460))) < 128
            ys, xs = np.where(mask)
            box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
            rgb = np.asarray(panel)
            # shrink the mask by a few pixels so dark outlines and the sheet background do not bleed into the colours
            from scipy.ndimage import binary_erosion
            core = binary_erosion(mask, iterations=3)
            filled = bleed(rgb, core)
            img = Image.fromarray(filled).crop(box)
            img.save(OUT / f"{n}_{label}.png")
        print("prepared", n)


if __name__ == "__main__":
    main(sys.argv[1:] or CAST)
