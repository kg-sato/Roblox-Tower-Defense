"""Contact sheet of hud_art/<prefix>*_a.png on a dark grey ground: python sheet.py vine out.png"""
import sys, glob, os
from PIL import Image
pre, out = sys.argv[1], sys.argv[2]
fs = sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "hud_art", pre + "*_a.png")))
T = 360
ims = []
for f in fs:
    im = Image.open(f).convert("RGBA"); im.thumbnail((T, T)); ims.append((os.path.basename(f), im))
cols = 5; rows = (len(ims) + cols - 1) // cols
sh = Image.new("RGB", (cols * T, rows * T), (70, 70, 74))
for i, (n, im) in enumerate(ims):
    sh.paste(im, ((i % cols) * T, (i // cols) * T), im)
sh.save(out); print(len(ims), [n for n, _ in ims])
