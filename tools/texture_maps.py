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


# ---- enemies and bosses (T124): 512 px sets with weathering per stage set -------------------------------------------------------------------
# Inputs from Blender/bake_enemy_maps.py: Roblox Dev/Assets/3D/Enemies/maps/_bake/<Name>_bake_color.png (palette colour on a smart-projected UV) and _bake_ao.png.
# Outputs in Enemies/maps/: <Name>_<Set>_Color_512, <Name>_<Set>_Roughness_512, <Name>_<Set>_Emissive_512, <Name>_Normal_512, <Name>_sets_sheet.png, enemy_maps_report.json.
# Weathering is procedural (noise, ambient occlusion, hue tests), one rule per set from Design/Stage Set Plans (T151): re-skin, never a new palette. Stage props: no prop models exist yet, so none are made.
EN = ROOT / "Roblox Dev" / "Assets" / "3D" / "Enemies" / "maps"
BAKE = EN / "_bake"
SETS = ["Lampwick", "Harbour", "Cathedral", "Foundry", "GreyVeil"]


def noise(seed, blur, shape=(S, S)):
    r = np.random.default_rng(seed)
    n = Image.fromarray((r.random(shape) * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(blur))
    a = np.asarray(n).astype(float)
    return (a - a.min()) / max(1e-6, a.max() - a.min())


def weather(a, ao, setname, seed):
    """a: colour 0..1 (H,W,3); ao: 0..1 (1 = open). Returns colour, roughness, emissive-add (all 0..1)."""
    mx, mn = a.max(2), a.min(2)
    painted = (mx > 0.03)[..., None]
    crev = np.clip((0.85 - ao) / 0.6, 0, 1)[..., None]       # crevices
    edge = np.clip((ao - 0.92) / 0.08, 0, 1)[..., None]      # open, exposed faces
    n1, n2 = noise(seed, 3)[..., None], noise(seed + 1, 1.2)[..., None]
    streak = noise(seed + 2, 0.0)  # replaced below by vertical streaks
    sx = np.asarray(Image.fromarray((np.random.default_rng(seed + 2).random((1, S)) * 255).astype("uint8")).resize((S, S)).filter(ImageFilter.GaussianBlur(2))).astype(float) / 255
    sx = ((sx - sx.min()) / max(1e-6, sx.max() - sx.min()))[..., None]
    rough = np.full((S, S), 0.55)
    glow = np.zeros((S, S))
    warm = ((a[..., 0] > a[..., 2] + 0.04) & (mx > 0.25))[..., None]  # brass and gold read warm
    if setname == "Lampwick":
        out = a * (1 - 0.25 * crev) + 0.05 * crev * n1  # dust and dirt in cracks
        rough = rough + 0.15 * crev[..., 0]
    elif setname == "Harbour":
        out = a * np.array([0.82, 0.93, 0.95]) * (1 - 0.3 * crev)  # wet and dark
        verd = np.clip((sx * 1.4 + n1 * 0.6 - 0.75) * 4, 0, 1) * warm * painted  # verdigris streaks run down brass
        out = out * (1 - 0.7 * verd) + np.array([0.27, 0.58, 0.48]) * 0.7 * verd
        rough = 0.32 - 0.1 * n2[..., 0] + 0.25 * verd[..., 0]
    elif setname == "Cathedral":
        out = a * 0.9 + 0.1 * np.array([0.9, 0.88, 0.8])  # pale
        gold = np.clip((edge[..., 0] - 0.3) * 1.4, 0, 1)[..., None] * (n1 > 0.35) * painted  # gilded edging on exposed faces
        out = out * (1 - 0.55 * gold) + np.array([0.82, 0.64, 0.24]) * 0.55 * gold
        wax = (np.clip((n1 - 0.72) * 6, 0, 1) * crev.clip(0.3, 1)) * painted  # wax drips
        out = out * (1 - 0.6 * wax) + np.array([0.93, 0.9, 0.78]) * 0.6 * wax
        rough = 0.5 - 0.15 * gold[..., 0]
    elif setname == "Foundry":
        out = a * np.array([0.74, 0.66, 0.58]) * (1 - 0.5 * crev)  # ash-brown, soot in crevices
        out = out * (1 - 0.2 * n2) + 0.0
        seam = np.clip((crev[..., 0] - 0.75) * 4, 0, 1) * (n1[..., 0] > 0.55) * painted[..., 0]  # ember glow in the seams
        out = out * (1 - 0.8 * seam[..., None]) + np.array([1.0, 0.45, 0.1]) * 0.8 * seam[..., None]
        glow = seam
        rough = 0.75 - 0.2 * seam
    else:  # GreyVeil: cold, starlit
        out = a * np.array([0.82, 0.9, 1.05]) + 0.06 * edge * np.array([0.6, 0.75, 1.0])
        flecks = (np.random.default_rng(seed + 3).random((S, S)) > 0.9985).astype(float)
        flecks = np.asarray(Image.fromarray((flecks * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(0.8))).astype(float) / 255
        flecks = np.clip(flecks * 5, 0, 1)[..., None] * painted
        out = out * (1 - flecks) + np.array([0.85, 0.92, 1.0]) * flecks
        rough = 0.45 - 0.15 * flecks[..., 0]
        glow = flecks[..., 0] * 0.6
    out = np.where(painted, np.clip(out, 0, 1), a)
    return out, np.clip(rough, 0, 1), np.clip(glow, 0, 1)


ereport = {}
bakes = sorted(BAKE.glob("*_bake_color.png")) if BAKE.exists() else []
for ci, cp in enumerate(bakes):
    n = cp.name[:-len("_bake_color.png")]
    a = np.asarray(Image.open(cp).convert("RGB")).astype(float) / 255
    ao = np.asarray(Image.open(BAKE / f"{n}_bake_ao.png").convert("L")).astype(float) / 255
    mx = a.max(2)
    sat = (mx - a.min(2)) / np.maximum(mx, 1e-6)
    base_glow = smooth(mx, 0.80, 0.95) * smooth(sat, 0.30, 0.50) * (mx > 0.03)
    lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2])
    low = np.asarray(Image.fromarray((lum * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(6))).astype(float) / 255
    h = (lum - low) + 0.6 * (ao - 0.8)  # painted edges plus a hint of ambient-occlusion relief
    dx, dy = np.gradient(h, axis=1) * 2.0 * S / 64, np.gradient(h, axis=0) * 2.0 * S / 64
    ln = np.sqrt(dx * dx + dy * dy + 1)
    Image.fromarray((np.stack([(-dx / ln + 1) / 2, (dy / ln + 1) / 2, (1 / ln + 1) / 2], 2) * 255).astype("uint8")).save(EN / f"{n}_Normal_512.png")
    tiles, rep = [], {"painted_fraction": round(float((mx > 0.03).mean()), 3)}
    for si, s in enumerate(SETS):
        col, rough, glow = weather(a, ao, s, 1000 * ci + 10 * si)
        em = np.clip(np.maximum(base_glow, glow), 0, 1)
        em = Image.fromarray((em * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1))
        Image.fromarray((col * 255).astype("uint8")).save(EN / f"{n}_{s}_Color_512.png")
        Image.fromarray((rough * 255).astype("uint8")).save(EN / f"{n}_{s}_Roughness_512.png")
        em.save(EN / f"{n}_{s}_Emissive_512.png")
        tiles.append(Image.fromarray((col * 255).astype("uint8")))
        rep[s] = {"mean_rgb": [round(float(v), 3) for v in col[mx > 0.03].mean(0)] if (mx > 0.03).any() else None, "roughness_mean": round(float(rough.mean()), 3),
                  "emissive_fraction": round(float((np.asarray(em) > 128).mean()), 4)}
    sheet = Image.new("RGB", (len(SETS) * 256, 256 + 22), (24, 24, 30))
    d = ImageDraw.Draw(sheet)
    for i, (t, s) in enumerate(zip(tiles, SETS)):
        sheet.paste(t.resize((256, 256), Image.LANCZOS), (i * 256, 22))
        d.text((i * 256 + 6, 4), f"{n} {s}", fill=(230, 230, 230))
    sheet.save(EN / f"{n}_sets_sheet.png")
    ereport[n] = rep
if ereport:
    (EN / "enemy_maps_report.json").write_text(json.dumps(ereport, indent=1))
    print(f"enemy sets: {len(ereport)} models x {len(SETS)} stage sets, 512 px: Color, Roughness, Emissive per set plus Normal")
    for n, r in ereport.items():
        print(n, r["painted_fraction"], {s: r[s]["emissive_fraction"] for s in SETS})
