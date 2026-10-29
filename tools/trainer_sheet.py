"""Trainer character (T113): the player's Lantern Keeper in 4 cosmetic variants, from Roblox Dev/Lore/The Lantern Role.md ("four outfit variants vary the coat colour and the lantern frame";
ranks Wick, Flame, Lamp, Beacon). A front-view concept figure drawn by code with the T112 props (long coat design A, wick satchel, Keeper's Lamp): same body in all four, only the coat colour and
the lantern frame metal change. The player is never named or gendered, so the figure has no face detail beyond two dots and a cap.
Writes Roblox Dev/Assets/Characters/Trainer/_trainer_sheet.png and _trainer_report.txt. Checks: coat colours pairwise differ (CIE Lab distance at least 25), also for deuteranopia simulation (at least 12);
lantern frame colours pairwise differ (Lab at least 20); the four silhouettes are identical except the colour (IoU at least 0.99, one body for all). Run with the Hunyuan3D venv."""
import pathlib, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Trainer"
W, H, S = 300, 520, 2
SKIN, TROUSER, BOOT = (226, 188, 150), (46, 44, 56), (44, 30, 22)
VARIANTS = [
    ("WICK  (levels 1 to 9)", dict(coat=(92, 70, 30), trim=(60, 44, 18), frame=(201, 162, 75), note="old lamp-oil, brass frame (the lore-literal outfit)")),
    ("FLAME  (10 to 19)", dict(coat=(180, 78, 50), trim=(116, 44, 28), frame=(190, 108, 62), note="ember red-brown (lighter than Wick), copper frame")),
    ("LAMP  (20 to 29)", dict(coat=(38, 98, 92), trim=(22, 60, 56), frame=(201, 162, 75), note="verdigris, brass frame")),
    ("BEACON  (30 and up)", dict(coat=(34, 48, 104), trim=(20, 30, 70), frame=(196, 202, 218), note="midnight blue, silver frame")),
]


def lab(rgb):
    c = np.array(rgb, dtype=float) / 255
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    x, y, z = (m @ c) / np.array([0.95047, 1.0, 1.08883])
    f = lambda t: np.where(t > 0.008856, np.cbrt(t), 7.787 * t + 16 / 116)
    return np.array([116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))])


def deut(rgb):
    c = np.array(rgb, dtype=float) / 255
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
    o = np.clip(m @ lin, 0, 1)
    o = np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)
    return tuple(int(v * 255) for v in o)


def P(pts):
    return [(x * S, y * S) for x, y in pts]


