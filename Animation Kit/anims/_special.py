"""Shared helpers for the specials: block, hit reaction, ultimate (method by fwjelaa).

feet()   where the soles are in a reference stance (legs split as given, torso square): the targets body() plants.
body()   builds an R6 pose from camera terms: torso yaw/lean/lunge, arm and head angles as the viewer sees them,
         feet planted on given spots. R6 needs this for big twists: the hips sit on the torso, so a 50 deg
         turn swings each hip ~0.8 studs around and a pose-language leg split turns with the torso. body() bends
         the torso at the hips, then solves both legs' swings plus a little give in the hips (damped least
         squares on the kit's own FK) so both soles land on their spots, both feet touch the floor and the legs
         keep pointing forward. spots_of() reads the spots of any pose (e.g. the fight stance).
mix()    blends body() recipes, so overshoots and in-betweens keep the feet planted as well.
shiver() keys a vibrating moving hold (power charging, straining at the end of a big hit); feet stay put.
strike() keys one contact the battlegrounds way: accelerate in, Hit marker, linear carry, ease out.
"""
import math

import animkit as ak
import checks
import rigs
from mathutils import Vector

_RIG = rigs.with_props("R6", ())
_LEGS = ("Right Leg", "Left Leg")
_SOLE = Vector((0, -1, 0))  # bottom centre of an R6 leg, in the leg's own space

# Fixed jitter pattern (not random, so every build is identical). Each row: px, py, pz, yaw, roll.
_JITTER = [
    (0.9, -0.5, 0.6, 0.8, -0.6), (-0.8, 0.7, -0.4, -0.9, 0.5), (0.4, -0.9, -0.8, 0.5, 0.9),
    (-0.9, 0.3, 0.9, -0.4, -0.8), (0.7, 0.8, -0.6, 0.9, 0.3), (-0.5, -0.6, 0.4, -0.7, -0.9),
    (1.0, 0.2, -0.9, 0.3, 0.7), (-0.6, -0.9, 0.7, -1.0, 0.2),
]


def _rot(x, y, z):
    return rigs.angles(x, y, z).to_3x3()


def _local(parent, world):
    """Pose-language angles of a child whose world rotation is `world`, under a parent rotated `parent`
    (the pose language is Rx*Ry*Rz, which is Blender's 'ZYX' Euler order)."""
    e = (parent.inverted() @ world).to_euler("ZYX")
    return tuple(math.degrees(v) for v in e)


def _soles(pose):
    fk = checks.forward_kinematics(_RIG, ak.pose_transforms(pose, _RIG))
    return {leg: fk[leg] @ _SOLE for leg in _LEGS}


def spots_of(pose):
    """Where a pose's soles are: {leg: (x, z)} in studs, character space."""
    s = _soles(pose)
    return {leg: (s[leg].x, s[leg].z) for leg in _LEGS}


def feet(rleg=(0, 0, 1), lleg=(0, 0, -1)):
    """Sole positions (x, z in studs, character space) of a square stance with the legs split like this."""
    return spots_of(ak.ground({"Torso": (0, 0, 0, 0, 0, 0), "Right Leg": tuple(rleg), "Left Leg": tuple(lleg)}))


_FLOAT_WEIGHT = 4.0  # a foot in the air costs this much more than a foot off its spot
_SPOT_WEIGHT = 5.0  # a foot off its spot costs this much more than the hips giving way by the same distance


def _solve(a, b):
    """Solve the small linear system a x = b (Gaussian elimination with partial pivoting)."""
    n = len(b)
    m = [list(row) + [v] for row, v in zip(a, b)]
    for c in range(n):
        piv = max(range(c, n), key=lambda i: abs(m[i][c]))
        if abs(m[piv][c]) < 1e-12:
            return None
        m[c], m[piv] = m[piv], m[c]
        for i in range(c + 1, n):
            f = m[i][c] / m[c][c]
            for j in range(c, n + 1):
                m[i][j] -= f * m[c][j]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (m[i][n] - sum(m[i][j] * x[j] for j in range(i + 1, n))) / m[i][i]
    return x


