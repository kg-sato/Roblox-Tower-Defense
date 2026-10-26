"""R6 sword light slash 2: backhand return swing, left -> right, snappy (34 f). Recipe in _sword.py."""
from _sword import light_slash, slash2_poses


def build():
    return light_slash("R6_SwordSlash2", slash2_poses(), n=2)
