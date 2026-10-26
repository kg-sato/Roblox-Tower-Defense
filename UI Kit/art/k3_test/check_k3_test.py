"""Checks returned art against the rules the ingest step needs: a square image, a flat magenta background that can be
keyed out, the subject filling the frame, and no magenta inside the subject. It cannot judge style, text or shadows;
those are checked by eye.

    python "UI Kit/art/k3_test/check_k3_test.py"                      checks k3_test/inbox
    python "UI Kit/art/k3_test/check_k3_test.py" "UI Kit/art/comfy_out"  checks any folder (baseline)
"""
import os
import sys
from collections import deque

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
# same "magenta family" test as comfy_generate.py and ingest_art.py, so a file that passes here keys out in ingest
BORDER_MIN = 0.95    # share of the outer ring that must be magenta
FILL_MIN, FILL_MAX = 0.60, 1.00   # subject bounding box as a share of the canvas
INTERIOR_MAX = 0.005 # subject pixels that ingest would turn into holes, as a share of the subject's pixels
KEY_LO = 38          # ingest_art.py key_out(lo=38): pixels this close to the border colour become transparent
SIZE = 256           # work at this size; enough for every rule above


def is_magenta(p):
    return p[0] - p[1] > 60 and p[2] - p[1] > 40


def check(path):
    img = Image.open(path).convert("RGB")
    full_w, full_h = img.size
    img.thumbnail((SIZE, SIZE))
    w, h = img.size
    px = img.load()
    mag = [[is_magenta(px[x, y]) for x in range(w)] for y in range(h)]

    ring = max(1, int(w * 0.03))
    ring_px = [(x, y) for y in range(h) for x in range(w) if x < ring or y < ring or x >= w - ring or y >= h - ring]
    border_share = sum(mag[y][x] for x, y in ring_px) / len(ring_px)
    cols = [px[x, y] for x, y in ring_px]
    border_rgb = tuple(sorted(c[i] for c in cols)[len(cols) // 2] for i in range(3))

    # flood fill from the edge over magenta: this is the background the ingest step can key out
    bg = [[False] * w for _ in range(h)]
    queue = deque((x, y) for x, y in ring_px if mag[y][x])
    for x, y in queue:
        bg[y][x] = True
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and mag[ny][nx] and not bg[ny][nx]:
                bg[ny][nx] = True
                queue.append((nx, ny))

    subject = [(x, y) for y in range(h) for x in range(w) if not bg[y][x]]
    problems = []
    if full_w != full_h:
        problems.append("not square (%dx%d)" % (full_w, full_h))
    if border_share < BORDER_MIN:
        problems.append("background not flat magenta (%.0f%% of edge)" % (border_share * 100))
    if not subject:
        problems.append("no subject found")
        fill = 0.0
        interior = 0.0
    else:
        xs = [x for x, _ in subject]
        ys = [y for _, y in subject]
        fill = max(max(xs) - min(xs) + 1, max(ys) - min(ys) + 1) / max(w, h)
        # ingest_art.py keys by colour everywhere (not only at the edge), so any subject pixel this close to the border colour is lost
        interior_px = [(x, y) for y in range(h) for x in range(w)
                       if not bg[y][x] and sum((px[x, y][i] - border_rgb[i]) ** 2 for i in range(3)) ** 0.5 <= KEY_LO]
        interior = len(interior_px) / len(subject)
        if not FILL_MIN <= fill <= FILL_MAX:
            problems.append("subject fills %.0f%% of frame (want %.0f to %.0f%%)" % (fill * 100, FILL_MIN * 100, FILL_MAX * 100))
        if interior > INTERIOR_MAX:
            problems.append("subject has background-coloured pixels (%.1f%%), ingest would leave holes" % (interior * 100))
    return full_w, full_h, border_share, border_rgb, fill, interior, problems


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "inbox")
    if not os.path.isdir(folder):
        print("no folder:", folder)
        return 1
    files = sorted(f for f in os.listdir(folder) if f.lower().endswith(".png"))
    if not files:
        print("no PNG files in", folder)
        return 1
    print("%-30s %-10s %-8s %-16s %-6s %-9s %s" % ("file", "size", "border", "border RGB", "fill", "interior", "verdict"))
    failed = 0
    for name in files:
        try:
            w, h, border, rgb, fill, interior, problems = check(os.path.join(folder, name))
        except OSError as e:
            print("%-30s unreadable: %s" % (name, e))
            failed += 1
            continue
        verdict = "PASS" if not problems else "FAIL: " + "; ".join(problems)
        failed += bool(problems)
        print("%-30s %-10s %-8s %-16s %-6s %-9s %s" % (
            name, "%dx%d" % (w, h), "%.0f%%" % (border * 100), "%s" % (rgb,), "%.0f%%" % (fill * 100),
            "%.2f%%" % (interior * 100), verdict))
    print("\n%d of %d passed the automatic checks. Style, text, shadow and orientation still need a look by eye."
          % (len(files) - failed, len(files)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
