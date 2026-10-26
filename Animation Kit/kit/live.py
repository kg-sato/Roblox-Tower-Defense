"""Entry point for Claude driving the user's live Blender through the Blender MCP.

    import sys; sys.path.insert(0, r"<pack>\\kit"); import live
    print(live.make("R6_Run"))           # build anims/R6_Run.py in the scene, export, check
    print(live.sheet("R6_Run"))          # contact sheet PNG to Read (headless-friendly)
    print(live.video("R6_Run"))          # MP4 for the video edit

Everything is reloaded on each call, so edits to the kit or to anims/*.py take effect at once.
"""
import importlib
import os
import sys

KIT = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.dirname(KIT)
ANIMS = os.path.join(PACK, "anims")
OUT = os.path.join(PACK, "out")
if KIT not in sys.path:
    sys.path.insert(0, KIT)


def _reload():
    import rigs, animkit, checks, export, preview  # noqa: E401
    for m in (rigs, animkit, checks, export, preview):
        importlib.reload(m)
    return animkit, export, preview


def clear_scene():
    """Remove only what the kit made (rigs, their collections, camera, floor); leave the rest alone."""
    import bpy
    for o in list(bpy.data.objects):
        if o.get("rbx_rig") or o.get("rbx_part") or o.get("rbx_deco") or o.name in ("AnimCam", "AnimFloor"):
            bpy.data.objects.remove(o)
    for c in list(bpy.data.collections):
        if not c.objects and not c.children:
            bpy.data.collections.remove(c)


def make(name, location=(0.0, 0.0, 0.0), keep_others=False):
    """Build anims/<name>.py, export it to out/, run the checks. Returns the report text."""
    animkit, export, _ = _reload()
    if not keep_others:
        clear_scene()
    path = os.path.join(ANIMS, f"{name}.py")
    anim = animkit.load(path)
    import bpy
    arm = bpy.data.objects[anim.name]
    arm.location.x, arm.location.y = location[0], location[1]
    report = export.export(arm, OUT)
    _save_blend(name)
    return report


def _save_blend(name):
    import bpy
    os.makedirs(os.path.join(OUT, "blend"), exist_ok=True)
    try:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "blend", f"{name}.blend"), copy=True)
    except RuntimeError as e:
        print("could not save .blend:", e)


def sheet(name, view="three_quarter", n=8, frames=None):
    """Contact sheet of n evenly spaced frames (or the given ones) -> out/sheet_<name>_<view>.png."""
    _, _, preview = _reload()
    import bpy
    arm = bpy.data.objects[name]
    frames = frames or preview.evenly(bpy.context.scene.frame_end, n)
    path = os.path.join(OUT, f"sheet_{name}_{preview.safe(view)}.png")
    preview.sheet(arm, frames, path, view)
    return f"{path}\nframes, left to right then top to bottom: {frames}"


def video(name, view="three_quarter"):
    _, _, preview = _reload()
    import bpy
    os.makedirs(os.path.join(OUT, "video"), exist_ok=True)
    return preview.video(bpy.data.objects[name], os.path.join(OUT, "video", f"{name}_{preview.safe(view)}.mp4"), view)


def compare_frames(name, frames, view="three_quarter", size=(480, 480)):
    """Render the given animation frames (for kit/run.py compare), in the reference's shape.
    Returns {frame: png path}."""
    _, _, preview = _reload()
    import bpy
    arm = bpy.data.objects[name]
    out = os.path.join(OUT, "_compare")
    distance = 13 if size[1] >= size[0] else 15  # wide shots need a little more room above and below
    paths = preview.frames(arm, frames, out, view, prefix=name, resolution=tuple(size), distance=distance)
    return dict(zip(frames, paths))


def reel(names, view="three_quarter", gap=8, title=None):
    """Several animations back to back on one rig, as one MP4 (e.g. the whole M1 combo) -> out/video/."""
    animkit, _, preview = _reload()
    clear_scene()
    anims = [animkit.load(os.path.join(ANIMS, f"{n}.py"), build=False) for n in names]
    title = title or "Reel_" + "_".join(names)[:60]
    arm = animkit.chain(title, anims, gap).build()
    os.makedirs(os.path.join(OUT, "video"), exist_ok=True)
    return preview.video(arm, os.path.join(OUT, "video", f"{title}_{view}.mp4"), view)
