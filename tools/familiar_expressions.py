"""Facial expression set (T110): 3 expressions for each of the 4 familiars with a drawn face (Ember, Frostling, Brass Hound, Gargoyle).
Concept sheets, painted by code over the textured front still: the original eyes and mouth are covered with the local colour and redrawn as HAPPY (idle), FIERCE (attack) and HURT (taking damage).
Writes Roblox Dev/Assets/Characters/Expressions/<Name>_expressions.png (reference + 3 expressions, zoomed face and full figure), _expressions_sheet.png and _expressions_report.txt.
Checks: every expression differs from the original and from the other two (mean absolute difference of the face crop above 2.0 on a 0 to 255 scale); features stay inside the face crop.
Run with the Hunyuan3D venv. Concept only: in game the faces are baked into the texture, so each expression needs its own colour texture (see Roblox Dev/Design/Expressions.md)."""
import math, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Expressions"
TEX = fc.TEX
K = 6  # zoom of the face crop

# source-pixel coordinates in the 384 px front stills
FACES = {
    "Ember": {"crop": (128, 140, 258, 230), "eyes": [(172, 176), (214, 176)], "r": 9, "mouth": (193, 201), "mw": 22, "mcover": (14, 8), "ink": (24, 18, 26), "eye_fill": None, "cover": 13},
    "Frostling": {"crop": (140, 140, 240, 215), "eyes": [(178, 170), (204, 170)], "r": 7, "mouth": (191, 190), "mw": 13, "mcover": (9, 5), "ink": (22, 22, 30), "eye_fill": None, "cover": 10},
    "BrassHound": {"crop": (128, 70, 252, 150), "eyes": [(172, 98), (212, 98)], "r": 8, "mouth": (191, 137), "mw": 22, "mcover": (11, 4), "ink": (24, 16, 16), "eye_fill": None, "cover": 11},
    "Gargoyle": {"crop": (130, 105, 254, 180), "eyes": [(172, 136), (211, 136)], "r": 8, "mouth": None, "mw": 0, "mcover": (0, 0), "ink": (22, 28, 40), "eye_fill": (176, 210, 228), "cover": 13},
}
EXPR = ["happy", "fierce", "hurt"]


def local_colour(arr, cx, cy, r):
    """Mean colour of a ring around (cx, cy), used to cover the old feature."""
    h, w = arr.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    d = np.hypot(xs - cx, ys - cy)
    ring = (d > r * 1.05) & (d < r * 1.7)
    return tuple(int(v) for v in arr[ring][:, :3].mean(axis=0))


