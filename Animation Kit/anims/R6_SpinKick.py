"""R6 spinning hook kick, snappy (Garou's 4th M1 / Tatsumaki / Whirlwind Step feel): one-shot, 44 frames,
fighting stance to fighting stance. Method by fwjelaa.

  stance (0) --> coil (7-9): the body winds the OTHER way (+45 deg to the left), sinks and starts moving its
      weight over the lead (left) foot; the rear fist wraps across the chest, the lead arm swings back
  --> spin (9-19): a full turn to the right on the planted left foot. The rear (right) leg peels off the floor,
      opens out sideways and sweeps round at hip height; the torso tilts away from it for balance, the lead arm
      flings out behind as a counterweight while the rear fist stays tucked. The head spots like a dancer: it
      holds the target while it can, then whips round ahead of the body and finds it again before the heel.
  --> CONTACT (19): the leg points straight at the target (torso -270 deg): Hit
  --> carry through (19-26): the spin brakes, the leg drops and lands back on its own stance spot (-378 deg is
      the stance's -18 after one full turn) --> absorb (27-32) --> stance (44).

The 360: Roblox blends two keys the short way round, so any key-to-key turn over 180 deg spins BACKWARDS.
Rule of thumb: key a spin at least every 90-120 deg. Here the turn is written as a speed per frame
(_moves2.spin) and every frame is keyed (<= 45 deg apart), so the spin always goes the right way.

The planted left foot pivots in place: the hips orbit it (_moves2.pivot_xz) instead of the Torso spinning on its
own centre, every key is planted, and lock_feet holds it on every in-between. The right foot is locked while it
is down (0-9 and 26-44) and free in between.

Markers: Hit (19) on contact (hit-stop 8-12 f, it's a finisher), TrailOn (11) / TrailOff (23) for a leg trail.
"""
import animkit as ak
from _lib import FIGHT_R6
from _moves2 import pivot_xz, planted, spin, track

NAME = "R6_SpinKick"
LENGTH = 44
HIT = 19
LIFT, LAND = 10, 26  # the right foot is in the air from LIFT to LAND - 1

# Torso yaw, as a turn per frame (+ = to the left). Coil 45 to the left, then 405 to the right: fastest into
# the contact (frames into a Hit may smear), braking hard after it.
YAW = spin(-18, [10, 10, 8, 7, 5, 3, 1, 1, 0,  # 1-9: coil to +27
                 -4, -10, -18, -26, -32, -37, -39, -42, -44, -45,  # 10-19: spin, -270 on the Hit
                 -36, -28, -20, -12, -7, -4, -1])  # 20-26: carry through to -378 (= the stance's -18)

# Everything else as {frame: value}; between keys a smooth monotone curve (_moves2.track).
TILT = {0: 0, 7: 5, 10: 4, 14: 14, 17: 24, 19: 27, 21: 24, 24: 10, 27: 0, LENGTH: 0}  # + = away from the kick
LEAN = {0: -6, 7: -14, 10: -8, 15: -3, 19: 0, 22: -3, 27: -12, 32: -10, LENGTH: -6}
PIVOT = {0: 0, 7: 0.3, 9: 0.4, 12: 1, 21: 1, 26: 0.25, 31: 0, LENGTH: 0}  # share of the hips moved over the left foot

# the kicking leg while it is in the air (relative to the Torso); frames 9 and 26 are filled in with the
# planted leg so lift-off and touch-down join up
RIGHT_LEG = {12: (-22, 10, 30), 15: (-10, 4, 62), 17: (-4, 0, 76), 19: (0, 0, 80), 21: (4, 0, 74),
             23: (2, 6, 46), 25: (-6, 14, 18)}

RIGHT_ARM = {0: (62, 0, -14), 7: (84, 0, -48), 10: (74, 0, -30), 13: (60, 0, 2), 16: (64, 0, -16),
             19: (70, 0, -28), 22: (62, 0, -24), 26: (54, 0, -4), 33: (66, 0, -18), LENGTH: (62, 0, -14)}
LEFT_ARM = {0: (78, 0, 10), 7: (38, 0, -34), 10: (56, 0, -20), 13: (60, 0, -44), 16: (20, 0, -62),
            19: (-10, 0, -64), 22: (10, 0, -56), 26: (62, 0, -16), 33: (82, 0, 14), LENGTH: (78, 0, 10)}

# head yaw relative to the Torso: holds the target (14), whips round (15-19), finds it again (20)
HEAD_YAW = {0: 10.8, 7: -20, 9: -24, 12: 6, 13: 30, 14: 58, 15: 34, 16: -2, 17: -38, 18: -62, 19: -72,
            20: -54, 21: -30, 22: -10, 24: 6, 27: 12, LENGTH: 10.8}
HEAD_PITCH = {0: 4, 7: 8, 19: 0, 27: 6, LENGTH: 4}


def build():
    feet = ak.soles(FIGHT_R6)
    a = ak.Anim(NAME, rig="R6", length=LENGTH, priority="Action")
    left = FIGHT_R6["Left Leg"]
    right_leg = dict(RIGHT_LEG)
    poses = {}
    for f in list(range(0, LIFT)) + list(range(LAND, LENGTH + 1)) + list(range(LIFT, LAND)):
        lean, yaw, tilt = track(LEAN, f), track(YAW, f), track(TILT, f)
        rot = (lean, yaw, tilt)
        px, pz = pivot_xz(rot, feet["Left Leg"])
        w = track(PIVOT, f)
        down = f < LIFT or f >= LAND
        if not down and LIFT - 1 not in right_leg:  # join the air path to the planted legs
            right_leg[LIFT - 1] = poses[LIFT - 1]["Right Leg"]
            right_leg[LAND] = poses[LAND]["Right Leg"]
        pose = {
            "Torso": (lean, yaw, tilt, px * w, 0.0, pz * w),
            "Head": (track(HEAD_PITCH, f), track(HEAD_YAW, f), 0),
            "Right Arm": track(RIGHT_ARM, f),
            "Left Arm": track(LEFT_ARM, f),
            "Left Leg": (left[0], left[1], left[2] - tilt),
            "Right Leg": FIGHT_R6["Right Leg"] if down else track(right_leg, f),
        }
        poses[f] = planted(pose, feet, legs=("Right Leg", "Left Leg") if down else ("Left Leg",))
    for f in sorted(poses):
        a.key(f, poses[f], ease="linear")
    a.marker(HIT, "Hit").marker(11, "TrailOn").marker(23, "TrailOff")
    a.lock_feet(0, LENGTH, legs=("Left Leg",), targets=feet)  # the pivot foot never moves
    a.lock_feet(0, LIFT - 1, legs=("Right Leg",), targets=feet)
    a.lock_feet(LAND, LENGTH, legs=("Right Leg",), targets=feet)
    return a
