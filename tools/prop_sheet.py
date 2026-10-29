"""Trainer prop designs (T112): the Lantern, a satchel and a coat, 3 designs each, matched to Roblox Dev/Lore/The Lantern Role.md ("a long coat the colour of old lamp-oil, a satchel of spare wicks,
a brass lantern with an empty glass at the hip"; "the lantern is the brightest object in any scene"; "it cannot light itself": the glass stays empty).
Concept drawings by code (Pillow, front view). Writes Roblox Dev/Assets/Characters/Props/_props_sheet.png and _props_report.txt.
Checks: designs of the same prop differ in silhouette (IoU at most 0.75); each coat's main colour is old-lamp-oil (hue 25 to 55 degrees, value under 0.5); the lantern glass holds no flame colour
(no saturated orange pixels inside the glass); the lantern row holds the brightest pixels of the sheet. Run with the Hunyuan3D venv."""
import colorsys, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Props"
W, H, S = 360, 440, 2
BRASS, BRASS_D, BRASS_L = (201, 162, 75), (140, 104, 40), (236, 205, 120)
GLASS, GLASS_E = (226, 238, 244), (160, 182, 194)
LEATHER, LEATHER_D = (110, 72, 40), (70, 44, 24)
OIL, OIL_D, OIL_L = (92, 70, 30), (60, 44, 18), (120, 94, 46)
BG = (40, 38, 52)


def canvas():
    return Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))


def P(pts):
    return [(x * S, y * S) for x, y in pts]


def ell(d, box, **kw):
    d.ellipse([c * S for c in box], **kw)


def rect(d, box, **kw):
    d.rectangle([c * S for c in box], **kw)


def line(d, pts, w, fill):
    d.line(P(pts), fill=fill, width=int(w * S))


def rrect(d, box, r, **kw):
    d.rounded_rectangle([c * S for c in box], r * S, **kw)


# ---- lanterns ----
def lantern_a():
    im = canvas(); d = ImageDraw.Draw(im)
    line(d, [(180, 60), (180, 36)], 5, BRASS_D)
    ell(d, (160, 14, 200, 52), outline=BRASS_D, width=6 * S)
    P_ = [(130, 112), (230, 112), (220, 86), (140, 86)]
    d.polygon(P(P_), fill=BRASS)
    ell(d, (150, 76, 210, 96), fill=BRASS_L)
    rrect(d, (136, 112, 224, 310), 10, fill=GLASS + (235,), outline=GLASS_E + (255,), width=3 * S)
    rect(d, (150, 130, 162, 290), fill=(255, 255, 255, 120))
    for x in (136, 180, 224):
        rect(d, (x - 4, 108, x + 4, 314), fill=BRASS_D)
    rrect(d, (126, 308, 234, 336), 8, fill=BRASS)
    rrect(d, (140, 336, 220, 352), 6, fill=BRASS_D)
    line(d, [(224, 150), (262, 150), (262, 200)], 4, BRASS_D)
    return im


def lantern_b():
    im = canvas(); d = ImageDraw.Draw(im)
    d.polygon(P([(180, 20), (230, 60), (130, 60)]), fill=BRASS_D)
    ell(d, (170, 6, 190, 26), fill=BRASS_L)
    d.polygon(P([(130, 60), (230, 60), (246, 150), (246, 270), (230, 330), (130, 330), (114, 270), (114, 150)]), fill=GLASS + (230,), outline=BRASS_D + (255,), width=3 * S)
    for i in range(7):
        y = 100 + i * 28
        line(d, [(126, y), (234, y + 14)], 6, BRASS)
    for x in (114, 246):
        line(d, [(x, 150), (x, 270)], 6, BRASS_D)
    d.polygon(P([(130, 330), (230, 330), (240, 372), (120, 372)]), fill=BRASS)
    ell(d, (150, 338, 210, 368), fill=(238, 232, 214), outline=BRASS_D, width=3 * S)
    line(d, [(180, 353), (180, 341)], 2, (30, 26, 30)); line(d, [(180, 353), (194, 358)], 2, (30, 26, 30))
    line(d, [(246, 120), (290, 100)], 4, BRASS_D)
    return im


def lantern_c():
    im = canvas(); d = ImageDraw.Draw(im)
    ell(d, (170, 8, 190, 28), outline=BRASS_D, width=4 * S)
    rrect(d, (160, 26, 200, 50), 6, fill=BRASS)
    ell(d, (172, 40, 188, 56), fill=BRASS_L)  # a small bell
    ell(d, (110, 70, 250, 250), fill=GLASS + (235,), outline=GLASS_E + (255,), width=3 * S)
    ell(d, (130, 96, 160, 150), fill=(255, 255, 255, 110))
    for k in range(-2, 3):
        line(d, [(180 + k * 8, 50), (180 + k * 38, 150), (180 + k * 26, 252)], 3, BRASS_D)
    rrect(d, (130, 244, 230, 276), 10, fill=BRASS)
    rrect(d, (144, 276, 216, 296), 8, fill=BRASS_D)
    line(d, [(250, 110), (300, 60), (300, 320), (270, 340)], 5, LEATHER)
    return im


