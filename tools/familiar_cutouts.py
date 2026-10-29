"""Familiar cutouts for the collection screen (T103): the textured front still of each familiar with the flat backdrop keyed out (transparent PNG, 384 px, cropped and
centred on a square canvas). In game the same image is shown in colour for a discovered familiar and tinted black (ImageColor3) as its silhouette for an undiscovered one.
Writes Roblox Dev/Assets/Characters/Collection/<Name>_cutout.png. Run with the Hunyuan3D venv."""
import pathlib, sys
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Collection"
OUT.mkdir(parents=True, exist_ok=True)
for p in sorted(fc.LORE.glob("*.md")):
    im = fc.key_out(Image.open(fc.TEX / f"{p.stem}_tex_front.png").convert("RGBA"))
    im = im.crop(im.getbbox())
    s = 340 / max(im.size)
    im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    canvas = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    canvas.paste(im, ((384 - im.width) // 2, 384 - im.height - 22), im)
    canvas.save(OUT / f"{p.stem}_cutout.png")
    print(p.stem, canvas.getbbox())
