"""R6 fall, snappy: 48-frame loop, arms raised, limbs drifting. Method by fwjelaa.

Built on _move.AIR (the shared airborne silhouette), so R6_Jump cross-fades into it and R6_Land picks
up from it. Every limb drifts on its own phase so nothing moves in lockstep:
  arms flutter +-9 deg twice per loop (24 f) in opposition, and sway out/in +-4 once per loop (48 f);
  legs pedal +-7 deg against each other (48 f); the chest rocks +-2, the head trails it.
Airborne: no ground(); the body rides 0.3 studs up on the HumanoidRootPart so the feet hang clear.
"""
import math

import animkit as ak
from _move import AIR, compose, key_loop

NAME = "R6_Fall"
LOOP = 48


def pose_at(t):
    w = 2 * math.pi / LOOP
    (rax, ray, raz), (lax, lay, laz) = AIR["arms"]
    (rlx, rly, rlz), (llx, lly, llz) = AIR["legs"]
    hx, hy, hz = AIR["head"]
    flutter = 9 * math.sin(2 * w * t)
    pedal = 7 * math.sin(w * t + 1.0)
    return compose(
        lean_x=AIR["lean_x"] + 2 * math.sin(w * t),
        tilt=2 * math.sin(w * t + 0.5),
        head=(hx - 3 * math.sin(w * t - 0.9), hy, hz + 2 * math.sin(w * t - 0.4)),
        arms=((rax + flutter, ray, raz + 4 * math.sin(w * t)),
              (lax - flutter, lay, laz + 4 * math.sin(w * t + 0.6))),
        legs=((rlx + pedal, rly, rlz + 2 * math.sin(w * t)), (llx - pedal, lly, llz + 2 * math.sin(w * t))),
        ground=False, py=AIR["py"],
    )


def build():
    a = ak.Anim(NAME, rig="R6", length=LOOP, loop=True, priority="Movement")
    return key_loop(a, pose_at, 4)
