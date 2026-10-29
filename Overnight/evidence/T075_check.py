import re, sys, pathlib
from PIL import Image
root = pathlib.Path(__file__).resolve().parents[2]
sheets = root / "Roblox Dev" / "Assets" / "Characters" / "Design Sheets"
page = (root / "Roblox Dev" / "Lore" / "Familiars" / "Ember.md").read_text(encoding="utf-8")
problems = []
for f in ["Ember_sheet.png", "Ember_silhouette.png", "Ember_report.txt"]:
    if not (sheets / f).exists():
        problems.append(f"missing {f}")
if not problems:
    sheet = Image.open(sheets / "Ember_sheet.png")
    sil = Image.open(sheets / "Ember_silhouette.png")
    print("sheet", sheet.size, "silhouette", sil.size)
    # silhouette strip must be black on white only (greyscale test), apart from the label text
    g = sil.convert("L")
    dark = sum(1 for v in (g.get_flattened_data() if hasattr(g, "get_flattened_data") else g.getdata()) if v < 60)
    print("dark pixels in silhouette strip:", dark)
    if dark < 5000:
        problems.append("silhouette strip nearly empty")
    rep = dict(re.findall(r"(\w[\w /]*?)=([\d.]+)", (sheets / "Ember_report.txt").read_text(encoding="utf-8")))
    print("report:", (sheets / "Ember_report.txt").read_text(encoding="utf-8").replace("\n", " | "))
    for k in ["circle", "square", "triangle", "plain flame"]:
        if k not in rep:
            problems.append(f"report lacks {k}")
        elif float(rep[k]) >= 0.75 and k != "plain flame":
            problems.append(f"overlap with {k} too high: {rep[k]}")
        elif k == "plain flame" and float(rep[k]) >= 0.80:
            problems.append(f"overlap with plain flame too high: {rep[k]}")
    fs = re.search(r"front/side=([\d.]+)", (sheets / "Ember_report.txt").read_text(encoding="utf-8"))
    if not fs or float(fs.group(1)) >= 0.85:
        problems.append("front and side silhouettes too similar or not reported")
# page checks: lore line 15-25 words, bio 120-200 words, banned design words
m = re.search(r"\*\*Lore line \((\d+) words\):\*\* (.+)", page)
lore = m.group(2).strip() if m else ""
lw = len(lore.split())
print("lore line words:", lw)
if not 15 <= lw <= 25:
    problems.append(f"lore line {lw} words")
bio = re.search(r"## Longer bio.*?\n\n(.+?)\n\n## ", page, re.S)
bw = len(bio.group(1).split()) if bio else 0
print("bio words:", bw)
if not 120 <= bw <= 200:
    problems.append(f"bio {bw} words")
for field in ["Gesture", "Flaw", "Voice", "Signature hue", "Role (one verb)"]:
    if field not in page:
        problems.append(f"missing field {field}")
head = page.split("## Silhouette and design decisions")[0] + bio.group(1) if bio else page
if re.search(r"\b(fox|sprout)\b", head.lower().replace("not a sprout", "")):
    problems.append("fox/sprout word in the character text")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
