"""Warn before a Studio script hits Roblox's 200,000-character Source limit. Reads Studio_Export/*.luau (the mirror of the Studio scripts).
Run: python tools/script_sizes.py   -> lists scripts over 150,000 characters; exit code 1 if any is over 190,000 (move a block into a ModuleScript first, see Known Issues.md, 'GameClient size')."""
import pathlib
import sys

LIMIT, WARN, FAIL = 200_000, 150_000, 190_000
root = pathlib.Path(__file__).resolve().parent.parent / "Studio_Export"
rows = sorted(((len(p.read_text(encoding="utf-8").replace("\r\n", "\n")), p.name) for p in root.glob("*.luau")), reverse=True)
bad = False
for n, name in rows:
    if n >= WARN:
        flag = "FAIL" if n >= FAIL else "WARN"
        bad |= n >= FAIL
        print(f"{flag} {name}: {n:,} of {LIMIT:,} ({LIMIT - n:,} left)")
print(f"{len(rows)} scripts checked; largest {rows[0][1]} {rows[0][0]:,}")
sys.exit(1 if bad else 0)
