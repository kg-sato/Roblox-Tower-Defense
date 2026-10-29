"""Draw a familiar design sheet (front, side and back turnaround, palette) and a silhouette test strip.

Usage: python tools/familiar_sheet.py ember
Output: Roblox Dev/Assets/Characters/Design Sheets/<Name>_sheet.png, <Name>_silhouette.png, <Name>_report.txt
Only Ember is defined so far (T075); add a function per familiar and register it in FAMILIARS.
Pure Pillow, no network, no model: shapes are drawn by code so the three views stay consistent.
"""
import math, sys, pathlib
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"
S = 3  # supersampling factor

INK = (36, 26, 20)
BRASS = (201, 162, 75)
BRASS_DARK = (122, 92, 38)
VERDI = (67, 179, 174)
FLAME_OUT = (213, 94, 0)
FLAME_MID = (230, 159, 0)
FLAME_CORE = (255, 232, 140)


def flame_points(cx, base_y, h, w, lean=0.0, curl=0.0, steps=48):
    """Outline of a teardrop flame, base at base_y, tip above. lean bends the whole flame, curl flicks the tip."""
    left, right = [], []
    for i in range(steps + 1):
        t = i / steps
        half = 0.5 * w * (math.sin(math.pi * (t ** 0.7)) ** 0.9) * (1 - t) ** 0.25
        x = cx + lean * h * t * t + curl * h * t ** 4
        y = base_y - h * t
        left.append((x - half, y))
        right.append((x + half, y))
    return left + right[::-1]


def ember_view(d, ox, oy, view, colour=True):
    """Draw Ember at origin (ox, oy = base centre) in the given view. Sizes are sheet pixels before zoom.
    Design: a teardrop flame on a small brass oil-lamp body (belly, spout and ring handle), with two detached sparks.
    Deliberately not a flame in a flower pot with leaf-like arms: that would read as a sprout (banned in the plan)."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    h, w = 150, 84
    if view == "front":
        lean, curl, spark = 0.02, 0.10, [(-62, 0.30), (58, 0.26)]
    elif view == "side":
        lean, curl, spark = 0.14, -0.18, [(40, 0.30)]
    else:
        lean, curl, spark = -0.02, 0.12, [(-62, 0.30), (58, 0.26)]
    ww = w if view != "side" else w * 0.78
    base_y = oy - 40
    # sparks: detached small teardrops at shoulder height, not attached to the body
    for dx, al in spark:
        pts = flame_points(ox + dx, base_y - h * 0.46, 26, 16, lean=al, curl=0.1 * (1 if al > 0 else -1))
        d.polygon(pts, fill=c(FLAME_MID), outline=c(INK) if colour else None)
    body = flame_points(ox, base_y, h, ww, lean=lean, curl=curl)
    d.polygon(body, fill=c(FLAME_OUT), outline=c(INK) if colour else None)
    if colour:
        d.polygon(flame_points(ox + 2, base_y - 6, h * 0.72, ww * 0.62, lean=lean * 0.8, curl=curl * 0.5), fill=FLAME_MID)
        d.polygon(flame_points(ox + 4, base_y - 12, h * 0.42, ww * 0.34, lean=lean * 0.5), fill=FLAME_CORE)
    # oil-lamp body: belly, foot, spout and ring handle
    bw = 82 if view != "side" else 58
    belly = [ox - bw / 2, oy - 46, ox + bw / 2, oy - 6]
    sdir = -1 if view == "front" else 1  # spout side: left in the front view, right in the side and back views
    hdir = -sdir
    hx = ox + hdir * (bw / 2 + 6)
    d.arc([hx - 14, oy - 40, hx + 14, oy - 8], 0, 360, fill=c(BRASS_DARK), width=6)
    sx = ox + sdir * (bw / 2 - 2)
    d.polygon([(sx, oy - 34), (sx + sdir * 26, oy - 40), (sx + sdir * 26, oy - 33), (sx, oy - 20)], fill=c(BRASS), outline=c(INK) if colour else None)
    d.polygon([(ox - bw * 0.3, oy - 11), (ox + bw * 0.3, oy - 11), (ox + bw * 0.22, oy + 8), (ox - bw * 0.22, oy + 8)], fill=c(BRASS_DARK), outline=c(INK) if colour else None)
    d.ellipse(belly, fill=c(BRASS))
    d.rectangle([ox - bw * 0.28, oy - 50, ox + bw * 0.28, oy - 42], fill=c(BRASS_DARK))
    if colour:
        d.line([(ox - bw / 2 + 12, oy - 28), (ox - bw / 4, oy - 12)], fill=VERDI, width=3)
        if view == "back":
            d.ellipse([ox - 4, oy - 34, ox + 4, oy - 26], fill=INK)
            d.polygon([(ox - 2, oy - 29), (ox + 2, oy - 29), (ox + 4, oy - 18), (ox - 4, oy - 18)], fill=INK)
    if colour and view in ("front", "side"):
        ey = base_y - h * 0.42
        ex = ox + (lean * h * 0.42 ** 2)
        spread = 17 if view == "front" else 10
        eyes = [ex - spread, ex + spread] if view == "front" else [ex + 9]
        for x in eyes:
            d.ellipse([x - 7, ey - 8, x + 7, ey + 8], fill=INK)
            d.ellipse([x - 3, ey - 5, x + 1, ey - 1], fill=(255, 255, 255))
        mx = ex if view == "front" else ex + 12
        d.arc([mx - 8, ey + 10, mx + 8, ey + 24], 20, 160, fill=INK, width=3)


STONE = (140, 142, 152)
STONE_DARK = (92, 94, 106)
STONE_LIGHT = (184, 186, 196)
SKY = (86, 180, 233)
GLOW = (200, 236, 255)


def gargoyle_view(d, ox, oy, view, colour=True):
    """Gargoyle (T076): a crouched stone watcher on a plinth, folded wings, two horns, a heavy brow, a tail and a sky-blue scarf.
    Wide and low on purpose: the opposite proportions to Ember's tall flame."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    bw = 46 if not side else 34  # half width of the body
    # wings folded up behind the shoulders (drawn first)
    if view in ("front", "back"):
        wings = [[(ox - 34, oy - 84), (ox - 84, oy - 158), (ox - 14, oy - 100)], [(ox + 34, oy - 84), (ox + 84, oy - 158), (ox + 14, oy - 100)]]
    else:
        wings = [[(ox - 10, oy - 84), (ox - 66, oy - 156), (ox + 14, oy - 100)]]
    for wpts in wings:
        d.polygon(wpts, fill=c(STONE_DARK), outline=ink)
    # tail: a thick curl off the plinth
    tail = [(ox + bw - 4, oy - 12), (ox + bw + 22, oy - 8), (ox + bw + 34, oy - 26), (ox + bw + 26, oy - 40)]
    if side:
        tail = [(ox - bw + 4, oy - 12), (ox - bw - 22, oy - 8), (ox - bw - 34, oy - 30), (ox - bw - 26, oy - 48)]
    d.line(tail, fill=c(STONE_DARK), width=9)
    # plinth
    d.polygon([(ox - 62, oy - 12), (ox + 62, oy - 12), (ox + 68, oy + 10), (ox - 68, oy + 10)], fill=c(STONE_DARK), outline=ink)
    d.rectangle([ox - 60, oy - 18, ox + 60, oy - 10], fill=c(STONE_LIGHT if colour else STONE))
    # hunched body
    body = [(ox - bw + 2, oy - 14), (ox - bw - 8, oy - 62), (ox - bw + 14, oy - 98), (ox + bw - 14, oy - 98), (ox + bw + 8, oy - 62), (ox + bw - 2, oy - 14)]
    d.polygon(body, fill=c(STONE), outline=ink)
    # forearms planted forward with round fists
    arm_x = [ox - bw + 4, ox + bw - 4] if not side else [ox + 4]
    for ax in arm_x:
        d.rectangle([ax - 11, oy - 64, ax + 11, oy - 22], fill=c(STONE_LIGHT if colour else STONE))
        d.ellipse([ax - 15, oy - 30, ax + 15, oy - 8], fill=c(STONE_LIGHT if colour else STONE))
    # head
    hx = ox if not side else ox + 14
    d.ellipse([hx - 32, oy - 140, hx + 32, oy - 86], fill=c(STONE))
    # horns
    for sgn in ([-1, 1] if not side else [1]):
        d.polygon([(hx + sgn * 28, oy - 124), (hx + sgn * 40, oy - 168), (hx + sgn * 10, oy - 130)], fill=c(STONE_DARK), outline=ink)
    scarf_tail_x = ox + 22 if view != "side" else ox - 8
    if colour:
        # scarf: a band at the neck with a tail hanging down the front (front, side) or back (back)
        d.polygon([(ox - 34, oy - 98), (ox + 34, oy - 98), (ox + 38, oy - 84), (ox - 38, oy - 84)], fill=SKY, outline=INK)
        d.polygon([(scarf_tail_x - 8, oy - 86), (scarf_tail_x + 10, oy - 86), (scarf_tail_x + 12, oy - 40), (scarf_tail_x - 4, oy - 44)], fill=SKY, outline=INK)
        d.line([(scarf_tail_x - 6, oy - 70), (scarf_tail_x + 10, oy - 68)], fill=(255, 255, 255), width=2)
    else:
        d.polygon([(ox - 34, oy - 98), (ox + 34, oy - 98), (ox + 38, oy - 84), (ox - 38, oy - 84)], fill=(0, 0, 0))
        d.polygon([(scarf_tail_x - 8, oy - 86), (scarf_tail_x + 10, oy - 86), (scarf_tail_x + 12, oy - 40), (scarf_tail_x - 4, oy - 44)], fill=(0, 0, 0))
    # face (front and side): heavy brow, small glowing eyes, flat mouth with two small fangs
    if colour and view in ("front", "side"):
        ey = oy - 118
        eyes = [hx - 13, hx + 13] if view == "front" else [hx + 12]
        d.rectangle([hx - 28 if view == "front" else hx - 6, ey - 12, hx + 28, ey - 4], fill=STONE_DARK)
        for x in eyes:
            d.ellipse([x - 6, ey - 4, x + 6, ey + 6], fill=GLOW)
            d.ellipse([x - 2, ey - 2, x + 2, ey + 2], fill=INK)
        mx = hx if view == "front" else hx + 14
        d.line([(mx - 12, oy - 98), (mx + 12, oy - 98)], fill=INK, width=3)
        d.polygon([(mx - 8, oy - 98), (mx - 4, oy - 98), (mx - 6, oy - 90)], fill=(255, 255, 255))
        d.polygon([(mx + 4, oy - 98), (mx + 8, oy - 98), (mx + 6, oy - 90)], fill=(255, 255, 255))
    if colour and view == "back":
        # carved crack down the back, a small chip, and a cut in the plinth
        d.line([(ox, oy - 96), (ox + 6, oy - 70), (ox - 4, oy - 44)], fill=STONE_DARK, width=2)


