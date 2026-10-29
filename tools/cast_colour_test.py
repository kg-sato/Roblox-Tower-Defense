"""Colour test for the 12 familiars (T088): identity colours under normal vision, protanopia, deuteranopia and tritanopia.
Usage: python tools/cast_colour_test.py            (tests SIGNATURE, the identity colours)
       python tools/cast_colour_test.py --body      (tests BODY, the body colours first declared in the cards, for the record)
Simulation: 3x3 matrices on linear RGB (Machado-style values written from memory, UNVERIFIED against the paper), then CIE76 delta E on Lab.
Writes _cast_colour_test.png (swatches under each view). Exit code 1 if any pair is under the limit in normal, protan or deutan."""
import itertools, math, pathlib, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets" / "_cast_colour_test.png"

# Identity colours (UI card frame, name plate, glow), chosen by a search for the best worst-case separation across the four simulations.
SIGNATURE = {
    "Ember": "#D55E00",
    "MothLantern": "#E69F00",
    "BrassHound": "#E3B07A",
    "Sentinel": "#7A5C26",
    "Frostling": "#9ED4F0",
    "Gargoyle": "#4A4C58",
    "Ward": "#7FA0C0",
    "Archivist": "#2BA69A",
    "Mourner": "#1F2230",
    "MirrorChorister": "#0072B2",
    "StarDrake": "#1E2A78",
    "GreyVeilWraith": "#EDEEF4",
}
# Body colours as first declared in the cards (kept for the record; this set fails the test: Gargoyle/Wraith 3.8, Brass Hound/Sentinel 7.2 under deuteranopia).
BODY = {
    "Ember": "#D55E00",
    "MothLantern": "#E69628",
    "BrassHound": "#C4863E",
    "Sentinel": "#C9A24B",
    "Frostling": "#9ED4F0",
    "Gargoyle": "#8C8E98",
    "Ward": "#546C84",
    "Archivist": "#165C5A",
    "Mourner": "#3E4252",
    "MirrorChorister": "#0072B2",
    "StarDrake": "#1E2A78",
    "GreyVeilWraith": "#9698A2",
}
if "--body" in sys.argv:
    SIGNATURE = BODY
    OUT = OUT.with_name("_cast_colour_test_body.png")

M = {
    "normal": [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
    "protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


def lin(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def unlin(c):
    c = max(0, min(1, c))
    return 255 * (12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055)


def rgb(h):
    return [int(h[i:i + 2], 16) for i in (1, 3, 5)]


def sim(h, k):
    c = [lin(v) for v in rgb(h)]
    return [sum(M[k][r][j] * c[j] for j in range(3)) for r in range(3)]


def lab(l):
    r, g, b = [max(0, min(1, v)) for v in l]
    X = 0.4124 * r + 0.3576 * g + 0.1805 * b
    Y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    Z = 0.0193 * r + 0.1192 * g + 0.9505 * b
    X /= 0.95047
    Z /= 1.08883
    f = lambda t: t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    fx, fy, fz = f(X), f(Y), f(Z)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def to_hex(l):
    return tuple(int(round(unlin(v))) for v in l)


def main():
    names = list(SIGNATURE)
    labs = {k: {n: lab(sim(SIGNATURE[n], k)) for n in names} for k in M}
    LIMIT = 15.0
    fails = []
    print(f"colours: {len(names)}; limit delta E {LIMIT} (my rule of thumb from the T030 note)")
    for k in M:
        pairs = sorted((math.dist(labs[k][a], labs[k][b]), a, b) for a, b in itertools.combinations(names, 2))
        low = [p for p in pairs if p[0] < LIMIT]
        print(f"{k}: min delta E {pairs[0][0]:.1f} ({pairs[0][1]} / {pairs[0][2]}); pairs under {LIMIT}: {len(low)}")
        for d, a, b in low:
            print(f"    {d:5.1f}  {a} / {b}")
            if k in ("protan", "deutan", "normal"):
                fails.append((k, a, b, d))
    sw, pad = 120, 10
    W = pad + len(names) * (sw + pad)
    H = pad + 4 * (sw + 34)
    im = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 12)
    except Exception:
        f = ImageFont.load_default()
    for row, k in enumerate(M):
        y = pad + row * (sw + 34)
        d.text((pad, y), k.upper(), fill=(0, 0, 0), font=f)
        for i, n in enumerate(names):
            x = pad + i * (sw + pad)
            d.rectangle([x, y + 16, x + sw, y + 16 + sw - 20], fill=to_hex(sim(SIGNATURE[n], k)), outline=(0, 0, 0))
            d.text((x, y + 16 + sw - 18), n, fill=(0, 0, 0), font=f)
    im.save(OUT)
    print("saved", OUT)
    return fails


if __name__ == "__main__":
    f = main()
    print("RESULT:", "FAIL" if f else "PASS")
    sys.exit(1 if f else 0)
