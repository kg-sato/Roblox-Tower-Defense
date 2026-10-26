"""Zip the pack for sharing: python kit/make_zip.py [output.zip] [--skip "R15_Sword*"]

Leaves out your API key, Blender files, videos, contact sheets, caches and your own reference clips (except the
PunchRef example). --skip leaves out animations (script + exports) whose name matches, e.g. unfinished ones.
Default output: Roblox-Animations-by-fwjelaa.zip next to the pack folder.
"""
import fnmatch
import os
import sys
import zipfile

PACK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOP = "Roblox-Animations-by-fwjelaa"

INCLUDE = [
    "README.md", "GUIDE.md", "GUIDE.html", "CLAUDE.md", "CREDITS.md", "fwjelaa animation method.md",
    "config.json", ".gitignore", ".secrets/README.txt",
    ".claude/settings.json", ".claude/skills/*/*",
    "kit/*.py", "anims/*.py", "roblox/*.luau", "roblox/examples/*.luau",
    "research/*.md", "images/*",
    "out/*.rbxmx", "out/*.luau", "out/*.json", "out/verify/*.json",
    "ref/PunchRef/*", "ref/sheet_PunchRef.png",
]
EXCLUDE = ["*/__pycache__/*", "*.pyc", ".secrets/*.txt"]


def wanted(rel):
    rel = rel.replace(os.sep, "/")
    if rel == ".secrets/README.txt":
        return True
    if any(fnmatch.fnmatch(rel, pat) for pat in EXCLUDE):
        return False
    return any(fnmatch.fnmatch(rel, pat) for pat in INCLUDE)


def main():
    args = sys.argv[1:]
    skip = []
    while "--skip" in args:
        i = args.index("--skip")
        skip.append(args[i + 1])
        del args[i:i + 2]
    out = args[0] if args else os.path.join(os.path.dirname(PACK), f"{TOP}.zip")
    files = []
    for root, dirs, names in os.walk(PACK):
        dirs[:] = [d for d in dirs if d not in ("__pycache__", "blend", "video", "_frames", "_compare")]
        for n in names:
            rel = os.path.relpath(os.path.join(root, n), PACK)
            stem = os.path.splitext(n)[0]
            if wanted(rel) and not any(fnmatch.fnmatch(stem, pat) for pat in skip):
                files.append(rel)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in sorted(files):
            z.write(os.path.join(PACK, rel), f"{TOP}/{rel.replace(os.sep, '/')}")
    print(f"ZIPPED {len(files)} files -> {out} ({os.path.getsize(out) / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
