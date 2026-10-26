"""Write Roblox animations as code in Blender.

    import animkit as ak
    a = ak.Anim("R6_Punch", rig="R6", length=30, priority="Action")
    a.key(0, ak.IDLE_R6)
    a.key(6, {"Torso": (0, 25, 0), "Right Arm": (40, 0, 15)}, ease="cubic_in")
    a.key(9, {"Torso": (0, -30, 0), "Right Arm": (90, 0, 0)}, ease="constant")
    a.marker(9, "Hit")
    a.build()

Pose language (same in roblox/AnimKit.luau): every joint gets (x, y, z) degrees, rotated like
CFrame.Angles(rad(x), rad(y), rad(z)) in the PARENT part's axes (X right, Y up, Z back).
Add three more numbers (x, y, z, px, py, pz) to also move the joint, in studs (only useful on Torso,
which is the RootJoint: crouch, lunge, hop).

    +x  arm/leg swings FORWARD, head looks UP, torso leans BACK
    +y  turns to the character's LEFT (seen from above, counter-clockwise)
    +z  right arm/leg OUT to the side; left arm/leg ACROSS the body (use -z for left out)
"""
import json
import math

import bpy
from mathutils import Quaternion

import rigs

# ease name -> (Blender interpolation, Blender easing, Roblox style or None if it must be baked).
# Measured in Studio: a Pose's easing shapes the move FROM it to the next pose (like Blender);
# Constant+In snaps straight to the next pose, Constant+Out holds (what "hold" means), and the old
# Cubic has In/Out swapped, so cubic eases use CubicV2.
EASES = {
    "linear": ("LINEAR", "AUTO", ("Linear", "In")),
    "constant": ("CONSTANT", "AUTO", ("Constant", "Out")),
    "cubic_in": ("CUBIC", "EASE_IN", ("CubicV2", "In")),
    "cubic_out": ("CUBIC", "EASE_OUT", ("CubicV2", "Out")),
    "cubic_inout": ("CUBIC", "EASE_IN_OUT", ("CubicV2", "InOut")),
    "elastic_out": ("ELASTIC", "EASE_OUT", ("Elastic", "Out")),
    "bounce_out": ("BOUNCE", "EASE_OUT", ("Bounce", "Out")),
    # Blender-only curves: exported by baking that stretch frame by frame
    "sine_inout": ("SINE", "EASE_IN_OUT", None),
    "quad_in": ("QUAD", "EASE_IN", None),
    "quad_out": ("QUAD", "EASE_OUT", None),
    "quart_out": ("QUART", "EASE_OUT", None),
    "quint_out": ("QUINT", "EASE_OUT", None),
    "expo_in": ("EXPO", "EASE_IN", None),
    "expo_out": ("EXPO", "EASE_OUT", None),
    "back_out": ("BACK", "EASE_OUT", None),
    "bezier": ("BEZIER", "AUTO", None),
}

PRIORITIES = ("Core", "Idle", "Movement", "Action", "Action2", "Action3", "Action4")

# Relaxed rest poses: arms slightly off the body so nothing intersects.
IDLE_R6 = {
    "Torso": (0, 0, 0, 0, 0, 0),
    "Head": (0, 0, 0),
    "Right Arm": (0, 0, 4),
    "Left Arm": (0, 0, -4),
    "Right Leg": (0, 0, 1),
    "Left Leg": (0, 0, -1),
}

IDLE_R15 = {
    "LowerTorso": (0, 0, 0, 0, 0, 0),
    "UpperTorso": (0, 0, 0),
    "Head": (0, 0, 0),
    "RightUpperArm": (0, 0, 4), "RightLowerArm": (0, 0, 0), "RightHand": (0, 0, 0),
    "LeftUpperArm": (0, 0, -4), "LeftLowerArm": (0, 0, 0), "LeftHand": (0, 0, 0),
    "RightUpperLeg": (0, 0, 1), "RightLowerLeg": (0, 0, 0), "RightFoot": (0, 0, 0),
    "LeftUpperLeg": (0, 0, -1), "LeftLowerLeg": (0, 0, 0), "LeftFoot": (0, 0, 0),
}

MIRROR = {"Right": "Left", "Left": "Right"}


