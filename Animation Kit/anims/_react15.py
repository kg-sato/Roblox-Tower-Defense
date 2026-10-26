"""R15 helpers for the reaction and movement clips (hit reaction, dash). Method by fwjelaa.

Key poses are written as fighter() parameters (anims/_r15.py): hips, move, chest, head, both feet,
both fists. A clip is solved on EVERY frame: the parameters of the two keys around a frame are blended
with the first key's ease and the IK runs again. So:
  - a planted foot stays exactly on its spot (and a gliding foot moves in a straight line),
  - knees and elbows always bend the right way (two IK solutions' joint angles are never mixed),
  - the arms can run on their own keys a few frames behind the body (loose arms, overlap).

    keys = [(0, K(), "linear"), (2, K(hips=(8, -38, 0), ...), "cubic_out"), ..., (24, K(), "linear")]
    a = timeline("R15_HitReact", keys, arms=arm_keys, priority="Action4")
"""
import math

from mathutils import Vector

import animkit as ak
from _r15 import STANCE, fighter, fk

ARM = ("lead_fist", "rear_fist", "lead_hand", "rear_hand")
_SHOULDER = {"lead_fist": Vector((-1, 0.563, 0)), "rear_fist": Vector((1, 0.563, 0))}  # chest axes

EASE = {
    "linear": lambda u: u,
    "quad_in": lambda u: u * u,
    "quad_out": lambda u: 1 - (1 - u) ** 2,
    "cubic_in": lambda u: u ** 3,
    "cubic_out": lambda u: 1 - (1 - u) ** 3,
    "quart_out": lambda u: 1 - (1 - u) ** 4,
    "cubic_inout": lambda u: 4 * u ** 3 if u < 0.5 else 1 - (-2 * u + 2) ** 3 / 2,
    "sine_inout": lambda u: 0.5 - 0.5 * math.cos(math.pi * u),
}


def foot(x, z, yaw=0.0, pitch=0.0, lift=0.0, anchor="flat"):
    """A foot placement for plant(): every key of a clip spells all six fields so they blend."""
    return {"x": x, "z": z, "yaw": yaw, "pitch": pitch, "lift": lift, "anchor": anchor}


_lf, _rf = STANCE["lead_foot"], STANCE["rear_foot"]
LEAD = foot(_lf["x"], _lf["z"], _lf["yaw"])  # the stance's feet, spelled out
REAR = foot(_rf["x"], _rf["z"], _rf["yaw"])
# Front-bottom edge of the stance's rear foot: a toe pivot that starts exactly on the stance foot.
_TOE = fk(fighter())["RightFoot"] @ Vector((0, -0.15, -0.5))


def toe(yaw=-50.0, pitch=0.0, dx=0.0, dz=0.0, lift=0.0):
    """The rear foot standing on its toe edge (heel up when pitch < 0), moved dx, dz from the stance's."""
    return foot(_TOE.x + dx, _TOE.z + dz, yaw, pitch, lift, "toe")


STANCE_K = dict(STANCE, lead_foot=LEAD, rear_foot=REAR)


def K(base=None, **over):
    """Key parameters: the stance (or `base`) overridden by keyword (hips, move, chest, head, lead_foot,
    rear_foot, lead_fist, rear_fist, lead_hand, rear_hand)."""
    k = dict(base or STANCE_K)
    k.update(over)
    return k


def arms(lead, rear, lead_hand=(0, 0, 0), rear_hand=(0, 0, 0)):
    """Arm-only key: (wrist, elbow direction) per fist in chest axes, plus wrist angles."""
    return {"lead_fist": lead, "rear_fist": rear, "lead_hand": lead_hand, "rear_hand": rear_hand}


def limb(side, direction, reach, elbow):
    """(wrist, elbow) for arms(): the wrist `reach` studs from the shoulder (1.64 = straight arm) along
    `direction`, both in chest axes; side "lead" (left) or "rear" (right)."""
    d = Vector(direction).normalized() * reach
    return tuple(_SHOULDER[f"{side}_fist"] + d), tuple(elbow)


STANCE_ARMS = arms(STANCE["lead_fist"], STANCE["rear_fist"], STANCE["lead_hand"], STANCE["rear_hand"])


def _lerp(a, b, t):
    if isinstance(a, dict):
        return {key: _lerp(a[key], b[key], t) for key in a}
    if isinstance(a, (tuple, list)):
        return tuple(_lerp(x, y, t) for x, y in zip(a, b))
    if isinstance(a, (int, float)):
        return a + (b - a) * t
    if a != b:
        raise ValueError(f"can't blend {a!r} into {b!r}: keep one anchor per foot for the whole clip")
    return a


