"""Compare two flipbook sheets (same grid) frame by frame, offline. Works on any RGBA sheet (ParticleFX, ours, repacks).
  python -I tools/sheet_compare.py analyze <sheet.png> [grid=8]            per-frame timeline of one sheet
  python -I tools/sheet_compare.py compare <ref.png> <ours.png> [grid=8] [out.png]
Per frame: coverage (share of the cell with alpha > 0.1), alpha-weighted mean colour, luminance, centroid and bbox
(fractions of the cell). compare prints both timelines, per-metric correlation and mean ratio, and writes a strip image
(ref row over ours row, every 4th frame) so the beats can be checked by eye. Local only."""
import sys
import numpy as np
from PIL import Image


def frames(path, g):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255
    c = a.shape[0] // g
    return [a[(i // g) * c:(i // g + 1) * c, (i % g) * c:(i % g + 1) * c] for i in range(g * g)], c


def metrics(f):
    al = f[..., 3]; m = al > 0.1
    if not m.any():
        return dict(cov=0, r=0, g=0, b=0, lum=0, cx=0.5, cy=0.5, w=0, h=0)
    w = al[m][:, None]
    rgb = (f[..., :3][m] * w).sum(0) / w.sum()
    ys, xs = np.where(m); n = al.shape[0]
    return dict(cov=m.mean(), r=rgb[0], g=rgb[1], b=rgb[2], lum=float((0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) * al[m].mean()),
                cx=xs.mean() / n, cy=ys.mean() / n, w=(xs.max() - xs.min()) / n, h=(ys.max() - ys.min()) / n)


KEYS = ["cov", "lum", "r", "g", "b", "cx", "cy", "w", "h"]


def table(ms, label):
    print(label); print("fr " + " ".join(f"{k:>5}" for k in KEYS))
    for i, m in enumerate(ms):
        print(f"{i:2d} " + " ".join(f"{m[k]:5.2f}" for k in KEYS))


def compare(ref, ours, g, out):
    fa, ca = frames(ref, g); fb, cb = frames(ours, g)
    A = [metrics(f) for f in fa]; B = [metrics(f) for f in fb]
    print(f"{'metric':6} {'corr':>6} {'ref mean':>9} {'ours mean':>9} {'ratio':>6}")
    res = {}
    for k in KEYS:
        a = np.array([m[k] for m in A]); b = np.array([m[k] for m in B])
        c = float(np.corrcoef(a, b)[0, 1]) if a.std() > 1e-6 and b.std() > 1e-6 else float("nan")
        res[k] = c
        print(f"{k:6} {c:6.2f} {a.mean():9.3f} {b.mean():9.3f} {b.mean() / a.mean() if a.mean() else 0:6.2f}")
    if out:
        s = 128
        def row(fs):
            tiles = []
            for f in fs[::4]:
                im = Image.fromarray((f * 255).astype(np.uint8), "RGBA").resize((s, s))
                bg = Image.new("RGBA", (s, s), (20, 18, 30, 255)); bg.alpha_composite(im); tiles.append(np.asarray(bg))
            return np.hstack(tiles)
        Image.fromarray(np.vstack([row(fa), row(fb)])).convert("RGB").save(out)
    return res


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "analyze":
        fs, c = frames(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 8)
        table([metrics(f) for f in fs], sys.argv[2])
    else:
        g = int(sys.argv[4]) if len(sys.argv) > 4 else 8
        compare(sys.argv[2], sys.argv[3], g, sys.argv[5] if len(sys.argv) > 5 else None)
