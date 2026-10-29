"""Generate full-body character concept images for the Mythic and Celestial familiars with the local ComfyUI (FLUX.1 schnell Q4), keyed to transparent PNGs for Hunyuan3D.
    Hunyuan3D/.venv/Scripts/python tools/comfy_character.py CantorVesper --variants 4 [--seed 11]
Prompts live in CHARACTERS below. Outputs: Roblox Dev/Assets/Characters/Concept/<Name>_s<seed>.png (raw) and Hunyuan3D/input_new/<Name>_s<seed>.png (magenta keyed to alpha).
Starts ComfyUI through UI Kit/art/comfy_generate.py's helpers; stop the server afterwards (it holds VRAM): see QUEUE.md."""
import argparse
import importlib.util
import io
import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("comfy_generate", ROOT / "UI Kit" / "art" / "comfy_generate.py")
cg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cg)

LOOK = ("solid flat uniform pure magenta #FF00FF background edge to edge, full body character concept for a 3D model, the whole figure visible from head to boots, front view, "
        "standing straight in a neutral relaxed A-pose with the arms slightly away from the body, symmetrical, even flat lighting, no cast shadow, "
        "painted in antique gold and near-black ink tones like an engraving, dark umber shadows, cream highlights, ornate but readable shapes, ")
CHARACTERS = {
    "CantorVesper": "a tall woman, the Star Choir's cantor, in a long silver-blue greatcoat with star-shaped brass buttons and a high stiff collar, a small star-shaped crown on short silver hair, "
                    "one hand holding a slender baton of light, calm stern face, knee-high boots",
    "DameOrrery": "a broad middle-aged woman, a master clockwork engineer of the Clockwork Guild, brass mechanical forearms and hands, round goggles pushed up on her forehead, "
                  "a heavy leather apron over a dark work coat full of tools and gears, a large wrench resting on her shoulder, confident smirk",
    "TheLamplighter": "a tall hooded figure, the first lamplighter of the city, in a long dark coat with a star pattern, a long pole in one hand with a glowing star-shaped lantern on top, "
                      "kind weathered face under the hood, scarf, worn boots",
    "VeilWalker": "a slender person in a floating long cape made of thin starry veils that hang above the ground, a mirror-like mask pushed up on the head showing a calm face, "
                  "bare feet, bracelets of small stars, graceful pose",
}


def key_out(png_bytes):
    im = Image.open(io.BytesIO(png_bytes)).convert("RGB")
    a = np.array(im).astype(float)
    mag = (a[..., 0] - a[..., 1] > 60) & (a[..., 2] - a[..., 1] > 40)
    alpha = np.where(mag, 0, 255).astype("uint8")
    rgba = np.dstack([np.array(im), alpha])
    return Image.fromarray(rgba, "RGBA")


ap = argparse.ArgumentParser()
ap.add_argument("name", choices=list(CHARACTERS))
ap.add_argument("--variants", type=int, default=4)
ap.add_argument("--seed", type=int, default=11)
ap.add_argument("--size", type=int, default=768)
ap.add_argument("--view", choices=["front", "back"], default="front", help="back = the same character seen from behind (for the texture projection)")
args = ap.parse_args()
cg.start_server() if not cg.server_up() else None
(ROOT / "Roblox Dev" / "Assets" / "Characters" / "Concept").mkdir(parents=True, exist_ok=True)
(ROOT / "Hunyuan3D" / "input_new").mkdir(parents=True, exist_ok=True)
for k in range(args.variants):
    seed = args.seed + k
    text = LOOK + CHARACTERS[args.name]
    if args.view == "back":
        text = text.replace("front view", "rear view seen from directly behind, the back of the head and the back of the clothes")
    raw = cg.run_one(text, seed, args.size, 4)
    raw = cg.flatten_background(raw)
    (ROOT / "Roblox Dev" / "Assets" / "Characters" / "Concept" / f"{args.name}_{args.view}_s{seed}.png" if args.view == "back" else f"{args.name}_s{seed}.png").write_bytes(raw)
    key_out(raw).save(ROOT / "Hunyuan3D" / "input_new" / (f"{args.name}_back_s{seed}.png" if args.view == "back" else f"{args.name}_s{seed}.png"))
    print("saved", args.name, seed, "background ok:", cg.background_ok(raw))
