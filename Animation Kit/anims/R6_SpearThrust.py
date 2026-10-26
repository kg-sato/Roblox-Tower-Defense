"""R6 spear thrust, snappy: draw back, coil, drive the spear straight out with a lunge. Method by fwjelaa.

Uses the sword set's footwork (`_sword.P` keeps both feet on the stance spots while the body turns and
lunges); the spear is the `Spear` prop on the same `Handle` joint. The spear stays level by countering the
arm: Handle x = -(arm x). Markers: TrailOn / Hit / TrailOff.
"""
import animkit as ak
from _sword import D, P, plant

NAME = "R6_SpearThrust"
PROPS = ("Spear",)


def spear(arm_x, arm_y=0, arm_z=0, tilt=0):
    """Right arm at arm_x with the spear held level (tilt > 0 points the tip up)."""
    return {"Right Arm": (arm_x, arm_y, arm_z), "Handle": (-arm_x + tilt, 0, 0)}


def build():
    # the torso turns right (bladed); arm y turns the spear back by about as much so it aims at the target
    stance = P(-34, {**spear(36, 30, 6, tilt=18), "Left Arm": (62, 0, 20)})
    draw = P(-50, {**spear(6, 44, 12, tilt=14), "Left Arm": (52, 0, 26)}, pz=0.18)  # spear pulled back to the hip
    contact = P(-6, {**spear(90, 6, -4, tilt=12), "Left Arm": (86, 0, 16)}, lean_x=-10, pz=-0.6)

    a = ak.Anim(NAME, rig="R6", props=PROPS, length=38, priority="Action", style="snappy")
    a.full(0, stance, ease="quad_out")  # ease into the draw
    a.full(6, draw, ease="linear")
    a.full(9, D(draw, 1.0), ease="cubic_in")  # coiled: the biggest jump is the last frame into the hit
    a.full(12, contact, ease="linear").marker(12, "Hit")
    a.full(14, plant(ak.blend(draw, contact, 1.1)), ease="cubic_out")  # carry through past the target
    a.full(18, D(contact), ease="cubic_out")
    a.full(38, stance, ease="linear")
    a.marker(9, "TrailOn").marker(16, "TrailOff")
    a.lock_feet(0, 38)
    return a
