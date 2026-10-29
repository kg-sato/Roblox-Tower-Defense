"""Stop hook: the loop. Inert unless Overnight/ACTIVE exists.
Each time Claude tries to stop it (1) restores tampered control files, (2) re-runs the verify command of every task
Claude just ticked and un-ticks it on failure, (3) enforces attempt limits, (4) hands out the next task, and (5) lets
the run end only when everything is done or blocked, a limit is hit, and Overnight/REPORT.md exists.
Task lines in Overnight/TODO.md:   - [ ] T01 | title | verify: <shell command, or manual>
"""
import hashlib, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

payload = json.load(sys.stdin)
root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or ".").resolve()
ov = root / "Overnight"
active = ov / "ACTIVE"
if not active.exists():
    sys.exit(0)

cfg = json.loads(active.read_text(encoding="utf-8"))
if cfg.get("night") != time.strftime("%Y-%m-%d"):
    # armed for another night: the user must confirm each night (arm.py --confirm-tonight), so this run ends now
    with open(ov / "PROGRESS.md", "a", encoding="utf-8") as f:
        f.write(f"- {time.strftime('%H:%M')} ended: armed for another night; the user confirms each night\n")
    active.rename(ov / f"ACTIVE.ended-{time.strftime('%Y%m%d-%H%M')}")
    sys.exit(0)
state_p = ov / "state.json"
state = json.loads(state_p.read_text(encoding="utf-8")) if state_p.exists() else {"iter": 0, "attempts": {}, "verified": {}}
store = Path.home() / ".claude" / "overnight_protected"
LINE = re.compile(r"^- \[( |x|!)\] (T\d+) \| (.*?) \| verify: (.*)$")


def save():
    state_p.write_text(json.dumps(state, indent=1), encoding="utf-8")


def log(msg):
    with open(ov / "PROGRESS.md", "a", encoding="utf-8") as f:
        f.write(f"- {time.strftime('%H:%M')} {msg}\n")


def block(reason):
    save()
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)


def disarm(note):
    log(note)
    active.rename(ov / f"ACTIVE.ended-{time.strftime('%Y%m%d-%H%M')}")
    sys.exit(0)


def tasks():
    out = []
    for i, line in enumerate((ov / "TODO.md").read_text(encoding="utf-8").splitlines()):
        m = LINE.match(line)
        if m:
            out.append({"i": i, "mark": m[1], "id": m[2], "title": m[3], "verify": m[4].strip()})
    return out


def set_mark(task_id, mark):
    p = ov / "TODO.md"
    lines = p.read_text(encoding="utf-8").splitlines()
    for i, line in enumerate(lines):
        m = LINE.match(line)
        if m and m[2] == task_id:
            lines[i] = "- [" + mark + line[4:]
    p.write_text("\n".join(lines) + "\n", encoding="utf-8")


state["iter"] += 1

# 0. hourly report, written by the gate itself so it costs no model tokens
hours = int((time.time() - cfg["start"]) / 3600)
if hours > state.get("reported", 0):
    state["reported"] = hours
    ts = tasks()
    cnt = {m: sum(1 for t in ts if t["mark"] == m) for m in " x!"}
    try:
        denied = len((ov / "denials.log").read_text(encoding="utf-8").splitlines())
    except Exception:
        denied = 0
    try:
        recent = [l.strip() for l in (ov / "PROGRESS.md").read_text(encoding="utf-8").splitlines()[-3:]]
    except Exception:
        recent = []
    with open(ov / "HOURLY.md", "a", encoding="utf-8") as f:
        f.write(f"## Hour {hours} ({time.strftime('%H:%M')}): done {cnt['x']}, blocked {cnt['!']}, open {cnt[' ']}, loops {state['iter']}, denials {denied}\n"
                + "".join(f"- {l}\n" for l in recent))

# 1. control files restored if changed
restored = []
for rel, h in cfg.get("hashes", {}).items():
    f = root / rel
    cur = hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else None
    if cur != h:
        src = store / rel.replace("/", "__")
        if src.exists():
            f.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, f)
            restored.append(rel)
