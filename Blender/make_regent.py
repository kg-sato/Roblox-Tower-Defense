"""The Hollow Court Regent boss model (T121), Blender headless.
Run:  blender -b --factory-startup -P make_regent.py -- <out_dir>
Design (Roblox Dev/Lore/Story/Chapter 4 - Clockwork Foundry.md, stage 20): "a figure in a crown of lit candles, ringing the Foundry's own bell"; summons mourners. A tall thin hollow-faced figure in a long dark coat,
a wide crown of seven candles with gold flames, one arm raised holding a big hanging bell on a hook, the other arm out with a hand-bell. Ash brown, ember orange, brass. Faces -Y."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 ash coat, 1 brass, 2 dark hollow, 3 ember flame, 4 candle wax, 5 black, 6 ember orange glow, 7 soot
PAL = [(86, 66, 56), (176, 132, 56), (20, 16, 18), (255, 170, 60), (232, 220, 190), (12, 10, 12), (230, 96, 40), (50, 42, 40)]
m = Model("HollowCourtRegent", out_dir, PAL, metallic=0.3, roughness=0.7)
for sx in (-1, 1):
    m.box((sx * 0.3, 0, 0.9), (0.3, 0.35, 1.8), 7)
    m.box((sx * 0.3, -0.2, 0.08), (0.4, 0.7, 0.16), 5)
m.cyl((0, 0, 1.5), 1.1, 0.55, 2.3, 0, seg=8)                     # long coat
m.cyl((0, 0, 1.5), 1.15, 1.1, 0.25, 7, seg=8)
m.box((0, -0.55, 2.7), (0.7, 0.06, 0.9), 1)                       # brass buttons plate
m.box((0, -0.05, 4.15), (0.7, 0.65, 0.8), 2)                      # hollow head
m.box((0, -0.4, 4.15), (0.5, 0.06, 0.4), 5)
for sx in (-1, 1):
    m.box((sx * 0.14, -0.38, 4.2), (0.08, 0.04, 0.08), 6)
# crown: ring of seven candles with flames
m.cyl((0, -0.05, 4.55), 0.62, 0.62, 0.18, 1, seg=10)
for k in range(7):
    a = math.radians(-90 + 360 * k / 7)
    cx, cy = 0.55 * math.cos(a), -0.05 + 0.55 * math.sin(a)
    m.box((cx, cy, 5.0), (0.14, 0.14, 0.6), 4)
    m.box((cx, cy, 5.45), (0.12, 0.12, 0.28), 3)
# right arm raised, big bell hanging from the hand; left arm out with a hand bell
m.blade((0.65, 0, 3.4), (1.8, -0.2, 4.3), 0.4, 0.3, 0.3, 0)
m.box((1.9, -0.2, 4.4), (0.35, 0.35, 0.35), 4)
m.box((1.9, -0.2, 4.0), (0.07, 0.07, 0.7), 5)
m.cyl((1.9, -0.2, 2.5), 0.9, 0.3, 1.5, 1, seg=8)
m.box((1.9, -0.2, 2.35), (0.2, 0.2, 0.2), 5)
m.blade((-0.65, 0, 3.2), (-1.9, -1.0, 2.7), 0.4, 0.3, 0.3, 0)
m.cyl((-2.0, -1.05, 2.1), 0.35, 0.12, 0.6, 1, seg=8)
m.finish()
