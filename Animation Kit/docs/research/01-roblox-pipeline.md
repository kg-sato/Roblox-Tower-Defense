# 01 - Roblox side of the pipeline: Blender animation -> Roblox Studio (R6 first, R15 too)

Research date: 2026-10-21. Every claim carries a tag:

- **[DOC]** official Roblox Creator Docs (the `Roblox/creator-docs` GitHub source; date = last commit to that file)
- **[STAFF]** DevForum post by a Roblox Staff account
- **[COMMUNITY]** DevForum or GitHub content by non-staff users
- **[ENGINE]** checked live in Roblox Studio **0.743.0.7431133** on 2026-10-21 via the Studio MCP (`execute_luau`). Rigs were built in memory or parented to Workspace for a few seconds and destroyed again; nothing was saved.
- **[UNVERIFIED]** could not confirm; do not state it as fact in the video

---

## 0. Things that changed recently (read this first)

1. **Avatar Joint Upgrade (AJU)**: R15 player characters now spawn with `AnimationConstraint` + `BallSocketConstraint` instead of `Motor6D`. Phase 2 has been rolling out since 2026-05-27: `StarterPlayer.AvatarJointUpgrade = Default` now means **Enabled**. Phase 3 (no opt-out at all) is targeted for the end of 2026. **R6 is not affected.** Staff said on 2026-01-26 and again on 2026-05-27 that R6 games are unaffected. [STAFF] [DOC Motor6D/AnimationConstraint pages]
   - On AnimationConstraint, `C0/C1/Part0/Part1` are **read-only** aliases for `Attachment0.CFrame`, `Attachment1.CFrame`, `Attachment0.Parent` and `Attachment1.Parent`. Writing to them throws. `Transform` works exactly like `Motor6D.Transform`, and the Animator writes it every frame. [DOC] [STAFF]
   - [ENGINE] `Players:CreateHumanoidModelFromDescription(desc, R15)` returned AnimationConstraints in this Studio build, and the R6 call returned Motor6Ds.
   - Staff said Motor6D "will be marked deprecated in favor of AnimationConstraints" (2026-01-26). The Motor6D API page now reads "Superseded by AnimationConstraint for avatar/character rigs" (doc updated 2026-09-22).
