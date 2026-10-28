"""Paint single particle textures (white on transparent, PNG) for the shapes most Roblox effects are built from,
and score them against a reference texture crop.
  python -I tools/fx_tex.py make <shape> <out.png> [size=512] [seed=1]
  python -I tools/fx_tex.py all <out_dir> [size=512]                 (every shape, plus contact.png)
  python -I tools/fx_tex.py score <ours.png> <ref_crop.png>          (ref crop = screenshot of the texture on a flat bg)
Shapes: lightning_ring, bolts_4x4, dot, dot_4x4, wisps, disc, ray_burst, swirl, crescent, glow, spark4, streak, ring, shard, plus, dot_corner.
4x4 shapes are flipbook sheets (Roblox needs exactly 1024x1024 for flipbooks, so they ignore `size`).
Score = alpha-mask IoU and the correlation of the two radial profiles and angular profiles (1.0 = same)."""
import sys, pathlib
import numpy as np
from PIL import Image

TAU = 2 * np.pi


def field(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    X, Y = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
    return X, Y, np.hypot(X, Y), np.arctan2(Y, X)


def noise1(seed, k=64, decay=1.2):  # smooth periodic 1D noise over the angle; lower decay = jaggier
    r = np.random.default_rng(seed)
    c = r.normal(size=k) / (np.arange(k) + 1) ** decay
    ph = r.uniform(0, TAU, k)
    return lambda a: sum(c[i] * np.sin((i + 1) * a + ph[i]) for i in range(k))


def g(d, w):
    return np.exp(-(d / w) ** 2)


def lightning_ring(n, seed):
    X, Y, R, A = field(n)
    j = noise1(seed, 64, 0.7)(A) * 0.05  # v2: thinner, more jagged, small halo (v1 halo read 1.6x too big in Hollow Purple)
    d = np.abs(R - (0.80 + j))
    return np.clip(g(d, 0.016) + 0.3 * g(d, 0.05), 0, 1)


def bolt(n, seed, length=0.5):
    X, Y, R, A = field(n)
    rng = np.random.default_rng(seed)
    p = rng.uniform(-0.4, 0.4, 2); ang = rng.uniform(0, TAU)
    pts = [p]
    for _ in range(7):
        ang += rng.normal(0, 0.9)
        p = p + np.array([np.cos(ang), np.sin(ang)]) * length / 7
        pts.append(p)
    out = np.zeros_like(R)
    for a, b in zip(pts, pts[1:]):
        ab = b - a; t = np.clip(((X - a[0]) * ab[0] + (Y - a[1]) * ab[1]) / (ab @ ab), 0, 1)
        d = np.hypot(X - a[0] - t * ab[0], Y - a[1] - t * ab[1])
        out = np.maximum(out, g(d, 0.02) + 0.35 * g(d, 0.07))
    return np.clip(out, 0, 1)


def sheet(frames):
    c = frames[0].shape[0]
    s = np.zeros((4 * c, 4 * c), np.float32)
    for i, f in enumerate(frames):
        s[(i // 4) * c:(i // 4 + 1) * c, (i % 4) * c:(i % 4 + 1) * c] = f
    return s


def bolts_4x4(n, seed):  # v2: three thicker bolts per frame (v1 read 0.3x the reference coverage)
    return sheet([np.maximum.reduce([bolt(256, seed * 1000 + i * 3 + j, 0.7) for j in range(3)]) * (1 - i / 20) for i in range(16)])


def dot_4x4(n, seed):
    out = []
    for i in range(16):
        t = i / 15
        X, Y, R, A = field(256)
        out.append(np.clip(g(R, 0.15) * 1.4, 0, 1) if i == 0 else np.zeros_like(R))  # v2: frame 1 only, like the reference
    return sheet(out)


def wisps(n, seed):  # soft smoke petals around the centre with thin filaments toward it
    X, Y, R, A = field(n)
    rng = np.random.default_rng(seed); out = np.zeros_like(R)
    for a0 in rng.uniform(0, TAU, 6):
        da = np.angle(np.exp(1j * (A - a0 - 1.2 * R)))
        out += 0.45 * g(da, 0.45) * g(R - rng.uniform(0.45, 0.65), 0.22) + 0.35 * g(da, 0.06) * g(R - 0.2, 0.15)
    return np.clip(out, 0, 0.8) * 0.2  # v2: faint, the reference smoke barely shows at Transparency 0.93


def dot(n, seed):
    X, Y, R, A = field(n)
    return np.clip(g(R, 0.07) * 1.3 + 0.15 * g(R, 0.15), 0, 1)


def disc(n, seed):
    X, Y, R, A = field(n)
    return np.clip((0.9 - R) / 0.02, 0, 1)


def ray_burst(n, seed):
    X, Y, R, A = field(n)
    rng = np.random.default_rng(seed); rays = np.zeros_like(R)
    for a0, w, L in zip(rng.uniform(0, TAU, 70), rng.uniform(0.03, 0.09, 70), rng.uniform(0.55, 0.9, 70)):
        da = np.angle(np.exp(1j * (A - a0)))
        rays += g(da, w) * np.clip((L - R) / 0.35, 0, 1)
    ring = g(R - 0.5, 0.2)
    return np.clip((0.55 * ring + 0.35 * rays) * np.clip((R - 0.25) / 0.2, 0, 1), 0, 0.9) * 0.3  # v2: faint like the reference


def swirl(n, seed):
    X, Y, R, A = field(n)
    s = np.sin(3 * (A + 3.0 * R) + noise1(seed, 8)(A) * 0.8)
    arcs = g(R - 0.82, 0.04) * (np.sin(2 * A + 1) > 0.2) + 0.5 * g(R - 0.68, 0.03) * (np.sin(3 * A) > 0.3)
    return np.clip(0.75 * g(1 - s, 0.7) * g(R - 0.35, 0.3) + 0.8 * arcs, 0, 0.9)


def crescent(n, seed):
    X, Y, R, A = field(n)
    thick = 0.03 * np.clip(np.sin(A) + 0.2, 0, 1.2) ** 1.5  # thickest at the bottom (image y grows down)
    return np.clip(g(R - 0.9, 0.004 + thick) * np.clip((np.sin(A) + 0.25) / 0.1, 0, 1), 0, 1)


def glow(n, seed):
    X, Y, R, A = field(n)
    return np.clip(g(R, 0.45) * (1 - R) * 1.2, 0, 1)


def spark4(n, seed):
    X, Y, R, A = field(n)
    return np.clip(g(X, 0.03) * g(Y, 0.6) + g(Y, 0.03) * g(X, 0.6) + g(R, 0.12), 0, 1)


def streak(n, seed):
    X, Y, R, A = field(n)
    return np.clip(g(Y, 0.05) * g(X, 0.55), 0, 1)


def ring(n, seed):
    X, Y, R, A = field(n)
    return np.clip(g(R - 0.8, 0.04) + 0.3 * g(R - 0.8, 0.12), 0, 1)


def shard(n, seed):  # thin vertical lens (healing shards, rain streaks)
    X, Y, R, A = field(n)
    w = 0.12 * np.clip(1 - Y ** 2, 0, 1) ** 0.8  # v2: 0.07 read 0.6x the reference coverage
    return np.clip(np.clip((w - np.abs(X)) / 0.02, 0, 1) * np.clip((0.95 - np.abs(Y)) / 0.1, 0, 1), 0, 1)


def plus(n, seed):  # rounded plus sign, arms 0.36 wide
    X, Y, R, A = field(n)
    def box(hx, hy, r=0.08):
        q = np.hypot(np.maximum(np.abs(X) - hx + r, 0), np.maximum(np.abs(Y) - hy + r, 0)) - r
        return np.clip(-q / 0.01, 0, 1)
    return np.maximum(box(0.23, 0.98), box(0.98, 0.23))


def dot_corner(n, seed):  # small dot in the top-left 1/8 of the image (reference "Specs" textures are drawn this way)
    X, Y, R, A = field(n)
    return np.clip(g(np.hypot(X + 0.84, Y + 0.84), 0.06) * 1.3, 0, 1)


SHAPES = {k: v for k, v in globals().items() if k in "lightning_ring bolts_4x4 dot dot_4x4 wisps disc ray_burst swirl crescent glow spark4 streak ring shard plus dot_corner".split()}


def save(a, path):
    a = np.clip(a, 0, 1)
    rgba = np.dstack([np.full_like(a, 255)] * 3 + [a * 255]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(path)


def alpha_of(path):
    im = Image.open(path)
    if im.mode == "RGBA" and np.asarray(im)[..., 3].min() < 250:
        a = np.asarray(im)[..., 3].astype(np.float32) / 255
    else:  # screenshot on a flat background: alpha ~ brightness above the background level
        l = np.asarray(im.convert("L")).astype(np.float32)
        bg = np.median(np.concatenate([l[0], l[-1], l[:, 0], l[:, -1]]))
        a = np.clip((l - bg) / max(255 - bg, 1), 0, 1)
    return a


def profiles(a):
    n = a.shape[0]; X, Y, R, A = field(n)
    rb = np.clip((R * 32).astype(int), 0, 31); ab = ((A + np.pi) / TAU * 36).astype(int) % 36
    rad = np.bincount(rb.ravel(), a.ravel(), 32) / np.maximum(np.bincount(rb.ravel(), minlength=32), 1)
    ang = np.bincount(ab.ravel(), a.ravel(), 36) / np.maximum(np.bincount(ab.ravel(), minlength=36), 1)
    return rad, ang


def corr(u, v):
    if u.std() < 1e-6 or v.std() < 1e-6:
        return 1.0 if abs(u.mean() - v.mean()) < 0.05 else 0.0
    return float(np.corrcoef(u, v)[0, 1])


def score(ours, ref):
    a, b = alpha_of(ours), alpha_of(ref)
    n = 256
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((n, n))).astype(np.float32) / 255
    b = np.asarray(Image.fromarray((b * 255).astype(np.uint8)).resize((n, n))).astype(np.float32) / 255
    ma, mb = a > 0.25, b > 0.25
    iou = (ma & mb).sum() / max((ma | mb).sum(), 1)
    (ra, aa), (rb, ab) = profiles(a), profiles(b)
    return {"iou": round(float(iou), 3), "radial_corr": round(corr(ra, rb), 3), "angular_corr": round(corr(aa, ab), 3),
            "mean_alpha": [round(float(a.mean()), 3), round(float(b.mean()), 3)]}


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "make":
        name, out = sys.argv[2], sys.argv[3]
        size = 1024 if name.endswith("4x4") else int(sys.argv[4]) if len(sys.argv) > 4 else 512
        save(SHAPES[name](size, int(sys.argv[5]) if len(sys.argv) > 5 else 1), out)
    elif cmd == "all":
        d = pathlib.Path(sys.argv[2]); d.mkdir(parents=True, exist_ok=True)
        size = int(sys.argv[3]) if len(sys.argv) > 3 else 512
        tiles = []
        for k, f in SHAPES.items():
            a = f(1024 if k.endswith("4x4") else size, 1); save(a, d / f"{k}.png")
            tiles.append(np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((192, 192))))
        rows = [np.hstack(tiles[i:i + 6] + [np.zeros((192, 192), np.uint8)] * (6 - len(tiles[i:i + 6]))) for i in range(0, len(tiles), 6)]
        Image.fromarray(np.vstack(rows)).save(d / "contact.png")
        print("wrote", len(tiles), "shapes to", d)
    elif cmd == "score":
        print(score(sys.argv[2], sys.argv[3]))
