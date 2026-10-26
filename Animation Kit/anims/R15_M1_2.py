"""R15 M1 hit 2, snappy: left straight (the lead-hand jab) from the fighting stance. Method by fwjelaa.

Same timeline as hit 1 (anims/R15_M1_1.py), 24 frames:
  stance -> wind-up f4 (hips open a little to the left, weight back, lead fist cocks by the cheek)
  -> strike f6, Hit marker "2": hips and chest close to the right, lunge over the lead knee, the lead
     shoulder rolls up to the chin, the lead elbow snaps straight on the line from the shoulder to the
     target's chin, the rear fist stays by our own chin, the rear heel peels up
  -> overshoot f8 (shoulder keeps rolling in, arm locks out) -> settle f11 -> recover to stance f24.
"""
from mathutils import Vector

from _m1r15 import clip, line_punch, toe
from _r15 import fighter

NAME = "R15_M1_2"
TARGET = Vector((-0.85, 1.0, -3.2))  # the opponent's chin, left of centre so the fist clears our head from behind
ELBOW = (-0.8, -0.6, 0.3)  # the lead elbow points down and out, never up
CHIN = ((0.45, 0.9, -0.95), (0.5, -1, 0.3))  # rear fist beside the jaw (chest axes), elbow tucked down


def poses():
    stance = fighter()
    windup = fighter(
        hips=(-2, -22, 0), move=(0, -0.38, 0.1), chest=(-11, 10, -2), head=(6, 16, 0),
        lead_fist=((-0.72, 0.9, -1.05), (-0.5, -1, 0.3)),  # pulled back to the cheek, loaded
        rear_fist=((0.6, 0.9, -0.95), (0.5, -1, 0.3)),
    )
    contact = fighter(
        hips=(-6, -48, 0), move=(0, -0.42, -0.3), chest=(-15, -4, -6), head=(4, 46, 4),
        rear_foot=toe("Right", -54, -16), rear_fist=CHIN,
    )
    line_punch(contact, "Left", TARGET, 1.565, ELBOW)  # elbow ~9 deg: the arm arrives straight
    over = fighter(
        hips=(-7, -52, 0), move=(0, -0.43, -0.35), chest=(-16, -6, -7), head=(3, 50, 5),
        rear_foot=toe("Right", -55, -19), rear_fist=CHIN,
    )
    line_punch(over, "Left", TARGET, 1.62, ELBOW)
    settle = fighter(
        hips=(-6, -49, 0), move=(0, -0.42, -0.31), chest=(-15, -4, -6), head=(4, 47, 4),
        rear_foot=toe("Right", -54, -16), rear_fist=CHIN,
    )
    line_punch(settle, "Left", TARGET, 1.54, ELBOW, drop=0.04)  # starting to retract
    back = fighter(  # halfway home: body opening back up, fist coming straight back to the guard
        hips=(-5, -38, 0), move=(0, -0.38, -0.12), chest=(-13, 0, -3), head=(7, 34, 2),
        rear_foot=toe("Right", -52, -6),
        lead_fist=((-0.78, 0.88, -1.5), (-0.4, -1, 0.15)),
        rear_fist=((0.65, 0.85, -1.0), (0.45, -1, 0.2)),
    )
    return {"stance": stance, "windup": windup, "contact": contact, "over": over, "settle": settle, "back": back}


def build():
    p = poses()
    return clip(NAME, [
        (0, p["stance"], "quad_out"),  # decelerate into the wind-up
        (4, p["windup"], "cubic_in"),  # accelerate: the biggest jump is the last frame
        (6, p["contact"], "linear"),
        (8, p["over"], "cubic_out"),
        (11, p["settle"], "bezier"),  # snap the fist back, then ease into the stance
        (17, p["back"], "bezier"),
        (24, p["stance"], "linear"),
    ], hit=6, value="2")
