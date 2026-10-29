"""List .glb files with triangle counts and bounding boxes (needs trimesh; run with the Hunyuan3D venv python).
Usage: Hunyuan3D\\.venv\\Scripts\\python tools\\glb_stats.py "Roblox Dev/Assets/3D/Familiars" [--limit 20000]
Exit code 1 if any model is over the limit or fails to load."""
import pathlib, sys
import trimesh

folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
limit = 20000
if "--limit" in sys.argv:
    limit = int(sys.argv[sys.argv.index("--limit") + 1])
bad = 0
total = 0
print(f"{'file':28} {'triangles':>9} {'vertices':>9} {'size (x y z)':>26}  watertight")
for f in sorted(folder.glob("*.glb")):
    try:
        scene = trimesh.load(str(f), force="scene")
        geoms = [g for g in scene.geometry.values() if hasattr(g, "faces")]
        tris = sum(len(g.faces) for g in geoms)
        verts = sum(len(g.vertices) for g in geoms)
        ext = scene.extents
        wt = all(g.is_watertight for g in geoms)
        flag = "" if tris <= limit else "  OVER LIMIT"
        if tris > limit:
            bad += 1
        total += 1
        print(f"{f.name:28} {tris:9d} {verts:9d} {ext[0]:8.2f} {ext[1]:8.2f} {ext[2]:8.2f}  {wt}{flag}")
    except Exception as e:
        bad += 1
        print(f"{f.name:28} FAILED to load: {e}")
print(f"{total} models listed; limit {limit}; problems: {bad}")
sys.exit(1 if bad else 0)