def _plant_legs(p, spots, swing, lift):
    """Solve both legs' world swings (x forward, z sideways) and let the hips give a little (px, pz) so that
    both soles land exactly on their spots with both feet on the floor (damped Gauss-Newton, 6 unknowns).
    Rigid R6 legs can't reach any spots from any hip position: lunge the hips forward and the back foot
    would float, so the hips settle back a touch instead, the way a body balances."""
    floor = -_RIG["hip_height"] + lift
    torso0 = ak._pad(p["Torso"])
    torso = _rot(*torso0[:3])

    def pose_of(u):
        q = dict(p)
        q["Torso"] = torso0[:3] + (torso0[3] + u[4], torso0[4], torso0[5] + u[5])
        q["Right Leg"] = _local(torso, _rot(u[0], 0, u[1]))
        q["Left Leg"] = _local(torso, _rot(u[2], 0, u[3]))
        return ak.ground(q, lift=lift)

    def residual(u):
        fk = checks.forward_kinematics(_RIG, ak.pose_transforms(pose_of(u), _RIG))
        res = []
        for leg in _LEGS:
            s = fk[leg] @ _SOLE
            res += [_SPOT_WEIGHT * (s.x - spots[leg][0]), _SPOT_WEIGHT * (s.z - spots[leg][1])]
        for leg in _LEGS:
            low = min(c.y for c in checks._corners(fk[leg], _RIG["parts"][leg]))
            raised = spots[leg][2] if len(spots[leg]) > 2 else 0.0  # a stepping foot can be in the air
            res.append(_FLOAT_WEIGHT * (low - floor - raised))
        return res + [u[4], u[5]]

    u = [swing["Right Leg"][0], swing["Right Leg"][1], swing["Left Leg"][0], swing["Left Leg"][1], 0.0, 0.0]
    limit = (12.0, 12.0, 12.0, 12.0, 0.15, 0.15)  # largest step per iteration: degrees, studs
    probe = (0.2, 0.2, 0.2, 0.2, 0.005, 0.005)
    lam = 1e-3
    r = residual(u)
    cost = sum(v * v for v in r)
    n = len(u)
    for _ in range(30):
        cols = []
        for k in range(n):
            du = list(u)
            du[k] += probe[k]
            cols.append([(a - b) / probe[k] for a, b in zip(residual(du), r)])
        jtj = [[sum(ci * cj for ci, cj in zip(cols[i], cols[j])) + (lam if i == j else 0) for j in range(n)]
               for i in range(n)]
        jtr = [sum(ci * ri for ci, ri in zip(cols[i], r)) for i in range(n)]
        step = _solve(jtj, [-v for v in jtr])
        if step is None:
            break
        step = [max(-m, min(m, v)) for v, m in zip(step, limit)]
        trial = [a + v for a, v in zip(u, step)]
        tr = residual(trial)
        tcost = sum(v * v for v in tr)
        if tcost < cost:
            u, r, cost, lam = trial, tr, tcost, lam * 0.3
            if max(abs(v) / m for v, m in zip(step, limit)) < 1e-4:
                break
        else:
            lam *= 10
            if lam > 1e8:
                break
    swing["Right Leg"], swing["Left Leg"] = (u[0], u[1]), (u[2], u[3])
    return pose_of(u)


def body(yaw=0.0, pitch=0.0, pz=0.0, px=0.0, lift=0.0, head=(0, 0, 0), look=0.7,
         r=(0, 0, 4), l=(0, 0, -4), rleg=(0, 0, 1), lleg=(0, 0, -1), spots=None):
    """An R6 pose in camera terms.
    yaw    torso turn, + = to its left (a right-hand punch turns the body left)
    pitch  torso lean, - = forward. The torso bends at the hips (R6 would pivot at its middle and swing the
           hips back), and leans along the way it faces, so a twisted torso keeps its hips level
    pz, px hips back (+) / lunge forward (-), and sideways; the feet stay on their spots
    head   (pitch, yaw, roll) of the head in the world; `look` = share of the torso yaw the head undoes,
           so the eyes stay on the target
    r, l   arms: x is the swing as seen in the world (90 = pointing level forward, 180 = straight up),
           y and z as in the pose language (relative to the torso: the arms turn with the shoulders)
    rleg, lleg  the stance: legs split like this with the torso square define where the feet stand
    spots  or give the foot spots directly: {leg: (x, z)} or (x, z, height) for a foot in the air"""
    spots = spots or feet(rleg, lleg)
    # lean along the way the torso faces (turn after lean): the hips stay level. The pose language's own order
    # (lean about the world's side axis after the turn) tilts a twisted R6 pelvis and lifts the rear foot.
    torso = _rot(0, yaw, 0) @ _rot(pitch, 0, 0)
    hips = torso @ Vector((0, -1, 0))  # where the leaning moved the hip line; put it back under the torso
    hx, hy, hz = head
    p = {
        "Torso": _local(_rot(0, 0, 0), torso) + (px - hips.x, 0, pz - hips.z),
        "Head": _local(torso, _rot(0, yaw * (1 - look) + hy, 0) @ _rot(hx, 0, hz)),
        "Right Arm": (r[0] - pitch, r[1], r[2]),
        "Left Arm": (l[0] - pitch, l[1], l[2]),
    }
    swing = {"Right Leg": (rleg[0], rleg[2]), "Left Leg": (lleg[0], lleg[2])}
    return _plant_legs(p, spots, swing, lift)


