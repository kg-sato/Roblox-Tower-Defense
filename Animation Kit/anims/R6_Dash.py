"""R6 forward dash, snappy: one-shot, 24 frames, from the fighting stance back to it. Method by fwjelaa.

  stance (0) --quad_out 3 f--> launch (3): chest drops forward, rear leg drives back, eyes on the target
  --> travel (3-13, a moving hold): deepest and lowest at 8 (the root path dips instead of sliding
      straight), arms thrown back behind the body
  --cubic_out 4 f--> brake (17): lead foot planted, counter-lean back, arms whip forward
  --> settle (20): past the stance by a few degrees --> stance (24).
The arms trail the body by ~2 frames all the way (overlap); the head is keyed with the body so it can
whip forward on the brake (inertia) instead of lagging upward. The lean pivots on the hips (_move.compose
hip_pivot), so the chest lunges ahead while the feet stay under the body. R6 feet only both touch when
the legs tilt about equally, so launch, travel and brake are all near-symmetric lunges.

Markers for the game script (the animation never moves the HumanoidRootPart):
  DashStart (1): apply the velocity (e.g. LinearVelocity ~45 studs/s along the flattened look vector)
  DashEnd (13): first brake frame, kill or decay the velocity while the body counter-leans.
"""
import animkit as ak
from _lib import FIGHT_R6
from _move import compose, interp, level_feet

NAME = "R6_Dash"
LENGTH = 24
DASH_START, DASH_END = 1, 13
ARMS = ("Right Arm", "Left Arm")

# frame: (lean, turn, head pitch, rear/right leg (x, z), lead/left leg (x, z)) -- legs as world swing
BODY = {
    3: (-26, -10, 20, (-38, 10), (34, -8)),  # launch: a low lunge, rear toe and lead heel both down
    8: (-32, -7, 26, (-46, 12), (38, -9)),  # mid travel: deepest and lowest (the root path dips)
    13: (-29, -8, 23, (-44, 11), (36, -8)),  # travel end (drift)
    17: (8, -22, -14, (-30, 10), (34, -12)),  # brake: rear foot catches up, counter-lean, head whips forward
    20: (-10, -17, 8, (-20, 10), (16, -8)),  # settle a little past the stance
}
EASE = {0: "quad_out", 3: "bezier", 8: "bezier", 13: "cubic_out", 17: "bezier", 20: "bezier"}
LEVEL = (3, 8, 13, 17)  # both feet on the floor: the slide and the planted brake

# frame: (right arm, left arm) as world (x, z), about 2 frames behind the body
ARMS_WORLD = {
    5: ((-46, 14), (-30, -14)),
    10: ((-76, 18), (-62, -18)),  # thrown back and out, clear of the body silhouette
    14: ((-70, 17), (-56, -17)),
    19: ((40, 2), (64, 6)),
    22: ((62, -14), (80, 10)),
}
ARM_EASE = {0: "quad_out", 5: "bezier", 10: "bezier", 14: "sine_inout", 19: "bezier", 22: "bezier"}

LEAN = {0: FIGHT_R6["Torso"][0], **{f: v[0] for f, v in BODY.items()}, LENGTH: FIGHT_R6["Torso"][0]}


def body(f):
    lean, turn, hx, (rx, rz), (lx, lz) = BODY[f]
    pose = compose(lean_x=lean, turn=turn, head=(hx, 0, 0), legs=((rx, 0, rz), (lx, 0, lz)), hip_pivot=True)
    return level_feet(pose) if f in LEVEL else pose


def arms(f):
    (rx, rz), (lx, lz) = ARMS_WORLD[f]
    lean = interp(LEAN, f)
    return {"Right Arm": (rx - lean, 0, rz), "Left Arm": (lx - lean, 0, lz)}


def build():
    a = ak.Anim(NAME, rig="R6", length=LENGTH, priority="Action", slides=True)
    a.full(0, FIGHT_R6, ease=EASE[0])
    for f in BODY:
        a.key(f, {j: v for j, v in body(f).items() if j not in ARMS}, ease=EASE[f])
    for f in ARMS_WORLD:
        a.key(f, arms(f), ease=ARM_EASE[f])
    a.key(0, {j: FIGHT_R6[j] for j in ARMS}, ease=ARM_EASE[0])
    a.full(LENGTH, FIGHT_R6, ease="linear")
    a.marker(DASH_START, "DashStart").marker(DASH_END, "DashEnd")
    return a