ICE = (158, 212, 240)
ICE_DARK = (88, 150, 200)
FROST_WHITE = (242, 250, 255)
MITT = (204, 121, 167)


def frostling_view(d, ox, oy, view, colour=True):
    """Frostling (T077): a small round child of frost in a pointed hood, with a jagged icicle hem, round mittens and stubby feet.
    Round and soft on purpose: a bell shape with one flicked hood tip, the opposite of Gargoyle's spiky bulk and Ember's tall flame."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    bw = 52 if not side else 38  # half width of the body
    # feet
    for fx in ([-20, 20] if not side else [-8, 14]):
        d.ellipse([ox + fx - 13, oy - 4, ox + fx + 13, oy + 12], fill=c(ICE_DARK))
    # body: a bell (rounded top, wider hem) with a jagged icicle hem
    d.ellipse([ox - bw, oy - 112, ox + bw, oy - 8], fill=c(ICE), outline=None)
    hem = []
    n = 7
    for i in range(n):
        x0 = ox - bw + i * (2 * bw / n)
        x1 = ox - bw + (i + 1) * (2 * bw / n)
        hem += [(x0, oy - 20), ((x0 + x1) / 2, oy + (6 if i % 2 else 0)), (x1, oy - 20)]
    d.polygon(hem, fill=c(ICE), outline=ink)
    # arms with round mittens
    mitts = [(-1, -62, -58), (1, 62, -58)] if not side else [(1, 36, -64)]
    for sgn, mx, my in mitts:
        d.line([(ox + sgn * (bw - 14), oy - 76), (ox + mx, oy + my)], fill=c(ICE_DARK), width=14)
        d.ellipse([ox + mx - 14, oy + my - 14, ox + mx + 14, oy + my + 14], fill=c(MITT), outline=None)
    # frost collar: small crystals around the neck
    cx = ox if not side else ox + 6
    for i in range(-3, 4):
        d.polygon([(cx + i * 11 - 6, oy - 100), (cx + i * 11 + 6, oy - 100), (cx + i * 11, oy - 114)], fill=c(FROST_WHITE if colour else (0, 0, 0)), outline=ink)
    # head: a round face under a pointed hood
    hx = ox if not side else ox + 8
    d.ellipse([hx - 38, oy - 160, hx + 38, oy - 92], fill=c(ICE_DARK))
    # pointed hood: a cone over the head with the tip flicked to one side (backwards in the side view)
    if view != "side":
        hood_tip = [(hx - 38, oy - 120), (hx - 32, oy - 160), (hx - 16, oy - 184), (hx - 48, oy - 216), (hx + 6, oy - 190), (hx + 32, oy - 160), (hx + 38, oy - 120)]
        bx, by = hx - 48, oy - 216
    else:
        hood_tip = [(hx - 34, oy - 120), (hx - 30, oy - 160), (hx - 18, oy - 184), (hx - 60, oy - 200), (hx + 2, oy - 192), (hx + 28, oy - 160), (hx + 30, oy - 120)]
        bx, by = hx - 60, oy - 200
    d.polygon(hood_tip, fill=c(ICE_DARK), outline=ink)
    # bobble on the hood tip
    d.ellipse([bx - 9, by - 9, bx + 9, by + 9], fill=c(FROST_WHITE if colour else (0, 0, 0)))
    if colour and view in ("front", "side"):
        # face opening
        d.ellipse([hx - 26, oy - 148, hx + 26, oy - 104] if view == "front" else [hx - 6, oy - 148, hx + 26, oy - 104], fill=FROST_WHITE)
        eyes = [hx - 11, hx + 11] if view == "front" else [hx + 14]
        for x in eyes:
            d.ellipse([x - 6, oy - 134, x + 6, oy - 120], fill=INK)
            d.ellipse([x - 3, oy - 131, x + 1, oy - 127], fill=(255, 255, 255))
        for x in ([hx - 20, hx + 20] if view == "front" else [hx + 20]):
            d.ellipse([x - 5, oy - 120, x + 5, oy - 113], fill=(244, 170, 190))
        d.arc([hx - 7 if view == "front" else hx + 8, oy - 118, hx + 7 if view == "front" else hx + 22, oy - 106], 20, 160, fill=INK, width=3)
    elif colour and view == "back":
        # a snowflake mark on the back of the body
        for ang in range(0, 180, 60):
            a = math.radians(ang)
            d.line([(ox - 16 * math.cos(a), oy - 62 - 16 * math.sin(a)), (ox + 16 * math.cos(a), oy - 62 + 16 * math.sin(a))], fill=FROST_WHITE, width=3)
    if colour:
        # frost shine on the body
        d.arc([ox - bw + 10, oy - 100, ox - 6, oy - 40], 200, 280, fill=FROST_WHITE, width=4)


INDIGO = (30, 42, 120)
INDIGO_LIGHT = (52, 84, 170)
STAR_WHITE = (245, 247, 255)
STAR_GOLD = (240, 192, 64)


def _star(d, x, y, r, fill):
    pts = []
    for i in range(8):
        a = math.pi / 4 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.38
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    d.polygon(pts, fill=fill)


def star_drake_view(d, ox, oy, view, colour=True):
    """Star Drake (T078): a long sinuous constellation-serpent with two spread star-fan wings, a crowned head and a star at the tail.
    Tall, thin and S-curved on purpose: the longest, most flowing shape in the cast, against Ember's teardrop, Gargoyle's block and Frostling's bell."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    amp = 34 if view != "side" else 58
    top = 168

    def at(t):
        # centre line of the body from tail (t=0, bottom) to head (t=1, top): an S-curve that sways more in the side view
        x = ox + amp * math.sin(2 * math.pi * (t * 1.15 + 0.05)) * (1 - 0.25 * t)
        y = oy - 14 - t * top
        return x, y

    def radius(t):
        if t < 0.15:
            return 4 + 70 * t * 0.9  # thin tail grows
        if t < 0.75:
            return 14 + 4 * math.sin(math.pi * (t - 0.15) / 0.6)
        return 14 - 22 * (t - 0.75)  # neck narrows to the head

    # wings (drawn first, behind the body), attached at t = 0.66
    wx, wy = at(0.66)
    sgns = [-1, 1] if view != "side" else [1]
    for sgn in sgns:
        span = 76 if view != "side" else 62
        wing = [(wx, wy), (wx + sgn * span, wy - 78), (wx + sgn * (span - 30), wy - 38), (wx + sgn * (span + 10), wy - 30),
                (wx + sgn * (span - 22), wy - 4), (wx + sgn * (span - 6), wy + 26), (wx + sgn * 36, wy + 8)]
        d.polygon(wing, fill=c(INDIGO_LIGHT), outline=c(INK) if colour else None)
        if colour:
            for tip in [(span, -78), (span + 10, -30), (span - 6, 26)]:
                d.line([(wx, wy), (wx + sgn * tip[0], wy + tip[1])], fill=STAR_WHITE, width=2)
                _star(d, wx + sgn * tip[0], wy + tip[1], 7, STAR_GOLD)
    # body: a chain of circles along the centre line, outline first then fill
    steps = 70
    if colour:
        for i in range(steps + 1):
            t = i / steps
            x, y = at(t)
            r = radius(t)
            d.ellipse([x - r - 2, y - r - 2, x + r + 2, y + r + 2], fill=INK)
    for i in range(steps + 1):
        t = i / steps
        x, y = at(t)
        r = radius(t)
        d.ellipse([x - r, y - r, x + r, y + r], fill=c(INDIGO))
    # tail star
    tx, ty = at(0.0)
    _star(d, tx, ty + 6, 20, c(STAR_GOLD))
    # head: a rounded wedge with swept-back horns and a three-star crown
    hx, hy = at(1.0)
    if view == "side":
        head = [(hx - 10, hy + 8), (hx + 8, hy - 16), (hx + 38, hy - 6), (hx + 40, hy + 6), (hx + 8, hy + 14)]
        horns = [[(hx - 6, hy - 2), (hx - 46, hy - 24), (hx - 2, hy - 18)], [(hx + 4, hy - 8), (hx - 30, hy - 46), (hx + 12, hy - 20)]]
    else:
        head = [(hx - 22, hy + 6), (hx - 14, hy - 18), (hx + 14, hy - 18), (hx + 22, hy + 6), (hx, hy + 22)]
        horns = [[(hx - 16, hy - 12), (hx - 52, hy - 32), (hx - 22, hy - 4)], [(hx + 16, hy - 12), (hx + 52, hy - 32), (hx + 22, hy - 4)]]
    for h in horns:
        d.polygon(h, fill=c(INDIGO_LIGHT), outline=c(INK) if colour else None)
    d.polygon(head, fill=c(INDIGO), outline=c(INK) if colour else None)
    for k, dx in enumerate([-16, 0, 16]):
        _star(d, hx + dx + (6 if view == "side" else 0), hy - 28 - (6 if k == 1 else 0), 8 if k == 1 else 6, c(STAR_GOLD))
    if colour and view in ("front", "side"):
        eyes = [hx - 9, hx + 9] if view == "front" else [hx + 24]
        for ex in eyes:
            d.ellipse([ex - 4, hy - 4, ex + 4, hy + 2], fill=STAR_WHITE)
    if colour:
        # constellation nodes: small stars along the body joined by thin lines
        prev = None
        for t in (0.12, 0.28, 0.45, 0.60, 0.80):
            x, y = at(t)
            if prev:
                d.line([prev, (x, y)], fill=STAR_WHITE, width=1)
            _star(d, x, y, 5, STAR_WHITE)
            prev = (x, y)


