"""R15 combat idle, snappy: 120-frame loop in the orthodox fighting stance. Method by fwjelaa.

Every key is solved from the stance (anims/_r15.py): the feet stay planted by IK while the body
bounces on bent knees, breathes and shifts its weight. Overlap without foot sliding:
  - bounce   60 f, 0.12 studs peak to peak (two per loop), knees take it
  - breath   60 f, chest x +-2.2 deg, 6 f behind the bounce
  - weight   120 f, hips slide 0.06 studs toward each foot with a little roll and turn
  - fists    ride the chest 5 f late (follow-through) and circle 0.04-0.06 studs
  - head     counters the chest 8 f late so the eyes stay on the target
"""
import math

from mathutils import Vector

import animkit as ak
from _r15 import STANCE, fighter, fk, reach

NAME = "R15_Idle"
LENGTH = 120
BOB = 60  # frames per bounce (divides LENGTH)
STEP = 10  # one key every STEP frames, smoothed with bezier
ARM_LAG = 5
HEAD_LAG = 8
TAU = 2 * math.pi


def body(t):
    """Stance parameters at frame t (fists not solved yet)."""
    bob = math.cos(TAU * t / BOB)  # +1 high, -1 low
    breath = math.cos(TAU * (t - 6) / BOB)  # chest opens just after the body rises
    shift = math.sin(TAU * t / LENGTH)  # +1 weight on the rear (right) foot
    hx, hy, hz = STANCE["hips"]
    mx, my, mz = STANCE["move"]
    cx, cy, cz = STANCE["chest"]
    return {
        "hips": (hx + 1.4 * bob, hy + 2.5 * shift, hz + 1.2 * shift),
        "move": (mx + 0.06 * shift, my + 0.06 * bob, mz + 0.025 * bob),
        "chest": (cx + 2.2 * breath, cy - 2.0 * shift, cz - 0.8 * shift),
    }


def fist_local(side, t):
    """Guard wrist target in chest axes: a small circle on top of the stance."""
    (x, y, z), elbow = STANCE["lead_fist" if side == "Left" else "rear_fist"]
    a = TAU * t / BOB + (0.0 if side == "Left" else 2.2)
    r = 1.0 if side == "Left" else 0.7
    return Vector((x + 0.04 * r * math.sin(a), y + 0.06 * r * math.cos(a), z + 0.04 * r * math.sin(TAU * t / LENGTH))), elbow


def pose_at(t):
    pose = fighter(**body(t))
    # fists follow the chest as it was ARM_LAG frames ago (overlap without sliding the feet)
    late = fk(fighter(**body(t - ARM_LAG)))["UpperTorso"]
    for side in ("Left", "Right"):
        at, elbow = fist_local(side, t - ARM_LAG)
        reach(pose, side, late @ at, elbow=late.to_3x3() @ Vector(elbow))
    # head counters the chest's breath and the hips' turn, a few frames late
    lag = body(t - HEAD_LAG)
    hx, hy, hz = STANCE["head"]
    dx = lag["chest"][0] - STANCE["chest"][0] + lag["hips"][0] - STANCE["hips"][0]
    dy = lag["chest"][1] - STANCE["chest"][1] + lag["hips"][1] - STANCE["hips"][1]
    pose["Head"] = (hx - 0.8 * dx, hy - 0.7 * dy, hz + 0.6 * math.sin(TAU * (t - HEAD_LAG) / LENGTH))
    return pose


def build():
    a = ak.Anim(NAME, rig="R15", length=LENGTH, loop=True, priority="Idle")
    for t in range(0, LENGTH, STEP):
        a.full(t, pose_at(t), ease="bezier")
    return a
