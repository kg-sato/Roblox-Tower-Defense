"""Shared helpers for the R6 movement set (idle, walk, jump, fall, land, dash). Method by fwjelaa.

Builds on _lib.py: lean / twist keep the feet planted when the Torso turns; roll() here does the same for
a sideways tilt (weight shift). Loops are keyed by sampling a pose function on a fixed grid with bezier
keys, so every sub-cycle that divides the loop length closes without a seam.
"""
import math

import animkit as ak
from _lib import lean, twist

# Upright neutral the movement set returns to (jump / fall / land); the idle and dash use _lib.FIGHT_R6.
NEUTRAL_R6 = ak.ground(ak.IDLE_R6)

# The airborne family shares one silhouette so jump -> fall -> land cross-fade cleanly:
# arms raised high (balancing), one leg forward, chest slightly back, eyes down toward the landing.
# R6 shoulders pivot 0.5 studs below the arm's top, so spreading an arm out (z) swings that stub into
# the Torso: keep |z| <= ~20 and get the "out" read from the raised x instead.
# py lifts the body on the HumanoidRootPart so the dangling feet stay clear of floor level.
AIR = {
    "lean_x": 4,
    "head": (-8, 0, 0),
    "arms": ((160, 0, 14), (144, 0, -17)),
    "legs": ((26, 0, 7), (-16, 0, -7)),  # already apart, so the landing starts pre-spread
    "py": 0.3,
}


def wave(f, period, phase=0.0):
    """sin over `period` frames, phase in cycles (0.25 = a quarter period later)."""
    return math.sin(2 * math.pi * (f / period + phase))


def ebb(f, period, phase=0.0):
    """0 -> 1 -> 0 over `period` frames (a smooth bump, 0 at f = 0)."""
    return 0.5 - 0.5 * math.cos(2 * math.pi * (f / period + phase))


def interp(table, f):
    """Linear read of {frame: value} at any frame (clamped at the ends)."""
    keys = sorted(table)
    if f <= keys[0]:
        return table[keys[0]]
    for a, b in zip(keys, keys[1:]):
        if a <= f <= b:
            return table[a] + (table[b] - table[a]) * (f - a) / (b - a)
    return table[keys[-1]]


def add(pose, delta):
    """Add per-joint offsets: delta = {joint: (dx, dy, dz) or (dx, dy, dz, dpx, dpy, dpz)}."""
    out = dict(pose)
    for j, d in delta.items():
        v = ak._pad(out.get(j, (0, 0, 0)))
        moved = tuple(a + b for a, b in zip(v, ak._pad(d)))
        out[j] = moved if j == "Torso" else moved[:3]
    return out


def roll(pose, z):
    """Tilt the R6 Torso sideways by z degrees (+ = top to the character's left, right hip up) and roll both
    legs back the other way, so they keep hanging straight (R6 legs hang off the Torso)."""
    out = dict(pose)
    t = list(ak._pad(out.get("Torso", (0, 0, 0))))
    t[2] += z
    out["Torso"] = tuple(t)
    for leg in ("Right Leg", "Left Leg"):
        lx, ly, lz = out.get(leg, (0, 0, 0))[:3]
        out[leg] = (lx, ly, lz - z)
    return out


def arms_world(pose, torso_x):
    """Arms keyed in world terms: R6 arms hang off the Torso, so add the lean back (world = arm x + lean)."""
    out = dict(pose)
    for arm in ("Right Arm", "Left Arm"):
        if arm in out:
            x, y, z = out[arm][:3]
            out[arm] = (x - torso_x, y, z)
    return out


