"""Check an enemy model (T114 onward): python tools/verify_enemy_model.py <Name> [budget]. Reads Roblox Dev/Assets/3D/Enemies/<Name>/<Name>.glb (JSON chunk), <Name>_stats.json and the stills.
Checks: the GLB parses with one mesh and at least one material and an image; triangles at most the budget (default 3000; the project rule is under 20000 for any mesh); the front-view silhouette
(backdrop keyed out, scaled to 48 px, bounding-box fitted) differs from all 12 familiar front cutouts (IoU at most 0.5; the worst over all three views is printed for information) so an enemy never reads as a familiar; the model's own three views differ from each other.
Exit 1 on failure. Run with the Hunyuan3D venv."""
import json, pathlib, struct, sys
import numpy as np
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

name = sys.argv[1]
budget = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
D = fc.ROOT / "Roblox Dev" / "Assets" / "3D" / "Enemies" / name
rows, bad = [], 0
data = (D / f"{name}.glb").read_bytes()
assert data[:4] == b"glTF"
clen, ctype = struct.unpack("<II", data[12:20])
j = json.loads(data[20:20 + clen])
st = json.loads((D / f"{name}_stats.json").read_text())
ok = len(j.get("meshes", [])) == 1 and len(j.get("materials", [])) >= 1 and len(j.get("images", [])) >= 1
rows.append(f"glb: {len(j.get('meshes', []))} mesh, {len(j.get('materials', []))} materials, {len(j.get('images', []))} images {'ok' if ok else 'CHECK'}")
bad += not ok
ok = st["triangles"] <= budget
rows.append(f"triangles {st['triangles']} (budget {budget}, project limit 20000) {'ok' if ok else 'OVER BUDGET'}")
bad += not ok


def mask48(img):
    im = fc.key_out(img.convert("RGBA"))
    a = np.array(im.split()[3]) > 40
    ys, xs = np.where(a)
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    s = 44 / max(a.shape)
    pil = Image.fromarray((a * 255).astype("uint8")).resize((max(1, int(a.shape[1] * s)), max(1, int(a.shape[0] * s))), Image.LANCZOS)
    out = np.zeros((48, 48), bool)
    arr = np.array(pil) > 127
    oy, ox = (48 - arr.shape[0]) // 2, (48 - arr.shape[1]) // 2
    out[oy:oy + arr.shape[0], ox:ox + arr.shape[1]] = arr
    return out


views = {v: mask48(Image.open(D / f"{name}_{v}.png")) for v in ("front", "side", "three_quarter")}
cut = {p.stem: mask48(Image.open(fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Collection" / f"{p.stem}_cutout.png")) for p in fc.LORE.glob("*.md")}
worst, worst_all = (0, ""), (0, "")
for v, m in views.items():
    for n, c in cut.items():
        iou = (m & c).sum() / (m | c).sum()
        if v == "front" and iou > worst[0]:
            worst = (iou, f"front vs {n}")
        if iou > worst_all[0]:
            worst_all = (iou, f"{v} vs {n}")
# the familiar cutouts are front views, so the pass/fail comparison is front against front; the worst over all views is printed for information
ok = worst[0] <= 0.5
rows.append(f"highest front silhouette IoU against any familiar front: {worst[0]:.2f} ({worst[1]}; limit 0.5) {'ok' if ok else 'TOO SIMILAR'}; worst over all views {worst_all[0]:.2f} ({worst_all[1]}, information only)")
bad += not ok
vv = list(views)
dmin = min(1 - (views[a] & views[b]).sum() / (views[a] | views[b]).sum() for i, a in enumerate(vv) for b in vv[i + 1:])
ok = dmin > 0.1
rows.append(f"views differ from each other (smallest 1-IoU {dmin:.2f}) {'ok' if ok else 'CHECK'}")
bad += not ok
for k in ("size", "length_over_height"):
    rows.append(f"{k}: {st.get(k)}")
print("\n".join(rows))
print(f"enemy model {name}: problems {bad}")
sys.exit(1 if bad else 0)