SENT_VERDI = (0, 158, 115)
SENT_AMBER = (230, 159, 0)


def _gear(d, x, y, r, teeth, fill, ink=None, hole=None):
    pts = []
    for i in range(teeth * 2):
        a = math.pi * i / teeth
        rr = r if i % 2 == 0 else r * 0.78
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    d.polygon(pts, fill=fill, outline=ink)
    if hole:
        d.ellipse([x - r * 0.3, y - r * 0.3, x + r * 0.3, y + r * 0.3], fill=hole)


def sentinel_view(d, ox, oy, view, colour=True):
    """Sentinel (T079): a stiff brass Foundry guard in a domed helmet with a brim and spike, round gear pauldrons, a chest gear,
    a halberd and a winding key on its back. Straight lines and a tall helmet on purpose, with the key and halberd breaking the box."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    hw = 34 if not side else 22  # half width of the torso at the shoulders
    # winding key on the back (drawn first so the body overlaps its shaft); on the left in side view, centred in back view
    if view in ("side", "back"):
        kx = ox - 24 if side else ox
        ky = oy - 108
        d.rectangle([kx - 3, ky - 4, kx + 3, ky + 30], fill=c(BRASS_DARK))
        d.line([(kx - 20, ky - 10), (kx + 20, ky - 10)], fill=c(BRASS), width=8)
        d.ellipse([kx - 26, ky - 18, kx - 12, ky - 4], fill=c(BRASS))
        d.ellipse([kx + 12, ky - 18, kx + 26, ky - 4], fill=c(BRASS))
    # halberd (right side of the figure; centred forward in the side view)
    px = ox + 62 if not side else ox + 30
    d.line([(px, oy - 6), (px, oy - 200)], fill=c(BRASS_DARK), width=5)
    d.polygon([(px, oy - 196), (px + 26, oy - 186), (px + 22, oy - 160), (px, oy - 168)], fill=c(BRASS), outline=ink)
    d.polygon([(px, oy - 200), (px - 5, oy - 212), (px + 5, oy - 212)], fill=c(BRASS), outline=ink)
    # legs and feet
    for lx in ([-16, 16] if not side else [-6, 8]):
        d.rectangle([ox + lx - 9, oy - 70, ox + lx + 9, oy - 12], fill=c(BRASS_DARK), )
        d.rectangle([ox + lx - 13, oy - 12, ox + lx + 15, oy + 4], fill=c(BRASS), )
    # pelvis and torso
    d.rectangle([ox - hw + 8, oy - 88, ox + hw - 8, oy - 68], fill=c(BRASS_DARK))
    torso = [(ox - hw + 6, oy - 86), (ox + hw - 6, oy - 86), (ox + hw + 6, oy - 138), (ox - hw - 6, oy - 138)]
    d.polygon(torso, fill=c(BRASS), outline=ink)
    # arms
    for ax in ([-(hw + 10), hw + 10] if not side else [4]):
        d.rectangle([ox + ax - 7, oy - 132, ox + ax + 7, oy - 80], fill=c(BRASS_DARK))
        d.ellipse([ox + ax - 9, oy - 86, ox + ax + 9, oy - 70], fill=c(BRASS))
    # gear pauldrons
    for sx in ([-(hw + 6), hw + 6] if not side else [4]):
        _gear(d, ox + sx, oy - 136, 15, 8, c(BRASS_DARK), ink, c(BRASS) if colour else None)
    # chest gear (front) or winding hole plate (back)
    if view != "back":
        _gear(d, ox + (0 if not side else 4), oy - 112, 13, 10, c(SENT_VERDI if colour else (0, 0, 0)), ink, c(BRASS_DARK) if colour else None)
    elif colour:
        d.rectangle([ox - 10, oy - 124, ox + 10, oy - 96], fill=BRASS_DARK)
    # head: domed helmet with brim and spike
    hx = ox if not side else ox + 4
    d.ellipse([hx - 20, oy - 182, hx + 20, oy - 142], fill=c(BRASS), outline=None)
    d.polygon([(hx - 4, oy - 180), (hx + 4, oy - 180), (hx, oy - 200)], fill=c(BRASS_DARK), outline=ink)
    d.rectangle([hx - 27, oy - 150, hx + 27, oy - 143], fill=c(BRASS_DARK))
    d.rectangle([hx - 15, oy - 143, hx + 15, oy - 136], fill=c(BRASS))
    if colour and view in ("front", "side"):
        vx0, vx1 = (hx - 12, hx + 12) if view == "front" else (hx + 2, hx + 16)
        d.rectangle([vx0, oy - 166, vx1, oy - 160], fill=SENT_AMBER)
    if colour:
        d.line([(ox - hw + 12, oy - 98), (ox - hw + 12, oy - 128)], fill=(255, 255, 255), width=2)


COAT = (84, 108, 132)
COAT_DARK = (54, 72, 94)
GLASS = (176, 226, 236)
LAMP_GLOW = (255, 214, 110)
SKIN = (222, 196, 170)


def ward_view(d, ox, oy, view, colour=True):
    """Ward (T080): a human lighthouse keeper in a long oilskin coat and a wide-brimmed sou'wester, carrying a glass lantern at hip height.
    Humanoid. Cone coat, wide hat brim and one big lantern at the side, so it differs from the boxy Sentinel with its tall halberd."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    ls = -1 if view in ("front",) else 1  # the lantern hangs on the viewer's left in front view, forward (right) in side view, mirrored in back view
    if view == "back":
        ls = 1
    # boots
    for bx in ([-12, 12] if not side else [-6, 12]):
        d.ellipse([ox + bx - 11, oy - 8, ox + bx + 11, oy + 8], fill=c(COAT_DARK))
    # coat: a long A-line cone, flared at the hem
    hem = 46 if not side else 34
    sh = 22 if not side else 16
    coat = [(ox - sh, oy - 132), (ox + sh, oy - 132), (ox + hem, oy - 6), (ox - hem, oy - 6)]
    d.polygon(coat, fill=c(COAT), outline=ink)
    if colour:
        d.polygon([(ox - hem, oy - 14), (ox + hem, oy - 14), (ox + hem + 2, oy - 6), (ox - hem - 2, oy - 6)], fill=COAT_DARK)
        if view != "back":
            for by in (-110, -88, -66):
                d.ellipse([ox - 3, oy + by - 3, ox + 3, oy + by + 3], fill=BRASS)
        else:
            d.line([(ox, oy - 126), (ox, oy - 12)], fill=COAT_DARK, width=3)
    # collar flaps
    d.polygon([(ox - sh - 4, oy - 134), (ox - 4, oy - 138), (ox - 6, oy - 120)], fill=c(COAT_DARK), outline=ink)
    d.polygon([(ox + sh + 4, oy - 134), (ox + 4, oy - 138), (ox + 6, oy - 120)], fill=c(COAT_DARK), outline=ink)
    # free arm (the other side), tucked
    far = -ls
    d.line([(ox + far * (sh - 2), oy - 126), (ox + far * (sh + 8), oy - 80)], fill=c(COAT_DARK), width=11)
    # lantern arm and lantern at hip height
    sx = ox + ls * (sh - 2)
    hx = ox + ls * (sh + 26 if not side else sh + 30)
    d.line([(sx, oy - 126), (hx, oy - 84)], fill=c(COAT_DARK), width=11)
    d.ellipse([hx - 7, oy - 90, hx + 7, oy - 76], fill=c(SKIN))
    d.line([(hx, oy - 82), (hx, oy - 62)], fill=c(BRASS_DARK), width=3)  # the chain
    lx0, lx1 = hx - 15, hx + 15
    d.rectangle([lx0 - 2, oy - 64, lx1 + 2, oy - 58], fill=c(BRASS))
    d.rectangle([lx0, oy - 58, lx1, oy - 24], fill=c(GLASS))
    d.rectangle([lx0 - 2, oy - 26, lx1 + 2, oy - 20], fill=c(BRASS))
    if colour:
        d.polygon([(hx, oy - 54), (hx + 7, oy - 40), (hx, oy - 30), (hx - 7, oy - 40)], fill=LAMP_GLOW)
        d.line([(lx0 + 4, oy - 54), (lx0 + 4, oy - 30)], fill=(255, 255, 255), width=2)
    # head and hat
    hdx = ox if not side else ox + 4
    d.ellipse([hdx - 14, oy - 156, hdx + 14, oy - 124], fill=c(SKIN))
    brim = [(hdx - 36, oy - 150), (hdx + 36, oy - 150), (hdx + 28, oy - 142), (hdx - 28, oy - 142)]
    if side:
        brim = [(hdx - 46, oy - 148), (hdx + 24, oy - 154), (hdx + 24, oy - 146), (hdx - 40, oy - 138)]  # the brim sweeps back in profile
    d.polygon(brim, fill=c(COAT_DARK), outline=ink)
    d.ellipse([hdx - 18, oy - 176, hdx + 18, oy - 148], fill=c(COAT_DARK))
    if colour and view in ("front", "side"):
        eyes = [hdx - 6, hdx + 6] if view == "front" else [hdx + 8]
        for ex in eyes:
            d.ellipse([ex - 2.5, oy - 140, ex + 2.5, oy - 134], fill=INK)
        d.line([(hdx - 4 if view == "front" else hdx + 4, oy - 128), (hdx + 4 if view == "front" else hdx + 12, oy - 128)], fill=INK, width=2)


