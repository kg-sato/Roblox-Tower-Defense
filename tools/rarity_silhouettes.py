"""Rarity silhouette kit (T099): rarity changes the OUTLINE, not only the colour. Drawn by code on each familiar's textured front still
(Roblox Dev/Assets/3D/Familiars/textured/<Name>_tex_front.png, backdrop keyed out). The kit only adds shapes behind the figure, so the base silhouette is a subset of every variant:
  Common    : the base figure only (no kit).
  Rare      : + a halo ring behind the head (one attached outline feature, reaches above the head).
  Epic      : Rare + two detached floating shards at chest height (2 more separate pieces, the outline widens).
  Legendary : Epic + a fan of 5 spikes behind the head and 4 orbiting shards (at least 4 more pieces, about double or triple the base width).
Writes Roblox Dev/Assets/Characters/Rarity/<Name>_rarity.png (colour row over silhouette row), _rarity_sheet.png (12 colour rows), _silhouette_sheet.png and _rarity_report.txt.
Checks per familiar: base subset of each variant, floating pieces (40 pixels or more, touching none of the figure): Common 0, Rare at most 1, Epic at least Rare + 2, Legendary at least Epic + 4, IoU against the base falls with each rarity (Rare at most 0.93, Epic at most 0.80, Legendary at most 0.55),
bounding-box width ratio rises. Run with the Hunyuan3D venv. Exit 1 on any failure."""
import math, pathlib, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Rarity"
C = 560
FIG = 230
KIT = {"Rare": (77, 143, 214), "Epic": (155, 93, 229), "Legendary": (242, 182, 50)}
NAMES = ["Common", "Rare", "Epic", "Legendary"]


def figure(name):
    im = fc.key_out(Image.open(fc.TEX / f"{name}_tex_front.png").convert("RGBA"))
    im = im.crop(im.getbbox())
    s = FIG / max(im.size)
    im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    canvas = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    x0, y0 = (C - im.width) // 2, C - im.height - 60
    canvas.paste(im, (x0, y0), im)
    return canvas, (x0, y0, x0 + im.width, y0 + im.height)


def kit_layers(box):
    """Return {rarity: L mask of kit shapes added at that rarity only}."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    cx = (x0 + x1) / 2
    hy = y0 + 0.22 * h
    layers = {}
    m = Image.new("L", (C, C), 0); d = ImageDraw.Draw(m)
    r = 0.34 * w + 22
    d.ellipse([cx - r, hy - r * 1.05, cx + r, hy + r * 1.05], outline=255, width=11)
    layers["Rare"] = m
    m = Image.new("L", (C, C), 0); d = ImageDraw.Draw(m)
    for sx in (-1, 1):
        px, py, s = cx + sx * (0.5 * w + 58), y0 + 0.5 * h, 26
        d.polygon([(px, py - 1.6 * s), (px + s, py), (px, py + 1.6 * s), (px - s, py)], fill=255)
    layers["Epic"] = m
    m = Image.new("L", (C, C), 0); d = ImageDraw.Draw(m)
    for a in (-72, -36, 0, 36, 72):
        t = math.radians(a)
        L = 0.62 * w + 120
        tip = (cx + math.sin(t) * L, hy - math.cos(t) * L * 1.0)
        b1 = (cx + math.cos(t) * 17, hy + math.sin(t) * 17)
        b2 = (cx - math.cos(t) * 17, hy - math.sin(t) * 17)
        d.polygon([tip, b1, b2], fill=255)
    for sx, fy, off in ((-1, 0.3, 40), (1, 0.3, 40), (-1, 0.85, 0), (1, 0.85, 0)):
        px = cx + sx * min(0.5 * w + 150 + off, C / 2 - 30)
        py = y0 + fy * h
        d.polygon([(px, py - 15), (px + 11, py), (px, py + 15), (px - 11, py)], fill=255)
    layers["Legendary"] = m
    return layers


def mask_of(img):
    return np.array(img.split()[3]) > 40


def pieces(mask):
    """Connected pieces of 40 pixels or more (specks from the backdrop key are ignored)."""
    lab, n = ndimage.label(mask, structure=np.ones((3, 3)))
    return int(sum(1 for i in range(1, n + 1) if (lab == i).sum() >= 40))


def detached(mask, base):
    """Kit pieces (40 pixels or more) that touch none of the figure's own pixels: the floating shards."""
    lab, n = ndimage.label(mask, structure=np.ones((3, 3)))
    return int(sum(1 for i in range(1, n + 1) if (lab == i).sum() >= 40 and not (base & (lab == i)).any()))


