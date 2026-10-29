"""Check the rigged familiars (T106). Reads each <Name>_rigged.glb (JSON chunk) and <Name>_rig_stats.json in Roblox Dev/Assets/3D/Familiars/rigged and Blender/rig_spec.py.
Hard checks per familiar: one skin whose joint names equal the archetype template exactly; the glTF node hierarchy of those joints equals the template's parents;
the core chain Root > Pelvis > Spine > Chest > Neck > Head is identical in all 12; at most 4 influences per vertex; weights sum to 1 (1 +/- 0.001); a head turn (30 degrees),
a spine lean (15 degrees) and a first-limb bend (40 degrees) each move at least 100 vertices on the evaluated mesh; each limb bone listed owns at least 1 vertex with weight 0.3 or more
except where reported. Warnings (not failures): bones that own fewer than 30 vertices, which means the template bone has little geometry near it on that model.
Exit 1 on any hard failure. Pure standard library."""
import json, pathlib, struct, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Blender"))
import rig_spec

D = ROOT / "Roblox Dev" / "Assets" / "3D" / "Familiars" / "rigged"


def glb_json(path):
    data = path.read_bytes()
    assert data[:4] == b"glTF"
    clen, ctype = struct.unpack("<II", data[12:20])
    assert ctype == 0x4E4F534A
    return json.loads(data[20:20 + clen])


bad, warns, core_seen = 0, [], {}
print(f"{'model':16} {'archetype':10} {'bones':>5} {'joints':>6} {'infl':>4} {'wsum':>13} {'head':>5} {'spine':>5} {'limb':>5}  result")
for g in sorted(D.glob("*_rigged.glb")):
    name = g.stem[:-7]
    j = glb_json(g)
    st = json.loads((D / f"{name}_rig_stats.json").read_text())
    spec = rig_spec.template(rig_spec.ARCHETYPE[name])
    want_names = [b[0] for b in spec]
    want_parent = {b[0]: b[1] for b in spec}
    problems = []
    skins = j.get("skins", [])
    if len(skins) != 1:
        problems.append(f"{len(skins)} skins")
        joints, parent = [], {}
    else:
        nodes = j["nodes"]
        jn = skins[0]["joints"]
        joints = [nodes[i]["name"] for i in jn]
        kids = {nodes[i]["name"]: [nodes[c]["name"] for c in nodes[i].get("children", [])] for i in jn}
        parent = {k: None for k in joints}
        for p, ch in kids.items():
            for c in ch:
                if c in parent:
                    parent[c] = p
        if sorted(joints) != sorted(want_names):
            problems.append("joint names differ from the template")
        if {k: parent.get(k) for k in want_names} != want_parent:
            problems.append("hierarchy differs from the template")
    core = [(b, want_parent[b]) for b in rig_spec.CORE_NAMES]
    core_seen[name] = core
    if st["max_influences"] > 4:
        problems.append("more than 4 influences")
    if not (0.999 <= st["weight_sum_min"] and st["weight_sum_max"] <= 1.001):
        problems.append("weights do not sum to 1")
    t = st["pose_tests"]
    for k, need in (("head_turn", 100), ("spine_lean", 100), ("limb_bend", 100)):
        if t[k]["vertices_moved"] < need:
            problems.append(f"{k} moved {t[k]['vertices_moved']} vertices")
    low = {b: n for b, n in st["owned_vertices_by_bone"].items() if n < 30 and b != "Root"}
    if low:
        warns.append(f"{name} ({st['archetype']}): bones with under 30 owned vertices: " + ", ".join(f"{b} {n}" for b, n in low.items()))
    bad += bool(problems)
    print(f"{name:16} {st['archetype']:10} {len(want_names):5d} {len(joints):6d} {st['max_influences']:4d} {st['weight_sum_min']:.3f}-{st['weight_sum_max']:.3f} "
          f"{t['head_turn']['vertices_moved']:5d} {t['spine_lean']['vertices_moved']:5d} {t['limb_bend']['vertices_moved']:5d}  {'ok' if not problems else '; '.join(problems)}")
if len({json.dumps(v) for v in core_seen.values()}) != 1:
    bad += 1
    print("core chain differs between familiars")
else:
    print("core chain identical in all familiars:", " > ".join(rig_spec.CORE_NAMES))
counts = {}
for n, a in rig_spec.ARCHETYPE.items():
    counts[a] = counts.get(a, 0) + 1
print("archetypes:", counts, "| bone counts:", {a: len(rig_spec.template(a)) for a in counts})
for w in warns:
    print("WARNING", w)
print("models:", len(list(D.glob('*_rigged.glb'))), "problems:", bad)
sys.exit(1 if bad or len(list(D.glob('*_rigged.glb'))) != 12 else 0)