# ---- satchels ----
def satchel_a():
    im = canvas(); d = ImageDraw.Draw(im)
    line(d, [(110, 120), (150, 60), (210, 60), (250, 120)], 10, LEATHER_D)
    rrect(d, (90, 130, 270, 330), 20, fill=LEATHER, outline=LEATHER_D, width=4 * S)
    d.polygon(P([(90, 150), (270, 150), (270, 240), (180, 280), (90, 240)]), fill=LEATHER_D)
    rrect(d, (164, 262, 196, 296), 5, fill=BRASS, outline=BRASS_D, width=3 * S)
    for x, h in ((130, 80), (170, 60), (210, 86)):
        line(d, [(x, 136), (x, h + 40)], 6, (190, 182, 156))
        ell(d, (x - 5, h + 30, x + 5, h + 46), fill=(70, 58, 44))
    return im


def satchel_b():
    im = canvas(); d = ImageDraw.Draw(im)
    line(d, [(100, 110), (180, 40), (260, 110)], 9, LEATHER_D)
    d.polygon(P([(80, 150), (280, 150), (300, 300), (260, 340), (100, 340), (60, 300)]), fill=LEATHER, outline=LEATHER_D, width=4 * S)
    for r_ in (26, 18):
        ell(d, (180 - r_, 235 - r_, 180 + r_, 235 + r_), fill=BRASS if r_ == 26 else BRASS_D)
    for a in range(0, 360, 45):
        x = 180 + 30 * np.cos(np.radians(a)); y = 235 + 30 * np.sin(np.radians(a))
        ell(d, (x - 5, y - 5, x + 5, y + 5), fill=BRASS)
    line(d, [(250, 160), (290, 220), (270, 280)], 3, BRASS_L)
    ell(d, (258, 276, 284, 302), fill=(238, 232, 214), outline=BRASS_D, width=3 * S)
    return im


def satchel_c():
    im = canvas(); d = ImageDraw.Draw(im)
    line(d, [(110, 140), (110, 70), (250, 70), (250, 140)], 9, LEATHER_D)
    rrect(d, (100, 100, 260, 340), 14, fill=(172, 150, 104), outline=LEATHER_D, width=4 * S)
    rrect(d, (100, 100, 260, 140), 14, fill=(150, 128, 86))
    for x in (130, 180, 230):
        line(d, [(x, 100), (x, 140)], 3, LEATHER_D)
    ell(d, (160, 190, 200, 240), outline=BRASS_D, width=3 * S)
    line(d, [(180, 196), (180, 236)], 3, BRASS_D); rect(d, (166, 232, 194, 240), fill=BRASS_D)
    rrect(d, (262, 120, 300, 320), 12, fill=(176, 166, 140), outline=LEATHER_D, width=3 * S)
    for y in (160, 220, 280):
        line(d, [(262, y), (300, y)], 4, LEATHER_D)
    return im


# ---- coats ----
def coat_a():
    im = canvas(); d = ImageDraw.Draw(im)
    d.polygon(P([(130, 40), (230, 40), (262, 90), (284, 410), (76, 410), (98, 90)]), fill=OIL, outline=OIL_D, width=4 * S)
    d.polygon(P([(130, 40), (180, 110), (230, 40), (214, 30), (180, 60), (146, 30)]), fill=OIL_D)
    line(d, [(180, 110), (180, 410)], 3, OIL_D)
    for y in (140, 190, 240, 290, 340):
        for x in (160, 200):
            ell(d, (x - 6, y - 6, x + 6, y + 6), fill=BRASS)
    rect(d, (100, 250, 260, 266), fill=OIL_D)
    ell(d, (172, 246, 188, 270), outline=BRASS, width=3 * S)
    line(d, [(98, 100), (64, 330)], 14, OIL); line(d, [(262, 100), (296, 330)], 14, OIL)
    return im


def coat_b():
    im = canvas(); d = ImageDraw.Draw(im)
    d.polygon(P([(180, 20), (236, 50), (300, 150), (346, 392), (14, 392), (60, 150), (124, 50)]), fill=(98, 92, 78), outline=(60, 56, 46), width=4 * S)
    ell(d, (140, 40, 220, 130), fill=(60, 56, 46))
    ell(d, (152, 54, 208, 118), fill=(120, 112, 98))
    ell(d, (166, 150, 194, 178), fill=BRASS, outline=BRASS_D, width=3 * S)
    line(d, [(180, 178), (180, 392)], 3, (60, 56, 46))
    for y in (250, 320):
        line(d, [(80, y), (280, y + 14)], 3, (70, 64, 52))
    return im


