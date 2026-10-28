"""Skill tree art, drawn with Pillow (no AI): one glyph icon per skill, the node hexagon, an iron chain strip for the
animated border, and a faint script wallpaper tile (Beyond Wonderland letters, like the grader's patterned black).

    python "UI Kit/art/make_tree_art.py"      -> UI Kit/art/tree_art/*.png

Icons are white so the game tints them with each branch's colour (ImageColor3). Glyphs come from Windows'
Segoe UI Symbol (seguisym.ttf); they are rendered to images, the font itself is not shipped."""
import os, random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "tree_art")
SYM = "C:/Windows/Fonts/seguisym.ttf"
WONDER = os.path.join(HERE, "fonts", "Beyond Wonderland.ttf")
GLYPHS = {
    "Start": "\u2726", "Claws": "\u2694", "Magnet": "\u26c3", "Armor": "\u26e8", "Charge": "\u26a1", "Charm": "\u2618",
    "Finder": "\u25c8", "Heavy": "\u2620", "Merger": "\u26ad", "Clock": "\u231b", "Mega": "\u2604", "Discount": "\u2696",
    "Guard": "\u2693", "Eye": "\U0001f441", "Learner": "\u2712", "Refund": "\u27f2", "Pity": "\u263d", "Double": "\u264a",
    "Haste": "\u27b6",
}


def icon(ch, size=128):
    f = ImageFont.truetype(SYM, int(size * 0.7))
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    l, t, r, b = d.textbbox((0, 0), ch, font=f)
    d.text(((size - (r - l)) / 2 - l, (size - (b - t)) / 2 - t), ch, font=f, fill=255)
    m = m.filter(ImageFilter.MaxFilter(5))  # bolder strokes: thin glyphs vanished at 30 px (review round 2)
    # a dark edge keeps the glyph readable on any node colour
    edge = m.filter(ImageFilter.MaxFilter(5))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dark = Image.new("RGBA", (size, size), (0, 0, 0, 255)); dark.putalpha(edge.point(lambda v: v * 0.7))
    out = Image.alpha_composite(out, dark)
    white = Image.new("RGBA", (size, size), (255, 255, 255, 255)); white.putalpha(m)
    return Image.alpha_composite(out, white)


def hexagon(size=128, fill=(14, 13, 18, 245), rim=True):
    s = 4  # supersample for smooth edges
    W = size * s
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def pts(r):
        return [(W / 2 + r * math.cos(math.radians(60 * k + 30)), W / 2 + r * math.sin(math.radians(60 * k + 30))) for k in range(6)]
    R = W * 0.47
    if rim:
        d.polygon(pts(R), fill=(96, 92, 102, 255))        # outer metal
        d.polygon(pts(R * 0.93), fill=(40, 38, 46, 255))    # groove
        d.polygon(pts(R * 0.88), fill=(150, 146, 156, 255)) # inner bevel
    d.polygon(pts(R * (0.84 if rim else 1)), fill=fill)
    return im.resize((size, size), Image.LANCZOS)


def glow(size=128):
    g = Image.new("L", (size, size), 0)
    ImageDraw.Draw(g).ellipse((size * 0.22, size * 0.22, size * 0.78, size * 0.78), fill=255)
    g = g.filter(ImageFilter.GaussianBlur(size * 0.12))
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0)); out.putalpha(g)
    return out


