"""R6 one-handed sword set: shared stance, key poses and recipes (method by fwjelaa).

The sword is joint `Handle` under the Right Arm (R6 has no wrist, so the Handle IS the wrist).
Handle angles, in the arm's own axes:
    (0, 0, 0)        blade along the arm's front face (forward when the arm hangs)
    x = -90 + e      blade continues the arm line, tilted e degrees off it (toward the arm's front)
    +y / -y          wrist turns the blade toward the arm's inner / outer side (lead / trail in a swing)

Every clip starts and ends on STANCE, so they chain without pops. Contacts carry a "Hit" marker,
swings carry "TrailOn" / "TrailOff" for the trail VFX.
"""
import math

import animkit as ak
from mathutils import Matrix

from _lib import lean, root, twist

PROPS = ("Sword",)


def g(pose, lift=0.0):
    """Ground a key pose with the sword rig (lowest foot corner exactly on the floor)."""
    return ak.ground(pose, "R6", lift=lift, props=PROPS)


# Untwisted base of the stance; every key pose below is this base with joints swapped, then
# twisted (torso y, feet stay planted), leaned and grounded.
BASE = {
    "Torso": (-6, 0, 0, 0, 0, 0),
    "Head": (4, 0, 0),
    "Right Arm": (55, 0, 2),  # sword hand in front of the right hip
    "Left Arm": (30, 0, -22),  # free arm out for balance
    "Right Leg": (-14, 0, 8),  # right foot back
    "Left Leg": (18, 0, -6),  # left foot forward
    "Handle": (-6, 8, 0),  # blade forward and up (~40 deg) at the opponent's chest
}


def _raw(tw, joints=None, lean_x=0.0, pz=0.0):
    pose = dict(BASE)
    pose.update(joints or {})
    pose = twist(pose, tw)
    if lean_x:
        pose = lean(pose, lean_x)
    # Lean about the torso's OWN side axis (turn first, then bend), not the world's: with the
    # pose language's Rx*Ry order a twisted torso bent forward tilts its hip line, and the back foot
    # can no longer reach the floor. The legs are re-solved by plant() anyway.
    x, y, z, px, py, pz0 = ak._pad(pose["Torso"])
    m = Matrix.Rotation(math.radians(y), 3, "Y") @ Matrix.Rotation(math.radians(x), 3, "X")
    e = m.to_euler("ZYX")
    pose["Torso"] = (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z), px, py, pz0)
    if pz:
        pose = root(pose, pz=pz)
    return pose


# Ready stance: left foot forward, right side back, blade pointing forward and up.
STANCE = g(_raw(-16))
SOLES = ak.soles(STANCE)  # the two floor spots every sword clip keeps its feet on


def _foot_heights(pose):
    import checks
    import rigs
    r = rigs.with_props("R6", ())
    fk = checks.forward_kinematics(r, ak.pose_transforms(pose, r))
    return {leg: min(c.y for c in checks._corners(fk[leg], r["parts"][leg])) + r["hip_height"]
            for leg in r["feet"]}


def plant(pose):
    """Both feet on their stance spots and on the floor. The legs swing so the soles stay put
    (ak.plant), then the hips shift along the line between the feet (weight onto the front or back
    foot), and if that is not enough tilt sideways a little, until BOTH feet touch: R6 legs have no
    knees, so after a big twist one leg is otherwise too short and its foot hovers."""
    targets = SOLES
    (rx, _, rz), (lx, _, lz) = targets["Right Leg"], targets["Left Leg"]
    n = ((lx - rx) ** 2 + (lz - rz) ** 2) ** 0.5
    ux, uz = (lx - rx) / n, (lz - rz) / n  # back foot -> front foot

    def shifted(s):
        out = ak.plant(root(pose, px=ux * s, pz=uz * s), targets)
        h = _foot_heights(out)
        return out, h["Left Leg"] - h["Right Leg"]  # > 0: the front foot hovers

    def secant(f, gain, lo, hi):
        x0, (out, e0) = 0.0, f(0.0)
        best = (abs(e0), out, e0)
        x1 = max(lo, min(hi, gain * e0))
        for _ in range(6):
            if best[0] < 0.01 or x1 == x0:
                break
            out, e1 = f(x1)
            best = min(best, (abs(e1), out, e1), key=lambda b: b[0])
            if abs(e1 - e0) < 1e-6:
                break
            x0, x1, e0 = x1, max(lo, min(hi, x1 - e1 * (x1 - x0) / (e1 - e0))), e1
        return best[1], best[2]

    out, e = secant(shifted, 1.5, -0.5, 0.5)
    if abs(e) >= 0.01:  # what the weight shift can't fix, a small sideways hip tilt does
        base = out

        def rolled(deg):
            t = ak._pad(base["Torso"])
            res = ak.plant(dict(base, Torso=(t[0], t[1], t[2] + deg, *t[3:])), targets)
            h = _foot_heights(res)
            return res, h["Left Leg"] - h["Right Leg"]

        out, e = secant(rolled, -30.0, -10.0, 10.0)
    return out