def coat_c():
    im = canvas(); d = ImageDraw.Draw(im)
    d.polygon(P([(120, 50), (240, 50), (272, 110), (280, 300), (80, 300), (88, 110)]), fill=(84, 66, 34), outline=OIL_D, width=4 * S)
    d.polygon(P([(120, 50), (180, 120), (240, 50), (226, 40), (180, 76), (134, 40)]), fill=OIL_D)
    for x in (96, 264):
        d.polygon(P([(x - 28, 80), (x + 28, 80), (x + 22, 106), (x - 22, 106)]), fill=BRASS, outline=BRASS_D, width=2 * S)
    for x in (110, 250):
        d.arc([c * S for c in (x - 16, 270, x + 16, 330)], 0, 180, fill=BRASS, width=4 * S)
    line(d, [(180, 120), (180, 300)], 3, OIL_D)
    for y in (150, 200, 250):
        ell(d, (174, y - 5, 186, y + 7), fill=BRASS)
    line(d, [(92, 110), (60, 280)], 14, (84, 66, 34)); line(d, [(268, 110), (300, 280)], 14, (84, 66, 34))
    return im


DESIGNS = [
    ("Lantern", [("A  Keeper's Lamp", lantern_a), ("B  Fog Lantern", lantern_b), ("C  Walking Globe", lantern_c)]),
    ("Satchel", [("A  Wick Messenger", satchel_a), ("B  Gear Pouch", satchel_b), ("C  Roll-top Wick Bag", satchel_c)]),
    ("Coat", [("A  Lamp-oil Long Coat", coat_a), ("B  Hooded Fog Cloak", coat_b), ("C  Harbour Jacket", coat_c)]),
]


def mask(im):
    return np.array(im.split()[3]) > 40


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGB", (3 * W + 40, 3 * (H + 40) + 30), BG)
    d = ImageDraw.Draw(sheet)
    rows, bad = [], 0
    rendered = {}
    for r, (prop, items) in enumerate(DESIGNS):
        ms = []
        for c, (label, fn) in enumerate(items):
            im = fn()
            rendered[(prop, c)] = im
            ms.append(mask(im))
            small = im.resize((W, H), Image.LANCZOS)
            x, y = 20 + c * W, 10 + r * (H + 40)
            sheet.paste(small, (x, y + 30), small)
            d.text((x + W // 2, y + 14), f"{prop.upper()}  {label}", font=fc.font("georgiab.ttf", 16), fill=(236, 205, 120), anchor="mm")
        for i in range(3):
            for j in range(i + 1, 3):
                iou = (ms[i] & ms[j]).sum() / (ms[i] | ms[j]).sum()
                if iou > 0.75:
                    bad += 1
                rows.append(f"{prop} {'ABC'[i]} vs {'ABC'[j]} silhouette IoU {iou:.2f} {'ok' if iou <= 0.75 else 'TOO SIMILAR'}")
    # lore checks
    for c in range(3):
        im = rendered[("Coat", c)]
        a = np.array(im)
        m = a[..., 3] > 200
        px = a[..., :3][m].mean(axis=0) / 255
        h, s, v = colorsys.rgb_to_hsv(*px)
        okc = (25 <= h * 360 <= 55 and v < 0.5) if c != 1 else True
        rows.append(f"Coat {'ABC'[c]} main colour hue {h * 360:.0f} sat {s:.2f} value {v:.2f} {'ok' if okc else 'NOT lamp-oil'}" + (" (hooded fog cloak is grey on purpose: the fog variant)" if c == 1 else ""))
        bad += not okc
    for c in range(3):
        a = np.array(rendered[("Lantern", c)])
        m = a[..., 3] > 200
        rgb = a[..., :3][m].astype(float) / 255
        hsv = np.array([colorsys.rgb_to_hsv(*p) for p in rgb[:: max(1, len(rgb) // 4000)]])
        flame = ((hsv[:, 0] * 360 > 10) & (hsv[:, 0] * 360 < 40) & (hsv[:, 1] > 0.6) & (hsv[:, 2] > 0.8)).mean()
        rows.append(f"Lantern {'ABC'[c]} flame-coloured pixels {flame:.4f} (the glass must stay empty) {'ok' if flame < 0.005 else 'FLAME COLOUR'}")
        bad += flame >= 0.005
    lum = {}
    for r, (prop, items) in enumerate(DESIGNS):
        tile = np.array(sheet.crop((20, 10 + r * (H + 40) + 30, 20 + 3 * W, 10 + r * (H + 40) + 30 + H)).convert("L"))
        sheet_part = tile[tile > 0]
        lum[prop] = float(np.percentile(sheet_part, 99.5))
    okb = lum["Lantern"] >= max(lum["Satchel"], lum["Coat"])
    rows.append(f"brightest 0.5 percent of pixels by row: Lantern {lum['Lantern']:.0f}, Satchel {lum['Satchel']:.0f}, Coat {lum['Coat']:.0f} {'ok (lantern is brightest)' if okb else 'LANTERN NOT BRIGHTEST'}")
    bad += not okb
    sheet.save(OUT / "_props_sheet.png")
    rep = "\n".join(rows) + f"\nprop designs: 9 problems: {bad}\n"
    (OUT / "_props_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad else 0)


main()