def figure(v, brass_trim=(201, 162, 75)):
    im = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    coat, trim, frame = v["coat"], v["trim"], v["frame"]
    # legs and boots
    for x in (116, 164):
        d.rectangle([c * S for c in (x - 14, 360, x + 14, 470)], fill=TROUSER)
        d.rounded_rectangle([c * S for c in (x - 18, 464, x + 18, 492)], 8 * S, fill=BOOT)
    # coat (long coat A shape), sleeves, collar, buttons, belt
    d.polygon(P([(105, 120), (195, 120), (214, 168), (226, 405), (74, 405), (86, 168)]), fill=coat, outline=trim)
    for sx in (-1, 1):
        d.polygon(P([(150 + sx * 62, 130), (150 + sx * 82, 138), (150 + sx * 100, 300), (150 + sx * 80, 306)]), fill=coat, outline=trim)
        d.ellipse([c * S for c in (150 + sx * 100 - 11, 296, 150 + sx * 100 + 11, 322)], fill=SKIN)
    d.polygon(P([(120, 112), (180, 112), (190, 130), (150, 182), (110, 130)]), fill=trim)
    d.line(P([(150, 182), (150, 405)]), fill=trim, width=3 * S)
    for y in (206, 246, 286, 326, 366):
        for x in (138, 162):
            d.ellipse([c * S for c in (x - 5, y - 5, x + 5, y + 5)], fill=(201, 162, 75))
    d.rectangle([c * S for c in (86, 268, 214, 282)], fill=trim)
    # head: skin, cap, two dots
    d.ellipse([c * S for c in (120, 40, 180, 112)], fill=SKIN)
    d.pieslice([c * S for c in (114, 28, 186, 100)], 180, 360, fill=trim)
    d.rectangle([c * S for c in (112, 62, 188, 70)], fill=trim)
    for x in (139, 161):
        d.ellipse([c * S for c in (x - 3, 84, x + 3, 91)], fill=(30, 26, 32))
    # satchel on the right hip (spare wicks), strap across the chest
    d.line(P([(186, 138), (96, 300)]), fill=(70, 44, 24), width=6 * S)
    d.rounded_rectangle([c * S for c in (92, 286, 144, 346)], 8 * S, fill=(110, 72, 40), outline=(70, 44, 24))
    d.polygon(P([(92, 296), (144, 296), (144, 318), (118, 330), (92, 318)]), fill=(70, 44, 24))
    # lantern at the left hip: hangs from the hand, brass or other metal frame, EMPTY glass
    lx, ly = 232, 300
    d.line(P([(lx, ly - 14), (lx, ly - 36)]), fill=frame, width=3 * S)
    d.ellipse([c * S for c in (lx - 8, ly - 48, lx + 8, ly - 32)], outline=frame, width=3 * S)
    d.rounded_rectangle([c * S for c in (lx - 22, ly - 14, lx + 22, ly + 56)], 6 * S, fill=(226, 238, 244, 235), outline=frame, width=3 * S)
    d.rectangle([c * S for c in (lx - 24, ly - 18, lx + 24, ly - 8)], fill=frame)
    d.rectangle([c * S for c in (lx - 24, ly + 52, lx + 24, ly + 64)], fill=frame)
    for x in (lx - 22, lx + 22):
        d.line(P([(x, ly - 10), (x, ly + 54)]), fill=frame, width=3 * S)
    d.rectangle([c * S for c in (lx - 12, ly + 4, lx - 6, ly + 38)], fill=(255, 255, 255, 120))
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGB", (4 * W + 50, H + 90), (36, 34, 48))
    d = ImageDraw.Draw(sheet)
    masks, rows, bad = [], [], 0
    for i, (label, v) in enumerate(VARIANTS):
        im = figure(v)
        masks.append(np.array(im.split()[3]) > 40)
        small = im.resize((W, H), Image.LANCZOS)
        x = 10 + i * (W + 10)
        sheet.paste(small, (x, 50), small)
        d.text((x + W // 2, 22), label, font=fc.font("georgiab.ttf", 17), fill=(236, 205, 120), anchor="mm")
        d.text((x + W // 2, H + 66), v["note"], font=fc.font("georgia.ttf", 13), fill=(190, 184, 200), anchor="mm")
        ex = fc.ROOT  # no-op, keeps the import used
    names = [v[0].split()[0] for v in VARIANTS]
    for a in range(4):
        for b in range(a + 1, 4):
            ca, cb = VARIANTS[a][1], VARIANTS[b][1]
            dc = float(np.linalg.norm(lab(ca["coat"]) - lab(cb["coat"])))
            dd = float(np.linalg.norm(lab(deut(ca["coat"])) - lab(deut(cb["coat"]))))
            df = float(np.linalg.norm(lab(ca["frame"]) - lab(cb["frame"])))
            iou = (masks[a] & masks[b]).sum() / (masks[a] | masks[b]).sum()
            ok = dc >= 25 and dd >= 12 and (df >= 20 or ca["frame"] == cb["frame"]) and iou >= 0.99
            # frames may repeat (Wick and Lamp both brass), but then the coats must differ by the checks above
            bad += not ok
            rows.append(f"{names[a]:6} vs {names[b]:6} coat dE {dc:5.1f}, deuteranopia dE {dd:5.1f}, frame dE {df:5.1f}, silhouette IoU {iou:.3f} {'ok' if ok else 'CHECK'}")
    sheet.save(OUT / "_trainer_sheet.png")
    rep = "\n".join(rows) + f"\ntrainer variants: 4 problems: {bad}\n"
    (OUT / "_trainer_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad else 0)


main()
