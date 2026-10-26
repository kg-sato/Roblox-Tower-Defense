"""R15 helpers for the example animations (method by fwjelaa).

R15 has knees and elbows, so instead of dropping the root like R6 we place the hands and feet and
let two-bone IK find the shoulder/hip and elbow/knee angles:

    pose = {"LowerTorso": (0, -25, 0, 0, -0.25, 0), "UpperTorso": (-8, -5, 0)}
    plant(pose, "Left", x=-0.7, z=-0.65, yaw=-20)        # foot flat on the floor at (x, z)
    reach(pose, "Right", (0.55, 0.75, -1.1), elbow=(0.3, -1, 0.3))   # wrist goes there

Positions are studs in character space: origin at the HumanoidRootPart centre, X right, Y up,
Z back (the character faces -Z), floor at y = -3. Bends: knee = negative x on the LowerLeg (shin
goes back), elbow = positive x on the LowerArm (forearm comes forward).
"""
import math

from mathutils import Matrix, Vector

import animkit as ak
import checks
import rigs

RIG = rigs.RIGS["R15"]
FLOOR = -RIG["hip_height"]
_JOINT = {p1: (p0, c0, c1) for _, p0, p1, c0, c1 in RIG["joints"]}
_FOOT = RIG["parts"]["RightFoot"]


def angles_of(m):
    """Rotation matrix -> (x, y, z) degrees with m = Rx(x) Ry(y) Rz(z), i.e. CFrame.Angles order."""
    m = m.to_3x3()
    y = math.asin(max(-1.0, min(1.0, m[0][2])))
    x = math.atan2(-m[1][2], m[2][2])
    z = math.atan2(-m[0][1], m[0][0])
    return tuple(round(math.degrees(a), 4) for a in (x, y, z))


def rot(x=0.0, y=0.0, z=0.0):
    return rigs.angles(x, y, z).to_3x3()


def fk(pose):
    """Part frames (centre CFrames relative to the HumanoidRootPart) for a pose."""
    return checks.forward_kinematics(RIG, ak.pose_transforms(pose, RIG))


def _pivot(frames, part):
    p0, c0, _ = _JOINT[part]
    return frames[p0] @ c0


def _bone(part, child):
    """Vector from `part`'s joint to `child`'s joint, in `part`'s axes."""
    return _JOINT[child][1].to_translation() - _JOINT[part][2].to_translation()


def _two_bone(pose, upper, lower, end, target, hint, bend, min_bend=0.0, max_bend=150.0):
    """Solve upper (ball joint) + lower (hinge on its x axis) so `end`'s joint lands on `target`.
    bend = +1 (elbow: forearm forward) or -1 (knee: shin back). `hint` (world) is where the
    middle joint should stick out relative to the line from the upper joint to the target."""
    frames = fk(pose)
    piv = _pivot(frames, upper)
    rp = piv.to_3x3()
    d = rp.inverted() @ (Vector(target) - piv.to_translation())
    b1, b2 = _bone(upper, lower), _bone(lower, end)
    l2 = b2.length
    c = (d.length ** 2 - b1.length ** 2 - l2 ** 2) / (-2 * b1.y * l2)
    e = math.degrees(math.acos(max(-1.0, min(1.0, c))))
    e = max(min_bend, min(max_bend, e))
    er = math.radians(e * bend)
    w = b1 + Vector((0, -l2 * math.cos(er), -l2 * math.sin(er)))

    def basis(axis, side_hint, fallback):
        a = axis.normalized()
        p = side_hint - a * side_hint.dot(a)
        if p.length < 1e-6:
            p = fallback - a * fallback.dot(a)
        p.normalize()
        return Matrix((a, p, a.cross(p))).transposed()  # columns a, p, a x p

    # The elbow/knee tip is the part's own +Z (elbow, points back) or -Z (knee, points forward):
    # turn the limb about the joint-target line until that tip faces the hint.
    tip = Vector((0, 0, bend))
    local = basis(w, tip, b1)
    world = basis(d, rp.inverted() @ Vector(hint), tip)
    pose[upper] = angles_of(world @ local.transposed())
    pose[lower] = (e * bend, 0.0, 0.0)
    return pose


