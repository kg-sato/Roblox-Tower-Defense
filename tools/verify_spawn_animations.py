"""Check the spawn animations (T094). Reads each <Name>_spawn.glb (JSON chunk) and <Name>_spawn_stats.json in Roblox Dev/Assets/3D/Familiars/spawn.
Per model: one animation named Spawn, duration 1.4 to 1.6 s, 3+ channels, skin joints match bones, "not a pop" checks: start height ratio under 0.15,
frame 4 still under 0.3 and frame 12 between 0.3 and 0.6, growth never shrinks until the overshoot frame 30, overshoot between 1.03 and 1.12, final
rest error under 0.001. Exit 1 on any failure. Pure standard library."""
import json, pathlib, struct, sys

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "spawn"


def glb_json(path):
    data = path.read_bytes()
    assert data[:4] == b"glTF"
    clen, ctype = struct.unpack("<II", data[12:20])
    assert ctype == 0x4E4F534A
    return json.loads(data[20:20 + clen])


bad = 0
print(f"{'model':16} {'anim':6} {'chan':>4} {'secs':>5} {'joints':>6} {'f1':>5} {'f4':>5} {'f12':>5} {'f30':>5} {'rest_err':>8}")
for g in sorted(D.glob("*_spawn.glb")):
    name = g.stem[:-6]
    j = glb_json(g)
    an = j.get("animations", [])
    st = json.loads((D / f"{name}_spawn_stats.json").read_text())
    ok = len(an) == 1 and an[0].get("name") == "Spawn"
    chan = len(an[0]["channels"]) if an else 0
    dur = max((j["accessors"][s["input"]]["max"][0] for s in an[0]["samplers"]), default=0) if an else 0
    joints = len(j["skins"][0]["joints"]) if j.get("skins") else 0
    r = st["height_ratio_by_frame"]
    seq = [r[k] for k in ("1", "4", "6", "10", "12", "18", "24", "30")]
    mono = all(b >= a for a, b in zip(seq, seq[1:]))
    ok = ok and 1.4 <= dur <= 1.6 and chan >= 3 and joints == len(st["bones"]) and r["1"] < 0.15 and r["4"] < 0.3 and 0.3 <= r["12"] <= 0.6 and mono and 1.03 <= r["30"] <= 1.12 and st["rest_error"] < 0.001
    bad += not ok
    print(f"{name:16} {an[0]['name'] if an else '-':6} {chan:4d} {dur:5.2f} {joints:6d} {r['1']:5.2f} {r['4']:5.2f} {r['12']:5.2f} {r['30']:5.2f} {st['rest_error']:8.5f}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*_spawn.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
