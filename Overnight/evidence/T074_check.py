import re, sys, pathlib, collections
root = pathlib.Path(__file__).resolve().parents[2]
page = (root / "Roblox Dev" / "Lore" / "Cast List - 12 Familiars.md").read_text(encoding="utf-8")
rows = []
for line in page.splitlines():
    m = re.match(r"\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$", line)
    if m:
        rows.append(m.groups())
problems = []
if len(rows) != 12:
    problems.append(f"expected 12 familiars, found {len(rows)}")
rar = collections.Counter(r[2] for r in rows)
if dict(rar) != {"Common": 4, "Rare": 4, "Epic": 2, "Legendary": 2}:
    problems.append(f"rarity counts {dict(rar)}")
names = [r[1] for r in rows]
roles = [r[3] for r in rows]
if len(set(names)) != 12:
    problems.append("duplicate names")
if len(set(roles)) != 12:
    problems.append(f"duplicate role verbs: {[k for k, v in collections.Counter(roles).items() if v > 1]}")
allowed = {"Lantern Keepers", "Clockwork Guild", "Hollow Court", "Star Choir", "Unaligned"}
facs = {r[4] for r in rows}
if not facs <= allowed:
    problems.append(f"unknown factions {facs - allowed}")
if not {"Lantern Keepers", "Clockwork Guild", "Hollow Court", "Star Choir"} <= facs:
    problems.append("not all four factions present")
for r in rows:
    if len(r[6].split()) > 20:
        problems.append(f"hook too long: {r[1]}")
    if re.search(r"\b(fox|sprout)\b", (r[1] + " " + r[3]).lower()):
        problems.append(f"banned design family: {r[1]}")
    if len(r[3].split()) != 1:
        problems.append(f"role not one verb: {r[1]} -> {r[3]}")
print("familiars:", len(rows), dict(rar), "factions:", dict(collections.Counter(r[4] for r in rows)))
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
