"""Familiar eye design system (T111): the eye shape reads the personality. Each of the 12 familiars gets an eye design from its three tone words (Roblox Dev/Lore/Familiars/<Name>.md, "Voice"),
described by parameters (shape, size, spacing, lid, pupil, highlights, tilt, extras) and drawn on a plain face disc in the familiar's identity colour.
Writes Roblox Dev/Assets/Characters/Eyes/_eye_sheet.png (12 faces at 256 px), _eye_sheet_small.png (the same at 48 px, the size they have on a card) and _eye_report.txt, and Roblox Dev/Design/Eye Design System.md.
Checks: all 12 parameter sets differ in at least two parameters; every pair differs in the 48 px greyscale render (mean absolute difference at least 6 on a 0 to 255 scale); the eyes are visible at 48 px
(dark or light eye pixels cover at least 1.5 percent of the face disc, except the deliberately eyeless Mourner). Run with the Hunyuan3D venv. Concept drawings, not the model textures."""
import pathlib, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Eyes"
NOTE = fc.ROOT / "Roblox Dev" / "Design" / "Eye Design System.md"
S = 4  # supersample

# shape: round, oval, almond, slit, half (flat-bottom half lid), lens (ring), point (small bright star), hollow (pale void), none
EYES = {
    "Ember": dict(shape="round", size="large", gap="wide", lid="open", pupil="dot", hl=1, tilt=0, extra="", why="eager, earnest, small: large, round, wide-set, one highlight"),
    "MothLantern": dict(shape="round", size="large", gap="normal", lid="half-top", pupil="high", hl=2, tilt=0, extra="soft lashes", why="dreamy, drifting, kind: heavy top lid, pupils drifting up, two highlights"),
    "BrassHound": dict(shape="round", size="medium", gap="close", lid="open", pupil="dot", hl=1, tilt=0, extra="big shine", why="loyal, cheerful, literal: plain round eyes, close together, one big shine"),
    "Sentinel": dict(shape="slit", size="medium", gap="normal", lid="open", pupil="none", hl=0, tilt=0, extra="visor glow", why="stiff, polite, literal: two vertical visor slits, perfectly straight"),
    "Frostling": dict(shape="oval", size="large", gap="wide", lid="open", pupil="dot", hl=1, tilt=0, extra="pink cheeks", why="cheerful, blunt, childlike: tall ovals, wide apart, cheeks"),
    "Gargoyle": dict(shape="half", size="medium", gap="normal", lid="flat-bottom", pupil="dot", hl=0, tilt=0, extra="pale blue", why="gruff, deadpan, loyal: flat-bottom half lids, pale, no highlight"),
    "Ward": dict(shape="almond", size="small", gap="normal", lid="half-top", pupil="dot", hl=1, tilt=-8, extra="crow's feet, one raised brow", why="patient, wry, weathered: narrow almonds, crow's feet, one raised brow"),
    "Archivist": dict(shape="lens", size="large", gap="normal", lid="open", pupil="dot", hl=0, tilt=0, extra="tick marks", why="precise, dry, tidy: concentric lens rings with tick marks"),
    "Mourner": dict(shape="none", size="none", gap="none", lid="veiled", pupil="none", hl=0, tilt=0, extra="veil seam, two lash marks", why="soft, formal, faceless: no eyes, a veil seam and two lash marks"),
    "MirrorChorister": dict(shape="almond", size="medium", gap="normal", lid="open", pupil="dot", hl=1, tilt=12, extra="mirror-white, shard highlight", why="sly, curious, kind: almonds tilted up, mirror white, a shard highlight"),
    "StarDrake": dict(shape="point", size="small", gap="wide", lid="open", pupil="none", hl=0, tilt=0, extra="halo", why="remote, grand, lonely: small distant star points with a halo"),
    "GreyVeilWraith": dict(shape="hollow", size="unequal", gap="normal", lid="open", pupil="none", hl=0, tilt=0, extra="two unequal pale voids", why="sparse, echoing, unmoored: two pale voids of unequal size"),
}
SIZE = {"small": 0.055, "medium": 0.085, "large": 0.115, "unequal": 0.085, "none": 0}
GAP = {"close": 0.10, "normal": 0.15, "wide": 0.205, "none": 0}
SZ = 256


