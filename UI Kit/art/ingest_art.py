"""Turns raw generated images (Kimi, Blender, anything) into game-ready UI sprites.

    python "UI Kit/art/ingest_art.py"                    process everything in art/inbox
    python "UI Kit/art/ingest_art.py" --size 512         output size (default 256; heroes/backdrops: 512)
    python "UI Kit/art/ingest_art.py" --key FF00FF       force the key colour (default: auto from the corners)
    python "UI Kit/art/ingest_art.py" --keep-bg          do not key out a background (backdrops, banners)

What it does for each inbox file `name.png|jpg|webp`:
  1. If the image already has real transparency it is used as is. Otherwise the solid background colour
     (sampled from the four corners, normally magenta #FF00FF) is keyed out with a soft edge and the edge
     colour is un-mixed from the key (no pink fringe).
  2. Trims to the subject, pads to a square with a small margin, resizes with LANCZOS.
  3. Saves art/out/<name>.png, records it in art/extra_manifest.json, and moves the original to art/processed/.
  4. Prints a report and flags problems: subject touching the edge, mostly empty, background not solid, tiny size.
Then run make_uiart.py and preview_install.py (or `python "UI Kit/art/build_art.py"`, which does all of it).
File naming: `icon_*` icons, `pet_*` pets, `bg_*` backdrops (kept opaque), `art_*` anything else.
"""
import glob
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
import json
import os
import shutil
import sys
import time

from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
INBOX = os.path.join(HERE, "inbox")
OUT = os.path.join(HERE, "out")
PROCESSED = os.path.join(HERE, "processed")
EXTRA = os.path.join(HERE, "extra_manifest.json")
os.makedirs(INBOX, exist_ok=True)
os.makedirs(OUT, exist_ok=True)
os.makedirs(PROCESSED, exist_ok=True)


def arg(flag, default=None, cast=str):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        return cast(sys.argv[i + 1])
    return default


