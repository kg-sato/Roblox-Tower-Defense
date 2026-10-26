"""R6 ultimate: power up, charge, 6-punch rush, finisher. Snappy, priority Action2 (method by fwjelaa).

Frames at 60 fps (188 f = 3.1 s):
  0   Activate    fight stance
  7               gather: fists cross low, head down, weight in            (the in-breath)
  10-13           BURST: a little hop that stomps down into a wide horse stance, chest up, head back,
                  arms thrown open
  24  ChargeStart power stance settles, then the body folds forward into the charge
  32-70           CHARGE: bent low over the wide stance, both arms swept back, eyes on the target; the whole
                  body trembles (root jitter every 2 f, growing from 0.02 to 0.05 studs) as it coils tighter
  70  Release     4 frames, accelerating, into the first punch
  74..108  Hit 1-6  barrage, right/left alternating, 8-7-7-6-6 frames apart (it speeds up)
  118             finisher wind-up: torso coiled 66 deg the other way, right fist cocked behind
  118-121         telegraph (a trembling hold), then 3 frames into
  124 Hit final   FINISHER: 92 deg unwind, hips driven forward, rear arm torn back; a 26-frame trembling hold
  150-188         recovery: pull back, step the right foot in (162), then the left (172), fight stance
From the burst to the end of the hold the feet never leave their spots: R6 hips sit on the torso, so every
pose is solved by _special.body() to keep the soles planted while the torso twists up to 66 degrees.
The game does hit-stop on each Hit (6-10 f) and a long one (15-30 f) on "final", plus camera/VFX on the
Activate / ChargeStart / Release markers. Travel (a dash into the rush) is the game's job, timed on Release.
"""
import animkit as ak
from _lib import FIGHT_R6
from _special import body, feet, mix, shake, shiver, spots_of, strike

NAME = "R6_Ultimate"

SPOTS = feet(rleg=(-18, 0, 34), lleg=(20, 0, -32))  # wide horse stance, lead (left) foot a little forward

# body() recipes: torso yaw (+ = turned left) / pitch (- = forward) / pz (- = hips forward), arms as seen
# in the world (90 = level forward), head pitch in the world with `look` = how much of the turn it undoes.
FIGHT_SPOTS = spots_of(FIGHT_R6)
GATHER = dict(yaw=-6, pitch=-22, head=(-28, 0, 0), look=0.8, r=(34, 0, -34), l=(38, 0, 38), spots=FIGHT_SPOTS)
BURST = dict(yaw=0, pitch=18, head=(36, 0, 0), r=(-24, 0, 62), l=(-24, 0, -62), spots=SPOTS)
POWER = dict(yaw=0, pitch=8, head=(14, 0, 0), r=(-14, 0, 48), l=(-14, 0, -48), spots=SPOTS)
COIL = dict(yaw=-10, pitch=-28, pz=0.05, head=(6, 0, 0), look=0.9, r=(-44, 0, 20), l=(-44, 0, -20), spots=SPOTS)
COIL_END = dict(yaw=-14, pitch=-34, pz=0.08, head=(2, 0, 0), look=0.9, r=(-54, 0, 24), l=(-54, 0, -24),
                spots=SPOTS)

HITS = (74, 82, 89, 96, 102, 108)
SIDES = "RLRLRL"
HEIGHTS = (100, 100, 108, 102, 94, 104)  # a little variety: the 3rd goes high, the 5th to the body


def rush_contact(side, height):
    """Big shoulder turn and a slightly rising fist; the other fist is pulled back and out, so from behind
    the barrage reads as shoulders and elbows pumping."""
    if side == "R":
        return dict(yaw=32, pitch=-20, pz=-0.20, head=(-2, 0, 0), look=0.8,
                    r=(height, 0, -4), l=(28, 0, -14), spots=SPOTS)
    return dict(yaw=-34, pitch=-20, pz=-0.20, head=(-2, 0, 0), look=0.8,
                r=(28, 0, 14), l=(height, 0, -10), spots=SPOTS)


def rush_mid(next_side):
    """Between punches: the torso passes square, the arm that just hit pulls back while the next one cocks."""
    if next_side == "L":
        return dict(yaw=-2, pitch=-18, pz=-0.12, head=(-2, 0, 0), look=0.8, r=(70, 0, -6), l=(30, 0, -8),
                    spots=SPOTS)
    return dict(yaw=-4, pitch=-18, pz=-0.12, head=(-2, 0, 0), look=0.8, r=(30, 0, 8), l=(70, 0, 6),
                spots=SPOTS)


