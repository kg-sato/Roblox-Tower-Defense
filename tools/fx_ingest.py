"""Turn the CC0 Unity Labs flipbook zips in VFX/third_party/unity_labs/ into Roblox-ready sheets in VFX/flipbooks/.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_ingest.py [--frame 128] [--levels 8]
Reads the .tga straight from each zip (nothing from the zip is run or extracted), takes alpha from luminance, picks
64 frames (8x8; neighbouring source frames are blended so steps stay even), keeps a transparent margin in every cell, applies the
violet-gold-white gradient map with a posterise step, and writes <name>_<g>x<g>.png plus a white _mono sheet.
Loops (fireballs, flames, smoke, cloud) get a crossfade so the last frame runs into the first; their names end in _loop
so `fx_sheet.py verify-all` checks the seam. Source: https://unity.com/ (Unity Labs free VFX image sequences, CC0)."""
import io, re, sys, zipfile
from pathlib import Path
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fx_sheet import RAMP, color  # noqa: E402  same gradient map as our own sheets

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "VFX" / "third_party" / "unity_labs"
OUT = ROOT / "VFX" / "flipbooks"
LOOPS = ("FireBall", "Flame", "CandleSmoke", "WispySmoke", "Cloud")
URL = "https://unity3d.com/files/labs/downloads/vfx/assets01/"


def frames_of(img: Image.Image, cols: int, rows: int):
    a = np.asarray(img.convert("RGBA")).astype(np.float32) / 255.0
    H, W = a.shape[0], a.shape[1]
    w = W // cols  # cells may not be whole pixels (CandleSmoke: 1024 / 20 = 51.2), so cut at rounded edges, same width
    h = H // rows
    out = []
    for r in range(rows):
        for c in range(cols):
            x0, y0 = round(c * W / cols), round(r * H / rows)
            cell = a[y0:y0 + h, x0:x0 + w]
            lum = cell[..., 0] * 0.299 + cell[..., 1] * 0.587 + cell[..., 2] * 0.114
            alpha = lum * cell[..., 3]  # alpha from luminance (times the source alpha when there is one)
            out.append((lum, alpha))
    return out


def crossfade_loop(seq, overlap):
    """Return M = N - overlap frames where frame M-1 runs straight into frame 0 (blend of the tail into the head)."""
    n = len(seq)
    m = n - overlap
    out = []
    for j in range(m):
        if j < overlap:
            w = j / overlap
            out.append(tuple((1 - w) * seq[j + m][k] + w * seq[j][k] for k in range(2)))
        else:
            out.append(seq[j])
    return out


def to_cell(lum, alpha, frame):
    """Square, resized to `frame` px, content inside 7/8 of the cell, edges forced fully transparent."""
    h, w = lum.shape
    s = max(h, w)
    pad = lambda x: np.pad(x, (((s - h) // 2, s - h - (s - h) // 2), ((s - w) // 2, s - w - (s - w) // 2)))
    inner = int(frame * 7 / 8)
    rs = lambda x: np.asarray(Image.fromarray(pad(x)).resize((inner, inner), Image.LANCZOS), np.float32)
    off = (frame - inner) // 2
    L, A = np.zeros((frame, frame), np.float32), np.zeros((frame, frame), np.float32)
    L[off:off + inner, off:off + inner] = np.clip(rs(lum), 0, 1)
    A[off:off + inner, off:off + inner] = np.clip(rs(alpha), 0, 1)
    ax = (np.arange(frame) + 0.5) / frame * 2 - 1
    X, Y = np.meshgrid(ax, ax)
    edge = np.clip((0.97 - np.maximum(np.abs(X), np.abs(Y))) / 0.12, 0, 1)
    return L, A * edge


def ingest(zpath: Path, frame: int, levels: int):
    with zipfile.ZipFile(zpath) as z:
        tga = [n for n in z.namelist() if n.lower().endswith(".tga") and "temperature" not in n.lower()]
        if not tga:
            return None
        name = tga[0]
        m = re.search(r"(\w+?)_(\d+)x(\d+)\.tga$", name, re.I)
        base, cols, rows = m.group(1), int(m.group(2)), int(m.group(3))
        img = Image.open(io.BytesIO(z.read(name)))
        img.load()
    seq = frames_of(img, cols, rows)
    loop = base.startswith(LOOPS)
    if loop:
        seq = crossfade_loop(seq, max(2, len(seq) // 4))
    else:
        # one-shot: start at the brightest frame (the hit) and let 4 charge-up frames lead into it
        energy = [float(f[1].sum()) for f in seq]
        seq = seq[int(np.argmax(energy)):]
    n = len(seq)
    g = 8
    total = g * g
    lead = 0 if loop else 4

    def sample(f):
        """Blend neighbouring source frames so every output step is the same size (no duplicated frames)."""
        a = int(np.floor(f))
        w = f - a
        b = (a + 1) % n if loop else min(a + 1, n - 1)
        a = a % n if loop else min(a, n - 1)
        return tuple((1 - w) * seq[a][k] + w * seq[b][k] for k in range(2))

    frames = []
    for i in range(total):
        if i < lead:
            L, A = seq[0]
            frames.append((L, A * 0.55 * (i + 1) / (lead + 1)))
            continue
        j = i - lead
        L, A = sample(j * n / (total - lead) if loop else j * (n - 1) / (total - lead - 1))
        if not loop:
            A = A * (1 - np.clip((j / (total - lead - 1) - 0.75) / 0.25, 0, 1) ** 1.5)  # end clean
        frames.append((L, A))
    sheet = np.zeros((g * frame, g * frame, 4), np.float32)
    mono = np.zeros_like(sheet)
    peak = max(float(f[1].max()) for f in frames) or 1.0
    # contrast stretch over the visible pixels so bright fireballs keep their inner detail instead of mapping to flat white
    vis = np.concatenate([f[0][f[1] > 0.15 * peak] for f in frames] or [np.zeros(1)])
    lo, hi = (np.percentile(vis, 5), np.percentile(vis, 99.5)) if vis.size > 100 else (0.0, 1.0)
    for k, (Ls, As) in enumerate(frames):
        L, A = to_cell(Ls, As, frame)
        A = np.clip(A / peak, 0, 1)
        I = np.clip((L - lo) / max(hi - lo, 1e-3), 0, 1) ** 1.3 * 0.92
        Iq = np.round(I * (levels - 1)) / (levels - 1)  # posterise, then gradient map
        y, x = divmod(k, g)
        sl = (slice(y * frame, (y + 1) * frame), slice(x * frame, (x + 1) * frame))
        sheet[sl] = np.dstack([color(Iq, RAMP), A])
        mono[sl] = np.dstack([np.ones((frame, frame, 3), np.float32), A])
    stem = "ul_" + base.lower() + ("_loop" if loop else "")
    OUT.mkdir(parents=True, exist_ok=True)
    for arr, suffix in ((sheet, ""), (mono, "_mono")):
        Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT / f"{stem}_{g}x{g}{suffix}.png", optimize=True)
    return stem, g, cols, rows, n, loop


if __name__ == "__main__":
    a = sys.argv[1:]
    opt = lambda k, d: type(d)(a[a.index(k) + 1]) if k in a else d
    for zp in sorted(SRC.glob("*/*-flipbooks.zip")):
        r = ingest(zp, opt("--frame", 128), opt("--levels", 8))
        if r:
            print(f"{zp.name}: {r[0]}_{r[1]}x{r[1]}.png from {r[2]}x{r[3]} ({r[4]} frames used{', loop' if r[5] else ''})")
