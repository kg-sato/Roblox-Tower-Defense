"""Character visual lookbook (T104): one sheet per familiar with 6 poses in colour (top row) and greyscale (bottom row), plus an index sheet of all 12.
Poses, all from the real textured model: 1 front, 2 three-quarter, 3 back (Familiars/textured stills, 384 px); 4 idle signature (idle frame 84); 5 attack windup (attack frame 8);
6 attack release (attack frame 11) (Blender workbench stills, 320 px). The flat render backdrop is keyed out (corner colour) and the figure is placed on a neutral card.
Writes Roblox Dev/Assets/Characters/Lookbook/<Name>_lookbook.png, _lookbook_index.png and _lookbook_report.txt.
Checks per familiar: 6 source images exist; the figure fills 45 to 95 percent of the tile height and keeps a margin of 4 px or more from the tile edge; the 6 poses are pairwise different
(mean absolute difference of the cut-out alpha above 1.0 on a 0 to 255 scale); the greyscale row spreads tones (5th to 95th percentile luminance gap of 40 or more). Run with the Hunyuan3D venv."""
import pathlib, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

F3D = fc.ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars"
OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Lookbook"
T = 300
POSES = [("FRONT", "textured", "{n}_tex_front.png"), ("THREE-QUARTER", "textured", "{n}_tex_three_quarter.png"), ("BACK", "textured", "{n}_tex_back.png"),
         ("IDLE", "idle", "{n}_idle_f084.png"), ("ATTACK WINDUP", "attack", "{n}_attack_f008.png"), ("ATTACK RELEASE", "attack", "{n}_attack_f011.png")]
BG = (44, 42, 56)


def cutout(path):
    im = fc.key_out(Image.open(path).convert("RGBA"))
    return im


def tile(im):
    """Fit the cut-out into a T x T tile (bottom-aligned, same scale rule for every pose: figure height at most 88 percent of the tile)."""
    bb = im.getbbox()
    cut = im.crop(bb)
    s = min((T * 0.88) / cut.height, (T * 0.88) / cut.width)
    cut = cut.resize((max(1, int(cut.width * s)), max(1, int(cut.height * s))), Image.LANCZOS)
    canvas = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    canvas.paste(cut, ((T - cut.width) // 2, T - cut.height - 14), cut)
    return canvas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows, bad, index = [], 0, []
    for p in sorted(fc.LORE.glob("*.md")):
        n = p.stem
        f = fc.parse(p)
        tiles, problems = [], []
        for label, folder, pat in POSES:
            path = F3D / folder / pat.format(n=n)
            if not path.exists():
                problems.append("missing " + path.name)
                continue
            tiles.append(tile(cutout(path)))
        if len(tiles) != 6:
            bad += 1
            rows.append(f"{n:16} {'; '.join(problems)}")
            continue
        alphas = [np.array(t.split()[3]).astype(float) for t in tiles]
        heights, margins = [], []
        for a in alphas:
            ys = np.where((a > 40).any(axis=1))[0]
            xs = np.where((a > 40).any(axis=0))[0]
            heights.append((ys.max() - ys.min() + 1) / T)
            margins.append(min(ys.min(), xs.min(), T - 1 - ys.max(), T - 1 - xs.max()))
        diffs = [np.abs(alphas[i] - alphas[j]).mean() for i in range(6) for j in range(i + 1, 6)]
        sheet = Image.new("RGB", (6 * T, 2 * T + 70), BG)
        d = ImageDraw.Draw(sheet)
        d.text((14, 12), f"{f['name'].upper()}  •  {f['faction'].upper()}  •  {f['rarity'].upper()}", font=fc.font("georgiab.ttf", 26), fill=(236, 205, 120))
        d.text((14, 44), f"colour row, then greyscale row   •   identity colour #{f['colour'][0]:02X}{f['colour'][1]:02X}{f['colour'][2]:02X}", font=fc.font("georgia.ttf", 14), fill=(170, 164, 182))
        grey_vals = []
        for i, t in enumerate(tiles):
            x = i * T
            bgc = Image.new("RGBA", (T, T), BG + (255,))
            bgc.alpha_composite(t)
            sheet.paste(bgc.convert("RGB"), (x, 70))
            g = bgc.convert("L")
            gm = np.array(g)[np.array(t.split()[3]) > 40]
            grey_vals.append(gm)
            sheet.paste(g.convert("RGB"), (x, 70 + T))
            d.text((x + T // 2, 70 + 14), POSES[i][0], font=fc.font("georgiab.ttf", 13), fill=(236, 205, 120), anchor="mm")
        allg = np.concatenate(grey_vals)
        spread = float(np.percentile(allg, 95) - np.percentile(allg, 5))
        if not (all(0.45 <= h <= 0.95 for h in heights) and min(margins) >= 4 and min(diffs) > 1.0 and spread >= 40):
            problems.append(f"heights {min(heights):.2f}-{max(heights):.2f} margin {min(margins)} mindiff {min(diffs):.2f} spread {spread:.0f}")
        bad += bool(problems)
        sheet.save(OUT / f"{n}_lookbook.png")
        index.append(sheet.resize((6 * 140, int((2 * T + 70) * 140 / T)), Image.LANCZOS))
        rows.append(f"{n:16} fill {min(heights):.2f}-{max(heights):.2f} margin>={min(margins):2d} min pose diff {min(diffs):5.2f} grey spread {spread:4.0f}  {'; '.join(problems) or 'ok'}")
    if index:
        h = index[0].height
        idx = Image.new("RGB", (index[0].width * 2, h * 6), BG)
        for i, im in enumerate(index):
            idx.paste(im, ((i % 2) * im.width, (i // 2) * h))
        idx.save(OUT / "_lookbook_index.png")
    rep = "\n".join(rows) + f"\nfamiliars: {len(rows)} problems: {bad}\n"
    (OUT / "_lookbook_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad or len(rows) != 12 else 0)


main()
