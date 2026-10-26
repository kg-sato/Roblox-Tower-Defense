"""R6 land, snappy: one-shot, 14 frames, picks up from the fall and ends on the upright idle. Method by fwjelaa.

  touch (0): feet reach down, arms still up from the fall
  --cubic_in--> impact (3): legs split and the body drops (R6 has no knees), chest folds forward
  --linear--> squash (5): 2 more frames of give, a little deeper (the overshoot)
  --> absorb (8): still low, a beat of give before the rise
  --> rise (10, 12): the front leg plants under the body; the Torso rolls so the back foot lifts and steps in
  --> upright (14): ak.IDLE_R6, grounded.
The arms trail the body: they are still falling at the impact and bottom out at frame 6, wide for balance.
A "Land" marker sits on the impact frame for dust / camera shake. Play it with a short fade (~0.05 s)
or the cross-fade from the fall eats the impact.
"""
import animkit as ak
from _move import NEUTRAL_R6, compose

NAME = "R6_Land"
LENGTH = 14
IMPACT = 3
ARMS = ("Right Arm", "Left Arm")

# frame: (lean, tilt, head pitch, right leg, left leg) -- legs as (x, z) world swing
BODY = {
    0: (0, 0, -8, (30, 10), (-24, -10)),
    IMPACT: (-16, 0, 7, (42, 15), (-40, -15)),
    5: (-19, 0, 10, (45, 16), (-43, -16)),
    8: (-14, -1, 8, (41, 14), (-41, -15)),  # still low: a beat of absorb before the rise
    10: (-8, -2, 5, (16, 7), (-28, -9)),  # front leg back under the body; the roll lifts the back foot
    12: (-2, -1.5, 2, (4, 3), (-10, -4)),  # the back foot steps in
}
# R6 box feet tilted 5-25 deg dip a corner, so ground() would push the body ABOVE standing height
# just before it settles; let that corner sit a hair into the floor instead (invisible, no pop up).
LIFT = {10: -0.06, 12: -0.05}
# frame: (right arm, left arm) as world (x, z): they fall a beat after the body
ARMS_WORLD = {
    0: ((148, 14), (134, -16)),
    4: ((64, 22), (76, -22)),
    6: ((18, 26), (30, -24)),
    11: ((4, 10), (8, -10)),
}
EASE = {0: "cubic_in", IMPACT: "linear", 5: "bezier", 8: "bezier", 10: "bezier", 12: "bezier"}


def lean_at(f):
    """The Torso lean on any frame (linear between body keys), to hang the arms off it."""
    keys = sorted(BODY)
    for a, b in zip(keys, keys[1:]):
        if a <= f <= b:
            return BODY[a][0] + (BODY[b][0] - BODY[a][0]) * (f - a) / (b - a)
    return BODY[keys[-1]][0]


def body(f):
    lean, tilt, hx, (rx, rz), (lx, lz) = BODY[f]
    return compose(lean_x=lean, tilt=tilt, head=(hx, 0, 0), legs=((rx, 0, rz), (lx, 0, lz)), hip_pivot=True,
                   lift=LIFT.get(f, 0.0))


def arms(f):
    (rx, rz), (lx, lz) = ARMS_WORLD[f]
    lean = lean_at(f)
    return {"Right Arm": (rx - lean, 0, rz), "Left Arm": (lx - lean, 0, lz)}


def build():
    a = ak.Anim(NAME, rig="R6", length=LENGTH, priority="Movement", slides=True)
    for f in BODY:
        a.key(f, {j: v for j, v in body(f).items() if j not in ARMS}, ease=EASE[f])
    for f in ARMS_WORLD:
        a.key(f, arms(f), ease="quad_in" if f == 0 else "bezier")
    a.full(LENGTH, NEUTRAL_R6, ease="linear")
    a.marker(IMPACT, "Land")
    a.offset("Head", 2)
    return a
