"""Morning digest: everything that happened in an overnight run (or any time window), in one file the user reads on waking.
  python tools/morning_digest.py [--since "2026-10-29 21:00"] [--push]
Writes Overnight/MORNING.md and a copy in the vault (Roblox Dev/Overnight/Morning <date>.md). Sources: Overnight/LEDGER.md (one line per finished task:
`T### | commit <hash> | "three word desc" | status | lane | evidence`), git log since the window start, Roblox Dev/Notify Log.md (milestone pushes), open and blocked
lines of Overnight/TODO.md, Overnight/denials.log. --push sends a one-line milestone to the phone (tools/notify.py --done). Window start default: the base commit in
Overnight/ACTIVE (or the newest ACTIVE.ended-* file), else 24 hours ago."""
import argparse, json, re, subprocess, sys, time
from datetime import datetime, timedelta
from pathlib import Path

root = Path(__file__).resolve().parents[1]
ap = argparse.ArgumentParser()
ap.add_argument("--since")
ap.add_argument("--push", action="store_true")
a = ap.parse_args()


def git(*args):
    return subprocess.run(["git", *args], cwd=root, capture_output=True, text=True).stdout.strip()


ov = root / "Overnight"
since = a.since
base = None
for f in [ov / "ACTIVE"] + sorted(ov.glob("ACTIVE.ended-*"), reverse=True)[:1]:
    if f.exists():
        try:
            base = json.loads(f.read_text(encoding="utf-8")).get("base")
            if not since and f.stat().st_mtime:
                pass
        except Exception:
            pass
        break
if not since:
    since = (datetime.now() - timedelta(hours=24)).strftime("%Y-%m-%d %H:%M")

log_args = ["log", "--reverse", "--format=%h|%ad|%s", "--date=format:%H:%M"]
commits = git(*log_args, f"{base}..HEAD").splitlines() if base else git(*log_args, f"--since={since}").splitlines()

ledger = []
lp = ov / "LEDGER.md"
if lp.exists():
    for line in lp.read_text(encoding="utf-8").splitlines():
        if re.match(r"^\s*-?\s*T\d+ \|", line):
            ledger.append(line.strip().lstrip("- ").strip())

notes = []
np_ = root / "Roblox Dev" / "Notify Log.md"
if np_.exists():
    for line in np_.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^- (\d{4}-\d{2}-\d{2} \d{2}:\d{2}) (.*)$", line)
        if m and m.group(1) >= since:
            notes.append(f"{m.group(1)} {m.group(2)}")

todo = (ov / "TODO.md")
open_n = blocked = 0
blocked_lines = []
if todo.exists():
    for line in todo.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^- \[( |x|!)\] (T\d+) \| (.*?) \| verify:", line)
        if m:
            if m.group(1) == " ":
                open_n += 1
            elif m.group(1) == "!":
                blocked += 1
                blocked_lines.append(f"{m.group(2)} {m.group(3)}")

denials = []
dp = ov / "denials.log"
if dp.exists():
    denials = [l for l in dp.read_text(encoding="utf-8", errors="replace").splitlines() if l.strip() >= since[:10]][-15:]

unverified = [l for l in ledger if "UNVERIFIED" in l.upper() or "attested" in l.lower()]
by_lane = {}
for l in ledger:
    parts = [p.strip() for p in l.split("|")]
    lane = parts[4] if len(parts) > 4 else "other"
    by_lane.setdefault(lane, []).append(l)

now = datetime.now().strftime("%Y-%m-%d %H:%M")
out = [f"# Morning digest ({now})", f"Window: since {since}" + (f" (base {base[:8]})" if base else ""), "",
       f"**{len(ledger)} tasks finished** (ledger), **{len(commits)} commits**, {len(notes)} phone milestones, {open_n} tasks still open, {blocked} blocked.",
       "Place file: NOT saved by me (save it yourself: File > Save, or Download a Copy). Nothing was pushed or published.", "",
       "## Finished, by lane (task | commit | three words | status | lane | evidence)"]
for lane in sorted(by_lane):
    out.append(f"### {lane}")
    out += [f"- {l}" for l in by_lane[lane]]
if not ledger:
    out.append("(ledger empty)")
out += ["", "## Commits"] + ([f"- {c.split('|')[0]} {c.split('|')[1]} {c.split('|', 2)[2]}" for c in commits] or ["(none)"])
out += ["", "## Phone milestones"] + ([f"- {n}" for n in notes] or ["(none)"])
out += ["", "## Needs you"] + ([f"- blocked: {b}" for b in blocked_lines] or ["- no blocked tasks"]) + ([f"- unverified or attested only: {l}" for l in unverified[:20]] if unverified else [])
if denials:
    out += ["", "## Denied actions (last 15)"] + [f"- {d[:200]}" for d in denials]
text = "\n".join(out) + "\n"
(ov / "MORNING.md").write_text(text, encoding="utf-8", newline="\n")
vault = root / "Roblox Dev" / "Overnight"
vault.mkdir(exist_ok=True)
(vault / f"Morning {datetime.now().strftime('%Y-%m-%d')}.md").write_text(text, encoding="utf-8", newline="\n")
print(text[:1500])
if a.push:
    msg = f"Morning digest ready: {len(ledger)} tasks, {len(commits)} commits, {blocked} blocked. Read Overnight/MORNING.md."
    subprocess.run([sys.executable, "-I", str(root / "tools" / "notify.py"), "--done", msg])
