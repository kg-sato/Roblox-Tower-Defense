"""Walk, Hit and Death clips for the enemy rigs (T142), as plain data. Pure Python (no bpy): used by Blender/rig_enemy.py to write <Name>_clips.json and to pose-test the rig.
Same convention and recipes as Studio_Export/FamiliarClips.luau (walk, hit, death per archetype), so the Studio side can build KeyframeSequences with the code it already has:
a pose is {bone: [rx, ry, rz, tx, ty, tz]}, rotation in degrees about ROBLOX MESH-SPACE axes (X right, Y up, -Z forward; forward swing of a hanging limb is +X, lean forward is -X,
wings flap about Z), translation in MODEL HEIGHTS (multiply by the model's height in studs; FamiliarClips uses studs directly). Missing bones stay at rest.
Differences from the familiar clips: translations are height fractions; the death also drops the pelvis further for a heavy biped (same shape for all)."""
import math

TAU = math.pi * 2
LENGTH = {"Walk": (1.0, 12, True), "Hit": (0.5, 10, False), "Death": (1.2, 24, False)}


def walk(arch, ph):
    s, c = math.sin(TAU * ph), math.cos(TAU * ph)
    bob = 0.02 * abs(s)
    p = {}
    if arch == "biped":
        p["Pelvis"] = [0, 0, 3 * s, 0, bob, 0]
        p["Chest"] = [0, 0, -2 * s]
        p["UpperLeg.L"], p["UpperLeg.R"] = [30 * s], [-30 * s]
        p["LowerLeg.L"], p["LowerLeg.R"] = [-35 * max(0, -s)], [-35 * max(0, s)]
        p["UpperArm.L"], p["UpperArm.R"] = [-22 * s], [22 * s]
        p["LowerArm.L"], p["LowerArm.R"] = [-10 * max(0, s)], [-10 * max(0, -s)]
        p["Head"] = [0, -4 * s, 2 * s]
    elif arch == "quadruped":
        p["Pelvis"] = [0, 0, 2 * s, 0, bob, 0]
        p["Chest"] = [-3, 3 * s, 0]
        p["FrontUpperLeg.L"], p["HindUpperLeg.R"] = [24 * s], [24 * s]
        p["FrontUpperLeg.R"], p["HindUpperLeg.L"] = [-24 * s], [-24 * s]
        p["FrontLowerLeg.L"], p["HindLowerLeg.R"] = [-30 * max(0, -s)], [-30 * max(0, -s)]
        p["FrontLowerLeg.R"], p["HindLowerLeg.L"] = [-30 * max(0, s)], [-30 * max(0, s)]
        p["Head"] = [4 * s, 0, 0]
        p["Tail1"] = [0, 15 * s]
        p["Tail2"] = [0, 20 * math.sin(TAU * ph - 0.8)]
    elif arch == "flyer":
        p["Pelvis"] = [0, 0, 0, 0, 0.04 * s, 0]
        p["Spine"] = [-4, 0, 2 * s]
        p["Head"] = [3 * s, 0, 0]
        p["WingInner.L"], p["WingInner.R"] = [0, 0, 35 * s], [0, 0, -35 * s]
        wo = 25 * math.sin(TAU * ph - 0.6)
        p["WingOuter.L"], p["WingOuter.R"] = [0, 0, wo], [0, 0, -wo]
        p["Tail1"] = [0, 12 * s]
        p["Tail2"] = [0, 18 * math.sin(TAU * ph - 0.9)]
    else:  # floater
        p["Pelvis"] = [0, 0, 0, 0, 0.03 * s, 0]
        p["Spine"] = [-6, 0, 3 * s]
        p["Chest"] = [-3, 0, -2 * s]
        p["Head"] = [3 * s, 0, 0]
        p["Trail1"] = [0, 14 * s]
        p["Trail2"] = [0, 20 * math.sin(TAU * ph - 1)]
        p["UpperArm.L"], p["UpperArm.R"] = [0, 0, 14 * c], [0, 0, -14 * c]
    return p


def hit(arch, t):
    e = t / 0.2 if t < 0.2 else max(0.0, 1 - (t - 0.2) / 0.8)
    e = e * e * (3 - 2 * e)
    p = {"Pelvis": [0, 0, 0, 0, 0, 0.08 * e], "Spine": [18 * e], "Chest": [14 * e], "Head": [26 * e]}
    if arch in ("biped", "floater"):
        p["UpperArm.L"], p["UpperArm.R"] = [25 * e], [25 * e]
    elif arch == "flyer":
        p["WingInner.L"], p["WingInner.R"] = [0, 0, -30 * e], [0, 0, 30 * e]
    elif arch == "quadruped":
        p["FrontUpperLeg.L"], p["FrontUpperLeg.R"] = [15 * e], [15 * e]
    return p


def death(arch, t):
    e = t * t * (3 - 2 * t)
    p = {"Pelvis": [0, 0, 0, 0, -0.35 * e, -0.08 * e], "Spine": [-50 * e], "Chest": [-35 * e], "Head": [-40 * e]}
    if arch == "biped":
        p["UpperLeg.L"], p["UpperLeg.R"] = [50 * e], [50 * e]
        p["LowerLeg.L"], p["LowerLeg.R"] = [-90 * e], [-90 * e]
        p["UpperArm.L"], p["UpperArm.R"] = [12 * e], [12 * e]
    elif arch == "quadruped":
        p["FrontUpperLeg.L"], p["FrontUpperLeg.R"] = [40 * e], [40 * e]
        p["HindUpperLeg.L"], p["HindUpperLeg.R"] = [-40 * e], [-40 * e]
    elif arch == "flyer":
        p["WingInner.L"], p["WingInner.R"] = [0, 0, 50 * e], [0, 0, -50 * e]
    else:
        p["UpperArm.L"], p["UpperArm.R"] = [0, 0, 30 * e], [0, 0, -30 * e]
    return p


RECIPE = {"Walk": walk, "Hit": hit, "Death": death}


def sample(arch, clip, t):
    """Pose at t seconds (Walk wraps; Hit and Death clamp)."""
    length, _, loop = LENGTH[clip]
    u = (t % length) / length if loop else min(max(t / length, 0.0), 1.0)
    return RECIPE[clip](arch, u if clip != "Hit" else u * length)  # Hit recipe takes seconds


def clip_data(arch):
    out = {}
    for clip, (length, steps, loop) in LENGTH.items():
        keys = []
        for i in range(steps + 1):
            if loop and i == steps:
                break
            t = length * i / steps
            keys.append({"t": round(t, 4), "pose": sample(arch, clip, t)})
        out[clip] = {"length": length, "loop": loop, "keys": keys}
    return out
