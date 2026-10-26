"""Shared helpers for the second move set: spin kick, side dash, ground slam. Method by fwjelaa.

track()     reads a {frame: value} table at any frame. Values may be numbers or tuples; between keys it runs a
            monotone cubic (smooth, never overshoots a key, starts and stops at rest on the first / last key).
            Give a key as (value, "linear") etc. to use one of the kit's eases on the stretch after it instead.
spin()      sums a per-frame speed list into an angle table: the clean way to key a 360 deg turn. Roblox blends
            two keys the short way round, so any key-to-key turn over 180 deg spins BACKWARDS; keyed every frame
            at <= 45 deg / frame it can't.
pivot_xz()  where the Torso must sit so one hip stays over a planted foot while the body turns, leans or tilts
            (the hips orbit the pivot foot instead of the Torso spinning on its own centre).
ground_on() puts the lowest corner of the given feet on the floor (the other foot may be in the air).
planted()   ak.plant for some legs only, grounded on those feet: single support (a kick, a step).
lowest()    lowest corner of any parts (feet, fists): check that a fist really reaches the floor.
side_dash() the side dash for either direction (R6_DashSide / R6_DashSideRight).
"""
import math

import animkit as ak
import checks
import rigs
from _lib import FIGHT_R6, twist
from _move import compose, interp

LEGS = ("Right Leg", "Left Leg")
ARMS = ("Right Arm", "Left Arm")
_RIG = rigs.with_props("R6", ())
FLOOR = -_RIG["hip_height"]

EASE = {
    "linear": lambda t: t,
    "constant": lambda t: 0.0,
    "quad_in": lambda t: t * t,
    "quad_out": lambda t: 1 - (1 - t) ** 2,
    "cubic_in": lambda t: t ** 3,
    "cubic_out": lambda t: 1 - (1 - t) ** 3,
    "cubic_inout": lambda t: 4 * t ** 3 if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2,
    "sine_inout": lambda t: 0.5 - 0.5 * math.cos(math.pi * t),
    "expo_in": lambda t: 0.0 if t <= 0 else 2 ** (10 * t - 10),
    "quint_out": lambda t: 1 - (1 - t) ** 5,
}


def _split(v):
    """A table entry is value or (value, ease); a value is a number or a tuple of numbers."""
    if isinstance(v, tuple) and len(v) == 2 and isinstance(v[1], str):
        return v[0], v[1]
    return v, None


def _slopes(xs, ys):
    """Fritsch-Carlson slopes: a cubic through every key that never overshoots between them."""
    n = len(xs)
    d = [(ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]) for i in range(n - 1)]
    m = [0.0] * n
    for i in range(1, n - 1):
        if d[i - 1] * d[i] > 0:
            h0, h1 = xs[i] - xs[i - 1], xs[i + 1] - xs[i]
            m[i] = 3 * (h0 + h1) / ((2 * h1 + h0) / d[i - 1] + (h1 + 2 * h0) / d[i])
    return m  # the first and last keys start / stop at rest


def _scalar(keys, f):
    xs = [k[0] for k in keys]
    if f <= xs[0]:
        return keys[0][1]
    if f >= xs[-1]:
        return keys[-1][1]
    i = max(j for j in range(len(xs) - 1) if xs[j] <= f)
    x0, x1 = xs[i], xs[i + 1]
    y0, y1, ease = keys[i][1], keys[i + 1][1], keys[i][2]
    t = (f - x0) / (x1 - x0)
    if ease:
        return y0 + (y1 - y0) * EASE[ease](t)
    m = _slopes(xs, [k[1] for k in keys])
    h = x1 - x0
    t2, t3 = t * t, t * t * t
    return ((2 * t3 - 3 * t2 + 1) * y0 + (t3 - 2 * t2 + t) * h * m[i]
            + (-2 * t3 + 3 * t2) * y1 + (t3 - t2) * h * m[i + 1])


def track(table, f):
    """Value of a {frame: value or (value, ease)} table at frame f (see the module docstring)."""
    rows = sorted((fr, *_split(v)) for fr, v in table.items())
    first = rows[0][1]
    if isinstance(first, (tuple, list)):
        return tuple(_scalar([(fr, v[c], e) for fr, v, e in rows], f) for c in range(len(first)))
    return _scalar(rows, f)


def spin(start, speeds, first=0):
    """{frame: angle}: `start` at frame `first`, then each frame turns by the next speed (deg / frame)."""
    out, a = {first: start}, start
    for i, s in enumerate(speeds, 1):
        a += s
        out[first + i] = a
    return out


def pivot_xz(torso, foot, leg="Left Leg"):
    """Torso (px, pz) that keeps `leg`'s hip line right above `foot` (x, y, z) for this Torso rotation."""
    rot = rigs.angles(*torso[:3]).to_3x3()
    side = -0.5 if leg == "Left Leg" else 0.5
    from mathutils import Vector
    hip = rot @ Vector((side, -1.0, 0.0))  # middle of the leg's top, Torso space
    return foot[0] - hip.x, foot[2] - hip.z


def _fk(pose):
    return checks.forward_kinematics(_RIG, ak.pose_transforms(pose, _RIG))


def lowest(pose, parts=LEGS):
    """Lowest corner (y, HumanoidRootPart space; the floor is -3) over the given parts."""
    fk = _fk(pose)
    return min(c.y for p in parts for c in checks._corners(fk[p], _RIG["parts"][p]))


def ground_on(pose, legs=LEGS, lift=0.0):
    """Move the root up / down so the lowest corner of these feet sits on the floor (+ lift)."""
    t = list(ak._pad(pose["Torso"]))
    t[4] += FLOOR + lift - lowest(pose, legs)
    out = dict(pose)
    out["Torso"] = tuple(t)
    return out


