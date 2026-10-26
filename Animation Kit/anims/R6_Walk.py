"""R6 walk, snappy: 44-frame cycle (22 per step), arms opposite the legs. Method by fwjelaa.

Per step: contact (0) -> down (~5) -> passing (11) -> up (~16) -> next contact (22); the left step is
the right one half a cycle later. Every key is grounded (ak.ground), so with R6's rigid legs the body
is lowest at contact (legs split +-30) and highest as they pass.

Feet that don't skate: an in-place walk is a treadmill, so the planted foot must slide back at ONE
steady speed from heel-strike to toe-off. The legs are driven by their sole position (sin of the swing
angle): linear while planted, and the swing is a Hermite curve that leaves and lands with that same
speed. Arms swing as pendulums 3 f behind the legs; the Torso twists with the arms, rolls over the
stance leg (that lifts the swing foot clear) and dips on the down.
Speed: 2 studs per 22 f = 5.45 studs/s; scale with track:AdjustSpeed(WalkSpeed / 5.45).
"""
import math

import animkit as ak
from _lib import lean, twist
from _move import arms_world, roll

NAME = "R6_Walk"
STEP = 22
CYCLE = 2 * STEP
SPLIT = 30  # leg swing at contact, degrees
ARMS = 28  # arm swing amplitude, degrees
ARM_LAG = 3  # frames the arms trail the legs
LEAN = -4  # slight forward lean: purposeful, not slouched


def leg_swing(t):
    """Right leg swing angle (deg, + = forward) at frame t: planted 0-22, swinging 22-44."""
    s0 = math.sin(math.radians(SPLIT))
    t %= CYCLE
    if t <= STEP:  # planted: the sole slides back at a constant speed
        s = s0 - 2 * s0 * t / STEP
    else:  # swing: leave and land at the planted speed, fastest as the legs pass
        u = (t - STEP) / STEP
        m = -2 * s0
        s = ((2 * u ** 3 - 3 * u ** 2 + 1) * -s0 + (u ** 3 - 2 * u ** 2 + u) * m
             + (-2 * u ** 3 + 3 * u ** 2) * s0 + (u ** 3 - u ** 2) * m)
    return math.degrees(math.asin(s))


def pose_at(t):
    w = 2 * math.pi / CYCLE
    arm = -ARMS * math.cos(w * (t - ARM_LAG))  # right arm: back when the right leg is forward
    dip = math.cos(2 * w * (t - 5))  # 1 on the "down" of each step
    p = {
        "Torso": (0, 0, 0, 0, 0, 0),
        "Head": (1 - LEAN * 0.6 + 1.2 * math.cos(2 * w * (t - 8)), 0, 0),  # eyes level, bob lags the dip
        "Right Leg": (leg_swing(t), 0, 1), "Left Leg": (leg_swing(t + STEP), 0, -1),
        "Right Arm": (arm, 0, 5 + 1.5 * math.sin(w * t)), "Left Arm": (-arm, 0, -5 + 1.5 * math.sin(w * t)),
    }
    p = twist(p, 4.5 * math.cos(w * (t - ARM_LAG)) * -1, head=0.7)  # shoulders follow the arms
    p = roll(p, -3.2 * math.sin(w * t))  # over the stance leg: the swing hip rises
    x = LEAN - 1.2 * dip
    p = arms_world(lean(p, x), x)
    return ak.ground(p)


def build():
    a = ak.Anim(NAME, rig="R6", length=CYCLE, loop=True, priority="Movement")
    for f in range(0, CYCLE, 2):
        a.key(f, pose_at(f), ease="bezier")
    return a
