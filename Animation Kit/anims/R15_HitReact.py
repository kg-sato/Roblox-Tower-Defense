"""R15 hit reaction (victim of an M1), snappy: 24 frames, priority Action4. Method by fwjelaa.

No anticipation: a reaction is caused, not chosen. Played with track:Play(0) (no fade) on the victim.
  0  fight stance (R15_Idle / R15_M1_1's fighter())
  2  PAIN (Impact marker): head snapped back and knocked to its right, chest arched back from the
     hips, hips shoved 0.3 studs back, knees give; the guard is broken and the arms fly open
  5  follow-through: head, chest and the loose arms keep travelling
  13 settle: dazed, guard low, hips still pushed back                <- 11-frame settle
  24 fight stance again (chains into the next reaction or the idle)
Both feet stay on the stance's spots the whole time (IK on every frame, anims/_react15.py): the knees
absorb the shove. The arms run on their own keys one frame behind the body (they are thrown by it).
On a hit-stop the game freezes this track at the Impact marker (track:AdjustSpeed(0)), which holds the
victim on the pain pose like fighting games do.
"""
from _react15 import K, STANCE_ARMS, STANCE_K, arms, limb, timeline

NAME = "R15_HitReact"
IMPACT = 2

PAIN = K(hips=(10, -38, -3), move=(0, -0.44, 0.30), chest=(18, -10, 4), head=(30, 2, -12))
THROUGH = K(hips=(12, -40, -4), move=(0, -0.50, 0.36), chest=(24, -12, 5), head=(36, -2, -14))
DAZED = K(hips=(2, -35, -2), move=(0, -0.43, 0.20), chest=(-3, -6, 5), head=(10, 16, -10))

# Arms, wrists and elbow-tip directions in chest axes (shoulders at x = +-1, y = 0.56). The guard is
# knocked open, the loose arms keep swinging out and up to shoulder height, drop, and come back up low.
FLUNG = arms(((-2.05, -0.2, -0.35), (-0.2, -0.3, 1)), ((2.05, -0.25, -0.15), (0.2, -0.3, 1)),
             (25, 0, 0), (25, 0, 0))
TRAIL = arms(((-2.25, 0.35, 0.35), (-0.2, -0.5, 1)), ((2.25, 0.3, 0.45), (0.2, -0.5, 1)),
             (35, 0, 0), (35, 0, 0))
FALL = arms(limb("lead", (-0.2, -0.85, -0.5), 1.4, (-0.4, -0.1, 1)), limb("rear", (0.3, -0.9, -0.3), 1.45, (0.4, -0.1, 1)),
            (15, 0, 0), (15, 0, 0))
LOW = arms(((-0.8, 0.0, -1.35), (-0.4, -1, 0.2)), ((0.95, -0.1, -1.3), (0.4, -1, 0.2)))


def build():
    body = [
        (0, STANCE_K, "linear"),  # the snap: straight in, no ease, no anticipation
        (IMPACT, PAIN, "cubic_out"),
        (5, THROUGH, "cubic_inout"),
        (13, DAZED, "cubic_inout"),
        (24, STANCE_K, "linear"),
    ]
    arm_keys = [
        (0, STANCE_ARMS, "linear"),
        (IMPACT + 1, FLUNG, "cubic_out"),
        (6, TRAIL, "sine_inout"),
        (11, FALL, "sine_inout"),
        (16, LOW, "cubic_inout"),
        (24, STANCE_ARMS, "linear"),
    ]
    a = timeline(NAME, body, arm_keys, priority="Action4", style="snappy")
    return a.marker(IMPACT, "Impact")
