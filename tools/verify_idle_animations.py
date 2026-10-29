"""Check the idle animations (T092). Reads each <Name>_idle.glb (JSON chunk) and <Name>_idle_stats.json in Roblox Dev/Assets/3D/Familiars/idle.
Per model: one animation named Idle, channels, duration (s), skin joints, breathing motion (frame 15), signature motion (max over frames 48 to 96),
loop closure error. Pass: duration 3.9 to 4.1 s, at least 3 channels, a skin with the expected joints, breathing motion above 0.01 units,
signature motion at least 2x the breathing motion, loop closure error under 0.001. Exit 1 on any failure. Pure standard library."""
import json, pathlib, struct, sys

D = pathlib.Path(__file__).resolve().parents[1] / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "idle"


def glb_json(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack("<4sII", data[:12])
    assert magic == b"glTF"
    clen, ctype = struct.unpack("<II", data[12:20])
    assert ctype == 0x4E4F534A
    return json.loads(data[20:20 + clen])


bad = 0
print(f"{'model':16} {'anim':6} {'chan':>4} {'secs':>5} {'joints':>6} {'breath':>7} {'signature':>9} {'closure':>8}")
for g in sorted(D.glob("*_idle.glb")):
    name = g.stem[:-5]
    j = glb_json(g)
    anims = j.get("animations", [])
    st = json.loads((D / f"{name}_idle_stats.json").read_text())
    ok = len(anims) == 1
    chan = len(anims[0]["channels"]) if anims else 0
    dur = 0.0
    if anims:
        for s in anims[0]["samplers"]:
            acc = j["accessors"][s["input"]]
            dur = max(dur, acc["max"][0])
    skins = j.get("skins", [])
    joints = len(skins[0]["joints"]) if skins else 0
    m = st["max_vertex_motion_by_frame"]
    breath = m["15"]
    sig = max(m[k] for k in ("48", "60", "72", "84", "96"))
    clo = st["loop_closure_error"]
    expect_joints = len(st["bones"])
    ok = ok and 3.9 <= dur <= 4.1 and chan >= 3 and joints == expect_joints and breath > 0.01 and sig >= 2 * breath and clo < 0.001
    if not ok:
        bad += 1
    nm = anims[0].get("name", "?") if anims else "-"
    print(f"{name:16} {nm:6} {chan:4d} {dur:5.2f} {joints:6d} {breath:7.3f} {sig:9.3f} {clo:8.5f}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(D.glob('*_idle.glb'))), "problems:", bad)
sys.exit(1 if bad else 0)
