"""R15 M1 hit 1, snappy: right straight (the rear-hand cross) from the fighting stance. Method by fwjelaa.

Same timeline as the R6 combo (anims/_m1.py), 24 frames:
  stance -> wind-up f4 (hips and chest coil right, rear fist cocks, weight back)
  -> strike f6, Hit marker: hips and chest unwind 60 deg, lunge 0.3 studs, rear heel pivots up, the
     elbow snaps straight on the line from the shoulder to the target's chin, lead fist to the chin
  -> overshoot f8 (body keeps turning, arm locks out) -> settle f11 -> recover to stance f24.
Every key is solved by IK from stance parameters (anims/_r15.py), so the lead foot never slides and
the rear foot turns on its toe.
"""
from mathutils import Vector

import animkit as ak
from _r15 import STANCE, fighter, fk, joint_pos, reach

NAME = "R15_M1_1"
TARGET = Vector((0.45, 1.0, -3.2))  # the opponent's chin; right of centre so the fist clears our head from behind

# The rear foot as a toe pivot: its front edge stays on the floor where the stance put it.
_rf = STANCE["rear_foot"]
_TOE = fk(fighter())["RightFoot"] @ Vector((0, -0.15, -0.5))  # front-bottom edge of the stance foot


def rear_foot(yaw, pitch):
    return {"x": _TOE.x, "z": _TOE.z, "yaw": yaw, "pitch": pitch, "anchor": "toe"}


def punch(pose, extend, drop=0.0):
    """Drive the right wrist `extend` studs from the shoulder along the line to TARGET."""
    shoulder = joint_pos(pose, "RightUpperArm")
    aim = (TARGET - shoulder).normalized()
    at = shoulder + aim * extend + Vector((0, -drop, 0))
    return reach(pose, "Right", at, elbow=(0.8, -0.6, 0.3), hand=(0, 0, 0), min_bend=3.0)


def poses():
    stance = fighter()
    windup = fighter(
        hips=(-2, -42, 0), move=(0, -0.4, 0.1), chest=(-13, -6, 2), head=(6, 40, 0),
        rear_foot=rear_foot(-50, 0),
        rear_fist=((1.15, 0.62, -0.72), (0.6, -1, 0.4)),  # rear fist cocked back by the ear
    )
    reach(windup, "Left", (0.15, 0.42, -2.0), elbow=(-0.6, -1, 0.2))  # lead hand reaches to measure
    contact = fighter(
        hips=(-6, 6, 0), move=(0, -0.41, -0.3), chest=(-16, 20, 0), head=(4, -24, 0),
        rear_foot=rear_foot(-18, -24),
        lead_fist=((-0.5, 0.92, -1.0), (-0.45, -1, 0.2)),  # lead fist back to the chin
    )
    punch(contact, 1.565)  # elbow ~9 deg: the arm arrives straight
    over = fighter(
        hips=(-7, 10, 0), move=(0, -0.42, -0.36), chest=(-17, 22, 0), head=(3, -29, 0),
        rear_foot=rear_foot(-14, -27),
        lead_fist=((-0.5, 0.9, -0.98), (-0.45, -1, 0.2)),
    )
    punch(over, 1.62)
    settle = fighter(
        hips=(-6, 7, 0), move=(0, -0.41, -0.31), chest=(-16, 20, 0), head=(4, -25, 0),
        rear_foot=rear_foot(-17, -24),
        lead_fist=((-0.52, 0.9, -1.0), (-0.45, -1, 0.2)),
    )
    punch(settle, 1.54, drop=0.04)  # elbow ~21 deg, starting to retract
    back = fighter(  # halfway home: body unwinding, fist coming straight back
        hips=(-5, -16, 0), move=(0, -0.37, -0.1), chest=(-13, 7, 0), head=(7, 12, 0),
        rear_foot=rear_foot(-40, -7),
        lead_fist=((-0.72, 0.86, -1.3), (-0.35, -1, 0.1)),
        rear_fist=((0.75, 1.0, -1.4), (0.35, -1, 0.1)),
    )
    return stance, windup, contact, over, settle, back


def build():
    stance, windup, contact, over, settle, back = poses()
    a = ak.Anim(NAME, rig="R15", priority="Action", style="snappy")
    a.full(0, stance, ease="quad_out")  # decelerate into the wind-up
    a.full(4, windup, ease="cubic_in")  # accelerate: the biggest jump is the last frame
    a.full(6, contact, ease="linear").marker(6, "Hit", "1")
    a.full(8, over, ease="cubic_out")
    a.full(11, settle, ease="bezier")  # snap the fist back, then ease into the stance
    a.full(17, back, ease="bezier")
    a.full(24, stance, ease="linear")
    a.length = 24
    return a  # no head offset: the head counter-turns to keep the eyes on the target
