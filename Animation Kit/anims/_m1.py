"""The R6 4-hit M1 combo, one recipe, two presets (snappy / weighty). Method by fwjelaa.

Each hit is its own animation, like in battleground games: the game plays M1_1..M1_4 per click.
Every clip starts and ends in the stance, so they chain without pops, and each has a "Hit" marker
on the contact frame. Hit-stop is NOT baked in: on the Hit marker the game script pauses the track
(track:AdjustSpeed(0) for STYLE[...]["hitstop"] frames) only when the hit lands.

Timeline of one hit (frames at 60 fps, snappy / weighty):
  stance -> wind-up (4 / 12, ease into it) -> strike (2 / 4, accelerate: biggest jump last)
  -> contact + Hit marker -> overshoot (+2) -> settle (hold 3 / 4) -> recover to stance (12 / 22)
"""
import animkit as ak
from _lib import STANCE, STYLE, root, twist

# Poses authored at snappy strength around the snappy stance; weighty scales them down.
AUTHORED_EXAGGERATION = STYLE["snappy"]["exaggerate"]


def _hit(n, stance):
    """(windup, contact) for hit n, built on the given stance."""
    if n == 1:  # right straight: torso unwinds left, rear fist drives straight out
        windup = root(twist(dict(stance, **{
            "Right Arm": (30, 0, -2), "Left Arm": (84, 0, 14), "Head": (2, 0, 0)}), -10), py=-0.05, pz=0.1)
        # the fist aims back toward straight ahead (y -18 undoes most of the torso turn) so the player still
        # sees it beside the head from behind; the guard hand tucks in instead of swinging out
        contact = root(twist(dict(stance, **{
            "Right Arm": (96, -18, -2), "Left Arm": (44, 0, 22), "Head": (-2, 0, 0)}), 42), py=-0.04, pz=-0.38)
    elif n == 2:  # left straight: torso turns right, lead fist snaps out, right fist back to the chin
        windup = root(twist(dict(stance, **{
            "Left Arm": (40, 0, 6), "Right Arm": (70, 0, -16), "Head": (2, 0, 0)}), 10), py=-0.05, pz=0.08)
        contact = root(twist(dict(stance, **{
            "Left Arm": (96, 16, 2), "Right Arm": (52, 0, -22), "Head": (-2, 0, 0)}), -26), py=-0.04, pz=-0.34)
    elif n == 3:  # right hook: arm wide, then swept across with a big torso unwind
        windup = root(twist(dict(stance, **{
            "Right Arm": (72, 0, 42), "Left Arm": (80, 0, 12), "Head": (2, 0, 0)}), -20), py=-0.08, pz=0.06)
        contact = root(twist(dict(stance, **{
            "Right Arm": (86, 0, -24), "Left Arm": (46, 0, 6), "Head": (0, 0, 0)}), 56), py=-0.06, pz=-0.3)
    else:  # 4: uppercut finisher: sink low and coil, then drive up and lean back
        windup = root(twist(dict(stance, **{
            "Torso": (-16, 0, 0, 0, 0, 0), "Right Arm": (-34, 0, 10), "Left Arm": (70, 0, 16),
            "Right Leg": (-10, 0, 22), "Left Leg": (34, 0, -18), "Head": (10, 0, 0)}), -24),
            py=-0.42, pz=0.12)
        contact = root(twist(dict(stance, **{
            "Torso": (14, 0, 0, 0, 0, 0), "Right Arm": (168, 0, -8), "Left Arm": (24, 0, -22),
            "Right Leg": (-14, 0, 6), "Left Leg": (16, 0, -4), "Head": (18, 0, 0)}), 30),
            py=0.12, pz=-0.42)
    return windup, contact


def make(n, style="snappy"):
    name = f"R6_M1_{n}" + ("" if style == "snappy" else "_Weighty")
    stance = STANCE[style]
    st = STYLE[style]
    t = st["finisher"] if n == 4 else st["m1"]
    windup, contact = _hit(n, STANCE["snappy"])
    k = st["exaggerate"] / AUTHORED_EXAGGERATION

    def retarget(pose):
        """Same move on this style's stance, k times as big (k = 1 for snappy)."""
        out = {}
        for j, v in pose.items():
            v, s0, s1 = ak._pad(v), ak._pad(STANCE["snappy"][j]), ak._pad(stance[j])
            moved = tuple(b + (c - a) * k for c, a, b in zip(v, s0, s1))
            out[j] = moved if j == "Torso" else moved[:3]
        return out

    windup, contact = retarget(windup), retarget(contact)
    feet = ak.soles(stance)

    def g(pose, lift=0.0):
        """Feet stay on the stance's floor spots (the body lunges and twists over them), on the floor."""
        pose = ak.plant(pose, feet)
        return ak.ground(pose, lift=lift) if lift else pose

    lift = 0.12 if n == 4 else 0.0  # the uppercut pops up off the floor

    a = ak.Anim(name, rig="R6", priority="Action", style=style)
    f = 0
    a.full(f, stance, ease="quad_out")  # decelerate into the wind-up
    f += t["antic"] - t.get("telegraph", 0)
    if t.get("telegraph"):
        a.full(f, g(windup), ease="linear")  # telegraph: a moving hold at the extreme
        f += t["telegraph"]
        a.full(f, g(ak.drift(windup, 2)), ease="cubic_in")
    else:
        a.full(f, g(windup), ease="cubic_in")  # accelerate: the biggest jump is the last frame
    f += t["strike"]
    hit = f
    a.full(f, g(contact, lift=lift), ease="linear").marker(f, "Hit", str(n))
    over = ak.blend(windup, contact, 1 + st["overshoot"])  # carry through past the contact
    a.full(f + 2, g(over, lift=lift), ease="cubic_out")
    f += t["hold"] + 2
    a.full(f, g(ak.drift(contact)), ease="cubic_out")  # settle: a moving hold, then ease home
    f += t["recover"]
    a.full(f, stance, ease="linear")
    a.length = f
    # no a.offset("Head", ...) here: the head counter-turns against the torso to keep its eyes on the
    # target, and delaying a counter-turn makes it whip round and snap back
    # the in-betweens of a 2-frame strike would drag the feet otherwise. The uppercut leaves the floor,
    # and locking legs around an airborne stretch makes them snap, so it relies on its planted keys.
    if not lift:
        a.lock_feet(0, f, targets=feet)
    a.hit_frame = hit
    return a
