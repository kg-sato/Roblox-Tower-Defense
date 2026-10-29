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
sky = Image.open("raw/sky_s22.png").convert("L").resize((W + 120, H + 68), Image.LANCZOS).point(lambda v: int(v * 0.24))
sky = ramp(sky, "#2c261b", "#bda878").convert("RGB")
vig = Image.radial_gradient("L").resize((W + 120, H + 68)).point(lambda v: min(255, int(v * 1.5)))  # 0 centre .. 255 edge
sky = Image.composite(Image.new("RGB", sky.size, K), sky, vig.point(lambda v: int(v * 0.8)))
src = Image.new("L", sky.size, 0); sx, sy = HEAD[0] + 60, HEAD[1] + 34
ImageDraw.Draw(src).ellipse([sx - 170, sy - 170, sx + 170, sy + 170], fill=255)
src = src.filter(ImageFilter.GaussianBlur(110))
sky = Image.composite(Image.new("RGB", sky.size, CR), sky, src.point(lambda v: int(v * 0.7)))
sky.save("layers/sky.png")
# 2 god rays (rotate in UI around the head)
S = 1400; ray = Image.new("L", (S, S), 0); d = ImageDraw.Draw(ray); random.seed(9)
for i in range(40):
    a = random.uniform(0, 2 * math.pi); wd = random.uniform(0.008, 0.04); v = random.randint(60, 200)
    d.polygon([(S / 2, S / 2), (S / 2 + S * math.cos(a - wd), S / 2 + S * math.sin(a - wd)), (S / 2 + S * math.cos(a + wd), S / 2 + S * math.sin(a + wd))], fill=v)
