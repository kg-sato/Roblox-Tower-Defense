"""Blender animation -> Roblox KeyframeSequence (.rbxmx file, command-bar .luau, and .json).

For every joint, each authored key becomes a Roblox Pose with the matching easing. Stretches whose
Blender curve has no Roblox easing (back, expo, bezier...) are baked frame by frame. The result is then
replayed the way Roblox plays it and compared with Blender, frame by frame, joint by joint; anything
that drifts more than TOLERANCE_DEG gets baked too. So what you saw in Blender is what Roblox plays.
"""
import json
import math
import os

import bpy
from mathutils import Matrix, Quaternion

import animkit
import rigs

TOLERANCE_DEG = 1.0
TOLERANCE_STUDS = 0.02
# Measured in Studio: between two poses Roblox doesn't follow a pure slerp; the gap grows with the size of
# the step (3.5 deg off on a 58 deg step, invisible on small ones). Steps bigger than this get baked.
MAX_STEP_DEG = 30.0

# Blender (interpolation, easing) -> Roblox (PoseEasingStyle, PoseEasingDirection)
ROBLOX_EASE = {}
for _name, (_interp, _easing, _rbx) in animkit.EASES.items():
    if _rbx:
        ROBLOX_EASE[(_interp, _easing)] = _rbx
for _easing in ("AUTO", "EASE_IN", "EASE_OUT", "EASE_IN_OUT"):
    ROBLOX_EASE[("CONSTANT", _easing)] = ("Constant", "Out")
    ROBLOX_EASE[("LINEAR", _easing)] = ("Linear", "In")


def _bounce_out(t):
    if t < 1 / 2.75:
        return 7.5625 * t * t
    if t < 2 / 2.75:
        t -= 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    if t < 2.5 / 2.75:
        t -= 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    t -= 2.625 / 2.75
    return 7.5625 * t * t + 0.984375


def _elastic_out(t):  # measured: Penner elastic, period 0.3, amplitude 1
    if t <= 0 or t >= 1:
        return float(t >= 1)
    return 2 ** (-10 * t) * math.sin((t - 0.075) * 2 * math.pi / 0.3) + 1


def roblox_alpha(style, direction, t):
    """How far Roblox is between two poses at t in [0, 1], as measured in Studio (see GUIDE.md).
    Easing comes from the EARLIER pose of the pair."""
    if style == "Linear":
        return t
    if style == "Constant":  # In snaps to the next pose at once, Out holds, InOut switches halfway
        return {"In": 1.0 if t > 0 else 0.0, "Out": 1.0 if t >= 1 else 0.0}.get(direction, float(t >= 0.5))
    if style in ("CubicV2", "Cubic"):
        if style == "Cubic":  # legacy Cubic has In and Out swapped
            direction = {"In": "Out", "Out": "In"}.get(direction, direction)
        if direction == "In":
            return t ** 3
        if direction == "Out":
            return 1 - (1 - t) ** 3
        return 4 * t ** 3 if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2
    if style == "Bounce" and direction in ("In", "Out"):  # Roblox's Bounce InOut is off; never mapped
        return _bounce_out(t) if direction == "Out" else 1 - _bounce_out(1 - t)
    if style == "Elastic" and direction in ("In", "Out"):
        return _elastic_out(t) if direction == "Out" else 1 - _elastic_out(1 - t)
    raise ValueError(f"no Roblox model for {style} {direction}")


def _lerp_cf(a, b, alpha):
    """CFrame:Lerp, including alpha outside 0..1 (elastic overshoot extrapolates)."""
    qa, qb = a.to_quaternion(), b.to_quaternion()
    d = qa.rotation_difference(qb)
    if d.w < 0:
        d.negate()
    axis, ang = d.to_axis_angle()
    q = qa @ Quaternion(axis, ang * alpha)
    m = q.to_matrix().to_4x4()
    m.translation = a.translation.lerp(b.translation, alpha)
    return m


def _angle(a, b):
    """Degrees between two rotations, the short way (q and -q are the same rotation)."""
    ang = math.degrees(a.to_quaternion().rotation_difference(b.to_quaternion()).angle)
    return min(ang, 360 - ang)


