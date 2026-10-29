"""Hollow Parishioner enemy model (self-assigned from the next-night plan), Blender headless, on enemy_lib.
Run:  blender -b --factory-startup -P make_parishioner.py -- <out_dir>
Design (Roblox Dev/Research/3D and Art/Backgrounds and Enemies - Mystic Victorian.md): "hooded cultist, hunched, lantern in hand; round hood, small lantern glow; muted grey-violet" (the horde grunt).
A hunched figure in a long grey-violet robe, a big ROUND hood with a dark hollow face and two dim eye points, hands clasped forward holding a small dead lantern with a faint glow. Faces -Y."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 robe grey-violet, 1 robe shadow, 2 hood dark hollow, 3 eye dim, 4 lantern glow, 5 black, 6 rope brown, 7 hood trim pale
PAL = [(112, 100, 140), (74, 66, 96), (20, 18, 26), (214, 206, 160), (255, 196, 100), (14, 12, 18), (96, 70, 48), (160, 150, 180)]
m = Model("HollowParishioner", out_dir, PAL, metallic=0.0, roughness=0.9)
# deeply hunched: the body steps forward in three blocks so the hood hangs ahead of the hips; a tall lantern pole is carried at the right, so the outline is not a plain hooded robe
m.cyl((0, 0.4, 0.1), 1.0, 0.75, 1.2, 0, seg=8)                  # robe skirt
m.cyl((0, 0.4, 0.1), 1.05, 1.0, 0.2, 1, seg=8)                  # hem band
m.box((0, 0.0, 1.45), (1.0, 0.9, 0.55), 0)                      # lower back
m.box((0, -0.5, 1.8), (1.0, 0.9, 0.5), 0)                       # shoulders pushed forward
m.box((0, 0.5, 1.9), (0.7, 0.5, 0.7), 1)                        # hump on the back
m.cyl((0, -1.0, 1.55), 0.62, 0.62, 0.15, 7, seg=10)             # hood trim ring
m.cyl((0, -1.0, 1.7), 0.7, 0.62, 0.85, 0, seg=10)               # big round hood hanging forward and low
m.cyl((0, -1.0, 2.5), 0.62, 0.3, 0.28, 0, seg=10)               # hood crown
m.box((0, -1.55, 2.0), (0.5, 0.1, 0.5), 2)                      # hollow face
for sx in (-1, 1):
    m.box((sx * 0.13, -1.6, 2.05), (0.08, 0.05, 0.08), 3)
m.blade((-0.5, -0.4, 1.75), (-0.45, -1.2, 0.9), 0.3, 0.22, 0.25, 1)    # left sleeve hangs forward
m.box((-0.45, -1.3, 0.8), (0.3, 0.3, 0.3), 7)
m.blade((0.5, -0.4, 1.75), (1.9, -0.9, 1.5), 0.3, 0.22, 0.25, 1)       # right arm holds the pole
m.box((1.95, -0.95, 1.5), (0.3, 0.3, 0.3), 7)
m.box((1.95, -0.95, 1.9), (0.1, 0.1, 3.8), 6)                          # lantern pole (to z 3.8)
m.box((1.95, -0.95, 3.85), (0.5, 0.5, 0.08), 5)
m.box((1.95, -0.95, 3.55), (0.36, 0.36, 0.5), 4)                       # small dead lantern, faint glow
m.box((1.95, -0.95, 3.27), (0.4, 0.4, 0.06), 5)
m.finish()
