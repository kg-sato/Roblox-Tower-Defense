"""Check the attack animations (T093). Reads each <Name>_attack.glb (JSON chunk) and <Name>_attack_stats.json in Roblox Dev/Assets/3D/Familiars/attack.
Per model: one animation named Attack, duration 0.9 to 1.1 s, channels, a skin whose joint count matches the bones, windup motion (frame 8), release motion
(frame 11, must exceed windup), forward displacement of the centroid at release (more negative Y than rest by at least 0.1), windup not forward of rest,
return-to-rest error under 0.001. Exit 1 on any failure. Pure standard library."""
import json, pathlib, struct, sys

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "attack"


def glb_json(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack("<4sII", data[:12])
    assert magic == b"glTF"
    clen, ctype = struct.unpack("<II", data[12:20])
    assert ctype == 0x4E4F534A
    return json.loads(data[20:20 + clen])


bad = 0
print(f"{'model':16} {'anim':7} {'chan':>4} {'secs':>5} {'joints':>6} {'wind':>6} {'rel':>6} {'fwd':>7} {'wind_y':>7} {'return':>7}")
for g in sorted(D.glob("*_attack.glb")):
    name = g.stem[:-7]
    j = glb_json(g)
    anims = j.get("animations", [])
    st = json.loads((D / f"{name}_attack_stats.json").read_text())
    ok = len(anims) == 1 and anims[0].get("name") == "Attack"
    chan = len(anims[0]["channels"]) if anims else 0
    dur = 0.0
    if anims:
        for s in anims[0]["samplers"]:
            dur = max(dur, j["accessors"][s["input"]]["max"][0])
    joints = len(j["skins"][0]["joints"]) if j.get("skins") else 0
    m = st["max_vertex_motion_by_frame"]
    wind, rel = m["8"], m["11"]
    fwd = st["centroid_y_rest"] - st["centroid_y_release"]
    wind_y = st["centroid_y_windup"] - st["centroid_y_rest"]
    ret = st["loop_closure_error"]
    ok = ok and 0.9 <= dur <= 1.1 and chan >= 3 and joints == len(st["bones"]) and rel > wind and fwd >= 0.1 and wind_y >= 0 and ret < 0.001
    bad += not ok
    nm = anims[0].get("name", "?") if anims else "-"
    print(f"{name:16} {nm:7} {chan:4d} {dur:5.2f} {joints:6d} {wind:6.3f} {rel:6.3f} {fwd:7.3f} {wind_y:7.3f} {ret:7.5f}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*_attack.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