def orient(pose, part, x=0.0, y=0.0, z=0.0):
    """Key `part` so it ends up at world rotation Ry(y) Rx(x) Rz(z), whatever its parents do
    (feet flat on the floor, a fist that stays level)."""
    frames = fk(pose)
    rp = _pivot(frames, part).to_3x3()
    pose[part] = angles_of(rp.inverted() @ rot(0, y, 0) @ rot(x, 0, 0) @ rot(0, 0, z))
    return pose


def foot_offset(pitch=0.0, yaw=0.0, anchor="flat"):
    """Ankle position relative to the floor point the foot rests on, for a foot at that pitch/yaw.
    anchor: "flat" (lowest corner touches, ankle above the given x, z), "toe" (the front edge stays
    at x, z: heel lifts), "heel" (the back edge stays: toes lift)."""
    f = rot(0, yaw, 0) @ rot(pitch, 0, 0)
    c1 = _JOINT["RightFoot"][2].to_translation()  # foot centre sits -c1 below the ankle
    hx, hy, hz = (s / 2 for s in _FOOT)
    corners = [f @ (Vector((sx * hx, sy * hy, sz * hz)) - c1) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    if anchor == "flat":
        return Vector((0, -min(c.y for c in corners), 0))
    edge = -1 if anchor == "toe" else 1
    p = f @ (Vector((0, -hy, edge * hz)) - c1)
    low = min(c.y for c in corners)
    return Vector((-p.x, -low, -p.z))


def leg_length(knee):
    """Hip-to-ankle distance with the knee bent `knee` degrees (either sign)."""
    b1, b2 = _bone("RightUpperLeg", "RightLowerLeg"), _bone("RightLowerLeg", "RightFoot")
    return math.sqrt(b1.length ** 2 + b2.length ** 2 + 2 * b1.length * b2.length * math.cos(math.radians(knee)))


def root_height_for(pose, side, knee, x, z, yaw=0.0, pitch=0.0, lift=0.0, anchor="flat"):
    """The LowerTorso py that gives this foot placement exactly that knee bend (the rest of the
    LowerTorso pose is kept). Lets a gait be designed by its knee curve."""
    probe = dict(pose)
    v = list(ak._pad(probe["LowerTorso"]))
    v[4] = 0.0
    probe["LowerTorso"] = tuple(v)
    hip = _pivot(fk(probe), f"{side}UpperLeg").to_translation()
    ankle = Vector((x, FLOOR + lift, z)) + foot_offset(pitch, yaw, anchor)
    flat = math.hypot(hip.x - ankle.x, hip.z - ankle.z)
    return ankle.y + math.sqrt(max(0.0, leg_length(knee) ** 2 - flat ** 2)) - hip.y


def plant(pose, side, x, z, yaw=0.0, pitch=0.0, lift=0.0, anchor="flat", knee=None):
    """IK one leg so its foot rests at (x, z) on the floor (+lift), turned `yaw` (+ = toes to the
    character's left) and pitched `pitch` (+ = toes up). The knee points along `knee` (world),
    default forward and a little out over the toes."""
    s = 1 if side == "Right" else -1
    ankle = Vector((x, FLOOR + lift, z)) + foot_offset(pitch, yaw, anchor)
    if knee is None:
        knee = rot(0, yaw, 0) @ Vector((0.25 * s, 0, -1))
    _two_bone(pose, f"{side}UpperLeg", f"{side}LowerLeg", f"{side}Foot", ankle, knee, -1, min_bend=2.0)
    return orient(pose, f"{side}Foot", pitch, yaw)


def reach(pose, side, at, elbow=None, hand=None, min_bend=4.0):
    """IK one arm so its wrist lands on `at`. `elbow` (world) is where the elbow points, default
    down and out. `hand` = (x, y, z) wrist angles relative to the forearm (default straight)."""
    s = 1 if side == "Right" else -1
    elbow = elbow or (0.6 * s, -1, 0.3)
    _two_bone(pose, f"{side}UpperArm", f"{side}LowerArm", f"{side}Hand", at, elbow, 1, min_bend=min_bend)
    pose[f"{side}Hand"] = tuple(hand) if hand else (0.0, 0.0, 0.0)
    return pose


def joint_pos(pose, part):
    """World position of the joint that drives `part` (e.g. "RightHand" = the wrist)."""
    return _pivot(fk(pose), part).to_translation()


def part_pos(pose, part):
    return fk(pose)[part].to_translation()


def root(pose, x=0.0, y=0.0, z=0.0, px=0.0, py=0.0, pz=0.0):
    """Add rotation (degrees) and movement (studs) to the LowerTorso."""
    out = dict(pose)
    v = list(ak._pad(out.get("LowerTorso", (0, 0, 0))))
    for i, d in enumerate((x, y, z, px, py, pz)):
        v[i] += d
    out["LowerTorso"] = tuple(v)
    return out


def guard(pose, side, at, elbow, hand=None, min_bend=4.0):
    """reach() with the wrist target and elbow direction given in UpperTorso axes (studs from its
    centre), so a guard hand rides along with the chest."""
    f = fk(pose)["UpperTorso"]
    return reach(pose, side, f @ Vector(at), elbow=f.to_3x3() @ Vector(elbow), hand=hand, min_bend=min_bend)


# Orthodox fighting stance (left foot and fist lead), bladed to the right, knees bent, fists up.
# Feet and fists are placed, IK does the rest, so every variation keeps the feet planted.
STANCE = {
    "hips": (-4, -32, 0),  # LowerTorso rotation
    "move": (0, -0.34, 0),  # LowerTorso px, py, pz: the crouch comes from the knees
    "chest": (-12, 4, 0),  # UpperTorso, relative to the hips
    "head": (8, 24, 0),  # eyes back on the target
    "lead_foot": {"x": -0.6, "z": -0.85, "yaw": -18},
    "rear_foot": {"x": 0.85, "z": 0.65, "yaw": -50},
    "lead_fist": ((-0.8, 0.85, -1.35), (-0.35, -1, 0.1)),  # wrist and elbow-tip direction, chest axes
    "rear_fist": ((0.8, 0.8, -1.1), (0.35, -1, 0.1)),
    "lead_hand": (0, 0, 0),
    "rear_hand": (0, 0, 0),
}


def fighter(base=None, **over):
    """Pose from stance parameters (STANCE, overridden by keyword). Lead side = Left."""
    p = dict(base or STANCE)
    p.update(over)
    hx, hy, hz = p["hips"]
    pose = {"LowerTorso": (hx, hy, hz, *p["move"]), "UpperTorso": tuple(p["chest"]), "Head": tuple(p["head"])}
    plant(pose, "Left", **p["lead_foot"])
    plant(pose, "Right", **p["rear_foot"])
    guard(pose, "Left", *p["lead_fist"], hand=p["lead_hand"])
    guard(pose, "Right", *p["rear_fist"], hand=p["rear_hand"])
    return pose


def periodic(points, period):
    """Smooth loop through (frame, values) points (cubic Hermite, any spacing). Returns f(t) -> tuple."""
    pts = sorted((t % period, tuple(v)) for t, v in points)
    n = len(pts)

    def at(i):  # point i with wrap-around, its time shifted by whole periods
        k, j = divmod(i, n)
        return pts[j][0] + k * period, pts[j][1]

    def tangent(i):
        (t0, v0), (t1, v1) = at(i - 1), at(i + 1)
        return [(b - a) / (t1 - t0) for a, b in zip(v0, v1)]

    def f(t):
        t %= period
        i = max(k for k in range(-1, n) if at(k)[0] <= t)
        (ta, va), (tb, vb) = at(i), at(i + 1)
        ma, mb, h = tangent(i), tangent(i + 1), tb - ta
        u = (t - ta) / h
        h00, h10, h01, h11 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u, -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
        return tuple(h00 * a + h10 * h * c + h01 * b + h11 * h * d for a, b, c, d in zip(va, vb, ma, mb))
    return f


def lowest_foot(pose):
    """Lowest foot corner above the floor (studs; negative = sunk)."""
    frames = fk(pose)
    return min(c.y for foot in RIG["feet"] for c in checks._corners(frames[foot], RIG["parts"][foot])) - FLOOR