def anim_meta(arm):
    meta = json.loads(arm.get("rbx_anim", "{}"))
    meta.setdefault("name", arm.name)
    meta.setdefault("rig", arm.get("rbx_rig", "R6"))
    meta.setdefault("props", [p for p in arm.get("rbx_props", "").split(",") if p])
    meta.setdefault("fps", bpy.context.scene.render.fps)
    meta.setdefault("length", bpy.context.scene.frame_end)
    meta.setdefault("loop", False)
    meta.setdefault("priority", "Action")
    return meta


def sample(arm, rig, length):
    """Motor6D.Transform of every joint on every frame 0..length, as Blender evaluates it."""
    scene = bpy.context.scene
    keep = scene.frame_current
    frames = []
    for f in range(length + 1):
        scene.frame_set(f)
        frames.append(rigs.motor_transforms(arm, rig))
    scene.frame_set(keep)
    return frames


def _authored_keys(arm, joint, length):
    """{frame: (interpolation, easing)} of the joint's keys inside 0..length."""
    keys = {}
    for fc in animkit.fcurves_of(arm, joint):
        for kp in fc.keyframe_points:
            f = int(round(kp.co.x))
            if 0 <= f <= length and f not in keys:
                keys[f] = (kp.interpolation, kp.easing)
    return keys


def build_tracks(arm, rig, length, samples):
    """Per joint: list of (frame, transform, style, direction). Returns (tracks, report)."""
    tracks, report = {}, {}
    for _, _, joint, _, _ in rig["joints"]:
        keys = _authored_keys(arm, joint, length)
        if not keys:
            continue
        frames = sorted(set(keys) | {0, length})
        poses, baked = [], 0
        for a, b in zip(frames, frames[1:]):
            ease = ROBLOX_EASE.get(keys.get(a, ("BAKE", "")))
            if b - a > 1 and _angle(samples[a][joint], samples[b][joint]) > MAX_STEP_DEG:
                ease = None  # a big turn between two keys: give Roblox every frame
            if ease is None:
                for f in range(a, b):
                    poses.append((f, samples[f][joint], "Linear", "In"))
                baked += b - a
            else:
                poses.append((a, samples[a][joint], *ease))
        poses.append((frames[-1], samples[frames[-1]][joint], "Linear", "In"))

        # replay the Roblox way and bake any stretch that drifts from Blender
        changed = True
        while changed:
            changed = False
            for i, (a, cfa, style, direction) in enumerate(poses[:-1]):
                b, cfb = poses[i + 1][0], poses[i + 1][1]
                worst, worst_f = 0.0, None
                for f in range(a + 1, b):
                    t = (f - a) / (b - a)
                    got = _lerp_cf(cfa, cfb, roblox_alpha(style, direction, t))
                    want = samples[f][joint]
                    err = max(_angle(got, want), (got.translation - want.translation).length / TOLERANCE_STUDS * TOLERANCE_DEG)
                    if err > worst:
                        worst, worst_f = err, f
                if worst_f is not None and _angle(cfa, cfb) > MAX_STEP_DEG:
                    worst, worst_f = TOLERANCE_DEG + 1, (a + b) // 2  # split big steps too
                if worst > TOLERANCE_DEG:
                    poses[i] = (a, cfa, "Linear", "In")
                    poses.insert(i + 1, (worst_f, samples[worst_f][joint], "Linear", "In"))
                    baked += 1
                    changed = True
                    break
        tracks[joint] = poses
        report[joint] = {"keys": len(poses), "baked": baked}
    return tracks, report


def markers_of(arm):
    out = []
    action = arm.animation_data.action if arm.animation_data else None
    for m in (action.pose_markers if action else []):
        name, _, value = m.name.partition(":")
        out.append((int(m.frame), name, value))
    return sorted(out)


