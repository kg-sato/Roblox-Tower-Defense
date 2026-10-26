"""R15 forward dash, snappy: one-shot, 24 frames, from the fighting stance back to it. Method by fwjelaa.

  stance (0) --quad_out 3 f--> launch (3): hips square up and drop, chest pitches forward, the rear leg
  drives back onto its toe, eyes stay on the target
  --> travel (3-13, a moving hold on a smooth curve): deepest and lowest at 8, lead knee bent under the
      chest, rear leg trailing on its toe, arms swept back behind the body
  --quad_out 4 f--> brake (17): lead foot bites the floor ahead, counter-lean back, knees absorb,
      head and arms whip forward (inertia)
  --> settle (20): a little past the stance --> stance (24).
The arms run on their own keys about 2 frames behind the body (overlap). Every frame is solved by IK
(anims/_react15.py), so the knees and elbows always bend the right way; the feet glide on purpose
(slides=True) while the game pushes the character.

Markers for the game script (the animation never moves the HumanoidRootPart):
  DashStart (1): apply the velocity (e.g. LinearVelocity ~45 studs/s along the flattened look vector)
  DashEnd (13): first brake frame, kill or decay the velocity while the body counter-leans.
"""
from _react15 import K, STANCE_ARMS, arms, foot, limb, timeline, toe

NAME = "R15_Dash"
DASH_START, DASH_END = 1, 13

STANCE = K(rear_foot=toe(-50, 0))  # the stance, its rear foot spelled as a toe pivot
LAUNCH = K(hips=(-22, -16, 0), move=(0, -0.6, -0.15), chest=(-14, 10, 0), head=(30, 8, 0),
           lead_foot=foot(-0.5, -1.05, -10), rear_foot=toe(-40, -40, dx=-0.15, dz=0.35))
TRAVEL = K(hips=(-26, -12, 0), move=(0, -0.72, -0.25), chest=(-17, 8, 0), head=(38, 4, 0),
           lead_foot=foot(-0.5, -1.15, -8), rear_foot=toe(-35, -55, dx=-0.2, dz=0.55))
TRAVEL_END = K(hips=(-25, -13, 0), move=(0, -0.68, -0.2), chest=(-16, 9, 0), head=(36, 5, 0),
               lead_foot=foot(-0.5, -1.15, -8), rear_foot=toe(-36, -52, dx=-0.2, dz=0.52))
BRAKE = K(hips=(6, -36, 3), move=(0, -0.74, 0.14), chest=(8, 2, -2), head=(-10, 30, 0),
          lead_foot=foot(-0.55, -1.45, -20, pitch=14), rear_foot=toe(-48, 0, dz=-0.05))
SETTLE = K(hips=(-8, -31, 0), move=(0, -0.42, 0.0), chest=(-14, 4, 0), head=(10, 24, 0),
           lead_foot=foot(-0.6, -0.95, -18), rear_foot=toe(-50, 0, dz=-0.05))

# Arms in chest axes: direction from the shoulder, reach (1.64 = straight) and elbow-tip direction.
# They drop out of the guard, sweep back nearly straight and a little out (above the back line, so the
# silhouette shows them), trail through the travel and swing down and forward through the brake.
DROP = arms(limb("lead", (-0.3, -0.85, -0.45), 1.4, (-0.4, 0, 1)), limb("rear", (0.35, -0.85, -0.4), 1.4, (0.4, 0, 1)))
SWEPT = arms(limb("lead", (-0.35, -0.6, 0.72), 1.56, (-0.2, 0.8, 0.5)),
             limb("rear", (0.4, -0.55, 0.75), 1.57, (0.2, 0.8, 0.5)), (-25, 0, 0), (-25, 0, 0))
BACK = arms(limb("lead", (-0.4, -0.48, 0.8), 1.6, (-0.2, 0.85, 0.45)),
            limb("rear", (0.45, -0.42, 0.82), 1.61, (0.2, 0.85, 0.45)), (-35, 0, 0), (-35, 0, 0))
DOWN = arms(limb("lead", (-0.3, -0.9, -0.3), 1.5, (-0.3, 0, 1)), limb("rear", (0.35, -0.88, -0.25), 1.5, (0.3, 0, 1)))
FRONT = arms(limb("lead", (0.2, -0.45, -0.87), 1.5, (-0.4, -1, 0.2)), limb("rear", (-0.05, -0.55, -0.83), 1.45, (0.4, -1, 0.2)),
             (10, 0, 0), (10, 0, 0))


def build():
    body = [
        (0, STANCE, "quad_out"),  # lean in fast, decelerating into the launch
        (3, LAUNCH, "smooth"),
        (8, TRAVEL, "smooth"),
        (DASH_END, TRAVEL_END, "quad_out"),  # the brake bites at once
        (17, BRAKE, "smooth"),
        (20, SETTLE, "smooth"),
        (24, STANCE, "linear"),
    ]
    arm_keys = [
        (0, STANCE_ARMS, "smooth"),
        (3, DROP, "smooth"),
        (6, SWEPT, "smooth"),
        (10, BACK, "smooth"),
        (14, SWEPT, "smooth"),
        (16, DOWN, "smooth"),
        (19, FRONT, "smooth"),
        (24, STANCE_ARMS, "linear"),
    ]
    a = timeline(NAME, body, arm_keys, priority="Action", style="snappy", slides=True)
    return a.marker(DASH_START, "DashStart").marker(DASH_END, "DashEnd")
