"""Dump the whole instance tree of a binary .rbxl/.rbxm (classes, parents, most property types, script sources) as JSON,
or as a Luau script that rebuilds a chosen subtree in Studio. Read-only parser; never runs anything from the file.
  python -I tools/rbxl_tree.py <file.rbxl> > tree.json
  python -I tools/rbxl_tree.py <file.rbxl> --luau <InstanceName> > build.luau   (rebuilds that instance and its children)
  python -I tools/rbxl_tree.py <file.rbxl> --spec <InstanceName> > spec.json    (compact tree for VFX/FXSpecBuild.luau)
  python -I tools/rbxl_tree.py <file.rbxl> --list                               (every instance path and class)
Formats per the Roblox binary model spec (same rules as tools/rbxl_emitters.py, whose readers are reused)."""
import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from rbxl_emitters import chunks, deinterleave, floats, read_prop

AXES = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (-1, 0, 0), (0, -1, 0), (0, 0, -1)]


def ints(b, n):  # interleaved big-endian zigzag int32
    out = []
    for raw in deinterleave(b, n):
        u = int.from_bytes(raw, "big")
        out.append((u >> 1) ^ -(u & 1))
    return out


def refs(b, n):
    acc, out = 0, []
    for v in ints(b, n):
        acc += v; out.append(acc)
    return out


def rot_from_id(i):
    """Axis-aligned rotation id: id = 6*axis(col0) + axis(col1) + 1. Returns row-major 3x3."""
    c0, c1 = AXES[(i - 1) // 6], AXES[(i - 1) % 6]
    c2 = (c0[1] * c1[2] - c0[2] * c1[1], c0[2] * c1[0] - c0[0] * c1[2], c0[0] * c1[1] - c0[1] * c1[0])
    return [c0[0], c1[0], c2[0], c0[1], c1[1], c2[1], c0[2], c1[2], c2[2]]


def read_any(ty, b, n):
    v = read_prop(ty, b, n)
    if v is not None:
        return v
    if ty == 0x1D:  # ProtectedString (script source)
        q, vals = 0, []
        for _ in range(n):
            l, = struct.unpack_from("<I", b, q); q += 4
            vals.append(b[q:q + l].decode("utf-8", "replace")); q += l
        return vals
    if ty == 0x03:
        return ints(b, n)
    if ty == 0x05:
        return [round(x, 5) for x in struct.unpack_from("<" + "d" * n, b, 0)]
    if ty == 0x0B:
        return [int.from_bytes(r, "big") for r in deinterleave(b, n)]
    if ty == 0x0C:  # Color3 as three float columns
        r, g, bl = floats(b[:4 * n], n), floats(b[4 * n:8 * n], n), floats(b[8 * n:12 * n], n)
        return [[x, y, z] for x, y, z in zip(r, g, bl)]
    if ty == 0x0E:
        xs, ys, zs = floats(b[:4 * n], n), floats(b[4 * n:8 * n], n), floats(b[8 * n:12 * n], n)
        return [[x, y, z] for x, y, z in zip(xs, ys, zs)]
    if ty == 0x10:  # CFrame: rotations first, then a Vector3 block of positions
        q, rots = 0, []
        for _ in range(n):
            rid = b[q]; q += 1
            if rid == 0:
                rots.append([round(x, 5) for x in struct.unpack_from("<9f", b, q)]); q += 36
            else:
                rots.append(rot_from_id(rid))
        pos = read_any(0x0E, b[q:], n)
        return [p + r for p, r in zip(pos, rots)]
    if ty == 0x13:
        return refs(b, n)
    if ty == 0x1A:  # Color3uint8
        return [[b[i] / 255, b[n + i] / 255, b[2 * n + i] / 255] for i in range(n)]
    return None


def parse(path):
    data = Path(path).read_bytes()
    assert data[:8] == b"<roblox!", "not a binary roblox file"
    classes, inst = {}, {}
    parents, skipped = {}, set()
    for name, b in chunks(data):
        if name == "INST":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); cn = b[8:8 + n].decode()
            cnt, = struct.unpack_from("<I", b, 9 + n)
            rs = refs(b[13 + n:], cnt)
            classes[cid] = (cn, rs)
            for r in rs:
                inst[r] = {"ref": r, "class": cn, "props": {}}
        elif name == "PROP":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); pn = b[8:8 + n].decode()
            cn, rs = classes[cid]
            v = read_any(b[8 + n], b[9 + n:], len(rs))
            if v is None:
                skipped.add(f"{cn}.{pn}:0x{b[8 + n]:02x}"); continue
            for r, x in zip(rs, v):
                inst[r]["props"][pn] = x
        elif name == "PRNT":
            cnt, = struct.unpack_from("<I", b, 1)
            ch, pa = refs(b[5:], cnt), refs(b[5 + 4 * cnt:], cnt)
            parents.update(zip(ch, pa))
    for r, i in inst.items():
        i["parent"] = parents.get(r, -1)
    return list(inst.values()), sorted(skipped)


