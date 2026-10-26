"""Checks the generated character portraits against the roster data, so variants can be ranked without anyone looking.

    python VFX/verify_roster_art.py            ranks every UI Kit/art/comfy_out/char_<id>_s<seed>.png

Per image: (1) subject mask = pixels that differ from the corner background colour; (2) coverage = share of the frame the subject
fills (want 10 to 55%); (3) margin = the subject must not touch the edge (at least 2% free on every side); (4) hue match =
angular distance between the subject's dominant hue and the roster's main or accent colour (want under 35 degrees; roster
colours are parsed from VFX/Roster.luau); (5) a score that combines them. A person (or the model reading the image) still picks
among the top variants: this only removes clear misses. It cannot judge cuteness, style consistency or anatomy.
"""
import colorsys
import glob
import math
import os
import re

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "UI Kit", "art", "comfy_out")
src = open(os.path.join(HERE, "Roster.luau"), encoding="utf-8").read()
ROSTER = {}
for m in re.finditer(r'id = "(\w+)".*?color = Color3\.fromRGB\((\d+), (\d+), (\d+)\), accent = Color3\.fromRGB\((\d+), (\d+), (\d+)\)', src):
    ROSTER[m.group(1)] = (tuple(int(m.group(i)) for i in (2, 3, 4)), tuple(int(m.group(i)) for i in (5, 6, 7)))


def hue(rgb):
    return colorsys.rgb_to_hsv(*(v / 255 for v in rgb))[0] * 360


def hdist(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def analyze(path, pid):
    im = Image.open(path).convert("RGB")
    im.thumbnail((256, 256))
    w, h = im.size
    px = im.load()
    bg = px[2, 2]
    mask = [[sum((px[x, y][i] - bg[i]) ** 2 for i in range(3)) > 40 ** 2 for x in range(w)] for y in range(h)]
    n = sum(sum(r) for r in mask)
    cov = n / (w * h)
    xs = [x for y in range(h) for x in range(w) if mask[y][x]]
    ys = [y for y in range(h) for x in range(w) if mask[y][x]]
    margin = min(min(xs), w - 1 - max(xs), min(ys), h - 1 - max(ys)) / w if xs else 0
    bins = [0.0] * 36
    for y in range(h):
        for x in range(w):
            if mask[y][x]:
                r, g, b = px[x, y]
                hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                if s > 0.3 and v > 0.3:
                    bins[int(hh * 36) % 36] += s * v
    peak = max(range(36), key=lambda i: bins[i])
    dom = peak * 10 + 5
    main, acc = ROSTER[pid]
    dm, da = hdist(dom, hue(main)), hdist(dom, hue(acc))
    # neutral main colours (cream, silver) have no useful hue: only hue-check characters whose main colour is saturated
    sat = colorsys.rgb_to_hsv(*(v / 255 for v in main))[1]
    best = min(dm, da) if sat > 0.35 else 0
    score = max(0.0, 100 - best * 1.2) - (0 if 0.10 <= cov <= 0.55 else 25) - (0 if margin >= 0.02 else 30)
    return {"cov": cov, "margin": margin, "dom": dom, "hue_gap": best, "score": score}


if __name__ == "__main__":
    for pid in ROSTER:
        files = sorted(glob.glob(os.path.join(OUT, "char_%s_s*.png" % pid)))
        if not files:
            print("%-8s no images yet" % pid)
            continue
        rows = [(analyze(f, pid), os.path.basename(f)) for f in files]
        rows.sort(key=lambda r: -r[0]["score"])
        for r, name in rows:
            flag = "ok " if r["score"] >= 60 else "LOW"
            print("%-8s %-22s cover %4.0f%%  margin %4.1f%%  hue gap %3.0f deg  score %5.1f  %s" % (pid, name, r["cov"] * 100, r["margin"] * 100, r["hue_gap"], r["score"], flag))
