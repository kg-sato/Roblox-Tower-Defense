"""Generates UI icons locally with ComfyUI (FLUX.1 schnell, GGUF Q4) and hands them to the ingest pipeline.

    python "UI Kit/art/comfy_generate.py" icon_dragon icon_shoe          generate these (names from DESCRIPTIONS)
    python "UI Kit/art/comfy_generate.py" --missing                      everything next_batch.py says is missing
    python "UI Kit/art/comfy_generate.py" icon_egg --variants 4 --seed 7 four candidates, seeds 7..10
    python "UI Kit/art/comfy_generate.py" icon_egg --prompt "a red apple"   one-off description
    add --inbox to copy the FIRST variant of each into art/inbox/ (then run ingest_art.py or watch_inbox.py)

Everything is local: it starts ComfyUI (ComfyUI/ComfyUI_windows_portable) on 127.0.0.1:8188 if it is not running,
sends an API-format workflow, and saves PNGs to art/comfy_out/<name>_s<seed>.png. Nothing is uploaded anywhere.
Same style block and magenta background rule as briefs/KIMI-MASTER-PROMPT.md, so ingest_art.py keys it out the same way.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(HERE))
PORTABLE = os.path.join(PROJECT, "ComfyUI", "ComfyUI_windows_portable")
OUT = os.path.join(HERE, "comfy_out")
INBOX = os.path.join(HERE, "inbox")
URL = "http://127.0.0.1:8188"

STYLE = ("glossy 3D cartoon mobile game icon, polished casual-game item icon, thick dark navy outline all around the "
         "subject, bright saturated candy colours, smooth gradient shading, soft white highlight on the upper left, "
         "darker lower edge, chunky simple shape readable at small size, centred, fills most of the frame, "
         "isolated on a flat solid pure magenta #FF00FF background, no text, no letters, no shadow on the ground")

STYLE_FLAT = ("flat 2D vector game icon, bold clean shapes, thick dark navy outline, limited palette of bright saturated colours, "
              "cel shading with one hard-edged shadow tone and one highlight shape, expressive character with personality, "
              "a little face or distinctive detail where it fits, centred, fills most of the frame, "
              "isolated on a flat solid pure magenta #FF00FF background, no text, no letters, no shadow on the ground, no 3D render, no gradients")

STYLE_SOLS = ("dark medieval fantasy game icon, mystical arcane relic, ornate aged metal and carved stone, engraved glowing runes, "
              "gothic and gilded details, deep midnight navy and black shadows with a rich accent colour (gold, violet, crimson or cyan) "
              "and a bright magical inner glow, painterly cel shading, strong rim light, one thin dark outline of even weight, "
              "slightly menacing and epic mood, the item feels ancient and powerful, centred, fills most of the frame, "
              "isolated on a flat solid pure magenta #FF00FF background, no text, no letters, no ground shadow, no glow spilling onto the background, no cartoon face")

# prefix goes FIRST: FLUX weights early words most, and the background kept failing when it was last
BG_PREFIX = ("solid flat uniform pure magenta #FF00FF background from edge to edge, no vignette, no gradient, no floor, no ground, "
             "no cast shadow, the object floats alone")
# every icon is drawn the way the UI shows it: upright, straight on, nothing rotated
COMPOSITION = ("front view, perfectly upright and axis-aligned, vertical orientation, no rotation, no tilt, no diagonal, "
               "symmetrical, facing the viewer, centred with equal empty margin on all four sides, the whole object "
               "fully inside the frame and about 90 percent of the frame, large and bold, one single object only, compact proportions")

# the descriptions live in next_batch.py; import them so there is one table
sys.path.insert(0, HERE)


def load_descriptions():
    src = open(os.path.join(HERE, "next_batch.py"), encoding="utf-8").read()
    block = re.search(r"DESCRIPTIONS = \{(.*?)\n\}", src, re.S).group(1)
    return dict(re.findall(r'"(icon_[a-z0-9_]+)": "([^"]+)"', block))


def api(path, data=None, timeout=30):
    req = urllib.request.Request(URL + path, data=None if data is None else json.dumps(data).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def server_up():
    try:
        api("/system_stats", timeout=3)
        return True
    except Exception:
        return False


def start_server():
    if server_up():
        return
    py = os.path.join(PORTABLE, "python_embeded", "python.exe")
    main = os.path.join(PORTABLE, "ComfyUI", "main.py")
    if not os.path.exists(py):
        sys.exit("ComfyUI is not installed at " + PORTABLE)
    log = open(os.path.join(PROJECT, "ComfyUI", "server.log"), "ab")
    subprocess.Popen([py, "-s", main, "--windows-standalone-build", "--listen", "127.0.0.1", "--port", "8188",
                      "--disable-auto-launch"], cwd=PORTABLE, stdout=log, stderr=log,
                     creationflags=0x08000000)  # CREATE_NO_WINDOW
    for _ in range(180):
        if server_up():
            return
        time.sleep(2)
    sys.exit("ComfyUI did not start; see ComfyUI/server.log")


def workflow(prompt, seed, size, steps):
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "flux1-schnell-Q4_K_S.gguf"}},
        "2": {"class_type": "DualCLIPLoader", "inputs": {"clip_name1": "t5xxl_fp8_e4m3fn.safetensors",
                                                         "clip_name2": "clip_l.safetensors", "type": "flux"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["2", 0]}},
        "6": {"class_type": "EmptyLatentImage", "inputs": {"width": size, "height": size, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["4", 0], "negative": ["5", 0],
                                                   "latent_image": ["6", 0], "seed": seed, "steps": steps, "cfg": 1.0,
                                                   "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"images": ["8", 0], "filename_prefix": "uikit"}},
    }


def run_one(prompt, seed, size, steps):
    pid = json.loads(api("/prompt", {"prompt": workflow(prompt, seed, size, steps)}))["prompt_id"]
    for _ in range(900):
        h = json.loads(api("/history/" + pid))
        if pid in h:
            st = h[pid]["status"]
            if st.get("status_str") == "error":
                raise RuntimeError(json.dumps(st.get("messages"))[:600])
            img = h[pid]["outputs"]["9"]["images"][0]
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            return api("/view?" + q, timeout=60)
        time.sleep(1)
    raise TimeoutError("generation timed out")


def background_ok(png_bytes):
    """True when the border is one flat magenta-family colour (so ingest_art.py can key it)."""
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(png_bytes)).convert("RGB")
    w, h = im.size
    pts = [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4), (w // 2, 3), (w // 2, h - 4), (3, h // 2), (w - 4, h // 2)]
    cols = [im.getpixel(p) for p in pts]
    spread = max(max(c[i] for c in cols) - min(c[i] for c in cols) for i in range(3))
    r, g, b = cols[0]
    return spread < 45 and r - g > 60 and b - g > 40


def flatten_background(png_bytes):
    """FLUX ignores "no shadow": paint every magenta-family region that touches the border with the corner colour,
    so ingest_art.py keys one flat colour. Subject pixels (not magenta-ish, or not connected to the border) are kept."""
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(png_bytes)).convert("RGB")
    w, h = im.size
    px = im.load()
    key = px[2, 2]

    def magenta(c):
        return c[0] - c[1] > 60 and c[2] - c[1] > 40
    seen = bytearray(w * h)
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        i = y * w + x
        if seen[i] or not magenta(px[x, y]):
            continue
        seen[i] = 1
        px[x, y] = key
        if x > 0:
            stack.append((x - 1, y))
        if x < w - 1:
            stack.append((x + 1, y))
        if y > 0:
            stack.append((x, y - 1))
        if y < h - 1:
            stack.append((x, y + 1))
    out = io.BytesIO()
    im.save(out, "PNG")
    return out.getvalue()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*")
    ap.add_argument("--missing", action="store_true")
    ap.add_argument("--variants", type=int, default=1)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--size", type=int, default=768)
    ap.add_argument("--steps", type=int, default=4)
    ap.add_argument("--prompt", help="override the description (one name only)")
    ap.add_argument("--style", choices=["3d", "flat", "sols"], default="3d", help="flat = 2D cel-shaded icons, files get a _flat suffix")
    ap.add_argument("--raw", action="store_true", help="skip the background clean-up")
    ap.add_argument("--inbox", action="store_true", help="copy the first variant to art/inbox/<name>.png")
    a = ap.parse_args()

    desc = load_descriptions()
    if a.style == "sols":
        from sols_descriptions import SOLS
        desc.update(SOLS)
    names = list(a.names)
    if a.missing:
        out = subprocess.run([sys.executable, os.path.join(HERE, "next_batch.py")], capture_output=True, text=True).stdout
        names += [l.strip() for l in out.splitlines() if l.startswith("  icon_")]
    if not names:
        sys.exit("nothing to do: give names or --missing")
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(INBOX, exist_ok=True)
    start_server()
    for n in names:
        d = a.prompt if a.prompt else desc.get(n)
        if not d:
            print("skip", n, ": no description in next_batch.py (use --prompt)")
            continue
        for v in range(a.variants):
            seed = a.seed + v
            t = time.time()
            png = None
            for attempt in range(4):
                png = run_one("%s. %s, %s, %s" % (BG_PREFIX, d, COMPOSITION, {"flat": STYLE_FLAT, "sols": STYLE_SOLS}.get(a.style, STYLE)), seed + attempt * 1000, a.size, a.steps)
                if a.raw or background_ok(png):
                    break
                print("  background not clean magenta, retrying with another seed")
            if not a.raw:
                png = flatten_background(png)
            path = os.path.join(OUT, "%s%s_s%d.png" % (n, "_" + a.style if a.style != "3d" else "", seed))
            open(path, "wb").write(png)
            print("%s seed %d -> %s (%.0fs)" % (n, seed, path, time.time() - t))
            if a.inbox and v == 0:
                shutil.copy2(path, os.path.join(INBOX, n + ".png"))
                print("  copied to inbox as", n + ".png")


if __name__ == "__main__":
    main()