def P(tw, joints=None, lean_x=0.0, pz=0.0):
    """Key pose: BASE with `joints` swapped in, torso turned `tw` (+ = left), leaned, shifted `pz`
    (studs, - = forward), both feet planted on the stance spots."""
    return plant(_raw(tw, joints, lean_x, pz))


def D(pose, degrees=1.5):
    """Moving hold of a key pose (ak.drift), feet re-planted."""
    return plant(ak.drift(pose, degrees))


# ---- light slashes ------------------------------------------------------------------------------

def _j(right_arm, left_arm, handle, right_leg=(-22, 0, 10), left_leg=(24, 0, -8), **more):
    return {"Right Arm": right_arm, "Left Arm": left_arm, "Handle": handle,
            "Right Leg": right_leg, "Left Leg": left_leg, **more}


def slash1_poses():
    """Forehand right -> left: coil right, unwind left through the target, both feet planted.
    The torso stops square to the target (0..+10): turning further with R6's rigid legs and the right
    foot behind crosses the legs, so the arm carries the rest of the sweep across the body."""
    windup = P(-46, _j((80, 0, 52), (62, 0, -12), (-55, -40, 0), (-20, 0, 10), (22, 0, -8)), lean_x=-2)
    mid = P(-26, _j((92, 0, 36), (30, 0, -20), (-72, -50, 0)), lean_x=-6)
    contact = P(0, _j((98, 0, -6), (-10, 0, -12), (-88, 6, 0), (-24, 0, 10)), lean_x=-10, pz=-0.12)
    follow = P(10, _j((104, 0, -56), (-14, 0, -2), (-90, 34, 0), (-24, 0, 10)), lean_x=-10, pz=-0.12)
    settle = D(P(7, _j((98, 0, -50), (-10, 0, -4), (-91, 22, 0), (-22, 0, 10), (22, 0, -8)), lean_x=-8,
                 pz=-0.08), 3)
    return {"windup": windup, "mid": mid, "contact": contact, "follow": follow, "settle": settle}


def slash2_poses():
    """Backhand left -> right (the return swing): cock the blade over the left shoulder, unwind
    right. The torso only turns a little left in the wind-up (planted R6 legs cross past square);
    the arm folds across the chest instead."""
    windup = P(12, _j((100, 0, -66), (16, 0, -26), (-46, 42, 0), (-20, 0, 10), (22, 0, -8)), lean_x=-2)
    mid = P(-4, _j((100, 0, -44), (24, 0, -36), (-68, 50, 0)), lean_x=-6)
    contact = P(-30, _j((98, 0, -14), (36, 0, -56), (-88, -2, 0), (-24, 0, 10)), lean_x=-10, pz=-0.1)
    follow = P(-50, _j((94, 0, 30), (34, 0, -62), (-96, -20, 0), (-24, 0, 10)), lean_x=-10, pz=-0.1)
    settle = D(P(-46, _j((88, 0, 26), (30, 0, -52), (-94, -8, 0), (-22, 0, 10), (22, 0, -8)), lean_x=-8,
                 pz=-0.06), 3)
    return {"windup": windup, "mid": mid, "contact": contact, "follow": follow, "settle": settle}


