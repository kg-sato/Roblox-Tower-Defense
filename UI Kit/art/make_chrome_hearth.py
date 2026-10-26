"""Warm storybook-fantasy skin ("Hearth") for the UI Kit chrome: wooden panels, gold trim, bright jewel-tone buttons with
a thick brown outline. Built from the fishing-game lesson: welcoming means warm, chunky, high contrast, few small details.

    python "UI Kit/art/make_chrome_hearth.py"            writes the warm versions over art/out/<same names>.png
    python "UI Kit/art/make_chrome_hearth.py" --restore  puts back the dark (Sols) chrome from art/out_sols_chrome_backup

Same sprite names, sizes and 9-slice margins as make_chrome.py, like make_chrome_sols.py. Never run make_chrome.py after this.
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_chrome as C
from PIL import Image, ImageDraw

SS = C.SS
OUT = C.OUT
BACKUP = os.path.join(HERE, "out_sols_chrome_backup")
EDGE = (36, 20, 10)  # thick dark brown outline
GOLD = (255, 214, 120)

BASE = {
    "green": (84, 198, 78), "blue": (66, 158, 238), "red": (232, 70, 70), "yellow": (255, 202, 62),
    "orange": (255, 148, 52), "purple": (158, 100, 228), "pink": (240, 110, 180), "gray": (140, 128, 116),
    "dark": (84, 56, 36), "night": (96, 66, 150),
}


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def trim_line(img, inset, color, alpha=170, corners=(True,) * 4, r=20):
    """Thin gold line just inside the border, drawn on top of an existing sprite."""
    W, H = img.size
    big = img.resize((W * SS, H * SS), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    d.rounded_rectangle([inset * SS, inset * SS, (W - inset) * SS - 1, (H - inset) * SS - 1], radius=max(r - inset, 2) * SS,
                        outline=color + (alpha,), width=3 * SS, corners=corners)
    return C.down(big, W, H)


def button(W, H, name):
    return C.glossy(W, H, 44, BASE[name], outline=EDGE, o=9, lip=14)


def pill(W, H, name):
    return C.glossy(W, H, 64, BASE[name], outline=EDGE, o=9, lip=12)


def header(W, H, name):
    return C.glossy(W, H, 52, BASE[name], outline=EDGE, o=9, corners=(True, True, False, False), lip=0, lip_on=False, gloss=0.5)


def wood_panel(W, H, light=False):
    top, bot = ((140, 96, 60), (92, 60, 38)) if light else ((100, 64, 40), (60, 38, 24))
    img = C.panel(W, H, 56, top, bot, border=EDGE, o=12, rim=GOLD + (110,))
    return img


def pill_dark(W, H):
    return C.glossy(W, H, H // 2, (70, 46, 30), outline=EDGE, o=7, lip=0, gloss=0.25, lip_on=False)


def bar_track(W, H):
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = C.put(canvas, Image.new("RGBA", canvas.size, EDGE + (255,)), 0, 0, C.rmask(W, H, H // 2))
    o = 7
    iw, ih = W - 2 * o, H - 2 * o
    inner = C.vgrad(iw * SS, ih * SS, (30, 18, 10), (72, 48, 30))
    canvas = C.put(canvas, inner, o * SS, o * SS, C.rmask(iw, ih, ih // 2))
    return C.down(canvas, W, H)


def bar_fill(W, H, name):
    return C.glossy(W, H, H // 2, BASE[name], outline=EDGE, o=5, lip=0, gloss=0.55, lip_on=False)


def close_button(S):
    img = C.glossy(S, S, int(S * 0.26), BASE["red"], outline=EDGE, o=9, lip=12, gloss=0.5)
    big = img.resize((S * SS, S * SS), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    c = S * SS // 2
    arm = int(S * SS * 0.2)
    wth = int(S * SS * 0.13)
    for sign in (1, -1):
        d.line([(c - arm, c - sign * arm - 6 * SS), (c + arm, c + sign * arm - 6 * SS)], fill=EDGE + (255,), width=wth + 10 * SS)
    for sign in (1, -1):
        d.line([(c - arm, c - sign * arm - 6 * SS), (c + arm, c + sign * arm - 6 * SS)], fill=(255, 250, 235, 255), width=wth)
    return C.down(big, S, S)


def slot(S):
    canvas = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    canvas = C.put(canvas, Image.new("RGBA", canvas.size, EDGE + (255,)), 0, 0, C.rmask(S, S, 30))
    o = 9
    iw = S - 2 * o
    inner = C.vgrad(iw * SS, iw * SS, (40, 24, 14), (86, 58, 38))
    canvas = C.put(canvas, inner, o * SS, o * SS, C.rmask(iw, iw, 24))
    sh = C.alpha_grad(iw * SS, 22 * SS, 140, 0, (0, 0, 0))
    canvas = C.put(canvas, sh, o * SS, o * SS, C.rmask(iw, 22, 14, (True, True, False, False)))
    return C.down(canvas, S, S)


def card(W, H, name):
    base = BASE[name]
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    canvas = C.put(canvas, Image.new("RGBA", canvas.size, EDGE + (255,)), 0, 0, C.rmask(W, H, 52))
    o1 = 10
    iw, ih = W - 2 * o1, H - 2 * o1
    col = C.vgrad(iw * SS, ih * SS, C.tint(base, 0.3), C.shade(base, 0.12))
    canvas = C.put(canvas, col, o1 * SS, o1 * SS, C.rmask(iw, ih, 44))
    o2 = 26
    jw, jh = W - 2 * o2, H - 2 * o2
    body = C.vgrad(jw * SS, jh * SS, (88, 58, 38), (54, 34, 22))
    canvas = C.put(canvas, body, o2 * SS, o2 * SS, C.rmask(jw, jh, 30))
    gl = C.alpha_grad(iw * SS, 26 * SS, 100, 0)
    canvas = C.put(canvas, gl, o1 * SS, o1 * SS, C.rmask(iw, 26, 14, (True, True, False, False)))
    return C.down(canvas, W, H)


def main():
    if "--restore" in sys.argv:
        for f in os.listdir(BACKUP):
            shutil.copy2(os.path.join(BACKUP, f), os.path.join(OUT, f))
        print("restored", len(os.listdir(BACKUP)), "dark chrome sprites")
        return
    manifest = json.load(open(os.path.join(OUT, "manifest.json"), encoding="utf-8"))
    if not os.path.isdir(BACKUP):
        os.makedirs(BACKUP)
        for n, m in manifest.items():
            if not n.startswith("icon_"):
                p = os.path.join(OUT, m["file"])
                if os.path.exists(p):
                    shutil.copy2(p, BACKUP)
        print("dark chrome backed up to", BACKUP)
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
    save("panel_dark", wood_panel(512, 512))
    save("panel_light", wood_panel(512, 512, True))
    for c in ("green", "blue", "orange", "purple", "red", "pink", "yellow", "night"):
        save("header_" + c, header(512, 168, c))
    save("pill_dark", pill_dark(320, 112))
    save("bar_track", bar_track(384, 96))
    for c in ("green", "blue", "orange", "red", "purple", "yellow", "pink"):
        save("bar_fill_" + c, bar_fill(384, 96, c))
    save("close_x", close_button(176))
    save("badge_red", C.badge(128))
    save("slot_dark", slot(256))
    for c in ("blue", "orange", "purple", "green", "pink", "yellow", "red"):
        save("card_" + c, card(384, 512, c))
    print("wrote", n_done, "warm chrome sprites")


if __name__ == "__main__":
    main()
