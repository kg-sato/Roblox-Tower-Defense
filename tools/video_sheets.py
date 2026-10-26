"""Contact sheets + sharpness curve for reference videos. Run with the Hunyuan3D venv python in isolated mode:
   Hunyuan3D/.venv/Scripts/python.exe -I tools/video_sheets.py <video> <out_dir> <interval_seconds> [start] [end]
Writes <out_dir>/<name>_sheet_N.jpg (16 frames per sheet, labelled with time) and prints a sharpness table
(variance of the Laplacian: high = sharp, low = blurry or empty) sampled every 0.2 s."""
import sys, os, cv2
from PIL import Image, ImageDraw
video, out, interval = sys.argv[1], sys.argv[2], float(sys.argv[3])
start = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0
cap = cv2.VideoCapture(video)
fps = cap.get(cv2.CAP_PROP_FPS)
dur = cap.get(cv2.CAP_PROP_FRAME_COUNT) / fps
end = float(sys.argv[5]) if len(sys.argv) > 5 else dur
name = os.path.splitext(os.path.basename(video))[0].strip().replace(" ", "_")
os.makedirs(out, exist_ok=True)
def grab(t):
    cap.set(cv2.CAP_PROP_POS_FRAMES, int(t * fps))
    ok, fr = cap.read()
    return fr if ok else None
times, t = [], start
while t <= end + 1e-6:
    times.append(round(t, 2)); t += interval
cells = []
for t in times:
    fr = grab(t)
    if fr is None: continue
    im = Image.fromarray(cv2.cvtColor(cv2.resize(fr, (480, 270)), cv2.COLOR_BGR2RGB))
    d = ImageDraw.Draw(im); d.rectangle((0, 0, 70, 18), fill=(0, 0, 0)); d.text((4, 3), f"{t:.2f}s", fill=(255, 255, 0))
    cells.append(im)
per = 16
for i in range(0, len(cells), per):
    sheet = Image.new("RGB", (1920, 270 * ((len(cells[i:i+per]) + 3) // 4)))
    for j, im in enumerate(cells[i:i+per]):
        sheet.paste(im, ((j % 4) * 480, (j // 4) * 270))
    p = os.path.join(out, f"{name}_sheet_{i // per + 1}.jpg"); sheet.save(p, quality=82); print("wrote", p)
print("sharpness (Laplacian variance, every 0.2s):")
row = []
t = start
while t <= end:
    fr = grab(t)
    if fr is None: break
    g = cv2.cvtColor(cv2.resize(fr, (480, 270)), cv2.COLOR_BGR2GRAY)
    row.append(f"{t:.1f}:{cv2.Laplacian(g, cv2.CV_64F).var():.0f}"); t += 0.2
print(" ".join(row))
