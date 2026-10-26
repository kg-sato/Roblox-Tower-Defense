"""R6 charged punch ("Serious Punch" / SF6 Drive Impact style): a long telegraphed charge, a 2-frame release and
a huge contact pose built for a long hit-stop. Snappy, priority Action2 (method by fwjelaa).

Frames at 60 fps (122 f = 2 s):
  0   fight stance
  5   PLANT     weight rocks back, the lead foot steps out to a longer base (lifted, never slid); the torso starts
                turning away and the right fist drops back
  12  READY     ChargeStart: chest turned 60 deg away from the target, right fist thrown far back and out, lead arm
                aiming, head locked on the target
  12-48         CHARGE: a trembling moving hold on 2s (constant keys: the stepped anime shake), coiling tighter
                (turn -60 -> -68, fist further back, hunching over it) while the shake grows
  48  ChargeEnd the shake stops dead; 3 frames of a last squeeze, then 2 frames into
  53  Hit       IMPACT: 104 deg unwind, hips driven far forward and down over the lead foot, fist straight through
                at the target, rear arm torn back. Hold this frame in the game for the hit-stop (20-30 f)
  55-85         follow-through: the body keeps pushing a little further while the shake dies out
  85-122        recovery: the arm comes back first, the torso follows, the lead foot steps home
Game side: wind/aura VFX between ChargeStart and ChargeEnd (TSB Serious Punch pushes nearby players away there),
impact frames + camera kick + 20-30 f hit-stop on Hit (SF6 Drive Impact freezes 25 f).
"""
import animkit as ak
from _moves import P, SPOTS, STANCE, feet, lock, smear, strike, tremble

NAME = "R6_ChargedPunch"

L0 = SPOTS["Left Leg"]
L_W = (-0.8, -1.5, 0.0)  # the lead foot's longer base
WIDE = feet(left=L_W)

PLANT = dict(yaw=-30, pitch=-2, pz=0.3, head=(-2, 0, 0), look=0.9, r=(16, 0, 26), l=(84, -12, -28),
             spots=feet(left=(-0.72, -1.15, 0.35)))
READY = dict(yaw=-56, pitch=-6, pz=0.0, head=(-6, 0, 0), look=0.95, r=(-62, 0, 40), l=(88, -24, -40), spots=WIDE)
COILED = dict(READY, yaw=-62, pitch=-14, pz=0.08, head=(-10, 0, 0), r=(-82, 0, 44), l=(90, -24, -42))
SQUEEZE = dict(COILED, yaw=-66, pitch=-16, pz=0.12, r=(-86, 0, 44))
IMPACT = dict(yaw=36, pitch=-30, pz=-1.0, head=(6, 0, 0), look=0.85, r=(102, 26, 34), l=(-60, 0, -26), spots=WIDE)
# the one smear frame of the release: the fist comes through low and close to the ribs, the rear arm already
# going back
SMEAR = smear(SQUEEZE, IMPACT, 0.45, r=(36, 10, 8), l=(24, 0, -14))
PUSH = dict(IMPACT, yaw=39, pitch=-31, pz=-1.04, r=(104, 27, 35), l=(-64, 0, -26))
ARM_DOWN = dict(IMPACT, yaw=30, pitch=-24, pz=-0.8, r=(62, 10, 16), l=(-30, 0, -20))
RISE = dict(yaw=2, pitch=-10, pz=-0.2, head=(0, 0, 0), look=0.8, r=(56, 0, 0), l=(40, 0, -4), spots=WIDE)
LIFT = dict(yaw=-10, pitch=-4, pz=0.24, head=(2, 0, 0), look=0.7, r=(60, 0, -10), l=(70, 0, 6),
            spots=feet(left=(-0.7, -1.1, 0.3)))
HOME = dict(yaw=-16, pitch=-6, pz=0.0, head=(4, 0, 0), look=0.6, r=(62, 0, -14), l=(76, 0, 10), spots=feet())


def build():
    a = ak.Anim(NAME, rig="R6", length=122, priority="Action2")
    a.full(0, STANCE, ease="quad_out")
    a.full(5, P(PLANT), ease="cubic_inout")
    a.full(12, P(READY), ease="constant").marker(12, "ChargeStart")

    # the charge: coil tighter while the shake grows, keyed on 2s
    tremble(a, 12, 48, READY, COILED, amp=(0.008, 0.04), deg=(0.3, 1.4), seed=2, end_ease="cubic_in")
    a.marker(48, "ChargeEnd")
    a.full(51, P(SQUEEZE), ease="linear")

    # release: 2 frames, then the impact pose the game freezes on
    over = strike(a, 53, SQUEEZE, IMPACT, "", mid=SMEAR, over=1.05)
    tremble(a, 55, 85, over, PUSH, every=3, amp=(0.045, 0.006), deg=(1.4, 0.2), seed=6, end_ease="cubic_inout")

    # recovery: the arm comes back first, the body follows, the lead foot steps home
    a.full(93, P(ARM_DOWN), ease="cubic_inout")
    a.full(101, P(RISE), ease="cubic_inout")
    a.full(107, P(LIFT), ease="cubic_inout")
    a.full(113, P(HOME), ease="cubic_out")
    a.full(122, STANCE, ease="linear")

    lock(a, "Right Leg", (0, 122))
    lock(a, "Left Leg", (12, 101), (113, 122))
    return a
