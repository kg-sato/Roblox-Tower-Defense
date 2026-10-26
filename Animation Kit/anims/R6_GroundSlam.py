"""R6 ground slam, snappy (Hunter's Grasp stomp / Crushing Blow / Metal Bat smash feel): one-shot, 64 frames,
fighting stance to fighting stance. Method by fwjelaa.

  stance (0) --> load (5): weight rocks back onto the rear (right) foot, arms swing back
  --> knee up (10-15): the lead knee rises, both fists sweep up overhead, back arched, eyes on the target
  --> hold (15-18, a moving hold: the fists cock further back, the telegraph)
  --quad_in 4 f--> IMPACT (22): the lead foot stomps far forward into a deep split, the body lunges down after
      it, chest folded over the front knee, both fists driven into the floor in front: Hit + Shockwave
  --> compress (24) --> low hold (24-31, drifting) --> push off the floor, chest up (31-37)
  --> the lead foot lifts and steps back in (38-46) while the body rises over the rear foot
  --> land in the stance and absorb (47) --> stance (64).

The rear foot never leaves its stance spot: the slam lunges forward off it and the recovery comes back to it,
so nothing skates and nothing hops. Every frame is built exactly: the hips are placed relative to the rear
foot (HIP), the rear leg is solved onto its spot, the lead leg is either planted (0-6, 22-37, 47-64) or swung
free (LEAD), and the pose is put on the floor. Keying every frame also keeps the hips on their true arc while
they swing over the rear foot (two keys would cut the corner and sink that foot into the floor).

Why a split: R6 legs are rigid 2-stud boxes and its arms reach 1.5 studs below the shoulder, so the fists only
touch the floor when the hips are about 1.4 studs up: legs ~76 deg apart front to back, chest folded ~60 deg.
It reads as the R6 "superhero landing": the front leg is the raised thigh, the back leg the knee down.

Markers: Hit and Shockwave (22) on the impact: hit-stop 8-12 f, camera shake, rocks / crater VFX.
"""
import animkit as ak
from _lib import FIGHT_R6
from _move import compose, level_feet
from _moves2 import FLOOR, ground_on, lowest, track

NAME = "R6_GroundSlam"
LENGTH = 64
HIT = 22
LEAD_DOWN = ((0, 6, "stance"), (HIT, 37, "slam"), (46, LENGTH, "stance"))  # lead foot planted (frames)

# {frame: value}: a smooth curve through the keys, or (value, ease) to shape the stretch after that key.
LEAN = {0: -6, 5: -16, 10: 2, 15: 8, 18: (12, "quad_in"), 22: (-60, "linear"), 24: (-64, "cubic_out"),
        31: -61, 37: -42, 40: -30, 44: -12, 47: -14, 52: -4, LENGTH: -6}
TURN = {0: -18, 5: -16, 10: -12, 15: -8, 18: (-6, "quad_in"), 22: -8, 37: -9, 41: -11, 44: -14, 47: -18,
        LENGTH: -18}
HEAD = {0: 4, 5: 14, 10: 6, 15: -2, 18: (-6, "quad_in"), 22: (52, "linear"), 24: (48, "cubic_out"), 31: 52,
        37: 34, 40: 26, 44: 12, 47: 9, 52: 2, LENGTH: 4}  # pitch, relative (up +): eyes on the target

# hip centre relative to the rear sole (x, z studs; z - = ahead of it). In the stance it sits ~1 stud ahead of
# the rear foot; standing on that foot alone it has to come back over it (x -0.5 puts the rear leg upright).
# "stance" / "slam" are read off the real poses in build().
HIP = {0: "stance", 5: (-0.64, -0.9), 8: (-0.5, -0.45), 10: (-0.5, -0.4), 15: (-0.48, -0.34),
       18: ((-0.48, -0.3), "quad_in"),
       22: ("slam", "linear"), 24: "slam", 31: "slam", 37: ("slam", "cubic_in"), 40: (-0.45, -1.45),
       43: (-0.6, -1.0), 46: "stance", LENGTH: "stance"}

# the lead (left) leg while it is off the floor, as a world swing (x forward, z out); 6, 37 and 47 are read
# off the planted poses so lift-off and touch-down join up
LEAD = {8: (36, 0, -8), 10: (46, 0, -8), 15: (70, 0, -10), 18: ((76, 0, -12), "quad_in"), 40: (66, 0, -10),
        43: (46, 0, -9), 45: (38, 0, -8)}

# arms as world swings: x from straight down (+ forward, 180 = straight up), z out
RIGHT_ARM = {0: (56, 0, -14), 5: (-38, 0, 14), 10: (70, 0, 4), 15: (166, 0, -13),
             18: ((178, 0, -12), "quad_in"), 22: ((16, 0, -8), "linear"), 24: ((13, 0, -8), "cubic_out"),
             31: (15, 0, -8), 37: (2, 0, 20), 41: (34, 0, 14), 44: (50, 0, -2), 47: (50, 0, -10),
             52: (58, 0, -14), LENGTH: (56, 0, -14)}
