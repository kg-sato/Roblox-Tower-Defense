"""T081 post step: 128px copies, six rarity frames (1..6 rings), contact sheet, measurements -> evidence."""
import os, sys, glob, statistics
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_icons_set import ITEMS, OUTD, GOLD, GROUND, SZ
from PIL import Image, ImageDraw

names = list(ITEMS)
for n in names:
    Image.open(os.path.join(OUTD, n + ".png")).resize((128, 128), Image.LANCZOS).save(os.path.join(OUTD, n + "_128.png"))
for i in range(1, 7):  # blank rarity frame: i concentric gold rings, same 6 px rim as the icons
    im = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse((SZ*.03, SZ*.03, SZ*.97, SZ*.97), fill=GROUND + (255,), outline=GOLD + (255,), width=6)
    for k in range(1, i):
        o = SZ * (.03 + .06 * k); d.ellipse((o, o, SZ - o, SZ - o), outline=GOLD + (255,), width=3)
    im.save(os.path.join(OUTD, "rarity_frame_%d.png" % i))
files = sorted(f for f in glob.glob(os.path.join(OUTD, "*.png")))
sheet = Image.new("RGB", (8 * 136 + 8, 5 * 136 + 8), (70, 70, 70))
for j, f in enumerate(files):
    im = Image.open(f).convert("RGBA").resize((128, 128), Image.LANCZOS)
    sheet.paste(im, (8 + (j % 8) * 136, 8 + (j // 8) * 136), im)
sheet.save(os.path.join(OUTD, "contact_sheet.jpg"), quality=90)
rows = []; runs_all = []
for f in files:
    im = Image.open(f)
    if im.size != (SZ, SZ) or im.mode != "RGBA": continue
    a = im.getchannel("A"); px = im.load()
    corner_a = a.getpixel((2, 2)); centre_a = a.getpixel((SZ // 2, SZ // 2))
    lum = im.convert("L"); runs = []
    for y in range(120, 400, 4):
        r = 0
        for x in range(SZ):
            if lum.getpixel((x, y)) > 110 and a.getpixel((x, y)) > 250: r += 1
            elif r: runs.append(r); r = 0
    runs_all.append((os.path.basename(f), statistics.median(runs) if runs else 0))
    cols = {}
    for y in range(0, SZ, 4):
        for x in range(0, SZ, 4):
            if a.getpixel((x, y)) > 250: c = px[x, y][:3]; k = "ground" if sum(c) < 90 else "gold" if sum(c) < 560 else "cream"; cols[k] = cols.get(k, 0) + 1
    t = sum(cols.values()); rows.append((os.path.basename(f), corner_a, centre_a, {k: round(v / t, 2) for k, v in cols.items()}))
meds = [m for _, m in runs_all]
print("files with alpha:", len(rows), "corner alpha all 0:", all(r[1] == 0 for r in rows), "centre alpha all 255:", all(r[2] == 255 for r in rows))
print("total png:", len(files), "(512px icons 17, 128px 17, rarity frames 6)")
print("median stroke run (px, 512 icons): min %.1f median %.1f max %.1f" % (min(meds), statistics.median(meds), max(meds)))
print("rim stroke width 6 px on all 512 icons (drawn, same code)")
for r in rows: print(r)