if restored:
    log("TAMPER: restored control files " + ", ".join(restored))
    block("Control files were modified and have been restored: " + ", ".join(restored) + ". Do not edit hooks, settings, POLICY.md or tools/overnight. Continue with the task list.")

# 2. limits
limit = None
if time.time() > cfg["deadline"]:
    limit = "time limit reached"
elif state["iter"] > cfg["max_iterations"]:
    limit = "iteration limit reached"

# 3. verify freshly ticked tasks
failed_msgs = []
for t in tasks():
    if t["mark"] != "x" or state["verified"].get(t["id"]):
        continue
    if t["verify"].lower().startswith("manual") or t["verify"].lower().startswith("studio"):
        ev = ov / "evidence" / f"{t['id']}.txt"
        ok = ev.exists() and ev.read_text(encoding="utf-8", errors="replace").lstrip().upper().startswith("PASS")
        out = "needs Overnight/evidence/%s.txt whose first line is PASS, followed by the real test output" % t["id"]
        kind = "attested"
    else:
        try:
            r = subprocess.run(t["verify"], shell=True, cwd=root, capture_output=True, text=True, timeout=600)
            ok, out = r.returncode == 0, ((r.stdout or "") + (r.stderr or ""))[-1800:]
        except subprocess.TimeoutExpired:
            ok, out = False, "verify command timed out after 600 s"
        kind = "gate-verified"
    if ok:
        state["verified"][t["id"]] = kind
        log(f"{t['id']} DONE ({kind}): {t['title']}")
    else:
        n = state["attempts"][t["id"]] = state["attempts"].get(t["id"], 0) + 1
        set_mark(t["id"], "!" if n >= 5 else " ")
        log(f"{t['id']} verify FAILED (attempt {n}): {out[-300:]}")
        if n >= 5:
            failed_msgs.append(f"{t['id']} failed verification 5 times; it is now marked blocked. Write why in PROGRESS.md and move to the next task.\n{out}")
        else:
            hint = " Three failures: reassess the root cause and pick a materially different approach." if n >= 3 else ""
            failed_msgs.append(f"{t['id']} was ticked but verification failed (attempt {n}/5), so it was un-ticked.{hint}\nVerify output:\n{out}")
if failed_msgs:
    block("\n\n".join(failed_msgs))

# 4. next work
todo = [t for t in tasks() if t["mark"] == " "]
if todo and not limit:
    t = todo[0]
    n = state["attempts"].get(t["id"], 0)
    try:
        used = int(subprocess.run(["git", "rev-list", "--count", f"{cfg['base']}..HEAD"], cwd=root, capture_output=True, text=True).stdout.strip())
    except Exception:
        used = 0
    el, tot = (time.time() - cfg["start"]) / 3600, (cfg["deadline"] - cfg["start"]) / 3600
    pace = f"{el:.1f}/{tot:.1f} h, commits {used}/3 (past 3 only with --intensive). "
    block(
        pace + f"Loop {state['iter']}/{cfg['max_iterations']}, {len(todo)} left. Next {t['id']}: {t['title']} (attempt {n}). "
        f"Verify: {t['verify']}. Tick [x] only after it passes; log one evidence line; checkpoint at milestones. Reply in under 30 words, no recap."
    )

# 5. wrap up: report required
report = ov / "REPORT.md"
fresh = report.exists() and report.stat().st_mtime > cfg["start"]
if not fresh:
    why = limit or "no actionable tasks remain"
    block(f"Run ending ({why}). Write Overnight/REPORT.md per POLICY.md Final Report (features, bugs fixed, tests and results, files changed, "
          f"blocked tasks, checkpoint commit hashes, next actions; mark each item gate-verified, attested or UNVERIFIED), run "
          f"`python tools/overnight/checkpoint.py -m \"<two plain sentences>\"`, then stop.")
disarm("Run ended: " + (limit or "all tasks done or blocked"))
