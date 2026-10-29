"""Check the textured familiar models (T091). Hunyuan3D venv python (trimesh, PIL, numpy).
For each <Name>.glb in Roblox Dev/Assets/3D/Familiars/textured: UV coordinates present, a base-colour texture and a metallic-roughness texture
embedded in the GLB, texture size, share of the colour map that is painted (not black), colour variety, roughness range.
Exit 1 if any check fails."""
import pathlib, sys
import numpy as np
import trimesh
from PIL import Image

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "textured"
bad = 0
print(f"{'model':18} {'uv':3} {'colTex':6} {'rghTex':6} {'size':>10} {'painted%':>8} {'colours':>7} {'rough min-max':>14} {'tris':>6}")
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
    ok = uv and col is not None and rgh is not None and painted > 15 and ncol > 6 and (rmax - rmin) > 10
    if not ok:
        bad += 1
    print(f"{g.stem:18} {str(uv):3} {str(col is not None):6} {str(rgh is not None):6} {sizes:>10} {painted:8.1f} {ncol:7d} {int(rmin):6d}-{int(rmax):<6d} {tris:6d}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