def lua_val(cls, k, v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, (int, float)):
        return repr(v)
    if k in ("CFrame",) or (isinstance(v, list) and len(v) == 12):
        return "CFrame.new(" + ",".join(repr(x) for x in v) + ")"
    if isinstance(v, list) and v and isinstance(v[0], list):
        if len(v[0]) == 5:
            return "ColorSequence.new({" + ",".join(f"ColorSequenceKeypoint.new({t},Color3.new({r},{g},{bb}))" for t, r, g, bb, _ in v) + "})"
        if len(v[0]) == 3:
            return "NumberSequence.new({" + ",".join(f"NumberSequenceKeypoint.new({t},{x},{e})" for t, x, e in v) + "})"
    if isinstance(v, list) and len(v) == 2:
        return f"NumberRange.new({v[0]},{v[1]})" if k in ("Lifetime", "Speed", "Rotation", "RotSpeed", "SpreadAngle_") else f"Vector2.new({v[0]},{v[1]})"
    if isinstance(v, list) and len(v) == 3:
        return (f"Color3.new({v[0]},{v[1]},{v[2]})" if "Color" in k else f"Vector3.new({v[0]},{v[1]},{v[2]})")
    return None


SKIP = {"Source", "Tags", "AttributesSerialize", "UniqueId", "HistoryId", "SourceAssetId", "ScriptGuid", "Capabilities", "DefinesCapabilities"}


def to_luau(items, root_name):
    by = {i["ref"]: i for i in items}
    kids = {}
    for i in items:
        kids.setdefault(i["parent"], []).append(i)
    root = next(i for i in items if i["props"].get("Name") == root_name)
    out = ["local R = {}", "local function S(o,k,v) pcall(function() o[k]=v end) end"]
    refprops = []
    def emit(i, parent_var):
        var = f"R[{i['ref']}]"
        out.append(f"{var} = Instance.new({json.dumps(i['class'])})")
        for k, v in i["props"].items():
            if k in SKIP or k == "Parent":
                continue
            if i["class"] in ("Beam",) and k in ("Attachment0", "Attachment1") or k in ("Part0", "Part1", "PrimaryPart", "Adornee"):
                refprops.append((i["ref"], k, v)); continue
            if k == "SpreadAngle":
                lv = f"Vector2.new({v[0]},{v[1]})"
            elif k in ("Size",) and i["class"] in ("ParticleEmitter",):
                lv = lua_val(i["class"], "NS", v)
            else:
                lv = lua_val(i["class"], k, v)
            if lv:
                out.append(f"S({var},{json.dumps(k)},{lv})")
        for c in kids.get(i["ref"], []):
            emit(c, var)
        out.append(f"{var}.Parent = {parent_var}")
    emit(root, "PARENT")
    for r, k, v in refprops:
        if v in by:
            out.append(f"if R[{v}] then S(R[{r}],{json.dumps(k)},R[{v}]) end")
    out.append(f"return R[{root['ref']}]")
    return "\n".join(out)


SPEC_SKIP = SKIP | {"Color3uint8", "MaterialVariantSerialized", "CollisionGroupId", "RotVelocity", "Velocity", "FlipbookIncompatible",
                    "formFactorRaw", "shape", "PivotOffset", "Locked", "Massless", "RootPriority", "CollisionGroup"}
REF_PROPS = {"Attachment0", "Attachment1", "Part0", "Part1", "PrimaryPart", "Adornee"}


def to_spec(items, root_name):
    """Compact JSON tree for VFX/FXSpecBuild.luau: {c, p, k, id}; reference props become {"ref": id} and are resolved
    after the build. Surface params and other Part noise are dropped."""
    kids = {}
    for i in items:
        kids.setdefault(i["parent"], []).append(i)
    root = next(i for i in items if i["props"].get("Name") == root_name)
    def node(i):
        p = {}
        for k, v in i["props"].items():
            if k in SPEC_SKIP or "Param" in k or "Surface" in k:
                continue
            p[k] = {"ref": v} if k in REF_PROPS else v
        return {"c": i["class"], "id": i["ref"], "p": p, "k": [node(c) for c in kids.get(i["ref"], [])]}
    return node(root)


if __name__ == "__main__":
    items, skipped = parse(sys.argv[1])
    if "--spec" in sys.argv:
        print(json.dumps(to_spec(items, sys.argv[sys.argv.index("--spec") + 1]), separators=(",", ":")))
    elif "--list" in sys.argv:  # one line per instance: path and class
        by = {i["ref"]: i for i in items}
        for i in items:
            n, q = [], i
            while q:
                n.append(q["props"].get("Name", "?")); q = by.get(q["parent"])
            print(i["class"], ".".join(reversed(n)))
    elif "--luau" in sys.argv:
        print(to_luau(items, sys.argv[sys.argv.index("--luau") + 1]))
    else:
        print(json.dumps({"skipped_types": skipped, "instances": items}, indent=1))