def _polar(k):
    """Fists as (direction from the shoulder, distance, elbow direction): blended this way the wrist
    swings on an arc around the shoulder instead of cutting a straight line past it, so the elbow
    doesn't fold and unfold on the way and the arm turns at an even speed."""
    k = dict(k)
    for name, shoulder in _SHOULDER.items():
        if name in k:
            wrist, elbow = k[name]
            r = Vector(wrist) - shoulder
            k[name] = (tuple(r.normalized()), r.length, tuple(Vector(elbow).normalized()))
    return k


def _slerp(a, b, t):
    a, b = Vector(a).normalized(), Vector(b).normalized()
    w = math.acos(max(-1.0, min(1.0, a.dot(b))))
    if w < 1e-4:
        return tuple(a.lerp(b, t))
    return tuple((a * math.sin((1 - t) * w) + b * math.sin(t * w)) / math.sin(w))


def _cartesian(k):
    for name, shoulder in _SHOULDER.items():
        if name in k:
            d, dist, elbow = k[name]
            k[name] = (tuple(shoulder + Vector(d).normalized() * dist), tuple(elbow))
    return k


def _hermite(p1, p2, m1, m2, h, u):
    """Cubic Hermite between p1 and p2 (tangents m1, m2 per frame, h frames apart), nested values."""
    if isinstance(p1, dict):
        return {key: _hermite(p1[key], p2[key], m1[key], m2[key], h, u) for key in p1}
    if isinstance(p1, (tuple, list)):
        return tuple(_hermite(*v, h, u) for v in zip(p1, p2, m1, m2))
    if isinstance(p1, (int, float)):
        h00, h10, h01, h11 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u, -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
        return h00 * p1 + h10 * h * m1 + h01 * p2 + h11 * h * m2
    return _lerp(p1, p2, u)


def _slope(a, b, df):
    """Per-frame change from a to b (0 where values can't blend)."""
    if isinstance(a, dict):
        return {key: _slope(a[key], b[key], df) for key in a}
    if isinstance(a, (tuple, list)):
        return tuple(_slope(x, y, df) for x, y in zip(a, b))
    return (b - a) / df if isinstance(a, (int, float)) and df else 0.0


def _tangent(keys, j):
    """Catmull-Rom tangent at key j, or zero where the curve doesn't run smoothly through it (an end
    of the clip, or a key next to an eased segment: those arrive or leave at rest)."""
    if 0 < j < len(keys) - 1 and keys[j - 1][2] == "smooth" and keys[j][2] == "smooth":
        return _slope(keys[j - 1][1], keys[j + 1][1], keys[j + 1][0] - keys[j - 1][0])
    return _slope(keys[j][1], keys[j][1], 0)


def sample(keys, f):
    """Parameters at frame f (clamped to the keys): each key's ease shapes the move to the next key.
    "smooth" runs a curve through the keys (a moving hold that never stops on a key)."""
    keys = [(kf, _polar(k), e) for kf, k, e in keys]
    f = max(keys[0][0], min(keys[-1][0], f))
    i = max(j for j in range(len(keys) - 1) if keys[j][0] <= f) if f < keys[-1][0] else len(keys) - 2
    (f0, k0, ease), (f1, k1, _) = keys[i], keys[i + 1]
    u = (f - f0) / (f1 - f0)
    if ease == "smooth":
        return _cartesian(_hermite(k0, k1, _tangent(keys, i), _tangent(keys, i + 1), f1 - f0, u))
    t = EASE[ease](u)
    k = _lerp(k0, k1, t)
    for name in _SHOULDER:
        if name in k:  # an even turn rate around the shoulder
            k[name] = (_slerp(k0[name][0], k1[name][0], t), k[name][1], _slerp(k0[name][2], k1[name][2], t))
    return _cartesian(k)


def timeline(name, keys, arm_keys=None, arm_lag=0, **anim):
    """Animation keyed on every frame from (frame, K(...), ease) keys. `arm_keys` (frame, arms(...),
    ease) drive the fists instead of the body keys; `arm_lag` delays them (overlap)."""
    length = keys[-1][0]
    a = ak.Anim(name, rig="R15", length=length, **anim)
    for f in range(length + 1):
        k = sample(keys, f)
        if arm_keys or arm_lag:
            late = sample(arm_keys or keys, f - arm_lag)
            k.update({key: late[key] for key in ARM})
        a.full(f, fighter(k), "linear")
    return a