def compose(lean_x=0.0, turn=0.0, tilt=0.0, head=(0, 0, 0), arms=((0, 0, 4), (0, 0, -4)),
            legs=((0, 0, 1), (0, 0, -1)), head_follow=0.6, ground=True, lift=0.0, py=0.0, pz=0.0,
            hip_pivot=False):
    """An R6 pose from world-ish limb angles: each arm / leg x is its swing from vertical (+ forward)
    whatever the Torso does. The Torso then leans (x, - = forward), turns (y) and tilts (z) on top;
    legs are turned back so they keep their swing, the head counter-turns `head_follow` of the turn.
    hip_pivot=True leans about the hips instead of the Torso centre: the chest folds forward while the
    hips (and so the feet) stay where they are. Without it a -20 lean swings the hips 0.34 studs back.
    ground=True puts the lowest foot corner on the floor (+ lift); airborne poses pass ground=False."""
    if hip_pivot:
        a = math.radians(lean_x)
        pz += math.sin(a)  # the hip line sits 1 stud below the Torso centre
        py -= 1 - math.cos(a)
    p = {"Torso": (0, 0, 0, 0, py, pz), "Head": tuple(head),
         "Right Arm": tuple(arms[0]), "Left Arm": tuple(arms[1]),
         "Right Leg": tuple(legs[0]), "Left Leg": tuple(legs[1])}
    p = twist(p, turn, head=head_follow)
    p = roll(p, tilt)
    p = arms_world(lean(p, lean_x), lean_x)
    return ak.ground(p, lift=lift) if ground else p


LEGS = ("Right Leg", "Left Leg")


def soles(pose):
    """Sole centre of each foot as (x, y, z) in HumanoidRootPart space (y = -3 is the floor)."""
    import checks
    import rigs
    from mathutils import Vector
    r = rigs.with_props("R6", ())
    fk = checks.forward_kinematics(r, ak.pose_transforms(pose, r))
    return {leg: tuple(fk[leg] @ Vector((0, -1, 0))) for leg in LEGS}


def foot_lows(pose):
    """Lowest corner height of each foot (HumanoidRootPart space; the floor is y = -3)."""
    import checks
    import rigs
    r = rigs.with_props("R6", ())
    fk = checks.forward_kinematics(r, ak.pose_transforms(pose, r))
    return {leg: min(c.y for c in checks._corners(fk[leg], r["parts"][leg])) for leg in LEGS}


def level_feet(pose, iters=12):
    """Both feet down: R6 legs are rigid, so in a split only the less tilted foot touches. Swing the
    higher leg (its x) until its lowest corner is level with the other foot's, then ground the pose."""
    out = dict(pose)
    lows = foot_lows(out)
    leg = max(LEGS, key=lambda j: lows[j])
    other = LEGS[1] if leg == LEGS[0] else LEGS[0]
    for _ in range(iters):
        err = lows[leg] - lows[other]
        if abs(err) < 0.005:
            break
        x, y, z = out[leg]
        out[leg] = (x + 0.5, y, z)
        slope = (foot_lows(out)[leg] - lows[leg]) / 0.5
        if abs(slope) < 1e-6:
            out[leg] = (x, y, z)
            break
        out[leg] = (x - err / slope, y, z)
        lows = foot_lows(out)
    return ak.ground(out)


def plant(pose, targets, iters=8):
    """Turn each leg (its x and z) until its sole centre is back over the floor spot in `targets`
    ({leg: (x, y, z)}, e.g. soles(stance)). The hips may sway, twist or roll; the feet don't skate.
    R6 legs are rigid, so a vertical bob still shows as a small sink / lift (keep it under ~0.06)."""
    out = dict(pose)
    h = 0.25
    for leg in LEGS:
        tx, _, tz = targets[leg]
        for _ in range(iters):
            x, y, z = out[leg][:3]
            fx, _, fz = soles(out)[leg]
            ex, ez = fx - tx, fz - tz
            if abs(ex) + abs(ez) < 1e-4:
                break
            out[leg] = (x + h, y, z)
            ax = soles(out)[leg]
            out[leg] = (x, y, z + h)
            az = soles(out)[leg]
            j11, j21 = (ax[0] - fx) / h, (ax[2] - fz) / h
            j12, j22 = (az[0] - fx) / h, (az[2] - fz) / h
            det = j11 * j22 - j12 * j21
            out[leg] = (x - (j22 * ex - j12 * ez) / det, y, z - (-j21 * ex + j11 * ez) / det)
    return out


def key_loop(anim, pose_at, step):
    """Key a loop by sampling pose_at(frame) every `step` frames (step must divide anim.length)."""
    assert anim.length % step == 0, "the key grid must divide the loop"
    for f in range(0, anim.length, step):
        anim.key(f, pose_at(f), ease="bezier")
    return anim
