"""Controller helper for the overnight run: close a batch of finished tasks in one step (saves tokens).
  python tools/night_close.py --lane sim --msg "Two plain sentences." T016="endless mode tested" T025="leaderboard rules added" ...
For each task: its evidence file Overnight/evidence/<id>.txt must start with PASS (else the task is skipped and reported); the task is ticked [x] in Overnight/TODO.md;
then ONE commit through tools/overnight/checkpoint.py (the sanctioned route) with the first task as --task, and one ledger line per task (same hash, its own three-word description).
Descriptions must be exactly three words."""
import re, subprocess, sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
args = sys.argv[1:]
lane = args[args.index("--lane") + 1] if "--lane" in args else "-"
msg = args[args.index("--msg") + 1] if "--msg" in args else ""
pairs = [a for a in args if re.match(r"^T\d+=", a)]
if not pairs or not msg:
    sys.exit('usage: night_close.py --lane L --msg "two sentences" T###="three words" ...')
ok = []
for a in pairs:
    tid, desc = a.split("=", 1)
    ev = root / "Overnight" / "evidence" / f"{tid}.txt"
    first = ev.read_text(encoding="utf-8-sig", errors="replace").lstrip().splitlines()[0].strip().upper() if ev.exists() and ev.stat().st_size else ""
    if len(desc.split()) != 3:
        print("skip", tid, "description must be three words")
    elif not first.startswith("PASS"):
        print("skip", tid, "evidence missing or not PASS:", first[:40])
    else:
        ok.append((tid, desc))
if not ok:
    sys.exit("nothing to close")
todo = root / "Overnight" / "TODO.md"
if len(msg) > 240 or len([x for x in re.split(r"(?<=[.!?])\s+", msg) if x]) > 2:
    sys.exit("message must be two plain sentences, at most 240 characters")
first_id, first_desc = ok[0]
r = subprocess.run([sys.executable, str(root / "tools" / "overnight" / "checkpoint.py"), "-m", msg, "--task", first_id, "--desc", first_desc, "--status", "attested", "--lane", lane,
                    "--evidence", f"Overnight/evidence/{first_id}.txt"], cwd=root, capture_output=True, text=True)
print((r.stdout + r.stderr).strip()[-200:])
if r.returncode:
    sys.exit("checkpoint failed; nothing ticked or logged")
s2 = todo.read_text(encoding="utf-8")
for tid, _ in ok:
    s2 = s2.replace(f"- [ ] {tid} |", f"- [x] {tid} |", 1)
todo.write_text(s2, encoding="utf-8", newline="\n")
h = subprocess.run(["git", "log", "-1", "--format=%h"], cwd=root, capture_output=True, text=True).stdout.strip()
with open(root / "Overnight" / "LEDGER.md", "a", encoding="utf-8") as f:
    for tid, desc in ok[1:]:
        f.write(f'{tid} | commit {h} | "{desc}" | attested | {lane} | Overnight/evidence/{tid}.txt\n')
print("closed", ", ".join(t for t, _ in ok), "in commit", h)
