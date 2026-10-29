"""Derive the 512 px map set for the 12 familiars (T123, T127, T128): python tools/texture_maps.py
Reads Roblox Dev/Assets/3D/Familiars/textured/<Name>_BaseColor.png and _Roughness.png (1024 px, from Blender/bake_familiar_textures.py) and writes to Roblox Dev/Assets/3D/Familiars/maps/:
  <Name>_Color_512.png, <Name>_Roughness_512.png, <Name>_Normal_512.png, <Name>_Emissive_512.png, and one contact sheet per rig family (<family>_<map>_sheet.png) plus maps_report.json.
Emissive rule (one rule across the cast): a pixel glows when it is bright and saturated: glow = smoothstep(0.80, 0.95, value) * smoothstep(0.30, 0.50, saturation), blurred 1 px, zero where the texture is unpainted (value under 0.03).
Normal map: tangent-space (OpenGL) normals from the high-pass of the colour luminance (painted edges and features become relief), strength 2.0; it is an inferred relief, not sculpted detail.
Family sheets are references: the models still use their own UVs; the maps are not packed into shared atlases."""
import json
import pathlib
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "textured"
OUT = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "maps"
OUT.mkdir(parents=True, exist_ok=True)
FAMILIES = {"biped": ["Ward", "Archivist", "Mourner", "MirrorChorister", "Sentinel", "Frostling"], "quadruped": ["BrassHound", "Gargoyle"], "flyer": ["MothLantern", "StarDrake"], "floater": ["Ember", "GreyVeilWraith"]}
S = 512


def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


report = {}
maps = {}
for fam, names in FAMILIES.items():
    for n in names:
        col = Image.open(SRC / f"{n}_BaseColor.png").convert("RGB").resize((S, S), Image.LANCZOS)
        rough = Image.open(SRC / f"{n}_Roughness.png").convert("L").resize((S, S), Image.LANCZOS)
        a = np.asarray(col).astype(float) / 255
        mx, mn = a.max(2), a.min(2)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        glow = smooth(mx, 0.80, 0.95) * smooth(sat, 0.30, 0.50) * (mx > 0.03)
        em = Image.fromarray((glow * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1))
        lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2])
        low = np.asarray(Image.fromarray((lum * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(6))).astype(float) / 255
        h = lum - low
        dx = np.gradient(h, axis=1) * 2.0 * S / 64
        dy = np.gradient(h, axis=0) * 2.0 * S / 64
        nz = np.ones_like(h)
        ln = np.sqrt(dx * dx + dy * dy + nz * nz)
        nrm = np.stack([(-dx / ln + 1) / 2, (dy / ln + 1) / 2, (nz / ln + 1) / 2], 2)
        normal = Image.fromarray((nrm * 255).astype("uint8"))
        files = {"Color": col, "Roughness": rough, "Normal": normal, "Emissive": em}
        for k, im in files.items():
            im.save(OUT / f"{n}_{k}_512.png")
        maps[n] = files
        painted = float((mx > 0.03).mean())
        report[n] = {"family": fam, "painted_fraction": round(painted, 3), "emissive_fraction_of_painted": round(float((glow > 0.5).sum() / max(1, (mx > 0.03).sum())), 4),
                     "normal_strength_std": round(float(np.sqrt(dx.var() + dy.var())), 4), "roughness_mean": round(float(np.asarray(rough).mean() / 255), 3)}
for fam, names in FAMILIES.items():
    for k in ("Color", "Roughness", "Normal", "Emissive"):
        cols = min(3, len(names))
        rows = (len(names) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * S, rows * (S + 22)), (24, 24, 30))
        d = ImageDraw.Draw(sheet)
        for i, n in enumerate(names):
            x, y = (i % cols) * S, (i // cols) * (S + 22)
            sheet.paste(maps[n][k].convert("RGB"), (x, y + 22))
            d.text((x + 6, y + 4), f"{n} {k} 512", fill=(230, 230, 230))
        sheet.save(OUT / f"{fam}_{k}_sheet.png")
(OUT / "maps_report.json").write_text(json.dumps(report, indent=1))
for n, r in report.items():
    print(n, r)
