"""Check the banish animations (T095). Reads each <Name>_banish.glb (JSON chunk) and <Name>_banish_stats.json in Roblox Dev/Assets/3D/Familiars/banish.
Per model: one animation named Banish, duration 1.1 to 1.3 s, 3+ channels, skin joints match bones, starts at the rest pose (rest error under 0.001),
a small anticipation swell at frame 6 (1.02 to 1.10), not an instant vanish (frame 12 between 0.6 and 0.95), never grows again after frame 6,
ends hidden (frame 36 height ratio under 0.05). Exit 1 on any failure. Pure standard library."""
import json, pathlib, struct, sys

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "banish"


def glb_json(path):
    data = path.read_bytes()
    assert data[:4] == b"glTF"
    clen, ctype = struct.unpack("<II", data[12:20])
    assert ctype == 0x4E4F534A
    return json.loads(data[20:20 + clen])


bad = 0
print(f"{'model':16} {'anim':6} {'chan':>4} {'secs':>5} {'joints':>6} {'f6':>5} {'f12':>5} {'f24':>5} {'f36':>5} {'rest_err':>8}")
for g in sorted(D.glob("*_banish.glb")):
    name = g.stem[:-7]
    j = glb_json(g)
    an = j.get("animations", [])
    st = json.loads((D / f"{name}_banish_stats.json").read_text())
    ok = len(an) == 1 and an[0].get("name") == "Banish"
    chan = len(an[0]["channels"]) if an else 0
    dur = max((j["accessors"][s["input"]]["max"][0] for s in an[0]["samplers"]), default=0) if an else 0
    joints = len(j["skins"][0]["joints"]) if j.get("skins") else 0
    r = st["height_ratio_by_frame"]
    seq = [r[k] for k in ("6", "12", "18", "24", "30", "36")]
    mono = all(b <= a for a, b in zip(seq, seq[1:]))
    ok = ok and 1.1 <= dur <= 1.3 and chan >= 3 and joints == len(st["bones"]) and 1.02 <= r["6"] <= 1.10 and 0.6 <= r["12"] <= 0.95 and mono and r["36"] < 0.05 and st["rest_error"] < 0.001
    bad += not ok
    print(f"{name:16} {an[0]['name'] if an else '-':6} {chan:4d} {dur:5.2f} {joints:6d} {r['6']:5.2f} {r['12']:5.2f} {r['24']:5.2f} {r['36']:5.2f} {st['rest_error']:8.5f}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*_banish.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
