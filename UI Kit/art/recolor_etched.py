"""Recolours the great brass eye's layers in the etched eye's palette (2026-10-29; the user, showing the old etched
loading-screen eye: "I really like the coloring in this", "i wanted these colors").
The palette is measured, not picked: pixels of the etched eye (upload_1028/eye.png) are sorted by brightness and the
mean colour of each brightness step becomes a gradient map (dark umber -> antique gold -> cream). Each target's
brightness is first histogram-matched to the etched eye's, so its contrast matches too, then mapped through the
gradient. Alpha is kept.
Inputs: r6/brass_eye.png, r8/iris_inner.png, r8/iris_outer.png, r7/lids_0..2.png. Outputs: same names in r9/.
Run: Hunyuan3D/.venv/Scripts/python.exe -I "UI Kit/art/recolor_etched.py" """
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "upload_1028")
OUT = os.path.join(UP, "r9")
os.makedirs(OUT, exist_ok=True)


def lum(rgb):
    return rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114


# eye.png itself is grey (Studio tinted it gold), so the reference is the eye as it showed on screen: a crop of the
# user's contact sheet, saved as menu_art/etched_eye_onscreen.png
ref = np.array(Image.open(os.path.join(HERE, "menu_art", "etched_eye_onscreen.png")).convert("RGBA")).astype(float)
m = ref[..., 3] > 200
rgb, L = ref[..., :3][m], lum(ref[..., :3][m])
order = np.argsort(L)
L, rgb = L[order], rgb[order]
N = 64  # gradient steps by brightness quantile
qs = np.array_split(np.arange(len(L)), N)
grad_L = np.array([L[q].mean() for q in qs])
grad_C = np.array([rgb[q].mean(0) for q in qs])
ref_sorted_L = L  # for histogram matching


def recolor(src, dst):
    im = np.array(Image.open(src).convert("RGBA")).astype(float)
    a = im[..., 3]
    l = lum(im[..., :3])
    vis = a > 30
    # stretch brightness (1st..99th percentile of the visible pixels) onto the reference's range; a full histogram
    # match made the eye as dark as the reference crop, which is mostly backdrop
    lo, hi = np.percentile(l[vis], [1, 99])
    # gamma 1.6: the etched eye is mostly dark with gold highlights, not mid-grey
    matched = grad_L[0] + np.clip((l - lo) / max(1, hi - lo), 0, 1) ** 1.6 * (grad_L[-1] - grad_L[0])
    out = np.empty_like(im)
    for c in range(3):
        out[..., c] = np.interp(matched, grad_L, grad_C[:, c])
    g = out[..., :3].mean(-1, keepdims=True)  # +60% saturation: the reference was measured through the fog, which greys it again on screen
    out[..., :3] = g + (out[..., :3] - g) * 1.6
    out[..., 3] = a
    out[~vis, :3] = im[~vis, :3] * 0.3  # near-invisible edge pixels: keep dark so no bright fringe
    Image.fromarray(np.clip(out, 0, 255).astype("uint8"), "RGBA").save(dst)
    return out


for rel in ["r6/brass_eye.png", "r8/iris_inner.png", "r8/iris_outer.png", "r7/lids_0.png", "r7/lids_1.png", "r7/lids_2.png"]:
    recolor(os.path.join(UP, rel), os.path.join(OUT, os.path.basename(rel)))

print("palette dark/mid/light:", [tuple(int(x) for x in grad_C[i]) for i in (2, 32, 61)])
# preview: the etched eye and the recoloured brass eye side by side on the backdrop's dark
bg = (18, 16, 20, 255)
e = Image.open(os.path.join(UP, "eye.png")).convert("RGBA").resize((512, 512))
b = Image.open(os.path.join(OUT, "brass_eye.png")).resize((512, 320))
pv = Image.new("RGBA", (1024, 512), bg)
pv.alpha_composite(e, (0, 0))
pv.alpha_composite(b, (512, 96))
pv.convert("RGB").save(os.path.join(OUT, "preview.jpg"))
print("wrote", OUT)