def leg_drop(degrees, leg=2.0, depth=1.0):
    """How far an R6 torso must drop (studs) so a leg swung `degrees` still touches the floor.
    R6 has no knees, but its legs are 1-stud-deep boxes whose corner swings down as they rotate:
    drop = leg*(1 - cos) - depth/2*sin. 25 deg -> 0.0, 35 -> 0.08, 48 -> 0.29, 60 -> 0.57.
    Use it as a negative py on the Torso."""
    a = math.radians(abs(degrees))
    return max(0.0, leg * (1 - math.cos(a)) - depth / 2 * math.sin(a))


def mirror(pose):
    """Swap left and right: names swap, y and z rotations and x moves flip."""
    out = {}
    for joint, v in pose.items():
        name = joint
        for a, b in MIRROR.items():  # "Right Arm" (R6) and "RightUpperArm" (R15)
            if joint.startswith(a):
                name = b + joint[len(a):]
                break
        v = tuple(v)
        m = (v[0], -v[1], -v[2])
        if len(v) == 6:
            m += (-v[3], v[4], v[5])
        out[name] = m
    return out


def merge(*poses):
    """Later poses win, joint by joint."""
    out = {}
    for p in poses:
        out.update(p)
    return out


def scale(pose, k):
    """Exaggerate (k > 1) or tone down (k < 1) a pose."""
    return {j: tuple(c * k for c in v) for j, v in pose.items()}


def _pad(v):
    v = tuple(v)
    return v + (0.0,) * (6 - len(v)) if len(v) < 6 else v


def blend(a, b, t):
    """Joint by joint, t of the way from pose a to pose b (t > 1 pushes past b: overshoot)."""
    out = {}
    for j in set(a) | set(b):
        va, vb = _pad(a.get(j, (0, 0, 0))), _pad(b.get(j, (0, 0, 0)))
        v = tuple(x + (y - x) * t for x, y in zip(va, vb))
        out[j] = v if len(a.get(j, b.get(j))) == 6 or any(v[3:]) else v[:3]
    return out


def pose_transforms(pose, rig):
    """Pose language -> Motor6D.Transform per joint: C0rot^-1 * move * CFrame.Angles * C0rot."""
    from mathutils import Matrix
    out = {}
    for _, p0, p1, c0, c1 in rig["joints"]:
        v = _pad(pose.get(p1, (0, 0, 0)))
        rc = c0.to_3x3().to_4x4()
        out[p1] = rc.inverted() @ Matrix.Translation(v[3:]) @ rigs.angles(*v[:3]) @ rc
    return out


def ground(pose, rig="R6", lift=0.0, props=()):
    """Raise or lower the root joint so the lowest foot corner sits exactly on the floor (+ lift).
    Use it on every grounded key pose: no sinking, no floating, whatever the legs are doing."""
    import checks
    r = rigs.with_props(rig, props)
    fk = checks.forward_kinematics(r, pose_transforms(pose, r))
    low = min(c.y for foot in r["feet"] for c in checks._corners(fk[foot], r["parts"][foot]))
    root_joint = r["joints"][0][2]
    v = list(_pad(pose.get(root_joint, (0, 0, 0))))
    v[4] += -r["hip_height"] - low + lift
    out = dict(pose)
    out[root_joint] = tuple(v)
    return out


def soles(pose, rig="R6", props=()):
    """Sole centre of each foot, (x, y, z) in HumanoidRootPart space (the floor is y = -hip_height)."""
    import checks
    from mathutils import Vector
    r = rigs.with_props(rig, props)
    fk = checks.forward_kinematics(r, pose_transforms(pose, r))
    return {foot: tuple(fk[foot] @ Vector((0, -r["parts"][foot][1] / 2, 0))) for foot in r["feet"]}


