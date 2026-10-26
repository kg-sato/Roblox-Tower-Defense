"""R6 barrage + straight finisher (TSB "Consecutive Punches" / JJS flurry style). Snappy, priority Action
(method by fwjelaa).

The rush is "limited animation" (Guilty Gear Xrd: every frame is a key frame): every pose is held for 2 frames
with the constant ease, so in the game it strobes on 2s like an anime barrage instead of sliding smoothly.
The feet stay planted in the fight stance the whole time; the torso rocks around a slightly bladed centre.
Frames at 60 fps (118 f = 2 s):
  0   fight stance
  4   GATHER    the in-breath: guard pulled tight to the chin, chest up
  8   SET       sink and hunch forward, shoulders square, fists chambered low. TrailOn (trails / afterimages)
  10-64 Hit 1-10  ten alternating straights 6 f apart (R, L, R...), each on 2s: contact (held 2 f) -> recoil
                (the arm that hit snaps back) -> passing (the next fist already on its way) -> next contact.
                The torso rocks +-23 deg with every punch, heights and aims change so no two land alike
  71  COCK      the finisher's wind-up: shoulders thrown the other way, right fist cocked behind
  71-74         a trembling 3-frame telegraph, then 2 frames into
  76  Hit final big right straight: hips driven forward over the lead foot, rear arm torn back; a 16-frame
                trembling hold, TrailOff at its end
  94-118        recovery to the fight stance
Game side: 1-2 f of hit-stop (or none) and an afterimage per numbered Hit; 10-12 f on "final" + knockback.
"""
import animkit as ak
from _moves import P, STANCE, feet, lock, smear, strike, tremble

NAME = "R6_Barrage"

ST = feet()  # the fight stance's own spots: nothing steps
C = -5  # the torso rocks around a slightly bladed centre (square on R6's left-foot-forward stance)

GATHER = dict(yaw=-10, pitch=-4, pz=0.06, head=(2, 0, 0), look=0.9, r=(72, 0, -16), l=(76, 0, 10), spots=ST)
SET = dict(yaw=C, pitch=-16, pz=-0.3, head=(-6, 0, 0), look=0.9, r=(38, 0, -6), l=(40, 0, 4), spots=ST)

FIRST, GAP, COUNT = 10, 6, 10
HITS = [FIRST + GAP * k for k in range(COUNT)]
SIDES = "RL" * (COUNT // 2)
HEIGHT = (100, 106, 96, 108, 102, 94, 108, 100, 104, 98)  # world swing of the punching arm (90 = level)
AIM = (0, 4, -4, 2, -2, 4, 0, -4, 2, 0)  # degrees sideways, so the fists land all over the target
PZ = {"R": -0.32, "L": -0.5}  # the left-side turn stands taller on this stance: drive it further in


def contact(k):
    """Punch k landing: a big shoulder turn behind the fist, the other fist yanked back to the hip."""
    hx, dz, side = HEIGHT[k], AIM[k], SIDES[k]
    if side == "R":
        return dict(yaw=C + 23, pitch=-16, pz=PZ[side], head=(-4, 0, 0), look=0.9, r=(hx, 10, 18 + dz),
                    l=(26, 0, -14), spots=ST)
    return dict(yaw=C - 23, pitch=-16, pz=PZ[side], head=(-4, 0, 0), look=0.9, r=(26, 0, 14),
                l=(hx, -10, -26 + dz), spots=ST)


def recoil(k):
    """2 f after punch k: the arm that hit snaps back (about 30 deg), the other is already coming."""
    hx, side = HEIGHT[k], SIDES[k]
    pz = PZ[side] + 0.08
    if side == "R":
        return dict(yaw=C + 10, pitch=-15, pz=pz, head=(-4, 0, 0), look=0.9, r=(hx - 30, 6, 10), l=(44, 0, -8),
                    spots=ST)
    return dict(yaw=C - 10, pitch=-15, pz=pz, head=(-4, 0, 0), look=0.9, r=(44, 0, 8), l=(hx - 30, -6, -16),
                spots=ST)


def passing(k):
    """4 f after punch k: the shoulders pass square, the next fist is halfway out."""
    pz = (PZ["R"] + PZ["L"]) / 2 + 0.12
    if SIDES[k] == "R":
        return dict(yaw=C - 6, pitch=-15, pz=pz, head=(-4, 0, 0), look=0.9, r=(40, 0, 10), l=(72, -4, -16), spots=ST)
    return dict(yaw=C + 6, pitch=-15, pz=pz, head=(-4, 0, 0), look=0.9, r=(72, 4, 10), l=(40, 0, -10), spots=ST)


COCK = dict(yaw=-46, pitch=-4, pz=0.14, head=(-4, 0, 0), look=0.95, r=(-36, 0, 28), l=(90, 0, -40), spots=ST)
COCK_HOLD = dict(COCK, yaw=-50, pz=0.17, r=(-42, 0, 30), l=(92, 0, -42))
FINAL = dict(yaw=30, pitch=-24, pz=-0.80, head=(4, 0, 0), look=0.85, r=(100, 30, 38), l=(-50, 0, -24), spots=ST)
FINAL_END = dict(FINAL, yaw=28, pitch=-22, pz=-0.74, r=(97, 30, 37), l=(-44, 0, -24))
PULL = dict(yaw=4, pitch=-10, pz=-0.3, head=(0, 0, 0), look=0.8, r=(58, 0, 0), l=(40, 0, -4), spots=ST)
HOME = dict(yaw=-15, pitch=-7, pz=-0.04, head=(4, 0, 0), look=0.6, r=(64, 0, -14), l=(78, 0, 10), spots=ST)


def build():
    a = ak.Anim(NAME, rig="R6", length=118, priority="Action")
    a.full(0, STANCE, ease="quad_out")
    a.full(4, P(GATHER), ease="cubic_in")  # accelerate into the set
    a.full(8, P(SET), ease="constant").marker(8, "TrailOn")

    # the rush, on 2s
    for k, f in enumerate(HITS):
        a.full(f, P(contact(k)), ease="constant").marker(f, "Hit", str(k + 1))
        a.full(f + 2, P(recoil(k)), ease="constant" if k + 1 < COUNT else "quad_out")
        if k + 1 < COUNT:
            a.full(f + 4, P(passing(k)), ease="constant")

    # the finisher: wind the other way, telegraph, then the big one
    last = HITS[-1]
    a.full(last + 7, P(COCK), ease="linear")
    tremble(a, last + 7, last + 10, COCK, COCK_HOLD, every=1, amp=(0.02, 0.02), deg=(0.8, 0.8), end_ease="cubic_in")
    fin = last + 12
    over = strike(a, fin, COCK_HOLD, FINAL, "final", mid=smear(COCK_HOLD, FINAL, 0.42, r=(36, 10, 8), l=(30, 0, -16)),
                  over=1.06)
    tremble(a, fin + 2, fin + 18, over, FINAL_END, amp=(0.04, 0.008), deg=(1.2, 0.3), seed=3, end_ease="cubic_inout")
    a.marker(fin + 18, "TrailOff")

    # recovery: the punching arm comes back first, then the body settles into the guard
    a.full(fin + 28, P(PULL), ease="cubic_inout")
    a.full(fin + 36, P(HOME), ease="cubic_out")
    a.full(118, STANCE, ease="linear")

    lock(a, "Right Leg", (0, 118))
    lock(a, "Left Leg", (0, 118))
    return a
