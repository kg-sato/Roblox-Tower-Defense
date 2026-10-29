"""The Unbound boss model (T118), three phase variants, Blender headless.
Run:  blender -b --factory-startup -P make_unbound.py -- <enemies_dir>     (writes <enemies_dir>/Unbound, UnboundP2, UnboundP3)
Design (Roblox Dev/Lore/Stage Set Lore.md, Chapter 1): "a faceless figure of fog ... what is left of a night nobody finished"; act 1 of the Clockmaker's story (denial, rolls back).
Phase 1: a tall hooded cone of fog with a blank pale oval where a face would be, long arms hanging, fog tatters at the hem.
Phase 2: it rises and spreads, arms flung wide, the blank face split down the middle, a ring of shards behind the head.
Phase 3: the cloak is gone; the head, two hands and loose fog shards float around a small hollow core with a faint lantern glow."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemy_lib import Model

root = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
# 0 fog blue-grey, 1 pale fog, 2 deep shadow, 3 blank face pale, 4 lantern glow, 5 dark hollow, 6 cold teal edge, 7 ink black
PAL = [(112, 128, 150), (176, 190, 206), (52, 62, 82), (226, 230, 236), (255, 206, 110), (18, 22, 32), (90, 150, 164), (10, 12, 18)]


def tatters(m, z, r, n, ln, idx):
    for k in range(n):
        a = 2 * math.pi * k / n
        p0 = (r * math.cos(a), r * math.sin(a), z)
        m.blade(p0, (p0[0] * 1.5, p0[1] * 1.5, z - 0.1), 0.35, 0.05, 0.1, idx)


# phase 1: a wide low bank of fog with a stooped figure rising from one side, an oversized blank oval head floating clear of the shoulders, arms dragging to the ground
m = Model("Unbound", os.path.join(root, "Unbound"), PAL, metallic=0.0, roughness=0.95)
m.cyl((0, 0, 0.1), 3.0, 1.4, 1.5, 0, seg=8, ry=0.7)
m.cyl((0, 0, 0.1), 3.05, 2.95, 0.25, 2, seg=8, ry=0.7)
tatters(m, 0.2, 3.0, 12, 0.8, 1)
m.cyl((-0.6, 0, 1.6), 1.1, 0.6, 1.6, 0, seg=8)
m.box((-0.2, -0.3, 4.55), (1.1, 0.7, 1.5), 3)       # oversized blank face, no features, floating
m.box((-0.2, -0.65, 4.55), (0.5, 0.06, 0.9), 1)
for sx, bx in ((-1, -1.4), (1, 0.2)):
    m.blade((bx, -0.2, 2.9), (bx + sx * 1.9, -1.3, 0.35), 0.5, 0.35, 0.35, 0)
    m.box((bx + sx * 2.0, -1.4, 0.3), (0.55, 0.6, 0.3), 3)
m.finish()
# phase 2: risen and spread, tall and narrow torso, split face, shard halo, arms flung wide
m = Model("UnboundP2", os.path.join(root, "UnboundP2"), PAL, metallic=0.0, roughness=0.95)
m.cyl((0, 0, 0.6), 2.2, 0.5, 3.0, 0, seg=8, ry=0.6)
tatters(m, 0.7, 2.2, 12, 0.9, 1)
m.cyl((0, 0, 3.6), 0.5, 0.9, 1.0, 0, seg=8)
for sx in (-1, 1):
    m.box((sx * 0.45, -0.1, 5.7), (0.8, 0.9, 1.5), 1)
    m.box((sx * 0.06, -0.58, 5.7), (0.06, 0.06, 1.3), 5)
    m.blade((sx * 0.9, -0.1, 4.4), (sx * 3.8, -0.8, 5.6), 0.5, 0.3, 0.35, 0)
    m.box((sx * 3.9, -0.85, 5.65), (0.45, 0.55, 0.45), 3)
for k in range(7):
    a = math.radians(-70 + 23 * k)
    m.blade((1.3 * math.sin(a), 0.5, 5.7 + 1.3 * math.cos(a)), (2.8 * math.sin(a), 0.55, 5.7 + 2.8 * math.cos(a)), 0.3, 0.05, 0.08, 6)
m.finish()
# phase 3: cloak gone, floating head, hands and shards around a hollow core
m = Model("UnboundP3", os.path.join(root, "UnboundP3"), PAL, metallic=0.0, roughness=0.95)
m.box((0, 0, 2.1), (0.7, 0.55, 0.9), 5)
m.box((0, -0.3, 2.1), (0.34, 0.06, 0.34), 4)
m.box((0, -0.1, 3.5), (0.6, 0.6, 0.9), 3)
for sx in (-1, 1):
    m.box((sx * 1.7, -0.5, 2.6), (0.4, 0.5, 0.4), 3)
    m.box((sx * 1.0, -0.2, 1.2), (0.5, 0.5, 0.2), 0)
for k in range(10):
    a = 2 * math.pi * k / 10
    r = 1.1 + 0.5 * (k % 3)
    z = 0.6 + 0.4 * (k % 4) + 0.5 * k / 3
    m.blade((r * math.cos(a), r * math.sin(a), z), (r * math.cos(a) * 1.3, r * math.sin(a) * 1.3, z + 0.35), 0.4, 0.1, 0.1, 0 if k % 2 else 6)
m.finish()