def plant(pose, targets, rig="R6", legs=None, iters=8, grounded=True):
    """Keep feet on their floor spots: swing each R6 leg (its x and z) until its sole is back over
    targets[leg] (x, z from `soles(...)`, e.g. of the stance), then ground the pose. Use it on every
    key pose where the body lunges, twists or leans but the feet should not skate. R6 only (R15 legs bend:
    solve those with IK). grounded=False leaves the root height alone (Anim.lock_feet uses that)."""
    if rig != "R6":
        raise ValueError("plant() solves R6 legs; R15 needs IK on hip, knee and ankle")
    out = dict(pose)
    h = 0.25
    max_step = 12.0  # degrees per iteration: a spot the leg can't reach must not fling it around
    for _ in range(2):  # grounding moves the hips, so solve, ground, solve again
        for leg in legs or ("Right Leg", "Left Leg"):
            tx, _, tz = targets[leg]
            best = None
            for _ in range(iters * 2):
                x, y, z = _pad(out.get(leg, (0, 0, 0)))[:3]
                fx, _, fz = soles(out)[leg]
                ex, ez = fx - tx, fz - tz
                err = abs(ex) + abs(ez)
                if best is None or err < best[0]:
                    best = (err, (x, y, z))
                if err < 1e-4:
                    break
                out[leg] = (x + h, y, z)
                ax = soles(out)[leg]
                out[leg] = (x, y, z + h)
                az = soles(out)[leg]
                j11, j21 = (ax[0] - fx) / h, (ax[2] - fz) / h
                j12, j22 = (az[0] - fx) / h, (az[2] - fz) / h
                det = j11 * j22 - j12 * j21
                if abs(det) < 1e-9:
                    break
                dx, dz = -(j22 * ex - j12 * ez) / det, -(-j21 * ex + j11 * ez) / det
                k = min(1.0, max_step / max(abs(dx), abs(dz), 1e-9))
                out[leg] = (x + dx * k, y, z + dz * k)
            out[leg] = best[1]  # the closest the leg got (an unreachable spot stays a near miss)
        if not grounded:
            break
        out = ground(out, rig)
    return out


def drift(pose, degrees=1.5):
    """A 'moving hold': the same pose, settled a little (torso sinks, arms relax) so it never freezes.
    Only shoulders move (R6 arms, R15 upper arms), so R15 elbows never bend the wrong way. Re-ground
    grounded poses afterwards (ak.ground)."""
    out = dict(pose)
    for j, v in pose.items():
        v = list(_pad(v))
        if j in ("Torso", "LowerTorso"):
            v[0] -= degrees * 0.5
            v[4] -= 0.02
        elif j in ("Right Arm", "Left Arm", "RightUpperArm", "LeftUpperArm"):
            v[0] -= degrees
        out[j] = tuple(v) if len(pose[j]) == 6 or j in ("Torso", "LowerTorso") else tuple(v[:3])
    return out


