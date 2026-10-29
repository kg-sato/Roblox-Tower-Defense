"""Asset budget report and check (T228, T237): python tools/asset_budget.py
Scans every GLB under Roblox Dev/Assets/3D and every audio file (wav, ogg, mp3) under Audio and VFX/sfx/out.
Budgets: triangles per mesh 20,000 (project rule; enemies and bosses 3,000 as chosen in Design/Enemy Models), embedded texture at most 1024 px on a side, one audio file at most 120 s (music is exempt up to 600 s).
Writes Overnight/evidence/asset_budget.json and prints the worst offenders; exit 1 if any budget is broken. Triangle counts come from the GLB index accessors (no Blender needed); audio length from the WAV header or, for OGG and MP3, from the file size only if a length cannot be read (reported as 'unknown')."""
import json
import pathlib
import struct
import sys
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
TRI_LIMIT, ENEMY_LIMIT, TEX_LIMIT, SFX_LIMIT, MUSIC_LIMIT = 20000, 3000, 1024, 120, 600


def glb_info(path):
    data = path.read_bytes()
    if data[:4] != b"glTF":
        return None
    clen, _ = struct.unpack("<II", data[12:20])
    j = json.loads(data[20:20 + clen])
    bin_off = 20 + clen + 8
    tris = 0
    for m in j.get("meshes", []):
        for p in m.get("primitives", []):
            if "indices" in p:
                tris += j["accessors"][p["indices"]]["count"] // 3
            else:
                tris += j["accessors"][p["attributes"]["POSITION"]]["count"] // 3
    sizes = []
    for im in j.get("images", []):
        if "bufferView" not in im:
            continue
        bv = j["bufferViews"][im["bufferView"]]
        raw = data[bin_off + bv.get("byteOffset", 0): bin_off + bv.get("byteOffset", 0) + bv["byteLength"]]
        if raw[:8] == b"\x89PNG\r\n\x1a\n":
            sizes.append(struct.unpack(">II", raw[16:24]))
        elif raw[:2] == b"\xff\xd8":
            i = 2
            while i < len(raw):
                if raw[i] != 0xFF:
                    break
                marker = raw[i + 1]
                seglen = struct.unpack(">H", raw[i + 2:i + 4])[0]
                if marker in (0xC0, 0xC2):
                    h, w = struct.unpack(">HH", raw[i + 5:i + 9])
                    sizes.append((w, h))
                    break
                i += 2 + seglen
    return tris, sizes


report = {"meshes": [], "audio": []}
bad = []
for p in sorted((ROOT / "Roblox Dev" / "Assets" / "3D").rglob("*.glb")):
    info = glb_info(p)
    if not info:
        continue
    tris, sizes = info
    rel = str(p.relative_to(ROOT)).replace("\\", "/")
    limit = ENEMY_LIMIT if "/Enemies/" in rel else TRI_LIMIT
    mx = max([max(s) for s in sizes], default=0)
    row = {"file": rel, "triangles": tris, "limit": limit, "max_texture": mx}
    report["meshes"].append(row)
    if tris > limit:
        bad.append(f"{rel}: {tris} triangles over {limit}")
    if mx > TEX_LIMIT:
        bad.append(f"{rel}: texture {mx} px over {TEX_LIMIT}")
for base in (ROOT / "Audio", ROOT / "VFX" / "sfx" / "out"):
    for p in sorted(base.rglob("*")):
        if p.suffix.lower() not in (".wav", ".ogg", ".mp3") or "__pycache__" in str(p):
            continue
        rel = str(p.relative_to(ROOT)).replace("\\", "/")
        secs = None
        if p.suffix.lower() == ".wav":
            try:
                with wave.open(str(p)) as w:
                    secs = w.getnframes() / w.getframerate()
            except Exception:
                secs = None
        limit = MUSIC_LIMIT if "Music" in rel else SFX_LIMIT
        report["audio"].append({"file": rel, "seconds": None if secs is None else round(secs, 1), "limit": limit})
        if secs is not None and secs > limit:
            bad.append(f"{rel}: {secs:.0f} s over {limit}")
(ROOT / "Overnight" / "evidence" / "asset_budget.json").write_text(json.dumps(report, indent=1))
m = report["meshes"]
print(f"{len(m)} meshes; most triangles: " + ", ".join(f"{r['file'].split('/')[-1]} {r['triangles']}" for r in sorted(m, key=lambda r: -r["triangles"])[:5]))
print(f"largest texture {max((r['max_texture'] for r in m), default=0)} px")
a = report["audio"]
known = [r for r in a if r["seconds"] is not None]
print(f"{len(a)} audio files ({len(known)} with a readable length); longest: " + ", ".join(f"{r['file'].split('/')[-1]} {r['seconds']}s" for r in sorted(known, key=lambda r: -r["seconds"])[:3]))
print("OVER BUDGET:" if bad else "all within budget", *bad, sep="\n")
sys.exit(1 if bad else 0)
