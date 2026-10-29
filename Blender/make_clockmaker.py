"""The Clockmaker endgame boss model (T122), Blender headless.
Run:  blender -b --factory-startup -P make_clockmaker.py -- <out_dir>
Design (Roblox Dev/Lore/The Clockmaker.md, act 5, stage 25): "the clock face seen from behind; the apprentice's lamp inside it". A huge clock face with twelve tick blocks and two hands stands behind a tall robed figure with no face;
the figure's chest is hollow and holds a small glowing lamp; long arms hold a pocket-watch-chain and a winding key. Brass, ink black, star gold. Faces -Y."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 dark robe, 1 brass, 2 pale clock face, 3 ink black, 4 lamp glow, 5 star gold, 6 deep violet, 7 steel
PAL = [(40, 34, 60), (190, 146, 60), (226, 218, 196), (12, 10, 18), (255, 214, 120), (250, 226, 130), (72, 50, 110), (120, 126, 140)]
m = Model("Clockmaker", out_dir, PAL, metallic=0.5, roughness=0.5)
CZ = 5.6                                                                     # clock centre height
# the clock is an open brass hoop (rim of 24 blocks, 12 tall tick blocks), so the robed figure shows through it and the silhouette is a ring, not a disc
for k in range(24):
    a = math.radians(15 * k)
    m.box((4.5 * math.sin(a), 1.0, CZ + 4.5 * math.cos(a)), (0.9, 0.5, 0.9), 1)
for k in range(12):
    a = math.radians(30 * k)
    m.box((3.5 * math.sin(a), 0.8, CZ + 3.5 * math.cos(a)), (0.3, 0.2, 0.8 if k % 3 == 0 else 0.45), 3)
m.box((0, 0.5, CZ + 1.5), (0.3, 0.2, 3.2), 3)                                # long hand pointing up
m.box((1.0, 0.5, CZ), (2.2, 0.2, 0.3), 3)                                    # short hand pointing right
m.disc((0, 0.4, CZ), 0.35, 0.25, 1, seg=8)
m.box((0, 0.6, CZ - 1.5), (0.14, 0.2, 3.0), 7)  # hanging spoke keeping the hands tied to the rim
# tall robed figure in front of the clock
m.cyl((0, -0.4, 0.1), 1.6, 0.8, 3.4, 0, seg=8)
m.cyl((0, -0.4, 3.5), 0.8, 1.15, 0.9, 0, seg=8)                              # shoulders
m.box((0, -0.95, 3.3), (0.9, 0.12, 0.9), 3)                                  # hollow chest
m.box((0, -1.0, 3.3), (0.4, 0.3, 0.45), 4)                                   # the apprentice's lamp
m.box((0, -1.0, 3.58), (0.5, 0.35, 0.08), 1)
m.box((0, -0.45, 4.9), (0.9, 0.8, 1.0), 6)                                   # faceless hood
m.cyl((0, -0.45, 5.4), 0.6, 0.05, 0.9, 6, seg=4)
for sx in (-1, 1):
    m.blade((sx * 0.95, -0.4, 4.1), (sx * 2.2, -1.5, 2.6), 0.5, 0.35, 0.35, 0)
    m.box((sx * 2.3, -1.6, 2.5), (0.4, 0.45, 0.4), 7)
m.box((-2.3, -1.6, 1.8), (0.1, 0.1, 1.2), 1)                                 # watch chain hanging
m.cyl((-2.3, -1.6, 1.0), 0.35, 0.35, 0.12, 5, seg=8)
m.box((2.3, -1.6, 1.8), (0.12, 0.12, 1.1), 1)                                # winding key
m.box((2.3, -1.6, 1.15), (0.7, 0.12, 0.2), 1)
m.finish()
