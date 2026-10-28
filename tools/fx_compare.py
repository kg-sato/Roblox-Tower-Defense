"""Record the Studio viewport and measure a side-by-side effect comparison (left half = reference, right half = ours).
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_compare.py record <out_dir> <seconds> [fps=30] [x0,y0,x1,y1]
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_compare.py measure <out_dir> [bg_threshold=40]
record: grabs the Studio window (must be visible, not minimised; in Edit mode keep the mouse over the viewport or
  Studio may stop redrawing), crops to the box of pixels that move (both effects) plus 60 px, writes
  frames.mp4 and a contact sheet. measure: per frame and per half: lit-pixel share of the half (coverage), mean
  luminance of lit pixels, mean hue and saturation, bounding box size; then a table of min/mean/max per half,
  the per-frame curves (curves.csv) and a side-by-side sheet. Stage tip: put the effects on a black backdrop so lit pixels are only the effect. Local only, nothing uploaded."""
import sys, subprocess, pathlib, csv
import cv2, numpy as np

ROOT = pathlib.Path(__file__).parent
FRONT = "--front" in sys.argv  # Edit mode only; Play mode redraws in the background


def record(out, seconds, fps, crop=None):
    out.mkdir(parents=True, exist_ok=True)
    raw = out / "raw.mp4"
    subprocess.run([sys.executable, "-I", str(ROOT / "record_window.py"), str(raw), str(seconds), str(fps), "Roblox Studio"] + (["--front"] if FRONT else []), check=True)
    v = cv2.VideoCapture(str(raw)); frames = []
    while True:
        ok, f = v.read()
        if not ok: break
        frames.append(f)
    if crop:
        x0, y0, x1, y1 = crop
    else:  # crop to the moving pixels (both effects) plus padding; opening removes UI flicker specks
        var = np.std(np.stack([cv2.cvtColor(f, cv2.COLOR_BGR2GRAY) for f in frames[::2]]).astype(np.float32), axis=0)
        m = cv2.morphologyEx((var > 20).astype(np.uint8), cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
        ys, xs = np.where(m > 0)
        pad = 60
        x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad, var.shape[1] - 1)
        y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad, var.shape[0] - 1)
    real_fps = v.get(cv2.CAP_PROP_FPS) or fps
    w = cv2.VideoWriter(str(out / "frames.mp4"), cv2.VideoWriter_fourcc(*"mp4v"), real_fps, (int(x1 - x0) // 2 * 2, int(y1 - y0) // 2 * 2))
    for f in frames:
        w.write(np.ascontiguousarray(f[y0:y0 + (y1 - y0) // 2 * 2, x0:x0 + (x1 - x0) // 2 * 2]))
    w.release()
    print(f"viewport crop x{x0}-{x1} y{y0}-{y1}, {len(frames)} frames at {real_fps:.1f} fps")


def stats(half, thr):
    g = cv2.cvtColor(half, cv2.COLOR_BGR2GRAY)
    lit = g > thr
    cov = lit.mean()
    if not lit.any():
        return [cov, 0, 0, 0, 0, 0]
    hsv = cv2.cvtColor(half, cv2.COLOR_BGR2HSV)
    h = hsv[..., 0][lit].astype(np.float32) * 2 * np.pi / 180
    hue = (np.degrees(np.arctan2(np.sin(h).mean(), np.cos(h).mean())) + 360) % 360
    ys, xs = np.where(lit)
    return [cov, g[lit].mean(), hue, hsv[..., 1][lit].mean(), (xs.max() - xs.min()) / g.shape[1], (ys.max() - ys.min()) / g.shape[0]]


def measure(out, thr):
    v = cv2.VideoCapture(str(out / "frames.mp4")); fps = v.get(cv2.CAP_PROP_FPS); rows, frames = [], []
    while True:
        ok, f = v.read()
        if not ok: break
        frames.append(f); m = f.shape[1] // 2
        rows.append(stats(f[:, :m], thr) + stats(f[:, m:], thr))
    a = np.array(rows)
    names = ["coverage", "lit_luma", "hue_deg", "saturation", "bbox_w", "bbox_h"]
    with open(out / "curves.csv", "w", newline="") as fh:
        wr = csv.writer(fh); wr.writerow(["t"] + [f"ref_{n}" for n in names] + [f"ours_{n}" for n in names])
        for i, r in enumerate(rows): wr.writerow([round(i / fps, 3)] + [round(x, 4) for x in r])
    print(f"{len(rows)} frames, {fps:.1f} fps, threshold {thr}")
    print(f"{'metric':12} {'ref mean':>9} {'ours mean':>9} {'ratio':>6}   {'ref max':>8} {'ours max':>8}")
    for j, n in enumerate(names):
        r, o = a[:, j].mean(), a[:, 6 + j].mean()
        print(f"{n:12} {r:9.3f} {o:9.3f} {o / r if r else 0:6.2f}   {a[:, j].max():8.3f} {a[:, 6 + j].max():8.3f}")
    picks = np.linspace(0, len(frames) - 1, 8).astype(int)
    th = [cv2.resize(frames[i], (480, int(480 * frames[i].shape[0] / frames[i].shape[1]))) for i in picks]
    for i, t in zip(picks, th): cv2.putText(t, f"t={i / fps:.2f}s", (6, 18), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
    cv2.imwrite(str(out / "sheet.jpg"), np.vstack([np.hstack(th[k:k + 2]) for k in range(0, 8, 2)]))


if __name__ == "__main__":
    cmd, out = sys.argv[1], pathlib.Path(sys.argv[2])
    if cmd == "record":
        crop = [int(x) for x in sys.argv[5].split(",")] if len(sys.argv) > 5 else None  # x0,y0,x1,y1 window pixels
        record(out, float(sys.argv[3]), float(sys.argv[4]) if len(sys.argv) > 4 else 30, crop)
    else:
        measure(out, float(sys.argv[3]) if len(sys.argv) > 3 else 40)
