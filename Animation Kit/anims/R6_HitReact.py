"""R6 hit reaction (victim of an M1), snappy: 24 frames, priority Action4 (method by fwjelaa).

No anticipation: a reaction is caused, not chosen. Played with track:Play(0) (no fade) on the victim.
  0  fight stance
  2  PAIN (Impact marker): head snapped back, chest arched back from the hips, hips shoved 0.3 studs back,
     guard broken and both arms thrown open                              <- 2-frame snap
  5  follow-through: head and arms keep travelling (they are loose, the torso was hit)
  13 settle: dazed, guard low, hips still pushed back                    <- 11-frame settle
  24 fight stance again (chains into the next reaction or the idle)
Both feet stay on the stance's spots the whole time: the legs absorb the shove (an R6 torso arched about its
middle would swing the hips forward and slide the feet; _special.body() bends it at the hips instead).
On a hit-stop the game can freeze this track at the Impact marker (track:AdjustSpeed(0)), which freezes the
victim on the pain pose like fighting games do.
"""
import animkit as ak
from _lib import FIGHT_R6
from _special import body, spots_of

NAME = "R6_HitReact"

FEET = spots_of(FIGHT_R6)
# The fight stance in body() terms: torso turned -18, leaning -6, head looking 60% back toward the target.
PAIN = dict(yaw=-26, pitch=16, pz=0.30, head=(44, 0, -8), look=0.6,  # head snapped back, jaw knocked aside
            r=(22, 0, 38), l=(30, 0, -30), spots=FEET)  # guard broken: arms thrown open, the rear one higher
THROUGH = dict(yaw=-28, pitch=20, pz=0.36, head=(54, 0, -10), look=0.6,
               r=(4, 0, 46), l=(14, 0, -38), spots=FEET)  # the loose arms keep going: trailing behind the body
DAZED = dict(yaw=-22, pitch=2, pz=0.22, head=(10, 0, -3), look=0.6,
             r=(26, 0, 18), l=(36, 0, -14), spots=FEET)  # guard still low


def build():
    a = ak.Anim(NAME, rig="R6", length=24, priority="Action4")
    a.full(0, FIGHT_R6, ease="linear")  # the snap: straight in, no ease, no anticipation
    a.full(2, body(**PAIN), ease="cubic_out").marker(2, "Impact")
    a.full(5, body(**THROUGH), ease="cubic_inout")
    a.full(13, body(**DAZED), ease="cubic_inout")
    a.full(24, FIGHT_R6, ease="linear")
    return a
