"""One command for the whole art pipeline.

    python "UI Kit/art/build_art.py"

1. make_chrome.py   regenerates the procedural sprites (buttons, panels, bars, cards, vector icons)
2. ingest_art.py    processes anything waiting in art/inbox (Kimi / Blender / manual images)
3. make_uiart.py    rewrites UI Kit/luau/UIArt.luau (sprite list + uploaded ids)
4. preview_install  copies the PNGs into Studio's local content folder for no-upload preview

Afterwards sync the Luau modules into Studio (see UI Kit/README.md) and look at the screens.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
for script in ("make_chrome.py", "ingest_art.py", "make_uiart.py", "preview_install.py"):
    print("==", script)
    r = subprocess.run([sys.executable, os.path.join(HERE, script)] + sys.argv[1:] if script == "ingest_art.py" else [sys.executable, os.path.join(HERE, script)])
    if r.returncode != 0:
        sys.exit("stopped: " + script + " failed")
