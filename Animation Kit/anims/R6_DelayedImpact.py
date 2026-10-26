"""R6 delayed-impact punch (JJS "Divergent Fist" style): the fist lands, stays buried for a held beat, then a
second, bigger burst drives through. Snappy, priority Action (method by fwjelaa).

Frames at 60 fps (66 f = 1.1 s):
  0   fight stance
  6   DRAW      torso turns away, rear fist drops back, lead hand reaches out to measure; lead foot comes up
  11  COCK      fist thrown back and out, weight on the rear leg, lead knee up (R6: leg swung forward)
  13            a 2-frame trembling hold at the extreme (the telegraph), then 2 frames into
  15  Hit "1"   the lead foot stomps down a step forward as the fist lands: solid, but not everything yet
  19-29         THE DELAY: the fist stays buried; the body locks up and trembles on 2s (constant keys), tension
                building, eyes on the target
  31            a tiny re-load: shoulders draw back a few degrees, head dips (the in-breath before the burst)
  33  Hit "2"   BURST + BlackFlash: hips and shoulders drive forward again, deeper over the front foot, the
                fist punches through and up, the rear arm is torn back. Keyed on 2s with constant keys (anime
                impact frames: it pops in, no in-between), where beat 1 was a smooth smear
  35-45         impact hold, trembling on 2s and dying down (the game adds hit-stop and the black flash VFX)
  51-60         recovery: pull back, then the lead foot steps back home (lifted, never slid)
  66  fight stance
Game side: hit-stop 6-8 f on "1", 15-24 f on "2" (GGST's mid counter freezes 21 f), knockback + VFX on BlackFlash.
"""
import animkit as ak
from _moves import P, SPOTS, STANCE, feet, lock, past, smear, spot, step, strike, tremble

NAME = "R6_DelayedImpact"

L0 = SPOTS["Left Leg"]
L_IN = spot("Left Leg", dx=-0.25, dz=-0.6)  # the lead foot's step forward (and a little out: a wider base)
IN = feet(left=L_IN)

DRAW = dict(yaw=-36, pitch=-2, pz=0.08, head=(-2, 0, 0), look=0.9, r=(-12, 0, 28), l=(86, 0, -26),
            spots=feet(left=step(L0, L_IN, 0.3, 0.2)))
# the chamber: weight back on the rear leg, lead knee up (R6: the leg swings forward), fist cocked behind
COCK = dict(yaw=-50, pitch=6, pz=0.34, head=(-4, 0, 0), look=0.95, r=(-66, 0, 40), l=(92, 0, -38),
            spots=feet(left=(L_IN[0], -1.1, 0.5)))
COCK_HOLD = dict(COCK, yaw=-54, pitch=7, pz=0.38, r=(-74, 0, 42), l=(94, 0, -40),
                 spots=feet(left=(L_IN[0], -1.14, 0.46)))
# beat 1: a solid straight, not everything yet
HIT1 = dict(yaw=24, pitch=-12, pz=-0.25, head=(-2, 0, 0), look=0.85, r=(96, 10, 20), l=(-10, 0, -22), spots=IN)
LOADED = dict(HIT1, yaw=22, pitch=-12, pz=-0.22, r=(95, 10, 19), l=(-13, 0, -22))  # locked up, tension building
RELOAD = dict(HIT1, yaw=15, pitch=-8, pz=-0.14, head=(-8, 0, 0), r=(92, 8, 15), l=(-18, 0, -20))
# beat 2: everything. Hips far forward and down, shoulders unwound, the fist drives through and up
HIT2 = dict(yaw=40, pitch=-30, pz=-0.85, head=(6, 0, 0), look=0.85, r=(114, 26, 36), l=(-62, 0, -24), spots=IN)
SETTLED = dict(HIT2, yaw=38, pitch=-28, pz=-0.8, r=(110, 26, 35), l=(-56, 0, -24))
PULL = dict(yaw=10, pitch=-10, pz=-0.28, head=(0, 0, 0), look=0.8, r=(56, 0, 6), l=(34, 0, -8), spots=IN)
LIFT = dict(yaw=-6, pitch=-6, pz=-0.04, head=(2, 0, 0), look=0.7, r=(60, 0, -10), l=(64, 0, 6),
            spots=feet(left=step(L_IN, L0, 0.5, 0.3)))
HOME = dict(yaw=-16, pitch=-6, pz=0.0, head=(4, 0, 0), look=0.6, r=(62, 0, -14), l=(76, 0, 10), spots=feet())


def build():
    a = ak.Anim(NAME, rig="R6", length=66, priority="Action")
    a.full(0, STANCE, ease="quad_out")
    a.full(6, P(DRAW), ease="cubic_out")  # slow into the cock: it has to read
    a.full(11, P(COCK), ease="linear")
    a.full(13, P(COCK_HOLD), ease="cubic_in")
    strike(a, 15, COCK_HOLD, HIT1, "1", mid=smear(COCK_HOLD, HIT1, 0.38, r=(34, 10, 10), l=(44, 0, -18)))

    # the delay: buried fist, body locked and trembling on 2s
    tremble(a, 19, 29, HIT1, LOADED, amp=(0.012, 0.024), deg=(0.4, 0.8), seed=1, end_ease="cubic_out")
    # the burst is "limited animation" (Guilty Gear Xrd: every frame a key frame): no in-between at all. The
    # re-load holds 2 frames, the impact pops in on one frame and holds 2, then the overshoot, all on 2s
    a.full(31, P(RELOAD), ease="constant")
    a.full(33, P(HIT2), ease="constant").marker(33, "Hit", "2").marker(33, "BlackFlash")
    over2 = past(RELOAD, HIT2, 1.06)

    # impact hold: the shake dies down, then recover and step home
    tremble(a, 35, 45, over2, SETTLED, amp=(0.04, 0.01), deg=(1.2, 0.4), seed=4, end_ease="cubic_inout")
    a.full(51, P(PULL), ease="cubic_inout")
    a.full(55, P(LIFT), ease="cubic_inout")
    a.full(60, P(HOME), ease="cubic_out")
    a.full(66, STANCE, ease="linear")

    lock(a, "Right Leg", (0, 66))
    lock(a, "Left Leg", (15, 51), (60, 66))
    return a
