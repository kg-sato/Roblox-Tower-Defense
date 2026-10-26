"""Watches for new Kimi / Blender images and processes them automatically.

    python "UI Kit/art/watch_inbox.py"                 watch until Ctrl+C
    python "UI Kit/art/watch_inbox.py" --once          process what is there now, then exit
    python "UI Kit/art/watch_inbox.py" --also "C:/path/to/folder"   watch one more folder (repeatable)

What it does
  * Watches art/inbox plus any --also folders (Kimi's output folder, Downloads...). It only picks up image files whose
    names start with icon_ / pet_ / bg_ / art_ (so it never touches your other downloads).
  * Waits until a file has stopped growing for 3 seconds (so half-written files are not grabbed).
  * Files from --also folders are COPIED into the inbox (the original stays where it was), then ingest_art.py runs,
    then make_uiart.py + preview_install.py rebuild the sprite list and the Studio preview.
  * Prints one line per file, and a "needs attention" line for anything the ingest flagged.
Nothing is uploaded to Roblox and Studio is not touched; after a run, sync the Luau modules (UI Kit/README.md).
"""
import glob
import os
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
INBOX = os.path.join(HERE, "inbox")
PREFIXES = ("icon_", "pet_", "bg_", "art_")
EXTS = (".png", ".jpg", ".jpeg", ".webp")
SEEN = os.path.join(HERE, ".watch_seen.txt")


def extra_folders():
    out = []
    for i, a in enumerate(sys.argv):
        if a == "--also" and i + 1 < len(sys.argv):
            out.append(sys.argv[i + 1])
    return out


def load_seen():
    if os.path.exists(SEEN):
        return set(open(SEEN, encoding="utf-8").read().splitlines())
    return set()


def mark_seen(seen, key):
    seen.add(key)
    with open(SEEN, "a", encoding="utf-8") as f:
        f.write(key + "\n")


def candidates(folder):
    for f in glob.glob(os.path.join(folder, "**", "*"), recursive=True):
        base = os.path.basename(f).lower()
        if base.endswith(EXTS) and base.startswith(PREFIXES):
            yield f


def stable(path, wait=3.0):
    try:
        a = os.path.getsize(path)
        time.sleep(wait)
        return a == os.path.getsize(path) and a > 0
    except OSError:
        return False


def run(script, *args):
    r = subprocess.run([sys.executable, os.path.join(HERE, script), *args], capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()


def cycle(seen, extras):
    moved = 0
    for folder in extras:
        if not os.path.isdir(folder):
            continue
        for f in candidates(folder):
            key = os.path.abspath(f) + "|" + str(os.path.getmtime(f))
            if key in seen:
                continue
            if not stable(f):
                continue
            dst = os.path.join(INBOX, os.path.basename(f))
            shutil.copy2(f, dst)
            mark_seen(seen, key)
            moved += 1
            print("copied into inbox:", f)
    pending = [f for f in candidates(INBOX)]
    ready = [f for f in pending if stable(f, 1.5)]
    if ready:
        code, out = run("ingest_art.py")
        print(out)
        if "problem(s)" in out and " 0 problem(s)" not in out:
            print("NEEDS ATTENTION: see the lines above")
        for s in ("make_uiart.py", "preview_install.py"):
            code, out = run(s)
            print(out.splitlines()[-1] if out else s + " ok")
        print("done at", time.strftime("%H:%M:%S"), "- sync Luau modules into Studio to see it")
    return moved + len(ready)


def main():
    os.makedirs(INBOX, exist_ok=True)
    extras = extra_folders()
    seen = load_seen()
    print("watching:", INBOX, *extras)
    if "--once" in sys.argv:
        cycle(seen, extras)
        return
    try:
        while True:
            cycle(seen, extras)
            time.sleep(4)
    except KeyboardInterrupt:
        print("stopped")


if __name__ == "__main__":
    main()