LEFT_ARM = {0: (72, 0, 10), 5: (-32, 0, -14), 10: (76, 0, -4), 15: (166, 0, 13),
            18: ((178, 0, 12), "quad_in"), 22: ((16, 0, 8), "linear"), 24: ((13, 0, 8), "cubic_out"),
            31: (15, 0, 8), 37: (2, 0, -20), 41: (44, 0, -12), 44: (62, 0, 6), 47: (64, 0, 12),
            52: (74, 0, 10), LENGTH: (72, 0, 10)}

SLAM = dict(lean=-60, turn=-8, legs=((-76, 0, 12), (76, 0, -12)))  # the split itself


def _hip(pose):
    """Hip centre (x, z) of a pose, HumanoidRootPart space."""
    from mathutils import Vector
    import rigs
    t = ak._pad(pose["Torso"])
    h = rigs.angles(*t[:3]).to_3x3() @ Vector((0, -1, 0))
    return t[3] + h.x, t[5] + h.z


def _world_leg(pose, leg="Left Leg"):
    """A leg's pose-language value back as compose()'s world swing (undo the lean and the turn)."""
    x, y, z = pose[leg][:3]
    t = ak._pad(pose["Torso"])
    return (x + t[0], y + t[1], z)


def build():
    stance = ak.soles(FIGHT_R6)
    rear, lead = stance["Right Leg"], "Left Leg"
    slam = level_feet(compose(lean_x=SLAM["lean"], turn=SLAM["turn"], legs=SLAM["legs"], ground=False,
                              hip_pivot=True))
    sole = ak.soles(slam)["Right Leg"]  # slide the split so its rear sole sits on the rear stance spot
    t = list(ak._pad(slam["Torso"]))
    t[3], t[5] = t[3] + rear[0] - sole[0], t[5] + rear[2] - sole[2]
    slam = dict(slam, Torso=tuple(t))
    spots = {"stance": stance, "slam": ak.soles(slam)}
    ref = {"stance": _hip(FIGHT_R6), "slam": _hip(slam)}

    def resolve(table):
        out = {}
        for f, v in table.items():
            v, ease = (v if isinstance(v, tuple) and len(v) == 2 and isinstance(v[1], str) else (v, None))
            if isinstance(v, str):
                v = (ref[v][0] - rear[0], ref[v][1] - rear[2])
            out[f] = (v, ease) if ease else v
        return out

    hip_track = resolve(HIP)
    lead_track = dict(LEAD)
    lead_track[6] = _world_leg(FIGHT_R6)
    lead_track[37] = _world_leg(slam)
    lead_track[46] = _world_leg(FIGHT_R6)

    a = ak.Anim(NAME, rig="R6", length=LENGTH, priority="Action")
    for f in range(1, LENGTH):
        down = next((where for s, e, where in LEAD_DOWN if s <= f <= e), None)
        lean, turn = track(LEAN, f), track(TURN, f)
        pose = compose(lean_x=lean, turn=turn, head=(track(HEAD, f), 0, 0),
                       arms=(track(RIGHT_ARM, f), track(LEFT_ARM, f)),
                       legs=((-12, 0, 10), track(lead_track, f)), ground=False)
        hx, hz = track(hip_track, f)
        ox, oz = _hip(dict(pose, Torso=ak._pad(pose["Torso"])[:3] + (0, 0, 0)))
        tt = list(ak._pad(pose["Torso"]))
        tt[3], tt[5] = rear[0] + hx - ox, rear[2] + hz - oz  # put the hip centre where HIP says
        pose = dict(pose, Torso=tuple(tt))
        if down:
            pose = ak.plant(pose, spots[down])  # both feet on their spots, then on the floor
        else:
            pose = ak.plant(pose, {"Right Leg": rear}, legs=("Right Leg",), grounded=False)
            pose = ground_on(pose, ("Right Leg",))
            assert lowest(pose, (lead,)) > FLOOR - 0.08, f"lead foot goes through the floor on frame {f}"
        a.key(f, pose, ease="linear")
    a.key(0, FIGHT_R6, ease="linear").key(LENGTH, FIGHT_R6, ease="linear")
    a.marker(HIT, "Hit").marker(HIT, "Shockwave")
    a.lock_feet(0, LENGTH, legs=("Right Leg",), targets=stance)  # the rear foot never moves
    for start, end, where in LEAD_DOWN:
        a.lock_feet(start, end, legs=(lead,), targets=spots[where])
    return a
