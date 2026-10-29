"""Recolour the 12 familiar base-colour textures in the etched eye's gold-ink palette (the user, 2026-10-29: "make the new 3D model similar in coloring", answered "yes applied" to recolouring the familiars).
Same measured gradient as UI Kit/art/recolor_etched.py (brightness -> dark umber, antique gold, cream, from menu_art/etched_eye_onscreen.png). Each texture's brightness is stretched (1st to 99th percentile of the painted pixels) onto the
reference range with gamma 1.6, mapped through the gradient, then blended with the original colour so each familiar keeps a hint of its identity: result = KEEP x original + (1 - KEEP) x gold-ink (KEEP = 0.2, change with --keep).
Unpainted pixels (value under 0.03) stay black. Reads Roblox Dev/Assets/3D/Familiars/textured/<Name>_BaseColor.png, writes Roblox Dev/Assets/3D/Familiars/gold/<Name>_BaseColor.png, a contact sheet gold_sheet.png and gold_report.json
(mean colour of the brightest 5 % of painted pixels for the reference and for each output, so the match is measured). Run: Hunyuan3D/.venv/Scripts/python tools/recolor_familiars.py [--keep 0.2]"""
import json
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "textured"
OUT = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "gold"
OUT.mkdir(parents=True, exist_ok=True)
keep = float(sys.argv[sys.argv.index("--keep") + 1]) if "--keep" in sys.argv else 0.2


def lum(rgb):
    return rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114


ref = np.array(Image.open(ROOT / "UI Kit" / "art" / "menu_art" / "etched_eye_onscreen.png").convert("RGBA")).astype(float)
m = ref[..., 3] > 200
rgb, L = ref[..., :3][m], lum(ref[..., :3][m])
o = np.argsort(L)
L, rgb = L[o], rgb[o]
qs = np.array_split(np.arange(len(L)), 64)
grad_L = np.array([L[q].mean() for q in qs])
grad_C = np.array([rgb[q].mean(0) for q in qs])


def top5(img_rgb, mask):
    l = lum(img_rgb)[mask]
    cut = np.percentile(l, 95)
    return [round(float(x), 1) for x in img_rgb[mask][l >= cut].mean(0)]


report = {"reference_top5_rgb": top5(ref[..., :3], m), "keep": keep}
names = sorted(p.stem[:-10] for p in SRC.glob("*_BaseColor.png"))
sheet = Image.new("RGB", (4 * 256, 3 * 278), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    im = np.array(Image.open(SRC / f"{n}_BaseColor.png").convert("RGB")).astype(float)
    l = lum(im)
    painted = im.max(2) / 255 > 0.03
    lo, hi = np.percentile(l[painted], [1, 99])
    matched = grad_L[0] + np.clip((l - lo) / max(1, hi - lo), 0, 1) ** 1.6 * (grad_L[-1] - grad_L[0])
    gold = np.stack([np.interp(matched, grad_L, grad_C[:, c]) for c in range(3)], 2)
    g = gold.mean(-1, keepdims=True)
    gold = g + (gold - g) * 1.6
    out = keep * im + (1 - keep) * gold
    out[~painted] = 0
    out = np.clip(out, 0, 255)
    Image.fromarray(out.astype("uint8")).save(OUT / f"{n}_BaseColor.png")
    report[n] = {"top5_rgb": top5(out, painted)}
    t = Image.fromarray(out.astype("uint8")).resize((256, 256))
    x, y = (i % 4) * 256, (i // 4) * 278
    sheet.paste(t, (x, y + 22))
    d.text((x + 6, y + 5), n, fill=(230, 230, 230))
sheet.save(OUT / "gold_sheet.png")
(OUT / "gold_report.json").write_text(json.dumps(report, indent=1))
print("reference top 5% mean RGB", report["reference_top5_rgb"])
for n in names:
    ref5 = np.array(report["reference_top5_rgb"])
    dist = float(np.linalg.norm(np.array(report[n]["top5_rgb"]) - ref5))
    report[n]["distance_to_reference"] = round(dist, 1)
    print(f"{n:16s} top5 {report[n]['top5_rgb']} distance {dist:.1f}")
(OUT / "gold_report.json").write_text(json.dumps(report, indent=1))
