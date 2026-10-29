"""Local git checkpoint for overnight runs. The only way the loop may commit (guard.py blocks raw git writes).
  python tools/overnight/checkpoint.py -m "Two plain sentences." [--intensive "reason"]
                                                                          commit on the overnight branch; 3 per run, more only with --intensive
  python tools/overnight/checkpoint.py --restore                          put the last checkpoint's files back (no history rewrite)
Rules: branch must be overnight/*; never pushes; never stages the .rbxl, Kimi, ComfyUI or anything git-ignored; at most
two sentences; no Co-Authored-By trailer (commits are under the user's own git identity)."""
import re, subprocess, sys, time
from pathlib import Path

root = Path(__file__).resolve().parents[2]
PATHS = ["VFX", "Tests", "Vendor", "tools", "Audio", "Roblox Dev", "UI Kit", "Stages", "Studio_Export", "Overnight", "Blender", "Animation Kit", ".gitignore", "CLAUDE.md"]
# Paths already in .gitignore (Overnight/ACTIVE*, state.json, captures, Codex Handoff) must not be listed here:
# git 2.54 exits 1 when an exclude pathspec names an ignored path, which aborted every checkpoint on 2026-10-27.
EXCLUDE = [":(exclude)*.rbxl", ":(exclude)Roblox Dev/.obsidian/*", ":(exclude)*.mp4"]  # videos are large; kept on disk only


def git(*a, check=True):
    r = subprocess.run(["git", *a], cwd=root, capture_output=True, text=True)
    if check and r.returncode:
        sys.exit("git " + " ".join(a) + " failed: " + (r.stderr or r.stdout).strip())
    return r.stdout.strip()


branch = git("branch", "--show-current")
if not branch.startswith("overnight/"):
    sys.exit(f"refusing: on branch '{branch}', checkpoints only on overnight/*")

if "--restore" in sys.argv:
    last = git("log", "-1", "--format=%H")
    git("restore", "--source=" + last, "--staged", "--worktree", "--", *[p for p in PATHS if (root / p).exists()])
    print("restored files to", last[:10])
    sys.exit(0)

ACTIVE = root / "Overnight" / "ACTIVE"
intensive = sys.argv[sys.argv.index("--intensive") + 1].strip() if "--intensive" in sys.argv else ""
if ACTIVE.exists():
    import json
    base = json.loads(ACTIVE.read_text(encoding="utf-8")).get("base")
    used = int(git("rev-list", "--count", f"{base}..HEAD")) if base else 0
    if used >= 3 and not intensive:
        sys.exit(f"refusing: {used} checkpoints already (cap 3). If the work done tonight is intensive, add --intensive \"one-line reason\"; it is logged in the report.")
    if used >= 3:
        with open(root / "Overnight" / "PROGRESS.md", "a", encoding="utf-8") as f:
            f.write(f"- {time.strftime('%H:%M')} OVER-CAP checkpoint {used + 1}: {intensive}\n")
if "-m" not in sys.argv:
    sys.exit('usage: checkpoint.py -m "message"')
msg = sys.argv[sys.argv.index("-m") + 1].strip()
if "co-authored-by" in msg.lower() or "\n" in msg:
    sys.exit("message must be one paragraph with no trailers")
if len([s for s in re.split(r"(?<=[.!?])\s+", msg) if s]) > 2 or len(msg) > 240:
    sys.exit("message must be two plain sentences at most (240 characters)")
git("add", "-A", "--", *[p for p in PATHS if (root / p).exists()], *EXCLUDE)
if not git("diff", "--cached", "--name-only"):
    print("nothing to checkpoint")
    sys.exit(0)
big = [f for f in git("diff", "--cached", "--name-only").splitlines() if (root / f).exists() and (root / f).stat().st_size > 20_000_000]
if big:
    git("reset", "-q")
    sys.exit("refusing: files over 20 MB staged: " + ", ".join(big))
git("commit", "-q", "-m", msg)
h = git("log", "-1", "--format=%h")
with open(root / "Overnight" / "PROGRESS.md", "a", encoding="utf-8") as f:
    f.write(f"- {time.strftime('%H:%M')} CHECKPOINT {h} on {branch}: {msg}\n")
print("checkpoint", h)
