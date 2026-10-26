"""R6 side dash to the character's LEFT, snappy: one-shot, 22 frames, stance to stance. Method by fwjelaa.

  stance (0) --quad_out 3 f--> push (3): the body tips into the travel (torso tilt +z), the rear leg shoves
      out sideways and stays stretched just off the floor, the lead foot glides under the body, eyes level
      and on the target
  --> glide (3-13, a moving hold): most tilted at 8, while the game pushes
  --quad_out 4 f--> brake (17): both feet back on their stance spots, counter-tilt the other way
  --> settle (20) a touch past the stance --> stance (22).
The arms trail the body by ~2 frames: the lead arm reaches out along the line of action (lead hand -> tilted
torso -> push foot), the rear fist tucks across the chest; on the brake both carry on toward the travel.
R6 can't drop its hips with a sideways split (its legs pivot on the outer hip edge), so the dash reads through
the tilt and that one long diagonal line, which is also what the player sees from behind.
The keys live in _moves2.side_dash (shared with R6_DashSideRight, its ak.mirror twin).

Markers for the game script (the animation never moves the HumanoidRootPart):
  DashStart (1): sideways velocity, e.g. LinearVelocity ~40 studs/s along -RightVector
  DashEnd (13): kill or decay the velocity; the body brakes over its planted feet (locked from 17).
slides=True: the lead foot glides on purpose during the push, so the skate check is skipped.
"""
from _moves2 import side_dash

NAME = "R6_DashSide"


def build():
    return side_dash(NAME, "left")
