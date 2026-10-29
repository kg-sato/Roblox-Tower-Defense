import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
page = (root / "Roblox Dev" / "Design" / "Credits and Licences.md").read_text(encoding="utf-8")
problems = []
sources = ["Audio/CREDITS.md", "VFX/ASSETS.md", "Vendor/README.md", "Animation Kit/docs/CREDITS.md", "CLAUDE.md"]
for s in sources:
    if not (root / s).exists():
        problems.append(f"missing source file {s}")
    if s not in page:
        problems.append(f"page does not cite {s}")
audio = (root / "Audio" / "CREDITS.md").read_text(encoding="utf-8")
for name in ["Gichco", "omfgdude", "RandomMind", "Fupi", "beardalaxy"]:
    if name not in page:
        problems.append(f"credit text lacks {name}")
    if name not in audio:
        problems.append(f"{name} not in Audio/CREDITS.md")
kit = (root / "Animation Kit" / "docs" / "CREDITS.md").read_text(encoding="utf-8")
if "fwjelaa" not in kit or "fwjelaa (FWJ STUDIOS)" not in page:
    problems.append("fwjelaa credit missing")
assets = (root / "VFX" / "ASSETS.md").read_text(encoding="utf-8")
for name in ["Unity Labs", "AnnoMotion", "particlefx", "Yuruzuu", "CodeManu"]:
    if name.lower() not in page.lower():
        problems.append(f"page lacks {name}")
    if name.lower() not in assets.lower():
        problems.append(f"{name} not in VFX/ASSETS.md")
rows = [l for l in page.splitlines() if l.startswith("| ") and "Licence stated" not in l and "---" not in l]
print(f"table rows={len(rows)}; decisions flagged={page.count('needs your decision') + page.count('Needs your decision')}")
print("PROBLEMS:", problems or "none")
sys.exit(1 if problems else 0)
