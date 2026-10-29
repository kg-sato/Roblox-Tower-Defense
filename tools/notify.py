"""Silent emergency push to the user's phone through ntfy (no call, no account). Claude may use it only for emergencies:
a bug it cannot solve alone, something destroyed, or a major error. Usage:
  python tools/notify.py --reason "short plain sentence" [--dry-run]
Refused: while Overnight/ACTIVE exists, between 21:00 and 05:00 local time, and more than once per 30 minutes.
Topic and server come from ~/.claude/ntfy.json (kept off the repo). Priority is low, so the phone should not sound or vibrate.
"""
import argparse, json, sys, time, urllib.request
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
home = Path.home() / ".claude"
ap = argparse.ArgumentParser()
ap.add_argument("--reason", required=True)
ap.add_argument("--dry-run", action="store_true")
a = ap.parse_args()

if (root / "Overnight" / "ACTIVE").exists():
    sys.exit("refused: the overnight loop is armed; notifications are off overnight")
hour = datetime.now().hour
if hour >= 21 or hour < 5:
    sys.exit("refused: quiet hours (21:00 to 05:00)")
reason = " ".join(a.reason.split())[:200]
if not reason:
    sys.exit("refused: empty reason")
stamp = home / "ntfy_last.txt"
if stamp.exists() and time.time() - float(stamp.read_text(encoding="utf-8")) < 30 * 60:
    sys.exit("refused: one notification per 30 minutes")

cfg = json.loads((home / "ntfy.json").read_text(encoding="utf-8"))
url = cfg["server"].rstrip("/") + "/" + cfg["topic"]
if a.dry_run:
    print("dry run, would send:", reason)
    sys.exit(0)
req = urllib.request.Request(url, data=reason.encode("utf-8"), method="POST",
                             headers={"Title": "Claude needs you", "Priority": "low", "Tags": "warning"})
with urllib.request.urlopen(req, timeout=15) as r:
    print("sent, status", r.status)
stamp.write_text(str(time.time()), encoding="utf-8")
