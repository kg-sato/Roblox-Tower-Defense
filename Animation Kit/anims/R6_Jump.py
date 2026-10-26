"""R6 jump, snappy: one-shot takeoff -> rise, 15 frames (the apex of a default jump is ~f15). Method by fwjelaa.

Roblox launches the body the moment Space is pressed, so there is no crouch: frame 0 is already the
push-off (toes on the floor, arms swinging up from low). Then:
  push (0) --quad_out--> extreme (body 5, arms 6): arms thrown up, right knee driven high, left leg trailing
  --> follow-through (9 / 10): arms and knee carry on a little past it
  --> moving hold into the fall silhouette (15), which R6_Fall picks up in the cross-fade.
The arms trail the body by a frame (overlap), which also keeps the throw under 40 deg per frame.
Airborne poses are not grounded; the body rides up on the HumanoidRootPart (py) for extra pop.
"""
import animkit as ak
from _move import AIR, compose

NAME = "R6_Jump"
LENGTH = 15
ARMS = ("Right Arm", "Left Arm")


def only(pose, joints, keep=True):
    return {j: v for j, v in pose.items() if (j in joints) == keep}


def build():
    a = ak.Anim(NAME, rig="R6", length=LENGTH, priority="Movement", slides=True)
    push = compose(lean_x=-6, head=(4, 0, 0), arms=((40, 0, 8), (30, 0, -8)),
                   legs=((-4, 0, 2), (-12, 0, -2)))  # toes still on the floor: grounded
    extreme = compose(lean_x=4, head=(10, 0, 0), arms=((168, 0, 10), (150, 0, -13)),
                      legs=((58, 0, 4), (-26, 0, -4)), ground=False, py=0.24)
    follow = compose(lean_x=6, head=(8, 0, 0), arms=((176, 0, 12), (160, 0, -15)),
                     legs=((64, 0, 5), (-30, 0, -5)), ground=False, py=0.3)
    (ra, la), (rl, ll) = AIR["arms"], AIR["legs"]
    apex = compose(lean_x=AIR["lean_x"], head=(-2, 0, 0), arms=((ra[0] + 4, 0, ra[2]), (la[0] + 4, 0, la[2])),
                   legs=((rl[0] + 8, 0, rl[2]), (ll[0] - 3, 0, ll[2])), ground=False, py=AIR["py"])

    # body: the launch is fastest at the start and decelerates into the extreme
    a.key(0, only(push, ARMS, keep=False), ease="quad_out")
    a.key(5, only(extreme, ARMS, keep=False), ease="cubic_inout")
    a.key(9, only(follow, ARMS, keep=False), ease="cubic_inout")
    a.key(LENGTH, only(apex, ARMS, keep=False), ease="linear")
    # arms: one frame behind the body
    a.key(0, only(push, ARMS), ease="quad_out")
    a.key(6, only(extreme, ARMS), ease="cubic_inout")
    a.key(10, only(follow, ARMS), ease="cubic_inout")
    a.key(LENGTH, only(apex, ARMS), ease="linear")
    a.offset("Head", 2)
    return a