def chain(link=64, h=40):
    """Tileable horizontal chain: a face-on oval link, then an edge-on link, period = 2 * link * 0.75."""
    s = 4
    P = int(link * 1.5)  # period
    W, H = P * s, h * s
    im = Image.new("RGBA", (W * 3, H), (0, 0, 0, 0))  # draw 3 periods, keep the middle so ends wrap cleanly
    d = ImageDraw.Draw(im)
    lw = int(H * 0.2)
    for k in range(-1, 4):
        x0 = k * W
        # face-on link (oval ring)
        box = (x0 + W * 0.02, H * 0.14, x0 + W * 0.02 + link * s, H * 0.86)
        d.ellipse(box, outline=(30, 28, 32, 255), width=lw + 6)
        d.ellipse(box, outline=(120, 116, 124, 255), width=lw)
        d.ellipse((box[0] + lw * 0.35, box[1] + lw * 0.35, box[2] - lw * 0.35, box[3] - lw * 0.35), outline=(206, 202, 210, 255), width=max(2, lw // 4))
        # edge-on link (flat bar with rounded ends) bridging to the next oval
        bx = x0 + W * 0.02 + link * s * 0.62
        bar = (bx, H * 0.36, bx + link * s * 0.9, H * 0.64)
        d.rounded_rectangle(bar, radius=H * 0.08, fill=(30, 28, 32, 255))
        d.rounded_rectangle((bar[0] + 3, bar[1] + 3, bar[2] - 3, bar[3] - 3), radius=H * 0.06, fill=(150, 146, 154, 255))
        d.line((bar[0] + 10, H * 0.43, bar[2] - 10, H * 0.43), fill=(220, 216, 224, 255), width=5)
    return im.crop((W, 0, 2 * W, H)).resize((P, h), Image.LANCZOS)


def lantern(w=128, h=168):
    """A small Victorian gas lantern for each skill node (white, tinted in game). Returns (frame, glass):
    frame = the metal (hook ring, cap, corner posts, bars, base); glass = the panes, which glow in the path colour once
    the skill is kindled. The glyph sits on the glass."""
    s = 4
    W, H = w * s, h * s
    fr = Image.new("L", (W, H), 0)
    gl = Image.new("L", (W, H), 0)
    d, g = ImageDraw.Draw(fr), ImageDraw.Draw(gl)
    cx = W / 2
    lw = 5 * s
    d.ellipse((cx - 9 * s, 2 * s, cx + 9 * s, 20 * s), outline=255, width=4 * s)          # hook ring
    d.polygon([(cx - 14 * s, 22 * s), (cx + 14 * s, 22 * s), (cx + 40 * s, 40 * s), (cx - 40 * s, 40 * s)], fill=255)  # cap
    d.rectangle((cx - 46 * s, 40 * s, cx + 46 * s, 46 * s), fill=255)                    # cap rim
    top, bot = 46 * s, 138 * s
    g.rounded_rectangle((cx - 40 * s, top, cx + 40 * s, bot), radius=6 * s, fill=255)     # glass
    for x in (-42, 42):                                                                 # corner posts
        d.rectangle((cx + x * s - lw / 2, top, cx + x * s + lw / 2, bot), fill=255)
    for x in (-14, 14):                                                                 # thin bars across the glass
        d.rectangle((cx + x * s - s, top, cx + x * s + s, bot), fill=150)
    d.rectangle((cx - 48 * s, bot, cx + 48 * s, bot + 7 * s), fill=255)                  # base rim
    d.polygon([(cx - 36 * s, bot + 7 * s), (cx + 36 * s, bot + 7 * s), (cx + 22 * s, bot + 22 * s), (cx - 22 * s, bot + 22 * s)], fill=255)
    def out(m):
        im = Image.new("RGBA", (W, H), (255, 255, 255, 0)); im.putalpha(m)
        return im.resize((w, h), Image.LANCZOS)
    # the glass: brighter in the middle, like a flame behind it
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((cx - 40 * s, 60 * s, cx + 40 * s, 128 * s), fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(14 * s))
    glass = ImageChops.multiply(gl, glow.point(lambda v: 90 + v * 165 // 255))
    return out(fr), out(glass)


def coin(size=128):
    """Brass coin with a gear-tooth rim and a small flame stamped in the middle (our lamplit theme)."""
    s = 4; W = size * s; c = W / 2
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    teeth = []
    for k in range(16):  # gear rim: 16 square teeth
        for f, r in ((0.0, .43), (0.12, .48), (0.38, .48), (0.5, .43), (1.0, .43)):
            a = (k + f) / 16 * math.tau
            teeth.append((c + math.cos(a) * W * r, c + math.sin(a) * W * r))
    d.polygon(teeth, fill=(120, 74, 26, 255))
    for r, col in ((0.42, (176, 112, 36)), (0.39, (238, 182, 86)), (0.33, (196, 132, 50)), (0.30, (250, 206, 120))):
        d.ellipse((c - W * r, c - W * r, c + W * r, c + W * r), fill=col + (255,))
    # highlight on the upper left, shade lower right
    hl = Image.new("L", (W, W), 0); ImageDraw.Draw(hl).ellipse((c - W * .28, c - W * .3, c + W * .05, c - W * .02), fill=150)
    hl = hl.filter(ImageFilter.GaussianBlur(W * .05)); white = Image.new("RGBA", (W, W), (255, 248, 220, 255)); white.putalpha(hl)
    im = Image.alpha_composite(im, white); d = ImageDraw.Draw(im)
    fl = [(c, c - W * .19), (c + W * .09, c - W * .02), (c + W * .07, c + W * .1), (c, c + W * .16), (c - W * .07, c + W * .1), (c - W * .09, c - W * .02)]
    d.polygon(fl, fill=(120, 60, 16, 255)); d.polygon([(c, c - W * .08), (c + W * .04, c + W * .05), (c, c + W * .1), (c - W * .04, c + W * .05)], fill=(255, 226, 150, 255))
    return im.resize((size, size), Image.LANCZOS)


def gem(size=128):
    """Faceted cyan crystal, light from the upper left."""
    s = 4; W = size * s
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    P = lambda x, y: (x * W, y * W)
    top, l, r, bl, br, bot, ml, mr = P(.5, .1), P(.16, .38), P(.84, .38), P(.3, .38), P(.7, .38), P(.5, .92), P(.36, .22), P(.64, .22)
    facets = [((ml, mr, br, bl), (150, 236, 255)), ((top, mr, ml), (220, 250, 255)), ((ml, l, bl), (110, 210, 245)), ((mr, r, br), (60, 160, 220)),
              ((l, bl, bot), (70, 180, 235)), ((bl, br, bot), (40, 140, 210)), ((br, r, bot), (24, 100, 180))]
    for pts, col in facets:
        d.polygon(pts, fill=col + (255,))
    d.line([l, ml, top, mr, r, bot, l], fill=(14, 50, 90, 255), width=s * 3)
    d.line([bl, br], fill=(230, 252, 255, 200), width=s * 2)
    return im.resize((size, size), Image.LANCZOS)


def watch_track(period=60, h=30):
    """Tileable brass minute-track rail (our clocks, not the grader's chains): two engraved brass rules with minute
    ticks between them, a long tick and a rivet every fifth. Period = 5 ticks, so it scrolls tick by tick."""
    s = 4
    W, H = period * s, h * s
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, H * 0.18, W, H * 0.82), fill=(22, 16, 12, 235))  # dark enamel between the rules
    for y0 in (H * 0.12, H * 0.82):  # brass rules: dark edge, body, highlight
        d.rectangle((0, y0, W, y0 + H * 0.09), fill=(60, 38, 16, 255))
        d.rectangle((0, y0 + 2, W, y0 + H * 0.09 - 2), fill=(196, 150, 78, 255))
        d.line((0, y0 + 4, W, y0 + 4), fill=(255, 226, 160, 255), width=2)
    step = W / 5
    for k in range(5):
        x = k * step + step / 2
        long = k == 2
        t = (H * 0.24, H * 0.76) if long else (H * 0.3, H * 0.52)
        d.rectangle((x - (5 if long else 3), t[0], x + (5 if long else 3), t[1]), fill=(214, 172, 100, 255))
        if long:  # a rivet under the long tick
            r = H * 0.07
            d.ellipse((x - r, H * 0.62 - r, x + r, H * 0.62 + r), fill=(120, 84, 40, 255))
            d.ellipse((x - r * 0.6, H * 0.62 - r * 0.8, x + r * 0.4, H * 0.62 + r * 0.2), fill=(255, 220, 150, 255))
    return im.resize((period, h), Image.LANCZOS)


def script_tile(size=512, seed=7):
    """Dense faint handwriting wallpaper; letters near the edges are drawn again on the far side so it tiles."""
    rnd = random.Random(seed)
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    letters = "abcdefghijklmnopqrstuvwxyzGRDWQ"
    for _ in range(420):
        f = ImageFont.truetype(WONDER, rnd.randint(26, 58))
        ch = rnd.choice(letters)
        x, y = rnd.randrange(size), rnd.randrange(size)
        a = rnd.randint(20, 46)
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                d.text((x + dx, y + dy), ch, font=f, fill=(255, 255, 255, a))
    return im


if __name__ == "__main__":
    os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)
    for k, ch in GLYPHS.items():
        icon(ch).save(os.path.join(OUT, "icons", k + ".png"))
    hexagon().save(os.path.join(OUT, "node_hex.png"))
    glow().save(os.path.join(OUT, "node_glow.png"))
    chain().save(os.path.join(OUT, "chain_h.png"))
    coin().save(os.path.join(OUT, "coin.png")); gem().save(os.path.join(OUT, "gem.png"))
    lf, lg = lantern()
    lf.save(os.path.join(OUT, "lantern_frame.png")); lg.save(os.path.join(OUT, "lantern_glass.png"))
    watch_track().save(os.path.join(OUT, "track_h.png"))
    watch_track().rotate(90, expand=True).save(os.path.join(OUT, "track_v.png"))
    chain().rotate(90, expand=True).save(os.path.join(OUT, "chain_v.png"))
    script_tile().save(os.path.join(OUT, "script_tile.png"))
    print("wrote", OUT)
