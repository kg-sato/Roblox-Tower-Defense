"""Dark-fantasy ("Sols" vibe) skin for the UI Kit chrome: buttons, panels, headers, cards, bars, close button, badge.

    python "UI Kit/art/make_chrome_sols.py"            writes the dark versions over art/out/<same names>.png
    python "UI Kit/art/make_chrome_sols.py" --restore  puts the candy versions back (from art/out_candy_backup)

Same sprite names, sizes and 9-slice margins as make_chrome.py, so every existing screen re-skins without code
changes. Look: near-black midnight navy bodies, one bright accent line per colour token, pale corner brackets,
square-ish corners. Icons are not touched (they come from ComfyUI, see Roblox Dev/Research/Image Generation Workflow.md).
Never run make_chrome.py after this: it would write the candy chrome back (and its vector icons over the ingested ones).
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_chrome as C  # reuse helpers only; main() is guarded
from PIL import Image, ImageDraw

SS = C.SS
OUT = C.OUT
BACKUP = os.path.join(HERE, "out_candy_backup")

# accent (the bright line and glow) and deep body colour per token
ACCENT = {
    "green": (70, 235, 160), "blue": (80, 175, 255), "red": (255, 76, 90), "yellow": (255, 208, 96),
    "orange": (255, 154, 66), "purple": (186, 128, 255), "pink": (255, 116, 204), "gray": (176, 184, 208),
    "dark": (122, 134, 176), "night": (140, 120, 235),
}
DEEP = {
    "green": (8, 66, 48), "blue": (12, 40, 92), "red": (84, 12, 26), "yellow": (88, 58, 8),
    "orange": (88, 40, 8), "purple": (44, 20, 100), "pink": (88, 16, 64), "gray": (34, 40, 58),
    "dark": (12, 14, 26), "night": (20, 16, 52),
}
EDGE = (3, 4, 10)  # outer outline
BRACKET = (226, 232, 255)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def brackets(canvas, W, H, inset, length, width, color=BRACKET, corners=(True, True, True, True)):
    """Thin pale L-shaped corner brackets (the Sols frame signature), drawn at SS resolution."""
    d = ImageDraw.Draw(canvas)
    s = SS
    i, L, w = inset * s, length * s, width * s
    x0, y0, x1, y1 = i, i, W * s - 1 - i, H * s - 1 - i
    col = color + (255,)
    if corners[0]:
        d.rectangle([x0, y0, x0 + L, y0 + w], fill=col)
        d.rectangle([x0, y0, x0 + w, y0 + L], fill=col)
    if corners[1]:
        d.rectangle([x1 - L, y0, x1, y0 + w], fill=col)
        d.rectangle([x1 - w, y0, x1, y0 + L], fill=col)
    if corners[2]:
        d.rectangle([x0, y1 - w, x0 + L, y1], fill=col)
        d.rectangle([x0, y1 - L, x0 + w, y1], fill=col)
    if corners[3]:
        d.rectangle([x1 - L, y1 - w, x1, y1], fill=col)
        d.rectangle([x1 - w, y1 - L, x1, y1], fill=col)


def frame(W, H, r, top, bottom, accent, line=3, inset=7, bracket=(30, 5, 3), corners=(True,) * 4, lip=0, glow=0.0):
    """Dark body, thin accent line inset from the edge, pale corner brackets. lip = extra dark strip at the bottom."""
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = C.put(canvas, Image.new("RGBA", canvas.size, EDGE + (255,)), 0, 0, C.rmask(W, H, r, corners))
    o = 3
    iw, ih = W - 2 * o, H - 2 * o
    body = C.vgrad(iw * SS, ih * SS, top, bottom)
    canvas = C.put(canvas, body, o * SS, o * SS, C.rmask(iw, ih, max(r - o, 1), corners))
    if glow > 0:  # soft accent light along the top inner edge
        gl = C.alpha_grad(iw * SS, int(ih * 0.5) * SS, int(255 * glow), 0, accent)
        canvas = C.put(canvas, gl, o * SS, o * SS, C.rmask(iw, int(ih * 0.5), max(r - o, 1), (corners[0], corners[1], False, False)))
    d = ImageDraw.Draw(canvas)
    s = SS
    d.rounded_rectangle([inset * s, inset * s, (W - inset) * s - 1, (H - inset - lip) * s - 1], radius=max(r - inset, 1) * s,
                        outline=accent + (255,), width=line * s, corners=corners)
    if lip:
        d.rectangle([o * s, (H - o - lip) * s, (W - o) * s - 1, (H - o) * s - 1], fill=mix(top, EDGE, 0.7) + (255,))
    if bracket:
        brackets(canvas, W, H, bracket[2], bracket[0], bracket[1], corners=corners)
    return C.down(canvas, W, H)


def button(W, H, name):
    a, deep = ACCENT[name], DEEP[name]
    return frame(W, H, 18, mix(deep, a, 0.30), mix(deep, EDGE, 0.35), a, line=4, inset=8, bracket=(26, 5, 4), lip=14, glow=0.22)


def pill(W, H, name):
    a, deep = ACCENT[name], DEEP[name]
    return frame(W, H, H // 2 - 4, mix(deep, a, 0.30), mix(deep, EDGE, 0.35), a, line=4, inset=8, bracket=None, lip=0, glow=0.2)


def header(W, H, name):
    a, deep = ACCENT[name], DEEP[name]
    return frame(W, H, 20, mix(deep, a, 0.22), mix(deep, EDGE, 0.5), a, line=3, inset=8, bracket=(34, 5, 4),
                 corners=(True, True, False, False), glow=0.18)


def card(W, H, name):
    a, deep = ACCENT[name], DEEP[name]
    return frame(W, H, 26, mix(deep, (20, 22, 40), 0.55), (6, 7, 16), a, line=5, inset=10, bracket=(40, 6, 4), glow=0.12)


def panel_sprite(W, H, light=False):
    top, bot = ((22, 26, 48), (10, 12, 26)) if light else ((12, 15, 32), (4, 6, 14))
    return frame(W, H, 22, top, bot, (150, 160, 200), line=3, inset=12, bracket=(52, 6, 5))


def pill_dark(W, H):
    return frame(W, H, H // 2 - 6, (14, 16, 30), (4, 5, 12), (122, 134, 176), line=3, inset=7, bracket=None)


def bar_track(W, H):
    return frame(W, H, 10, (2, 3, 8), (14, 16, 30), (122, 134, 176), line=3, inset=5, bracket=None)


def bar_fill(W, H, name):
    a = ACCENT[name]
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = C.put(canvas, Image.new("RGBA", canvas.size, EDGE + (255,)), 0, 0, C.rmask(W, H, 10))
    o = 4
    iw, ih = W - 2 * o, H - 2 * o
    fill = C.vgrad(iw * SS, ih * SS, mix(a, (255, 255, 255), 0.35), mix(a, EDGE, 0.45))
    canvas = C.put(canvas, fill, o * SS, o * SS, C.rmask(iw, ih, 7))
    gl = C.alpha_grad((iw - 12) * SS, int(ih * 0.35) * SS, 150, 0)
    canvas = C.put(canvas, gl, (o + 6) * SS, (o + 4) * SS, C.rmask(iw - 12, int(ih * 0.35), 5, (True, True, False, False)))
    return C.down(canvas, W, H)


def close_button(S):
    img = frame(S, S, 14, (110, 14, 30), (40, 4, 12), ACCENT["red"], line=4, inset=7, bracket=(26, 4, 3), glow=0.25)
    big = img.resize((S * SS, S * SS), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    c = S * SS // 2
    arm = int(S * SS * 0.2)
    wth = int(S * SS * 0.09)
    for sign in (1, -1):
        d.line([(c - arm, c - sign * arm), (c + arm, c + sign * arm)], fill=(255, 236, 236, 255), width=wth)
    return C.down(big, S, S)


def badge(S):
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    d.ellipse([0, 0, S * SS - 1, S * SS - 1], fill=EDGE + (255,))
    b = int(S * SS * 0.07)
    d.ellipse([b, b, S * SS - 1 - b, S * SS - 1 - b], fill=(255, 208, 96, 255))  # thin gold ring
    b2 = int(S * SS * 0.13)
    inner = C.vgrad(S * SS - 2 * b2, S * SS - 2 * b2, (230, 40, 60), (96, 8, 24))
    m = Image.new("L", inner.size, 0)
    ImageDraw.Draw(m).ellipse([0, 0, inner.width - 1, inner.height - 1], fill=255)
    canvas = C.put(canvas, inner, b2, b2, m)
    return C.down(canvas, S, S)


def slot(S):
    return frame(S, S, 14, (4, 5, 12), (16, 18, 34), (90, 100, 140), line=3, inset=6, bracket=None)


def main():
    if "--restore" in sys.argv:
        for f in os.listdir(BACKUP):
            shutil.copy2(os.path.join(BACKUP, f), os.path.join(OUT, f))
        print("restored", len(os.listdir(BACKUP)), "candy sprites")
        return
    manifest = json.load(open(os.path.join(OUT, "manifest.json"), encoding="utf-8"))
    if not os.path.isdir(BACKUP):
        os.makedirs(BACKUP)
        for n, m in manifest.items():
            if not n.startswith("icon_"):
                p = os.path.join(OUT, m["file"])
                if os.path.exists(p):
                    shutil.copy2(p, BACKUP)
        shutil.copy2(os.path.join(OUT, "manifest.json"), BACKUP)
        print("candy chrome backed up to", BACKUP)
    n_done = 0

    def save(name, img):
        nonlocal n_done
        m = manifest[name]
        assert img.size == (m["w"], m["h"]), (name, img.size, m["w"], m["h"])
        img.save(os.path.join(OUT, m["file"]), optimize=True)
        n_done += 1

    for c in ("green", "blue", "red", "yellow", "orange", "purple", "pink", "gray", "dark"):
        save("btn_" + c, button(384, 160, c))
        save("pill_btn_" + c, pill(384, 128, c))
    save("panel_dark", panel_sprite(512, 512))
    save("panel_light", panel_sprite(512, 512, True))
    for c in ("green", "blue", "orange", "purple", "red", "pink", "yellow", "night"):
        save("header_" + c, header(512, 168, c))
    save("pill_dark", pill_dark(320, 112))
    save("bar_track", bar_track(384, 96))
    for c in ("green", "blue", "orange", "red", "purple", "yellow", "pink"):
        save("bar_fill_" + c, bar_fill(384, 96, c))
    save("close_x", close_button(176))
    save("badge_red", badge(128))
    save("slot_dark", slot(256))
    for c in ("blue", "orange", "purple", "green", "pink", "yellow", "red"):
        save("card_" + c, card(384, 512, c))
    print("wrote", n_done, "dark-fantasy chrome sprites")


if __name__ == "__main__":
    main()
