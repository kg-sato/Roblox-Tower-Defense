"""R6 combat idle, snappy: 120-frame loop on the fighting stance (_lib.FIGHT_R6). Method by fwjelaa.

Two layers, both dividing the loop:
  breath (60 f, twice per loop): chest rises and falls, Torso bobs 0.1 studs, the guard dips with it
  weight shift (120 f, once per loop): a slow sideways roll + twist, so the stance never looks frozen
Overlap: the fists trail the Torso by 5-7 f, the head counters the Torso and trails by 8 f.
The legs are solved every key (_move.plant) so the soles never leave their spot on the floor; R6 has no
knees, so the bob itself is centred on the grounded stance (+0.04 / -0.06 studs).
"""
import animkit as ak
from _lib import FIGHT_R6, lean, root, twist
from _move import add, ebb, key_loop, plant, roll, soles, wave

NAME = "R6_Idle"
LOOP = 120
BREATH = 60
SWAY = 120
FEET = soles(FIGHT_R6)


def pose_at(f):
    b = ebb(f, BREATH)  # 0 = top of the inhale, 1 = fully settled (exhale)
    s = wave(f, SWAY)  # weight shift side to side
    c = wave(f, SWAY, 0.25)  # the same shift a quarter later: the twist leads the roll
    p = add(FIGHT_R6, {
        "Right Arm": (3 - 6 * b, 0, -1.5 * b),  # rear fist sinks as the chest settles
        "Left Arm": (3.5 - 7 * b, 0, 2 * b + 2 * s),  # lead fist breathes and drifts with the weight
        "Head": (-1.5 + 3.5 * b, 0, -1.5 * s),  # counter: chin lifts while the chest drops
    })
    p = lean(p, 1.5 - 3 * b)  # chest up on the inhale, hunch on the exhale
    p = roll(p, 1.4 * s)
    p = twist(p, 3 * c, head=0.7)
    return plant(root(p, py=0.05 - 0.1 * b), FEET)


def build():
    a = ak.Anim(NAME, rig="R6", length=LOOP, loop=True, priority="Idle")
    key_loop(a, pose_at, 10)
    a.offset("Left Arm", 5).offset("Right Arm", 7).offset("Head", 8)
    return a
