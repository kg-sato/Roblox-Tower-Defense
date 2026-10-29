import pathlib, trimesh, json
d = pathlib.Path("Roblox Dev/Assets/3D/Familiars/clean")
rows = []
bad = 0
for g in sorted(d.glob("*.glb")):
    sc = trimesh.load(str(g), force="scene")
    geoms = [x for x in sc.geometry.values() if hasattr(x, "faces")]
    tris = sum(len(x.faces) for x in geoms)
    b = sc.bounds  # glTF is Y up
    h = b[1][1] - b[0][1]
    cx, cz = (b[0][0] + b[1][0]) / 2, (b[0][2] + b[1][2]) / 2
    ok = tris <= 20000 and abs(h - 4.0) < 0.02 and abs(b[0][1]) < 0.02 and abs(cx) < 0.02 and abs(cz) < 0.02
    if not ok: bad += 1
    fbx = (d / (g.stem + ".fbx")).exists()
    print(f"{g.name:22} tris {tris:6d}  height {h:5.2f}  min_y {b[0][1]:6.3f}  centre x {cx:6.3f} z {cz:6.3f}  fbx {fbx}  {'ok' if ok else 'CHECK'}")
print("models:", len(list(d.glob('*.glb'))), "problems:", bad)
