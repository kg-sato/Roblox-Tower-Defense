"""HUD frame art (2026-10-30): hyperrealistic antique steampunk brass pieces from local ComfyUI (FLUX schnell), on black, cut to alpha by flood fill
from the border (the dark inset stays opaque so text on it is readable).
    python "UI Kit/art/make_hud_art.py" plate_wide plate_roll ring_ult plate_tall crest [--variants 4] [--seed 11]
Outputs UI Kit/art/hud_art/<name>_s<seed>.png (raw) and _a.png (alpha). Stop the ComfyUI server afterwards."""
import argparse, io, os, sys, time
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import comfy_generate as cg  # noqa: E402
import make_menu_art as mm  # noqa: E402

OUT = os.path.join(HERE, "hud_art")
BASE = ("photorealistic macro photograph of antique steampunk hardware, aged polished brass and copper with dark patina in the crevices, "
        "small hex rivets, fine engraved scrollwork, warm golden rim light, hard specular highlights, heavy 3D relief, sculpted, "
        "perfectly flat front view, perfectly symmetrical, pure solid black background outside, no text, no letters, no people")
ART = {
    "plate_wide": ("a wide horizontal rectangular UI plaque frame, thick even riveted brass border with a rope-twist wire edge, "
                   "a rivet in each corner, the inner panel is a smooth empty dark blackened iron plate, border thickness identical on all four sides, " + BASE, (1024, 384)),
    "plate_roll": ("a wide ornate horizontal rectangular button bezel, heavy riveted polished brass border with a twisted rope edge, "
                   "small gears and screws in the corners, the inner panel is an empty dark purple-black glass plate, border thickness identical on all four sides, " + BASE, (1024, 448)),
    "ring_ult": ("a perfectly circular antique pressure gauge bezel seen straight on, thick polished brass ring with rivets, "
                 "a thin outer rope-twist ring, the centre is an empty dark smoked glass disc, no needle, no numbers, " + BASE, (768, 768)),
    "plate_wide2": ("a wide horizontal rectangular UI plaque frame with smooth rounded corners, a thick sculpted brass bevelled border with a twisted rope edge on both sides, "
                    "small rivets spaced only along the middle of the top and bottom edges, no rivets or bolts in the corners, deep inner shadow, "
                    "the inner panel is a smooth empty dark smoked-glass plate, border thickness identical on all four sides, " + BASE, (1024, 384)),
    "plate_roll2": ("a wide horizontal rectangular button bezel with smooth rounded corners, heavy sculpted polished brass border with deep bevel and a twisted rope edge, "
                    "small rivets spaced along the middle of the top and bottom edges only, no corner bolts, the inner panel is an empty glowing amber glass window with a soft warm gradient, "
                    "border thickness identical on all four sides, " + BASE, (1024, 448)),
    "plate_tall": ("a tall vertical rectangular UI panel frame, thick even riveted brass border with a rope-twist wire edge, "
                   "rivets in the corners, the inner panel is a smooth empty dark blackened iron plate, border thickness identical on all four sides, " + BASE, (576, 1024)),
    "crest": ("a small brass winged emblem: spread feathered brass wings either side of a round antique gauge with a glowing amber lamp "
              "at its centre, centred, wide aspect, " + BASE, (1024, 384)),
}

WB = ("hand-painted dark fantasy storybook illustration, whimsical enchanted forest, gold-leaf glowing tree branches and curling vines with tiny leaves and "
      "small glowing buds, warm lantern light, soft golden glow, cream and gold on ink black, delicate engraved runes, curvy organic hand-crafted shapes, "
      "perfectly flat front view, symmetrical, pure solid black background outside, no text, no letters, no people")
