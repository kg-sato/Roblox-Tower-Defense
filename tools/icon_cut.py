"""Cut the AnnoMotion fantasy RPG icon pack (CC0) into one PNG per icon with alpha (T31).
  Hunyuan3D/.venv/Scripts/python.exe -I tools/icon_cut.py
Reads VFX/third_party/fantasy_icons/am_free_rpg_icons.psd (the composite already has a transparent background),
finds each icon as a connected blob of alpha, names it from the PSD layer whose box covers it, pads it square with a
transparent margin, resizes to 256 px and writes UI Kit/art/icons_fantasy/<name>.png plus a contact sheet."""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "VFX/third_party/fantasy_icons/am_free_rpg_icons.psd"
OUT = ROOT / "UI Kit/art/icons_fantasy"
SIZE = 256

im = Image.open(SRC)
rgba = np.asarray(im.convert("RGBA"))
alpha = (rgba[..., 3] > 8).astype(np.uint8)
# join the small detached bits of one icon (sparkles, drops) before labelling
joined = cv2.dilate(alpha, np.ones((25, 25), np.uint8))
n, labels, stats, _ = cv2.connectedComponentsWithStats(joined)
boxes = [stats[i] for i in range(1, n) if stats[i][cv2.CC_STAT_AREA] > 2000]

named = []
for layer in im.layers:
    name, bbox = layer[0], layer[2]
    if name and not name.startswith("<") and not name.startswith("</") and bbox:
        named.append((name, bbox))


def name_for(x, y, w, h):
    cx, cy = x + w / 2, y + h / 2
    best, area = None, 0
    for name, (x0, y0, x1, y1) in named:
        if x0 <= cx <= x1 and y0 <= cy <= y1 and (x1 - x0) * (y1 - y0) > area:
            best, area = name, (x1 - x0) * (y1 - y0)
    return best


OUT.mkdir(parents=True, exist_ok=True)
boxes.sort(key=lambda s: (round(s[1] / 400), s[0]))  # rows, then left to right
written, unnamed = [], 0
for k, s in enumerate(boxes):
    x, y, w, h = int(s[0]), int(s[1]), int(s[2]), int(s[3])
    crop = rgba[y:y + h, x:x + w].copy()
    crop[..., 3] = crop[..., 3] * alpha[y:y + h, x:x + w]  # keep only real alpha, not the dilation
    side = int(max(w, h) * 1.12)
    canvas = np.zeros((side, side, 4), np.uint8)
    oy, ox = (side - h) // 2, (side - w) // 2
    canvas[oy:oy + h, ox:ox + w] = crop
    name = name_for(x, y, w, h)
    if not name:
        unnamed += 1
        name = f"icon_{k + 1:02d}"
    slug = "fantasy_" + name.lower().replace(" ", "_")
    Image.fromarray(canvas, "RGBA").resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"{slug}.png", optimize=True)
    written.append(slug)

cols = 8
sheet = Image.new("RGB", (cols * 128, ((len(written) + cols - 1) // cols) * 128), (18, 16, 28))
for i, slug in enumerate(written):
    tile = Image.open(OUT / f"{slug}.png").resize((120, 120))
    bg = Image.new("RGBA", (120, 120), (18, 16, 28, 255))
    bg.alpha_composite(tile)
    sheet.paste(bg.convert("RGB"), ((i % cols) * 128 + 4, (i // cols) * 128 + 4))
sheet.save(ROOT / "Overnight/captures/T31_fantasy_icons.jpg", quality=85)
print(len(written), "icons written,", unnamed, "without a layer name, names unique:", len(set(written)) == len(written))
