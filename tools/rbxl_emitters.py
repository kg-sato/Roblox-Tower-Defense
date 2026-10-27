"""List the ParticleEmitter layers inside Roblox .rbxl place files: layer names and texture ids (string properties only).
  python -I tools/rbxl_emitters.py <file.rbxl> [...] > out.json
Read-only parser of the binary format (LZ4 chunks). Never opens Studio, never runs anything in the file."""
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
    print(json.dumps({Path(f).name: parse(f) for f in sys.argv[1:]}, indent=1))
