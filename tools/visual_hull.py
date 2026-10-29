"""Build a volumetric low-poly model from a familiar's front and side silhouettes (visual hull), for characters whose Hunyuan3D shape came out as a thin plate.
Usage (Hunyuan3D venv python): python tools/visual_hull.py <Name> [<Name> ...]
Reads Roblox Dev/Assets/Characters/Design Sheets/<Name>_silhouette.png (panel 0 = front, panel 1 = side, both drawn at the same scale and ground line),
intersects the two extruded silhouettes in a voxel grid, smooths, runs marching cubes, decimates to about 18000 triangles and writes
Roblox Dev/Assets/3D/Familiars/<Name>.glb (Y up, 1.97 units tall, like the Hunyuan3D output). Pure numpy, scipy, scikit-image, trimesh, pymeshlab."""
import pathlib, sys
import numpy as np
import trimesh
import pymeshlab
from PIL import Image
from scipy.ndimage import gaussian_filter
from skimage.measure import marching_cubes

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHEETS = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"
OUT = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars"
PANEL = 380
TARGET_FACES = 18000
HEIGHT_UNITS = 1.97


def panel_mask(name, idx):
    im = Image.open(SHEETS / f"{name}_silhouette.png").convert("L").crop((idx * PANEL, 0, (idx + 1) * PANEL, 460))
    return np.asarray(im) < 128


def build(name):
    front, side = panel_mask(name, 0), panel_mask(name, 1)
    fy, fx = np.where(front)
    sy, sx = np.where(side)
    y0, y1 = min(fy.min(), sy.min()), max(fy.max(), sy.max())
    f = front[y0:y1 + 1, fx.min():fx.max() + 1]
    s = side[y0:y1 + 1, sx.min():sx.max() + 1]
    h = f.shape[0]
    # downscale so the grid is about 200 voxels tall
    k = 200 / h
    def rs(m, shape):
        return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize(shape, Image.BILINEAR)) > 127
    H = 200
    F = rs(f, (max(1, round(f.shape[1] * k)), H))   # shape (H, Wf)
    S = rs(s, (max(1, round(s.shape[1] * k)), H))   # shape (H, Ws)
    vol = (F[:, :, None] & S[:, None, :]).astype(np.float32)  # (y, x, z)
    vol = np.pad(vol, 4)
    vol = gaussian_filter(vol, 2.2)
    verts, faces, _, _ = marching_cubes(vol, level=0.45)
    # axes: (y, x, z) -> (x, y up, z); flip y because image rows run downwards
    v = np.stack([verts[:, 1], (vol.shape[0] - verts[:, 0]), verts[:, 2]], axis=1)
    v -= np.array([v[:, 0].mean(), v[:, 1].min(), v[:, 2].mean()])
    v *= HEIGHT_UNITS / (v[:, 1].max() - v[:, 1].min())
    m = trimesh.Trimesh(vertices=v, faces=faces[:, ::-1], process=True)
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(m.vertices, m.faces))
    ms.meshing_decimation_quadric_edge_collapse(targetfacenum=TARGET_FACES, preservenormal=True)
    ms.meshing_re_orient_faces_coherently()
    out = ms.current_mesh()
    mm = trimesh.Trimesh(vertices=out.vertex_matrix(), faces=out.face_matrix(), process=True)
    OUT.mkdir(parents=True, exist_ok=True)
    mm.export(OUT / f"{name}.glb")
    ext = mm.extents
    print(f"{name}: {len(mm.faces)} triangles, size {ext[0]:.2f} x {ext[1]:.2f} x {ext[2]:.2f}")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        build(n)