def to_data(arm):
    meta = anim_meta(arm)
    rig = rigs.with_props(meta["rig"], meta["props"])
    length, fps = meta["length"], meta["fps"]
    samples = sample(arm, rig, length)
    tracks, report = build_tracks(arm, rig, length, samples)
    markers = markers_of(arm)

    times = sorted({f for poses in tracks.values() for f, *_ in poses} | {f for f, _, _ in markers})
    keyframes = []
    for f in times:
        poses = {}
        for joint, track in tracks.items():
            for pf, cfm, style, direction in track:
                if pf == f:
                    poses[joint] = {"cf": rigs.cf_components(cfm), "style": style, "dir": direction}
        keyframes.append({
            # rounded DOWN: a key must never sit a hair after its frame, or a `constant` hold would still
            # show the old pose on the frame where it should snap
            "time": math.floor(f / fps * 1e5) / 1e5,
            "poses": poses,
            "markers": [[n, v] for mf, n, v in markers if mf == f],
        })
    parents = {p1: p0 for _, p0, p1, _, _ in rig["joints"]}
    data = {
        "name": meta["name"], "rig": meta["rig"], "props": meta["props"], "loop": meta["loop"],
        "slides": meta.get("slides", False),
        "priority": meta["priority"], "fps": fps, "length": length, "root": rig["root"],
        "parents": parents, "keyframes": keyframes,
    }
    return data, report, samples


# ---- writers ----------------------------------------------------------------------------------

LUAU_BUILDER = r'''
-- Built by the fwjelaa animation method. Paste into Studio's command bar (View > Command Bar) in
-- Edit mode and press Enter. Creates ServerStorage.Animations["{name}"] (a KeyframeSequence),
-- which the Animation Editor and Moon Animator 2 can open (see GUIDE.md).
local HttpService = game:GetService("HttpService")
local data = HttpService:JSONDecode([==[{json}]==])
local function build(data)
	local kfs = Instance.new("KeyframeSequence")
	kfs.Name = data.name
	kfs.Loop = data.loop
	kfs.Priority = Enum.AnimationPriority[data.priority]
	for _, k in ipairs(data.keyframes) do
		local kf = Instance.new("Keyframe")
		kf.Time = k.time
		local made = {}
		local function poseFor(part)
			if made[part] then return made[part] end
			local p = Instance.new("Pose")
			p.Name = part
			p.Weight = 0 -- placeholder unless keyed below
			p.CFrame = CFrame.identity
			local parent = data.parents[part]
			p.Parent = parent and poseFor(parent) or kf
			made[part] = p
			return p
		end
		for part, pose in pairs(k.poses) do
			local p = poseFor(part)
			p.CFrame = CFrame.new(table.unpack(pose.cf))
			p.EasingStyle = Enum.PoseEasingStyle[pose.style]
			p.EasingDirection = Enum.PoseEasingDirection[pose.dir]
			p.Weight = 1
		end
		for _, m in ipairs(k.markers) do
			local marker = Instance.new("KeyframeMarker")
			marker.Name = m[1]
			marker.Value = m[2]
			marker.Parent = kf
		end
		kf.Parent = kfs
	end
	return kfs
end
local folder = game.ServerStorage:FindFirstChild("Animations") or Instance.new("Folder")
folder.Name = "Animations"
folder.Parent = game.ServerStorage
local old = folder:FindFirstChild(data.name)
if old then old:Destroy() end
local kfs = build(data)
kfs.Parent = folder
print(("Animation %s ready: ServerStorage.Animations.%s (%d keyframes)"):format(data.name, data.name, #data.keyframes))
return kfs
'''


def write_luau(data, path):
    text = LUAU_BUILDER.replace("{json}", json.dumps(data, separators=(",", ":"))).replace("{name}", data["name"])
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text.lstrip())


