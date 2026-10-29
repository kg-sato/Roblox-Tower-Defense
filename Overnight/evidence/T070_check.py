import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
page = root / "Roblox Dev" / "Lore" / "NPC - Tamsin the Supplier.md"
rows = []
for line in page.read_text(encoding="utf-8").splitlines():
    m = re.match(r"\|\s*(SH-\d+)\s*\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|\s*$", line)
    if m:
        rows.append(m.groups())
banned = ["epic", "grind", "nerf", "doom", "blood", "slaughter", "limited", "hurry", "last chance",
          "robux", "discount", "sale", "free"]
problems = []
if len(rows) != 30:
    problems.append(f"expected 30 texts, found {len(rows)}")
for sid, use, text in rows:
    is_item = re.match(r"(Plain|Verdigris|Moonsilver|Starlit|Lamp-oil|Harbour|Cathedral|Foundry|Amber|Moon-pale|Star-white)", use)
    is_category = use.startswith("category")
    limit = 20 if is_item else 16
    n = len(text.split())
    if not is_category and n > limit:
        problems.append(f"{sid}: {n} words (limit {limit})")
    low = text.lower()
    for b in banned:
        if re.search(r"\b" + re.escape(b) + r"\b", low):
            problems.append(f"{sid}: banned {b}")
    if re.search(r"\d", text):
        problems.append(f"{sid}: contains a digit (prices belong to the UI)")
print(f"texts={len(rows)}")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