def mix(a, b, t):
    """Blend two body() recipes (keyword dicts) t of the way from a to b; t > 1 overshoots past b.
    Blending recipes instead of finished poses keeps the feet planted on the in-betweens too."""
    out = {}
    for k in set(a) | set(b):
        va, vb = a.get(k, b.get(k)), b.get(k, a.get(k))
        if k == "spots":
            out[k] = {leg: tuple(x + (y - x) * t for x, y in zip(va[leg], vb[leg])) for leg in _LEGS}
        elif isinstance(va, tuple):
            out[k] = tuple(x + (y - x) * t for x, y in zip(va, vb))
        else:
            out[k] = va + (vb - va) * t
    return out


def shake(recipe, i, amp=0.03, deg=0.8):
    """A body() recipe shaken: hips moved up to `amp` studs, torso turned/tilted up to `deg` degrees, fists
    trembling. Re-solved by body(), so the feet stay planted while everything above them vibrates."""
    jx, _, jz, jyaw, jpitch = _JITTER[i % len(_JITTER)]
    out = dict(recipe)
    out["px"] = recipe.get("px", 0.0) + jx * amp
    out["pz"] = recipe.get("pz", 0.0) + jz * amp
    out["yaw"] = recipe.get("yaw", 0.0) + jyaw * deg
    out["pitch"] = recipe.get("pitch", 0.0) + jpitch * deg * 0.6
    for k, arm in enumerate(("r", "l")):
        ax, ay, az = recipe.get(arm, (0, 0, 4 if arm == "r" else -4))
        s = 1 if (i + k) % 2 else -1
        out[arm] = (ax + s * deg * 1.5, ay, az - s * deg)
    return out


def smooth(t):
    return t * t * (3 - 2 * t)


def shiver(a, f0, f1, start, end, every=2, amp=(0.02, 0.05), deg=(0.6, 1.2), seed=0):
    """Vibrating moving hold from frame f0 to f1 between two body() recipes: the body slides smoothly from
    `start` to `end` while it shakes every `every` frames, the shake growing from amp[0] to amp[1] (or
    dying down, if amp[1] < amp[0]). Keys are linear, so each shake is a sharp little tremble; both ends are
    clean (unshaken) poses."""
    frames = list(range(f0, f1 + 1, every))
    if frames[-1] != f1:
        frames.append(f1)
    for n, f in enumerate(frames):
        s = (f - f0) / (f1 - f0)
        base = mix(start, end, smooth(s))
        if f not in (f0, f1):
            base = shake(base, n + seed, amp[0] + (amp[1] - amp[0]) * s, deg[0] + (deg[1] - deg[0]) * s)
        a.full(f, body(**base), ease="linear")
    return a


def strike(a, f, contact, before, value, over=0.12, carry=2, out="cubic_out", over_pose=None):
    """Contact at frame f with a Hit marker, then `carry` frames of linear follow-through past the
    contact (overshoot = `over` of the move from `before`, or `over_pose`). Returns the follow-through frame."""
    a.full(f, contact, ease="linear").marker(f, "Hit", value)
    a.full(f + carry, over_pose or ak.ground(ak.blend(before, contact, 1 + over)), ease=out)
    return f + carry
