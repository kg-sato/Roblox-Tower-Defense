"""Paints the loading / menu art with local ComfyUI (FLUX schnell) on black, then cuts each to a PNG with alpha.

    python "UI Kit/art/make_menu_art.py" eye clock tree [--variants 3] [--seed 1]

Outputs: UI Kit/art/menu_art/<name>_s<seed>.png (raw) and <name>_s<seed>_a.png (alpha). Black background is turned into
transparency by brightness (light-on-black art reads as glowing), plus a soft round mask for round subjects.
Stop the ComfyUI server afterwards (it holds VRAM)."""
import argparse, os, sys, io, time
from PIL import Image, ImageFilter, ImageChops, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import comfy_generate as cg  # noqa: E402

OUT = os.path.join(HERE, "menu_art")
INK = ("monochrome black and white ink etching illustration, intricate cross-hatching and fine linework, highly detailed, "
       "dramatic, eerie, pure black background around the subject, centred, no text, no letters, no watermark")
ART = {
    # mask: "lum" = alpha from brightness, "round" = soft circle, "oval" = soft eye-shaped oval
    "eye": ("extreme close-up of a single wide open human eye, the iris is an intricate clockwork dial with tiny roman numerals "
            "and a glowing sigil at the pupil, long detailed eyelashes, wet glossy highlights, veins, " + INK, "oval"),
    # 2026-10-28 night (review: "a human-eye engraving, not brass clockwork"): the loading screen's great eye
    "brasseye": ("front view of a single giant mechanical steampunk automaton eye, almond shaped, the eyeball is polished ivory "
                 "enamel and the iris is an intricate brass clockwork dial with roman numerals, tiny gears and a glowing amber "
                 "pupil, set in a socket of riveted polished brass and copper plates with engraved filigree, warm golden rim "
                 "light, photorealistic, symmetrical, centred, wide aspect, pure black background, no text, no face, no skin", "oval", (1024, 640)),
    "brassplate": ("close-up of a smooth curved polished brass armour plate with fine engraved filigree and a row of small rivets "
                   "along one edge, warm golden light, photorealistic, fills the whole frame edge to edge, no background, no text", "none"),
    "clock": ("front view of an ornate antique steampunk pocket watch face without hands, aged polished brass and copper, "
              "exposed interlocking gears and cogs visible through cut-outs in the dial, engraved roman numerals on an ivory "
              "enamel chapter ring, rivets, filigree, warm golden rim light, photorealistic, perfectly circular, centred, fills the frame, "
              "pure black background, no text other than numerals, no hands", "round"),
    "gear": ("a single ornate steampunk brass gear wheel seen straight on, many fine teeth, cut-out spokes with filigree, "
             "engraved surface, polished brass with warm highlights, perfectly circular and centred, pure black background", "round"),
    "tree": ("a majestic ancient tree made of glowing white and pale blue light, luminous branches spreading wide like a crown, "
             "glowing roots of light spreading below, tiny sparkles drifting, ethereal, cosmic, symmetrical, centred, "
             "isolated on a pure black background, highly detailed, no ground, no text", "lum"),
    "frame": ("front view of an ornate empty gothic picture frame, baroque filigree of aged copper and bronze, a small "
              "carved gargoyle crest at the top centre, scrollwork and thin chains on the sides, the frame is thin and "
              "elegant, the inside of the frame is completely empty pure black, pure black background outside, "
              "symmetrical, flat front view, no text, no picture inside", "frame", (576, 768)),
    "frame2": ("front view of an empty steampunk picture frame made of polished brass and copper, a small open pocket watch "
               "with roman numerals at the top centre as the crest, little interlocking gears and rivets in the four corners, "
               "thin art nouveau filigree along the sides, Victorian gaslight style, the frame is thin and elegant, the inside "
               "of the frame is completely empty pure black, pure black background outside, symmetrical, flat front view, "
               "no text, no picture inside, no faces, no creatures", "frame", (576, 768)),
    "road_lane": ("wide panoramic painting of a Victorian gaslit city skyline at night seen from a cobbled lane, rows of "
                  "rooftops and chimneys, a distant brass clock tower, warm lit windows, gas lamps, thin fog, a large pale "
                  "moon, deep blue night sky with stars, painterly, atmospheric, no people, no text", "none", (1024, 512)),
    "road_veil": ("wide panoramic painting of a misty violet valley at night where magic shows itself, floating stones with "
                  "glowing runes, ruined arches, soft purple fog, glowing motes, deep violet sky, painterly, atmospheric, "
                  "no people, no text", "none", (1024, 512)),
    "road_stars": ("wide panoramic painting of deep space seen from a stairway of light, a vast galaxy band, nebula clouds "
                   "in pale blue and white, a faint glowing rune circle in the sky, countless stars, cosmic, serene, "
                   "painterly, no planets close up, no people, no text", "none", (1024, 512)),
}


def cut(png, mask):
    im = Image.open(io.BytesIO(png)).convert("RGB")
    w, h = im.size
    lum = im.convert("L")
    if mask == "none":
        return im.convert("RGBA")
    if mask == "lum":
        a = lum.point(lambda v: 0 if v < 12 else min(255, int((v - 12) * 1.6)))
    elif mask == "frame":  # metal is mid-bright; the empty inside and outside are near black
        a = lum.point(lambda v: 0 if v < 18 else min(255, int((v - 18) * 4)))
    else:
        a = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(a)
        if mask == "round":
            d.ellipse((w * 0.035, h * 0.035, w * 0.965, h * 0.965), fill=255)
        else:
            d.ellipse((w * 0.04, h * 0.2, w * 0.96, h * 0.8), fill=255)
        a = a.filter(ImageFilter.GaussianBlur(w * 0.03))
        # keep pure-black areas see-through even inside the mask
        a = ImageChops.multiply(a, lum.point(lambda v: 0 if v < 6 else min(255, v * 6)))
    out = im.convert("RGBA")
    out.putalpha(a)
    return out


def run_wf(wf):
    import json, urllib.parse
    pid = json.loads(cg.api("/prompt", {"prompt": wf}))["prompt_id"]
    for _ in range(900):
        h = json.loads(cg.api("/history/" + pid))
        if pid in h:
            img = h[pid]["outputs"]["9"]["images"][0]
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            return cg.api("/view?" + q, timeout=60)
        time.sleep(1)
    raise TimeoutError("generation timed out")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="+")
    ap.add_argument("--variants", type=int, default=2)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--steps", type=int, default=4)
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    cg.start_server()
    for n in a.names:
        prompt, mask = ART[n][0], ART[n][1]
        wh = ART[n][2] if len(ART[n]) > 2 else (a.size, a.size)
        for v in range(a.variants):
            s = a.seed + v
            t = time.time()
            wf = cg.workflow(prompt, s, a.size, a.steps)
            wf["6"]["inputs"]["width"], wf["6"]["inputs"]["height"] = wh
            png = run_wf(wf)
            open(os.path.join(OUT, "%s_s%d.png" % (n, s)), "wb").write(png)
            cut(png, mask).save(os.path.join(OUT, "%s_s%d_a.png" % (n, s)))
            print(n, s, "%.0fs" % (time.time() - t), flush=True)


if __name__ == "__main__":
    main()
