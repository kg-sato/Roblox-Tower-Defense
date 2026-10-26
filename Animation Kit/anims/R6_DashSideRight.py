"""R6 side dash to the character's RIGHT: R6_DashSide mirrored. Method by fwjelaa.

Every dash key is mirrored with ak.mirror on the square body, then turned into the orthodox fighting stance,
so this clip still starts, brakes and ends on _lib.FIGHT_R6 (left foot forward) and chains with the rest.
Markers: DashStart (1) sideways velocity along +RightVector, DashEnd (13) kill it.
"""
from _moves2 import side_dash

NAME = "R6_DashSideRight"


def build():
    return side_dash(NAME, "right")
