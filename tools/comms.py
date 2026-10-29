"""File-based communication between chats (no model calls). Replaces chat-to-chat prompts except when another agent must reason or decide.
All state lives in Roblox Dev/Comms/ (Obsidian vault):
  status/<chat>.md   one short file per chat, OVERWRITTEN: now / next / done (last 5) / blocked / needs. Read it instead of asking "what are you doing".
  inbox/<chat>.md    messages to a chat, appended; each chat reads only its UNREAD lines at a task boundary (read marks them read).
  Decisions.md       append-only decisions that other chats must follow.
Usage:
  python tools/comms.py status --chat NAME [--now "..."] [--next "..."] [--done "..."] [--blocked "..."] [--needs "..."]
  python tools/comms.py post --from NAME --to NAME "message"          (append to the inbox; --urgent flags it)
  python tools/comms.py read --chat NAME                              (print unread inbox lines, mark read; prints nothing if none)
  python tools/comms.py decide --from NAME "decision"
  python tools/comms.py show [--chat NAME]                            (all statuses, or one)
  python tools/comms.py digest [--push] [--loop SECONDS]              (one-line-per-chat digest; --push sends it to the phone through tools/notify.py only when something
                                                                       changed since the last push; --loop repeats, e.g. 900 = every 15 minutes, no model calls)
Chat names: main (the manager "Low"), ui-rework-mgr, loading-anim, refs-intake, overnight, or a worker name."""
import argparse, hashlib, subprocess, sys, time
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
C = root / "Roblox Dev" / "Comms"
(C / "status").mkdir(parents=True, exist_ok=True)
(C / "inbox").mkdir(exist_ok=True)
now = lambda: datetime.now().strftime("%Y-%m-%d %H:%M")

ap = argparse.ArgumentParser()
ap.add_argument("cmd", choices=["status", "post", "read", "decide", "show", "digest"])
ap.add_argument("text", nargs="?", default="")
ap.add_argument("--chat")
ap.add_argument("--from", dest="frm")
ap.add_argument("--to")
ap.add_argument("--urgent", action="store_true")
for k in ("now", "next", "done", "blocked", "needs"):
    ap.add_argument("--" + k)
ap.add_argument("--push", action="store_true")
ap.add_argument("--loop", type=int, default=0)
a = ap.parse_args()


def fields(p):
    d = {}
    if p.exists():
        for line in p.read_text(encoding="utf-8").splitlines():
            if line.startswith("- ") and ":" in line:
                k, v = line[2:].split(":", 1)
                d[k.strip()] = v.strip()
    return d


if a.cmd == "status":
    p = C / "status" / f"{a.chat}.md"
    d = fields(p)
    for k in ("now", "next", "blocked", "needs"):
        if getattr(a, k) is not None:
            d[k] = getattr(a, k)
    if a.done:
        recent = [x for x in d.get("done", "").split(" ;; ") if x]
        d["done"] = " ;; ".join(([f"{now()[11:]} {a.done}"] + recent)[:5])
    d["updated"] = now()
    p.write_text(f"# {a.chat}\n" + "".join(f"- {k}: {d.get(k, '')}\n" for k in ("updated", "now", "next", "done", "blocked", "needs")), encoding="utf-8", newline="\n")
elif a.cmd == "post":
    p = C / "inbox" / f"{a.to}.md"
    with open(p, "a", encoding="utf-8", newline="\n") as f:
        f.write(f"- [ ] {now()} from {a.frm}{' !URGENT' if a.urgent else ''}: {a.text}\n")
elif a.cmd == "read":
    p = C / "inbox" / f"{a.chat}.md"
    if p.exists():
        lines = p.read_text(encoding="utf-8").splitlines()
        unread = [l for l in lines if l.startswith("- [ ] ")]
        for l in unread:
            print(l[6:])
        if unread:
            p.write_text("\n".join(l.replace("- [ ] ", "- [x] ", 1) if l.startswith("- [ ] ") else l for l in lines) + "\n", encoding="utf-8", newline="\n")
elif a.cmd == "decide":
    p = C / "Decisions.md"
    if not p.exists():
        p.write_text("# Decisions (append-only; every chat follows these)\n\n", encoding="utf-8")
    with open(p, "a", encoding="utf-8", newline="\n") as f:
        f.write(f"- {now()} {a.frm}: {a.text}\n")
elif a.cmd == "show":
    for p in sorted((C / "status").glob("*.md")):
        if not a.chat or p.stem == a.chat:
            print(p.read_text(encoding="utf-8"))
elif a.cmd == "digest":
    stamp = C / ".last_digest"
    while True:
        lines = []
        for p in sorted((C / "status").glob("*.md")):
            d = fields(p)
            bits = [d.get("now", "")[:50]]
            if d.get("blocked"):
                bits.append("BLOCKED " + d["blocked"][:40])
            if d.get("needs"):
                bits.append("NEEDS " + d["needs"][:40])
            last = (d.get("done", "").split(" ;; ")[0])[:50]
            if last:
                bits.append("last: " + last)
            lines.append(f"{p.stem}: " + "; ".join(b for b in bits if b))
        text = " | ".join(lines)
        h = hashlib.md5(text.encode()).hexdigest()
        changed = not stamp.exists() or stamp.read_text() != h
        if a.push and changed and lines:
            subprocess.run([sys.executable, "-I", str(root / "tools" / "notify.py"), "--done", text[:200]])
            stamp.write_text(h)
        elif not a.push:
            print(text)
        if not a.loop:
            break
        time.sleep(a.loop)