2. **Animation Clip Editor (ACE) importer rewrite.** Beta 2026-01-15, GA 2026-03-31. It uses the same code path as Import 3D, imports FBX **and glTF**, handles several clips per file, and auto-saves the clips into `ServerStorage/RBX_ANIMSAVES`. More import settings arrived on 2026-08-04: Rig Scale, Rest Pose Source, Rig Type, and track selection. [STAFF]
3. **Animation permissions overhaul (2025-07-31) and sharing (2025-08-21).** An animation **no longer has to be owned by the experience owner**. The experience needs *permission* to use it instead. [STAFF]
4. **Open Cloud can upload animations (2025-10-23).** It takes `.rbxm`/`.rbxmx` with content type `model/x-rbxm`. The legacy `UploadNewAnimation` endpoint was turned off around 2026-03-09. [STAFF] [DOC]
5. **Adaptive Animation** went GA on 2026-04-29 (HumanoidRigDescription retargeting). Since then several people have reported broken **R6 Blender imports** (torso doesn't move, with the message "Torso has animation data but isn't moving. Turn off the Adaptive Animations beta feature in Studio."). Reports run from 2026-05-14 to 2026-07-02. Staff asked for repro files on 2026-05-15, and no fix announcement was found. [COMMUNITY] [STAFF]
6. **CubicV2** easing (engine v646, Oct 2024) replaces the buggy `Cubic`. [STAFF] [DOC]

---

## 1. Official ways to get a Blender animation into Studio

### 1a. Animation Clip Editor (ACE, "Animation Editor" / "Clip Editor") -> Import

- **Menu path (current docs):** `...` (next to the rig name or in the playback controls) -> **Import -> From File** -> pick `.fbx` or `.gltf/.glb` -> **Import Settings** dialog -> **Import**. [DOC avatar/animation-packs.md, 2026-09-10; avatar/emotes/import.md, 2026-08-25]. The older label **"Import -> From FBX Animation"** still appears in the Maya guide [DOC export-avatar-animations-from-maya.md, 2026-08-25]. The exact label in today's build is [UNVERIFIED], so check it on screen.
- **The main Animation Editor doc page (`animation/editor.md`) has never documented FBX import.** It has zero mentions of "FBX" in all 22 commits from 2023-08-29 to 2026-10-15. The import steps only live in the emote, animation-pack and Maya pages. [DOC]
- **Import Settings (since 2026-08-04)** [STAFF bballerblox, "Animation Import Improvements"]:
  - **Rig Scale** plus a scale factor, for files not authored in studs. Staff: "A stud is 0.28 meters, or 11.02 inches."
  - **Rest Pose Source**: pick which track supplies the rest pose. Before this, the rest pose was always the first frame of the first track. Options include **Imported Rig** (rest pose from the file's rig) and **Imported Rig (Zeroed Rotations)** (zeroes all bone rotations first). The animation-pack doc says to pick "Imported Rig".
  - **Rig Type: R15 or Custom.** There is **no R6 option**, so an R6 animation is a "Custom" rig as far as the importer is concerned. The same goes for Import 3D, whose Rig Type is R15 / Custom / No Rig [DOC studio/importer.md, 2026-10-21].
  - **Animation track selection**: choose which clip in the file to load.
  - Import 3D gains an "Animation General" section. Its **"Default with rotations"** option keeps the original global rotations [STAFF georjozh, 2026-08-04 reply].
- **Since 2026-01-15** [STAFF bballerblox, "[Full Release] Animation Clip Editor: Improved Importing and glTF Support"]: imported clips are saved automatically to `ServerStorage/RBX_ANIMSAVES` under the clip's name in the file (local only, so a separate upload step is still needed). Multiple clips per file are supported and swapped in with the **Load** menu. A bug that rotated some animations by 180 degrees was fixed during the beta (fix confirmed 2026-02-11, GA 2026-03-31). Staff also said that "the old importer wasn't always reliable".
- **Rig types it drives:** both Motor6D (part) rigs and skinned Bone rigs. Poses are matched **by name**. Motor6D.ChildName/ParentName mirror the Part1/Part0 names, and "the animation system uses this name to match the joint against the corresponding pose channel in an animation, so a rig's part names must line up with the names authored in its animations" [DOC Motor6D.yaml, 2026-09-22]. The Maya guide says the joint hierarchy and naming must match "exactly", and lists R15 names starting at Root > HumanoidRootPart > LowerTorso ... [DOC].
  - For an **R6** FBX, the bones must therefore be named exactly like the parts: `HumanoidRootPart`, `Torso`, `Head`, `Left Arm`, `Right Arm`, `Left Leg`, `Right Leg` (with spaces), parented HRP > Torso > limbs/head. This is **inferred** from the name-matching rule above; no official R6 FBX spec was found [UNVERIFIED as an official spec].
- **Importer quirks found by the community** [COMMUNITY sakura_soyuta / Candy_Project, 2026-08-05 in the "Animation Import Improvements" thread]:
  - A mesh object (FBX) or mesh data (glTF) **named like a bone** turns that bone into a Motor6D.
  - Motor6Ds were imported with **rest-pose rotations zeroed**, which is why "Zeroed Rotations" exists.
  - For R15, meshes named `{Name}_Geo` are associated with bone `{Name}`, but not for custom rigs.
  - A bone with the same name as an exported object can get deleted.
- **Axes:** Roblox is +Y up / -Z forward and Blender is +Z up / -Y forward. Blender's FBX exporter defaults ("Use Space Transform") handle meshes [COMMUNITY keyre124, 2026-01-16]. Keep the same Forward/Up settings for the model and its animations [COMMUNITY Candy_Project, 2026-08-10].
- **Frame rate / frame range:** `Keyframe.Time` is in seconds (float), so the clip's timing is resolution-independent [DOC]. Blender writes frames outside the loop range unless the frame range is set explicitly (NLA strip or Dope Sheet end frame) [STAFF OriginalSleepyhead, 2026-01-21]. How the ACE importer resamples FBX frame rates is [UNVERIFIED]. Den_S's own advice for his tool is "step rate of 1 at 30 fps" [COMMUNITY].
- **Known R6 problems:**
  - Adaptive Animation (GA 2026-04-29) broke R6 Blender imports for several users: "Torso has animation data but isn't moving", and the suggested beta toggle doesn't exist. Reported on t/4636035 (2026-05-14, staff asked for files 2026-05-15) and t/4713305 (2026-07-02, via both the Blender Animations plugin and ACE FBX import). During the beta, R6 torsos couldn't be rotated at all (t/4148296, 2025-12-13; t/4151404, staff 2026-01-05: "not planning on enabling the beta before all issues are resolved"). [COMMUNITY] [STAFF]
  - A community workaround is to set `Workspace.Retargeting` (enum `AnimatorRetargetingMode`) to disabled [COMMUNITY, not confirmed to work].
  - **[ENGINE] My test:** a script-built KeyframeSequence with a `Torso` pose **does** drive the R6 `RootJoint` correctly at runtime (registered clip + `Animator:StepAnimations`, `Workspace.Retargeting = Default`). If the bug still exists, it is in the import path rather than in playback. [UNVERIFIED which]
- **Curve animations:** Curve Editor converts a `KeyframeSequence` into a `CurveAnimation` (**irreversible**). Euler or Quaternion rotation type has to be chosen *before* converting. Bounce/Elastic are not native in curves and get baked into extra keys [DOC curve-editor.md, 2026-04-28]. **Emotes and Marketplace animation packs must be CurveAnimation** [DOC emotes/specifications.md, avatar/animation-packs.md]. Ordinary in-game animations can stay KeyframeSequence.

### 1b. Import 3D (File -> Import / Avatar -> Import)

- `.fbx` and `.gltf` support "rigs ... animation data" [DOC importer.md]. Since 2022 an animation inside an FBX appears as a separate node named `"rigName"_"animName"_Animation` and was **uploaded to the Toolbox on import**; multiple clips must be in separate animation stacks [STAFF sonlytheonetime1, 2022-04-06]. Today, with "Upload to Roblox" on, the asset gets uploaded, and the 2026-01-15 FAQ says Import 3D can upload animations "directly as animation assets" [STAFF].
- Since 2026-08-04, animations on imported models are also saved into AnimSaves automatically (when the ACE is open) [STAFF].

### 1c. Related new tools (context only)

- Animation Graphs full release on 2026-07-15 (blend trees and state machines, stored under RBX_ANIMSAVES) [STAFF]. Adaptive Animation GA on 2026-04-29 [STAFF].

---

## 2. Community Blender <-> Roblox animation tools

| Tool | What it is | Status (2026-10-21) | Links |
|---|---|---|---|
| **Den_S "Blender rig exporter/animation importer"** | The original. A Studio plugin plus a single-file Blender addon "Rbx Animations" | Thread created 2017-03-30, OP last edited 2023-01-31, 1,956 posts, last post 2026-09-17. Addon `bl_info` targets Blender 2.80. Community reports are mixed: "not compatible with 4.3+" (2024-12), "works on 4.4" (2025-04), "works on 4.5.1" (2025-08), and broken torso on 5.0 (2025-12-10). An updated community script (pastebin DhTbba6C, "3.0 - 4.2+, 4.3 not supported", 2025-02-20) also exists. **Effectively superseded.** | devforum.roblox.com/t/34729 - plugin roblox.com/library/716953901 - addon pastebin.com/raw/V5aBemWL |
| **Cautioned "RBXMonkey"** (formerly "Blender Animations (ultimate edition)"), a fork of Den_S | Blender extension plus Studio plugin | **Actively maintained.** GitHub repo created 2025-10-26, 110 stars, GPL-3.0. Releases v2.4.1 (2026-02-28) through **v3.1.2 (2026-10-17)**. `blender_manifest.toml`: `blender_version_min = "4.2.0"`. Thread post #1628 (edited 2025-10-27): "Supports up to blender 5.0, 4.2+ is recommended". | github.com/Cautioned/Blender-Animations-Plugin - Studio plugin create.roblox.com/store/asset/16708835782 - Blender Extensions listing (approval queue) |
| **Staticaliza's Blender Animation Tools** | Built on RBXMonkey, adds animator utilities and impact frames | Repo created 2026-02-21, pushed 2026-10-18. README says it supports Blender 4.2 through 5.2. GPL-3.0. Needs the RBXMonkey Studio plugin as well. | github.com/Staticaliza/Staticaliza-Blender-Animation-Tools - plugin create.roblox.com/store/asset/118148792788940 |
| **R6 IK + FK Blender Rig** (Aeresei) | Ready-made R6 control rig (IK/FK blending) | Thread created 2025-03-31, now V2.5 (edited 2026-10-19). Requires Cautioned's plugin, Blender 4.2+, and 3.1.1+ for weapon export. | devforum.roblox.com/t/3586405 |
| Yarik_superpro tutorial | Full Roblox <-> Blender pipeline (Motor6D + Bone, IK/FK) | 2025-11-02 (edited 2025-11-17) | devforum.roblox.com/t/4042154 |
| TK-DZ/Roblox-IK-R15 | R15 IK rig for the RbxAnimations addon | Last push 2024-05-04 | github.com/TK-DZ/Roblox-IK-R15 |
| "RoBlender" | **Not found** as a Roblox animation tool. "RoBlend" is an unrelated mesh-editing plugin (2024). | [UNVERIFIED / likely doesn't exist] | - |

### How they move data (exact formats)

- **Den_S (read from the addon source).** The Studio plugin's "Export rig" writes an `.obj`. Rig metadata is hidden in extra mesh names, **base32-encoded**. In Blender, "Rebuild rig" creates an armature named `__Rig`.
- "Export animation" bakes **every frame** from `frame_start` to `frame_end` in steps of `frame_step`, using `scene.render.fps`. It produces this JSON:
  ```json
  {"t": <length_seconds>, "kfs": [ {"t": <time_s>, "kf": {"<BoneName>": [x,y,z, r00,r01,r02, r10,r11,r12, r20,r21,r22]}} ]}
  ```
  The 12 numbers are CFrame components in Roblox's Y-up space. They are the **joint transform between C0 and C1**, which is exactly what `Pose.CFrame` holds. Identity poses are omitted.
- The JSON is then `json.dumps(..., separators=(',',':'))` -> `zlib.compress(level 9)` -> `base64` -> **system clipboard**. In Studio you click **"Load large animation"**, paste, and the plugin builds a KeyframeSequence; "Upload animation" publishes it.
- The original tool does not support skinned meshes or bones ("use the built-in .fbx animation importer instead").
- **RBXMonkey v3 (read from the source).** The same base payload, but each pose entry becomes `[[12 CFrame comps], "<EasingStyle>", "<EasingDirection>"]`, with optional face-control data under `"fc"` and an `"is_deform_bone_rig": true` flag for skinned rigs.
  - **Bake to clipboard**: base64 of the zlib-compressed JSON.
  - **Bake to File**: writes `.rbxanim`, the zlib-compressed JSON.
  - **Live sync**: the Blender addon runs a **local HTTP server on port 31337**, and the Studio plugin connects to it from its "Blender Sync" tab.
  - Easing mapping: Blender LINEAR -> Linear, CONSTANT -> Constant, CUBIC -> **CubicV2**, BOUNCE -> Bounce (except Bounce InOut). Anything else is baked as Linear keys. The code comments say this was "Verified against Animator:StepAnimations".
  - Supports deform-bone (skinned) rigs, IK/FK tools, weapon/prop export, and an "Import FBX animation" operator.
  - Blender operator ids worth knowing for MCP scripting: `object.rbxanims_bake` (clipboard), `object.rbxanims_bake_file` (`.rbxanim`), `object.rbxanims_genrig`, `object.rbxanims_importfbxanimation`, `object.rbxanims_mapkeyframes`.
- **Other AI-agent projects already doing "Claude + Blender MCP -> Roblox animation"** (all GitHub, all 2026; competition for the video):
  - `dillydog580/animate-roblox-characters` (created 2026-07-12). A Claude/Codex skill. Uses Blender MCP plus Cautioned's plugin, `.rbxanim` for Motor6D R6/R15 rigs, and FBX for skinned rigs.
  - `bikotoru/roblox-ai-genkidama-pipeline` (2026-08-10, Spanish). Claude Code + Blender MCP + Studio MCP, R6 + VFX.
  - `TheAstrayDev/rig-motion-skill` (2026-10-01). R6 in Blender.
  - `yansha-os/motion-tools` (2026-09-07). Its own MCP server and Studio plugin; saves KeyframeSequences.
  - `Guilherme-M-Mateus/keyframe-coach` (2026-10-20).
  - A DevForum user also reported using "Claude ... thru MCP" in Blender for Roblox animations (2026-08-11).

---

## 3. KeyframeSequence / Keyframe / Pose semantics

- **Pose -> joint:** "Although a Pose is assigned to a BasePart by name, the object manipulated during animation playback is actually the Motor6D connected to this part." Example from the docs: the R15 `LowerTorso` pose drives the joint named `Root`. "The Roblox animation system applies Pose.CFrame to the corresponding Motor6D by manipulating ... Motor6D.Transform. The original C0 and C1 values are not changed." [DOC Pose.yaml, 2026-08-25]
- **Formula, [ENGINE]-verified** (Head.CFrame matched with FuzzyEq):
  ```lua
  Part1.CFrame = Part0.CFrame * C0 * Transform * C1:Inverse()
  ```
  After `StepAnimations` to the last keyframe, `Neck.Transform` equalled that keyframe's `Pose.CFrame`.
- **Hierarchy:** poses nest by joint tree, and each Pose is named after the **child part (Part1)** of its joint.
  - **R6:** `Keyframe > HumanoidRootPart > Torso > {Head, Right Arm, Left Arm, Right Leg, Left Leg}` [ENGINE: drove RootJoint, Neck, both Shoulders and both Hips].
  - **R15:** `HumanoidRootPart > LowerTorso (joint "Root") > {UpperTorso (Waist) > {Head (Neck), LeftUpperArm (LeftShoulder) > LeftLowerArm (LeftElbow) > LeftHand (LeftWrist), RightUpperArm > RightLowerArm > RightHand}, LeftUpperLeg (LeftHip) > LeftLowerLeg (LeftKnee) > LeftFoot (LeftAnkle), RightUpperLeg > RightLowerLeg > RightFoot}`. Derived from the engine joint list in section 6.
  - The `HumanoidRootPart` pose has no joint above it and acts only as the container. Den_S's addon also ignores the root bone transform ("keeps HRP static") [COMMUNITY; engine effect of a non-identity HRP pose UNVERIFIED].
- **Pose.Weight**: `PoseBase.Weight` is **deprecated** ("Use AnimationTrack:AdjustWeight()"). [ENGINE] default = 1. `Pose.MaskWeight` is also deprecated, [ENGINE] default 0. Leave both at their defaults. [DOC]
- **Which segment does easing apply to?** `PoseBase.EasingStyle` is "the easing style to use to **reach the next Pose's value**" [DOC PoseBase.yaml]. **[ENGINE-verified]:** easing set on keyframe *k* shapes the segment k -> k+1. Putting CubicV2 In only on the *second* key left the 0 -> 1 segment linear.
- **Enum.PoseEasingStyle** [DOC, 2026-08-06]: `Linear=0, Constant=1, Elastic=2, Cubic=3 (deprecated), Bounce=4, CubicV2=5`. The default is Linear. The ACE menu offers Linear, Constant, CubicV2, Elastic and Bounce [DOC editor.md].
- **Enum.PoseEasingDirection**: `In=0, Out=1, InOut=2`. Pose default = **In** [ENGINE]. It has no effect on Linear or Constant per the docs. However, Constant does depend on direction, see below.
- **CubicV2 fix** [STAFF BloxSoMeta, 2024-10-10, bug thread from 2020-02-02]:
  - The old `Cubic` In/Out were **reversed at runtime** compared with the editor preview. InOut, Elastic, Bounce and TweenService were not affected.
  - CubicV2 (added in **v646**) "has the same behavior as Cubic inside the ACE, but reverses the direction in the engine to match".
  - The old Cubic is kept for compatibility. Third-party tools need updating to recognise CubicV2.
- **[ENGINE] easing test.** A 0 deg -> 90 deg Neck rotation over 1 s, angle sampled at t = 0.25 / 0.5 / 0.75 (Linear ideal = 22.5 / 45 / 67.5):

  | Pose easing on first key | 0.25 | 0.50 | 0.75 | Meaning |
  |---|---|---|---|---|
  | Linear (any direction) | 21.6 | 45.0 | 68.4 | linear |
  | CubicV2 In | 1.4 | 11.2 | 38.0 | slow start (t^3) |
  | CubicV2 Out | 52.0 | 78.8 | 88.6 | fast start, slow end |
  | CubicV2 InOut | 5.6 | 45.0 | 84.4 | slow both ends |
  | legacy Cubic In | 52.0 | 78.8 | 88.6 | **reversed (bug still present)** |
  | legacy Cubic Out | 1.4 | 11.2 | 38.0 | reversed |
  | Constant Out | 0 | 0 | 0 | holds the current key until the next |
  | Constant In | 90 | 90 | 90 | jumps to the next key immediately |
  | Bounce Out | 42.5 | 68.9 | 87.5 | bounces at the end (= TweenService Out) |
  | Bounce In | 2.5 | 21.1 | 47.5 | bounces at the start |
  | Elastic Out | 82.0 | 91.4 | 90.5 | overshoots near the end |
  | Elastic In | 0.5 | 1.4 | 8.0 | wind-up at the start |

  - **Conclusion:** at runtime, CubicV2, Bounce and Elastic In/Out behave like TweenService and like the ACE help text ("In - slower at the beginning"). The enum page says that "In and Out are backwards from ... TweenService" for legacy reasons; **my runtime test contradicts that for everything except legacy Cubic**. So use CubicV2 and trust the table above.
  - Minor observation: Linear rotation came out at 21.6 deg rather than 22.5 deg at 25%, which looks like normalized-quaternion lerp. Bake dense keys for very large rotations between keys.
- **KeyframeSequence.Loop / Priority** are inherited from `AnimationClip`. `AnimationTrack.Looped` and `.Priority` default to the clip's values and can be overwritten at play time [DOC AnimationClip.yaml]. [ENGINE] defaults on a script-created KeyframeSequence are `Loop = true`, `Priority = Action`, and the same for CurveAnimation. **Set both explicitly.**
- A looping clip doesn't interpolate from the last key back to the first, so duplicate the first key as the last [DOC editor.md].
- **Length** = the highest `Keyframe.Time` (seconds) [DOC]. `AnimationClip.Length` returns 0 until loaded [DOC]. Hidden `KeyframeSequence.AuthoredHipHeight` defaults to 1.35 [DOC].
- **Markers:** a `KeyframeMarker` (child of a Keyframe, `Value: string`) fires `AnimationTrack:GetMarkerReachedSignal(markerName)` with `Value` as the argument. Add one with `Keyframe:AddMarker`. Names need not be unique [DOC Keyframe.yaml, KeyframeMarker.yaml].
- Keyframe names matter for the default Animate script: when a keyframe named **`End`** is reached, it replays the animation, or returns to idle after an emote [ENGINE, Animate source; DOC editor.md: "rename the final keyframe `End` (case-sensitive)" for default replacements].
- **Max length / size limits:** **[UNVERIFIED]** for normal animations; no official limit was found. Emotes and animation-pack clips must be **10 s or less** [DOC]. Open Cloud uploads are capped at **20 MB** per file [DOC].

---

## 4. Testing an animation without publishing

- `AnimationClipProvider:RegisterAnimationClip(clip)` returns a temporary id (a **hash**; [ENGINE] e.g. `d0ca89122016407640716c54535c13a6`). `RegisterActiveAnimationClip` returns an `active://` URL instead. Both accept KeyframeSequence or CurveAnimation. The id is "temporary and cannot be used outside of Studio" [DOC AnimationClipProvider.yaml, 2026-08-25].
- `KeyframeSequenceProvider` (and its `RegisterKeyframeSequence`) is a **deprecated service** that doesn't support CurveAnimation [DOC]. Use AnimationClipProvider.
- **Where it works:**
  - [ENGINE] Edit mode via plugin/MCP: yes, but **the rig must be in the DataModel**. With an unparented rig, `track.Length` stayed 0 and nothing moved.
  - Play Solo, server and client: yes, with `Workspace.AuthorityMode = Automatic`; **no** with `AuthorityMode = Server` [COMMUNITY bug report 2026-09-26].
  - Live servers: blocked ("can only be called in Studio") [COMMUNITY 2023, 2026].
  - Multi-client test: there was a client playback problem in 2023 [COMMUNITY; current state UNVERIFIED].
- `Animator:StepAnimations(deltaTime)` advances `TimePosition` of all playing tracks and applies the pose. It is "For use in the command bar or by plugins only", and joints must be reset manually after stopping [DOC Animator.yaml, 2026-10-09]. **[ENGINE] works from the Studio MCP `execute_luau`.** Pattern used:
  ```lua
  local id = game:GetService("AnimationClipProvider"):RegisterAnimationClip(keyframeSequence)
  local anim = Instance.new("Animation"); anim.AnimationId = id
  local track = rig.Humanoid.Animator:LoadAnimation(anim)   -- rig must be parented to workspace
  local t0 = os.clock(); while track.Length == 0 and os.clock() - t0 < 3 do task.wait() end
  track:Play(0); rig.Humanoid.Animator:StepAnimations(0.5)  -- read joint.Transform / part CFrames here
  track:Stop(0); rig.Humanoid.Animator:StepAnimations(0)
  ```
- **Animation Editor save storage:**
  - Save / Save As stores a KeyframeSequence (or CurveAnimation) in `ServerStorage`. "In the rare cases that your game requires accessing local data, reference the value of the ObjectValue in your rig's `AnimSaves` folder", for example `rig.AnimSaves.Value.<SavedAnimation>` [DOC editor.md].
  - Actual layout: `ServerStorage > RBX_ANIMSAVES > <ObjectValue named like the rig> > <clips>` [STAFF 2026-02-23; COMMUNITY 2026-08-22 path "ServerStorage -> RBX_ANIMSAVES -> Rig (ObjectValue) -> AnimationGraph"; DOC animation-packs.md "ServerStorage > RBX_ANIMSAVES > [your rig]"].
  - Imported clips land here automatically (since 2026-01).
  - Making a script-created KeyframeSequence appear in the ACE "Load" list by parenting it under that ObjectValue is [UNVERIFIED but consistent with the above].
  - Large RBX_ANIMSAVES folders have caused Studio stutter and slow loads (2026 reports) [COMMUNITY].

---

## 5. Publishing / uploading

- **ACE:** `...` -> **Publish to Roblox** -> Asset Configuration (title, description, **Creator**; choose the group if the game is group-owned) -> Submit -> copy the ID from the Toolbox [DOC editor.md].
- **Explorer:** right-click the KeyframeSequence/CurveAnimation -> **Save to Roblox** -> Title, Creator, optional "Set Animation Properties" (animation type, sub-animation, parent model name, weight) [DOC animation-packs.md, 2026-09-10].
- **Import 3D** with "Upload to Roblox" on uploads the animation as an asset [STAFF 2022-04-06, 2026-01-15 FAQ].
- **Open Cloud Assets API** [DOC usage-assets.md, 2026-10-09; STAFF ThirteenDucks, 2025-10-23]:
  - `POST https://apis.roblox.com/assets/v1/assets` with `assetType: "Animation"`, file `.rbxm` or `.rbxmx`, content type **`model/x-rbxm` for both** (staff confirmed `.rbxmx`; using `model/x-rbxmx` returned 400 "not supported yet").
  - Limits: 20 MB per call, one asset per call. API key scopes `asset:read` + `asset:write`. Creator is `userId` or `groupId`.
  - The root instance must be a KeyframeSequence or CurveAnimation [COMMUNITY Asphalt README].
  - Warning: ".rbxm or .rbxmx files edited outside of Roblox Studio might not upload or function" (that includes files generated by rbx-dom or Lune) [DOC].
  - The Assets API is beta; Update Asset is beta.
  - The legacy cookie endpoint `data.roblox.com/ide/publish/UploadNewAnimation` was deprecated about 1 week after 2026-03-02 [STAFF].
  - Community tools that already upload animations this way: Asphalt (`jackTabsCode/asphalt`) and the `rblx-open-cloud` Python library (with a MIME override, 2026-02-01).
- **Ownership / permission rules (current):**
  - Since **2025-07-31**, animations are **Restricted** assets, like audio and video. They cannot be made Open Use.
  - An experience needs **permission**, which it gets in any of these ways:
    - granted in Creator Hub (experience -> Configure -> Permissions -> Assets tab, paste IDs)
    - automatically, when someone who can share the animation inserts it or playtests with it in Studio
    - by copy-pasting the Animation instance or ID (also needs share rights)
  - Animations no longer have to be re-uploaded to the experience owner, including after an ownership transfer [STAFF BobaMuncher].
  - Since **2025-08-21** you can also share with connections and groups (Creator Hub -> asset -> Permissions -> Collaborators / Experiences) [STAFF].
  - The **old rule** (pre-2025-07-31, still quoted all over the DevForum) was that the animation must be owned by the experience owner: the user, or the group for group games. Publishing under the game's owner is still the simplest path, and the docs still say to pick the group in the Creator field.

---

## 6. Standard rig joint data

### R6 [ENGINE] (`CreateHumanoidModelFromDescription(HumanoidDescription.new(), R6)`, Studio 0.743)

Part sizes (studs): **Head 2x1x1, Torso 2x2x1, HumanoidRootPart 2x2x1, Left/Right Arm 1x2x1, Left/Right Leg 1x2x1**. All joints are `Motor6D`. RootJoint is parented to HumanoidRootPart; all others are parented to Torso.

| Joint | Part0 -> Part1 | C0 | C1 |
|---|---|---|---|
| RootJoint | HumanoidRootPart -> Torso | `CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)` | `CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)` |
| Neck | Torso -> Head | `CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)` | `CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)` |
| Right Shoulder | Torso -> Right Arm | `CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)` | `CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)` |
| Left Shoulder | Torso -> Left Arm | `CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)` | `CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)` |
| Right Hip | Torso -> Right Leg | `CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)` | `CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)` |
| Left Hip | Torso -> Left Leg | `CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)` | `CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)` |

Practical consequence: because of the rotated C0/C1, a Pose rotation about local X/Y/Z does **not** map to world X/Y/Z the obvious way. For the R6 Neck and RootJoint, the joint frame is "Z up". Compute Pose CFrames through the formula in section 3 instead of guessing axes.

### R15 [ENGINE] (default HumanoidDescription body, i.e. the current default mesh body, not the Rig Builder "Block" rig)

Joints are `AnimationConstraint` (AJU active) and are **parented to Part1**. All C0/C1 rotations are identity. Values are rounded to 4 decimals.

| Joint | Part0 -> Part1 | C0 position | C1 position |
|---|---|---|---|
| Root | HumanoidRootPart -> LowerTorso | (0, -1, 0) | (0, -0.2, 0) |
| Waist | LowerTorso -> UpperTorso | (0, 0.2, 0) | (0, -0.849, 0) |
| Neck | UpperTorso -> Head | (0, 0.849, 0) | (0, -0.5758, 0) |
| LeftShoulder / RightShoulder | UpperTorso -> Left/RightUpperArm | (-/+0.9716, 0.5975, 0) | (+/-0.5005, 0.4189, 0) |
| LeftElbow / RightElbow | UpperArm -> LowerArm | (0, -0.355, 0) | (0, 0.2748, 0) |
| LeftWrist / RightWrist | LowerArm -> Hand | (0, -0.5322, 0) | (0, 0.1316, 0) |
| LeftHip / RightHip | LowerTorso -> Left/RightUpperLeg | (-/+0.5, -0.2, 0) | (0, 0.4714, 0) |
| LeftKnee / RightKnee | UpperLeg -> LowerLeg | (0, -0.4493, 0) | (0, 0.4132, 0) |
| LeftAnkle / RightAnkle | LowerLeg -> Foot | (0, -0.5965, 0) | (0, 0.106, 0) |

- Part sizes for that body: HRP 2x2x1, Head 1.159x1.182x1.161, UpperTorso 1.943x1.698x1.004, LowerTorso 1.991x0.401x1.004, UpperArm 1.001x1.242x1.002, LowerArm 1.001x1.118x1.002, Hand 0.984x0.316x1.028, UpperLeg 0.993x1.363x0.973, LowerLeg 0.993x1.301x0.973, Foot 1.009x0.312x1.001. Humanoid.HipHeight is 2.192.
- **R15 values depend on body package and scale.** The Rig Builder "Block Avatar" R15 C0/C1 values are **[UNVERIFIED]**; read them from the inserted rig at runtime instead of hardcoding.
- The 15 R15 joint names are confirmed: Root, Waist, Neck, LeftShoulder, LeftElbow, LeftWrist, RightShoulder, RightElbow, RightWrist, LeftHip, LeftKnee, LeftAnkle, RightHip, RightKnee, RightAnkle.

---

## 7. Replacing default movement animations

- **Option A (docs):** a Script in ServerScriptService. On `player.CharacterAppearanceLoaded`, stop the playing tracks and set `character.Animate.<state>.<AnimName>.AnimationId` [DOC using.md, 2026-07-07]. The Animate script reconfigures itself live because it listens to `ChildAdded`/`ChildRemoved` on each StringValue and `Changed` on each Animation [ENGINE, source].
- **Option B (no code): Studio Avatar Settings -> Movement** [DOC studio/avatar-settings.md, 2026-09-03]:
  - **Animation Packs**: Player Choice (default) / **Standard R15** / **Standard R6**.
  - **Animation Clips**: Player Choice / **Custom Clips**, which overrides "any default animation type with a custom ID ... applied on top of your selection of Animation Pack".
  - The avatar type setting is R6 / R15 / "R15 & R6".
- **Option C (community classic):** play-test, copy `Animate` from your character, paste into `StarterPlayer > StarterCharacterScripts`, and edit the IDs. This is widely used but not described in the current docs [COMMUNITY].
- **Animate script contents [ENGINE, Studio 0.743]:**
  - **R6:** `idle` (Animation1 `180435571` w=9, Animation2 `180435792` w=1), `walk` WalkAnim `180426354`, `run` RunAnim `180426354`, `jump` `125750702`, `fall` `180436148`, `climb` `180436334`, `sit` `178130996`, `toolnone` `182393478`. There are **no swim/swimidle entries**.
  - **R6 quirks** (source):
    - `onRunning` only ever plays **`walk`**, never `run`.
    - Speed scaling `AdjustSpeed(speed / 14.5)` is applied **only if the current walk AnimationId is the default `180426354`**, so a custom R6 walk plays at 1x regardless of WalkSpeed.
    - Climb uses `speed / 12.0`.
    - `jumpAnimDuration = 0.3`, `fallTransitionTime = 0.3`. Speeds are divided by `Figure:GetScale()`.
  - **R15:** idle `507766388` (w=9) / `507766666` (w=1), walk `913402848`, run `913376220`, jump `507765000`, fall `507767968`, climb `507765644`, swim `913384386`, swimidle `913389285`, sit `2506281703`, toolnone `507768375`, toolslash `522635514`, toollunge `522638767`, wave/point/dance/dance2/dance3/cheer/laugh, mood `14366558676`.
  - **R15 walk/run blend** (source, `setRunSpeed`):
    - `onRunning` triggers above `0.75 * heightScale` studs/s and calls `setAnimationSpeed(speed / 16)`.
    - Then `runSpeed = (speed/16) * 1.25 / heightScale`.
    - If `runSpeed <= 0.5`: walk only, `timeWarp = runSpeed/0.5`.
    - If `0.5 < runSpeed < 1`: crossfade by weight.
    - If `runSpeed >= 1`: run only, `timeWarp = runSpeed`.
    - At heightScale 1 that means: walk only up to 6.4 studs/s, blend to 12.8, run only above. At default WalkSpeed 16, it is run only at 1.25x speed.
    - `heightScale = HipHeight / 2`, damped by `ScaleDampeningPercent`. Swim uses `speed/10`, climb `speed/5`. `jumpAnimDuration = 0.31`, `fallTransitionTime = 0.2`.
  - The Animate script sets `Priority = Core` on the locomotion tracks it plays [ENGINE source].
- **Idle weights:** chance = weight / total weight [DOC]. Default is 9:1.
- **Priority rules** [DOC AnimationPriority.yaml]:
  - Order, high to low: **Action4 > Action3 > Action2 > Action > Movement > Idle > Core**.
  - Enum values: Idle 0, Movement 1, Action 2, Action2 3, Action3 4, Action4 5, **Core 1000**.
  - Evaluation runs per joint from high to low priority while the summed track weight is under 1.0. Once the sum reaches 1.0, lower priorities are skipped for that joint. Equal priorities blend in proportion to weight (normalized if the sum exceeds 1).
  - Roblox defaults and catalog bundles play at Core. Recommended use: Idle for idles, Movement for walk/run/swim/climb, Action+ for overrides.
- **Marketplace animation packs** (full release 2026-09-09):
  - R15 only, **CurveAnimation only**, 10 s or less per clip, all clips loop except Jump, 8-9 clips.
  - 80 Robux upload fee, one pack per day per creator, 300 Robux price floor.
  - Validation rejects clips whose root moves too far, that exceed the speed limit, or that translate any part more than 1.5 studs [DOC animation-packs.md].

---

## 8. What this means for the tutorial pipeline (recommendations, not sourced facts)

1. **R6 path that avoids the import bugs:** Blender (MCP) computes per-frame joint transforms in Roblox space, which is exactly RBXMonkey's `kf` payload. Then Studio MCP `execute_luau` builds a `KeyframeSequence` (HRP > Torso > limbs, `Pose.CFrame = transform`, `Loop` and `Priority` set explicitly, CubicV2 or Linear), parents it under `ServerStorage.RBX_ANIMSAVES.<rig>`, and previews it with `RegisterAnimationClip` + `StepAnimations`. The user then publishes with right-click **Save to Roblox** or ACE **Publish to Roblox**. This path doesn't depend on FBX axis or rest-pose quirks or the Adaptive Animation R6 bug.
2. **"Normal user" path for the video:** Blender + RBXMonkey (v3.1.2, Blender 4.2-5.x) -> live sync or `.rbxanim` -> Studio plugin -> publish.
3. **Upload automation** is possible through Open Cloud, but only with a Studio-saved `.rbxm`. Publishing still needs user consent, so keep it a manual step on camera.

---

## Sources

| # | URL | Date | Type |
|---|---|---|---|
| 1 | https://create.roblox.com/docs/reference/engine/classes/Pose (src: github.com/Roblox/creator-docs .../classes/Pose.yaml) | 2026-08-25 | Official doc |
| 2 | .../classes/PoseBase.yaml | 2025-10-30 | Official doc |
| 3 | .../enums/PoseEasingStyle.yaml | 2026-08-06 | Official doc |
| 4 | .../enums/PoseEasingDirection.yaml | 2025-07-24 | Official doc |
| 5 | .../classes/KeyframeSequence.yaml | 2026-03-17 | Official doc |
| 6 | .../classes/Keyframe.yaml | 2026-03-17 | Official doc |
| 7 | .../classes/KeyframeMarker.yaml | 2025-10-30 | Official doc |
| 8 | .../classes/AnimationClip.yaml | 2026-08-25 | Official doc |
| 9 | .../classes/AnimationClipProvider.yaml | 2026-08-25 | Official doc |
| 10 | .../classes/KeyframeSequenceProvider.yaml (deprecated service) | 2026-06-08 | Official doc |
| 11 | .../classes/Animator.yaml (StepAnimations) | 2026-10-09 | Official doc |
| 12 | .../classes/Motor6D.yaml | 2026-09-22 | Official doc |
| 13 | .../classes/AnimationConstraint.yaml | 2026-08-25 | Official doc |
| 14 | .../enums/AnimationPriority.yaml | 2025-07-24 | Official doc |
| 15 | .../classes/Workspace.yaml (Retargeting) | 2026-10-16 | Official doc |
| 16 | https://create.roblox.com/docs/animation/editor | 2026-10-15 | Official doc |
| 17 | https://create.roblox.com/docs/animation/using | 2026-07-07 | Official doc |
| 18 | https://create.roblox.com/docs/animation/curve-editor | 2026-04-28 | Official doc |
| 19 | https://create.roblox.com/docs/studio/importer | 2026-10-21 | Official doc |
| 20 | https://create.roblox.com/docs/cloud/guides/usage-assets | 2026-10-09 | Official doc |
| 21 | https://create.roblox.com/docs/characters/adaptive-animation | 2026-06-16 | Official doc |
| 22 | https://create.roblox.com/docs/avatar/animation-packs | 2026-09-10 | Official doc |
| 23 | https://create.roblox.com/docs/avatar/emotes/import and /emotes/specifications | 2026-08-25 | Official doc |
| 24 | https://create.roblox.com/docs/art/characters/export-avatar-animations-from-maya | 2026-08-25 | Official doc |
| 25 | https://create.roblox.com/docs/studio/avatar-settings | 2026-09-03 | Official doc |
| 26 | https://devforum.roblox.com/t/4775593 "Animation Import Improvements" | 2026-08-04 | Staff announcement + replies |
| 27 | https://devforum.roblox.com/t/4260501 "[Full Release] Animation Clip Editor: Improved Importing and glTF Support" | 2026-01-15 (GA update 2026-03-31) | Staff announcement + replies |
| 28 | https://devforum.roblox.com/t/1746157 "New Animation Importing for the Unified Smart Mesh Importer Beta" | 2022-04-06 | Staff announcement |
| 29 | https://devforum.roblox.com/t/4298561 "Avatar Joint Upgrade ... Now Live" | 2026-01-26 | Staff announcement + replies (R6 unaffected) |
| 30 | https://devforum.roblox.com/t/4656414 "AJU Phase 2 Rollout & Updated Migration Recommendations" | 2026-05-27 | Staff announcement + replies |
| 31 | https://devforum.roblox.com/t/449068 "Animation cubic easing direction reversed" | 2020-02-02; staff fix post 2024-10-10 | Bug report + staff |
| 32 | https://devforum.roblox.com/t/4022082 "Open Cloud Upload Support for More Asset Types" | 2025-10-23; reminder 2026-03-02 | Staff announcement |
| 33 | https://devforum.roblox.com/t/3852101 "Improving Animation Asset Permissions" | 2025-07-31 | Staff announcement |
| 34 | https://devforum.roblox.com/t/3892540 "Sharing Animation Assets with Connections and Groups" | 2025-08-21 | Staff announcement |
| 35 | https://devforum.roblox.com/t/4605672 "[Full Release] Adaptive Animation" | 2026-04-29 | Staff announcement |
| 36 | https://devforum.roblox.com/t/4636035 "Adaptive Animations Breaks R6 Blender Importing" | 2026-05-14 to 2026-07-02 | Bug report (staff replied) |
| 37 | https://devforum.roblox.com/t/4713305 "Animations imported onto R6 Rigs Don't Work Since Adaptive Animations" | 2026-07-02 | Bug report |
| 38 | https://devforum.roblox.com/t/4148296 and /t/4151404 (R6 torso, Adaptive Animation beta) | 2025-12-13 / staff 2026-01-05 | Bug reports |
| 39 | https://devforum.roblox.com/t/4894439 "RegisterAnimationClip doesn't work in Server Authority mode" | 2026-09-26 | Bug report |
| 40 | https://devforum.roblox.com/t/2249245 (RegisterAnimationClip, multi-client) | 2023-03-29 | Bug report |
| 41 | https://devforum.roblox.com/t/4432728 (staff: ObjectValue under RBX_ANIMSAVES) | 2026-02-23 | Staff reply |
| 42 | https://devforum.roblox.com/t/4861803 "[Full Release] Create and Sell Animation Packs" | 2026-09-09 | Staff announcement |
| 43 | https://devforum.roblox.com/t/4739840 "[Full Release] Animation Graphs" | 2026-07-15 | Staff announcement |
| 44 | https://devforum.roblox.com/t/34729 Den_S "Blender rig exporter/animation importer" (+ post #1628 by Cautioned) | 2017-03-30 (OP edit 2023-01-31; #1628 edited 2025-10-27; last post 2026-09-17) | Community tool thread |
| 45 | https://pastebin.com/raw/V5aBemWL (Den_S addon source) | not dated (2.80+ build) | Community code |
| 46 | https://github.com/Cautioned/Blender-Animations-Plugin (RBXMonkey) | repo 2025-10-26; release v3.1.2 2026-10-17 | Community code |
| 47 | https://create.roblox.com/store/asset/16708835782 (RBXMonkey Studio plugin) | - | Community plugin |
| 48 | https://github.com/Staticaliza/Staticaliza-Blender-Animation-Tools | 2026-02-21 to 2026-10-18 | Community code |
| 49 | https://devforum.roblox.com/t/3586405 "R6 IK + FK Blender Rig" | 2025-03-31 (edited 2026-10-19) | Community resource |
| 50 | https://devforum.roblox.com/t/4042154 "Full Roblox <-> Blender Rig Animation Pipeline" | 2025-11-02 | Community tutorial |
| 51 | https://github.com/jackTabsCode/asphalt (README: animation upload) | release v2.0.2 2026-07-07 | Community tool |
| 52 | https://github.com/dillydog580/animate-roblox-characters ; github.com/bikotoru/roblox-ai-genkidama-pipeline ; github.com/TheAstrayDev/rig-motion-skill ; github.com/yansha-os/motion-tools | 2026-07 to 2026-10 | Community (competing AI pipelines) |
| 53 | Roblox Studio 0.743.0.7431133, live engine probes via Studio MCP (joint data, Animate source, easing tests) | 2026-10-21 | Primary measurement |
