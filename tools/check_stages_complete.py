"""Every stage has lore, a caption and music assigned, and uses the right stage set (T232): python tools/check_stages_complete.py
For stages 1 to 25: lore = the chapter note exists (Roblox Dev/Lore/Story/Chapter N - *.md, N = ceil(stage / 5)); caption = Stage Captions.md has an intro row for the stage; music = the stage set in Studio_Export/StageSets.luau
names a music state that exists in Studio_Export/MusicFX.luau (Music.states); set = the set StageSets gives the stage matches the lore's set for that chapter (the lore has five sets, StageSets.forStage repeats the list after its last set).
Exit 1 on any gap. Stdlib only."""
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LORE = ROOT / "Roblox Dev" / "Lore"
text = (ROOT / "Studio_Export" / "StageSets.luau").read_text(encoding="utf-8")
sets = []
for m in re.finditer(r'\{\s*id = "(\w+)"(.*?)\n\t\},?', text, re.S):
    body = m.group(2)
    mu = re.search(r'music = "(\w+)"', body)
    st = re.search(r"stages = (\d+)", body)
    sets.append((m.group(1), mu.group(1) if mu else None, int(st.group(1)) if st else 5))
states = set(re.findall(r"^\t(\w+) = \{", re.search(r"Music\.states = \{(.*?)\n\}", (ROOT / "Studio_Export" / "MusicFX.luau").read_text(encoding="utf-8"), re.S).group(1), re.M))
captions = set(int(n) for n in re.findall(r"^\| \d+ \| (\d+) \| intro \|", (LORE / "Story" / "Stage Captions.md").read_text(encoding="utf-8"), re.M))
chapters = {int(re.match(r"Chapter (\d)", p.name).group(1)): p.name for p in (LORE / "Story").glob("Chapter *.md")}
lore_sets = ["LampwickLane", "HarbourOfBrass", "SilentCathedral", "ClockworkFoundry", "AboveTheGreyVeil"]
bad = 0
for stage in range(1, 26):
    total, chosen = 0, sets[0]
    for s in sets:
        if stage <= total + s[2]:
            chosen = s
            break
        total += s[2]
    else:
        chosen = sets[((stage - 1) // 5) % len(sets)]
    chapter = math.ceil(stage / 5)
    probs = []
    if chapter not in chapters:
        probs.append("no chapter note")
    if stage not in captions:
        probs.append("no intro caption")
    if not chosen[1] or chosen[1] not in states:
        probs.append(f"music state {chosen[1]} not defined")
    if chosen[0] != lore_sets[chapter - 1]:
        probs.append(f"uses set {chosen[0]}, lore says {lore_sets[chapter - 1]}")
    bad += bool(probs)
    if probs:
        print(f"stage {stage}: " + "; ".join(probs))
print(f"25 stages, {bad} with gaps; StageSets defines {len(sets)} sets: {', '.join(s[0] for s in sets)}")
sys.exit(1 if bad else 0)