ROBE = (0, 114, 178)
ROBE_DARK = (0, 70, 120)
SILVER = (206, 214, 228)
MIRROR_SHINE = (255, 255, 255)


def mirror_chorister_view(d, ox, oy, view, colour=True):
    """Mirror Chorister (T081): a robed Star Choir singer, humanoid, whose face is a round mirror under a hood with two cat ears
    (a nod to the mirror-cat in the task list). A slim robe with wide bell sleeves raised in song, so it reads as a Y on a column."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    sh = 17 if not side else 13
    hem = 30 if not side else 22
    # robe
    d.polygon([(ox - sh, oy - 130), (ox + sh, oy - 130), (ox + hem, oy - 4), (ox - hem, oy - 4)], fill=c(ROBE), outline=ink)
    if colour:
        d.polygon([(ox - hem, oy - 14), (ox + hem, oy - 14), (ox + hem + 1, oy - 4), (ox - hem - 1, oy - 4)], fill=SILVER)
        if view != "back":
            d.polygon([(ox - sh, oy - 126), (ox - sh + 8, oy - 126), (ox + sh, oy - 70), (ox + sh - 8, oy - 70)], fill=STAR_WHITE)
        else:
            d.polygon([(ox - 6, oy - 124), (ox + 6, oy - 124), (ox + 10, oy - 40), (ox - 10, oy - 40)], fill=ROBE_DARK)
    # feet
    for bx in ([-9, 9] if not side else [-3, 9]):
        d.ellipse([ox + bx - 8, oy - 6, ox + bx + 8, oy + 6], fill=c(ROBE_DARK))
    # raised bell sleeves
    sides = [-1, 1] if not side else [1]
    for s in sides:
        sx = ox + s * (sh - 2)
        reach = 58 if not side else 44
        sleeve = [(sx, oy - 126), (sx + s * reach, oy - 176), (sx + s * (reach + 14), oy - 152), (sx + s * 26, oy - 106)]
        d.polygon(sleeve, fill=c(ROBE), outline=ink)
        if colour:
            d.polygon([(sx + s * reach, oy - 176), (sx + s * (reach + 14), oy - 152), (sx + s * (reach + 9), oy - 148), (sx + s * (reach - 3), oy - 170)], fill=SILVER)
        d.ellipse([sx + s * (reach + 2) - 7, oy - 184, sx + s * (reach + 2) + 7, oy - 170], fill=c(SKIN))
    # hood with two cat ears
    hx = ox if not side else ox + 3
    d.ellipse([hx - 21, oy - 178, hx + 21, oy - 130], fill=c(ROBE_DARK))
    ears = [(-1, 1)] if False else ([-1, 1] if not side else [-1, 1])
    for s in ears:
        d.polygon([(hx + s * 6, oy - 170), (hx + s * 22, oy - 172), (hx + s * 18, oy - 200)] if not side else [(hx + s * 4 - 2, oy - 170), (hx + s * 18, oy - 170), (hx + s * 12 - 2, oy - 198)], fill=c(ROBE_DARK), outline=ink)
    # mirror face
    if view in ("front", "side"):
        mw = 14 if view == "front" else 7
        mx = hx if view == "front" else hx + 8
        d.ellipse([mx - mw, oy - 174, mx + mw, oy - 138], fill=c(SILVER))
        if colour:
            d.ellipse([mx - mw + 3, oy - 170, mx - mw + 9, oy - 160], fill=MIRROR_SHINE)
            if view == "front":
                _star(d, mx + 3, oy - 150, 5, STAR_GOLD)
    elif colour:
        d.line([(hx - 12, oy - 140), (hx + 12, oy - 140)], fill=SILVER, width=3)


ARCH_COAT = (22, 92, 90)
ARCH_COAT_DARK = (14, 60, 62)
ARCH_LENS = (170, 232, 236)
LEDGER = (120, 78, 50)


def archivist_view(d, ox, oy, view, colour=True):
    """Archivist (T082): the Guild's memory keeper, a stooped humanoid clockwork scribe in an owl mask (big lens eyes, beak, ear tufts)
    and a scalloped feather mantle, holding a ledger on thin legs. Egg-shaped body on stilts with a wide mantle, so it differs from the
    cone-coated Ward and the bell-shaped Frostling."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    bw = 40 if not side else 28
    # thin legs and big feet
    for lx in ([-12, 12] if not side else [-4, 10]):
        d.line([(ox + lx, oy - 50), (ox + lx, oy - 8)], fill=c(BRASS_DARK), width=6)
        d.polygon([(ox + lx - 14, oy), (ox + lx + 14, oy), (ox + lx + 8, oy - 10), (ox + lx - 8, oy - 10)], fill=c(BRASS), outline=ink)
    # back gear (back view) drawn behind the body is not needed; draw body first
    d.ellipse([ox - bw, oy - 138, ox + bw, oy - 44], fill=c(ARCH_COAT), outline=None)
    # scalloped hem of the coat
    for i in range(-3, 4):
        d.ellipse([ox + i * (bw * 0.28) - 8, oy - 54, ox + i * (bw * 0.28) + 8, oy - 38], fill=c(ARCH_COAT_DARK))
    # feather mantle: two scalloped tiers across the shoulders, spread outward
    for tier, (yy, wd) in enumerate([(-124, 58), (-104, 52), (-84, 44)]):
        wd2 = wd if not side else wd * 0.62
        d.polygon([(ox - wd2, oy + yy), (ox + wd2, oy + yy), (ox + wd2 - 6, oy + yy + 18), (ox + wd2 - 20, oy + yy + 12), (ox + wd2 - 34, oy + yy + 20), (ox - wd2 + 34, oy + yy + 20), (ox - wd2 + 20, oy + yy + 12), (ox - wd2 + 6, oy + yy + 18)], fill=c(BRASS if tier % 2 == 0 else BRASS_DARK), outline=ink)
    if view == "back" and colour:
        # a big winding cog on the back
        _gear(d, ox, oy - 80, 20, 10, BRASS_DARK, INK, BRASS)
    # ledger held at the chest (front and side)
    if view != "back":
        lx0, lx1 = (ox - 22, ox + 22) if not side else (ox + 6, ox + 32)
        d.rectangle([lx0, oy - 98, lx1, oy - 62], fill=c(LEDGER))
        if colour:
            d.rectangle([lx0 + 3, oy - 95, lx1 - 3, oy - 65], fill=(238, 226, 196))
            for yy in (-90, -82, -74):
                d.line([(lx0 + 7, oy + yy), (lx1 - 7, oy + yy)], fill=(150, 130, 100), width=1)
        for hx_ in ([lx0 - 2, lx1 + 2] if not side else [lx0 + 2]):
            d.ellipse([hx_ - 6, oy - 84, hx_ + 6, oy - 72], fill=c(BRASS))
    # pocket watch on a chain
    if colour and view != "back":
        d.line([(ox - bw + 10, oy - 112), (ox - bw + 4, oy - 78)], fill=BRASS_DARK, width=2)
        d.ellipse([ox - bw - 4, oy - 78, ox - bw + 12, oy - 62], fill=BRASS, outline=None)
        d.line([(ox - bw + 4, oy - 70), (ox - bw + 4, oy - 76)], fill=INK, width=2)
    # head: a large round owl mask with ear tufts, lens eyes and a beak
    hx = ox if not side else ox + 4
    d.ellipse([hx - 30, oy - 190, hx + 30, oy - 132], fill=c(BRASS))
    for s in ([-1, 1] if not side else [-1, 1]):
        d.polygon([(hx + s * 10, oy - 184), (hx + s * 28, oy - 188), (hx + s * 26, oy - 212)] if not side else [(hx + s * 6 - 2, oy - 184), (hx + s * 22, oy - 188), (hx + s * 18 - 2, oy - 210)], fill=c(BRASS_DARK), outline=ink)
    if view in ("front", "side"):
        eyes = [hx - 14, hx + 14] if view == "front" else [hx + 12]
        for ex in eyes:
            d.ellipse([ex - 13, oy - 176, ex + 13, oy - 150], fill=c(ARCH_LENS if colour else (255, 255, 255)))
            if colour:
                _gear(d, ex, oy - 163, 8, 8, BRASS_DARK, None, ARCH_LENS)
                d.ellipse([ex - 2, oy - 165, ex + 2, oy - 161], fill=INK)
        bx = hx if view == "front" else hx + 26
        d.polygon([(bx - 6, oy - 156), (bx + 6, oy - 156), (bx + (0 if view == "front" else 8), oy - 138)], fill=c(BRASS_DARK), outline=ink)
    elif colour:
        d.arc([hx - 20, oy - 180, hx + 20, oy - 140], 200, 340, fill=BRASS_DARK, width=3)