def light_slash(name, poses, n=1):
    """Snappy light slash (34 f). Body: stance 0 -> wind-up 8 -> mid 10 -> contact 12 (Hit)
    -> follow-through 15 -> settle 19 (moving hold) -> stance 34. The blade trails the arm into the
    wind-up (its key lands 1 f after the arm's), lags behind the hand through mid-swing, whips past it
    at contact and overshoots ~15-20 deg past the arm before settling. Contact sits at ~65% of the
    blade's arc; TrailOn on the first frame of the swing, TrailOff when the follow-through eases out."""
    p = poses
    body = [j for j in STANCE if j != "Handle"]

    def only(pose, joints):
        return {j: pose[j] for j in joints}

    a = ak.Anim(name, rig="R6", props=PROPS, length=34, priority="Action", style="snappy")
    a.key(0, only(STANCE, body), "quad_out")
    a.key(8, only(p["windup"], body), "quad_in")
    a.key(10, only(p["mid"], body), "linear")
    a.key(12, only(p["contact"], body), "linear")
    a.key(15, only(p["follow"], body), "cubic_out")
    a.key(19, only(p["settle"], body), "sine_inout")
    a.key(34, only(STANCE, body), "linear")
    h = "Handle"
    a.key(0, {h: STANCE[h]}, "linear")
    a.key(2, {h: STANCE[h]}, "quad_out")
    a.key(9, {h: p["windup"][h]}, "quad_in")
    a.key(10, {h: p["mid"][h]}, "linear")
    a.key(12, {h: p["contact"][h]}, "linear")
    a.key(14, {h: p["follow"][h]}, "cubic_out")
    a.key(19, {h: p["settle"][h]}, "sine_inout")
    a.key(34, {h: STANCE[h]}, "linear")
    a.marker(8, "TrailOn").marker(12, "Hit", str(n)).marker(15, "TrailOff")
    a.offset("Head", 2).offset("Left Arm", 1)  # length is set first: offset clamps keys to it
    return a


# ---- heavy overhead cleave ---------------------------------------------------------------------
# In the side plane the blade's pitch is about arm x + torso x + Handle x (0 = forward, 90 = up,
# 180 = back), which is how the numbers below were chosen.

def heavy_poses():
    """Overhead cleave: rise and coil with the blade hanging behind the head, then chop down through
    the target with the whole body (lean, drop, twist), the tip stopping just off the floor.
    The arm stays under 180 deg (straight up): past that the R6 shoulder reads as broken."""
    windup = P(-28, {"Right Arm": (170, 0, 8), "Left Arm": (104, 0, -14), "Handle": (22, 32, 0),
                     "Head": (-8, 0, 0), "Right Leg": (-14, 0, 8), "Left Leg": (16, 0, -6)}, lean_x=14)
    coil = P(-34, {"Right Arm": (174, 0, 8), "Left Arm": (108, 0, -12), "Handle": (24, 32, 0),
                   "Head": (-10, 0, 0), "Right Leg": (-14, 0, 8), "Left Leg": (16, 0, -6)}, lean_x=17)
    mid = P(-20, {"Right Arm": (160, 0, 4), "Left Arm": (70, 0, -18), "Handle": (28, 28, 0),
                  "Head": (0, 0, 0), "Right Leg": (-20, 0, 10), "Left Leg": (22, 0, -8)}, lean_x=4)
    contact = P(-6, {"Right Arm": (126, 0, 6), "Left Arm": (-6, 0, -20), "Handle": (-72, -6, 0),
                     "Head": (12, 0, 0), "Right Leg": (-26, 0, 12), "Left Leg": (28, 0, -10)}, lean_x=-16)
    follow = P(0, {"Right Arm": (98, 0, 10), "Left Arm": (-20, 0, -24), "Handle": (-104, -14, 0),
                   "Head": (22, 0, 0), "Right Leg": (-30, 0, 12), "Left Leg": (30, 0, -10)}, lean_x=-27)
    settle = P(-2, {"Right Arm": (100, 0, 10), "Left Arm": (-14, 0, -22), "Handle": (-100, -12, 0),
                    "Head": (18, 0, 0), "Right Leg": (-28, 0, 12), "Left Leg": (28, 0, -10)}, lean_x=-23)
    return {"windup": windup, "coil": coil, "mid": mid, "contact": contact, "follow": follow, "settle": settle}


