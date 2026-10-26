"""R15 run, snappy: 28-frame cycle (14 per step), bent-knee stride, pumping bent arms. Method by fwjelaa.

Per step: contact (heel strike) -> down (lowest, knee absorbs ~60 deg) -> passing (swing knee folds
~118 deg under the hip) -> toe-off -> flight (body highest) -> next contact.

How it stays clean:
  - The planted foot is solved by IK on every stance frame and slides back at ONE constant ground
    speed (heel strike, roll flat, peel off the toe), so there is no skating or sinking.
  - The root height is a designed curve (0.29 studs peak to peak), the stance knee takes it.
  - The swing leg, arms, chest and head are classic FK key poses in WORLD angles (+ = forward of
    vertical), converted to the joints' own axes here so the lean never tilts the stride.
  - Hips turn with the forward leg, the chest counter-twists them, arms trail the legs by 1 frame,
    the head by 2 and keeps the eyes level.
"""
import animkit as ak
from _r15 import orient, periodic, plant, root_height_for

NAME = "R15_Run"
STEP = 14  # frames per step
CYCLE = 2 * STEP
HIP_PITCH = -11  # LowerTorso forward tilt
CHEST_PITCH = -9  # UpperTorso on top: -20 total lean
SPEED = 0.19  # studs per frame the ground slides under the stance foot (11.4 studs/s)
CONTACT_Z = -0.76  # where the heel lands, ahead of the hips
TOE_OFF = 9  # last stance frame of a step
TRACK_X = 0.42  # feet land a little inside the hips

# Hips through one step, right foot landing at 0: (frame, (turn, roll)). The left step mirrors it.
TURN = [(0, (10, 1)), (3, (7, 3)), (7, (0, 2)), (9, (-3, 1)), (11.5, (-7, 0))]
_TURN = periodic(TURN + [(f + STEP, (-yaw, -roll)) for f, (yaw, roll) in TURN], 2 * STEP)
# Stance knee bend per frame after heel strike: absorb to 50 at the down pose, extend to toe-off.
# The root height is solved from it, so the body sinks and rises exactly as the knee does.
KNEE = [15, 27, 37, 44, 43, 38, 31, 24, 18, 13]

# Swing leg (the right one, in the frames after it leaves the ground): thigh, knee, foot pitch.
SWING = [(14, (-30, -72, -38)), (17, (-12, -108, -28)), (21, (36, -118, -18)), (24, (58, -86, -4))]

# Upper body per key frame of the right step: (frame, right arm (upper, elbow, twist), left arm, head x)
ARMS = [
    (0, (-56, 72, -6), (46, 106, 22), 15),
    (3, (-46, 76, -4), (38, 102, 20), 16),
    (7, (2, 90, 6), (-6, 86, 4), 15),
    (10, (38, 102, 20), (-46, 76, -4), 14),
]


def foot_plan(k):
    """Stance foot (x, z, pitch, anchor) of the right foot k frames after its heel strike: the
    ground point slides back at constant speed; heel strike rolls flat, then the heel peels off."""
    g = CONTACT_Z + SPEED * k  # ankle's ground point
    if k <= 2:
        u = k / 2
        return TRACK_X, g + 0.5, 14 * (1 - u * u * (3 - 2 * u)), "heel"
    if k <= 5:
        return TRACK_X, g, 0.0, "flat"
    u = (k - 5) / (TOE_OFF - 5)
    return TRACK_X, g - 0.5, -40 * u * u, "toe"  # the toe push speeds up into take-off


def _heights():
    """Root py for every frame of one step: solved from KNEE in stance, a parabola in flight."""
    py = []
    for k in range(TOE_OFF + 1):
        yaw, roll = _TURN(k)
        x, z, pitch, anchor = foot_plan(k)
        pose = {"LowerTorso": (HIP_PITCH, yaw, roll, 0, 0, 0)}
        py.append(root_height_for(pose, "Right", KNEE[k], x, z, pitch=pitch, anchor=anchor))
    p9, slope, n = py[-1], py[-1] - py[-2], STEP - TOE_OFF  # take-off speed carries into the arc
    c = (py[0] - p9 - slope * n) / n ** 2
    py += [p9 + slope * i + c * i * i for i in range(1, n)]
    return py


PY = _heights()


def root_at(t):
    """LowerTorso at any frame of the cycle."""
    yaw, roll = _TURN(t)
    return (HIP_PITCH, yaw, roll, 0, PY[t % STEP], 0)


def stance_foot(pose, side, k):
    """Plant the stance foot k frames after its heel strike."""
    s = 1 if side == "Right" else -1
    x, z, pitch, anchor = foot_plan(k)
    plant(pose, side, x=x * s, z=z, pitch=pitch, anchor=anchor, knee=(0.15 * s, 0, -1))


def swing_leg(pose, side, thigh, knee, pitch):
    s = 1 if side == "Right" else -1
    yaw = pose["LowerTorso"][1]
    pose[f"{side}UpperLeg"] = (thigh - HIP_PITCH, -0.7 * yaw, 2 * s)  # swing straight ahead
    pose[f"{side}LowerLeg"] = (knee, 0, 0)
    orient(pose, f"{side}Foot", pitch, 0)


def arm(pose, side, upper, elbow, twist):
    s = 1 if side == "Right" else -1
    pose[f"{side}UpperArm"] = (upper - HIP_PITCH - CHEST_PITCH, twist * s, 11 * s)  # elbows a bit wide
    pose[f"{side}LowerArm"] = (elbow, 0, 0)
    pose[f"{side}Hand"] = (-12, 0, 0)


def leg_joints(side):
    return [f"{side}UpperLeg", f"{side}LowerLeg", f"{side}Foot"]


def build():
    a = ak.Anim(NAME, rig="R15", length=CYCLE, loop=True, priority="Movement")
    for t in range(CYCLE):
        a.key(t, {"LowerTorso": root_at(t)}, ease="linear")  # every frame: the IK below relies on it
    for side, start in (("Right", 0), ("Left", STEP)):
        for k in range(TOE_OFF + 1):  # stance: IK every frame
            t = start + k
            pose = {"LowerTorso": root_at(t)}
            stance_foot(pose, side, k)
            a.key(t, {j: pose[j] for j in leg_joints(side)}, ease="bezier")
        for f, (thigh, knee, pitch) in SWING:  # swing: FK key poses
            t = (start + f) % CYCLE
            pose = {"LowerTorso": root_at(t)}
            swing_leg(pose, side, thigh, knee, pitch)
            a.key(t, {j: pose[j] for j in leg_joints(side)}, ease="bezier")
    for f, ra, la, head_x in ARMS:
        _, yaw, roll, *_ = root_at(f)
        upper = {"UpperTorso": (CHEST_PITCH, -2.2 * yaw, -roll), "Head": (head_x, 1.1 * yaw, 0)}
        arm(upper, "Right", *ra)
        arm(upper, "Left", *la)
        a.key(f, upper, ease="bezier")
        a.key(f + STEP, ak.mirror(upper), ease="bezier")
    for part in ("UpperArm", "LowerArm", "Hand"):
        a.offset(f"Right{part}", 1).offset(f"Left{part}", 1)
    a.offset("Head", 2)
    return a