MOURN_COAT = (62, 66, 82)
MOURN_COAT_DARK = (38, 40, 54)
VEIL = (176, 190, 212)
BONE = (236, 232, 224)
LILY = (250, 250, 246)


def mourner_view(d, ox, oy, view, colour=True):
    """Mourner (T083): a very tall, narrow humanoid in a long mourning coat and a hooded veil, with a blank bone-white face (it gave its face
    away), head bowed, hands clasped on a white lily. The veil falls behind as a long train. The tallest, narrowest figure among the people."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    bow = 8 if side else 0  # the head and shoulders lean forward in profile
    sh = 18 if not side else 13
    hem = 30 if not side else 22
    # veil train behind (side and back views show it most; in front it frames the figure)
    if side:
        d.polygon([(ox - 6, oy - 182), (ox - 46, oy - 8), (ox + 2, oy - 8), (ox + 4, oy - 120)], fill=c(VEIL), outline=ink)
    elif view == "back":
        d.polygon([(ox - 20, oy - 178), (ox + 20, oy - 178), (ox + 34, oy - 6), (ox - 34, oy - 6)], fill=c(VEIL), outline=ink)
    # feet
    for bx in ([-8, 8] if not side else [-2, 8]):
        d.ellipse([ox + bx - 7, oy - 5, ox + bx + 7, oy + 6], fill=c(MOURN_COAT_DARK))
    # long coat
    d.polygon([(ox - sh + bow, oy - 142), (ox + sh + bow, oy - 142), (ox + hem, oy - 4), (ox - hem, oy - 4)], fill=c(MOURN_COAT), outline=ink)
    if colour:
        d.polygon([(ox - hem, oy - 12), (ox + hem, oy - 12), (ox + hem + 1, oy - 4), (ox - hem - 1, oy - 4)], fill=MOURN_COAT_DARK)
        if view != "back":
            for yy in (-120, -98, -76):
                d.ellipse([ox + bow * 0.5 - 2, oy + yy - 2, ox + bow * 0.5 + 2, oy + yy + 2], fill=VEIL)
    # a long shawl draped from one shoulder to the hem: a lopsided, wider lower outline (added after the T087 strip showed the Mourner
    # read as a plain spike next to Ember)
    # (the one-sided shawl made it read like Ward's cone, so it is a wide shoulder cape instead: wide on top, narrow below)
    if view != "side":
        d.polygon([(ox - sh - 2, oy - 140), (ox + sh + 2, oy - 140), (ox + 46, oy - 112), (ox + 40, oy - 94), (ox - 40, oy - 94), (ox - 46, oy - 112)], fill=c(VEIL), outline=ink)
    else:
        d.polygon([(ox - 14 + bow, oy - 140), (ox + 16 + bow, oy - 140), (ox + 30 + bow, oy - 100), (ox - 24 + bow, oy - 100)], fill=c(VEIL), outline=ink)
    # long sleeves hanging, hands clasped at the waist holding a lily
    if view != "back":
        for s in ([-1, 1] if not side else [1]):
            d.polygon([(ox + s * (sh - 2) + bow, oy - 138), (ox + s * (sh + 7) + bow, oy - 132), (ox + s * 8 + bow, oy - 76), (ox + s * 2 + bow, oy - 80)], fill=c(MOURN_COAT_DARK), outline=ink)
        d.ellipse([ox - 8 + bow * 0.6, oy - 86, ox + 8 + bow * 0.6, oy - 70], fill=c(BONE))
        if colour:
            d.line([(ox + bow * 0.6, oy - 76), (ox + bow * 0.6 + 4, oy - 60)], fill=(110, 160, 130), width=2)
            for k in range(3):
                a = -0.5 + k * 0.5
                d.polygon([(ox + bow * 0.6, oy - 86), (ox + bow * 0.6 + 12 * math.sin(a) + 2, oy - 106 + 4 * k), (ox + bow * 0.6 + 4, oy - 84)], fill=LILY, outline=INK)
        else:
            d.polygon([(ox + bow * 0.6 - 4, oy - 88), (ox + bow * 0.6, oy - 110), (ox + bow * 0.6 + 4, oy - 88)], fill=(0, 0, 0))
    else:
        d.polygon([(ox - 6, oy - 138), (ox + 6, oy - 138), (ox + 14, oy - 90), (ox - 14, oy - 90)], fill=c(MOURN_COAT_DARK))
    # hooded veil over the head and shoulders
    hx = ox + bow
    hood = [(hx + 26 * math.cos(a / 20 * math.pi), oy - 160 + 34 * math.sin(a / 20 * math.pi) * (1 if math.sin(a / 20 * math.pi) < 0 else 0.7)) for a in range(0, 41)]
    d.polygon(hood, fill=c(VEIL), outline=ink)
    # blank face: a smooth bone-white oval with no features (a single hairline crack in colour mode)
    if view in ("front", "side"):
        fw = 12 if view == "front" else 7
        fx = hx if view == "front" else hx + 8
        d.ellipse([fx - fw, oy - 184, fx + fw, oy - 150], fill=c(BONE))
        if colour:
            d.line([(fx - 1, oy - 182), (fx + 2, oy - 168), (fx - 2, oy - 158)], fill=(200, 196, 188), width=1)


HOUND_BODY = (196, 134, 62)
HOUND_DARK = (128, 84, 40)
HOUND_TAPE = (213, 94, 0)
HOUND_COLLAR = (22, 92, 90)


def _leg(d, c, p0, p1, p2, width=10):
    """A two-segment leg with a gear at the knee and a small paw block at the foot."""
    d.line([p0, p1], fill=c(HOUND_DARK), width=width)
    d.line([p1, p2], fill=c(HOUND_BODY), width=width)
    _gear(d, p1[0], p1[1], 8, 8, c(BRASS), None, c(HOUND_DARK))
    d.rectangle([p2[0] - 9, p2[1] - 3, p2[0] + 9, p2[1] + 5], fill=c(HOUND_DARK))


def brass_hound_view(d, ox, oy, view, colour=True):
    """Brass Hound (T084): a creature, not humanoid (the cast keeps four non-humanoid slots). A bronze clockwork hound with gear joints, brass plate ears,
    a coil-spring tail, a tally dial on its flank and a paper-tape tongue. Long and low in the side view, the only four-legged shape in the cast."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    if view == "side":
        # tail: a coil spring rising behind
        pts = []
        for i in range(0, 41):
            t = i / 40
            pts.append((ox - 62 - 20 * t + 7 * math.sin(t * 26), oy - 84 - 52 * t))
        d.line(pts, fill=c(BRASS_DARK), width=5)
        # far legs (darker, offset)
        _leg(d, c, (ox + 30, oy - 52), (ox + 36, oy - 30), (ox + 40, oy - 6))
        _leg(d, c, (ox - 34, oy - 52), (ox - 26, oy - 30), (ox - 32, oy - 6))
        # body
        d.ellipse([ox - 70, oy - 98, ox - 8, oy - 46], fill=c(HOUND_BODY))
        d.ellipse([ox - 4, oy - 106, ox + 58, oy - 40], fill=c(HOUND_BODY))
        d.rectangle([ox - 40, oy - 98, ox + 30, oy - 48], fill=c(HOUND_BODY))
        # near legs
        _leg(d, c, (ox + 42, oy - 52), (ox + 50, oy - 30), (ox + 54, oy - 6))
        _leg(d, c, (ox - 46, oy - 52), (ox - 38, oy - 30), (ox - 44, oy - 6))
        # neck, head and ear
        d.polygon([(ox + 40, oy - 98), (ox + 62, oy - 102), (ox + 78, oy - 134), (ox + 56, oy - 132)], fill=c(HOUND_BODY), outline=ink)
        d.polygon([(ox + 62, oy - 142), (ox + 92, oy - 144), (ox + 116, oy - 128), (ox + 114, oy - 116), (ox + 88, oy - 112), (ox + 62, oy - 116)], fill=c(HOUND_BODY), outline=ink)
        d.polygon([(ox + 62, oy - 140), (ox + 44, oy - 132), (ox + 54, oy - 108)], fill=c(BRASS), outline=ink)
        d.polygon([(ox + 54, oy - 108), (ox + 72, oy - 102), (ox + 72, oy - 112)], fill=c(HOUND_COLLAR))  # collar
        if colour:
            d.ellipse([ox + 80, oy - 134, ox + 90, oy - 124], fill=INK)
            d.ellipse([ox + 83, oy - 132, ox + 86, oy - 129], fill=(255, 255, 255))
            d.ellipse([ox + 110, oy - 128, ox + 118, oy - 120], fill=INK)
            d.polygon([(ox + 96, oy - 114), (ox + 112, oy - 114), (ox + 108, oy - 96), (ox + 100, oy - 98)], fill=HOUND_TAPE)
            # tally dial on the flank
            d.ellipse([ox - 14, oy - 84, ox + 8, oy - 62], fill=(240, 230, 200), outline=None)
            d.line([(ox - 3, oy - 73), (ox + 2, oy - 82)], fill=INK, width=2)
    elif view == "front":
        # hind legs hinted behind, then front legs
        _leg(d, c, (ox - 30, oy - 56), (ox - 34, oy - 30), (ox - 34, oy - 6))
        _leg(d, c, (ox + 30, oy - 56), (ox + 34, oy - 30), (ox + 34, oy - 6))
        d.polygon([(ox - 26, oy - 112), (ox + 26, oy - 112), (ox + 40, oy - 52), (ox - 40, oy - 52)], fill=c(HOUND_BODY), outline=ink)
        _leg(d, c, (ox - 18, oy - 70), (ox - 20, oy - 34), (ox - 20, oy - 6))
        _leg(d, c, (ox + 18, oy - 70), (ox + 20, oy - 34), (ox + 20, oy - 6))
        d.ellipse([ox - 26, oy - 154, ox + 26, oy - 108], fill=c(HOUND_BODY))
        d.ellipse([ox - 13, oy - 130, ox + 13, oy - 104], fill=c(HOUND_BODY), outline=None)
        for s in (-1, 1):
            d.polygon([(ox + s * 20, oy - 150), (ox + s * 44, oy - 140), (ox + s * 36, oy - 112)], fill=c(BRASS), outline=ink)
        d.polygon([(ox - 20, oy - 110), (ox + 20, oy - 110), (ox + 22, oy - 100), (ox - 22, oy - 100)], fill=c(HOUND_COLLAR))
        if colour:
            for s in (-1, 1):
                d.ellipse([ox + s * 12 - 5, oy - 140, ox + s * 12 + 5, oy - 130], fill=INK)
                d.ellipse([ox + s * 12 - 2, oy - 139, ox + s * 12 + 1, oy - 136], fill=(255, 255, 255))
            d.ellipse([ox - 5, oy - 122, ox + 5, oy - 114], fill=INK)
            d.polygon([(ox - 5, oy - 112), (ox + 5, oy - 112), (ox + 3, oy - 96), (ox - 3, oy - 96)], fill=HOUND_TAPE)
    else:  # back
        pts = []
        for i in range(0, 41):
            t = i / 40
            pts.append((ox + 7 * math.sin(t * 26), oy - 90 - 60 * t))
        d.line(pts, fill=c(BRASS_DARK), width=5)
        _leg(d, c, (ox - 24, oy - 58), (ox - 30, oy - 30), (ox - 30, oy - 6))
        _leg(d, c, (ox + 24, oy - 58), (ox + 30, oy - 30), (ox + 30, oy - 6))
        d.polygon([(ox - 34, oy - 104), (ox + 34, oy - 104), (ox + 42, oy - 52), (ox - 42, oy - 52)], fill=c(HOUND_BODY), outline=ink)
        d.ellipse([ox - 30, oy - 110, ox + 30, oy - 70], fill=c(HOUND_BODY))
        for s in (-1, 1):
            d.polygon([(ox + s * 24, oy - 112), (ox + s * 40, oy - 124), (ox + s * 36, oy - 100)], fill=c(BRASS), outline=ink)
        if colour:
            _gear(d, ox, oy - 78, 11, 9, BRASS_DARK, INK, BRASS)


