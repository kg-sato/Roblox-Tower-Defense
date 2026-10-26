"""R6 run, snappy: 28-frame cycle (14 per step), straight-arm pump, forward lean.

contact -> down (lowest) -> passing (legs cross) -> up (flight, highest) -> next contact.
R6 has no knees, so the Torso drops while the legs are split (ak.leg_drop) and rises when they cross.
"""
import animkit as ak
from _lib import lean

NAME = "R6_Run"
LEAN = -16  # degrees, forward
STEP = 14  # frames per step


def step_poses(side):
    """The 4 key poses of one step, `side` = the leg that lands at the start."""
    s = 1 if side == "Right" else -1  # +1: right leg forward
    # Arms hang off the leaning Torso, so they are keyed |LEAN| further forward to swing evenly
    # around the vertical: world swing = arm x + LEAN.
    fwd = -LEAN

    def arms(r, l):
        return {"Right Arm": (r + fwd, 0, 8), "Left Arm": (l + fwd, 0, -8)}

    contact = {
        "Torso": (0, -6 * s, 0, 0, -ak.leg_drop(48), 0),
        "Head": (12, 4 * s, 0),
        "Right Leg": (48 * s, 6 * s, 2), "Left Leg": (-48 * s, 6 * s, -2),
        **arms(-52 * s, 58 * s),
    }
    down = {  # weight absorbed: the lowest point
        "Torso": (0, -4 * s, 0, 0, -ak.leg_drop(40) - 0.05, 0),
        "Head": (14, 3 * s, 0),
        "Right Leg": (40 * s, 4 * s, 2), "Left Leg": (-40 * s, 4 * s, -2),  # no knees: both legs split
        **arms(-44 * s, 48 * s),
    }
    passing = {
        "Torso": (0, 0, 0, 0, 0.06, 0),
        "Head": (11, 0, 0),
        "Right Leg": (-4 * s, 0, 2), "Left Leg": (10 * s, 0, -2),
        **arms(4 * s, -4 * s),
    }
    up = {  # flight: highest point, legs scissoring for the next contact
        "Torso": (0, 3 * s, 0, 0, 0.16, 0),
        "Head": (10, -2 * s, 0),
        "Right Leg": (-34 * s, -3 * s, 2), "Left Leg": (40 * s, -3 * s, -2),
        **arms(46 * s, -40 * s),
    }
    return [lean(p, LEAN) for p in (contact, down, passing, up)]


def build():
    a = ak.Anim(NAME, rig="R6", length=2 * STEP, loop=True, priority="Movement")
    for i, side in enumerate(("Right", "Left")):
        start = i * STEP
        for pose, f in zip(step_poses(side), (0, 3, 7, 10)):
            a.key(start + f, pose, ease="bezier")
    a.offset("Right Arm", 1).offset("Left Arm", 1).offset("Head", 2)
    return a
