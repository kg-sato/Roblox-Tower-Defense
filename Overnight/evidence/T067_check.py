import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
page = root / "Roblox Dev" / "Lore" / "Story" / "Stage Captions.md"
rows = []
for line in page.read_text(encoding="utf-8").splitlines():
    m = re.match(r"\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*([a-z ]+?)\s*\|\s*(\[.*\])\s*\|", line)
    if m:
        rows.append((int(m.group(2)), m.group(3), m.group(4)))
banned = ["epic", "grind", "nerf", "doom", "blood", "slaughter", "die", "hurry", "prophecy", "chosen one"]
problems = []
if len(rows) != 40:
    problems.append(f"expected 40 captions, found {len(rows)}")
caps = [c for _, _, c in rows]
if len(set(caps)) != len(caps):
    problems.append("duplicate captions")
for stage, slot, cap in rows:
    if not re.fullmatch(r"\[ [A-Z' -]+ \]", cap):
        problems.append(f"bad format: {cap}")
        continue
    words = cap[2:-2].split()
    if not 2 <= len(words) <= 5:
        problems.append(f"{len(words)} words: {cap}")
    low = cap.lower()
    for b in banned:
        if re.search(r"\b" + re.escape(b) + r"\b", low):
            problems.append(f"banned word {b}: {cap}")
intro = {s for s, slot, _ in rows if slot == "intro"}
missing = [s for s in range(1, 26) if s not in intro]
if missing:
    problems.append(f"stages without intro: {missing}")
# every intro caption should also appear in its chapter script (consistency)
chapters = (root / "Roblox Dev" / "Lore" / "Story").glob("Chapter *.md")
text = "\n".join(p.read_text(encoding="utf-8") for p in chapters)
not_in_chapters = [c for s, slot, c in rows if slot == "intro" and c not in text]
print(f"captions={len(rows)} unique={len(set(caps))} intros={len(intro)}")
print("intro captions not found in chapter scripts:", not_in_chapters or "none")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
