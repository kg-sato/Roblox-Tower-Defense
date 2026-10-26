"""Automatic quality checks on an exported animation, frame by frame, in Roblox space.

They catch what is easy to miss from one camera: limbs passing through the body, feet sinking into
the floor, one-frame pops, a seam where a loop wraps, attacks without a hit marker.
"""
import math
from itertools import product

from mathutils import Matrix, Vector

import rigs

SINK_STUDS = 0.15  # feet may dip this far below the floor before it counts
OVERLAP_STUDS = 0.2  # how deep one part may sink into another
POP_DEG_PER_FRAME = 40  # at 60 fps; faster than this reads as a glitch unless it is a smear
SEAM_DEG = 0.5
SKATE_CONTACT = 0.05  # a foot this close to the floor counts as planted
SKATE_STUDS = 0.3  # how far a planted foot may slide before it reads as skating


def forward_kinematics(rig, transforms):
    """Part CFrames (relative to the root) from Motor6D transforms: P1 = P0 * C0 * T * C1^-1."""
    frames = {rig["root"]: Matrix.Identity(4)}
    pending = list(rig["joints"])
    while pending:
        for j in list(pending):
            _, p0, p1, c0, c1 = j
            if p0 in frames:
                frames[p1] = frames[p0] @ c0 @ transforms.get(p1, Matrix.Identity(4)) @ c1.inverted()
                pending.remove(j)
    return frames


def _corners(frame, size):
    hx, hy, hz = (s / 2 for s in size)
    return [frame @ Vector((x, y, z)) for x, y, z in product((-hx, hx), (-hy, hy), (-hz, hz))]


def _samples_along(frame, size, n=5):
    """Points on the part's centre line and corners: enough to catch a limb inside the body."""
    hx, hy, hz = (s / 2 for s in size)
    pts = _corners(frame, size)
    for i in range(n):
        t = -1 + 2 * i / (n - 1)
        pts.append(frame @ Vector((0, t * hy * 0.9, 0)))
    return pts


def _angle(a, b):
    """Degrees between two joint rotations, the short way round (q and -q are the same rotation)."""
    ang = math.degrees(a.to_quaternion().rotation_difference(b.to_quaternion()).angle)
    return min(ang, 360 - ang)


def _depth_inside(point, frame, size):
    """How deep `point` is inside the box (0 if outside)."""
    local = frame.inverted() @ point
    d = min(s / 2 - abs(c) for c, s in zip(local, size))
    return max(0.0, d)


def _ranges(frames):
    """[1,2,3,7,8] -> '1-3, 7-8'."""
    out, start, prev = [], None, None
    for f in frames:
        if start is None:
            start = prev = f
        elif f == prev + 1:
            prev = f
        else:
            out.append(f"{start}-{prev}" if prev != start else f"{start}")
            start = prev = f
    if start is not None:
        out.append(f"{start}-{prev}" if prev != start else f"{start}")
    return ", ".join(out)


def run(arm, data, samples):
    rig = rigs.with_props(data["rig"], data["props"])
    sizes = rig["parts"]
    floor = -rig["hip_height"]
    issues = []
    fk = [forward_kinematics(rig, s) for s in samples]

    sink = {}
    for f, frames in enumerate(fk):
        low = min(c.y for foot in rig["feet"] for c in _corners(frames[foot], sizes[foot]))
        if low < floor - SINK_STUDS:
            sink[f] = floor - low
    if sink:
        root_joint = rig["joints"][0][2]
        issues.append(f"feet sink up to {max(sink.values()):.2f} studs into the floor on frames "
                      f"{_ranges(sorted(sink))}: lift the {root_joint} (py) or bend the legs less")

    # foot skating: a foot that stays on the floor should stay put (skipped for loops: walks and runs
    # slide their planted foot back on purpose, the character travels over it)
    if not data["loop"] and not data.get("slides"):
        for foot in rig["feet"]:
            span, slid = [], []
            for f, frames in enumerate(fk + [None]):
                down = frames is not None and min(
                    c.y for c in _corners(frames[foot], sizes[foot])) < floor + SKATE_CONTACT
                if down:
                    span.append(f)
                    continue
                if len(span) > 1:
                    sole = Vector((0, -sizes[foot][1] / 2, 0))  # the bottom of the foot, not its centre
                    p0 = fk[span[0]][foot] @ sole
                    moved = max(((fk[g][foot] @ sole - p0) * Vector((1, 0, 1))).length for g in span)
                    if moved > SKATE_STUDS:
                        slid.append(f"{moved:.2f} studs on frames {span[0]}-{span[-1]}")
                span = []
            if slid:
                issues.append(f"{foot} skates while planted: {'; '.join(slid)} (plant it, or lift it to step)")

    for a, b in rig["pairs"]:
        bad = {}
        for f, frames in enumerate(fk):
            depth = max(_depth_inside(p, frames[b], sizes[b]) for p in _samples_along(frames[a], sizes[a]))
            if depth > OVERLAP_STUDS:
                bad[f] = depth
        if bad:
            issues.append(f"{a} goes {max(bad.values()):.2f} studs into {b} on frames {_ranges(sorted(bad))}")

    fps = data["fps"]
    limit = POP_DEG_PER_FRAME * 60 / fps
    # the last frames into a Hit (attacker) or Impact (victim) marker may be smears: that's the point of them
    strike = {round(k["time"] * fps) - d for k in data["keyframes"] for m in k["markers"]
              if m[0] in ("Hit", "Impact") for d in range(0, 3)}
    # a pose held with `constant` snaps to the next one on purpose (the anime "on 2s" look): excuse that frame
    snaps = {}
    for joint in samples[0]:
        held = False
        for k in data["keyframes"]:
            pose = k["poses"].get(joint)
            if pose is None:
                continue
            if held:
                snaps.setdefault(joint, set()).add(round(k["time"] * fps))
            held = pose["style"] == "Constant"
    for joint in samples[0]:
        pops = []
        for f in range(1, len(samples)):
            if f in strike or f in snaps.get(joint, ()):
                continue
            if _angle(samples[f - 1][joint], samples[f][joint]) > limit:
                pops.append(f)
        if pops:
            issues.append(f"{joint} snaps more than {limit:.0f} deg in one frame at frames {_ranges(pops)} "
                          f"(fine for a deliberate smear, otherwise add an in-between)")

    if data["loop"]:
        for joint in samples[0]:
            if _angle(samples[0][joint], samples[-1][joint]) > SEAM_DEG:
                issues.append(f"loop seam: {joint} differs between the first and last frame")

    if (data["priority"].startswith("Action") and not data["loop"] and not data.get("slides")
            and not any(k["markers"] for k in data["keyframes"])):
        issues.append("attack without a marker: add a.marker(frame, 'Hit') on the impact frame")
    return issues
