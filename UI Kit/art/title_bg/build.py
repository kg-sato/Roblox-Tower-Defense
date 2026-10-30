"""Round 2: builds the title-page layers (1920x1080) from raw FLUX output + Pillow. Gold-ink palette. Out: layers/*.png, composite.png"""
import math, random, os
from PIL import Image, ImageFilter, ImageOps, ImageDraw, ImageChops
os.makedirs("layers", exist_ok=True)
W, H = 1920, 1080
K, D, G, G2, CR = "#0b0a09", "#1a1714", "#b8975a", "#d9b878", "#efe6cf"
HEAD = (1230, 285)   # where the deity's head ends up
def ramp(img, mid, hi): return ImageOps.colorize(ImageOps.autocontrast(img.convert("L")), K, mid, hi, midpoint=118)
def grad(w, h, fn): # vertical L gradient from fn(y/h)->0..255
    g = Image.linear_gradient("L").resize((w, h)); return g.point(lambda v: int(fn(v / 255)))
# 1 sky: dark, vignetted, one luminous source behind the head
sky = Image.open("raw/sky_s22.png").convert("L").resize((W + 120, H + 68), Image.LANCZOS).point(lambda v: int(v * 0.07))
sky = ramp(sky, "#14110c", "#bda878").convert("RGB")
vig = Image.radial_gradient("L").resize((W + 120, H + 68)).point(lambda v: min(255, int(v * 2.2)))  # 0 centre .. 255 edge
sky = Image.composite(Image.new("RGB", sky.size, K), sky, vig.point(lambda v: int(v * 0.95)))
src = Image.new("L", sky.size, 0); sx, sy = HEAD[0] + 60, HEAD[1] + 34
ImageDraw.Draw(src).ellipse([sx - 120, sy - 120, sx + 120, sy + 120], fill=255)
src = src.filter(ImageFilter.GaussianBlur(90))
core = Image.new("L", sky.size, 0); ImageDraw.Draw(core).ellipse([sx - 70, sy - 70, sx + 70, sy + 70], fill=255); core = core.filter(ImageFilter.GaussianBlur(45))
src = ImageChops.lighter(src.point(lambda v: min(255, int(v * 1.8))), core)  # r4: real focal sun
sky = Image.composite(Image.new("RGB", sky.size, CR), sky, src)
xg = Image.linear_gradient("L").rotate(-90).resize(sky.size)  # 0 left .. 255 right
dark = ImageChops.multiply(xg.point(lambda v: int(max(0, v - 120) * 1.3)), Image.linear_gradient("L").resize(sky.size).point(lambda v: 90 + v // 2))
sky = Image.composite(Image.new("RGB", sky.size, K), sky, ImageChops.multiply(dark.point(lambda v: int(v * 0.55)), ImageOps.invert(src)))  # r4: darken muddy mid-right/bottom, not the sun
sky.save("layers/sky.png")
# 2 god rays (rotate in UI around the head)
S = 1400; ray = Image.new("L", (S, S), 0); d = ImageDraw.Draw(ray); random.seed(9)
for i in range(48):
    a = random.uniform(0, 2 * math.pi); wd = random.uniform(0.008, 0.04); v = random.randint(90, 255)
    d.polygon([(S / 2, S / 2), (S / 2 + S * math.cos(a - wd), S / 2 + S * math.sin(a - wd)), (S / 2 + S * math.cos(a + wd), S / 2 + S * math.sin(a + wd))], fill=v)
ray = ImageChops.multiply(ray.filter(ImageFilter.GaussianBlur(10)), ImageOps.invert(Image.radial_gradient("L").resize((S, S))).point(lambda v: min(255, int(v * 1.15))))
r = Image.new("RGBA", (S, S), G2); r.putalpha(ray.point(lambda v: int(v * 0.85))); r.save("layers/rays.png")
# 3 figure r4: feathered luminance matte (no cut-out edge), soft void face + crown of light, graded to the scene
f = Image.open("raw/fig3_s70.png").convert("L")
void = Image.new("L", f.size, 0); ImageDraw.Draw(void).ellipse([638, 96, 726, 186], fill=255); void = void.filter(ImageFilter.GaussianBlur(24)); void = void.point(lambda v: min(255, int(v * 1.25)))
f = ImageChops.multiply(f, ImageOps.invert(void.point(lambda v: int(v * 0.97))))
HS = (685, 140); HAND = (410, 360)
TH, SC = 17, 1.6
clr = Image.new('L', f.size, 255); ImageDraw.Draw(clr).rectangle([0, 0, 520, 300], fill=0); ImageDraw.Draw(clr).rectangle([1180, 0, 1344, 330], fill=0); ImageDraw.Draw(clr).rectangle([0, 600, 150, 768], fill=0)
clr = clr.filter(ImageFilter.GaussianBlur(40))
inter = ImageChops.multiply(f.point(lambda v: 255 if v > 22 else 0), clr).filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.MinFilter(25))
inter = inter.filter(ImageFilter.MinFilter(21)).filter(ImageFilter.GaussianBlur(10))  # solid core, feathered ~10 px
edge = ImageChops.multiply(f.point(lambda v: min(255, int(v * 2.4))), clr)  # luminous wisps fade by their own brightness
m = ImageChops.lighter(inter, edge).filter(ImageFilter.GaussianBlur(2))
m = ImageChops.lighter(m, void)  # the soft void face stays opaque (dark), the sun shows around it
m = ImageChops.multiply(m, grad(*f.size, lambda t: 255 if t < .5 else 255 * max(0.0, 1 - (t - .5) * 2.2) ** 1.4))  # lower body dissolves
hi = tuple(int(c * 0.9) for c in (239, 230, 207))
body = ramp(f.point(lambda v: min(255, int(300 * (v / 255) ** 1.7))), "#1b1610", "#%02x%02x%02x" % hi).convert("RGBA")
shade = grad(*f.size, lambda t: 255 - 120 * t)  # darker toward the base: matches the scene's blacks
body = Image.composite(body, Image.new("RGBA", f.size, K + "ff"), shade)
rim = ImageChops.subtract(m, m.filter(ImageFilter.MinFilter(9)).filter(ImageFilter.GaussianBlur(6)))
rim = ImageChops.multiply(rim, grad(*f.size, lambda t: 255 * max(0.15, 1 - t * 1.4)))  # lit from the sun at the head
rimc = Image.new("RGBA", f.size, G2); rimc.putalpha(rim.point(lambda v: min(255, int(v * 1.1))))
vg = Image.new("L", f.size, 0); ImageDraw.Draw(vg).ellipse([665, 120, 705, 166], fill=255); vg = vg.filter(ImageFilter.GaussianBlur(14))
vc = Image.new("RGBA", f.size, G2); vc.putalpha(vg.point(lambda v: int(v * 0.32))); body.alpha_composite(vc)  # faint light inside the void
body.putalpha(m); body.alpha_composite(rimc)
halo = m.filter(ImageFilter.MaxFilter(41)).filter(ImageFilter.GaussianBlur(60)).point(lambda v: int(v * 0.22))
fog = Image.new("RGBA", f.size, CR); fog.putalpha(halo); fog.alpha_composite(body)
fog = fog.resize((int(f.size[0] * SC), int(f.size[1] * SC)), Image.LANCZOS)
pivot = (HS[0] * SC, HS[1] * SC)
fog = fog.rotate(TH, resample=Image.BICUBIC, center=pivot, translate=(0, 0))
fig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
# crown: thin rings + radiant spikes behind the head (gold-ink, restrained)
crown = Image.new("L", (W, H), 0); cdr = ImageDraw.Draw(crown); hx0, hy0 = HEAD
for rad, wd, v in ((150, 2, 70), (215, 1, 38)): cdr.ellipse([hx0 - rad, hy0 - rad, hx0 + rad, hy0 + rad], outline=v, width=wd)
random.seed(4)
for i in range(24):
    a_ = i * math.pi / 12 + random.uniform(-.03, .03); r0 = 130; r1 = random.choice((330, 390, 450, 520)); w_ = 0.012
    cdr.polygon([(hx0 + r0 * math.cos(a_ - w_), hy0 + r0 * math.sin(a_ - w_)), (hx0 + r1 * math.cos(a_), hy0 + r1 * math.sin(a_)), (hx0 + r0 * math.cos(a_ + w_), hy0 + r0 * math.sin(a_ + w_))], fill=random.randint(40, 90))
crown = crown.filter(ImageFilter.GaussianBlur(1.6)); cc = Image.new("RGBA", (W, H), G2); cc.putalpha(crown); fig.alpha_composite(cc)
fig.paste(fog, (int(HEAD[0] - pivot[0]), int(HEAD[1] - pivot[1])), fog)
# ground mist at the lower body, dissolving into the city
random.seed(21); gm = Image.new("L", (W, H), 0); gd = ImageDraw.Draw(gm)
for _ in range(46):
    x = random.randint(780, 1800); y = random.randint(560, 760); rx = random.randint(120, 320); ry = random.randint(22, 60); gd.ellipse([x - rx, y - ry, x + rx, y + ry], fill=random.randint(40, 110))
gm = gm.filter(ImageFilter.GaussianBlur(38)); gmc = Image.new("RGBA", (W, H), "#cdbf9c"); gmc.putalpha(gm.point(lambda v: int(v * 0.8))); fig.alpha_composite(gmc)
clean = Image.new("L", (W, H), 255); cd = ImageDraw.Draw(clean)
cd.rectangle([1835, 0, W, H], fill=0); cd.rectangle([1735, 520, W, H], fill=0)
fig.putalpha(ImageChops.multiply(fig.split()[3], clean.filter(ImageFilter.GaussianBlur(8))))
fig.save("layers/figure.png")
th = math.radians(TH); hx, hy = (HAND[0] - HS[0]) * SC, (HAND[1] - HS[1]) * SC
HANDF = ((HEAD[0] + hx * math.cos(th) + hy * math.sin(th)), (HEAD[1] - hx * math.sin(th) + hy * math.cos(th)))
print("left hand at", HANDF[0] / W, HANDF[1] / H)
# 4 mist bands (wrap in x)
def band(seed, h, op):
    random.seed(seed); w = 2048; base = Image.new("L", (w, h), 0); dd = ImageDraw.Draw(base)
    for _ in range(60):
        x = random.randint(0, w); y = random.randint(h // 4, 3 * h // 4); rx = random.randint(150, 420); ry = random.randint(20, h // 3)
        for dx in (-w, 0, w): dd.ellipse([x - rx + dx, y - ry, x + rx + dx, y + ry], fill=random.randint(40, 120))
    base = base.filter(ImageFilter.GaussianBlur(45)); base = ImageChops.multiply(base, grad(w, h, lambda t: 255 * math.sin(math.pi * t)))
    im = Image.new("RGBA", (w, h), CR); im.putalpha(base.point(lambda v: min(255, int(v * op)))); return im
band(1, 420, 0.4).save("layers/mist_far.png"); band(2, 420, 0.7).save("layers/mist_near.png")
# 5 ground: foggy rooftops far below, fading into the sky mist
gr = Image.open("raw/ground_s82.png").convert("L").resize((W, int(W * 768 / 1344)), Image.LANCZOS)
gr = gr.crop((0, gr.size[1] - 640, W, gr.size[1])).point(lambda v: int(v * 0.12))
grc = ramp(gr, "#1a1610", "#7a6a48").convert("RGBA")
grc.putalpha(grad(W, 640, lambda t: 230 * min(1, t * 2.6) ** 1.5))
xr = Image.linear_gradient("L").rotate(-90).resize((W, 640)).point(lambda v: 255 - int(max(0, v - 110) * 0.8))  # darken mid-right
grc.putalpha(ImageChops.multiply(grc.split()[3], xr))
ground = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ground.paste(grc, (0, H - 640), grc)
ground.paste(Image.new("RGBA", (W, 160), K), (0, H - 160), grad(W, 160, lambda t: 255 * t))  # dark at the very bottom
ground.save("layers/ground.png")
# 6 foreground: bridge girder with arches, rail, the tiny traveller with a warm lamp
fg = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(fg)
def y0(x): return 896 - x * 60 / W
d.polygon([(0, y0(0)), (W, y0(W)), (W, y0(W) + 96), (0, y0(0) + 96)], fill=K)
for x in range(-60, W + 120, 150):  # arches cut out of the girder (show the fog below)
    d.pieslice([x, y0(x) + 18, x + 120, y0(x) + 190], 180, 360, fill=(0, 0, 0, 0))
d.line([(0, y0(0)), (W, y0(W))], fill=G, width=3)
for x in range(60, W, 140): d.line([(x, y0(x)), (x, y0(x) - 56)], fill=D, width=5)
d.line([(0, y0(0) - 56), (W, y0(W) - 56)], fill=D, width=4)
cx = 830; cy = y0(cx) - 3
d.polygon([(cx - 7, cy), (cx + 7, cy), (cx + 5, cy - 22), (cx + 1, cy - 28), (cx - 1, cy - 28), (cx - 5, cy - 22)], fill=K)
d.ellipse([cx - 4, cy - 38, cx + 4, cy - 30], fill=K)
d.line([(cx - 8, cy), (cx - 6, cy - 22), (cx - 5, cy - 30)], fill=CR, width=2); d.line([(cx + 8, cy), (cx + 6, cy - 22), (cx + 4, cy - 30)], fill=G2, width=2); d.line([(cx + 4, cy - 26), (cx + 13, cy - 38)], fill=K, width=3)
d.line([(cx - 6, cy - 22), (cx - 4, cy - 2)], fill=G2, width=1); d.line([(cx - 4, cy - 38), (cx - 2, cy - 31)], fill=G2, width=1)  # rim light
lamp = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ld = ImageDraw.Draw(lamp); lx, ly = cx + 14, cy - 40
ld.ellipse([lx - 70, ly - 70, lx + 70, ly + 70], fill=(239, 214, 150, 235)); ld.ellipse([lx - 24, ly - 24, lx + 24, ly + 24], fill=(255, 240, 200, 255)); lamp = lamp.filter(ImageFilter.GaussianBlur(26))
path = Image.new("L", (W, H), 0); pdw = ImageDraw.Draw(path); hxp, hyp = HANDF
pdw.polygon([(lx, ly - 5), (hxp, hyp - 14), (hxp, hyp + 14), (lx, ly + 5)], fill=255); path = path.filter(ImageFilter.GaussianBlur(14))
pf = ImageChops.multiply(path, Image.new("L", (W, H), 90)); pc = Image.new("RGBA", (W, H), G2); pc.putalpha(pf); lamp.alpha_composite(pc)
fg.alpha_composite(lamp); ImageDraw.Draw(fg).ellipse([lx - 3, ly - 3, lx + 3, ly + 3], fill=CR)
fg.save("layers/foreground.png")
# composite preview
bg = Image.open("layers/sky.png").crop((60, 34, 60 + W, 34 + H)).convert("RGBA")
rr = Image.open("layers/rays.png").resize((2400, 2400)); bg.alpha_composite(rr.crop((1200 - HEAD[0], 1200 - HEAD[1], 1200 - HEAD[0] + W, 1200 - HEAD[1] + H)))
bg.alpha_composite(ground); bg.alpha_composite(fig)
bg.alpha_composite(Image.open("layers/mist_far.png").crop((0, 0, W, 420)), (0, 560)); bg.alpha_composite(Image.open("layers/mist_near.png").crop((0, 0, W, 420)), (0, 700))
bg.alpha_composite(fg); bg.convert("RGB").save("composite.png")
al = fig.split()[3]; n = sum(al.point(lambda v: 1 if v > 60 else 0).getdata()); print("entity frac a>60:", n / (W * H), "a>128:", sum(al.point(lambda v: 1 if v > 128 else 0).getdata()) / (W * H))
