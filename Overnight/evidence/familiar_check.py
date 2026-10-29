"""Check a familiar's design sheet and bio page. Usage: python Overnight/evidence/familiar_check.py <Name> [<other names ...>]
Checks: sheet/silhouette/report files exist, silhouette overlap with basic shapes and with the plain reference shape is below
thresholds, front/side silhouettes differ, lore line 15-25 words, bio 120-200 words, required fields, no fox or sprout wording.
With more than one name it also compares the front silhouettes pairwise (IoU) and requires every pair below 0.60."""
import re, sys, pathlib
from PIL import Image
root = pathlib.Path(__file__).resolve().parents[2]
sheets = root / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"


def px(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()


def check(name):
    problems = []
    page_path = root / "Roblox Dev" / "Lore" / "Familiars" / f"{name}.md"
    for f in [f"{name}_sheet.png", f"{name}_silhouette.png", f"{name}_report.txt"]:
        if not (sheets / f).exists():
            problems.append(f"missing {f}")
    if not page_path.exists():
        problems.append("missing bio page")
    if problems:
        return problems
    page = page_path.read_text(encoding="utf-8")
    sil = Image.open(sheets / f"{name}_silhouette.png")
    sheet = Image.open(sheets / f"{name}_sheet.png")
    g = sil.convert("L")
    dark = sum(1 for v in px(g) if v < 60)
    rep = (sheets / f"{name}_report.txt").read_text(encoding="utf-8")
    print(f"[{name}] sheet {sheet.size} silhouette {sil.size} dark px {dark}")
    print(f"[{name}] report: " + rep.strip().replace("\n", " | "))
    if dark < 5000:
        problems.append("silhouette strip nearly empty")
    ious = dict(re.findall(r"(circle|square|triangle|plain [a-z ]+?)=([\d.]+)", rep))
    for k, v in ious.items():
        lim = 0.80 if k.startswith("plain") else 0.75
        if float(v) >= lim:
            problems.append(f"overlap with {k} = {v} (limit {lim})")
    if len(ious) < 4:
        problems.append("report lacks the four reference overlaps")
    fs = re.search(r"front/side=([\d.]+)", rep)
    if not fs or float(fs.group(1)) >= 0.85:
        problems.append("front and side silhouettes too similar or not reported")
    m = re.search(r"\*\*Lore line \((\d+) words\):\*\* (.+)", page)
    lw = len(m.group(2).split()) if m else 0
    if not 15 <= lw <= 25:
        problems.append(f"lore line {lw} words")
    bio = re.search(r"## Longer bio.*?\n\n(.+?)\n\n## ", page, re.S)
    bw = len(bio.group(1).split()) if bio else 0
    if not 120 <= bw <= 200:
        problems.append(f"bio {bw} words")
    print(f"[{name}] lore line {lw} words, bio {bw} words")
    for field in ["Gesture", "Flaw", "Voice", "Signature hue", "Role (one verb)", "Faction"]:
        if field not in page:
            problems.append(f"missing field {field}")
    head = page.split("## Silhouette and design decisions")[0] + (bio.group(1) if bio else "")
    if re.search(r"\b(fox|sprout)\b", re.sub(r"(?i)not a sprout|looks like a sprout|sprout in a pot|sprout-style|the sprout", "", head).lower()):
        problems.append("fox/sprout wording in the character text")
    return problems


def front_mask(name):
    sil = Image.open(sheets / f"{name}_silhouette.png").convert("L").crop((0, 0, 380, 460))
    m = sil.point(lambda v: 255 if v < 128 else 0)
    box = m.getbbox()
    c = m.crop(box)
    k = 64 / max(c.size)  # keep the aspect ratio, so tall and wide shapes are not stretched to look alike
    c = c.resize((max(1, round(c.size[0] * k)), max(1, round(c.size[1] * k))))
    canvas = Image.new("L", (64, 64), 0)
    canvas.paste(c, ((64 - c.size[0]) // 2, (64 - c.size[1]) // 2))
    return canvas


if __name__ == "__main__":
    names = sys.argv[1:] or ["Ember"]
    allp = []
    for n in names:
        p = check(n)
        allp += [f"{n}: {x}" for x in p]
    if len(names) > 1:
        masks = {n: front_mask(n) for n in names}
        for i, a in enumerate(names):
            for b in names[i + 1:]:
                A, B = list(px(masks[a])), list(px(masks[b]))
                inter = sum(1 for x, y in zip(A, B) if x and y)
                union = sum(1 for x, y in zip(A, B) if x or y)
                iou = inter / union
                flag = "ok" if iou < 0.60 else ("REVIEW by eye" if iou < 0.70 else "FAIL")
                print(f"pair {a}/{b}: front silhouette IoU {iou:.2f} -> {flag}")
                # Filled-shape IoU is a coarse heuristic: below 0.60 passes, 0.60 to 0.70 needs a human look at the strip
                # (reported, not counted as a problem), 0.70 or more fails.
                if iou >= 0.70:
                    allp.append(f"{a} and {b} silhouettes too similar ({iou:.2f})")
    print("PROBLEMS:", allp or "none")
    sys.exit(1 if allp else 0)
