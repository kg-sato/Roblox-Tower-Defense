"""List the ParticleEmitter layers inside Roblox .rbxl place files, with their numeric properties.
  python -I tools/rbxl_emitters.py <file.rbxl> [...] > out.json            (names and textures only)
  python -I tools/rbxl_emitters.py --full <file.rbxl> [...] > recipes.json (every layer with its numbers)
Read-only parser of the binary format (LZ4 / ZSTD chunks). Never opens Studio, never runs anything in the file.
Binary rules used (Roblox binary model format): Float32, Int32 and Enum columns are byte-interleaved big-endian
(all first bytes, then all second bytes ...); floats are rotated left one bit (sign bit stored last); NumberRange is
two little-endian floats per value; NumberSequence keypoints are (time, value, envelope) and ColorSequence keypoints
(time, r, g, b, envelope), little-endian, each list prefixed by a uint32 count; Vector2 is interleaved X column then Y."""
import json, struct, sys
from pathlib import Path


def lz4(src, size):
    out, i = bytearray(), 0
    while i < len(src):
        t = src[i]; i += 1
        lit = t >> 4
        if lit == 15:
            while True:
                b = src[i]; i += 1; lit += b
                if b != 255: break
        out += src[i:i + lit]; i += lit
        if i >= len(src): break
        off = struct.unpack_from("<H", src, i)[0]; i += 2
        ml = t & 15
        if ml == 15:
            while True:
                b = src[i]; i += 1; ml += b
                if b != 255: break
        ml += 4
        for _ in range(ml):
            out.append(out[-off])
    return bytes(out[:size])


def chunks(data):
    p = 32
    while p < len(data):
        name = data[p:p + 4].decode("ascii", "replace").strip("\0 ")
        cl, ul = struct.unpack_from("<II", data, p + 4)
        p += 16
        body = data[p:p + (cl or ul)]
        p += cl or ul
        if cl and body[:4].hex() == "28b52ffd":  # newer Roblox saves use ZSTD (Python 3.14 has it built in)
            from compression import zstd
            body = zstd.decompress(body)
            yield name, body
            if name == "END": return
            continue
        yield name, (lz4(body, ul) if cl else body)
        if name == "END": return


def deinterleave(b, n, width=4):
    """N values of `width` bytes stored column by column (byte 0 of every value first)."""
    return [bytes(b[k * n + i] for k in range(width)) for i in range(n)]


def floats(b, n):
    out = []
    for raw in deinterleave(b, n):
        u = int.from_bytes(raw, "big")
        u = ((u >> 1) | ((u & 1) << 31)) & 0xFFFFFFFF  # undo the one-bit rotation (sign bit moved to the end)
        out.append(round(struct.unpack("<f", struct.pack("<I", u))[0], 4))
    return out


def enums(b, n):
    return [int.from_bytes(raw, "big") for raw in deinterleave(b, n)]


def read_prop(ty, b, n):
    """Decode one PROP column of n values; returns None for types we do not need."""
    if ty == 0x01:
        q, vals = 0, []
        for _ in range(n):
            l, = struct.unpack_from("<I", b, q); q += 4
            vals.append(b[q:q + l].decode("utf-8", "replace")); q += l
        return vals
    if ty == 0x02:
        return [bool(x) for x in b[:n]]
    if ty == 0x04:
        return floats(b, n)
    if ty == 0x12:
        return enums(b, n)
    if ty == 0x17:  # NumberRange
        return [[round(v, 4) for v in struct.unpack_from("<ff", b, 8 * i)] for i in range(n)]
    if ty == 0x0D:  # Vector2: X column then Y column, each interleaved
        xs, ys = floats(b[:4 * n], n), floats(b[4 * n:8 * n], n)
        return [[x, y] for x, y in zip(xs, ys)]
    if ty in (0x15, 0x16):  # NumberSequence / ColorSequence
        q, vals, per = 0, [], 3 if ty == 0x15 else 5
        for _ in range(n):
            c, = struct.unpack_from("<I", b, q); q += 4
            kps = []
            for _ in range(c):
                kps.append([round(v, 4) for v in struct.unpack_from("<" + "f" * per, b, q)]); q += 4 * per
            vals.append(kps)
        return vals
    return None


FULL = ["Name", "Texture", "Size", "Transparency", "Color", "Lifetime", "Rate", "Speed", "Rotation", "RotSpeed", "Squash",
        "LightEmission", "LightInfluence", "FlipbookLayout", "FlipbookMode", "ZOffset", "SpreadAngle", "Drag", "TimeScale",
        "Orientation", "LockedToPart", "Brightness"]


def parse_full(path):
    data = Path(path).read_bytes()
    assert data[:8] == b"<roblox!", "not a binary rbxl"
    classes, props = {}, {}
    for name, b in chunks(data):
        if name == "INST":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); cn = b[8:8 + n].decode()
            cnt, = struct.unpack_from("<I", b, 8 + n + 1)
            classes[cid] = (cn, cnt)
        elif name == "PROP":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); pn = b[8:8 + n].decode()
            if classes.get(cid, ("",))[0] != "ParticleEmitter" or pn not in FULL:
                continue
            v = read_prop(b[8 + n], b[9 + n:], classes[cid][1])
            if v is not None:
                props[pn] = v
    count = len(props.get("Name", []))
    return [{k: props[k][i] for k in FULL if k in props} for i in range(count)]


def parse(path):
    data = Path(path).read_bytes()
    assert data[:8] == b"<roblox!", "not a binary rbxl"
    classes, props = {}, {}
    for name, b in chunks(data):
        if name == "INST":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); cn = b[8:8 + n].decode()
            cnt, = struct.unpack_from("<I", b, 8 + n + 1)
            classes[cid] = (cn, cnt)
        elif name == "PROP":
            cid, = struct.unpack_from("<I", b, 0)
            n, = struct.unpack_from("<I", b, 4); pn = b[8:8 + n].decode()
            ty = b[8 + n]
            if ty != 1 or classes.get(cid, ("",))[0] != "ParticleEmitter": continue
            q, vals = 8 + n + 1, []
            for _ in range(classes[cid][1]):
                l, = struct.unpack_from("<I", b, q); q += 4
                vals.append(b[q:q + l].decode("utf-8", "replace")); q += l
            props[pn] = vals
    return {"emitters": len(props.get("Name", [])), "layers": props.get("Name", []), "textures": props.get("Texture", [])}


if __name__ == "__main__":
    full = "--full" in sys.argv
    files = [f for f in sys.argv[1:] if f != "--full"]
    print(json.dumps({Path(f).name: (parse_full(f) if full else parse(f)) for f in files}, indent=1))
