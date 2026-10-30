"""T081: 40-icon set (status, currency, rarity, faction). FLUX schnell via comfy_generate, then forced into one
palette (near-black ground, antique gold, cream) on a round badge with alpha. Usage: make_icons_set.py [names...]"""
import io, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import comfy_generate as cg
from PIL import Image, ImageDraw, ImageOps, ImageFilter

OUTD = os.path.join(cg.HERE, "icons_set"); RAW = os.path.join(OUTD, "raw")
SZ = 512
GROUND, GOLD, CREAM = (12, 10, 8), (201, 162, 74), (244, 232, 196)
S = {"burn": "a single flame", "chill": "a six-armed snowflake crystal", "stun": "a spiral of dizzy stars around a bolt",
     "mark": "a crosshair target ring", "hush": "a closed mouth with a finger-to-lips, or a bell with a slash",
     "coin": "a round coin with a lantern emblem", "gem": "a faceted diamond gemstone"}
R = {"common": "one simple plain round pebble-shaped badge, one ring", "uncommon": "a badge with a single leaf sprig",
     "rare": "a badge with a four-pointed star", "epic": "a badge with a winged crest",
     "legendary": "a badge with a radiant crown and rays", "mythic": "a badge with an eye in a sunburst of rays and stars"}
F = {"lantern_keepers": "a hanging oil lantern", "clockwork_guild": "a cogwheel gear with a key",
     "hollow_court": "a hollow-eyed theatre mask with a thorn crown", "star_choir": "a five-pointed star with radiating song lines"}
ITEMS = {}
for k, v in S.items(): ITEMS[("status_" if k in ("burn","chill","stun","mark","hush") else "currency_") + k] = v
for k, v in R.items(): ITEMS["rarity_" + k] = v
for k, v in F.items(): ITEMS["faction_" + k] = v
STYLE = ("vintage copperplate engraving, fine hatching and crosshatch line work, antique gold ink lines on a pure black "
         "background, cream white highlights, one large centred emblem filling 85 percent of the frame, no border, no frame, no circle, high contrast, no colour other than gold and cream, no text, no letters")

def finish(png):
    g = Image.open(io.BytesIO(png)).convert("L").resize((SZ, SZ), Image.LANCZOS)
    g = ImageOps.autocontrast(g, cutoff=1)
    rgb = ImageOps.colorize(g, GROUND, CREAM, mid=GOLD, blackpoint=30, midpoint=150, whitepoint=235)
    m = Image.new("L", (SZ * 4, SZ * 4), 0); d = ImageDraw.Draw(m)
    d.ellipse((SZ * 4 * .03,) * 2 + (SZ * 4 * .97,) * 2, fill=255)
    m = m.resize((SZ, SZ), Image.LANCZOS)
    im = rgb.convert("RGBA"); im.putalpha(m)
    # thin gold rim ring: same stroke on every icon
    ImageDraw.Draw(im).ellipse((SZ*.03, SZ*.03, SZ*.97, SZ*.97), outline=GOLD + (255,), width=6)
    return im

def main():
    names = sys.argv[1:] or list(ITEMS)
    os.makedirs(RAW, exist_ok=True)
    cg.start_server()
    for n in names:
        p = "%s. %s, symbol of %s" % ("solid pure black background", STYLE, ITEMS[n]) if False else \
            "Black background. An emblem icon of %s. %s" % (ITEMS[n], STYLE)
        png = cg.run_one(p, 11, 768, 4)
        open(os.path.join(RAW, n + ".png"), "wb").write(png)
        finish(png).save(os.path.join(OUTD, n + ".png"))
        print(n, flush=True)

if __name__ == "__main__":
    main()
