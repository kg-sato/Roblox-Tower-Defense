"""Shared helpers for the R15 M1 combo, hits 2-4 (hit 1 is anims/R15_M1_1.py). Method by fwjelaa.

Every hit starts and ends on _r15.fighter() (the orthodox stance), is solved by IK from stance
parameters, and puts a "Hit" marker on its contact frame (valued "2", "3", "4").
"""
from mathutils import Vector

import animkit as ak
from _r15 import STANCE, fighter, fk, joint_pos, reach, root_height_for

_STANCE = fk(fighter())
# front-bottom edge of each stance foot: the ball of the foot a heel-up pivot turns on
TOE = {s: _STANCE[f"{s}Foot"] @ Vector((0, -0.15, -0.5)) for s in ("Right", "Left")}


def toe(side, yaw, pitch=0.0, lift=0.0):
    """Foot pivoting on its ball: the front edge stays where the stance put it (heel lifts when
    pitch < 0). With lift > 0 the foot leaves the floor straight above that spot (a hop).
    Keep the pivot within ~30 deg of yaw and ~35 deg of pitch, or the sole reads as skating."""
    return {"x": TOE[side].x, "z": TOE[side].z, "yaw": yaw, "pitch": pitch, "anchor": "toe", "lift": lift}


def on_legs(knees, **params):
    """fighter(**params) with the LowerTorso height chosen so the legs bend `knees` = (lead, rear)
    degrees (the straighter leg wins, so neither foot is left floating)."""
    probe = fighter(**params)
    feet = {"Left": params.get("lead_foot", STANCE["lead_foot"]),
            "Right": params.get("rear_foot", STANCE["rear_foot"])}
    py = min(root_height_for(probe, side, knee, **{k: v for k, v in feet[side].items() if k != "knee"})
             for side, knee in zip(("Left", "Right"), knees))
    mx, _, mz = params.get("move", STANCE["move"])
    return fighter(**dict(params, move=(mx, py, mz)))


def line_punch(pose, side, target, extend, elbow, drop=0.0, hand=(0, 0, 0), min_bend=3.0):
    """Drive the wrist `extend` studs from the shoulder along the line to `target` (a straight punch)."""
    shoulder = joint_pos(pose, f"{side}UpperArm")
    aim = (Vector(target) - shoulder).normalized()
    at = shoulder + aim * extend + Vector((0, -drop, 0))
    return reach(pose, side, at, elbow=elbow, hand=hand, min_bend=min_bend)


def clip(name, keys, hit, value):
    """keys: [(frame, pose, ease)], first and last on the stance. Hit marker on frame `hit`."""
    a = ak.Anim(name, rig="R15", priority="Action", style="snappy")
    for frame, pose, ease in keys:
        a.full(frame, pose, ease=ease)
    a.marker(hit, "Hit", value)
    a.length = keys[-1][0]
    a.hit_frame = hit
    return a