def corner_key(img):
    """Median colour of 4 corner patches, plus how consistent they are (max channel spread)."""
    w, h = img.size
    n = max(4, min(w, h) // 40)
    patches = [img.crop((0, 0, n, n)), img.crop((w - n, 0, w, n)), img.crop((0, h - n, n, h)), img.crop((w - n, h - n, w, h))]
    cols = []
    for p in patches:
        px = list(p.convert("RGB").getdata())
        cols.append(tuple(sorted(c[i] for c in px)[len(px) // 2] for i in range(3)))
    key = tuple(sorted(c[i] for c in cols)[len(cols) // 2] for i in range(3))
    spread = max(max(c[i] for c in cols) - min(c[i] for c in cols) for i in range(3))
    return key, spread


def key_out(img, key, lo=38.0, hi=96.0):
    """Soft chroma key. alpha ramps from 0 (<= lo away from key) to 1 (>= hi away); edge colour un-mixed."""
    rgb = img.convert("RGB")
    px = list(rgb.getdata())
    out = []
    kr, kg, kb = key
    for r, g, b in px:
        d = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
        if d <= lo:
            out.append((0, 0, 0, 0))
        elif d >= hi:
            out.append((r, g, b, 255))
        else:
            a = (d - lo) / (hi - lo)
            # un-mix: pixel = a*fg + (1-a)*key  ->  fg = (pixel - (1-a)*key) / a
            fr = max(0, min(255, int((r - (1 - a) * kr) / a)))
            fg_ = max(0, min(255, int((g - (1 - a) * kg) / a)))
            fb = max(0, min(255, int((b - (1 - a) * kb) / a)))
            out.append((fr, fg_, fb, int(a * 255)))
    res = Image.new("RGBA", rgb.size)
    res.putdata(out)
    return res


def has_real_alpha(img):
    if img.mode != "RGBA":
        return False
    a = img.getchannel("A")
    lo, hi = a.getextrema()
    return lo < 200


def deskew(img):
    """Straightens long thin subjects (sword, rod, pickaxe, flag pole) that the generator drew diagonally.
    Finds the main axis of the opaque pixels; if the shape is clearly elongated and within 50 degrees of vertical
    (or 20 of horizontal) it is rotated onto that axis by the smallest turn. Compact shapes are left alone."""
    import math
    try:
        import numpy as np
    except ImportError:
        return img, None
    a = np.asarray(img.getchannel("A")) > 40
    ys, xs = np.nonzero(a)
    if len(xs) < 200:
        return img, None
    cov = np.cov(np.vstack([xs - xs.mean(), ys - ys.mean()]))
    vals, vecs = np.linalg.eigh(cov)
    if vals[1] / max(vals[0], 1e-6) < 6:  # not clearly elongated
        return img, None
    vx, vy = vecs[:, 1]
    ang = math.degrees(math.atan2(vx, -vy))  # degrees clockwise from straight up
    ang = (ang + 90) % 180 - 90  # axis has no direction: fold into -90..90
    if abs(ang) <= 50:
        turn = ang  # snap to vertical
    elif 90 - abs(ang) <= 20:
        turn = -(90 - abs(ang)) if ang > 0 else (90 - abs(ang))  # snap to horizontal
    else:
        return img, None
    if abs(turn) < 3:
        return img, None
    return img.rotate(turn, resample=Image.BICUBIC, expand=True), turn


def square_pad(img, margin=0.05):
    bbox = img.getchannel("A").point(lambda v: 255 if v > 10 else 0).getbbox()
    if not bbox:
        return img, None
    sub = img.crop(bbox)
    side = int(max(sub.size) * (1 + 2 * margin))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(sub, ((side - sub.width) // 2, (side - sub.height) // 2))
    return canvas, bbox


def main():
    size = arg("--size", 256, int)
    keep_bg = "--keep-bg" in sys.argv
    forced = arg("--key", None)
    files = sorted(f for ext in ("png", "jpg", "jpeg", "webp") for f in glob.glob(os.path.join(INBOX, "*." + ext)))
    if not files:
        print("inbox is empty:", INBOX)
        return
    extra = json.load(open(EXTRA, encoding="utf-8")) if os.path.exists(EXTRA) else {}
    problems = 0
    for f in files:
        stem = os.path.splitext(os.path.basename(f))[0].strip().lower().replace(" ", "_").replace("-", "_")
        if not stem.startswith(("icon_", "pet_", "bg_", "art_")):
            stem = "art_" + stem
        img = Image.open(f)
        img.load()
        notes = []
        if min(img.size) < 256:
            notes.append("small source (%dx%d), will look soft" % img.size)
        opaque_bg = stem.startswith("bg_") or keep_bg
        if opaque_bg:
            res = img.convert("RGBA")
            res = res.resize((size * 2 if size < 512 else size, int(res.height * (size * 2 if size < 512 else size) / res.width)), Image.LANCZOS)
            notes.append("kept opaque")
        else:
            if has_real_alpha(img):
                res = img.convert("RGBA")
                notes.append("used existing transparency")
            else:
                if forced:
                    key = tuple(int(forced[i:i + 2], 16) for i in (0, 2, 4))
                    spread = 0
                else:
                    key, spread = corner_key(img)
                if spread > 40:
                    notes.append("background is not a solid colour (corner spread %d); result may be poor" % spread)
                    problems += 1
                res = key_out(img, key)
                notes.append("keyed out #%02X%02X%02X" % key)
            if "--no-deskew" not in sys.argv:
                res, turned = deskew(res)
                if turned:
                    notes.append("straightened by %.0f degrees" % turned)
            res, bbox = square_pad(res)
            if bbox is None:
                notes.append("NOTHING LEFT after keying (wrong key colour?)")
                problems += 1
                continue
            full = img.size
            if bbox[0] <= 1 or bbox[1] <= 1 or bbox[2] >= full[0] - 1 or bbox[3] >= full[1] - 1:
                notes.append("subject touches the image edge (cropped?)")
                problems += 1
            cover = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]) / (full[0] * full[1])
            if cover < 0.12:
                notes.append("subject is small in the frame (%.0f%% of area)" % (cover * 100))
            # shave a one pixel fringe so no key colour survives at the rim
            a = res.getchannel("A").filter(ImageFilter.MinFilter(3))
            res.putalpha(a)
            res = res.resize((size, size), Image.LANCZOS)
        res.save(os.path.join(OUT, stem + ".png"), optimize=True)
        extra[stem] = {"file": stem + ".png", "w": res.width, "h": res.height}
        stamp = time.strftime("%Y%m%d-%H%M%S")
        shutil.move(f, os.path.join(PROCESSED, stamp + "_" + os.path.basename(f)))
        print("%-22s %4dx%-4d  %s" % (stem, res.width, res.height, "; ".join(notes) if notes else "ok"))
    json.dump(extra, open(EXTRA, "w", encoding="utf-8"), indent=2)
    print("done: %d file(s), %d problem(s). Next: python \"UI Kit/art/build_art.py\"" % (len(files), problems))


if __name__ == "__main__":
    main()
