"""R6 sword light slash 1: forehand, right -> left, snappy (36 f). Recipe in _sword.py."""
from _sword import light_slash, slash1_poses


def build():
    return light_slash("R6_SwordSlash1", slash1_poses())
