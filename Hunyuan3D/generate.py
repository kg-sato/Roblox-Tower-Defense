"""Make Roblox-ready 3D models from images with Hunyuan3D-2mini Turbo (shape only).

Usage (from the Hunyuan3D folder):
    .venv\\Scripts\\python generate.py path\\to\\image.png [more images...]
    .venv\\Scripts\\python generate.py images\\ --faces 10000 --quality high

Each image becomes <name>.glb in the vault's Assets/3D folder (or --out).
Meshes are cleaned and reduced to stay under Roblox's 20,000-triangle limit.
"""
import argparse
import os
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Keep downloaded model weights inside this project folder.
os.environ.setdefault("HF_HOME", str(HERE / "hf_cache"))
os.environ.setdefault("U2NET_HOME", str(HERE / "hf_cache" / "u2net"))
sys.path.insert(0, str(HERE / "Hunyuan3D-2"))

import torch  # noqa: E402
from PIL import Image  # noqa: E402

from hy3dgen.rembg import BackgroundRemover  # noqa: E402
from hy3dgen.shapegen import (  # noqa: E402
    DegenerateFaceRemover,
    FaceReducer,
    FloaterRemover,
    Hunyuan3DDiTFlowMatchingPipeline,
)

DEFAULT_OUT = HERE.parent / "Roblox Dev" / "Assets" / "3D"
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}
QUALITY = {  # octree resolution: higher = more detail, more VRAM and time
    "fast": 256,
    "normal": 320,
    "high": 380,
}


def collect_images(paths):
    images = []
    for p in map(Path, paths):
        if p.is_dir():
            images += sorted(f for f in p.iterdir() if f.suffix.lower() in IMAGE_EXTS)
        elif p.exists():
            images.append(p)
        else:
            print(f"Skipping missing file: {p}")
    return images


def load_image(path, rembg):
    image = Image.open(path)
    has_alpha = image.mode == "RGBA" and image.getextrema()[3][0] < 255
    if not has_alpha:
        image = rembg(image.convert("RGB"))
    return image.convert("RGBA")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("images", nargs="+", help="image files or folders")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT, help="output folder")
    ap.add_argument("--faces", type=int, default=18000, help="max triangles (Roblox limit is 20000)")
    ap.add_argument("--quality", choices=QUALITY, default="normal")
    ap.add_argument("--steps", type=int, default=5, help="denoising steps (turbo model: 5 is enough)")
    ap.add_argument("--seed", type=int, default=12345)
    args = ap.parse_args()

    if args.faces > 20000:
        sys.exit("--faces must be 20000 or less for Roblox.")
    images = collect_images(args.images)
    if not images:
        sys.exit("No images found.")
    args.out.mkdir(parents=True, exist_ok=True)

    print("Loading Hunyuan3D-2mini Turbo (first run downloads the model)...")
    pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
        "tencent/Hunyuan3D-2mini",
        subfolder="hunyuan3d-dit-v2-mini-turbo",
        use_safetensors=False,
        device="cuda",
    )
    pipeline.enable_flashvdm(topk_mode="merge")
    rembg = BackgroundRemover()
    cleanup = [FloaterRemover(), DegenerateFaceRemover()]
    reducer = FaceReducer()

    for path in images:
        start = time.time()
        torch.cuda.reset_peak_memory_stats()
        image = load_image(path, rembg)
        mesh = pipeline(
            image=image,
            num_inference_steps=args.steps,
            octree_resolution=QUALITY[args.quality],
            num_chunks=20000,
            generator=torch.manual_seed(args.seed),
            output_type="trimesh",
        )[0]
        for step in cleanup:
            mesh = step(mesh)
        mesh = reducer(mesh, max_facenum=args.faces)

        out_file = args.out / f"{path.stem}.glb"
        mesh.export(out_file)
        peak = torch.cuda.max_memory_allocated() / 2**30
        print(f"{path.name} -> {out_file}  |  {len(mesh.faces)} triangles  |  "
              f"{time.time() - start:.1f}s  |  peak VRAM {peak:.1f} GB")


if __name__ == "__main__":
    main()