MOTH_WING = (242, 224, 182)
MOTH_PATTERN = (230, 150, 40)
MOTH_BROWN = (92, 62, 44)
MOTH_TUNIC = (70, 52, 44)


def moth_lantern_view(d, ox, oy, view, colour=True):
    """Moth-Lantern (T085): a humanoid young lamplighter in a cloak of moth wings, with feathered antennae and a lantern on a pole.
    Humanoid (head, torso, two arms, two legs). Wide butterfly-shaped wings behind a slim body make a broad X, unlike the cones and columns."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    # wings (behind the body)
    if not side:
        for s in (-1, 1):
            up = [ox + s * 14, oy - 150, ox + s * 94, oy - 96] if s == 1 else [ox - 94, oy - 150, ox - 14, oy - 96]
            lo = [ox + s * 14, oy - 118, ox + s * 74, oy - 56] if s == 1 else [ox - 74, oy - 118, ox - 14, oy - 56]
            d.ellipse([min(up[0], up[2]), up[1] - 20, max(up[0], up[2]), up[3] + 8], fill=c(MOTH_WING))
            d.ellipse([min(lo[0], lo[2]), lo[1], max(lo[0], lo[2]), lo[3]], fill=c(MOTH_PATTERN if colour else (0, 0, 0)))
            if colour:
                d.ellipse([ox + s * 54 - 12, oy - 148, ox + s * 54 + 12, oy - 124], fill=MOTH_BROWN)
                d.ellipse([ox + s * 54 - 6, oy - 143, ox + s * 54 + 6, oy - 129], fill=MOTH_WING)
                d.ellipse([ox + s * 54 - 2, oy - 140, ox + s * 54 + 2, oy - 132], fill=INK)
                d.ellipse([ox + s * 42 - 7, oy - 92, ox + s * 42 + 7, oy - 78], fill=MOTH_BROWN)
    else:
        d.ellipse([ox - 70, oy - 168, ox - 8, oy - 100], fill=c(MOTH_WING))
        d.ellipse([ox - 56, oy - 118, ox - 8, oy - 60], fill=c(MOTH_PATTERN if colour else (0, 0, 0)))
        if colour:
            d.ellipse([ox - 52, oy - 150, ox - 30, oy - 128], fill=MOTH_BROWN)
            d.ellipse([ox - 46, oy - 144, ox - 36, oy - 134], fill=MOTH_WING)
    # legs
    for lx in ([-6, 7] if not side else [-3, 6]):
        d.line([(ox + lx, oy - 56), (ox + lx, oy - 6)], fill=c(MOTH_BROWN), width=7)
        d.ellipse([ox + lx - 8, oy - 6, ox + lx + 8, oy + 5], fill=c(MOTH_TUNIC))
    # tunic and belt
    hw = 15 if not side else 11
    d.polygon([(ox - hw, oy - 128), (ox + hw, oy - 128), (ox + hw + 5, oy - 52), (ox - hw - 5, oy - 52)], fill=c(MOTH_TUNIC), outline=ink)
    if colour:
        d.rectangle([ox - hw - 3, oy - 86, ox + hw + 3, oy - 80], fill=BRASS)
    # arms; one holds the lamp pole
    px = ox + 52 if not side else ox + 30
    d.line([(px, oy - 4), (px, oy - 176)], fill=c(BRASS_DARK), width=4)
    d.line([(ox + hw - 2, oy - 120), (px - 2, oy - 98)], fill=c(MOTH_BROWN), width=8)
    d.ellipse([px - 6, oy - 104, px + 6, oy - 92], fill=c(SKIN))
    if not side:
        d.line([(ox - hw + 2, oy - 120), (ox - hw - 6, oy - 80)], fill=c(MOTH_BROWN), width=8)
    # lantern at the top of the pole
    d.rectangle([px - 12, oy - 200, px + 12, oy - 194], fill=c(BRASS))
    d.rectangle([px - 10, oy - 194, px + 10, oy - 170], fill=c(LAMP_GLOW if colour else (0, 0, 0)))
    d.rectangle([px - 12, oy - 172, px + 12, oy - 166], fill=c(BRASS))
    d.polygon([(px - 6, oy - 200), (px + 6, oy - 200), (px, oy - 210)], fill=c(BRASS_DARK))
    # head and feathered antennae
    hx = ox if not side else ox + 3
    d.ellipse([hx - 13, oy - 156, hx + 13, oy - 128], fill=c(SKIN))
    d.ellipse([hx - 15, oy - 162, hx + 15, oy - 144], fill=c(MOTH_BROWN))  # hair / cap
    for s in ([-1, 1] if not side else [-1, 1]):
        pts = [(hx + s * 6, oy - 160), (hx + s * 16, oy - 180), (hx + s * 12 + (s * 8 if not side else 0), oy - 196)]
        d.line(pts, fill=c(MOTH_BROWN), width=3)
        d.ellipse([pts[-1][0] - 5, pts[-1][1] - 5, pts[-1][0] + 5, pts[-1][1] + 5], fill=c(MOTH_PATTERN if colour else (0, 0, 0)))
    if colour and view in ("front", "side"):
        eyes = [hx - 5, hx + 5] if view == "front" else [hx + 6]
        for ex in eyes:
            d.ellipse([ex - 2.5, oy - 146, ex + 2.5, oy - 140], fill=INK)
        d.arc([hx - 4 if view == "front" else hx + 2, oy - 140, hx + 4 if view == "front" else hx + 10, oy - 132], 20, 160, fill=INK, width=2)


WR_GREY = (150, 152, 162)
WR_DARK = (84, 86, 100)
WR_PALE = (214, 216, 226)
WR_VIOLET = (184, 170, 220)


def wraith_view(d, ox, oy, view, colour=True):
    """Grey Veil Wraith (T086): a tall ghostly humanoid, no legs, hovering above the ground, a slumped hooded head with a dark hollow face and two pale
    pinprick eyes, long thin arms with spread fingers, a ragged hem that breaks into long wisps, and one long ribbon streaming above one shoulder.
    Boss-tier and unaligned: the only floating, ragged, asymmetrical figure, and the one that has no feet."""
    def c(rgb):
        return rgb if colour else (0, 0, 0)

    ink = c(INK) if colour else None
    side = view == "side"
    sh = 16 if not side else 12
    hem = 36 if not side else 26
    lift = 14  # hovering: the wisps end above the ground
    # long ribbon rising from the left shoulder (drawn first so the body overlaps its root)
    rib = [(ox - sh - 14 * (i / 40) - 26 * math.sin((i / 40) * 5.2), oy - 130 - 104 * (i / 40)) for i in range(41)]
    d.line(rib, fill=c(WR_VIOLET), width=6)
    # ragged hem wisps (below the body)
    n = 6
    lengths = [30, 12, 36, 20, 40, 16]
    for i in range(n):
        x0 = ox - hem + i * (2 * hem / n)
        x1 = ox - hem + (i + 1) * (2 * hem / n)
        d.polygon([(x0, oy - 40 - lift), (x1, oy - 40 - lift), ((x0 + x1) / 2 + (6 if i % 2 else -6), oy - lift + 8 - lengths[i] * 0.2 + 12)], fill=c(WR_GREY), outline=ink)
    # body: a narrow shoulder widening to a ragged hem
    d.polygon([(ox - sh, oy - 136), (ox + sh, oy - 136), (ox + hem, oy - 40 - lift), (ox - hem, oy - 40 - lift)], fill=c(WR_GREY), outline=ink)
    if colour:
        d.polygon([(ox - 4, oy - 130), (ox + 6, oy - 130), (ox + 14, oy - 56 - lift), (ox - 8, oy - 56 - lift)], fill=WR_PALE)
    # long arms with spread fingers
    for s in ([-1, 1] if not side else [1]):
        ax = ox + s * (sh - 2)
        hx = ox + s * (sh + 20)
        d.polygon([(ax, oy - 130), (ax + s * 8, oy - 128), (hx + s * 4, oy - 62 - lift), (hx - s * 2, oy - 62 - lift)], fill=c(WR_DARK), outline=ink)
        for k in (-1, 0, 1):
            d.line([(hx + s * 1, oy - 62 - lift), (hx + s * (1 + k * 5), oy - 40 - lift)], fill=c(WR_DARK), width=3)
    # slumped hooded head, tilted to one side
    hx0 = ox - 6 if not side else ox + 2
    d.ellipse([hx0 - 18, oy - 178, hx0 + 18, oy - 128], fill=c(WR_DARK), outline=None)
    d.polygon([(hx0 - 20, oy - 150), (hx0 + 20, oy - 150), (hx0 + 14, oy - 132), (hx0 - 14, oy - 132)], fill=c(WR_DARK))
    if colour and view in ("front", "side"):
        fw = 9 if view == "front" else 5
        fx = hx0 if view == "front" else hx0 + 8
        d.ellipse([fx - fw, oy - 166, fx + fw, oy - 138], fill=(24, 24, 32))
        for ex in ([fx - 4, fx + 4] if view == "front" else [fx + 1]):
            d.ellipse([ex - 1.5, oy - 154, ex + 1.5, oy - 151], fill=(255, 255, 255))


EMBER_PLAIN = [(32, 0), (50, 22), (58, 44), (54, 58), (32, 63), (10, 58), (6, 44), (14, 22)]
FROST_PLAIN = [(32, 4), (52, 14), (60, 36), (58, 63), (6, 63), (4, 36), (12, 14)]  # a plain snowball bell
GARG_PLAIN = [(6, 63), (4, 34), (18, 12), (46, 12), (60, 34), (58, 63)]  # a plain rounded rock

DRAKE_PLAIN = [(28, 0), (36, 8), (34, 63), (24, 63), (24, 8)]  # a plain upright pole

SENT_PLAIN = [(24, 0), (40, 0), (40, 20), (48, 24), (48, 63), (16, 63), (16, 24), (24, 20)]  # a plain boxy robot

WARD_PLAIN = [(32, 0), (46, 20), (58, 63), (6, 63), (18, 20)]  # a plain cone

CHOR_PLAIN = [(24, 0), (40, 0), (46, 63), (18, 63)]  # a plain column

ARCH_PLAIN = [(32, 0), (50, 16), (58, 40), (50, 56), (38, 60), (36, 63), (28, 63), (26, 60), (14, 56), (6, 40), (14, 16)]  # a plain egg

MOURN_PLAIN = [(26, 0), (38, 0), (46, 63), (18, 63)]  # a plain tall column

HOUND_PLAIN = [(2, 40), (10, 28), (40, 26), (46, 12), (60, 14), (62, 26), (62, 40), (56, 63), (44, 63), (40, 50), (20, 50), (16, 63), (4, 63)]  # a plain dog loaf

MOTH_PLAIN = [(32, 20), (60, 4), (62, 30), (40, 40), (58, 58), (32, 48), (6, 58), (24, 40), (2, 30), (4, 4)]  # a plain butterfly

WRAITH_PLAIN = [(26, 0), (38, 0), (44, 40), (58, 63), (6, 63), (20, 40)]  # a plain ghost sheet

FAMILIARS = {
    "ember": {
        "name": "Ember", "task": "T075", "fn": ember_view, "plain_name": "plain flame", "plain": EMBER_PLAIN,
        "swatches": [("flame", FLAME_OUT), ("mid", FLAME_MID), ("core", FLAME_CORE), ("brass", BRASS), ("brass dark", BRASS_DARK), ("verdigris", VERDI), ("ink", INK)],
        "footer": "Gesture: lifts its flame to the lantern.   Flaw: gutters when the lantern is out.   Hue: vermilion-orange (#D55E00).",
    },
    "gargoyle": {
        "name": "Gargoyle", "task": "T076", "fn": gargoyle_view, "plain_name": "plain rock", "plain": GARG_PLAIN,
        "swatches": [("stone", STONE), ("stone dark", STONE_DARK), ("stone light", STONE_LIGHT), ("scarf sky", SKY), ("eye glow", GLOW), ("ink", INK)],
        "footer": "Gesture: turns its head very slowly.   Flaw: wakes late (first attack delayed).   Hue: ash grey with a sky-blue scarf (#56B4E9).",
    },
    "frostling": {
        "name": "Frostling", "task": "T077", "fn": frostling_view, "plain_name": "plain snowball", "plain": FROST_PLAIN,
        "swatches": [("ice", ICE), ("hood", ICE_DARK), ("frost white", FROST_WHITE), ("mitten", MITT), ("ink", INK)],
        "footer": "Gesture: blows on its mittens, then holds them out.   Flaw: slows when the stage is warm (lamps near).   Hue: pale ice blue (#9ED4F0).",
    },
    "star_drake": {
        "name": "StarDrake", "task": "T078", "fn": star_drake_view, "plain_name": "plain pole", "plain": DRAKE_PLAIN,
        "swatches": [("indigo", INDIGO), ("wing blue", INDIGO_LIGHT), ("star white", STAR_WHITE), ("star gold", STAR_GOLD), ("ink", INK)],
        "footer": "Gesture: sings one long note, tail star flaring.   Flaw: slow to charge its ultimate when alone.   Hue: deep indigo (#1E2A78) with gold stars.",
    },
    "sentinel": {
        "name": "Sentinel", "task": "T079", "fn": sentinel_view, "plain_name": "plain robot", "plain": SENT_PLAIN,
        "swatches": [("brass", BRASS), ("brass dark", BRASS_DARK), ("verdigris gear", SENT_VERDI), ("visor amber", SENT_AMBER), ("ink", INK)],
        "footer": "Gesture: tips its helmet, then lowers the halberd.   Flaw: freezes for a beat after each step (telegraph).   Hue: brass with bluish green (#009E73).",
    },
    "ward": {
        "name": "Ward", "task": "T080", "fn": ward_view, "plain_name": "plain cone", "plain": WARD_PLAIN,
        "swatches": [("oilskin coat", COAT), ("coat dark", COAT_DARK), ("lantern glass", GLASS), ("lamp glow", LAMP_GLOW), ("brass", BRASS), ("ink", INK)],
        "footer": "Gesture: raises the lantern toward the water.   Flaw: only helps neighbours that stay put (a moved neighbour gets nothing for a wave).   Hue: harbour slate with a lamp glow.",
    },
    "mirror_chorister": {
        "name": "MirrorChorister", "task": "T081", "fn": mirror_chorister_view, "plain_name": "plain column", "plain": CHOR_PLAIN,
        "swatches": [("robe blue", ROBE), ("robe dark", ROBE_DARK), ("silver mirror", SILVER), ("star white", STAR_WHITE), ("star gold", STAR_GOLD), ("ink", INK)],
        "footer": "Gesture: tilts its head and holds out an open palm.   Flaw: echoes a neighbour at reduced power, and does nothing alone.   Hue: Choir blue (#0072B2) with a silver mirror face.",
    },
    "archivist": {
        "name": "Archivist", "task": "T082", "fn": archivist_view, "plain_name": "plain egg", "plain": ARCH_PLAIN,
        "swatches": [("coat teal", ARCH_COAT), ("coat dark", ARCH_COAT_DARK), ("brass", BRASS), ("lens glass", ARCH_LENS), ("ledger", LEDGER), ("ink", INK)],
        "footer": "Gesture: turns its head all the way round.   Flaw: hastens neighbours but is slow itself (lowest own attack rate).   Hue: Guild teal (#165C5A) with brass.",
    },
    "mourner": {
        "name": "Mourner", "task": "T083", "fn": mourner_view, "plain_name": "plain tall column", "plain": MOURN_PLAIN,
        "swatches": [("coat", MOURN_COAT), ("coat dark", MOURN_COAT_DARK), ("veil", VEIL), ("bone face", BONE), ("lily", LILY), ("ink", INK)],
        "footer": "Gesture: bows its head and raises a finger to where lips would be.   Flaw: Hush needs two still seconds to prime.   Hue: ash charcoal with a pale blue veil (Hollow Court).",
    },
    "brass_hound": {
        "name": "BrassHound", "task": "T084", "fn": brass_hound_view, "plain_name": "plain dog loaf", "plain": HOUND_PLAIN,
        "swatches": [("bronze body", HOUND_BODY), ("bronze dark", HOUND_DARK), ("brass", BRASS), ("collar teal", HOUND_COLLAR), ("tape tongue", HOUND_TAPE), ("ink", INK)],
        "footer": "Gesture: sits and thumps its spring tail.   Flaw: very short range; cannot reach flyers.   Hue: bronze with a Guild teal collar.",
    },
    "moth_lantern": {
        "name": "MothLantern", "task": "T085", "fn": moth_lantern_view, "plain_name": "plain butterfly", "plain": MOTH_PLAIN,
        "swatches": [("wing cream", MOTH_WING), ("wing gold", MOTH_PATTERN), ("wing brown", MOTH_BROWN), ("tunic", MOTH_TUNIC), ("lamp glow", LAMP_GLOW), ("ink", INK)],
        "footer": "Gesture: flutters once, then holds the lantern high.   Flaw: its marks fade when no lit lamp is near.   Hue: moth gold and cream (Lantern Keepers).",
    },
    "grey_veil_wraith": {
        "name": "GreyVeilWraith", "task": "T086", "fn": wraith_view, "plain_name": "plain ghost sheet", "plain": WRAITH_PLAIN,
        "swatches": [("grey", WR_GREY), ("grey dark", WR_DARK), ("pale", WR_PALE), ("veil violet", WR_VIOLET), ("ink", INK)],
        "footer": "Gesture: reaches out one long arm, palm up, then closes it slowly.   Flaw: unbound, so it ignores all neighbour buffs.   Hue: Grey Veil grey with pale violet.",
    },
}


def render_view(fn, view, colour, size=(380, 460)):
    img = Image.new("RGB", (size[0] * S, size[1] * S), (245, 238, 224) if colour else (255, 255, 255))
    d = ImageDraw.Draw(img)

    ZOOM = 1.55
    ox0, oy0 = size[0] / 2, size[1] - 70

    def zx(x):
        return (ox0 + (x - ox0) * ZOOM) * S

    def zy(y):
        return (oy0 + (y - oy0) * ZOOM) * S

    class Scaled:
        """Wrap ImageDraw so callers use sheet pixels; everything is zoomed about the base centre."""
        def polygon(self, pts, fill=None, outline=None):
            q = [(zx(x), zy(y)) for x, y in pts]
            if outline:
                d.polygon(q, fill=fill, outline=outline, width=int(2 * S * ZOOM))
            else:
                d.polygon(q, fill=fill)
        def ellipse(self, box, fill=None, outline=None):
            d.ellipse([zx(box[0]), zy(box[1]), zx(box[2]), zy(box[3])], fill=fill)
        def rectangle(self, box, fill=None):
            d.rectangle([zx(box[0]), zy(box[1]), zx(box[2]), zy(box[3])], fill=fill)
        def line(self, pts, fill=None, width=1):
            d.line([(zx(x), zy(y)) for x, y in pts], fill=fill, width=int(width * S * ZOOM))
        def arc(self, box, a0, a1, fill=None, width=1):
            d.arc([zx(box[0]), zy(box[1]), zx(box[2]), zy(box[3])], a0, a1, fill=fill, width=int(width * S * ZOOM))

    fn(Scaled(), size[0] / 2, size[1] - 70, view, colour)
    return img.resize(size, Image.LANCZOS)


def font(sz):
    for p in ("C:/Windows/Fonts/georgia.ttf", "C:/Windows/Fonts/arial.ttf"):
        if pathlib.Path(p).exists():
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def build(key):
    meta = FAMILIARS[key]
    name, fn = meta["name"], meta["fn"]
    OUT.mkdir(parents=True, exist_ok=True)
    views = ["front", "side", "back"]
    colour = [render_view(fn, v, True) for v in views]
    sil = [render_view(fn, v, False) for v in views]
    # --- sheet
    W, H = 380 * 3 + 80, 460 + 250
    sheet = Image.new("RGB", (W, H), (245, 238, 224))
    d = ImageDraw.Draw(sheet)
    d.text((24, 14), f"{name.upper()}  design sheet ({meta['task']})", fill=INK, font=font(30))
    for i, img in enumerate(colour):
        sheet.paste(img, (20 + i * 380 + i * 20, 56))
        d.text((20 + i * 400 + 150, 56 + 436), views[i].upper(), fill=INK, font=font(18))
    # palette strip
    swatches = meta["swatches"]
    for i, (n, rgb) in enumerate(swatches):
        x = 24 + i * 150
        d.rectangle([x, 56 + 470, x + 60, 56 + 510], fill=rgb, outline=INK)
        d.text((x, 56 + 514), f"{n}  #{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}", fill=INK, font=font(13))
    d.text((24, 56 + 540), meta["footer"], fill=INK, font=font(15))
    sheet.save(OUT / f"{name}_sheet.png")
    # --- silhouette test strip: 3 views big, then the front at 64 px greyscale beside primitives
    strip = Image.new("RGB", (380 * 3 + 60 + 4 * 90, 460), (255, 255, 255))
    for i, img in enumerate(sil):
        strip.paste(img, (i * 380, 0))
    front64 = sil[0].convert("L").resize((64, 64 * 460 // 380), Image.LANCZOS)
    fx = 380 * 3 + 20
    strip.paste(front64.convert("RGB"), (fx, 20))
    d2 = ImageDraw.Draw(strip)
    d2.text((fx, 110), "64 px", fill=(0, 0, 0), font=font(12))
    strip.save(OUT / f"{name}_silhouette.png")
    return name, sil, meta


def _px(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()


def ratios(sil_front, meta):
    """Machine check numbers: fill ratio, IoU against basic shapes and against a plain flame, differences between views."""
    g = sil_front.convert("L").point(lambda v: 255 if v < 128 else 0)
    bbox = g.getbbox()
    c0 = g.crop(bbox)
    k = 64 / max(c0.size)  # keep the aspect ratio: stretching a tall figure to a square makes everything look like a block
    c0 = c0.resize((max(1, round(c0.size[0] * k)), max(1, round(c0.size[1] * k))))
    crop = Image.new("L", (64, 64), 0)
    crop.paste(c0, ((64 - c0.size[0]) // 2, (64 - c0.size[1]) // 2))
    area = sum(1 for v in _px(crop) if v) / (64 * 64)

    def iou(a, b):
        inter = sum(1 for x, y in zip(_px(a), _px(b)) if x and y)
        union = sum(1 for x, y in zip(_px(a), _px(b)) if x or y)
        return inter / union

    def shape(kind):
        im = Image.new("L", (64, 64), 0)
        dd = ImageDraw.Draw(im)
        if kind == "circle":
            dd.ellipse([0, 0, 63, 63], fill=255)
        elif kind == "square":
            dd.rectangle([0, 0, 63, 63], fill=255)
        elif kind == "triangle":
            dd.polygon([(32, 0), (63, 63), (0, 63)], fill=255)
        else:
            dd.polygon(meta["plain"], fill=255)
        return im
    return area, {k: iou(crop, shape(k)) for k in ("circle", "square", "triangle", meta["plain_name"])}


if __name__ == "__main__":
    key = (sys.argv[1] if len(sys.argv) > 1 else "ember").lower()
    name, sil, meta = build(key)
    area, ious = ratios(sil[0], meta)
    # difference between views: IoU of binary silhouettes should not be near 1 (not copies)
    def binary(im):
        return im.convert("L").point(lambda v: 255 if v < 128 else 0)
    def iou2(a, b):
        A, B = binary(a), binary(b)
        inter = ImageChops.logical_and(A.convert("1"), B.convert("1")).getbbox()
        ai = sum(1 for x, y in zip(_px(A), _px(B)) if x and y)
        un = sum(1 for x, y in zip(_px(A), _px(B)) if x or y)
        return ai / un
    vf, vs, vb = sil
    lines = [
        f"familiar={name}",
        f"fill ratio (64 px crop) = {area:.2f}",
        "IoU vs basic shapes: " + ", ".join(f"{k}={v:.2f}" for k, v in ious.items()),
        f"view overlap front/side={iou2(vf, vs):.2f} front/back={iou2(vf, vb):.2f} side/back={iou2(vs, vb):.2f}",
    ]
    (OUT / f"{name}_report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
