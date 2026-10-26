"""Shared helpers for the signature punches: delayed impact, barrage, charged punch (method by fwjelaa).

Poses are body() recipes from _special.py (torso yaw / lean / hips, arms as the camera sees them, feet on
given floor spots), so big twists and lunges keep both soles where they stand. On top of that:

P()        solves a recipe into a pose and plants every grounded foot with ak.plant (a foot whose spot has a
           height is in the air: a deliberate step)
spot(), step()   floor spots: a foot moved from the fight stance, and a foot halfway through a step (lifted)
tremble()  a vibrating moving hold keyed on 2s. ease="constant" gives the stepped anime shake (Guilty Gear Xrd's
           "every frame is a key frame"); the body slides from one recipe to another underneath the shake
smear()    the one in-between frame of a fast strike, with the arms shaped by hand (no T-pose sweep)
past()     an overshoot recipe: the body carried past a contact, feet where the contact put them
strike()   one contact the battlegrounds way: a solved in-between on the frame before, the contact with its Hit
           marker, a linear carry past it, then ease out
lock()     a.lock_feet() per leg over the stretches where that foot is down

Every clip starts and ends on _lib.FIGHT_R6, so they chain with the M1s.
"""
import animkit as ak
from _lib import FIGHT_R6
from _special import body, mix, shake, smooth, spots_of

LEGS = ("Right Leg", "Left Leg")
STANCE = FIGHT_R6
# where the fight stance's soles stand: (x, z, height above the floor)
SPOTS = {leg: xz + (0.0,) for leg, xz in spots_of(FIGHT_R6).items()}


def spot(leg, dx=0.0, dz=0.0, h=0.0):
    """The fight stance's spot for `leg`, moved dx (right +) / dz (back +) studs, h studs up."""
    x, z, _ = SPOTS[leg]
    return (x + dx, z + dz, h)


def step(a, b, t=0.5, h=0.3):
    """A foot t of the way from spot a to spot b, lifted h studs (a real step, not a slide)."""
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, h)


def feet(right=None, left=None):
    """Spots dict for body(): stance spots unless given."""
    return {"Right Leg": right or SPOTS["Right Leg"], "Left Leg": left or SPOTS["Left Leg"]}


def P(recipe):
    """body() recipe -> pose, with every grounded foot planted exactly on its spot."""
    pose = body(**recipe)
    spots = recipe["spots"]
    down = tuple(leg for leg in LEGS if (spots[leg][2] if len(spots[leg]) > 2 else 0.0) <= 0.0)
    if down:
        pose = ak.plant(pose, {leg: (spots[leg][0], 0.0, spots[leg][1]) for leg in down}, legs=down)
    return pose


def tremble(a, f0, f1, start, end, every=2, amp=(0.01, 0.03), deg=(0.4, 1.0), ease="constant", seed=0,
            end_ease="linear"):
    """Moving hold from f0 to f1: the body slides from recipe `start` to `end` (smoothstep) while it shakes
    every `every` frames, the shake going from amp[0] to amp[1] studs and deg[0] to deg[1] degrees (it dies
    down when the second number is smaller). Both ends are clean poses; the last key gets `end_ease`."""
    frames = list(range(f0, f1 + 1, every))
    if frames[-1] != f1:
        frames.append(f1)
    for n, f in enumerate(frames):
        s = (f - f0) / (f1 - f0)
        base = mix(start, end, smooth(s))
        if f not in (f0, f1):
            base = shake(base, n + seed, amp[0] + (amp[1] - amp[0]) * s, deg[0] + (deg[1] - deg[0]) * s)
        a.full(f, P(base), ease=end_ease if f == f1 else ease)
    return a


def past(before, contact, over=1.08):
    """The recipe `over` of the way from `before` to `contact` (over > 1: carried past it). Feet stay put."""
    return dict(mix(before, contact, over), spots=contact["spots"])


def smear(before, contact, t=0.45, **arms):
    """The one in-between frame of a fast strike: body t of the way there, but the arms given explicitly (r=..., l=...).
    R6 has no elbows, so a straight arm swung from behind the body to a straight punch sweeps out sideways through
    a T-pose if it is blended; a fist that comes through low and close to the ribs reads as a punch instead."""
    out = mix(before, contact, t)
    out.update(arms)
    return out


def strike(a, f, before, contact, value, mid=0.42, over=1.08, carry=2, out="cubic_out", extra=()):
    """Contact on frame f (Hit marker = value, plus any `extra` marker names), coming from recipe `before`
    keyed on f-2 or earlier. f-1 gets a solved in-between `mid` of the way (the feet stay put and the last
    frame still has the biggest jump; or pass a recipe as `mid`, e.g. smear(...), to shape that frame
    yourself), then `carry` frames of linear follow-through `over` past the contact.
    Returns the follow-through recipe."""
    a.full(f - 1, P(mid if isinstance(mid, dict) else mix(before, contact, mid)), ease="linear")
    a.full(f, P(contact), ease="linear").marker(f, "Hit", value)
    for name in extra:
        a.marker(f, name)
    follow = past(before, contact, over)
    a.full(f + carry, P(follow), ease=out)
    return follow


def lock(a, leg, *spans):
    """Keep `leg`'s foot nailed to the floor over each (start, end) stretch (it must be down there)."""
    for s, e in spans:
        a.lock_feet(s, e, legs=(leg,))
    return a
