"""Merge evolution (T100): 3 tiers per familiar. Tier 1 is the base model. Tier 2 and tier 3 each add exactly ONE visible body feature with a reason, and the figure grows
(scale 1.00 / 1.15 / 1.30). Features are attached to the body, so they never use the rarity kit shapes of T099 (halo ring, floating shards, spike fan).
Writes Roblox Dev/Design/Merge Evolution.md, rewrites the "Merge tiers" line of each Roblox Dev/Lore/Familiars/<Name>.md, and draws
Roblox Dev/Assets/Characters/Merge/<Name>_tiers.png (3 figures at tier scale, labels under them) plus _tiers_sheet.png and _tiers_report.txt.
Checks: 12 familiars, each feature at most 10 words with a reason of 4 to 20 words, no banned kit words, all 24 features unique, area grows at least 25 percent per tier (measured on the silhouette).
Run with the Hunyuan3D venv. The features are specified, not modelled: no 3D model contains them yet."""
import pathlib, re, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import familiar_cards as fc

SCALE = (1.0, 1.15, 1.30)
BANNED = ("halo", "ring", "orbit", "shard", "spike", "crown")
TIERS = {
    "Ember": (("a second, smaller flame tongue beside the main flame", "it has learned to carry the light of two lamps"),
              ("a brass key on a chain from the handle", "a Keeper trusted it with the key to the lamp room")),
    "MothLantern": (("a second, smaller lantern hung from the other antenna", "it now guides two walkers at once"),
                    ("wing tips edged with thin gold map-lines", "it has flown the whole of Lampwick Lane and remembers it")),
    "BrassHound": (("a brass tally collar with one notch per friend", "it counts friends now, not trespassers"),
                   ("a second coiled spring tail segment", "the Foundry wound it tighter for every friend it kept")),
    "Sentinel": (("a cape of overlapping brass plates on the shoulders", "its rounds have worn a cloak of brass onto it"),
                 ("a taller plumed crest on the helmet", "the Guild promoted it for the rounds it never missed")),
    "Frostling": (("a longer icicle point on the hood", "each winter it stays, the cold grows on it"),
                  ("a scarf of frost that trails behind", "the mourners knitted it one, and it froze")),
    "Gargoyle": (("a second scarf tail", "the scarf was a gift and it will not wear less of it"),
                 ("polished stone plates on the shoulders", "weather and many years of being looked at have polished it")),
    "Ward": (("a second small lantern on the belt", "it keeps a spare light for the next ship"),
             ("a cape of rain-shimmer", "forty years of tides left their shine on it")),
    "Archivist": (("a second, smaller ledger under the other wing", "the Guild trusted it with the spare lost hours"),
                  ("a brass watch chain with a wax seal", "it was sworn in as keeper of the ledger")),
    "Mourner": (("a second veil layer", "it has given up more of its face than before"),
                ("a small candle held in the free hand", "it now lights the way for those who follow")),
    "MirrorChorister": (("a second pair of hood ears", "it hears the echo of the echo"),
                        ("a hand mirror held at the chest", "it finally keeps one reflection for itself")),
    "StarDrake": (("a second, smaller pair of wings", "the long note carries further on more wing"),
                  ("a tail tipped with one lit star-point", "the last star of the Choir answers it")),
    "GreyVeilWraith": (("a second trailing ribbon of grey cloth", "more fog has chosen to follow it"),
                       ("a pale lantern held in one trailing sleeve", "it follows the lantern, so now it carries one")),
}
OUT = fc.ROOT / "Roblox Dev" / "Assets" / "Characters" / "Merge"


