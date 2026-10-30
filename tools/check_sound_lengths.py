"""No sound plays longer than its declared length (T236): python tools/check_sound_lengths.py
Reads Studio_Export/SoundCatalog.luau (name -> dur seconds, vol, pri) and VFX/sfx/out/<name>.wav; a sound is a problem when its WAV is longer than its declared dur by more than 0.05 s, when a declared sound has no WAV file,
or when a WAV has no catalog entry (information). Also prints the priority list (pri 1 is dropped first) for the mix notes. Exit 1 on a problem. Stdlib only."""
import pathlib
import re
import sys
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
cat = {}
for m in re.finditer(r"^\s*(\w+) = \{ dur = ([\d.]+), vol = ([\d.]+), pri = (\d)", (ROOT / "Studio_Export" / "SoundCatalog.luau").read_text(encoding="utf-8"), re.M):
    cat[m.group(1)] = (float(m.group(2)), float(m.group(3)), int(m.group(4)))
out = ROOT / "VFX" / "sfx" / "out"
bad, longest = [], []
for name, (dur, vol, pri) in cat.items():
    f = out / f"{name}.wav"
    if not f.exists():
        bad.append(f"{name}: declared in the catalog but {f.name} is missing")
        continue
    with wave.open(str(f)) as w:
        secs = w.getnframes() / w.getframerate()
    longest.append((secs, name))
    if secs > dur + 0.05:
        bad.append(f"{name}: file {secs:.3f} s is longer than the declared {dur:.3f} s")
man = ROOT / "VFX" / "sfx" / "MANIFEST.md"  # overnight cue set: every row needs its WAV, length within 0.05 s of the row
nman = 0
if man.exists():
    for m in re.finditer(r"^\| (\w+) \| ([\d.]+) \|", man.read_text(encoding="utf-8"), re.M):
        nman += 1
        f = out / f"{m.group(1)}.wav"
        if not f.exists():
            bad.append(f"{m.group(1)}: in MANIFEST.md but {f.name} is missing")
            continue
        with wave.open(str(f)) as w:
            secs = w.getnframes() / w.getframerate()
        if abs(secs - float(m.group(2))) > 0.05:
            bad.append(f"{m.group(1)}: file {secs:.3f} s differs from MANIFEST.md {m.group(2)} s")
print(f"{nman} MANIFEST.md sounds checked")
extra = sorted(p.stem for p in out.glob("*.wav") if p.stem not in cat)
print(f"{len(cat)} catalog sounds checked; longest {max(longest)[1]} {max(longest)[0]:.2f} s")
print("priority 1 (dropped first):", ", ".join(sorted(n for n, v in cat.items() if v[2] == 1)))
print("priority 3 (kept longest):", ", ".join(sorted(n for n, v in cat.items() if v[2] == 3)))
if extra:
    print(f"WAV files with no catalog entry ({len(extra)}, information):", ", ".join(extra))
print("PROBLEMS:" if bad else "all sounds within their declared length", *bad, sep="\n")
sys.exit(1 if bad else 0)
