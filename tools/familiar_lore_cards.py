"""Familiar lore cards (T097): the collection back of each card with the full bio (120 to 200 words) from Roblox Dev/Lore/Familiars/<Name>.md ("Longer bio").
Reuses the frame, colours and parsing of tools/familiar_cards.py. Writes Roblox Dev/Assets/Characters/Cards/<Name>_lore.png (630 x 880), _lore_sheet.png and _lore_report.txt.
Run with Hunyuan3D\.venv\Scripts\python tools\familiar_lore_cards.py. Drawn by code: a concept layout, not final art."""
import pathlib, re, sys
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

W, H = fc.W, fc.H


def draw_back(f, bio):
    c = f["colour"]
    glow = c if fc.lum(c) > 0.08 else fc.mix(c, (255, 255, 255), 0.55)
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    frame = fc.vgrad((W, H), fc.BRASS[0], fc.BRASS[2])
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], 34, fill=255)
    card.paste(frame, (0, 0), mask)
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([16, 16, W - 17, H - 17], 24, fill=(26, 23, 34), outline=(90, 66, 24), width=3)
    d.rounded_rectangle([24, 24, W - 25, H - 25], 18, outline=(201, 162, 75), width=2)
    for (x, y) in ((30, 30), (W - 31, 30), (30, H - 31), (W - 31, H - 31)):
        d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=(236, 205, 120), outline=(90, 66, 24), width=2)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(140, 104, 40))
    # portrait medallion
    R = 78
    cx, cy = W // 2, 54 + R
    med = Image.new("RGBA", (2 * R, 2 * R), (0, 0, 0, 0))
    bg = fc.vgrad((2 * R, 2 * R), fc.mix((20, 20, 34), glow, 0.25), fc.mix((10, 10, 16), glow, 0.1)).convert("RGBA")
    tex = fc.key_out(Image.open(fc.TEX / f"{f['file']}_tex_three_quarter.png").convert("RGBA"))
    tex = tex.crop(tex.getbbox())
    s = min((2 * R - 24) / tex.width, (2 * R - 24) / tex.height)
    tex = tex.resize((int(tex.width * s), int(tex.height * s)), Image.LANCZOS)
    bg.paste(tex, ((2 * R - tex.width) // 2, (2 * R - tex.height) // 2), tex)
    m = Image.new("L", (2 * R, 2 * R), 0)
    ImageDraw.Draw(m).ellipse([0, 0, 2 * R - 1, 2 * R - 1], fill=255)
    card.paste(bg, (cx - R, cy - R), m)
    d.ellipse([cx - R - 2, cy - R - 2, cx + R + 2, cy + R + 2], outline=(236, 205, 120), width=4)
    d.ellipse([cx - R + 5, cy - R + 5, cx + R - 5, cy + R - 5], outline=(90, 66, 24), width=1)
    # name plate
    plate = [44, 226, W - 44, 292]
    d.rounded_rectangle(plate, 12, fill=c, outline=(236, 205, 120), width=3)
    txt = (255, 255, 255) if fc.contrast((255, 255, 255), c) >= fc.contrast(fc.INK, c) else fc.INK
    nf = fc.font("georgiab.ttf", 36)
    while d.textlength(f["name"].upper(), font=nf) > plate[2] - plate[0] - 40:
        nf = fc.font("georgiab.ttf", nf.size - 2)
    d.text((W // 2, 259), f["name"].upper(), font=nf, fill=txt, anchor="mm")
    d.text((W // 2, 312), f"{f['faction'].upper()}  •  {f['rarity'].upper()}", font=fc.font("georgiab.ttf", 16), fill=(190, 182, 200), anchor="mm")
    d.line([(90, 332), (W // 2 - 14, 332)], fill=(201, 162, 75), width=2)
    d.line([(W // 2 + 14, 332), (W - 90, 332)], fill=(201, 162, 75), width=2)
    fc.gem(d, W // 2, 332, 6, (201, 162, 75), (90, 66, 24))
    # bio, justified-left paragraph
    bf = fc.font("georgia.ttf", 19)
    lines = fc.wrap(d, bio, bf, W - 120)
    y = 352
    for ln in lines:
        d.text((60, y), ln, font=bf, fill=fc.PARCH, anchor="lt")
        y += 27
    bottom = y
    d.text((W // 2, H - 52), f"{f['role'].upper()}  •  {f['home'].upper()}", font=fc.font("georgia.ttf", 16), fill=(160, 150, 130), anchor="mm")
    return card, {"lines": len(lines), "bottom": bottom, "max_line": max(d.textlength(l, font=bf) for l in lines),
                  "plate_contrast": fc.contrast(txt, c), "text_contrast": fc.contrast(fc.PARCH, (26, 23, 34))}


def main():
    cards, rows, bad = [], [], 0
    for p in sorted(fc.LORE.glob("*.md")):
        f = fc.parse(p)
        t = p.read_text(encoding="utf-8")
        bio = re.search(r"## Longer bio[^\n]*\n(.+?)\n\n## ", t, re.S).group(1).strip()
        words = len(bio.split())
        card, m = draw_back(f, bio)
        card.save(fc.OUT / f"{f['file']}_lore.png")
        cards.append(card)
        ok = 120 <= words <= 200 and m["bottom"] <= H - 85 and m["max_line"] <= W - 120 and m["plate_contrast"] >= 4.5 and m["text_contrast"] >= 7
        bad += not ok
        rows.append(f"{f['file']:16} words {words:3d} lines {m['lines']:2d} text_bottom {m['bottom']:4d} plate_contrast {m['plate_contrast']:5.2f} text_contrast {m['text_contrast']:5.2f} {'ok' if ok else 'CHECK'}")
    sheet = Image.new("RGB", (4 * 330, 3 * 460), (40, 40, 52))
    for i, card in enumerate(cards):
        sm = card.resize((315, int(315 * H / W)), Image.LANCZOS)
        sheet.paste(sm, ((i % 4) * 330 + 8, (i // 4) * 460 + 8), sm)
    sheet.save(fc.OUT / "_lore_sheet.png")
    rep = "\n".join(rows) + f"\ncards: {len(cards)} problems: {bad}\n"
    (fc.OUT / "_lore_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad or len(cards) != 12 else 0)


main()
