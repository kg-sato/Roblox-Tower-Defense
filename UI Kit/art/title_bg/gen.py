"""Title-page background art via ComfyUI (reuses comfy_generate). Layers: sky, figure. Output: title_bg/raw/<name>_s<seed>.png"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import comfy_generate as C
import io
from PIL import Image
INK = "black and white engraving, fine ink hatching and crosshatch, high contrast, monochrome, no colour"
P = {
 "figure": "a colossal faceless robed deity made of pale white fog and silver mist, smooth blank featureless head with no eyes no nose no mouth no face, long robes dissolving into drifting cloud, one enormous slender hand reaching down and forward, towering, seen from the side leaning down toward the left, on a pure solid black background, " + INK,
 "figure2": "a single tall faceless figure in a long hooded robe, completely smooth blank featureless head with no eyes no ears no nose no mouth, one arm outstretched forward with an open hand reaching down, head bowed toward the left, seen from the side, lower robe fading into thin wisps of white smoke, only the figure, no clouds, no background, on a pure solid black background, " + INK,
 "fig3": "a colossal faceless deity made of white fog and ink wash, upper body and two long arms with detailed slender hands reaching down and forward toward the left, smooth blank featureless hooded head with no face, the robes and sleeves dissolving into drifting mist and smoke, translucent wispy lower body fading to nothing, ink wash and fine engraving, dramatic rim light, high detail, on a pure solid black background, ",
 "ground": "ruined gothic city rooftops and broken towers far below seen through thick fog, dark moody, fine engraving, black and white, ",
 "sky": "vast dramatic storm clouds with shafts of god rays streaming down from a bright gap, towering cumulus, empty sky, no objects, no figures, " + INK,
}
os.makedirs("raw", exist_ok=True)
C.start_server()
name = sys.argv[1]; n = int(sys.argv[2]); seed = int(sys.argv[3]); w = int(sys.argv[4]); h = int(sys.argv[5])
wf = C.workflow
for v in range(n):
    s = seed + v
    f = C.workflow((P[name] + (INK if name in ("fig3",) else "")), s, 1024, 4)
    f["6"]["inputs"]["width"], f["6"]["inputs"]["height"] = w, h
    import json
    pid = json.loads(C.api("/prompt", {"prompt": f}))["prompt_id"]
    import time, urllib.parse
    while True:
        hh = json.loads(C.api("/history/" + pid))
        if pid in hh:
            img = hh[pid]["outputs"]["9"]["images"][0]
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            open("raw/%s_s%d.png" % (name, s), "wb").write(C.api("/view?" + q, timeout=60)); print("ok", name, s); break
        time.sleep(1)
