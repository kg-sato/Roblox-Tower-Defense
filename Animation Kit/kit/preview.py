"""Render an animation for review or for a video: single frames, a contact sheet, or an MP4.

Workbench renders, so a full MP4 of a 2-second animation takes a few seconds.
"""
import math
import os

import bpy
from mathutils import Vector

VIEWS = {  # camera direction from the character (Blender axes: front is -Y), elevation in degrees
    "front": (0, -1, 0.12),
    "three_quarter": (-0.75, -1, 0.25),  # front, from the character's right side
    "side": (-1, 0, 0.1),  # the character's right side
    "back_three_quarter": (0.75, 1, 0.3),
    "back": (0, 1, 0.25),  # straight behind and a little above: the player's own camera
    "top": (0, -0.2, 1),
}


def safe(view):
    """A view name that is safe in a file name ("yaw:30" -> "yaw30")."""
    return str(view).replace(":", "").replace(".", "_")


def view_direction(view):
    """A named view, or "yaw:<deg>[:<pitch deg>]" to match a reference clip's camera: yaw 0 = straight in
    front, 90 = the character's right side, 180 = behind, -90 = its left side; pitch = degrees above."""
    if isinstance(view, str) and view.startswith("yaw:"):
        parts = [float(p) for p in view.split(":")[1:]]
        yaw, pitch = math.radians(parts[0]), math.radians(parts[1] if len(parts) > 1 else 8)
        # front is -Y in Blender, the character's right is -X
        return Vector((-math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    return Vector(VIEWS[view]).normalized()


def stage(arm, view="three_quarter", distance=15.0, lens=50, resolution=(1280, 720)):
    """Camera, floor and Workbench look. Re-running it just moves the camera."""
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_WORKBENCH"
    except TypeError:
        pass
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "MATERIAL"
    shading.show_shadows = True
    shading.shadow_intensity = 0.35
    shading.show_cavity = True
    shading.cavity_type = "WORLD"
    shading.background_type = "VIEWPORT"
    shading.background_color = (0.09, 0.1, 0.12)
    if scene.world is None:  # Workbench renders use the world colour as the background
        scene.world = bpy.data.worlds.new("AnimWorld")
    scene.world.color = (0.09, 0.1, 0.12)
    scene.display.render_aa = "16"
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"

    floor = bpy.data.objects.get("AnimFloor")
    if floor is None:
        mesh = bpy.data.meshes.new("AnimFloor")
        s = 30
        mesh.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
        floor = bpy.data.objects.new("AnimFloor", mesh)
        scene.collection.objects.link(floor)
        mat = bpy.data.materials.new("AnimFloor")
        mat.diffuse_color = (0.28, 0.3, 0.33, 1)
        mesh.materials.append(mat)
    floor.location = (arm.location.x, arm.location.y, 0)

    cam = bpy.data.objects.get("AnimCam")
    if cam is None:
        cam = bpy.data.objects.new("AnimCam", bpy.data.cameras.new("AnimCam"))
        scene.collection.objects.link(cam)
    cam.data.lens = lens
    target = Vector((arm.location.x, arm.location.y, 3.0))
    d = Vector(view_direction(view))
    cam.location = target + d * distance
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    return cam


def frames(arm, frame_list, out_dir, view="three_quarter", prefix=None, **kw):
    """Render the listed frames to PNGs. Returns their paths."""
    scene = bpy.context.scene
    stage(arm, view, **kw)
    prefix = prefix or arm.name
    os.makedirs(out_dir, exist_ok=True)
    keep = scene.frame_current
    paths = []
    for f in frame_list:
        scene.frame_set(f)
        scene.render.image_settings.file_format = "PNG"
        scene.render.filepath = os.path.join(out_dir, f"{prefix}_{safe(view)}_{f:04d}.png")
        bpy.ops.render.render(write_still=True)
        paths.append(scene.render.filepath)
    scene.frame_set(keep)
    return paths


def video(arm, path, view="three_quarter", **kw):
    """MP4 of the animation, for review or the YouTube edit."""
    scene = bpy.context.scene
    stage(arm, view, **kw)
    rs = scene.render
    try:
        rs.image_settings.media_type = "VIDEO"
    except (AttributeError, TypeError):
        pass
    rs.image_settings.file_format = "FFMPEG"
    rs.ffmpeg.format = "MPEG4"
    rs.ffmpeg.codec = "H264"
    rs.ffmpeg.constant_rate_factor = "HIGH"
    rs.filepath = path
    bpy.ops.render.render(animation=True)
    return path


def evenly(length, n=8):
    """n frames spread over 0..length, ends included."""
    return sorted({round(i * length / (n - 1)) for i in range(n)})


def sheet(arm, frame_list, path, view="three_quarter", cols=4, cell=(480, 360)):
    """Contact sheet: the listed frames, left to right, top to bottom, in one PNG."""
    import numpy as np
    tmp = os.path.join(os.path.dirname(path), "_frames")
    paths = frames(arm, frame_list, tmp, view, resolution=cell)
    w, h = cell
    rows = math.ceil(len(paths) / cols)
    canvas = None
    for i, p in enumerate(paths):
        img = bpy.data.images.load(p)
        px = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        px = px.reshape(h, w, 4)
        if canvas is None:  # empty cells get the background colour (the top-left pixel)
            canvas = np.empty((rows * h, cols * w, 4), dtype=np.float32)
            canvas[:] = px[h - 1, 0]
        r, c = divmod(i, cols)
        # Blender images start at the bottom row; the sheet's first row is the top one
        canvas[(rows - 1 - r) * h:(rows - r) * h, c * w:(c + 1) * w] = px
        bpy.data.images.remove(img)
        os.remove(p)
    out = bpy.data.images.new("sheet", cols * w, rows * h, alpha=False)
    out.pixels.foreach_set(canvas.ravel())
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    return path
