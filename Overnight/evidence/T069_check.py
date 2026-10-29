import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
page = root / "Roblox Dev" / "Lore" / "NPC - Pip the Apprentice.md"
rows = []
for line in page.read_text(encoding="utf-8").splitlines():
    m = re.match(r"\|\s*(PIP-\d+)\s*\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|\s*$", line)
    if m:
        rows.append(m.groups())
banned = ["epic", "grind", "nerf", "doom", "blood", "slaughter", "hurry!", "prophecy", "robux"]
spoilers = ["ysolde", "marrow", "stopped it", "apprentice who", "motive", "lost someone"]
problems = []
if len(rows) != 36:
    problems.append(f"expected 36 lines, found {len(rows)}")
for pid, pool, text in rows:
    n = len(text.split())
    if n > 14:
        problems.append(f"{pid}: {n} words")
    low = text.lower()
    for b in banned:
        if b in low and b != "hurry!":
            problems.append(f"{pid}: banned {b}")
    for s in spoilers:
        if s in low:
            problems.append(f"{pid}: spoiler {s}")
pools = sorted({p for _, p, _ in rows})
print(f"lines={len(rows)} pools={len(pools)}: {pools}")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