def _xml_escape(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


_STYLE_TOKEN = {"Linear": 0, "Constant": 1, "Elastic": 2, "Cubic": 3, "Bounce": 4, "CubicV2": 5}
_DIR_TOKEN = {"In": 0, "Out": 1, "InOut": 2}
_PRIORITY_TOKEN = {"Idle": 0, "Movement": 1, "Action": 2, "Action2": 3, "Action3": 4, "Action4": 5, "Core": 1000}


def write_rbxmx(data, path):
    """KeyframeSequence as a Roblox XML model: drag it into Studio or use File > Import / Insert from File."""
    ref = [0]

    def item(cls, props, children):
        ref[0] += 1
        return f'<Item class="{cls}" referent="RBX{ref[0]}"><Properties>{props}</Properties>{children}</Item>'

    def cframe(name, c):
        tags = ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"]
        return f'<CoordinateFrame name="{name}">' + "".join(f"<{t}>{v}</{t}>" for t, v in zip(tags, c)) + "</CoordinateFrame>"

    children_of = {}
    for child, parent in data["parents"].items():
        children_of.setdefault(parent, []).append(child)

    def pose_xml(part, poses):
        keyed = part in poses
        p = poses.get(part, {"cf": [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1], "style": "Linear", "dir": "In"})
        kids = "".join(pose_xml(c, poses) for c in children_of.get(part, []) if _subtree_keyed(c, poses))
        props = (f'<string name="Name">{_xml_escape(part)}</string>' + cframe("CFrame", p["cf"])
                 + f'<token name="EasingDirection">{_DIR_TOKEN[p["dir"]]}</token>'
                 + f'<token name="EasingStyle">{_STYLE_TOKEN[p["style"]]}</token>'
                 + f'<float name="Weight">{1 if keyed else 0}</float>')
        return item("Pose", props, kids)

    def _subtree_keyed(part, poses):
        return part in poses or any(_subtree_keyed(c, poses) for c in children_of.get(part, []))

    kfs = []
    for k in data["keyframes"]:
        inner = pose_xml(data["root"], k["poses"]) if _subtree_keyed(data["root"], k["poses"]) else ""
        for name, value in k["markers"]:
            inner += item("KeyframeMarker", f'<string name="Name">{_xml_escape(name)}</string>'
                          f'<string name="Value">{_xml_escape(value)}</string>', "")
        kfs.append(item("Keyframe", f'<string name="Name">Keyframe</string><float name="Time">{k["time"]}</float>', inner))
    root = item("KeyframeSequence",
                f'<string name="Name">{_xml_escape(data["name"])}</string>'
                f'<bool name="Loop">{"true" if data["loop"] else "false"}</bool>'
                f'<token name="Priority">{_PRIORITY_TOKEN[data["priority"]]}</token>', "".join(kfs))
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">' + root + "</roblox>")


def export(arm=None, out_dir=None):
    """Export the animation on `arm` (default: the active armature). Returns a short report string."""
    arm = arm or bpy.context.view_layer.objects.active
    if arm is None or arm.type != "ARMATURE":
        arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE" and "rbx_rig" in o)
    out_dir = out_dir or os.path.join(os.path.dirname(os.path.dirname(__file__)), "out")
    os.makedirs(out_dir, exist_ok=True)
    data, report, samples = to_data(arm)
    name = data["name"]
    with open(os.path.join(out_dir, f"{name}.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    write_luau(data, os.path.join(out_dir, f"{name}.luau"))
    write_rbxmx(data, os.path.join(out_dir, f"{name}.rbxmx"))
    # what Blender shows on every frame, so Studio can check its playback against it (roblox/verify.luau)
    os.makedirs(os.path.join(out_dir, "verify"), exist_ok=True)
    with open(os.path.join(out_dir, "verify", f"{name}.json"), "w", encoding="utf-8") as f:
        json.dump([{j: rigs.cf_components(m) for j, m in s.items()} for s in samples], f, separators=(",", ":"))
    import checks
    issues = checks.run(arm, data, samples)
    lines = [f"EXPORTED {name}: {len(data['keyframes'])} keyframes, {data['length']} frames "
             f"({data['length'] / data['fps']:.2f}s), loop={data['loop']}, priority={data['priority']}"]
    lines += [f"  {j}: {r['keys']} poses ({r['baked']} baked)" for j, r in report.items()]
    lines += ["  files: out/%s.rbxmx  out/%s.luau  out/%s.json" % (name, name, name)]
    lines += ["CHECKS: " + ("all clear" if not issues else f"{len(issues)} to look at")] + [f"  - {i}" for i in issues]
    return "\n".join(lines)