def draw_face(base, spec, expr):
    x0, y0, x1, y1 = spec["crop"]
    crop = base.crop((x0, y0, x1, y1)).convert("RGB")
    arr = np.array(crop)
    big = crop.resize((crop.width * K, crop.height * K), Image.LANCZOS)
    if expr is None:
        return big
    d = ImageDraw.Draw(big, "RGBA")
    ink = spec["ink"]
    r = spec["r"] * K

    def P(p):
        return ((p[0] - x0) * K, (p[1] - y0) * K)

    # cover old eyes and mouth with the local colour, feathered so no patch edge shows
    for e in spec["eyes"]:
        cx, cy = P(e)
        col = local_colour(arr, e[0] - x0, e[1] - y0, spec["cover"] / 1.0)
        mask = Image.new("L", big.size, 0)
        ImageDraw.Draw(mask).ellipse([cx - spec["cover"] * K, cy - spec["cover"] * K, cx + spec["cover"] * K, cy + spec["cover"] * K], fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(spec["cover"] * K * 0.25))
        big.paste(Image.new("RGB", big.size, col), (0, 0), mask)
    if spec["mouth"]:
        mx, my = P(spec["mouth"])
        rx, ry = spec["mcover"]
        col = local_colour(arr, spec["mouth"][0] - x0, spec["mouth"][1] - y0, 9)
        mask = Image.new("L", big.size, 0)
        ImageDraw.Draw(mask).ellipse([mx - rx * K, my - ry * K, mx + rx * K, my + ry * K], fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(ry * K * 0.3))
        big.paste(Image.new("RGB", big.size, col), (0, 0), mask)
    big = big.filter(ImageFilter.GaussianBlur(1.2 * K / 3))
    d = ImageDraw.Draw(big, "RGBA")
    fill = spec["eye_fill"] or ink
    for i, e in enumerate(spec["eyes"]):
        cx, cy = P(e)
        side = -1 if i == 0 else 1  # left eye (image left) leans one way
        if expr == "happy":
            d.arc([cx - r, cy - r * 0.7, cx + r, cy + r * 1.3], 200, 340, fill=ink + (255,), width=int(r * 0.42))
            if spec["eye_fill"]:
                d.arc([cx - r, cy - r * 0.7, cx + r, cy + r * 1.3], 200, 340, fill=spec["eye_fill"] + (255,), width=int(r * 0.2))
        elif expr == "fierce":
            d.ellipse([cx - r * 0.95, cy - r * 0.55, cx + r * 0.95, cy + r * 0.6], fill=fill + (255,), outline=ink + (255,), width=max(1, int(r * 0.12)))
            d.ellipse([cx - r * 0.3 + side * r * 0.1, cy - r * 0.15, cx + r * 0.3 + side * r * 0.1, cy + r * 0.35], fill=ink + (255,))
            d.line([(cx - side * r * 1.3, cy - r * 1.35), (cx + side * r * 1.2, cy - r * 0.45)], fill=ink + (255,), width=int(r * 0.5))
        else:  # hurt
            d.ellipse([cx - r * 1.1, cy - r * 1.1, cx + r * 1.1, cy + r * 1.1], fill=fill + (255,), outline=ink + (255,), width=max(1, int(r * 0.14)))
            d.ellipse([cx - r * 0.55, cy - r * 0.45, cx + r * 0.55, cy + r * 0.65], fill=ink + (255,))
            d.ellipse([cx - r * 0.35, cy - r * 0.45, cx - r * 0.05, cy - r * 0.15], fill=(255, 255, 255, 255))
            d.line([(cx - side * r * 1.3, cy - r * 1.75), (cx + side * r * 1.1, cy - r * 1.0)], fill=ink + (255,), width=int(r * 0.38))
            d.ellipse([cx - r * 0.2 + side * r * 0.4, cy + r * 1.3, cx + r * 0.25 + side * r * 0.4, cy + r * 1.95], fill=(170, 220, 255, 230))
    if spec["mouth"]:
        mx, my = P(spec["mouth"])
        w = spec["mw"] * K
        if expr == "happy":
            d.arc([mx - w / 2, my - w * 0.25, mx + w / 2, my + w * 0.35], 15, 165, fill=ink + (255,), width=int(K * 1.6))
        elif expr == "fierce":
            d.polygon([(mx - w / 2, my), (mx - w / 4, my + w * 0.18), (mx, my), (mx + w / 4, my + w * 0.18), (mx + w / 2, my), (mx + w / 2, my + w * 0.22), (mx - w / 2, my + w * 0.22)], fill=ink + (255,))
            d.polygon([(mx - w * 0.28, my + w * 0.1), (mx - w * 0.18, my + w * 0.28), (mx - w * 0.08, my + w * 0.1)], fill=(250, 250, 245, 255))
        else:
            d.arc([mx - w / 2, my + w * 0.05, mx + w / 2, my + w * 0.6], 200, 340, fill=ink + (255,), width=int(K * 1.6))
    return big


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows, bad, sheet = [], 0, []
    for name, spec in FACES.items():
        base = Image.open(TEX / f"{name}_tex_front.png").convert("RGB")
        faces = {"reference": draw_face(base, spec, None)}
        for e in EXPR:
            faces[e] = draw_face(base, spec, e)
        arrs = {k: np.array(v).astype(float) for k, v in faces.items()}
        diffs = {}
        names_e = list(arrs)
        ok = True
        for i, a in enumerate(names_e):
            for b in names_e[i + 1:]:
                m = float(np.abs(arrs[a] - arrs[b]).mean())
                diffs[(a, b)] = m
                if m < 2.0:
                    ok = False
        bad += not ok
        w, h = faces["reference"].size
        full = Image.new("RGB", (4 * w, h + 330 + 40), (28, 26, 38))
        d = ImageDraw.Draw(full)
        for i, k in enumerate(["reference"] + EXPR):
            full.paste(faces[k], (i * w, 40))
            d.text((i * w + w // 2, 20), k.upper(), font=fc.font("georgiab.ttf", 18), fill=(236, 205, 120), anchor="mm")
            # full figure with the face pasted back at the same scale
            fig = base.copy()
            x0, y0, x1, y1 = spec["crop"]
            fig.paste(faces[k].resize((x1 - x0, y1 - y0), Image.LANCZOS), (x0, y0))
            fig = fig.resize((330, 330), Image.LANCZOS)
            full.paste(fig, (i * w + (w - 330) // 2, h + 40))
        full.save(OUT / f"{name}_expressions.png")
        sheet.append(full.resize((full.width // 2, full.height // 2), Image.LANCZOS))
        rows.append(f"{name:10} min pair diff {min(diffs.values()):5.1f} (reference vs happy {diffs[('reference', 'happy')]:.1f}, fierce {diffs[('reference', 'fierce')]:.1f}, hurt {diffs[('reference', 'hurt')]:.1f}; happy vs fierce {diffs[('happy', 'fierce')]:.1f}, fierce vs hurt {diffs[('fierce', 'hurt')]:.1f}) {'ok' if ok else 'CHECK'}")
    W = max(s.width for s in sheet)
    big = Image.new("RGB", (W, sum(s.height for s in sheet)), (28, 26, 38))
    y = 0
    for s in sheet:
        big.paste(s, (0, y)); y += s.height
    big.save(OUT / "_expressions_sheet.png")
    rep = "\n".join(rows) + f"\nfamiliars: {len(rows)} problems: {bad}\n"
    (OUT / "_expressions_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad else 0)


main()