def draw(name, spec, colour):
    W = SZ * S
    im = Image.new("RGB", (W, W), (28, 26, 38))
    d = ImageDraw.Draw(im, "RGBA")
    cx, cy, R = W / 2, W / 2, W * 0.45
    face = tuple(int(c * 0.55 + 90 * 0.45) for c in colour)
    d.ellipse([cx - R, cy - R, cx + R, cy + R], fill=face + (255,))
    ink = (22, 18, 28)
    light = (245, 244, 236)
    r = SIZE[spec["size"]] * W
    gap = GAP[spec["gap"]] * W
    ey = cy - W * 0.03
    shape = spec["shape"]
    eyes = [(cx - gap, ey), (cx + gap, ey)]
    if shape == "none":
        d.line([(cx, cy - R * 0.55), (cx, cy + R * 0.35)], fill=ink + (255,), width=int(W * 0.012))
        for sx in (-1, 1):
            d.arc([cx + sx * W * 0.12 - W * 0.05, cy - W * 0.06, cx + sx * W * 0.12 + W * 0.05, cy + W * 0.02], 20, 160, fill=ink + (255,), width=int(W * 0.008))
        return im.resize((SZ, SZ), Image.LANCZOS)
    for i, (ex, ey2) in enumerate(eyes):
        side = -1 if i == 0 else 1
        rr = r * (0.7 if (shape == "hollow" and i == 1) else 1.0)
        if shape in ("round", "oval", "half", "almond"):
            w, h = rr, rr
            if shape == "oval":
                h = rr * 1.45
            if shape == "almond":
                h = rr * 0.6
                w = rr * 1.25
            if shape == "half":
                h = rr * 0.8
            fill = (176, 210, 228) if spec["extra"] == "pale blue" else (light if shape == "almond" and "mirror" in spec["extra"] else ink)
            if spec["extra"] == "pale blue" or "mirror" in spec["extra"]:
                d.ellipse([ex - w, ey2 - h, ex + w, ey2 + h], fill=fill + (255,), outline=ink + (255,), width=int(W * 0.007))
            else:
                d.ellipse([ex - w, ey2 - h, ex + w, ey2 + h], fill=ink + (255,))
            if shape == "half":
                d.rectangle([ex - w * 1.05, ey2 + h * 0.15, ex + w * 1.05, ey2 + h * 1.1], fill=face + (255,))
                d.line([(ex - w, ey2 + h * 0.15), (ex + w, ey2 + h * 0.15)], fill=ink + (255,), width=int(W * 0.008))
            if spec["lid"] == "half-top":
                d.rectangle([ex - w * 1.1, ey2 - h * 1.1, ex + w * 1.1, ey2 - h * 0.15], fill=face + (255,))
                d.arc([ex - w, ey2 - h, ex + w, ey2 + h], 190, 350, fill=ink + (255,), width=int(W * 0.01))
            if spec["pupil"] in ("dot", "high") and not (shape == "almond" and "mirror" in spec["extra"]):
                py = ey2 - (h * 0.25 if spec["pupil"] == "high" else 0)
                for k in range(spec["hl"]):
                    hx = ex - w * (0.35 - 0.5 * k)
                    hy = py - h * (0.35 - 0.3 * k)
                    d.ellipse([hx - w * 0.2, hy - w * 0.2, hx + w * 0.2, hy + w * 0.2], fill=light + (255,))
            if "mirror" in spec["extra"]:
                d.polygon([(ex - w * 0.5, ey2 - h * 0.3), (ex - w * 0.1, ey2 - h * 0.6), (ex + w * 0.15, ey2 - h * 0.2)], fill=(255, 255, 255, 255))
            if spec["tilt"]:
                d.line([(ex - side * w * 1.3, ey2 - h * 1.5 - side * spec["tilt"] * 0.4), (ex + side * w * 1.1, ey2 - h * 1.4 + side * spec["tilt"] * 0.4)], fill=ink + (255,), width=int(W * 0.008))
            if "crow" in spec["extra"]:
                for k in (-1, 0, 1):
                    d.line([(ex + side * w * 1.2, ey2 + k * h * 0.5), (ex + side * w * 1.9, ey2 + k * h * 0.9)], fill=ink + (200,), width=int(W * 0.005))
                if i == 0:
                    d.line([(ex - w * 1.1, ey2 - h * 2.1), (ex + w * 1.1, ey2 - h * 1.7)], fill=ink + (255,), width=int(W * 0.01))
            if "lashes" in spec["extra"]:
                for k in (-1, 0, 1):
                    d.line([(ex + side * w * 0.9, ey2 - h * 0.6), (ex + side * w * 1.4, ey2 - h * (0.9 + 0.25 * k))], fill=ink + (255,), width=int(W * 0.005))
        elif shape == "slit":
            d.rectangle([ex - r * 0.35, ey2 - r * 1.5, ex + r * 0.35, ey2 + r * 1.5], fill=(255, 214, 120, 255), outline=ink + (255,), width=int(W * 0.006))
            d.rectangle([ex - r * 0.7, ey2 - r * 1.7, ex + r * 0.7, ey2 + r * 1.7], outline=ink + (255,), width=int(W * 0.008))
        elif shape == "lens":
            rr = rr * 1.35
            for k, f in enumerate((1.0, 0.7, 0.4)):
                d.ellipse([ex - rr * f, ey2 - rr * f, ex + rr * f, ey2 + rr * f], outline=ink + (255,), width=int(W * 0.014), fill=(light if k == 2 else None))
            d.ellipse([ex - rr * 0.18, ey2 - rr * 0.18, ex + rr * 0.18, ey2 + rr * 0.18], fill=ink + (255,))
            for a in range(0, 360, 45):
                x0 = ex + np.cos(np.radians(a)) * rr * 1.05
                y0 = ey2 + np.sin(np.radians(a)) * rr * 1.05
                x1 = ex + np.cos(np.radians(a)) * rr * 1.25
                y1 = ey2 + np.sin(np.radians(a)) * rr * 1.25
                d.line([(x0, y0), (x1, y1)], fill=ink + (255,), width=int(W * 0.006))
        elif shape == "point":
            for k, a in enumerate((60, 30, 12)):
                rad = rr * (2.4 - k * 0.8)
                d.ellipse([ex - rad, ey2 - rad, ex + rad, ey2 + rad], fill=(255, 255, 255, a))
            d.polygon([(ex, ey2 - rr * 1.6), (ex + rr * 0.35, ey2 - rr * 0.35), (ex + rr * 1.6, ey2), (ex + rr * 0.35, ey2 + rr * 0.35), (ex, ey2 + rr * 1.6), (ex - rr * 0.35, ey2 + rr * 0.35), (ex - rr * 1.6, ey2), (ex - rr * 0.35, ey2 - rr * 0.35)], fill=(255, 255, 255, 255))
        elif shape == "hollow":
            d.ellipse([ex - rr, ey2 - rr, ex + rr, ey2 + rr], fill=(236, 238, 246, 255))
            d.ellipse([ex - rr * 1.5, ey2 - rr * 1.5, ex + rr * 1.5, ey2 + rr * 1.5], outline=(236, 238, 246, 90), width=int(W * 0.006))
    return im.resize((SZ, SZ), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    names = list(EYES)
    imgs = {n: draw(n, EYES[n], fc.parse(fc.LORE / f"{n}.md")["colour"]) for n in names}
    # checks
    bad = 0
    rows = []
    keys = ("shape", "size", "gap", "lid", "pupil", "hl", "tilt", "extra")
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            same = sum(EYES[a][k] == EYES[b][k] for k in keys)
            if len(keys) - same < 2:
                bad += 1
                rows.append(f"PARAM CLASH {a} / {b}")
    small = {n: np.array(im.resize((48, 48), Image.LANCZOS).convert("L")).astype(float) for n, im in imgs.items()}
    mind, pair = 1e9, ""
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            m = float(np.abs(small[a] - small[b]).mean())
            if m < mind:
                mind, pair = m, f"{a} / {b}"
            if m < 6:
                bad += 1
                rows.append(f"TOO SIMILAR AT 48 PX {a} / {b} ({m:.1f})")
    for n in names:
        if EYES[n]["shape"] == "none":
            continue
        arr = small[n]
        yy, xx = np.mgrid[0:48, 0:48]
        disc = np.hypot(xx - 24, yy - 24) < 21.6
        face = np.median(arr[disc])
        cover = float((np.abs(arr[disc] - face) > 60).mean())
        if cover < 0.015:
            bad += 1
            rows.append(f"EYES NOT VISIBLE AT 48 PX {n} ({cover:.3f})")
    sheet = Image.new("RGB", (4 * SZ, 3 * (SZ + 30)), (28, 26, 38))
    small_sheet = Image.new("RGB", (12 * 48 + 11 * 6, 48 + 20), (28, 26, 38))
    d = ImageDraw.Draw(sheet)
    ds = ImageDraw.Draw(small_sheet)
    for i, n in enumerate(names):
        x, y = (i % 4) * SZ, (i // 4) * (SZ + 30)
        sheet.paste(imgs[n], (x, y))
        d.text((x + SZ // 2, y + SZ + 14), n, font=fc.font("georgiab.ttf", 15), fill=(236, 205, 120), anchor="mm")
        small_sheet.paste(imgs[n].resize((48, 48), Image.LANCZOS), (i * 54, 0))
    sheet.save(OUT / "_eye_sheet.png")
    small_sheet.save(OUT / "_eye_sheet_small.png")
    md = ["# Eye Design System (T111)", "",
          "The eye shape reads the personality. Each familiar's eyes come from its three tone words (the voice line in `Lore/Familiars/<Name>.md`), written as parameters and drawn by `tools/eye_system.py` on a plain face disc in the identity colour. Sheets: `Assets/Characters/Eyes/_eye_sheet.png` (256 px) and `_eye_sheet_small.png` (48 px, the size on a card). Concept drawings: the real eyes are on the model textures, and only Ember, Frostling, Brass Hound and Gargoyle have drawn faces today (see [[Expressions]]). Look UNVERIFIED by the user.", "",
          "## Rules",
          "1. **Size reads age and openness:** large = young or earnest (Ember, Frostling, Moth-Lantern), small = old, far or guarded (Ward, Star Drake).",
          "2. **Spacing reads trust:** wide = open and naive, close = loyal and focused.",
          "3. **Lids read mood:** open = alert, heavy top lid = dreamy or weary, flat-bottom half lid = deadpan.",
          "4. **Highlights read warmth:** one big highlight = eager, two = dreamy, none = guarded or mechanical.",
          "5. **Shape reads species of mind:** round and oval = living and soft, almond = clever, slit and lens = mechanical, point and hollow = otherworldly, none = a mask.",
          "6. **One look per familiar:** no two share more than six of the eight parameters, and no two look alike at 48 px.", "",
          "| Familiar | Eyes | Why |", "|---|---|---|"]
    for n in names:
        e = EYES[n]
        md.append(f"| [[{n}]] | {e['shape']}, {e['size']}, gap {e['gap']}, lid {e['lid']}, pupil {e['pupil']}, {e['hl']} highlight(s){', ' + e['extra'] if e['extra'] else ''} | {e['why']} |")
    md += ["", f"Checks (`Overnight/evidence/T111.txt`): all 12 parameter sets differ in at least two parameters; every pair differs at 48 px (smallest mean difference {mind:.1f} on a 0 to 255 scale, {pair}, limit 6); eyes visible at 48 px."]
    NOTE.write_text("\n".join(md) + "\n", encoding="utf-8")
    rep = "\n".join(rows) + f"\nfamiliars: {len(names)} smallest 48 px pair difference {mind:.1f} ({pair}) problems: {bad}\n"
    (OUT / "_eye_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad else 0)


main()
