"""Copies art/out/*.png into Studio's local content folder so Studio can show them with no upload.

    python "UI Kit/art/preview_install.py"          install (or refresh)
    python "UI Kit/art/preview_install.py" --remove  delete the copied folder

Studio loads  rbxasset://textures/uikit/<name>.png  from  <Studio version folder>\\content\\textures\\uikit\\.
This is a DEV PREVIEW ONLY: the files exist on this computer, not in a published game, and Studio updates
install a new version folder (just run this again). Final art must be uploaded and referenced by asset id.
"""
import glob
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
versions = os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "Versions")
targets = []
for exe in glob.glob(os.path.join(versions, "version-*", "RobloxStudioBeta.exe")):
    targets.append(os.path.join(os.path.dirname(exe), "content", "textures", "uikit_v6"))
if not targets:
    sys.exit("No Roblox Studio version folder found under " + versions)

for t in targets:
    if "--remove" in sys.argv:
        shutil.rmtree(t, ignore_errors=True)
        print("removed", t)
        continue
    os.makedirs(t, exist_ok=True)
    n = 0
    for f in glob.glob(os.path.join(OUT, "*.png")):
        if os.path.basename(f).startswith("_"):
            continue
        shutil.copy2(f, os.path.join(t, os.path.basename(f)))
        n += 1
    print("copied", n, "PNGs to", t)





