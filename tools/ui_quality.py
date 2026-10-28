"""UI quality metrics for the abstract-HUD work (2026-10-28; user: "make everything abstract, no UI that looks similar").
Measures what the user objected to: stock-looking boxes/pills and controls that look alike.

    python -I tools/ui_quality.py <hud_on.png> <hud_off.png> <controls.json> [out_dir]

hud_on / hud_off: the same viewport captured with the HUD visible and hidden (Play mode, same camera).
controls.json: {"Name": [x, y, w, h], ...} in capture pixels (from the Luau probe in the Abstract UI note).
Per control it extracts the HUD's own pixels (difference mask) inside its rect and reports:
  boxy      1 if the drawn silhouette is an axis-aligned rectangle or pill (approxPolyDP to 4 points, or a convex hull
            that fills >= 92% of its bounding box with straight sides) - the "stock button" look
  fill      share of the bounding box the silhouette fills
  verts     corner count of the simplified outline (circles ~ many, triangles 3, rectangles 4)
Across controls:
  lookalike pairs: (shape distance (Hu moments) < 0.03 OR appearance correlation of the size-normalised drawing > 0.7
            OR outline IoU > 0.85) AND dominant (median) colour within 30 (Lab) AND size ratio within 1.6x - two controls a player would read as the same kind
  distinct  1 - (lookalike pairs / possible pairs)
Writes masks.png (each control's silhouette) to out_dir when given.
"""
import itertools
import json
import os
import sys
import cv2
import numpy as np


def main():
    on = cv2.imread(sys.argv[1]).astype(np.int16)
    off = cv2.imread(sys.argv[2]).astype(np.int16)
    ctr = json.load(open(sys.argv[3], encoding="utf-8"))
    out = sys.argv[4] if len(sys.argv) > 4 else None
    diff = np.abs(on - off).max(2)
    mask = (diff > 28).astype(np.uint8) * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    lab = cv2.cvtColor(on.astype(np.uint8), cv2.COLOR_BGR2LAB).astype(np.float32)
    rows, info = [], {}
    tiles = []
    for name, (x, y, w, h) in ctr.items():
        x, y, w, h = int(x), int(y), int(w), int(h)
        x0, y0 = max(0, x), max(0, y)
        m = mask[y0:y + h, x0:x + w]
        if m.size == 0 or m.sum() == 0:
            continue
        cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        c = max(cnts, key=cv2.contourArea)
        area = cv2.contourArea(c)
        if area < 30:
            continue
        hull = cv2.convexHull(c)
        bx, by, bw, bh = cv2.boundingRect(c)
        fill = area / max(bw * bh, 1)
        approx = cv2.approxPolyDP(hull, 0.03 * cv2.arcLength(hull, True), True)
        verts = len(approx)
        hull_fill = cv2.contourArea(hull) / max(bw * bh, 1)
        boxy = int((verts == 4 and hull_fill > 0.85) or (hull_fill >= 0.92 and min(bw, bh) > 8))
        col = lab[y0:y + h, x0:x + w][m > 0].mean(0)
        g = cv2.cvtColor(on[y0:y + h, x0:x + w].astype(np.uint8), cv2.COLOR_BGR2GRAY).astype(np.float32)
        cb = c - [0, 0]
        gx, gy_, gw, gh = bx, by, bw, bh
        patch = (g * (m > 0))[gy_:gy_ + gh, gx:gx + gw]
        app = cv2.resize(patch, (48, 48), interpolation=cv2.INTER_AREA)
        app = (app - app.mean()) / (app.std() + 1e-6)
        sil = np.zeros((bh, bw), np.uint8)
        cv2.drawContours(sil, [c - [bx, by]], -1, 1, -1)
        sil = cv2.resize(sil, (48, 48), interpolation=cv2.INTER_NEAREST).astype(bool)
        col = np.median(lab[y0:y + h, x0:x + w][m > 0], 0)  # dominant colour, robust to icons and labels
        info[name] = dict(c=c, col=col, size=float(np.sqrt(area)), fill=fill, verts=verts, boxy=boxy, app=app, sil=sil)
        rows.append((name, boxy, fill, verts, int(area)))
        t = cv2.resize(m, (90, 90 * max(m.shape[0], 1) // max(m.shape[1], 1) or 1))
        tiles.append((name, cv2.resize(m, (90, 90))))
    print("%-16s %5s %5s %5s %7s" % ("control", "boxy", "fill", "verts", "area"))
    for r in rows:
        print("%-16s %5d %5.2f %5d %7d" % r)
    names = list(info)
    pairs = []
    for a, b in itertools.combinations(names, 2):
        A, B = info[a], info[b]
        d = cv2.matchShapes(A["c"], B["c"], cv2.CONTOURS_MATCH_I1, 0)
        cd = float(np.linalg.norm(A["col"] - B["col"]))
        sr = max(A["size"], B["size"]) / max(min(A["size"], B["size"]), 1e-6)
        corr = float((A['app'] * B['app']).mean())  # appearance: same drawing, any size
        iou = float((A['sil'] & B['sil']).sum() / max((A['sil'] | B['sil']).sum(), 1))  # same outline, any size
        if (d < 0.03 or corr > 0.7 or iou > 0.85) and cd < 30 and sr < 1.6:
            pairs.append((a, b, d, cd, corr))
    n = len(names); possible = n * (n - 1) // 2
    print("\nboxy controls: %d of %d" % (sum(r[1] for r in rows), len(rows)))
    print("lookalike pairs: %d of %d  -> distinct %.2f" % (len(pairs), possible, 1 - len(pairs) / max(possible, 1)))
    for a, b, d, cd, corr in pairs:
        print("  %s ~ %s  (shape %.3f, colour %.0f, appearance corr %.2f)" % (a, b, d, cd, corr))
    if out:
        os.makedirs(out, exist_ok=True)
        cv2.imwrite(os.path.join(out, "hud_mask.png"), mask)
        if tiles:
            sheet = np.hstack([cv2.copyMakeBorder(t, 4, 18, 4, 4, cv2.BORDER_CONSTANT, value=60) for _, t in tiles])
            cv2.imwrite(os.path.join(out, "masks.png"), sheet)


if __name__ == "__main__":
    main()
