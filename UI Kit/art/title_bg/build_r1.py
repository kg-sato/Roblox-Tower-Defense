"""Builds the title-page layers (1920x1080 unless noted) from raw FLUX output + Pillow. Gold-ink palette only. Out: layers/*.png, composite.png"""
import math, random, os
from PIL import Image, ImageFilter, ImageOps, ImageDraw, ImageChops
os.makedirs("layers", exist_ok=True)
W, H = 1920, 1080
K, D, G, G2, CR = "#0b0a09", "#1a1714", "#b8975a", "#d9b878", "#efe6cf"
def ramp(img, lo=0, hi=255): return ImageOps.colorize(ImageOps.autocontrast(img.convert("L")), K, "#40372a", "#c9b68c", blackpoint=lo, whitepoint=hi, midpoint=130)
# 1 sky: darkened so the figure reads against it
sky = Image.open("raw/sky_s22.png").convert("L").resize((W + 120, H + 68), Image.LANCZOS)
sky = sky.point(lambda v: int(v * 0.8))
ramp(sky, 0, 200).convert("RGB").save("layers/sky.png")  # oversize by 120x68 so parallax drift never shows an edge
# 2 god rays: square, rotate in UI; additive-looking (alpha), fades radially
S = 1400; ray = Image.new("L", (S, S), 0); d = ImageDraw.Draw(ray); random.seed(4)
for i in range(46):
    a = random.uniform(0, 2 * math.pi); wd = random.uniform(0.012, 0.05); v = random.randint(40, 120)
    d.polygon([(S / 2, S / 2), (S / 2 + S * math.cos(a - wd), S / 2 + S * math.sin(a - wd)), (S / 2 + S * math.cos(a + wd), S / 2 + S * math.sin(a + wd))], fill=v)
ray = ray.filter(ImageFilter.GaussianBlur(14))
fade = Image.radial_gradient("L").resize((S, S)); fade = ImageOps.invert(fade).point(lambda v: min(255, int(v * 1.6)))
ray = ImageChops.multiply(ray, fade)
r = Image.new("RGBA", (S, S), G2); r.putalpha(ray.point(lambda v: int(v * 0.55))); r.save("layers/rays.png")
# 3 figure: hooded faceless robe, mask from luminance, plus a soft fog halo (the "entity" = figure + fog cloak)
f = Image.open("raw/figure2_s43.png").convert("L")
m = f.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9)).filter(ImageFilter.GaussianBlur(1.5))
body = ImageOps.colorize(ImageOps.autocontrast(f), D, "#b49f72", CR, midpoint=100).convert("RGBA"); body.putalpha(ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(5)).point(lambda v: int(v*0.82)), Image.linear_gradient('L').transpose(Image.FLIP_TOP_BOTTOM).resize(f.size).point(lambda v: min(255, int(150 + v*0.42)))))
halo = m.filter(ImageFilter.MaxFilter(101)).filter(ImageFilter.GaussianBlur(120)).point(lambda v: min(255, int(v * 1.5)))
fogc = Image.new("RGBA", f.size, CR); fogc.putalpha(halo)
fogc.alpha_composite(body); sc = 2.1
fc = fogc.resize((int(768 * sc), int(1024 * sc)), Image.LANCZOS)
fig = Image.new("RGBA", (W, H), (0, 0, 0, 0)); fig.paste(fc, (367, -152), fc)
fig.save("layers/figure.png")
# 4 mist bands: wrap-around horizontal noise (tileable in x), alpha
def band(seed, h, op):
    random.seed(seed); w = 2048
    base = Image.new("L", (w, h), 0); d = ImageDraw.Draw(base)
    for _ in range(70):
        x = random.randint(0, w); y = random.randint(h // 4, 3 * h // 4); rx = random.randint(150, 420); ry = random.randint(20, h // 3)
        for dx in (-w, 0, w): d.ellipse([x - rx + dx, y - ry, x + rx + dx, y + ry], fill=random.randint(40, 120))
    base = base.filter(ImageFilter.GaussianBlur(40)); fade = Image.linear_gradient('L').resize((w, h)); fade = fade.point(lambda v: int(255 * math.sin(math.pi * v / 255))); base = ImageChops.multiply(base, fade)
    im = Image.new("RGBA", (w, h), CR); im.putalpha(base.point(lambda v: min(255, int(v * op)))); return im
band(1, 420, 1.0).save("layers/mist_far.png"); band(2, 420, 1.5).save("layers/mist_near.png")
# 5 foreground: bridge edge + tiny character looking up
fg = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(fg)
d.polygon([(0, 900), (W, 840), (W, H), (0, H)], fill=K)
d.line([(0, 896), (W, 836)], fill=G, width=4); d.line([(0, 884), (W, 824)], fill=D, width=3)
for x in range(60, W, 140): y = 896 - x * 60 / W; d.line([(x, y), (x, y - 56)], fill=D, width=5) # posts
d.line([(0, 840), (W, 780)], fill=D, width=4)
cx, cy = 830, 896 - 830 * 60 / W  # ~35px tall figure on the rail line = 3% of height, 1% of width
cy -= 3
d.polygon([(cx - 7, cy), (cx + 7, cy), (cx + 5, cy - 22), (cx + 1, cy - 28), (cx - 1, cy - 28), (cx - 5, cy - 22)], fill=K)  # body + cloak
d.ellipse([cx - 4, cy - 38, cx + 4, cy - 30], fill=K); d.line([(cx + 4, cy - 26), (cx + 13, cy - 38)], fill=K, width=3) # arm raised to the figure
d.ellipse([cx - 5, cy - 39, cx + 3, cy - 31], outline=G, width=1)
fg.save("layers/foreground.png")
# composite preview
bg = Image.open("layers/sky.png").crop((60, 34, 60 + W, 34 + H)).convert("RGBA")
rr = Image.open("layers/rays.png").resize((2000, 2000)); bg.alpha_composite(rr.crop((40, 0, 40 + W, H)) if False else rr.crop((40, 460, 40 + W, 460 + H)))
bg.alpha_composite(fig)
for n, y in (("far", 560), ("near", 700)):
    mm = Image.open("layers/mist_%s.png" % n); bg.alpha_composite(mm.crop((0, 0, W, 420)), (0, y)) if False else bg.alpha_composite(mm, (0, y)) if W <= 2048 else None
bg.alpha_composite(fg); bg.convert("RGB").save("composite.png")
al = fig.split()[3]; print('entity frac a>60:', sum(al.point(lambda v: 1 if v > 60 else 0).getdata()) / (W * H), 'a>128:', sum(al.point(lambda v: 1 if v > 128 else 0).getdata()) / (W * H))
