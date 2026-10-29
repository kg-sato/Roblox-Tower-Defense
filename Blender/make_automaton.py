"""The Clockmaker's Automaton boss model (T119), Blender headless.
Run:  blender -b --factory-startup -P make_automaton.py -- <out_dir>
Design (Roblox Dev/Lore/The Clockmaker.md, act 2, stage 10; Stage Set Lore: "a gear-engine that slows the board"; "winds itself by hand-cranks that are fresh and clean"):
a four-legged brass engine: one huge toothed gear faces the front as its body, a smaller gear behind, a hanging pendulum, a lamp-eye turret on top, and two bright clean hand-cranks at the sides. Faces -Y."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 old brass, 1 bright clean brass, 2 dark iron, 3 red lamp, 4 gold rivet, 5 black, 6 steel, 7 copper
PAL = [(130, 98, 44), (226, 184, 84), (44, 42, 48), (232, 52, 44), (240, 206, 110), (14, 14, 18), (120, 126, 136), (152, 90, 54)]
m = Model("ClockmakerAutomaton", out_dir, PAL, metallic=0.65, roughness=0.45)
# legs: four splayed jointed legs and feet
for sx in (-1, 1):
    for sy in (-1, 1):
        hip = (sx * 1.2, sy * 1.0, 2.6)
        knee = (sx * 2.9, sy * 1.7, 3.0)
        m.blade(hip, knee, 0.45, 0.4, 0.4, 2)
        m.box((sx * 2.9, sy * 1.7, 1.6), (0.4, 0.4, 2.8), 2)
        m.box((sx * 2.95, sy * 1.75, 0.15), (0.9, 0.9, 0.3), 5)
# chassis, big front gear, rear gear, hub
m.box((0, 0.3, 2.9), (2.6, 2.0, 0.5), 2)
m.disc((0, -0.9, 4.4), 2.0, 0.5, 0, seg=24, teeth=0.12)
m.disc((0, -1.2, 4.4), 1.1, 0.25, 1, seg=16, teeth=0.1)
m.disc((0, -1.4, 4.4), 0.35, 0.2, 4, seg=8)
m.disc((0, 0.9, 4.9), 1.4, 0.4, 7, seg=20, teeth=0.1)
# lamp-eye turret on top and a short chimney vent
m.box((0, 0.2, 6.9), (0.9, 0.9, 0.6), 2)
m.box((0, -0.3, 6.9), (0.5, 0.06, 0.2), 3)
m.cyl((0.8, 0.9, 6.0), 0.2, 0.15, 1.0, 6, seg=6)
# pendulum hanging in front of the chassis
m.box((0, -0.6, 2.2), (0.12, 0.12, 1.2), 6)
m.cyl((0, -0.6, 1.2), 0.45, 0.45, 0.25, 1, seg=8)
# two clean hand-cranks at the sides
for sx in (-1, 1):
    m.blade((sx * 2.0, 0.2, 4.4), (sx * 3.4, 0.2, 4.4), 0.2, 0.2, 0.2, 1)
    m.blade((sx * 3.4, 0.2, 4.4), (sx * 3.4, -0.7, 4.4), 0.2, 0.2, 0.2, 1)
    m.box((sx * 3.4, -0.9, 4.4), (0.35, 0.35, 0.35), 4)
m.finish()