def planted(pose, spots, legs=LEGS, lift=0.0):
    """ak.plant for just these legs, grounded on just these feet (the others may be in the air)."""
    return ground_on(ak.plant(pose, spots, legs=legs, grounded=False), legs, lift)


# ---------------------------------------------------------------------------------------------------------
# Side dash. Keys are written for a dash to the LEFT on a square body (no stance turn), then mirrored with
# ak.mirror for the right dash, and only then turned into the orthodox stance (_lib.twist -18). Mirroring the
# finished stance poses would give a southpaw stance (right foot forward) that pops against FIGHT_R6; this
# way both dashes start, brake and end on the same orthodox stance and chain with every other clip.
DASH_LEN = 22
DASH_START, DASH_END = 1, 13
STANCE_TURN = -18  # FIGHT_R6 is the square stance turned this far

# frame: body for the square, dash-left pose. lean (x, - = forward, bends at the hips), tilt (z, + = top to
# the left, into the travel), legs as world swings (x forward, z out), head relative (level: z ~ -tilt).
# R6 legs pivot on the OUTER top edge of the hip, so a leg opened sideways digs its inner corner into the
# floor until ~53 deg: a sideways split can't lower an R6 body. The dash reads through the tilt instead: the
# lead foot glides on the floor under the leaning body, the push leg stays stretched out and just off it.
DASH_KEYS = {
    3: dict(lean=-14, tilt=16, head=(2, 0, -10), legs=((-18, 0, 38), (14, 0, -14))),  # push: the rear leg
    # shoves out, the body tips into the travel
    8: dict(lean=-18, tilt=22, head=(3, 0, -14), legs=((-22, 0, 46), (16, 0, -18))),  # mid glide: most tilted
    13: dict(lean=-17, tilt=20, head=(3, 0, -13), legs=((-21, 0, 44), (16, 0, -17))),  # glide end: DashEnd
    17: dict(lean=-2, tilt=-9, head=(0, 0, 6), legs=((-12, 0, 10), (18, 0, -8))),  # brake: both feet back on
    # their stance spots, counter-tilt
    20: dict(lean=-9, tilt=3, head=(5, 0, -2), legs=((-12, 0, 10), (18, 0, -8))),  # settle past the stance
}
DASH_EASE = {0: "quad_out", 3: "bezier", 8: "bezier", 13: "quad_out", 17: "bezier", 20: "bezier"}
DASH_PLANTED = (17, 20)  # brake onward: feet on the stance spots (locked to the end)

# Arms trail the body by ~2 frames (overlap), as world swings (right, left). The lead arm reaches out along
# the line of action (lead hand -> tilted torso -> push foot); the rear fist tucks across the chest, out of the
# silhouette. On the brake both whip on toward the travel, then settle into the guard.
DASH_ARMS = {
    5: ((64, 0, -24), (34, 0, -40)),
    10: ((58, 0, -30), (26, 0, -52)),
    15: ((60, 0, -28), (30, 0, -48)),
    19: ((48, 0, -34), (78, 0, -30)),
}
DASH_ARM_EASE = {0: "quad_out", 5: "bezier", 10: "bezier", 15: "cubic_out", 19: "bezier"}


def _dash_square(f):
    k = DASH_KEYS[f]
    return compose(lean_x=k["lean"], tilt=k["tilt"], head=k["head"], legs=k["legs"], ground=False,
                   hip_pivot=True)


def _dash_arms(f):
    """Arm keys relative to the torso: take off the lean and tilt the body has at that frame."""
    lean = interp({0: FIGHT_R6["Torso"][0], **{g: k["lean"] for g, k in DASH_KEYS.items()},
                        DASH_LEN: FIGHT_R6["Torso"][0]}, f)
    tilt = interp({0: 0.0, **{g: k["tilt"] for g, k in DASH_KEYS.items()}, DASH_LEN: 0.0}, f)
    (rx, ry, rz), (lx, ly, lz) = DASH_ARMS[f]
    return {"Right Arm": (rx - lean, ry, rz - tilt), "Left Arm": (lx - lean, ly, lz - tilt)}


def side_dash(name, direction="left"):
    feet = ak.soles(FIGHT_R6)
    lead = "Left Leg" if direction == "left" else "Right Leg"
    trail = "Right Leg" if lead == "Left Leg" else "Left Leg"
    a = ak.Anim(name, rig="R6", length=DASH_LEN, priority="Action", slides=True)
    a.full(0, FIGHT_R6, ease=DASH_EASE[0])
    for f in DASH_KEYS:
        pose = _dash_square(f)
        if direction == "right":
            pose = ak.mirror(pose)
        pose = twist(pose, STANCE_TURN)
        if f in DASH_PLANTED:
            pose = ak.plant(pose, feet)
        else:  # glide on the lead foot, the push leg stretched out just off the floor
            pose = ground_on(pose, (lead,))
            assert lowest(pose, (trail,)) > FLOOR + 0.06, f"{name}: the push foot drags on frame {f}"
        a.key(f, {j: v for j, v in pose.items() if j not in ARMS}, ease=DASH_EASE[f])
    for f in DASH_ARMS:
        arms = _dash_arms(f)
        a.key(f, ak.mirror(arms) if direction == "right" else arms, ease=DASH_ARM_EASE[f])
    a.key(0, {j: FIGHT_R6[j] for j in ARMS}, ease=DASH_ARM_EASE[0])
    a.full(DASH_LEN, FIGHT_R6, ease="linear")
    a.lock_feet(DASH_PLANTED[0], DASH_LEN, targets=feet)
    a.marker(DASH_START, "DashStart").marker(DASH_END, "DashEnd")
    return a
