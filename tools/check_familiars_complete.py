"""Every familiar has a bio, a portrait, a voice line and a silhouette entry (T231): python tools/check_familiars_complete.py
Per familiar in Roblox Dev/Lore/Familiars/*.md: bio = the lore note exists and has more than 400 characters; portrait = Assets/Characters/Cards/<Name>_card.png and Collection/<Name>_cutout.png exist;
voice line = Roblox Dev/Lore/voice_lines.json has a non-empty entry; silhouette entry = the lore note has a section or line naming the silhouette. Exit 1 on any gap. Stdlib only."""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
D = ROOT / "Roblox Dev"
voice = json.loads((D / "Lore" / "voice_lines.json").read_text(encoding="utf-8"))
bad = 0
names = sorted(p.stem for p in (D / "Lore" / "Familiars").glob("*.md"))
for n in names:
    text = (D / "Lore" / "Familiars" / f"{n}.md").read_text(encoding="utf-8")
    checks = {
        "bio": len(text) > 400,
        "card": (D / "Assets" / "Characters" / "Cards" / f"{n}_card.png").exists(),
        "cutout": (D / "Assets" / "Characters" / "Collection" / f"{n}_cutout.png").exists(),
        "voice": bool(voice.get(n)),
        "silhouette": "silhouette" in text.lower(),
    }
    miss = [k for k, v in checks.items() if not v]
    bad += bool(miss)
    print(f"{n}: {'ok' if not miss else 'MISSING ' + ', '.join(miss)}")
print(f"{len(names)} familiars, {bad} with gaps")
sys.exit(1 if bad else 0)
