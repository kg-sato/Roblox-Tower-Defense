"""Shared stances and timing presets for the example animations (method by fwjelaa).

Numbers come from research/03-animation-craft.md, all frames at 60 fps.
"""
import animkit as ak

# Timing presets: "snappy" = battlegrounds (TSB / JJS feel), "weighty" = Deepwoken / MK feel.
STYLE = {
    "snappy": {
        "m1": {"antic": 4, "strike": 2, "hitstop": 5, "hold": 3, "recover": 12},
        "finisher": {"antic": 10, "telegraph": 3, "strike": 3, "hitstop": 10, "hold": 5, "recover": 24},
        "overshoot": 0.12,  # share of the motion past the target before settling
        "lag": 1,  # frames each link of the chain trails its driver (torso -> arm -> hand)
        "exaggerate": 1.4,
    },
    "weighty": {
        "m1": {"antic": 12, "strike": 4, "hitstop": 3, "hold": 4, "recover": 22},
        "finisher": {"antic": 20, "telegraph": 6, "strike": 5, "hitstop": 7, "hold": 6, "recover": 36},
        "overshoot": 0.05,
        "lag": 2,
        "exaggerate": 1.1,
    },
}


def lean(pose, x):
    """Lean the R6 Torso by x degrees (negative = forward) and turn both legs back the other way,
    so the feet stay where they were (R6 legs hang off the Torso)."""
    out = dict(pose)
    t = list(out.get("Torso", (0, 0, 0, 0, 0, 0)))
    t += [0] * (6 - len(t))
    t[0] += x
    out["Torso"] = tuple(t)
    for leg in ("Right Leg", "Left Leg"):
        lx, ly, lz = out.get(leg, (0, 0, 0))[:3]
        out[leg] = (lx - x, ly, lz)
    return out


def twist(pose, y, legs=1.0, head=0.6):
    """Turn the R6 Torso by y degrees (+ = to its left); legs counter-turn so the feet stay planted,
    head counter-turns `head` of it so the eyes stay on target."""
    out = dict(pose)
    t = list(out.get("Torso", (0, 0, 0, 0, 0, 0)))
    t += [0] * (6 - len(t))
    t[1] += y
    out["Torso"] = tuple(t)
    for leg in ("Right Leg", "Left Leg"):
        lx, ly, lz = out.get(leg, (0, 0, 0))[:3]
        out[leg] = (lx, ly - y * legs, lz)
    hx, hy, hz = out.get("Head", (0, 0, 0))[:3]
    out["Head"] = (hx, hy - y * head, hz)
    return out


def root(pose, px=0.0, py=0.0, pz=0.0):
    """Move the R6 Torso (studs): py < 0 crouch, pz < 0 lunge forward."""
    out = dict(pose)
    t = list(out.get("Torso", (0, 0, 0, 0, 0, 0)))
    t += [0] * (6 - len(t))
    t[3] += px
    t[4] += py
    t[5] += pz
    out["Torso"] = tuple(t)
    return out


# Orthodox fighting stance: left foot forward, body bladed to the right, fists up (snappy idle base).
FIGHT_R6 = root(twist({
    "Torso": (-6, 0, 0, 0, 0, 0),
    "Head": (4, 0, 0),
    "Right Arm": (62, 0, -14),  # rear fist up by the chin
    "Left Arm": (78, 0, 10),  # lead fist forward
    "Right Leg": (-12, 0, 10),
    "Left Leg": (18, 0, -8),
}, -18), py=-ak.leg_drop(16))

# Weighty stance: lower, wider, hands lower.
HEAVY_R6 = root(twist({
    "Torso": (-8, 0, 0, 0, 0, 0),
    "Head": (6, 0, 0),
    "Right Arm": (40, 0, -6),
    "Left Arm": (52, 0, 12),
    "Right Leg": (-16, 0, 14),
    "Left Leg": (20, 0, -12),
}, -22), py=-ak.leg_drop(22))

FIGHT_R6 = ak.ground(FIGHT_R6)
HEAVY_R6 = ak.ground(HEAVY_R6)
STANCE = {"snappy": FIGHT_R6, "weighty": HEAVY_R6}