ART.update({
    "vine_wide": ("a wide horizontal UI plaque frame whose border is made of two intertwined living golden branches with curling tendrils, small leaves and glowing buds, "
                  "gently wavy outline, the inner panel is empty dark ink-black velvet, border thickness even, " + WB, (1024, 384)),
    "vine_roll": ("a wide horizontal button frame, golden twisting branches and curled tendrils around a warm glowing amber lantern-glass window in the middle, "
                  "tiny glowing runes along the edge, small leaves, the glass window is empty, " + WB, (1024, 448)),
    "vine_tall": ("a tall vertical UI panel frame, a thick golden vine climbing up both sides with curling tendrils and tiny leaves, rounded organic outline, "
                  "the inner panel is empty dark ink-black velvet, " + WB, (576, 1024)),
    "vine_ring": ("a perfectly circular wreath of golden branches and small leaves with tiny glowing runes, thin and delicate, "
                  "the centre is an empty dark ink-black disc, " + WB, (768, 768)),
    "vine_panel": ("a large rectangular window frame with ornate curling golden branch corners, thin golden vine line along the edges, tiny leaves and glowing buds, "
                   "the middle is completely empty dark ink-black, " + WB, (1024, 768)),
})

SB = ("hand-painted storybook illustration of antique steampunk brass hardware with gold leaf highlights and a warm glow, dark ink-black background, "
      "polished aged brass, small rivets, delicate engraved details, whimsical, perfectly flat front view, centred, pure solid black background outside, no text, no letters, no people")
ART.update({
    "gear_big": ("a single large ornate brass cog gear with twelve teeth and a round hub with spokes, " + SB, (768, 768)),
    "gear_small": ("a small brass cog gear with eight teeth and a rivet at the centre, " + SB, (768, 768)),
    "gauge": ("a round antique brass pressure gauge with a glass face, a tiny needle and tick marks, no numbers, " + SB, (768, 768)),
    "pipe_h": ("a short horizontal brass pipe segment with riveted flanges at both ends, straight, thin and wide, " + SB, (1024, 256)),
    "cogchain": ("a horizontal row of five small interlocking brass cogs of different sizes in a line, " + SB, (1024, 320)),
})

IB = ("polished aged brass and black wrought iron Art Nouveau ornament in the style of Hector Guimard, smooth whiplash S-curves ending in small coils, "
      "elegant asymmetric flowing lines, sculpted relief, warm golden rim light, subtle patina, thin delicate lines, dark ink-black background, "
      "perfectly flat front view, pure solid black background outside, no leaves, no flowers, no text, no letters, no people")
ART.update({
    "iron_wide": ("a wide horizontal UI plaque frame, thin brass whiplash curves flowing along the border and curling into small coils at both ends and corners, "
                  "the inner panel is empty dark ink-black, border thickness even, " + IB, (1024, 384)),
    "iron_tall": ("a tall vertical UI panel frame, thin brass whiplash curves running up both sides ending in coils at top and bottom, "
                  "the inner panel is empty dark ink-black, " + IB, (576, 1024)),
    "iron_panel": ("a large rectangular window frame with ornate whiplash-curve corners in brass and wrought iron, thin curved line along the edges, "
                   "the middle is completely empty dark ink-black, " + IB, (1024, 768)),
    "iron_ring": ("a perfectly circular ring of thin brass whiplash curves and small coils, delicate, the centre is an empty dark ink-black disc, " + IB, (768, 768)),
})


def cut(png):
    im = Image.open(io.BytesIO(png)).convert("RGB")
    w, h = im.size
    lum = im.convert("L")
    mask = Image.new("L", (w, h), 255)
    # outside = connected dark region touching the border
    probe = lum.point(lambda v: 0 if v < 26 else 255)  # 0 = dark
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]
    flood = probe.copy()
    for s in seeds:
        if flood.getpixel(s) == 0:
            ImageDraw.floodfill(flood, s, 128)
    a = flood.point(lambda v: 0 if v == 128 else 255)
    out = im.convert("RGBA")
    out.putalpha(a)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="+")
    ap.add_argument("--variants", type=int, default=4)
    ap.add_argument("--seed", type=int, default=11)
    ap.add_argument("--steps", type=int, default=4)
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    cg.start_server()
    for n in a.names:
        prompt, wh = ART[n]
        for v in range(a.variants):
            s = a.seed + v
            t = time.time()
            wf = cg.workflow(prompt, s, 1024, a.steps)
            wf["6"]["inputs"]["width"], wf["6"]["inputs"]["height"] = wh
            png = mm.run_wf(wf)
            open(os.path.join(OUT, "%s_s%d.png" % (n, s)), "wb").write(png)
            cut(png).save(os.path.join(OUT, "%s_s%d_a.png" % (n, s)))
            print(n, s, "%.0fs" % (time.time() - t), flush=True)


if __name__ == "__main__":
    main()
