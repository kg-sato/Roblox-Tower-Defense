"""R15 M1 hit 3, snappy: right hook from the fighting stance. Method by fwjelaa.

Same timeline as hits 1-2, 24 frames:
  stance -> wind-up f4 (hips and chest coil hard to the right, weight back, the rear arm swings out
     wide, bent ~90 deg)
  -> swing f5 (the bent arm comes round level, elbow leading) -> strike f6, Hit marker "3": hips and
     chest unwind ~85 deg, lunge, rear heel pivots up, the elbow stays locked at ~90 deg level with the
     shoulder and the fist sweeps flat across onto the target's jaw, lead fist tucked to the chin
  -> overshoot f8 (the body keeps turning, the fist carries on across) -> settle f11 -> stance f24.
The hook arm is a rigid "L" (upper arm + forearm at a fixed bend) turned about the vertical through
the shoulder, so the fist travels on a flat arc.
"""
import math

from mathutils import Vector

from _m1r15 import clip, toe
from _r15 import fighter, joint_pos, reach

NAME = "R15_M1_3"
UPPER = Vector((0.55, 0.22, -0.8)).normalized()  # contact: upper arm forward and out, elbow flared wide
FORE = Vector((-0.82, 0.05, -0.57)).normalized()  # contact: forearm level, across the front, square to UPPER


def _yaw(v, deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return Vector((v.x * c + v.z * s, v.y, -v.x * s + v.z * c))


def hook(pose, swing, rise=0.0):
    """The hook arm, its L turned `swing` degrees about the vertical (0 = contact, - = cocked back
    to the right, + = carried through to the left); `rise` lifts the fist (studs)."""
    up, fore = _yaw(UPPER, swing), _yaw(FORE, swing)
    at = joint_pos(pose, "RightUpperArm") + up * 0.88 + fore * 0.76 + Vector((0, rise, 0))
    return reach(pose, "Right", at, elbow=up, min_bend=20.0)


def poses():
    stance = fighter()
    windup = fighter(
        hips=(-3, -46, 0), move=(0, -0.4, 0.1), chest=(-10, -8, 4), head=(6, 50, 0),
        lead_fist=((-0.6, 0.9, -1.2), (-0.45, -1, 0.2)),
    )
    hook(windup, -85, rise=-0.1)  # cocked out wide to the right
    swing = fighter(
        hips=(-4, -16, 0), move=(0, -0.41, -0.08), chest=(-9, 14, 2), head=(5, 2, 0),
        rear_foot=toe("Right", -40, -8),
        lead_fist=((-0.55, 0.92, -1.1), (-0.45, -1, 0.2)),
    )
    hook(swing, -42)
    contact = fighter(
        hips=(-4, 10, 0), move=(0, -0.42, -0.24), chest=(-8, 22, 4), head=(3, -30, 0),
        rear_foot=toe("Right", -20, -22),
        lead_fist=((-0.5, 0.92, -1.0), (-0.45, -1, 0.2)),  # lead fist back to the chin
    )
    hook(contact, 0)
    over = fighter(
        hips=(-5, 13, 0), move=(0, -0.43, -0.28), chest=(-9, 26, 4), head=(2, -36, 0),
        rear_foot=toe("Right", -18, -24),
        lead_fist=((-0.5, 0.9, -0.98), (-0.45, -1, 0.2)),
    )
    hook(over, 18)
    settle = fighter(
        hips=(-4, 11, 0), move=(0, -0.42, -0.25), chest=(-8, 24, 4), head=(3, -33, 0),
        rear_foot=toe("Right", -19, -22),
        lead_fist=((-0.52, 0.9, -1.0), (-0.45, -1, 0.2)),
    )
    hook(settle, 12, rise=-0.06)
    back = fighter(  # halfway home: body coiling back, the elbow drops and the fist returns to the guard
        hips=(-5, -12, 0), move=(0, -0.38, -0.1), chest=(-12, 12, 1), head=(7, 2, 0),
        rear_foot=toe("Right", -36, -10),
        lead_fist=((-0.7, 0.88, -1.25), (-0.4, -1, 0.15)),
        rear_fist=((0.6, 0.95, -1.3), (0.45, -1, 0.2)),
    )
    return {"stance": stance, "windup": windup, "swing": swing, "contact": contact, "over": over,
            "settle": settle, "back": back}


def build():
    p = poses()
    return clip(NAME, [
        (0, p["stance"], "quad_out"),  # decelerate into the wind-up
        (4, p["windup"], "cubic_in"),  # accelerate: the biggest jump is the last frame
        (5, p["swing"], "linear"),
        (6, p["contact"], "linear"),
        (8, p["over"], "cubic_out"),
        (11, p["settle"], "bezier"),
        (17, p["back"], "bezier"),
        (24, p["stance"], "linear"),
    ], hit=6, value="3")
