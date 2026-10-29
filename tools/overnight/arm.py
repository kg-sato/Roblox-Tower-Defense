"""Arm or disarm the overnight loop. Run this yourself before bed; Claude is not allowed to.
  python tools/overnight/arm.py [--hours 8] [--max-iter 60]     arm (creates branch overnight/<date>, snapshots control files)
  python tools/overnight/arm.py --off                           disarm
Refuses to arm if tracked files have uncommitted changes (commit or stash your own work first) so the overnight
commits contain only overnight work. The place file Claude.rbxl is ignored by this check."""
import argparse, hashlib, json, shutil, subprocess, sys, time
from pathlib import Path

root = Path(__file__).resolve().parents[2]
ov = root / "Overnight"
ap = argparse.ArgumentParser()
ap.add_argument("--hours", type=float, default=8)
ap.add_argument("--max-iter", type=int, default=60)
ap.add_argument("--off", action="store_true")
ap.add_argument("--confirm-tonight", action="store_true", help="the user's yes for tonight; required every night")
a = ap.parse_args()


def git(*x):
    return subprocess.run(["git", *x], cwd=root, capture_output=True, text=True).stdout.strip()


if a.off:
    (ov / "ACTIVE").unlink(missing_ok=True)
    print("disarmed")
    sys.exit(0)

if not a.confirm_tonight:
    sys.exit("refusing: arming needs the user's confirmation for tonight. Run with --confirm-tonight, yourself, each night.")
dirty = [l for l in git("status", "--porcelain", "--untracked-files=no").splitlines() if "Claude.rbxl" not in l and "Overnight/PROGRESS.md" not in l]  # checkpoint.py appends to PROGRESS.md after each commit
if dirty:
    sys.exit("uncommitted tracked changes, commit or stash first:\n" + "\n".join(dirty[:20]))
branch = "overnight/" + time.strftime("%Y-%m-%d")
cur = git("branch", "--show-current")
if not cur.startswith("overnight/"):
    r = subprocess.run(["git", "switch", "-c", branch], cwd=root, capture_output=True, text=True)
    if r.returncode:
        r = subprocess.run(["git", "switch", branch], cwd=root, capture_output=True, text=True)
        if r.returncode:
            sys.exit(r.stderr)
store = Path.home() / ".claude" / "overnight_protected"
store.mkdir(parents=True, exist_ok=True)
guard = [".claude/settings.json", "Overnight/POLICY.md"] + [str(p.relative_to(root)).replace("\\", "/") for p in (root / "tools" / "overnight").glob("*.py")]
hashes = {}
for rel in guard:
    f = root / rel
    if f.exists():
        hashes[rel] = hashlib.sha256(f.read_bytes()).hexdigest()
        shutil.copy2(f, store / rel.replace("/", "__"))
now = time.time()
cfg = {"night": time.strftime("%Y-%m-%d"), "start": now, "deadline": now + a.hours * 3600, "max_iterations": a.max_iter, "branch": git("branch", "--show-current"), "base": git("rev-parse", "HEAD"), "hashes": hashes}
(ov / "ACTIVE").write_text(json.dumps(cfg, indent=1), encoding="utf-8")
(ov / "state.json").write_text(json.dumps({"iter": 0, "attempts": {}, "verified": {}}), encoding="utf-8")
(ov / "evidence").mkdir(exist_ok=True)
with open(ov / "PROGRESS.md", "a", encoding="utf-8") as f:
    f.write(f"\n## Run {time.strftime('%Y-%m-%d %H:%M')} on {cfg['branch']} ({a.hours} h, {a.max_iter} loops)\n")
print(f"armed on {cfg['branch']} until {time.strftime('%H:%M', time.localtime(cfg['deadline']))}, max {a.max_iter} loops")
