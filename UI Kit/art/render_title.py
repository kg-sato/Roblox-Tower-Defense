"""Renders text in Beyond Wonderland (Chris Hansen, free for commercial use, see fonts/readme.txt) to a PNG with alpha,
for titles and key labels that Roblox's built-in fonts can't match.

    python "UI Kit/art/render_title.py" "GUARDIAN GRID" out.png [--px 220] [--style gold|ivory|ember]

Look: inky letters with a brushed metal fill (top light, bottom deep), a thin dark outline, a soft warm glow behind.
The image is trimmed to the text plus the glow margin; height scales with --px (the font size in pixels)."""
import argparse, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "fonts", "Beyond Wonderland.ttf")
STYLES = {  # top colour, bottom colour, glow colour, outline colour
    "gold": ((255, 238, 196), (196, 128, 44), (255, 170, 70), (34, 18, 6)),
    "ivory": ((250, 246, 236), (176, 168, 156), (210, 220, 255), (14, 12, 18)),
    "ember": ((255, 214, 150), (200, 70, 30), (255, 100, 40), (30, 8, 4)),
}


def render(text, px=220, style="gold", spacing=0.06):
    top, bot, glow_c, line_c = STYLES[style]
    f = ImageFont.truetype(FONT, px)
    pad = int(px * 0.35)
    l, t, r, b = f.getbbox(text)
    track = int(px * spacing)
    w = (r - l) + track * max(0, len(text) - 1) + pad * 2
    h = (b - t) + pad * 2
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    x = pad - l
    for ch in text:  # manual letter spacing
        d.text((x, pad - t), ch, font=f, fill=255)
        x += f.getlength(ch) + track
    # fill: vertical gradient with a bright band a third of the way down (brushed metal)
    grad = Image.new("RGB", (1, h))
    for y in range(h):
        k = min(1, max(0, (y - pad) / max(1, h - 2 * pad)))
        band = max(0, 1 - abs(k - 0.32) * 6) * 0.35
        c = [int(top[i] + (bot[i] - top[i]) * k) for i in range(3)]
        grad.putpixel((0, y), tuple(min(255, int(v + (255 - v) * band)) for v in c))
    fill = grad.resize((w, h))
    outline = mask.filter(ImageFilter.MaxFilter(max(3, (px // 40) | 1)))
    glow = mask.filter(ImageFilter.MaxFilter(max(3, (px // 18) | 1))).filter(ImageFilter.GaussianBlur(px * 0.12))
    out = Image.new("RGBA", (w, h), glow_c + (0,))
    out.putalpha(glow.point(lambda v: int(v * 0.4)))
    line = Image.new("RGBA", (w, h), line_c + (255,))
    line.putalpha(outline)
    out = Image.alpha_composite(out, line)
    body = fill.convert("RGBA")
    body.putalpha(mask)
    out = Image.alpha_composite(out, body)
    return out.crop(out.getbbox())


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("text"); ap.add_argument("out")
    ap.add_argument("--px", type=int, default=220)
    ap.add_argument("--style", default="gold", choices=list(STYLES))
    a = ap.parse_args()
    im = render(a.text, a.px, a.style)
    im.save(a.out)
    print(a.out, im.size)
