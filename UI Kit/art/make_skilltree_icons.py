"""Engraved arcane icons for the skill tree (2026-10-29): 19 white line-art glyphs, 256 px, one 9 px line weight,
transparent background (tinted gold/cream in game). Pillow only. Run: python make_skilltree_icons.py -> skilltree_icons/*.png + _sheet.png"""
import math, os
from PIL import Image, ImageDraw
SS, N, W = 4, 256, 9
C = N * SS / 2
OUT = os.path.join(os.path.dirname(__file__), "skilltree_icons")
os.makedirs(OUT, exist_ok=True)
def P(x, y): return (C + x * SS, C + y * SS)  # glyph coords: -128..128
def new(): im = Image.new("L", (N * SS, N * SS), 0); return im, ImageDraw.Draw(im)
def line(d, pts, w=W): d.line([P(*p) for p in pts], fill=255, width=w * SS, joint="curve"); [d.ellipse([P(p[0] - w / 2, p[1] - w / 2), P(p[0] + w / 2, p[1] + w / 2)], fill=255) for p in (pts[0], pts[-1])]
def circ(d, cx, cy, r, w=W, fill=False):
    b = [P(cx - r, cy - r), P(cx + r, cy + r)]
    d.ellipse(b, fill=255 if fill else None, outline=255, width=w * SS)
def arc(d, cx, cy, r, a0, a1, w=W):
    d.arc([P(cx - r, cy - r), P(cx + r, cy + r)], a0, a1, fill=255, width=w * SS)
def poly(d, pts, w=W, closed=True): line(d, pts + ([pts[0]] if closed else []), w)
def dot(d, x, y, r): d.ellipse([P(x - r, y - r), P(x + r, y + r)], fill=255)
def star(d, cx, cy, r, k=5, inner=0.45, rot=-90, w=W):
    pts = []
    for i in range(k * 2):
        a = math.radians(rot + i * 180 / k); rr = r if i % 2 == 0 else r * inner
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    poly(d, pts, w)
def icon_Start(d):
    star(d, 0, 0, 105, 8, 0.45); circ(d, 0, 0, 24)
def icon_Claws(d):
    for o in (-52, 0, 52):
        line(d, [(o - 22 + 44 * t + 24 * math.sin(math.pi * t), -92 + 184 * t) for t in [i / 14 for i in range(15)]])
def icon_Magnet(d):
    arc(d, 0, -8, 70, 180, 360); line(d, [(-70, -8), (-70, 70)]); line(d, [(70, -8), (70, 70)]); line(d, [(-92, 40), (-48, 40)], 8); line(d, [(48, 40), (92, 40)], 8)
    line(d, [(-92, 78), (-48, 78)]); line(d, [(48, 78), (92, 78)])
def icon_Armor(d):
    poly(d, [(-70, -85), (70, -85), (70, 10), (0, 100), (-70, 10)]); line(d, [(0, -85), (0, 100)], 7); line(d, [(-60, -20), (60, -20)], 7)
def icon_Charge(d):
    poly(d, [(20, -105), (-55, 15), (-5, 15), (-22, 105), (58, -25), (8, -25)])
def icon_Charm(d):
    for dx, dy in ((-34, -34), (34, -34), (-34, 34), (34, 34)): circ(d, dx, dy, 32)
    line(d, [(0, 0), (10, 100)])
def icon_Finder(d):
    poly(d, [(-85, -35), (-45, -85), (45, -85), (85, -35), (0, 100)]); line(d, [(-85, -35), (85, -35)], 7)
    line(d, [(-45, -85), (-25, -35), (0, 100)], 7); line(d, [(45, -85), (25, -35), (0, 100)], 7)
def icon_Heavy(d):
    line(d, [(-80, -80), (80, 80)]); line(d, [(80, -80), (-80, 80)]); line(d, [(-100, -55), (-55, -100)], 8); line(d, [(100, -55), (55, -100)], 8)
    circ(d, -85, 85, 12, 7); circ(d, 85, 85, 12, 7)
def icon_Merger(d):
    circ(d, -34, 0, 62); circ(d, 34, 0, 62); poly(d, [(0, -22), (14, 0), (0, 22), (-14, 0)], 7)
