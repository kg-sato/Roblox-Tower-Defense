import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
story = root / "Roblox Dev" / "Lore" / "Story"
page = (story / "Ending - The Clock Turns.md").read_text(encoding="utf-8")
ch5 = (story / "Chapter 5 - Above the Grey Veil.md").read_text(encoding="utf-8")
problems = []
# 1. captions in the shot list
caps = re.findall(r"`(\[ [A-Z' -]+ \])`", page)
if len(caps) < 2:
    problems.append("expected at least 2 captions in the shot list")
for c in caps:
    if c not in ch5:
        problems.append(f"caption not in chapter 5: {c}")
# 2. narration and voice lines (quoted after Narration: or Voice:) must appear in chapter 5, ignoring the extra pip line
quotes = re.findall(r'(?:Narration|Voice): "([^"]+)"', page)
for q in quotes:
    if q not in ch5:
        problems.append(f"line not in chapter 5: {q}")
# 3. shot timings contiguous to 45 s
times = re.findall(r"\|\s*(\d+)(?: to (\d+))? \|", page)
spans = []
for a, b in times:
    spans.append((int(a), int(b) if b else int(a)))
spans = [s for s in spans if s[1] >= s[0]]
spans.sort()
end = spans[-1][1] if spans else 0
prev = 0
for a, b in spans:
    if a != prev and not (a == b and a == prev):
        problems.append(f"gap before {a}s (previous ended {prev}s)")
    prev = b
if end != 45:
    problems.append(f"shot list ends at {end}s, want 45")
print(f"captions={caps} lines_checked={len(quotes)} shots={len(spans)} end={end}s")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