class Anim:
    def __init__(self, name, rig="R6", props=(), length=60, fps=60, loop=False, priority="Action",
                 style="snappy", slides=False):
        """slides=True: the feet glide on purpose (dashes, slides, knockback), so skip the skate check."""
        if priority not in PRIORITIES:
            raise ValueError(f"priority must be one of {PRIORITIES}")
        self.name, self.rig_type, self.props = name, rig, tuple(props)
        self.length, self.fps, self.loop, self.priority, self.style = length, fps, loop, priority, style
        self.slides = slides
        self.keys = []  # (frame, joint, value, ease)
        self.markers = []  # (frame, name, value)
        self.locks = []  # (start, end, legs, targets)
        self.rig = rigs.with_props(rig, self.props)

    # ---- authoring -------------------------------------------------------------------------
    def key(self, frame, pose, ease="cubic_inout"):
        """Key the listed joints at `frame`. `ease` shapes the motion FROM this key to the next one."""
        if ease not in EASES:
            raise ValueError(f"unknown ease {ease!r}; use one of {sorted(EASES)}")
        for joint, value in pose.items():
            if joint not in self.rig["parts"] or joint == self.rig["root"]:
                raise ValueError(f"{joint!r} is not an animatable joint of {self.rig_type}")
            value = tuple(float(c) for c in value)
            if len(value) not in (3, 6):
                raise ValueError(f"{joint}: give (x, y, z) or (x, y, z, px, py, pz)")
            self.keys = [k for k in self.keys if not (k[0] == frame and k[1] == joint)]
            self.keys.append((frame, joint, value, ease))
        return self

    def value_at_or_before(self, joint, frame):
        found = [k for k in self.keys if k[1] == joint and k[0] <= frame]
        return max(found, key=lambda k: k[0])[2] if found else (0.0, 0.0, 0.0)

    def full(self, frame, pose, ease="cubic_inout"):
        """Key EVERY joint: listed ones get the new value, the rest keep their last keyed value."""
        joints = [j for j in self.rig["parts"] if j != self.rig["root"]]
        full = {j: pose.get(j, self.value_at_or_before(j, frame)) for j in joints}
        return self.key(frame, full, ease)

    def hold(self, frame, until, ease="cubic_inout"):
        """Keep the pose keyed at `frame` (all joints) still until `until`."""
        joints = [j for j in self.rig["parts"] if j != self.rig["root"]]
        self.key(until, {j: self.value_at_or_before(j, frame) for j in joints}, ease)
        return self

    def offset(self, joint, frames):
        """Overlap / follow-through: delay every key of one joint by `frames` (wraps around on loops)."""
        moved = []
        for f, j, v, e in self.keys:
            if j == joint:
                if self.loop and f == self.length:
                    continue  # the loop is closed again in build()
                # one-shots aren't clamped at the end: `length` may still change after this call
                f = (f + frames) % self.length if self.loop else max(0, f + frames)
            moved.append((f, j, v, e))
        self.keys = moved
        return self

    def lock_feet(self, start=0, end=None, legs=("Right Leg", "Left Leg"), targets=None):
        """R6: keep these feet exactly where they are at `start` for every frame up to `end`, by solving
        the legs frame by frame after the keys are in (the in-betweens of fast moves drag planted feet
        otherwise). The legs get a key on every frame of that stretch. Lift a foot to step: end the lock."""
        self.locks.append((start, self.length if end is None else end, tuple(legs), targets))
        return self

    def marker(self, frame, name, value=""):
        """KeyframeMarker (animation event), e.g. "Hit" on the impact frame. Scripts listen with
        track:GetMarkerReachedSignal(name)."""
        self.markers.append((frame, name, str(value)))
        return self

    def _close_loop(self):
        """Make the motion periodic: every joint's keys in [0, length) are repeated one cycle before
        and after, so frame 0 and frame `length` match and smooth curves keep their speed through
        the seam."""
        L = self.length
        for j in {k[1] for k in self.keys}:
            if any(k[1] == j and (k[0] < 0 or k[0] > L) for k in self.keys):
                continue  # already closed
            ks = {k[0]: k for k in self.keys if k[1] == j and 0 <= k[0] <= L}
            if L in ks and 0 not in ks:
                f, _, v, e = ks.pop(L)
                ks[0] = (0, j, v, e)
            ks.pop(L, None)
            period = sorted(ks.values(), key=lambda k: k[0])
            self.keys = [k for k in self.keys if k[1] != j]
            for shift in (-L, 0, L):
                self.keys += [(f + shift, j, v, e) for f, _, v, e in period]

    def _pose_now(self, arm):
        """The pose language values of every joint at the current frame, read back from the bones."""
        pose = {}
        for _, _, joint, _, _ in self.rig["joints"]:
            pb = arm.pose.bones[joint]
            e = pb.rotation_quaternion.to_euler("ZYX")  # matrix Rx*Ry*Rz, like CFrame.Angles
            pose[joint] = (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z), *pb.location)
        return pose

    def _apply_locks(self, arm):
        if self.rig_type != "R6":
            raise ValueError("lock_feet() solves R6 legs; on R15 plant the feet with IK")
        scene = bpy.context.scene
        solved = {}
        for start, end, legs, targets in self.locks:  # solve everything first: new keys change later frames
            scene.frame_set(start)
            targets = targets or soles(self._pose_now(arm), self.rig_type, self.props)
            for f in range(start, end + 1):
                scene.frame_set(f)
                p = plant(self._pose_now(arm), targets, self.rig_type, legs, grounded=False)
                for leg in legs:
                    solved[(f, leg)] = p[leg]
        last = {}
        for (f, leg), v in sorted(solved.items(), key=lambda kv: (kv[0][1], kv[0][0])):
            pb = arm.pose.bones[leg]
            q = rigs.angles(*v[:3]).to_quaternion()
            if leg in last and last[leg].dot(q) < 0:
                q.negate()
            last[leg] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f)
        for leg in {leg for _, leg in solved}:
            for fc in fcurves_of(arm, leg):
                for kp in fc.keyframe_points:
                    if (int(round(kp.co.x)), leg) in solved:
                        kp.interpolation = "LINEAR"
                fc.update()
        scene.frame_set(0)

    # ---- Blender ---------------------------------------------------------------------------
    def build(self, location=(0.0, 0.0, 0.0)):
        """(Re)build the rig and write this animation as Blender keyframes. Returns the armature."""
        scene = bpy.context.scene
        scene.render.fps, scene.render.fps_base = self.fps, 1.0
        scene.frame_start, scene.frame_end = 0, self.length

        arm = bpy.data.objects.get(self.name)
        if arm is not None:
            coll = bpy.data.collections.get(self.name)
            for o in list(coll.objects) if coll else [arm]:
                bpy.data.objects.remove(o)
            if coll:
                bpy.data.collections.remove(coll)
        arm = rigs.build(self.rig_type, name=self.name, props=self.props, location=location)

        if self.loop:
            self._close_loop()

        arm.animation_data_create()
        action = bpy.data.actions.new(self.name)
        arm.animation_data.action = action
        last_q = {}
        for frame, joint, value, ease in sorted(self.keys, key=lambda k: (k[1], k[0])):
            pb = arm.pose.bones[joint]
            q = rigs.angles(*value[:3]).to_quaternion()
            if joint in last_q and last_q[joint].dot(q) < 0:
                q.negate()  # keep the short way round, like Roblox does
            last_q[joint] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=frame)
            if len(value) == 6:
                pb.location = value[3:]
                pb.keyframe_insert("location", frame=frame)
        for frame, joint, value, ease in self.keys:
            interp, easing, _ = EASES[ease]
            for fc in fcurves_of(arm, joint):
                for kp in fc.keyframe_points:
                    if abs(kp.co.x - frame) < 0.01:
                        kp.interpolation = interp
                        kp.easing = easing
                        if interp == "BEZIER":
                            kp.handle_left_type = kp.handle_right_type = "AUTO_CLAMPED"
        for fc in all_fcurves(arm):
            fc.update()
        if self.locks:
            self._apply_locks(arm)

        for frame, name, value in self.markers:
            m = action.pose_markers.new(f"{name}:{value}" if value else name)
            m.frame = frame
        arm["rbx_anim"] = json.dumps({
            "name": self.name, "rig": self.rig_type, "props": list(self.props), "length": self.length,
            "fps": self.fps, "loop": self.loop, "priority": self.priority, "style": self.style,
            "slides": self.slides,
        })
        scene.frame_set(0)
        return arm