def icon_Clock(d):
    circ(d, 0, 0, 92)
    for i in range(12):
        a = math.radians(i * 30); r0 = 74 if i % 3 else 66
        line(d, [(math.cos(a) * r0, math.sin(a) * r0), (math.cos(a) * 85, math.sin(a) * 85)], 6)
    line(d, [(0, 0), (0, -58)], 8); line(d, [(0, 0), (40, 18)], 8)
def icon_Mega(d):
    circ(d, 0, 0, 38)
    for i in range(12):
        a = math.radians(i * 30); r0, r1 = 56, (108 if i % 2 == 0 else 86)
        line(d, [(math.cos(a) * r0, math.sin(a) * r0), (math.cos(a) * r1, math.sin(a) * r1)], 8)
def icon_Discount(d):
    poly(d, [(-70, -90), (70, -90)], 9, False); arc(d, 0, -90, 70, 0, 180); line(d, [(0, -20), (0, 70)]); line(d, [(-48, 90), (48, 90)]); line(d, [(-30, 70), (30, 70)], 8)
def icon_Guard(d):
    circ(d, -48, -48, 34); line(d, [(-24, -24), (80, 80)]); line(d, [(48, 48), (28, 68)], 8); line(d, [(76, 76), (56, 96)], 8)
    circ(d, -48, -48, 10, 6)
def icon_Eye(d):
    arc(d, 0, 90, 150, 232, 308); arc(d, 0, -90, 150, 52, 128); circ(d, 0, 0, 32); dot(d, 0, 0, 12)
    for a in (-70, -35, 0, 35, 70):
        r = math.radians(a - 90); line(d, [(math.cos(r) * 78, math.sin(r) * 60 - 20), (math.cos(r) * 108, math.sin(r) * 92 - 20)], 6)
def icon_Learner(d):
    poly(d, [(0, -50), (-95, -70), (-95, 70), (0, 90)], 9, False); poly(d, [(0, -50), (95, -70), (95, 70), (0, 90)], 9, False); line(d, [(0, -50), (0, 90)], 7)
    for y in (-25, 5, 35): line(d, [(-75, y - 10), (-20, y + 2)], 5); line(d, [(75, y - 10), (20, y + 2)], 5)
def icon_Refund(d):
    arc(d, -10, 0, 90, 50, 310); arc(d, 30, 0, 72, 75, 285); star(d, 55, -50, 20, 4, 0.4, -90, 7)
def icon_Pity(d):
    poly(d, [(-60, -95), (60, -95)], 9, False); poly(d, [(-60, 95), (60, 95)], 9, False)
    poly(d, [(-50, -95), (50, -95), (6, 0), (50, 95), (-50, 95), (-6, 0)], 9)
    line(d, [(-22, 70), (22, 70)], 7)
def icon_Double(d):
    for cx in (-48, 48):
        poly(d, [(cx, -92), (cx + 36, -40), (cx + 36, 30), (cx, 95), (cx - 36, 30), (cx - 36, -40)], 8)
    line(d, [(-58, 10), (-40, -10), (-26, 12)], 6); line(d, [(38, -20), (56, 0), (70, -22)], 6)
def icon_Haste(d):
    poly(d, [(-85, 95), (-75, 25), (-25, -45), (85, -95), (55, -5), (-5, 55)], 9); line(d, [(-85, 95), (60, -75)], 7)
names = [k[5:] for k in globals() if k.startswith("icon_")]
sheet = Image.new("RGB", (N * 5, N * 4), (12, 11, 10))
for i, nm in enumerate(names):
    im, d = new(); globals()["icon_" + nm](d)
    im = im.resize((N, N), Image.LANCZOS)
    rgba = Image.new("RGBA", (N, N), (255, 255, 255, 0)); rgba.putalpha(im)
    rgba.save(os.path.join(OUT, nm + ".png"))
    t = Image.new("RGB", (N, N), (217, 184, 120)); sheet.paste(t, ((i % 5) * N, (i // 5) * N), im)
sheet.save(os.path.join(OUT, "_sheet.png")); print(len(names), names)
