"""Push to the user's phone through ntfy (no call, no account). Two modes. Usage:
  python tools/notify.py --done "short plain sentence" [--dry-run]     MILESTONE: a major part finished. Allowed at any time (also overnight, quiet hours, back to back);
                                                                       also appended to Roblox Dev/Notify Log.md so the record is kept. Default priority.
  python tools/notify.py --reason "short plain sentence" [--dry-run]   EMERGENCY: a bug it cannot solve alone, something destroyed, a major error. Silent (low priority).
                                                                       Allowed overnight and in quiet hours (user, 2026-10-29); refused only if another emergency went out in the last 30 minutes.
Milestone messages replace long status text in chat: put the outcome, the evidence and what is unverified in the sentence (max 200 characters), details go in the vault.
Topic and server come from ~/.claude/ntfy.json (kept off the repo)."""
import argparse, json, sys, time, urllib.request
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
home = Path.home() / ".claude"
ap = argparse.ArgumentParser()
g = ap.add_mutually_exclusive_group(required=True)
g.add_argument("--reason", help="emergency message")
g.add_argument("--done", help="milestone message")
ap.add_argument("--dry-run", action="store_true")
a = ap.parse_args()

milestone = a.done is not None
text = " ".join((a.done if milestone else a.reason).split())[:200]
if not text:
    sys.exit("refused: empty message")

if not milestone:
    # 2026-10-29 (user): notifications go through while overnight is armed and in quiet hours; only the flood guard (one emergency per 30 minutes) stays
    stamp = home / "ntfy_last.txt"
    if stamp.exists() and time.time() - float(stamp.read_text(encoding="utf-8")) < 30 * 60:
        sys.exit("refused: one emergency notification per 30 minutes")

if a.dry_run:
    print("dry run, would send" + (" milestone:" if milestone else " emergency:"), text)
    sys.exit(0)

cfg = json.loads((home / "ntfy.json").read_text(encoding="utf-8"))
url = cfg["server"].rstrip("/") + "/" + cfg["topic"]
headers = {"Title": "Done" if milestone else "Claude needs you", "Priority": "default" if milestone else "low", "Tags": "white_check_mark" if milestone else "warning"}
req = urllib.request.Request(url, data=text.encode("utf-8"), method="POST", headers=headers)
with urllib.request.urlopen(req, timeout=15) as r:
    print("sent, status", r.status)
if milestone:
    log = root / "Roblox Dev" / "Notify Log.md"
    if not log.exists():
        log.write_text("# Notify log\nOne line per milestone sent to the phone with `python tools/notify.py --done` (newest last). Details are in [[Session Log]].\n\n", encoding="utf-8")
    with open(log, "a", encoding="utf-8") as f:
        f.write(f"- {datetime.now().strftime('%Y-%m-%d %H:%M')} {text}\n")
else:
    (home / "ntfy_last.txt").write_text(str(time.time()), encoding="utf-8")
