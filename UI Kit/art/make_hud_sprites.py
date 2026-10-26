"""HUD sprites for the dark-fantasy ("Sols") Lobby HUD: bracket-frame slots, buttons, currency counters, a leaderboard row
and a tutorial chevron. Adds them to art/out and art/extra_manifest.json (so make_uiart.py picks them up).

    python "UI Kit/art/make_hud_sprites.py"

Run with the ComfyUI embedded Python (it has Pillow): ComfyUI/ComfyUI_windows_portable/python_embeded/python.exe
Never run make_chrome.py (it would write the candy chrome back).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_chrome_sols as M  # reuses frame(), mix(), colours
import make_chrome as C
from PIL import Image, ImageDraw, ImageFilter

OUT = C.OUT
EXTRA = os.path.join(HERE, "extra_manifest.json")
extra = json.load(open(EXTRA, encoding="utf-8")) if os.path.exists(EXTRA) else {}

PALE = (226, 232, 255)
STEEL = (122, 134, 176)
GOLD = (255, 208, 96)
CYAN = (90, 205, 255)
VIOLET = (186, 128, 255)


def add(name, img, slice_=None):
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    e = {"file": name + ".png", "w": img.width, "h": img.height}
    if slice_:
        e["slice"] = list(slice_)
    extra[name] = e


def hud_frame(W, H, accent, top=(14, 18, 38), bottom=(4, 6, 16), line=2, bracket=True, glow=0.0, r=8):
    return M.frame(W, H, r, top, bottom, accent, line=line, inset=5, bracket=(22, 4, 2) if bracket else None, glow=glow)


def chevron(S=256):
    # a bold right-pointing chevron: white body, navy outline, a soft gold underglow
    pts = [(0.16, 0.10), (0.50, 0.10), (0.86, 0.50), (0.50, 0.90), (0.16, 0.90), (0.52, 0.50)]
    body = C.icon_from_polys(S, [pts], (255, 255, 255), (206, 212, 236), inner_scale=0.84, outline=(6, 8, 20))
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon([(x * S, y * S) for x, y in pts], fill=GOLD + (200,))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.05))
    out = Image.alpha_composite(glow, body)
    return out


def main():
    # square menu button and hotbar slot (9-slice)
    add("hud_slot", hud_frame(256, 256, STEEL, glow=0.08, r=10), (56, 56, 56, 56))
    add("hud_slot_hot", hud_frame(256, 256, GOLD, top=(30, 24, 10), glow=0.15, r=10), (56, 56, 56, 56))
    # small action buttons (Auto, Quick) and the big Roll button
    add("hud_btn", hud_frame(384, 160, PALE, line=2), (56, 56, 56, 56))
    add("hud_btn_on", hud_frame(384, 160, (90, 235, 160), top=(10, 44, 34), bottom=(3, 14, 12), line=3, glow=0.16), (56, 56, 56, 56))
    add("hud_roll", hud_frame(512, 192, GOLD, top=(58, 40, 8), bottom=(14, 8, 2), line=3, glow=0.28), (64, 64, 64, 64))
    # currency counters (cyan / violet / gold)
    add("hud_counter_cyan", hud_frame(384, 112, CYAN, top=(8, 30, 52), line=3, glow=0.12), (44, 44, 44, 44))
    add("hud_counter_violet", hud_frame(384, 112, VIOLET, top=(30, 16, 62), line=3, glow=0.12), (44, 44, 44, 44))
    add("hud_counter_gold", hud_frame(384, 112, GOLD, top=(52, 38, 8), line=3, glow=0.12), (44, 44, 44, 44))
    # leaderboard row and header (wide, thin)
    add("hud_row", hud_frame(512, 96, (70, 80, 120), top=(10, 12, 28), line=2, bracket=True, r=6), (40, 40, 40, 40))
    # tutorial chevron
    add("icon_chevron", chevron(256))
    json.dump(extra, open(EXTRA, "w", encoding="utf-8"), indent=2)
    print("added", len([k for k in extra if k.startswith("hud_") or k == "icon_chevron"]), "HUD sprites")


if __name__ == "__main__":
    main()
