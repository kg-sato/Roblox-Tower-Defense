"""Familiar portrait cards (T096). Draws 12 cards (630 x 880) with Pillow from the lore files in Roblox Dev/Lore/Familiars/*.md and the textured model
stills (Roblox Dev/Assets/3D/Familiars/textured/<Name>_tex_three_quarter.png). Each card: brass frame with corner studs, portrait window with an
identity-colour glow, rarity gems, name plate in the identity colour with the epithet, faction and element line, the one-sentence lore line, and a
role and home-set footer. Writes Roblox Dev/Assets/Characters/Cards/<Name>_card.png, _contact_sheet.png and _card_report.txt (layout and contrast checks).
Run with the Hunyuan3D venv: Hunyuan3D\\.venv\\Scripts\\python tools\\familiar_cards.py. Drawn by code: a clean concept card, not hand-painted art."""
import pathlib, re, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[1]
LORE = ROOT / "Roblox Dev" / "Lore" / "Familiars"
TEX = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "textured"
OUT = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Cards"
FONTS = pathlib.Path(r"C:\Windows\Fonts")
W, H = 630, 880
BRASS = [(236, 205, 120), (201, 162, 75), (140, 104, 40), (201, 162, 75)]
INK = (24, 22, 30)
PARCH = (238, 226, 196)
RARITY = {"Common": 1, "Rare": 2, "Epic": 3, "Legendary": 4}


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def lum(c):
    f = lambda v: (v / 255 / 12.92) if v / 255 <= 0.03928 else (((v / 255) + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2])


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def parse(path):
    t = path.read_text(encoding="utf-8")
    name_ep = re.search(r"\*\*Name and epithet:\*\* (.+?)\.\n", t).group(1)
    fac = re.search(r"\*\*Faction and element:\*\* (.+?)\. \*\*Rarity:\*\* (\w+)", t)
    role = re.search(r"\*\*Role \(one verb\):\*\* (\w+)", t).group(1)
    home = re.search(r"\*\*Home set:\*\* (.+?)\.", t).group(1)
    col = re.search(r"\*\*Identity colour.*?`(#[0-9A-Fa-f]{6})`", t).group(1)
    lore = re.search(r"\*\*Lore line \((\d+) words\):\*\* (.+)\n", t)
    name, epithet = [s.strip() for s in name_ep.split(",", 1)]
    return {"file": path.stem, "name": name, "epithet": epithet, "faction": fac.group(1).split(";")[0].strip(),
            "element": fac.group(1).split(";")[1].strip() if ";" in fac.group(1) else "", "rarity": fac.group(2), "role": role, "home": home,
            "colour": hexrgb(col), "lore": lore.group(2).strip()}


def wrap(draw, text, fnt, maxw):
    lines, cur = [], ""
    for w in text.split():
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=fnt) <= maxw:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def vgrad(size, top, bot):
    g = Image.new("RGB", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        d.line([(0, y), (size[0], y)], fill=mix(top, bot, y / max(1, size[1] - 1)))
    return g


def gem(d, cx, cy, r, fill, edge):
    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=fill, outline=edge)


def key_out(im):
    """The stills have an opaque flat backdrop: make pixels near the corner colour transparent (soft edge between distance 14 and 30)."""
    px = im.load()
    bg = px[2, 2][:3]
    a = Image.new("L", im.size, 255)
    ap = a.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = px[x, y][:3]
            dist = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            ap[x, y] = 0 if dist < 14 else (255 if dist > 30 else int((dist - 14) / 16 * 255))
    a = a.filter(ImageFilter.MinFilter(3))
    out = im.copy()
    out.putalpha(a)
    return out


