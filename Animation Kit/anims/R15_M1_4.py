"""R15 M1 hit 4, snappy: rising uppercut finisher (the launcher). Method by fwjelaa.

Finisher timeline (the R6 combo's: wind-up 10 with a 3-frame telegraph, strike 3, hold 5, recover 24),
44 frames:
  stance -> dip f7 (sink low on bent knees, hips and chest coil right and fold forward, the rear fist
     drops to the hip) -> telegraph hold f7-f10 (still sinking a touch, never frozen)
  -> scoop f12 (legs pushing, the fist swings forward past the belly)
  -> strike f13, Hit marker "4": the legs drive up onto the toes, hips and chest unwind and lean back,
     the rear fist rises from the hip in front of the chin with the elbow bent ~100 deg
  -> apex f16 (a small hop: both feet leave the floor, the fist carries on above the head)
  -> land f20 (knees absorb on the stance spots) -> recover to stance f44.
"""
from _m1r15 import clip, on_legs, toe
from _r15 import fighter, reach

NAME = "R15_M1_4"


def poses():
    stance = fighter()
    dip = on_legs(
        (100, 92),
        hips=(-6, -50, 0), move=(0, 0, 0.12), chest=(-20, -6, -8), head=(16, 50, 0),
    )
    reach(dip, "Left", (0.35, 0.5, -1.45), elbow=(-0.3, -1, 0.2))  # lead fist tight in front of the face
    reach(dip, "Right", (1.25, -1.15, -0.05), elbow=(0.3, -0.3, 1))  # fist low by the hip, elbow back
    dip2 = on_legs(  # telegraph: a moving hold, sinking and coiling a touch more
        (104, 96),
        hips=(-7, -53, 0), move=(0, 0, 0.13), chest=(-21, -7, -9), head=(17, 53, 0),
    )
    reach(dip2, "Left", (0.35, 0.45, -1.45), elbow=(-0.3, -1, 0.2))
    reach(dip2, "Right", (1.27, -1.2, 0.0), elbow=(0.3, -0.3, 1))
    rise = on_legs(  # mid-drive: legs pushing, hips unwinding, the fist scooping past the belly
        (72, 66),
        hips=(-4, -24, 0), move=(0, 0, 0.0), chest=(-10, 4, 0), head=(12, 18, 0),
        rear_foot=toe("Right", -40, -10),
        lead_fist=((-0.8, 0.85, -1.15), (-0.4, -1, 0.2)),
    )
    reach(rise, "Right", (1.3, -0.5, -1.1), elbow=(0.3, -0.6, 0.8))
    contact = on_legs(
        (10, 12),
        hips=(-2, 4, 0), move=(0, 0, -0.08), chest=(4, 30, 8), head=(6, -30, 0),
        lead_foot=toe("Left", -18, -20), rear_foot=toe("Right", -32, -34),
        lead_fist=((-0.85, 0.6, -1.0), (-0.4, -1, 0.3)),  # lead fist pulls back to the chest
    )
    reach(contact, "Right", (0.45, 1.25, -1.45), elbow=(0.15, -1, -0.3))  # forearm upright, elbow under it
    apex = on_legs(
        (16, 20),
        hips=(0, 8, 0), move=(0, 0, -0.1), chest=(10, 34, 10), head=(12, -36, 0),
        lead_foot=toe("Left", -18, -30, lift=0.3), rear_foot=toe("Right", -36, -40, lift=0.3),
    )
    reach(apex, "Left", (-1.45, 0.1, -0.2), elbow=(-0.4, -1, 0.4))  # lead fist yanked down to the side
    reach(apex, "Right", (0.55, 2.55, -0.38), elbow=(0.2, -0.3, -1))  # fist above the head, elbow bent
    land = on_legs(
        (80, 76),
        hips=(-6, 0, 0), move=(0, 0, -0.1), chest=(-8, 22, 4), head=(8, -22, 0),
        lead_fist=((-0.85, 0.75, -1.1), (-0.4, -1, 0.3)),
    )
    reach(land, "Right", (0.85, 0.95, -1.7), elbow=(0.2, -1, -0.2))
    back = on_legs(  # halfway home: fist lowering to the guard, body coiling back to the right
        (66, 62),
        hips=(-5, -16, 0), move=(0, 0, -0.06), chest=(-12, 10, 1), head=(8, 6, 0),
        lead_fist=((-0.8, 0.88, -1.3), (-0.35, -1, 0.1)),
        rear_fist=((0.7, 1.05, -1.25), (0.4, -1, 0.1)),
    )
    return {"stance": stance, "dip": dip, "dip2": dip2, "rise": rise, "contact": contact, "apex": apex,
            "land": land, "back": back}


def build():
    p = poses()
    return clip(NAME, [
        (0, p["stance"], "quad_out"),  # decelerate into the dip
        (7, p["dip"], "linear"),  # telegraph: a moving hold at the bottom
        (10, p["dip2"], "cubic_in"),  # then explode: the biggest jump is the last frame
        (12, p["rise"], "linear"),
        (13, p["contact"], "linear"),  # carries straight on up into the top of the hop
        (16, p["apex"], "cubic_in"),  # then fall
        (20, p["land"], "cubic_out"),  # knees absorb the landing
        (30, p["back"], "bezier"),
        (44, p["stance"], "linear"),
    ], hit=13, value="4")