def bbox_w(mask):
    xs = np.where(mask.any(axis=0))[0]
    return xs.max() - xs.min() + 1


def build(name):
    fig, box = figure(name)
    layers = kit_layers(box)
    base_mask = mask_of(fig)
    variants, masks, colour = {}, {}, {}
    acc = Image.new("L", (C, C), 0)
    for r in NAMES:
        if r != "Common":
            acc = Image.fromarray(np.maximum(np.array(acc), np.array(layers[r])))
        kit_mask = acc.copy()
        # kit behind the figure: kit colour comes from the highest rarity present, plus a lighter inner tone
        img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
        if r != "Common":
            col = Image.new("RGBA", (C, C), KIT[r] + (255,))
            img.paste(col, (0, 0), kit_mask)
        img.alpha_composite(fig)
        colour[r] = img
        masks[r] = mask_of(img)
    return colour, masks, base_mask


def silhouette_img(mask):
    a = Image.new("RGB", (C, C), (240, 240, 240))
    a.paste(Image.new("RGB", (C, C), (15, 15, 20)), (0, 0), Image.fromarray((mask * 255).astype("uint8")))
    return a


def tile(img):
    bg = Image.new("RGBA", (C, C), (28, 26, 38, 255))
    bg.alpha_composite(img)
    return bg.convert("RGB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows, bad, colour_rows, sil_rows = [], 0, [], []
    for p in sorted(fc.LORE.glob("*.md")):
        name = p.stem
        colour, masks, base = build(name)
        iou = {r: (masks[r] & masks["Common"]).sum() / (masks[r] | masks["Common"]).sum() for r in NAMES}
        pc = {r: detached(masks[r], base) for r in NAMES}
        wr = {r: bbox_w(masks[r]) / bbox_w(masks["Common"]) for r in NAMES}
        subset = all((base & ~masks[r]).sum() == 0 for r in NAMES)
        ok = (subset and pc["Common"] == 0 and pc["Rare"] <= 1 and pc["Epic"] >= pc["Rare"] + 2 and pc["Legendary"] >= pc["Epic"] + 4
              and iou["Rare"] <= 0.93 and iou["Epic"] <= 0.80 and iou["Legendary"] <= 0.55
              and iou["Rare"] > iou["Epic"] > iou["Legendary"] and wr["Rare"] <= wr["Epic"] < wr["Legendary"])
        bad += not ok
        rows.append(f"{name:16} IoU vs base R {iou['Rare']:.2f} E {iou['Epic']:.2f} L {iou['Legendary']:.2f} | floating shards {pc['Common']}/{pc['Rare']}/{pc['Epic']}/{pc['Legendary']} | width x {wr['Rare']:.2f}/{wr['Epic']:.2f}/{wr['Legendary']:.2f} | subset {subset} {'ok' if ok else 'CHECK'}")
        crow = Image.new("RGB", (4 * C, C))
        srow = Image.new("RGB", (4 * C, C))
        for i, r in enumerate(NAMES):
            crow.paste(tile(colour[r]), (i * C, 0))
            srow.paste(silhouette_img(masks[r]), (i * C, 0))
        both = Image.new("RGB", (4 * C, 2 * C)); both.paste(crow, (0, 0)); both.paste(srow, (0, C))
        both.save(OUT / f"{name}_rarity.png")
        colour_rows.append(crow); sil_rows.append(srow)
    for fname, rws in (("_rarity_sheet.png", colour_rows), ("_silhouette_sheet.png", sil_rows)):
        sheet = Image.new("RGB", (4 * 210, 12 * 210))
        for i, rw in enumerate(rws):
            sheet.paste(rw.resize((4 * 210, 210), Image.LANCZOS), (0, i * 210))
        sheet.save(OUT / fname)
    rep = "\n".join(rows) + f"\nfamiliars: {len(rows)} problems: {bad}\n"
    (OUT / "_rarity_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad or len(rows) != 12 else 0)


main()
