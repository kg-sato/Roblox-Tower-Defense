"""Catalogue a folder of Roblox flipbook sheets (<name>-roblox-<g>x<g>.png) into a JSON the game can read.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_catalog.py VFX/third_party/particlefx VFX/flipbooks/particlefx_catalog.json
Per sheet: grid, frame px, how many frames are non-empty, hit frame, looping or one-shot (first vs last frame), edge alpha
(a faint square haze if above 0), Lifetime from particlefx_lifetimes.json, and the ParticleEmitter settings to use."""
import hashlib, json, re, sys
from pathlib import Path
import numpy as np
from PIL import Image

src, out = Path(sys.argv[1]), Path(sys.argv[2])
life = json.loads((out.parent / "particlefx_lifetimes.json").read_text(encoding="utf-8"))
items, seen = {}, {}
for p in sorted(src.glob("*.png")):
    m = re.match(r"(.+?)-roblox-(\d)x(\d)(?:\((\d)\))?\.png$", p.name)
    if not m:
        continue
    name, g, variant = m[1], int(m[2]), m[4]
    im = np.asarray(Image.open(p).convert("RGBA")).astype(np.float32) / 255
    f = im.shape[0] // g
    A = [im[(i // g) * f:(i // g + 1) * f, (i % g) * f:(i % g + 1) * f, 3] for i in range(g * g)]
    E = np.array([a.sum() for a in A])
    nonblank = int((E > 0.001 * f * f).sum())
    H = np.array([(a > 0.9).sum() for a in A], np.float32)
    edge = max(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()) for a in A)
    step = float(np.mean([np.abs(A[i] - A[i + 1]).mean() for i in range(len(A) - 1)])) + 1e-9
    seam = float(np.abs(A[0] - A[-1]).mean()) / step
    rgb = im[..., :3][im[..., 3] > 0.5]
    key = name + (f"_v{variant}" if variant else "")
    items[key] = {
        "file": p.name, "sha256_16": hashlib.sha256(p.read_bytes()).hexdigest()[:16], "grid": g, "frame_px": f,
        "frames_nonblank": nonblank, "hit_frame": int(np.argmax(H > 0.5 * H.max())) if H.max() else 0,
        "peak_coverage_pct": round(float((A[int(E.argmax())] > 0.1).mean() * 100), 1),
        "ends_clean": bool(E[-1] < 0.03 * E.max()), "loop_seam_vs_step": round(seam, 2),
        "kind": "loop" if seam < 1.8 and E[-1] > 0.1 * E.max() else "one_shot",
        "edge_alpha_max": round(float(edge), 3), "mean_rgb": [int(x) for x in (rgb.mean(0) * 255)] if len(rgb) else None,
        "lifetime": life.get(name),
        "emitter": {"Texture": "rbxassetid://<upload id>", "FlipbookLayout": f"Grid{g}x{g}", "FlipbookMode": "OneShot",
                    "Lifetime": life.get(name), "Rate": 0, "LightInfluence": 0, "LockedToPart": True},
    }
dups = {}
for k, v in items.items():
    dups.setdefault(v["sha256_16"], []).append(k)
out.write_text(json.dumps({"count": len(items), "identical_files": [v for v in dups.values() if len(v) > 1], "effects": items}, indent=1), encoding="utf-8")
bad = [k for k, v in items.items() if v["edge_alpha_max"] > 0.01 or v["frames_nonblank"] < v["grid"] ** 2 * 0.5]
print(len(items), "sheets;", "identical:", [v for v in dups.values() if len(v) > 1], "\nflag (edge haze or mostly empty):", bad)
print({k: (v["kind"], v["lifetime"], v["hit_frame"]) for k, v in list(items.items())[:44]})