def draw_card(f):
    c = f["colour"]
    glow = c if lum(c) > 0.08 else mix(c, (255, 255, 255), 0.55)
    card = Image.new("RGB", (W, H), (20, 18, 26))
    # brass frame: gradient fill then dark card face
    frame = vgrad((W, H), BRASS[0], BRASS[2])
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], 34, fill=255)
    base = Image.new("RGB", (W, H), (0, 0, 0))
    base.paste(frame, (0, 0), mask)
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    card.paste(base, (0, 0), mask)
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([16, 16, W - 17, H - 17], 24, fill=(26, 23, 34), outline=(90, 66, 24), width=3)
    d.rounded_rectangle([24, 24, W - 25, H - 25], 18, outline=(201, 162, 75), width=2)
    for (x, y) in ((30, 30), (W - 31, 30), (30, H - 31), (W - 31, H - 31)):
        d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=(236, 205, 120), outline=(90, 66, 24), width=2)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(140, 104, 40))
    # portrait window
    px0, py0, px1, py1 = 48, 48, W - 48, 488
    pw, ph = px1 - px0, py1 - py0
    win = vgrad((pw, ph), mix((20, 20, 34), glow, 0.18), mix((10, 10, 16), glow, 0.08)).convert("RGBA")
    g = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    gd.ellipse([pw * 0.1, ph * 0.12, pw * 0.9, ph * 0.98], fill=glow + (150,))
    g = g.filter(ImageFilter.GaussianBlur(60))
    win = Image.alpha_composite(win, g)
    tex = Image.open(TEX / f"{f['file']}_tex_three_quarter.png").convert("RGBA")
    tex = key_out(tex)
    bbox = tex.getbbox()
    tex = tex.crop(bbox)
    s = min((pw - 40) / tex.width, (ph - 50) / tex.height)
    tex = tex.resize((int(tex.width * s), int(tex.height * s)), Image.LANCZOS)
    sh = Image.new("RGBA", win.size, (0, 0, 0, 0))
    ex, ey = (pw - tex.width) // 2, ph - tex.height - 22
    shadow = Image.new("RGBA", tex.size, (0, 0, 0, 0))
    shadow.putalpha(tex.split()[3].point(lambda v: int(v * 0.6)))
    sh.paste(shadow, (ex + 6, ey + 8), shadow)
    sh = sh.filter(ImageFilter.GaussianBlur(7))
    win = Image.alpha_composite(win, sh)
    win.paste(tex, (ex, ey), tex)
    wm = Image.new("L", (pw, ph), 0)
    ImageDraw.Draw(wm).rounded_rectangle([0, 0, pw - 1, ph - 1], 14, fill=255)
    card.paste(win, (px0, py0), wm)
    d.rounded_rectangle([px0 - 1, py0 - 1, px1, py1], 14, outline=(236, 205, 120), width=3)
    d.rounded_rectangle([px0 + 4, py0 + 4, px1 - 4, py1 - 4], 11, outline=(90, 66, 24), width=1)
    # rarity gems
    n = RARITY[f["rarity"]]
    cx0 = W // 2 - (n - 1) * 17
    for i in range(n):
        gem(d, cx0 + i * 34, 508, 11, (236, 205, 120), (90, 66, 24))
    # name plate
    plate = [44, 528, W - 44, 602]
    d.rounded_rectangle(plate, 12, fill=c, outline=(236, 205, 120), width=3)
    txt = (255, 255, 255) if contrast((255, 255, 255), c) >= contrast(INK, c) else INK
    nf = font("georgiab.ttf", 40)
    while d.textlength(f["name"].upper(), font=nf) > plate[2] - plate[0] - 40:
        nf = font("georgiab.ttf", nf.size - 2)
    d.text((W // 2, 565), f["name"].upper(), font=nf, fill=txt, anchor="mm")
    ef = font("georgiai.ttf", 22)
    d.text((W // 2, 626), f["epithet"].capitalize(), font=ef, fill=(236, 205, 120), anchor="mm")
    ff = font("georgiab.ttf", 17)
    fac = f"{f['faction'].upper()}  \u2022  {f['element'].upper()}"
    d.text((W // 2, 660), fac, font=ff, fill=(190, 182, 200), anchor="mm")
    d.line([(90, 682), (W // 2 - 14, 682)], fill=(201, 162, 75), width=2)
    d.line([(W // 2 + 14, 682), (W - 90, 682)], fill=(201, 162, 75), width=2)
    gem(d, W // 2, 682, 6, (201, 162, 75), (90, 66, 24))
    # lore line
    lf = font("georgiai.ttf", 23)
    lines = wrap(d, f["lore"], lf, W - 130)
    y = 702
    for ln in lines:
        d.text((W // 2, y), ln, font=lf, fill=PARCH, anchor="mt")
        y += 31
    lore_bottom = y
    # footer
    ft = font("georgia.ttf", 16)
    foot = f"{f['role'].upper()}  \u2022  {f['home'].upper()}"
    d.text((W // 2, H - 52), foot, font=ft, fill=(160, 150, 130), anchor="mm")
    return card, {"lines": len(lines), "lore_bottom": lore_bottom, "max_line": max(d.textlength(l, font=lf) for l in lines),
                  "name_font": nf.size, "plate_contrast": contrast(txt, c), "epithet_contrast": contrast((236, 205, 120), (26, 23, 34)),
                  "lore_contrast": contrast(PARCH, (26, 23, 34)), "foot_bottom": H - 52 + 10}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    cards, rows, bad = [], [], 0
    for p in sorted(LORE.glob("*.md")):
        f = parse(p)
        card, m = draw_card(f)
        card.save(OUT / f"{f['file']}_card.png")
        cards.append((f, card))
        ok = m["lore_bottom"] <= H - 85 and m["max_line"] <= W - 130 and m["plate_contrast"] >= 4.5 and m["lore_contrast"] >= 7 and m["epithet_contrast"] >= 4.5 and m["lines"] <= 4
        bad += not ok
        rows.append(f"{f['file']:16} {f['rarity']:9} lines {m['lines']} lore_bottom {m['lore_bottom']:4d} name_font {m['name_font']} plate_contrast {m['plate_contrast']:5.2f} lore_contrast {m['lore_contrast']:5.2f} {'ok' if ok else 'CHECK'}")
    sheet = Image.new("RGB", (4 * 330, 3 * 460), (40, 40, 52))
    for i, (f, card) in enumerate(cards):
        sm = card.resize((315, int(315 * H / W)), Image.LANCZOS)
        sheet.paste(sm, ((i % 4) * 330 + 8, (i // 4) * 460 + 8), sm)
    sheet.save(OUT / "_contact_sheet.png")
    rep = "\n".join(rows) + f"\ncards: {len(cards)} problems: {bad}\n"
    (OUT / "_card_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad or len(cards) != 12 else 0)


if __name__ == "__main__":
    main()