WINDUP = dict(yaw=-64, pitch=-6, pz=0.12, head=(-4, 0, 0), look=0.95, r=(-62, 0, 36), l=(94, 0, -14),
              spots=SPOTS)
WINDUP_HOLD = dict(WINDUP, yaw=-68, pitch=-7, pz=0.14, r=(-68, 0, 38), l=(96, 0, -16))  # coils a bit more
FINAL = dict(yaw=30, pitch=-32, pz=-0.70, head=(6, 0, 0), look=0.85, r=(112, 0, -4), l=(-58, 0, -10),
             spots=SPOTS)


def _halfway(leg, lift):
    """A foot in mid-step from the wide stance back to the fight stance, `lift` studs off the floor."""
    return tuple((a + b) / 2 for a, b in zip(SPOTS[leg], FIGHT_SPOTS[leg])) + (lift,)


# recovery: two real steps back into the fight stance (sliding feet would read as skating)
STEP_R = dict(yaw=6, pitch=-12, pz=-0.35, head=(0, 0, 0), look=0.7, r=(62, 0, -8), l=(8, 0, -14),
              spots={"Right Leg": _halfway("Right Leg", 0.3), "Left Leg": SPOTS["Left Leg"]})
STEP_L = dict(yaw=-8, pitch=-8, pz=-0.15, head=(2, 0, 0), look=0.7, r=(48, 0, -12), l=(40, 0, 6),
              spots={"Right Leg": FIGHT_SPOTS["Right Leg"], "Left Leg": _halfway("Left Leg", 0.3)})


def build():
    a = ak.Anim(NAME, rig="R6", length=188, priority="Action2")

    # 1. activation: gather in, burst open into the power-up stance
    a.full(0, FIGHT_R6, ease="quad_out").marker(0, "Activate")
    a.full(7, body(**GATHER), ease="quad_in")
    a.full(10, body(**mix(GATHER, BURST, 0.5), lift=0.22), ease="linear")  # a little hop...
    a.full(13, body(**BURST), ease="linear")  # ...that stomps down into the wide stance
    a.full(15, body(**mix(POWER, BURST, 1.15)), ease="cubic_out")
    a.full(24, body(**POWER), ease="cubic_in").marker(24, "ChargeStart")
    a.full(28, body(**mix(POWER, COIL, 0.5)), ease="cubic_out")  # cubic in+out = one inout, feet solved midway

    # 2. charge: fold into the coil, then a trembling hold that tightens
    shiver(a, 32, 70, COIL, COIL_END)
    a.full(70, body(**COIL_END), ease="cubic_in").marker(70, "Release")
    a.full(73, body(**mix(COIL_END, rush_contact("R", HEIGHTS[0]), 0.42)), ease="linear")  # solved in-between

    # 3. barrage
    before = COIL_END
    for i, (f, side) in enumerate(zip(HITS, SIDES)):
        contact = rush_contact(side, HEIGHTS[i])
        nxt = HITS[i + 1] if i + 1 < len(HITS) else f + 10
        carry = 2 if nxt - f >= 7 else 1
        quick = nxt - 3 - (f + carry) <= 2  # only 2 frames to pull back: keep it even, no ease spike
        strike(a, f, body(**contact), None, i + 1, carry=carry, out="linear" if quick else "quad_out",
               over_pose=body(**mix(before, contact, 1.12)))
        if i + 1 < len(HITS):
            before = rush_mid(SIDES[i + 1])
            a.full(nxt - 3, body(**before), ease="cubic_in")

    # 4. finisher: wind up the other way, telegraph, then the big one
    a.full(118, body(**WINDUP), ease="linear")
    a.full(121, body(**shake(WINDUP_HOLD, 3, 0.03, 1.0)), ease="cubic_in")
    a.full(123, body(**mix(WINDUP_HOLD, FINAL, 0.42)), ease="linear")  # solved in-between: feet stay put
    over_kw = mix(WINDUP_HOLD, FINAL, 1.06)
    over = strike(a, 124, body(**FINAL), None, "final", over_pose=body(**over_kw))
    settled = mix(FINAL, POWER, 0.06)  # a breath of the power stance: the hold sinks and relaxes
    shiver(a, over, 150, over_kw, settled, every=3, amp=(0.04, 0.005), deg=(1.0, 0.2), seed=5)
    a.full(150, body(**settled), ease="cubic_inout")

    # 5. recovery
    a.full(162, body(**STEP_R), ease="cubic_inout")
    a.full(172, body(**STEP_L), ease="cubic_inout")
    a.full(188, FIGHT_R6, ease="linear")
    return a
