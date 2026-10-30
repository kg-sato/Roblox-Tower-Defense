"""Fraction of pixels with blue-dominant hue (b > r+20 and b > g+10). Usage: blue_frac.py image..."""
import sys
from PIL import Image
for p in sys.argv[1:]:
    im = Image.open(p).convert("RGB"); px = im.getdata(); n = 0
    for r, g, b in px:
        if b > r + 20 and b > g + 10: n += 1
    print(p, im.size, round(n / (im.size[0] * im.size[1]), 5))
