"""Collect the familiar voice lines (T098) from Roblox Dev/Lore/Familiars/<Name>.md into one note and one JSON file, and check them.
Writes Roblox Dev/Lore/Familiar Voice Lines.md and Roblox Dev/Lore/voice_lines.json. Checks per familiar: exactly 3 lines (summon, attack, victory) and 3 tone words,
each line 1 to 8 words and at most 40 characters, no line repeated across the cast, the line does not contain the familiar's own name
(rule: the speaker should be guessable without it). Exit 1 on any failure. Pure standard library."""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LORE = ROOT / "Roblox Dev" / "Lore"
MAX_WORDS, MAX_CHARS = 8, 40
rows, bad, seen = [], 0, {}
for p in sorted((LORE / "Familiars").glob("*.md")):
    t = p.read_text(encoding="utf-8")
    name = re.search(r"\*\*Name and epithet:\*\* ([^,]+),", t).group(1).strip()
    m = re.search(r'\*\*Voice \(3 words\):\*\* ([^.]+)\. Lines: summon "(.+?)" Attack "(.+?)" Victory "(.+?)"', t)
    problems = []
    if not m:
        rows.append({"file": p.stem, "name": name, "problems": ["voice line not found"]}); bad += 1; continue
    tone = [w.strip() for w in m.group(1).split(",")]
    lines = {"summon": m.group(2), "attack": m.group(3), "victory": m.group(4)}
    if len(tone) != 3:
        problems.append("tone is not 3 words")
    for k, v in lines.items():
        n = len(re.findall(r"[\w']+", v))
        if not 1 <= n <= MAX_WORDS:
            problems.append(f"{k} has {n} words")
        if len(v) > MAX_CHARS:
            problems.append(f"{k} has {len(v)} characters")
        if re.search(r"\b" + re.escape(name.split()[-1]) + r"\b", v, re.I):
            problems.append(f"{k} contains the name")
        if v in seen:
            problems.append(f"{k} repeats {seen[v]}")
        seen[v] = p.stem + "." + k
    bad += bool(problems)
    rows.append({"file": p.stem, "name": name, "tone": tone, **lines, "problems": problems})
md = ["# Familiar Voice Lines (T098)", "",
      "Text for later recording. Collected by `tools/voice_lines.py` from each [[Cast List - 12 Familiars|familiar]] page in `Familiars/`; the lines were written in T075 to T086 under rule 6 of [[Character Bible Rules]]. Tone is three words. Not recorded or tested in game yet; read-aloud pacing and sound are UNVERIFIED.", "",
      "| Familiar | Tone | Summon | Attack | Victory |", "|---|---|---|---|---|"]
for r in rows:
    if "summon" in r:
        md.append(f"| [[{r['file']}]] ({r['name']}) | {', '.join(r['tone'])} | {r['summon']} | {r['attack']} | {r['victory']} |")
(LORE / "Familiar Voice Lines.md").write_text("\n".join(md) + "\n", encoding="utf-8")
(LORE / "voice_lines.json").write_text(json.dumps({r["file"]: {k: r[k] for k in ("name", "tone", "summon", "attack", "victory")} for r in rows if "summon" in r}, indent=1), encoding="utf-8")
print(f"{'familiar':16} {'summon':6} {'attack':6} {'victory':7}  problems")
for r in rows:
    wc = lambda k: len(re.findall(r"[\w']+", r.get(k, "")))
    print(f"{r['file']:16} {wc('summon'):6d} {wc('attack'):6d} {wc('victory'):7d}  {'; '.join(r['problems']) or 'ok'}")
print("familiars:", len(rows), "problems:", bad)
sys.exit(1 if bad or len(rows) != 12 else 0)
