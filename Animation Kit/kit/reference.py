"""Reference clips -> frames, inside Blender (it reads mp4 / mov / webm / gif with its own FFmpeg).

Used by `python kit/run.py ref <clip> <Name>`; you don't call it directly.
"""
import json
import os

import bpy


def extract(video, out_dir, step=0, max_frames=24, width=480, start=0, end=None):
    """Write every `step`-th frame of the clip to out_dir/frame_<n>.png (n = the clip's own frame
    number, from 0) and out_dir/info.json. step=0 picks one so about max_frames come out."""
    scene = bpy.context.scene
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences  # Blender 5 renamed it
    strip = strips.new_movie("reference", video, 1, 1)
    fps = float(strip.fps) or 30.0
    total = int(strip.frame_final_duration)
    el = strip.elements[0]
    src_w, src_h = el.orig_width, el.orig_height
    end = total - 1 if end is None else min(end, total - 1)
    if step <= 0:
        step = max(1, round((end - start + 1) / max_frames))
    # render at the clip's own size, scaled down as a whole (a smaller canvas would crop the strip)
    scene.render.resolution_x, scene.render.resolution_y = src_w, src_h
    scene.render.resolution_percentage = max(1, min(100, round(100 * width / src_w)))
    scene.render.use_sequencer = True
    scene.render.image_settings.file_format = "PNG"
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    os.makedirs(out_dir, exist_ok=True)
    for old in os.listdir(out_dir):
        if old.startswith("frame_") and old.endswith(".png"):
            os.remove(os.path.join(out_dir, old))
    frames = list(range(start, end + 1, step))
    if frames[-1] != end:
        frames.append(end)
    for n in frames:
        scene.frame_set(n + 1)  # the strip starts on scene frame 1
        scene.render.filepath = os.path.join(out_dir, f"frame_{n:04d}.png")
        bpy.ops.render.render(write_still=True)
    info = {"source": os.path.basename(video), "fps": fps, "frames": total, "step": step,
            "size": [src_w, src_h], "extracted": frames}
    with open(os.path.join(out_dir, "info.json"), "w", encoding="utf-8") as f:
        json.dump(info, f, indent=1)
    return info
