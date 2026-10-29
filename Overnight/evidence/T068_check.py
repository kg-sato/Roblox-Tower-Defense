import re, sys, pathlib, collections
root = pathlib.Path(__file__).resolve().parents[2]
page = root / "Roblox Dev" / "Lore" / "Story" / "Familiar Dialogue.md"
rows = []
for line in page.read_text(encoding="utf-8").splitlines():
    m = re.match(r"\|\s*(FD-\d+)\s*\|\s*(.+?),\s*(\d)\s*\|\s*(.+?)\s*\|\s*$", line)
    if m:
        rows.append((m.group(1), m.group(2), int(m.group(3)), m.group(4)))
banned = ["epic", "grind", "nerf", "doom", "blood", "slaughter", "hurry", "prophecy"]
problems = []
pairs = collections.Counter(p for _, p, _, _ in rows)
if len(rows) != 18:
    problems.append(f"expected 18 exchanges, found {len(rows)}")
if len(pairs) != 9:
    problems.append(f"expected 9 pairs, found {len(pairs)}")
for p, n in pairs.items():
    got = sorted(k for _, q, k, _ in rows if q == p)
    if got != [1, 2]:
        problems.append(f"pair {p} has exchanges {got}")
names = {"Ember", "Moth-Lantern", "Ward", "Clockwork Owl", "Frostling", "Mourner", "Gargoyle",
         "Brass Hound", "Sentinel", "Star Drake", "Mirror-cat", "Wraith"}
for fid, pair, k, text in rows:
    for part in text.split(" / "):
        m = re.match(r"([A-Za-z\- ]+?):\s*(.+)", part)
        if not m:
            problems.append(f"{fid}: bad part {part!r}")
            continue
        speaker, line = m.groups()
        if speaker.strip() not in names:
            problems.append(f"{fid}: unknown speaker {speaker}")
        # a speaker may include a second sentence; count words per spoken part
        n = len(line.split())
        if n > 12:
            problems.append(f"{fid}: {n} words in {part!r}")
        for b in banned:
            if re.search(r"\b" + b + r"\b", line.lower()):
                problems.append(f"{fid}: banned word {b}")
print(f"exchanges={len(rows)} pairs={len(pairs)}")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
