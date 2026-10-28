"""Pixel half of the effect quality gate: per recipe window of a screen recording, peak luminance and hot area.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/fx_gate_frames.py <clip.mp4> <first_start_s> <gap_s> <name1,name2,...>
first_start_s: when the first recipe starts in the clip (pass "auto" to take the first frame that differs from the
opening frames). Each recipe window is gap_s long. Luminance is Rec. 709 on 0..1; the baseline is the median of the
opening frames. Reports per recipe: peak_lum (99.5th percentile of the brightest frame), hot_area_pct (share of pixels
that are > 0.9 and were not hot in the baseline, at the worst frame), max_mean_jump (largest frame-to-frame change of the
mean luminance, a flash indicator)."""
import json, sys
import cv2, numpy as np

clip, first, gap, names = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4].split(",")
cap = cv2.VideoCapture(clip)
fps = cap.get(cv2.CAP_PROP_FPS) or 20.0
lums = []
while True:
    ok, fr = cap.read()
    if not ok:
        break
    small = cv2.resize(fr, (480, int(480 * fr.shape[0] / fr.shape[1])))
    b, g, r = [c.astype(np.float32) / 255.0 for c in cv2.split(small)]
    lums.append(0.2126 * r + 0.7152 * g + 0.0722 * b)
base = np.median(np.stack(lums[:5]), 0)
if first == "auto":
    diffs = [float(np.abs(L - base).mean()) for L in lums]
    start = next((i for i, d in enumerate(diffs) if d > 0.004), 0) / fps
else:
    start = float(first)
out = []
for k, name in enumerate(names):
    a, b = int((start + k * gap) * fps), int((start + (k + 1) * gap) * fps)
    win = lums[a:min(b, len(lums))]
    if not win:
        out.append({"recipe": name, "error": "window outside the clip"})
        continue
    peak = max(float(np.percentile(L, 99.5)) for L in win)
    hot = max(float(((L > 0.9) & (base <= 0.9)).mean() * 100) for L in win)
    means = [float(L.mean()) for L in win]
    jump = max((abs(means[i + 1] - means[i]) for i in range(len(means) - 1)), default=0.0)
    out.append({"recipe": name, "peak_lum": round(peak, 3), "hot_area_pct": round(hot, 2), "max_mean_jump": round(jump, 4)})
print(json.dumps({"fps": round(fps, 1), "first_start_s": round(start, 2), "rows": out}, indent=1))