def heavy(name, style="snappy"):
    """Heavy cleave, timing from HEAVY_TIMING. Body: stance -> wind-up (rise, coil) -> telegraph
    (moving hold) -> mid -> contact (Hit) -> follow-through -> settle -> stance. The blade trails
    the arm `lag` frames into the wind-up, keeps cocking back while the arm starts down, then whips
    through to contact and overshoots."""
    p = heavy_poses()
    t = HEAVY_TIMING[style]
    body = [j for j in STANCE if j != "Handle"]
    h = "Handle"

    def only(pose, joints):
        return {j: pose[j] for j in joints}

    a = ak.Anim(name, rig="R6", props=PROPS, length=t["end"], priority="Action", style=style)
    lag = t["lag"]
    a.key(0, only(STANCE, body), "cubic_inout")
    a.key(t["up"], only(p["windup"], body), "sine_inout")
    a.key(t["hold"], only(p["coil"], body), "quad_in")  # telegraph: keeps loading, never freezes
    a.key(t["mid"], only(p["mid"], body), "linear")
    a.key(t["hit"], only(p["contact"], body), "quad_out")  # carries through, slowing into the floor
    a.key(t["follow"], only(p["follow"], body), "cubic_out")
    a.key(t["settle"], only(D(p["settle"], 2), body), "sine_inout")
    a.key(t["end"], only(STANCE, body), "linear")
    a.key(0, {h: STANCE[h]}, "linear")
    a.key(lag + 1, {h: STANCE[h]}, "cubic_inout")
    a.key(t["up"] + lag, {h: p["windup"][h]}, "linear")
    a.key(t["hold"] + 1, {h: p["mid"][h]}, "quad_in")  # still cocking back as the arm starts down
    a.key(t["hit"], {h: p["contact"][h]}, "quad_out")
    a.key(t["follow"], {h: p["follow"][h]}, "cubic_out")
    a.key(t["settle"], {h: p["settle"][h]}, "sine_inout")
    a.key(t["end"], {h: STANCE[h]}, "linear")
    a.marker(t["up"], "Windup").marker(t["hold"], "TrailOn").marker(t["hit"], "Hit", "heavy")
    a.marker(t["hit"] + 2, "TrailOff")  # the blade has lost half its speed
    a.offset("Head", 2 * lag).offset("Left Arm", lag)
    return a


HEAVY_TIMING = {
    "snappy": {"up": 16, "hold": 19, "mid": 22, "hit": 25, "follow": 28, "settle": 34, "end": 60, "lag": 2},
}


def _body(pose):
    return {j: v for j, v in pose.items() if j != "Handle"}


def heavy_weighty(name):
    """Weighty cleave (126 f): slow rise through a front pass, long held telegraph that keeps
    loading, a 10 f chop that drags through the target instead of stopping, the blade's weight
    carrying it to the floor, then a long effortful recovery (torso comes up before the blade).

    body:   stance 0 -> rise 16 -> wind-up 30 -> coil 38 (telegraph) -> mid 43 -> contact 48 (Hit)
            -> drag-through to follow 62 -> settle 74 -> lift 100 (blade dragged back to the right hip) -> stance 126
    blade:  trails the arm 2-3 f all through the wind-up, still cocking back at 40, whips to contact
    """
    p = heavy_poses()
    rise = P(-22, {"Right Arm": (122, 0, 6), "Left Arm": (70, 0, -16), "Handle": (4, 14, 0),
                   "Head": (-2, 0, 0), "Right Leg": (-14, 0, 8), "Left Leg": (16, 0, -6)}, lean_x=6)
    contact = p["contact"]
    follow = P(0, {"Right Arm": (98, 0, 10), "Left Arm": (-22, 0, -16), "Handle": (-104, -14, 0),
                   "Head": (22, 0, 0), "Right Leg": (-32, 0, 14), "Left Leg": (32, 0, -12)}, lean_x=-28)
    settle = P(-2, {"Right Arm": (104, 0, 10), "Left Arm": (-6, 0, -16), "Handle": (-100, -12, 0),
                    "Head": (12, 0, 0), "Right Leg": (-30, 0, 14), "Left Leg": (30, 0, -12)}, lean_x=-24)
    lift = P(-22, {"Right Arm": (40, 0, 14), "Left Arm": (14, 0, -24), "Handle": (-44, -16, 0),
                   "Head": (8, 0, 0), "Right Leg": (-18, 0, 10), "Left Leg": (20, 0, -8)}, lean_x=-10)
    h = "Handle"
    a = ak.Anim(name, rig="R6", props=PROPS, length=126, priority="Action", style="weighty")
    a.key(0, _body(STANCE), "sine_inout")
    a.key(16, _body(rise), "sine_inout")
    a.key(30, _body(p["windup"]), "linear")
    a.key(38, _body(p["coil"]), "quad_in")
    a.key(43, _body(p["mid"]), "linear")
    a.key(48, _body(contact), "quad_out")  # drags through: a third of the speed, then glides down
    a.key(62, _body(follow), "sine_inout")
    a.key(74, _body(settle), "sine_inout")
    a.key(100, _body(lift), "sine_inout")
    a.key(126, _body(STANCE), "linear")
    a.key(0, {h: STANCE[h]}, "linear")
    a.key(3, {h: STANCE[h]}, "sine_inout")
    a.key(19, {h: rise[h]}, "sine_inout")
    a.key(33, {h: p["windup"][h]}, "linear")
    a.key(40, {h: p["mid"][h]}, "quad_in")
    a.key(48, {h: contact[h]}, "quad_out")
    a.key(63, {h: follow[h]}, "sine_inout")
    a.key(75, {h: settle[h]}, "sine_inout")
    a.key(103, {h: lift[h]}, "sine_inout")
    a.key(126, {h: STANCE[h]}, "linear")
    a.marker(30, "Windup").marker(38, "TrailOn").marker(48, "Hit", "heavy").marker(56, "TrailOff")
    a.offset("Head", 4).offset("Left Arm", 2)
    return a