ray = ImageChops.multiply(ray.filter(ImageFilter.GaussianBlur(10)), ImageOps.invert(Image.radial_gradient("L").resize((S, S))).point(lambda v: min(255, int(v * 1.5))))
r = Image.new("RGBA", (S, S), G2); r.putalpha(ray.point(lambda v: int(v * 0.75))); r.save("layers/rays.png")
# 3 figure: faceless (face painted to a void), rotated so the reaching arm lowers toward the traveller, rim lit, translucent
f = Image.open("raw/fig3_s70.png").convert("L")
void = Image.new("L", f.size, 0); ImageDraw.Draw(void).ellipse([649, 94, 721, 186], fill=255); void = void.filter(ImageFilter.GaussianBlur(7)); void = void.point(lambda v: min(255, v * 2))
f = ImageChops.multiply(f, ImageOps.invert(void.point(lambda v: int(v * 0.97))))
HS = (685, 140); HAND = (410, 360)  # head centre in the source
TH, SC = 17, 1.6
clr = Image.new('L', f.size, 255); ImageDraw.Draw(clr).rectangle([0, 0, 520, 300], fill=0); ImageDraw.Draw(clr).rectangle([1180, 0, 1344, 330], fill=0); ImageDraw.Draw(clr).rectangle([0, 600, 150, 768], fill=0)
m = ImageChops.multiply(f.point(lambda v: 255 if v > 22 else 0), clr.filter(ImageFilter.GaussianBlur(40)))
m = m.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7)).filter(ImageFilter.GaussianBlur(1.5))
m = ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(3)), grad(*f.size, lambda t: 255 * (1 - 0.35 * t) if t < .75 else 255 * (1 - 0.35 * t) * (1 - (t - .75) * 2.2)))  # lower body thins out
body = ramp(f.point(lambda v: min(255, int(v * 1.1))), "#a48f62", CR).convert("RGBA")
rim = ImageChops.subtract(m, m.filter(ImageFilter.MinFilter(13)).filter(ImageFilter.GaussianBlur(4))).point(lambda v: int(v * 0.35))
rimc = Image.new("RGBA", f.size, CR); rimc.putalpha(rim)
body.putalpha(m.point(lambda v: int(v * 0.97))); body.alpha_composite(rimc)
halo = m.filter(ImageFilter.MaxFilter(61)).filter(ImageFilter.GaussianBlur(70)).point(lambda v: int(v * 0.5))
fog = Image.new("RGBA", f.size, CR); fog.putalpha(halo); fog.alpha_composite(body)
fog = fog.resize((int(f.size[0] * SC), int(f.size[1] * SC)), Image.LANCZOS)
pivot = (HS[0] * SC, HS[1] * SC)
fog = fog.rotate(TH, resample=Image.BICUBIC, center=pivot, translate=(0, 0))
fig = Image.new("RGBA", (W, H), (0, 0, 0, 0)); fig.paste(fog, (int(HEAD[0] - pivot[0]), int(HEAD[1] - pivot[1])), fog)
fig.save("layers/figure.png")
th = math.radians(TH); hx, hy = (HAND[0] - HS[0]) * SC, (HAND[1] - HS[1]) * SC
print("left hand at", (HEAD[0] + hx * math.cos(th) + hy * math.sin(th)) / W, (HEAD[1] - hx * math.sin(th) + hy * math.cos(th)) / H)
# 4 mist bands (wrap in x)
def band(seed, h, op):
    random.seed(seed); w = 2048; base = Image.new("L", (w, h), 0); dd = ImageDraw.Draw(base)
    for _ in range(60):
        x = random.randint(0, w); y = random.randint(h // 4, 3 * h // 4); rx = random.randint(150, 420); ry = random.randint(20, h // 3)
        for dx in (-w, 0, w): dd.ellipse([x - rx + dx, y - ry, x + rx + dx, y + ry], fill=random.randint(40, 120))
    base = base.filter(ImageFilter.GaussianBlur(45)); base = ImageChops.multiply(base, grad(w, h, lambda t: 255 * math.sin(math.pi * t)))
    im = Image.new("RGBA", (w, h), CR); im.putalpha(base.point(lambda v: min(255, int(v * op)))); return im
band(1, 420, 1.0).save("layers/mist_far.png"); band(2, 420, 1.5).save("layers/mist_near.png")
# 5 ground: foggy rooftops far below, fading into the sky mist
gr = Image.open("raw/ground_s82.png").convert("L").resize((W, int(W * 768 / 1344)), Image.LANCZOS)
gr = gr.crop((0, gr.size[1] - 640, W, gr.size[1])).point(lambda v: int(v * 0.38))
grc = ramp(gr, "#3a3122", "#9c8860").convert("RGBA")
grc.putalpha(grad(W, 640, lambda t: 230 * min(1, t * 2.6) ** 1.5))
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
d.ellipse([cx - 4, cy - 38, cx + 4, cy - 30], fill=K); d.line([(cx + 4, cy - 26), (cx + 13, cy - 38)], fill=K, width=3)
d.line([(cx - 6, cy - 22), (cx - 4, cy - 2)], fill=G2, width=1); d.line([(cx - 4, cy - 38), (cx - 2, cy - 31)], fill=G2, width=1)  # rim light
lamp = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ld = ImageDraw.Draw(lamp); lx, ly = cx + 14, cy - 40
ld.ellipse([lx - 26, ly - 26, lx + 26, ly + 26], fill=(217, 184, 120, 160)); lamp = lamp.filter(ImageFilter.GaussianBlur(14))
fg.alpha_composite(lamp); ImageDraw.Draw(fg).ellipse([lx - 3, ly - 3, lx + 3, ly + 3], fill=CR)
fg.save("layers/foreground.png")
# composite preview
bg = Image.open("layers/sky.png").crop((60, 34, 60 + W, 34 + H)).convert("RGBA")
rr = Image.open("layers/rays.png").resize((2400, 2400)); bg.alpha_composite(rr.crop((1200 - HEAD[0], 1200 - HEAD[1], 1200 - HEAD[0] + W, 1200 - HEAD[1] + H)))
bg.alpha_composite(ground); bg.alpha_composite(fig)
bg.alpha_composite(Image.open("layers/mist_far.png").crop((0, 0, W, 420)), (0, 560)); bg.alpha_composite(Image.open("layers/mist_near.png").crop((0, 0, W, 420)), (0, 700))
bg.alpha_composite(fg); bg.convert("RGB").save("composite.png")
al = fig.split()[3]; n = sum(al.point(lambda v: 1 if v > 60 else 0).getdata()); print("entity frac a>60:", n / (W * H), "a>128:", sum(al.point(lambda v: 1 if v > 128 else 0).getdata()) / (W * H))
