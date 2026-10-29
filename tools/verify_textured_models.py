"""Check the textured familiar models (T091). Hunyuan3D venv python (trimesh, PIL, numpy).
For each <Name>.glb in Roblox Dev/Assets/3D/Familiars/textured: UV coordinates present, a base-colour texture and a metallic-roughness texture
embedded in the GLB, texture size, share of the colour map that is painted (not black), colour variety, roughness range.
Exit 1 if any check fails."""
import pathlib, sys
import numpy as np
import trimesh
from PIL import Image

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "textured"
ORIGINAL12 = ["Ward", "Archivist", "Mourner", "MirrorChorister", "Sentinel", "Frostling", "BrassHound", "Gargoyle", "MothLantern", "StarDrake", "Ember", "GreyVeilWraith"]
SPECKLE_MAX = 0.02  # T407: share of painted pixels more than 24 levels from their 5 by 5 median; the first-pass bakes of the 12 originals were 0.010 to 0.045


def speckle(a):
    q = a.astype(int)
    H, W = a.shape[:2]
    pad = np.pad(a, ((2, 2), (2, 2), (0, 0)), mode="edge")
    med = np.median(np.stack([pad[y:y + H, x:x + W] for y in range(5) for x in range(5)]), axis=0)
    painted = q.sum(axis=2) > 30
    return float(((np.abs(q - med).max(axis=2) > 24) & painted).sum() / max(1, painted.sum()))


bad = 0
print(f"{'model':18} {'uv':3} {'colTex':6} {'rghTex':6} {'size':>10} {'painted%':>8} {'colours':>7} {'rough min-max':>14} {'tris':>6} {'speckle':>7}")
for g in sorted(D.glob("*.glb")):
    sc = trimesh.load(str(g), force="scene")
    geoms = [x for x in sc.geometry.values() if hasattr(x, "faces")]
    m = geoms[0]
    uv = getattr(m.visual, "uv", None) is not None
    mat = getattr(m.visual, "material", None)
    col = getattr(mat, "baseColorTexture", None)
    rgh = getattr(mat, "metallicRoughnessTexture", None)
    colimg = np.asarray(Image.open(D / f"{g.stem}_BaseColor.png").convert("RGB"))
    rghimg = np.asarray(Image.open(D / f"{g.stem}_Roughness.png").convert("L"))
    painted = (colimg.sum(axis=2) > 30).mean() * 100
    ncol = len({tuple(c) for c in (colimg[::8, ::8] // 16).reshape(-1, 3)})
    rmin, rmax = rghimg[rghimg > 0].min() if (rghimg > 0).any() else 0, rghimg.max()
    sizes = f"{col.size[0]}x{col.size[1]}" if col is not None else "-"
    tris = sum(len(x.faces) for x in geoms)
    sp = speckle(colimg)
    ok = uv and col is not None and rgh is not None and painted > 15 and ncol > 6 and (rmax - rmin) > 10 and (sp <= SPECKLE_MAX or g.stem not in ORIGINAL12)
    if not ok:
        bad += 1
    print(f"{g.stem:18} {str(uv):3} {str(col is not None):6} {str(rgh is not None):6} {sizes:>10} {painted:8.1f} {ncol:7d} {int(rmin):6d}-{int(rmax):<6d} {tris:6d} {sp:7.4f}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