def words(s):
    return len(re.findall(r"[\w'-]+", s))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows, bad, sheet_rows = [], 0, []
    feats = []
    for p in sorted(fc.LORE.glob("*.md")):
        n = p.stem
        (f2, r2), (f3, r3) = TIERS[n]
        fig = fc.key_out(Image.open(fc.TEX / f"{n}_tex_front.png").convert("RGBA"))
        fig = fig.crop(fig.getbbox())
        areas = []
        img = Image.new("RGB", (3 * 330, 380), (28, 26, 38))
        d = ImageDraw.Draw(img)
        for i, sc in enumerate(SCALE):
            k = 250 / max(fig.size) * sc
            t = fig.resize((max(1, int(fig.width * k)), max(1, int(fig.height * k))), Image.LANCZOS)
            areas.append(int((np.array(t.split()[3]) > 40).sum()))
            ox = i * 330 + (330 - t.width) // 2
            img.paste(t, (ox, 300 - t.height), t)
            d.text((i * 330 + 165, 322), f"TIER {i + 1}", font=fc.font("georgiab.ttf", 18), fill=(236, 205, 120), anchor="mm")
            lab = ("base model", f2, f3)[i]
            lines = fc.wrap(d, lab, fc.font("georgia.ttf", 14), 300)[:2]
            for j, ln in enumerate(lines):
                d.text((i * 330 + 165, 344 + 16 * j), ln, font=fc.font("georgia.ttf", 14), fill=(220, 214, 200), anchor="mm")
        img.save(OUT / f"{n}_tiers.png")
        sheet_rows.append(img)
        g = [areas[1] / areas[0], areas[2] / areas[1]]
        problems = []
        for f, r in ((f2, r2), (f3, r3)):
            if words(f) > 10 or not 4 <= words(r) <= 20:
                problems.append("length")
            if any(re.search(r"" + b + r"s?", f.lower()) for b in BANNED):
                problems.append("banned word in " + f)
            feats.append(f)
        if min(g) < 1.25:
            problems.append("area growth under 25 percent")
        bad += bool(problems)
        rows.append(f"{n:16} area growth {g[0]:.2f} / {g[1]:.2f} | {'; '.join(problems) or 'ok'}")
        t = p.read_text(encoding="utf-8")
        new = (f"- Merge tiers (T100, final): tier 2 adds {f2} ({r2}); tier 3 adds {f3} ({r3}). "
               "The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).")
        t2 = re.sub(r"^- Merge tiers \(T100.*$", lambda m: new, t, flags=re.M)
        if t2 != t:
            p.write_text(t2, encoding="utf-8")
    if len(set(feats)) != len(feats) or len(feats) != 24:
        bad += 1
        rows.append("features not 24 unique")
    sheet = Image.new("RGB", (3 * 330, 12 * 380), (28, 26, 38))
    for i, im in enumerate(sheet_rows):
        sheet.paste(im, (0, i * 380))
    sheet.resize((3 * 220, 12 * 253), Image.LANCZOS).save(OUT / "_tiers_sheet.png")
    md = ["# Merge Evolution (T100)", "",
          "Three tiers per familiar, written overnight 2026-10-29. Tier 1 is the base model; **tier 2 and tier 3 each add one body-attached feature with a reason**, "
          "and the figure grows to 115 percent and 130 percent. Features never use the rarity kit shapes (halo ring, floating shards, spike fan) of [[Rarity Silhouettes]], "
          "so a Legendary at tier 3 still reads as two different things. Rule: [[Character Bible Rules]]. Specified only: no 3D model contains these features yet, "
          "and the look is UNVERIFIED. Per-familiar strips: `Assets/Characters/Merge/<Name>_tiers.png`, `_tiers_sheet.png`. Built by `tools/merge_tiers.py`.", "",
          "| Familiar | Tier 2 adds | Why | Tier 3 adds | Why |", "|---|---|---|---|---|"]
    for n, ((f2, r2), (f3, r3)) in TIERS.items():
        md.append(f"| [[{n}]] | {f2} | {r2} | {f3} | {r3} |")
    md += ["", "## Open decisions for the user",
           "1. Merge is three of the same pet into one tier up (see the [[Game Design Doc]]); the plan has only 3 tiers, so tier 3 is the final look. Is 130 percent size at tier 3 enough on the 2 by 6 grid, or should it be larger?",
           "2. Features here are placeholders in words; the 3D work (new model parts, bone weights for the two-bone figures) is a later step and may change which features are cheap."]
    (fc.ROOT / "Roblox Dev" / "Design" / "Merge Evolution.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    rep = "\n".join(rows) + f"\nfamiliars: {len(rows)} problems: {bad}\n"
    (OUT / "_tiers_report.txt").write_text(rep, encoding="utf-8")
    print(rep)
    sys.exit(1 if bad else 0)


main()
