"""R6 fist block, snappy: a 90-frame guard loop (method by fwjelaa).

Frame 0 is already the guard, so the clip can loop for as long as the player holds block:
    track.Looped = true (the kit sets Loop) ; track:Play(0.07)   -- 4-frame fade = the 3-5 f block-in
    track:Stop(0.1)                                               -- back to the stance on release
The 0.07 s fade does the "enter in 3-5 f" from the fight stance (a loop can't contain a one-time entry).

Guard: torso hunched forward and squared up a little, crouched on a wider stance, both straight arms raised
and crossed in front of the face (rear/right fist higher, lead/left fist lower and further out, so the
forearms overlap like an X from the front and frame the head from behind), head down behind them.
Hold: one 90 f breath (sink + tighten on the exhale), arms lag the torso 4 f and the head 6 f, so the
guard is never frozen but stays rock solid (about 1-2 degrees of drift).
"""
import animkit as ak
from _lib import lean, twist

NAME = "R6_Block"
LENGTH = 90


def guard(breath=0.0):
    """The guard; breath 0..1 = inhale..exhale (torso sinks a touch, arms squeeze in and up)."""
    b = breath
    p = {
        "Torso": (0, 0, 0, 0, 0, 0),
        "Head": (6 - 1 * b, 0, 0),  # level on a hunched torso = chin down in the world
        "Right Arm": (136 + 1.5 * b, 0, -44 - 1.5 * b),  # rear fist high, across to the left brow
        "Left Arm": (126 + 2 * b, 0, 50 + 1.5 * b),  # lead fist lower and further out, across the chin
        "Right Leg": (-16 - 1.5 * b, 0, 12),
        "Left Leg": (22 + 1.5 * b, 0, -10),  # legs widen on the exhale: R6 sinks with no knees
    }
    return ak.ground(twist(lean(p, -12 - 1.5 * b), -8))


def build():
    a = ak.Anim(NAME, rig="R6", length=LENGTH, loop=True, priority="Action")
    a.key(0, guard(0.0), ease="bezier")
    a.key(LENGTH // 2, guard(1.0), ease="bezier")
    a.offset("Right Arm", 4).offset("Left Arm", 4).offset("Head", 6)
    a.marker(0, "GuardUp")  # fires as the guard is up (and again each loop): open the block window here
    return a
