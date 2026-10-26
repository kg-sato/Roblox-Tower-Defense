"""R6 straight punch rebuilt from a reference clip (ref/PunchRef: an R15 punch, front three-quarter view).

Made the way the pack's reference flow works (CLAUDE.md, "When the user sends a reference"):
  python kit/run.py ref <clip> PunchRef --every 1      timing sheet: ref/sheet_PunchRef.png
  python kit/run.py compare R6_PunchFromRef --ref PunchRef --view three_quarter
Notes taken from the sheet (clip frames = animation frames, 60 fps):
  f0-3   guard: low, knees bent, both fists up by the chin, lead side forward
  f4-5   wind-up: the rear fist draws back a touch as the hips start to turn
  f6     contact: rear arm fully out at shoulder height, torso unwound ~40 deg, a short lunge
  f6-13  the punch stays out (a moving hold), the lead fist guards the chin
  f13-24 recovery back into the guard
R6 can't bend the knees, so the low guard becomes a wider leg split (ak.ground drops the torso to match).
"""
import animkit as ak
from _lib import root, twist

NAME = "R6_PunchFromRef"

GUARD = root(twist({
    "Torso": (-12, 0, 0, 0, 0, 0),
    "Head": (10, 0, 0),
    "Right Arm": (92, 0, -22),  # rear fist up by the chin
    "Left Arm": (96, 0, 16),  # lead fist up and forward
    "Right Leg": (-28, 0, 16),  # round 2: a wider split = the reference's low, bent-knee guard
    "Left Leg": (32, 0, -14),
}, -20), py=0)


def build():
    guard = ak.ground(GUARD)
    feet = ak.soles(guard)
    windup = ak.plant(root(twist(dict(guard, **{"Right Arm": (70, 0, -10), "Left Arm": (96, 0, 18)}), -8),
                           pz=0.06), feet)
    contact = ak.plant(root(twist(dict(guard, **{
        # round 3: pitch the body into the punch, but R6's knee-less legs can't keep both feet planted
        # under a big pitch on top of a big twist (they flail), so -18 with a 34 deg turn is the limit
        "Torso": (-18, 0, 0, *ak._pad(guard["Torso"])[3:]),
        "Right Arm": (104, -18, -2),  # straight out at shoulder height despite the pitch
        "Left Arm": (98, 0, 26),  # lead fist tucked to the chin
        "Head": (12, 0, 0)}), 34), pz=-0.34), feet)

    a = ak.Anim(NAME, rig="R6", length=24, priority="Action", style="snappy")
    a.full(0, guard, ease="linear")
    a.full(3, ak.plant(ak.drift(guard, 1), feet), ease="quad_out")
    a.full(5, windup, ease="cubic_in")  # accelerate into the hit
    a.full(6, contact, ease="linear").marker(6, "Hit")
    a.full(8, ak.plant(ak.blend(windup, contact, 1.08), feet), ease="cubic_out")  # carry through
    a.full(13, ak.plant(ak.drift(contact, 2), feet), ease="cubic_out")  # the punch stays out, settling
    a.full(24, guard, ease="linear")
    a.lock_feet(0, 24, targets=feet)
    return a
