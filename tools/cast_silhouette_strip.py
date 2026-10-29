"""Greyscale silhouette strip for the whole cast (T087): front and side views of all twelve familiars at 64 px, shown at true size and enlarged.
Usage: python tools/cast_silhouette_strip.py
Reads Roblox Dev/Assets/Characters/Design Sheets/<Name>_silhouette.png (3 panels of 380 px: front, side, back), writes _cast_silhouette_strip.png
and prints pairwise overlap (IoU) for the front and side rows. Pure Pillow."""
import pathlib
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHEETS = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"
CAST = ["Ember", "MothLantern", "BrassHound", "Sentinel", "Frostling", "Gargoyle", "Ward", "Archivist", "Mourner", "MirrorChorister", "StarDrake", "GreyVeilWraith"]
PANEL = 380


def px(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()


def panel(name, idx):
    sil = Image.open(SHEETS / f"{name}_silhouette.png").convert("L")
    return sil.crop((idx * PANEL, 0, (idx + 1) * PANEL, 460)).point(lambda v: 255 if v < 128 else 0)


def fit64(mask):
    """Crop to the figure, scale so the longest side is 64 px (aspect kept), centre on a 64x64 canvas (white figure on black)."""
    box = mask.getbbox()
    c = mask.crop(box)
    k = 64 / max(c.size)
    c = c.resize((max(1, round(c.size[0] * k)), max(1, round(c.size[1] * k))), Image.LANCZOS).point(lambda v: 255 if v > 127 else 0)
    canvas = Image.new("L", (64, 64), 0)
    canvas.paste(c, ((64 - c.size[0]) // 2, (64 - c.size[1]) // 2))
    return canvas


def fit_common_scale(masks):
    """Same scale for every figure (height-true): each figure is scaled by one factor so relative size is preserved, then centred on 64x64.
    The tallest figure is 64 px tall."""
    boxes = [m.getbbox() for m in masks]
    tallest = max(b[3] - b[1] for b in boxes)
    widest = max(b[2] - b[0] for b in boxes)
    k = 64 / max(tallest, widest)
    out = []
    for m, b in zip(masks, boxes):
        c = m.crop(b)
        c = c.resize((max(1, round(c.size[0] * k)), max(1, round(c.size[1] * k))), Image.LANCZOS).point(lambda v: 255 if v > 127 else 0)
        canvas = Image.new("L", (64, 64), 0)
        canvas.paste(c, ((64 - c.size[0]) // 2, 64 - 2 - c.size[1]))  # stand them on a common ground line
        out.append(canvas)
    return out


def iou(a, b):
    A, B = list(px(a)), list(px(b))
    inter = sum(1 for x, y in zip(A, B) if x and y)
    union = sum(1 for x, y in zip(A, B) if x or y)
    return inter / union if union else 0


def font(sz):
    for p in ("C:/Windows/Fonts/arial.ttf",):
        if pathlib.Path(p).exists():
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def main():
    rows = {}
    for label, idx in (("front", 0), ("side", 1)):
        masks = [panel(n, idx) for n in CAST]
        rows[label] = fit_common_scale(masks)
    # layout: for each row: true-size 64 px tiles, then 3x enlarged tiles (nearest neighbour)
    tile, big = 64, 192
    pad = 10
    W = pad + 12 * (big + pad)
    H = pad + 2 * (tile + pad + big + 34 + pad)
    sheet = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    y = pad
    for label in ("front", "side"):
        d.text((pad, y - 2), f"{label.upper()} views, common scale (1 to 12 in the order of the cast list: Ember, MothLantern, BrassHound, Sentinel, Frostling, Gargoyle, Ward, Archivist, Mourner, MirrorChorister, StarDrake, GreyVeilWraith)", fill=(0, 0, 0), font=font(12))
        y += 16
        for i, m in enumerate(rows[label]):
            x = pad + i * (big + pad)
            small = Image.eval(m, lambda v: 255 - v).convert("RGB")  # black figure on white
            sheet.paste(small, (x, y))
            d.text((x + 70, y + 24), f"{i + 1}", fill=(0, 0, 0), font=font(16))
            bigim = small.resize((big, big), Image.NEAREST)
            sheet.paste(bigim, (x, y + tile + 6))
            d.rectangle([x, y + tile + 6, x + big - 1, y + tile + 6 + big - 1], outline=(200, 200, 200))
        y += tile + 6 + big + 18
    sheet.save(SHEETS / "_cast_silhouette_strip.png")
    print("saved", SHEETS / "_cast_silhouette_strip.png", sheet.size)
    for label in ("front", "side"):
        ms = rows[label]
        pairs = []
        for i in range(12):
            for j in range(i + 1, 12):
                pairs.append((iou(ms[i], ms[j]), CAST[i], CAST[j]))
        pairs.sort(reverse=True)
        print(f"{label}: top 6 most similar pairs (IoU, same scale, standing on one ground line)")
        for v, a, b in pairs[:6]:
            print(f"  {v:.2f}  {a} / {b}")
        print(f"{label}: max IoU {pairs[0][0]:.2f}, pairs >= 0.60: {sum(1 for p in pairs if p[0] >= 0.60)}, pairs >= 0.70: {sum(1 for p in pairs if p[0] >= 0.70)}")


if __name__ == "__main__":
    main()