def chain(name, anims, gap=0):
    """One long animation from several (same rig), back to back with `gap` frames between: for showreels."""
    first = anims[0]
    out = Anim(name, rig=first.rig_type, props=first.props, fps=first.fps, priority=first.priority)
    t = 0
    for a in anims:
        if (a.rig_type, a.props) != (first.rig_type, first.props):
            raise ValueError("chain() needs animations on the same rig and props")
        out.keys += [(f + t, j, v, e) for f, j, v, e in a.keys if 0 <= f <= a.length]
        out.markers += [(f + t, n, v) for f, n, v in a.markers]
        t += a.length + gap
    out.length = t - gap
    return out


def all_fcurves(arm):
    from bpy_extras import anim_utils
    ad = arm.animation_data
    if not ad or not ad.action:
        return []
    bag = anim_utils.animdata_get_channelbag_for_assigned_slot(ad)
    return list(bag.fcurves) if bag else []


def fcurves_of(arm, joint):
    prefix = f'pose.bones["{joint}"].'
    return [fc for fc in all_fcurves(arm) if fc.data_path.startswith(prefix)]


def load(path, build=True):
    """Run an animation script (anims/<Name>.py) and return its Anim, built in the scene."""
    import os
    import sys
    folder = os.path.dirname(os.path.abspath(path))
    if folder not in sys.path:
        sys.path.insert(0, folder)  # so anims can share helpers (anims/_lib.py)
    for mod_name, mod in list(sys.modules.items()):  # helpers in anims/ re-import fresh every run
        if os.path.dirname(os.path.abspath(getattr(mod, "__file__", None) or "")) == folder:
            del sys.modules[mod_name]
    ns = {"__name__": "anim_script", "__file__": path}
    with open(path, encoding="utf-8") as f:
        exec(compile(f.read(), path, "exec"), ns)
    anim = ns["build"]()
    if build:
        anim.build()
    return anim
