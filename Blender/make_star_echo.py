"""The Star Choir's Echo boss model (T120), Blender headless.
Run:  blender -b --factory-startup -P make_star_echo.py -- <out_dir>
Design (Roblox Dev/Lore/Stage Set Lore.md, stage 15): "the first sign of the sky"; the Choir knows what was lost. A tall hovering singer in a silver-blue robe with an open mouth, a spiked star halo behind its head,
and two smaller echo copies hovering at its sides at different heights, each with a tiny halo. Moonlit blue-silver with red and blue glass accents. Faces -Y."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 silver robe, 1 pale moon, 2 deep blue, 3 red glass, 4 star gold, 5 dark mouth, 6 blue glass, 7 ink
PAL = [(150, 166, 196), (222, 230, 244), (40, 52, 96), (206, 50, 60), (250, 226, 130), (14, 16, 30), (70, 120, 220), (10, 12, 20)]
m = Model("StarChoirEcho", out_dir, PAL, metallic=0.2, roughness=0.6)


def singer(cx, z0, s, halo_idx):
    m.cyl((cx, 0, z0), 1.0 * s, 0.35 * s, 2.6 * s, 0, seg=8)                    # robe hovering, no legs
    m.cyl((cx, 0, z0), 1.05 * s, 1.0 * s, 0.2 * s, 2, seg=8)                    # hem band
    m.box((cx, -0.02 * s, z0 + 2.9 * s), (0.7 * s, 0.6 * s, 0.75 * s), 1)       # head
    m.box((cx, -0.34 * s, z0 + 2.85 * s), (0.28 * s, 0.06 * s, 0.34 * s), 5)    # open mouth
    for sx in (-1, 1):
        m.box((cx + sx * 0.2 * s, -0.32 * s, z0 + 3.1 * s), (0.1 * s, 0.05 * s, 0.1 * s), 6)
        m.blade((cx + sx * 0.3 * s, 0, z0 + 2.2 * s), (cx + sx * 1.5 * s, -0.5 * s, z0 + 3.2 * s), 0.35 * s, 0.25 * s, 0.25 * s, 0)  # arms raised in song
    m.disc((cx, 0.5 * s, z0 + 3.3 * s), 1.1 * s, 0.1 * s, halo_idx, seg=16, teeth=0.9)  # spiked star halo behind the head


singer(0, 1.0, 1.0, 4)
singer(-3.3, 0.4, 0.55, 6)
singer(3.3, 2.0, 0.55, 3)
m.finish()
