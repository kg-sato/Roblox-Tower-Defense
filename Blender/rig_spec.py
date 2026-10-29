"""Rig templates for the familiars (T106): one shared core chain plus per-archetype limbs. Pure Python (no bpy), used by Blender/rig_template.py and tools/verify_rig_templates.py.
Core chain, identical in every template (so one idle, attack, spawn or banish clip can drive any familiar): Root > Pelvis > Spine > Chest > Neck > Head.
Archetypes: biped (arms and legs), quadruped (four legs, tail), flyer (two wings, tail), floater (no legs: a hanging trail and short arms).
Positions are fractions of the model's bounding box: x = lateral, in half-widths from the centre (negative is the character's right, .L bones use positive x);
y = depth, in half-depths from the centre (negative is forward, the model faces -Y in Blender); z = height from the feet (0) to the top (1).
Names use '.L' and '.R'; the right bone is the left bone with x negated. Bone count stays well under Roblox's limit for one skinned mesh (about 150)."""

CORE = [
    ("Root", None, (0, 0, 0.0), (0, 0, 0.08)),
    ("Pelvis", "Root", (0, 0, 0.38), (0, 0, 0.50)),
    ("Spine", "Pelvis", (0, 0, 0.50), (0, 0, 0.65)),
    ("Chest", "Spine", (0, 0, 0.65), (0, 0, 0.78)),
    ("Neck", "Chest", (0, 0, 0.78), (0, 0, 0.86)),
    ("Head", "Neck", (0, 0, 0.86), (0, 0, 1.0)),
]
CORE_NAMES = [b[0] for b in CORE]

# limbs listed for the left side only; mirror() adds the right side
_LIMBS = {
    "biped": [
        ("UpperArm.L", "Chest", (0.55, 0, 0.74), (0.85, 0, 0.55)),
        ("LowerArm.L", "UpperArm.L", (0.85, 0, 0.55), (0.95, 0, 0.36)),
        ("UpperLeg.L", "Pelvis", (0.30, 0, 0.40), (0.30, 0, 0.20)),
        ("LowerLeg.L", "UpperLeg.L", (0.30, 0, 0.20), (0.30, 0, 0.02)),
    ],
    "quadruped": [
        ("FrontUpperLeg.L", "Chest", (0.40, -0.45, 0.45), (0.40, -0.45, 0.22)),
        ("FrontLowerLeg.L", "FrontUpperLeg.L", (0.40, -0.45, 0.22), (0.40, -0.45, 0.02)),
        ("HindUpperLeg.L", "Pelvis", (0.40, 0.45, 0.45), (0.40, 0.45, 0.22)),
        ("HindLowerLeg.L", "HindUpperLeg.L", (0.40, 0.45, 0.22), (0.40, 0.45, 0.02)),
    ],
    "flyer": [
        ("WingInner.L", "Chest", (0.30, 0.10, 0.72), (0.65, 0.10, 0.80)),
        ("WingOuter.L", "WingInner.L", (0.65, 0.10, 0.80), (1.00, 0.10, 0.86)),
    ],
    "floater": [
        ("UpperArm.L", "Chest", (0.40, 0, 0.72), (0.80, 0, 0.55)),
    ],
}
_CENTRE = {
    "biped": [],
    "quadruped": [
        ("Tail1", "Pelvis", (0, 0.40, 0.45), (0, 0.75, 0.45)),
        ("Tail2", "Tail1", (0, 0.75, 0.45), (0, 1.00, 0.50)),
    ],
    "flyer": [
        ("Tail1", "Pelvis", (0, 0.30, 0.40), (0, 0.65, 0.32)),
        ("Tail2", "Tail1", (0, 0.65, 0.32), (0, 1.00, 0.22)),
    ],
    "floater": [
        ("Trail1", "Pelvis", (0, 0.10, 0.38), (0, 0.20, 0.20)),
        ("Trail2", "Trail1", (0, 0.20, 0.20), (0, 0.30, 0.05)),
    ],
}

# which template each familiar uses (reason in the design note Roblox Dev/Design/Rig Template.md)
ARCHETYPE = {
    "Ember": "floater", "MothLantern": "flyer", "BrassHound": "quadruped", "Sentinel": "biped",
    "Frostling": "biped", "Gargoyle": "quadruped", "Ward": "biped", "Archivist": "biped",
    "Mourner": "biped", "MirrorChorister": "biped", "StarDrake": "flyer", "GreyVeilWraith": "floater",
    "CantorVesper": "biped", "DameOrrery": "biped", "TheLamplighter": "biped", "VeilWalker": "biped",
    "ConstableWren": "biped", "MadamQuill": "biped", "CogWarden": "biped", "FerrymanOfFog": "biped",
}


def mirror(bones):
    out = []
    for name, parent, h, t in bones:
        out.append((name, parent, h, t))
        if name.endswith(".L"):
            out.append((name[:-2] + ".R", parent[:-2] + ".R" if parent and parent.endswith(".L") else parent, (-h[0], h[1], h[2]), (-t[0], t[1], t[2])))
    return out


def template(archetype):
    """Bones for an archetype: list of (name, parent, head_fraction, tail_fraction), parents always listed before children."""
    return CORE + _CENTRE[archetype] + mirror(_LIMBS[archetype])


def bone_names(archetype):
    return [b[0] for b in template(archetype)]