# ---- block and parry ------------------------------------------------------------------------------

def guard_pose():
    """Block guard: squared up and low, blade flat across the chest pointing left, the free hand
    bracing the flat near the tip."""
    return P(-6, {"Right Arm": (104, 0, 0), "Left Arm": (108, 0, 6), "Handle": (-20, 71, 0),
                  "Head": (-6, 0, 0), "Right Leg": (-24, 0, 14), "Left Leg": (26, 0, -12)}, lean_x=-6)


def block(name):
    """Looping guard (72 f). The 3-5 f enter is the fade when the game starts the track:
    track:Play(0.07). Breathing runs on a 36 f sub-cycle, the arms and blade drift on the full
    72 f, the blade lags the arms by 6 f so it never sits dead still."""
    guard = guard_pose()
    sunk = P(-7, {"Right Arm": (102.5, 0, -0.5), "Left Arm": (106.5, 0, 5.5), "Handle": (-21.5, 72, 0),
                  "Head": (-5, 0, 0), "Right Leg": (-25, 0, 14), "Left Leg": (27, 0, -12)}, lean_x=-7)
    a = ak.Anim(name, rig="R6", props=PROPS, length=72, loop=True, priority="Action", style="snappy")
    torso_legs = ("Torso", "Right Leg", "Left Leg")
    for f, pose in ((0, guard), (18, sunk), (36, guard), (54, sunk)):
        a.key(f, {j: pose[j] for j in torso_legs}, "bezier")
    for f, pose in ((0, guard), (36, sunk)):
        a.key(f, {j: pose[j] for j in ("Right Arm", "Left Arm", "Head", "Handle")}, "bezier")
    a.offset("Handle", 6).offset("Head", 4).offset("Left Arm", 2)
    a.marker(0, "Guard")
    return a


def parry_poses():
    """Deflect: the blade snaps into a rising diagonal across the face (hand at the right chest, tip
    up and to the left above the head) to catch the incoming swing; the impact knocks it back
    toward the right and the body flinches."""
    deflect = P(-6, {"Right Arm": (112, 0, 10), "Left Arm": (-14, 0, -26), "Handle": (-34, 42, 0),
                     "Head": (-10, 0, 0), "Right Leg": (-22, 0, 12), "Left Leg": (24, 0, -10)}, lean_x=-3)
    recoil = P(-10, {"Right Arm": (118, 0, 15), "Left Arm": (-8, 0, -30), "Handle": (-26, 36, 0),
                     "Head": (-2, 0, 0), "Right Leg": (-20, 0, 12), "Left Leg": (22, 0, -10)}, lean_x=2)
    return deflect, recoil


def parry(name):
    """Parry (22 f): snap 3 f into the deflect (Parry marker; the blade starts a frame after the
    hand), impact recoil 2 f, moving hold to 10, recover to the stance by 22."""
    deflect, recoil = parry_poses()
    h = "Handle"
    a = ak.Anim(name, rig="R6", props=PROPS, length=22, priority="Action", style="snappy")
    a.key(0, _body(STANCE), "quad_out")
    a.key(3, _body(deflect), "linear")
    a.key(5, _body(recoil), "cubic_out")
    a.key(10, _body(D(recoil, 2)), "cubic_inout")
    a.key(22, _body(STANCE), "linear")
    a.key(0, {h: STANCE[h]}, "linear")
    a.key(1, {h: STANCE[h]}, "quad_out")
    a.key(3, {h: deflect[h]}, "linear")
    a.key(5, {h: recoil[h]}, "cubic_out")
    a.key(11, {h: (-29, 38, 0)}, "cubic_inout")
    a.key(22, {h: STANCE[h]}, "linear")
    a.marker(3, "Parry")
    a.offset("Head", 2).offset("Left Arm", 1)
    return a
