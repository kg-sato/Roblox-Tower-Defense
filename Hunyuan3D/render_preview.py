"""Render preview images of a mesh: python render_preview.py model.glb [out_dir]"""
import sys
from pathlib import Path
import numpy as np
import trimesh
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

src = Path(sys.argv[1])
out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.parent / "preview"
out.mkdir(parents=True, exist_ok=True)

m = trimesh.load(src, force="mesh")
m.apply_translation(-m.bounds.mean(axis=0))
v, f = m.vertices, m.faces
# glTF is Y-up; matplotlib is Z-up, so swap axes: (x, y, z) -> (x, -z, y)
v = np.stack([v[:, 0], -v[:, 2], v[:, 1]], axis=1)
tris = v[f]
normals = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
normals /= np.linalg.norm(normals, axis=1, keepdims=True) + 1e-12
light = np.array([0.4, -0.6, 0.7]); light /= np.linalg.norm(light)
shade = 0.25 + 0.75 * np.clip(normals @ light, 0, 1)
colors = np.stack([shade * 0.78, shade * 0.80, shade * 0.86, np.ones_like(shade)], axis=1)

r = (v.max(0) - v.min(0)).max() / 2 * 1.02
views = {"front": (5, -90), "side": (5, 0), "back": (5, 90), "three_quarter": (22, -45)}
for name, (elev, azim) in views.items():
    fig = plt.figure(figsize=(5, 5), dpi=160)
    ax = fig.add_subplot(111, projection="3d")
    pc = Poly3DCollection(tris, facecolors=colors, edgecolors="none", linewidths=0)
    ax.add_collection3d(pc)
    ax.set_xlim(-r, r); ax.set_ylim(-r, r); ax.set_zlim(-r, r)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev, azim); ax.set_axis_off()
    fig.patch.set_facecolor("#e9ecef")
    fig.savefig(out / f"{src.stem}_{name}.png", facecolor=fig.get_facecolor(), bbox_inches="tight", pad_inches=0.02)
    plt.close(fig)
    print(out / f"{src.stem}_{name}.png")

# wireframe close-up to judge triangle density
fig = plt.figure(figsize=(5, 5), dpi=160)
ax = fig.add_subplot(111, projection="3d")
ax.add_collection3d(Poly3DCollection(tris, facecolors=colors, edgecolors=(0, 0, 0, 0.35), linewidths=0.15))
ax.set_xlim(-r, r); ax.set_ylim(-r, r); ax.set_zlim(-r, r)
ax.set_box_aspect((1, 1, 1)); ax.view_init(22, -45); ax.set_axis_off()
fig.patch.set_facecolor("#e9ecef")
fig.savefig(out / f"{src.stem}_wireframe.png", facecolor=fig.get_facecolor(), bbox_inches="tight", pad_inches=0.02)
print(out / f"{src.stem}_wireframe.png")
