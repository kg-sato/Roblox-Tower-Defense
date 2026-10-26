# 02 – Moon Animator 2: save format, import/export, features, programmatic access

Research date: **2026-10-21**. Scope: what Claude (writing Luau through the Roblox Studio MCP, plugin security) must produce so the result opens cleanly in **Moon Animator 2** (xSIXx, asset 4725618216), plus how the user then plays, exports and publishes it.

## Evidence labels

| Label | Meaning |
|---|---|
| **[STUDIO]** | Checked by Claude on 2026-10-21 with read-only Luau in the user's own Studio ("Place1"). The plugin is loaded as `cloud_4725618216.Moon Animator 2` (the official Creator Store asset) and reports version **!V34000**. Nothing was created or changed in the place. |
| **[SRC]** | Read in a public source. The date is the source's post or commit date. |
| **[INFER]** | Inferred from source code or labels. Not confirmed by running it. |
| **[UNVERIFIED]** | A claim from one source, conflicting sources, or an AI-written blog. Test it before putting it in a video. |

Version caveat: the Creator Store listing was updated on **2026-10-21 04:14 UTC** and its description ends `!V36000` [SRC: Roblox toolbox API, 2026-10-21]. The copy loaded in the user's Studio reports `!V34000` in **Options › Other** [STUDIO]. Studio installs cloud plugin updates when it restarts, so menu labels and the save format may differ slightly after the next restart. Re-run the probes in §9 after any update.

---

## 1. Product facts

- **Asset and creator:** asset 4725618216, "Moon Animator 2 [sale!]", by `xsixx` (verified creator). It was created 2020-02-23. The listing has 27.9k upvotes and 2.1k downvotes (93%) and 140 scripts [SRC: toolbox-service API, 2026-10-21].
- **Price:** USD 19.99, purchasable, not free. The description says "On sale for 33% off" [SRC: toolbox-service API, 2026-10-21]. A May 2026 DevForum post gives the regular price as 1,700 Robux, about $30 [SRC: DevForum t/4652703, 2026-05-25]. The Eclipse comparison site saw the same USD 19.99 on 2026-10-20.
- **Unofficial copies:** several GitHub repos host cracked or "unlocked" copies, for example `zildjibian/moon-animator`, `befexx/Moon-Animator-2-Unlocked` (2026-09-16) and `GlobeReverse/Moon-Animator-2`. Don't use or show them in the videos. The user's Studio runs the official cloud asset [STUDIO].
- **Community:** the Roblox community 5677095 "Moon Animator" (owner xsixx, 79,030 members) has no documentation [SRC: groups API, 2026-10-21].
- **Official docs:** none found. The only official tutorial is the YouTube video "Moon Animator 2 Basics – Official Tutorial" (q8tGNMo_jHg, c. Dec 2021), which a 2024 DevForum guide calls outdated [SRC: t/2874657, 2024-03-13].

---

## 2. Native save format ("Moon 2 File")

### 2.1 Location and container (high confidence)
- Saving (**File › Save**, key `0`) writes a **StringValue** into **`ServerStorage.MoonAnimator2Saves`**:
  - Moonlite README: "The `save` is a StringValue normally stored in `game.ServerStorage.MoonAnimator2Saves`" [SRC: MaximumADHD/Moonlite README, last commit 2024-08-08].
  - Moon2Cutscene says the same [SRC: DevForum t/3001411, 2024-06-02 … 2026-07-09].
  - FGController README: "the save file will appear in `ServerStorage -> MoonAnimator2Saves`" [SRC: GitHub FGController, 2026-10-14].
  - MoonPlus `Signals.FileOpened` passes `file: StringValue` [SRC: zildjibian/moon-plus README, 2024-05].
- A StringValue is **not** a playable animation. Uploading it with "Save to Roblox" does nothing useful [SRC: t/1653708, 2022-02-02; t/1996677 #4, 2024-12-01].
- Folder names used by older versions (all outdated): `xSIXxAnimationSaves`, `MoonAnimationSaves` (Moon Suite and Moon 1, 2021) [SRC: t/1178138, 2021-04-20]. Earlier Moon 2 builds exported to `ServerStorage.MoonAnimatorExport`, while still saving to `MoonAnimator2Saves` [SRC: t/1996677, 2022-09-26].
- At the time of the probe this place had no `MoonAnimator2Saves`, `RBX_ANIMSAVES` or `AnimSaves` instances [STUDIO].

### 2.2 StringValue.Value = JSON (high confidence: two independent parsers)
Moonlite reads it with `HttpService:JSONDecode(save.Value)`, using these types [SRC: Moonlite `Types.lua` / `init.lua`, 2024-08-08]:

```lua
type MoonAnimSave = {
  Items: { { Path: { ItemType: string, InstanceTypes: {string}, InstanceNames: {string} } } },
  Information: {
    Created: number, Modified: number,
    Length: number,          -- in frames
    Looped: boolean,
    FPS: number?,            -- Moonlite falls back to 60
    ExportedPriority: string -- e.g. "Action"
  },
}
```
- `Path.InstanceNames` is the full name path from `game`. Moonlite and Moon2Cutscene skip element 1 and resolve elements 2..n from `game`, so element 1 is the root ("game") [INFER from both parsers].
- MoonPlus internal docs list the same `Path` class: `Serialize() -> {ItemType, InstanceNames, InstanceTypes}` [SRC: moon-plus `docs/data`, 2024-05-08].
- Supported `ItemType`s in V34000 come from `_G.MoonGlobal.ItemTable.Items` [STUDIO]. They include `Rig`, `Camera`, `BasePart`, `Model`, `Motor6D`, `AnimationConstraint`, `IKControl`, `FaceControls`, `Humanoid`, `ParticleEmitter`, `Sound`, `Beam`, `Trail`, `Light`, `Lighting`, `Attachment`, `Weld`, `WeldConstraint`, post effects and UI items (Frame, ImageLabel, TextLabel). There are 72 in total.

### 2.3 Child instance tree (medium confidence: from the Moonlite parser plus one error message)
The StringValue has one child per item, named after its **1-based index into `Items`**: `"1"`, `"2"`, …
A real path from a user error confirms this: `ServerStorage.MoonAnimator2Saves.CutsceneCC3.2.MarkerTrack.281` [SRC: t/2515950 #11, 2023-12-15].

```
ServerStorage.MoonAnimator2Saves
└─ <FileName>                     StringValue (JSON above)
   └─ "1"                         Folder  (item #1)
      ├─ "Rig"                    Folder  (only for ItemType "Rig")
      │  └─ "_joint"  (×N, all with this same name)
      │     ├─ "_hier"            StringValue  e.g. "LowerTorso.UpperTorso.RightUpperArm" (Part1 names, root→joint) [INFER]
      │     ├─ "default"          CFrameValue  rest value of the joint
      │     └─ "_keyframes"       Folder
      │        └─ "<startFrame>"  Folder  keyframe "pack"
      │           ├─ "Values"     Folder → children "0","1",… (ValueBase; index = frame offset from startFrame)
      │           └─ "Eases"      Folder → children "0",… each { "Type": StringValue, "Params": Folder{ "Direction": StringValue, "Overshoot"/"Amplitude"/"Period": NumberValue } }
      │              (legacy: single "Ease" Folder with "Style" + "Direction" StringValues)
      ├─ "<PropertyName>"         Folder per animated property (e.g. "CFrame", "Transparency", "FieldOfView")
      │  ├─ "default"             ValueBase (optional)
      │  └─ "<startFrame>" packs  (same Values/Eases layout)
      └─ "MarkerTrack"            Folder (animation events)
         └─ "<startFrame>"        Folder with "name" StringValue, "width" NumberValue,
                                   "KFMarkers" Folder (each child ValueBase: .Value = marker name, child "Val" = marker value)
```
- **Joint value semantics [INFER]:** Moonlite computes `Motor6D.Transform = storedValue:Inverse() * default`. So Moon stores an animated **C1-style** CFrame (`default * Transform:Inverse()`), not `Transform` itself. A writer would have to reproduce this exactly.
- **Non-ValueBase values:** read from the attribute `Value`. Extra type tags are stored as sibling children: `EnumType` (StringValue), or marker children named `Vector2`, `ColorSequence`, `NumberSequence` or `NumberRange` [SRC: Moonlite `readValue`].
- **Ease types:** `Linear, Constant, Sine, Quad, Cubic, Quart, Quint, Sextic, Expo, Circ, Back, Bounce, Elastic`. Directions: `In, Out, InOut, OutIn` [SRC: Moonlite Types; STUDIO: `EasingFunctions` has 46 entries, e.g. `SexticOutIn`].
- **Keyframe and marker internals:** keyframes are `{_tblType="Keyframe", frm_pos, EaseMap, TargetValues, width}`. Markers are `{_tblType="Marker", frm_pos, name, width, codeBegin?, codeEnd?, KFMarkers}` [SRC: moon-plus `docs/data`, 2024-05].
- **Gotcha:** don't give an animated instance a purely numeric name such as a part called "1". "Moon Animator fails to save these correctly" [SRC: FGController README, 2026-10-14]. Numeric child names are reserved for item indices.
- **Open-failure example:** `…LayerSystem.ItemObject:19: attempt to index nil with 'CFrame'` happened when an item's target instance could not be resolved [SRC: t/3129906, 2024-08-22]. A hand-written save that points at a missing or renamed instance is likely to fail like this.

### 2.4 Who has documented or reverse-engineered it
| Project | What it does | Date | Notes |
|---|---|---|---|
| **Moonlite** (MaximumADHD), github.com/MaximumADHD/Moonlite | Runtime player that parses Moon 2 saves | last commit 2024-08-08; PRs open until 2026-07 | Best public description of the format (read side only). The npm `@rbxts/moonlite` 1.0.4 (2023-08-25) is a TS fork |
| **Moon2Cutscene** (Hzodx), Creator Store 17712048551 | Runtime cutscene player for Moon 2 files | 2024-06-02; 2026-07-09 update added "new character joints" (`setIndexUseAnimationConstraint`) and earlier bones (2025-06-28) | Closed source on the Store |
| **Moon Animator Object Exporter** (funjack17gaming), 14367322993 | Turns Moon save objects into tween scripts | 2023-08-09 | Broke on marker tracks in 2023-12 |
| **MoonPlus** (zildjibian), Creator Store 17171181036 | Modding framework that hooks Moon internals via `_G.MoonGlobal` | 2024-05 | Same author hosts cracked Moon builds. Use the docs only as a reference |
| **Face Animation Importer** (mrXen0o), 81143924403575 | **Writes** face animation into an existing Moon file ("Select your Moon Animator file and click Add Animation") | 2026-08-18 | Shows that third-party writers exist. Its source is not public (only the Blender add-on is) |
| **Arc** VFX plugin | "Moon Sync – sync Moon Animator projects with ARC projects" | 2026-10-01 | Reads and syncs Moon files |
| **Moon2Module**, DevForum t/2975574 | Converts Moon projects into ModuleScripts | 2024 | Not inspected |
| **FGController** | Paid runtime that parses Moon JSON | 2026-10-14 | Not inspected |

No public **"KeyframeSequence → Moon 2 file"** converter was found. Moon's own **File › Import…** is that converter (see §3). Apex Animator's FAQ also says it cannot import Moon's own files, only Moon output that was exported as a KeyframeSequence [SRC: t/4918289, 2026-10-06].

---

## 3. Importing into Moon Animator 2

### 3.1 Menu path (high confidence)
- **File › Import…** (shortcut **Shift+I**) [STUDIO: File menu label and shortcut]. The dialog title is **"Import to Rig"** [STUDIO].
- The dialog contains these controls [STUDIO, labels only]: `Replace Keyframes` | `Paste Keyframes` | `Events` | `Roblox...` | `Importing: < none >` | `Group` | `Rigs` | `Face` | `Avatar Shop...` | `OK`.
  - The window object has `SetKFSeq` and `sel_changed` functions [STUDIO]. So "Importing:" is filled by **selecting a KeyframeSequence in the Explorer** while the dialog is open [INFER].
  - User walkthrough: "Head to File, find and press 'Import' and select the rig you want the frames to be imported to. Select the file in [ServerStorage] and press and then confirm." [SRC: t/4684412 #14, 2026-08-07]
  - `Avatar Shop...` opens the "Avatar Shop" window with an `Emote Id:` field [STUDIO]. `Roblox...` presumably imports a published animation ID [INFER]. Older wording of the same flow: "file, import, roblox, select your published animation, and select the paste option" [SRC: t/2217524, 2024-01-16].
  - `Replace Keyframes` overwrites the rig's keys. `Paste Keyframes` inserts them at the playhead [INFER from labels and t/2217524].
  - `Events` probably imports KeyframeMarkers or named keyframes as Moon events [INFER, label only, **untested**].
  - `Rigs` / `Face` probably choose body joints and/or FaceControls channels [INFER].
- The 2021 equivalent was "Item › Import to Rig" [SRC: t/1318136, 2021-06-28]. It is outdated.

### 3.2 What Moon accepts
- **KeyframeSequence only, not CurveAnimation.** "Moon only does Keyframe sequences, so I needed to convert them from Curveanimations" [SRC: t/4017097, 2025-10-20]. When given a CurveAnimation, the import silently does nothing [SRC: t/3877057, 2025-08-13].
- **ID imports need asset permission.** An import from an ID that "shows like I didn't do anything" can be a permissions problem: the place must have permission to use the animation asset [SRC: t/3877057 #5, 2026-06-23]. A **local** KeyframeSequence in ServerStorage avoids this completely.
- **Moon's own bundled animations are KeyframeSequences.** `cloud_4725618216.Moon Animator 2.Animations` holds `R6Walk` (22 keyframes, 0.667 s), `R15Walk` (26, 0.625 s) and `R15Idle` (198, 4.3 s). All are standard `KeyframeSequence › Keyframe › Pose "HumanoidRootPart" › Pose "Torso"/"LowerTorso" …` trees with `Linear/In` poses and `Loop=true`. Moon converts them internally (`_G.MoonGlobal.RobloxToBuffers`, `RobloxToSimple`, `RobloxKeyframeCount`) [STUDIO]. **KFS → Moon is a first-class code path inside Moon.**
- **Where Roblox's Animation Editor saves:** `ServerStorage.RBX_ANIMSAVES.<RigName>.<Anim>`. The Clip Editor also saves imported FBX/glTF clips there automatically [SRC: t/4260501, 2026-01-15, GA 2026-03-31]. Old "Moon looks in the rig's AnimSaves, Roblox now saves to ServerStorage" confusion: [SRC: t/2833443, 2024-02-22].
- **[UNVERIFIED]:** "put a KeyframeSequence in a Model named AnimSaves inside the rig and it should appear in Moon" was posted "from memory" [SRC: t/4017097 #2, 2025-10-20]. Not confirmed.

### 3.3 What may be lost or changed on import (all UNVERIFIED, test once)
- **Easing:** Roblox `PoseEasingStyle` supports only Linear, Constant, Cubic, CubicV2, Bounce and Elastic. How Moon maps CubicV2 has not been verified.
- **Markers:** whether KeyframeMarkers come in as Moon events depends on the `Events` option [INFER].
- **FPS:** Moon snaps keys to its frame grid (file FPS, default 60). Keyframe times that are not multiples of 1/60 s will be rounded [INFER from frame-indexed format].

### 3.4 Rig support
- **Character Inserter** offers **R6**, **R15**, **Old R15**, "Default Body", "Original", account name/ID, presets and faces [STUDIO: window labels]. All six bundled template rigs use Motor6D (R6: 6, R15 and Old R15: 15) and no AnimationConstraints [STUDIO].
- Roblox's newer default R15 rigs use **AnimationConstraint** instead of Motor6D. A user found "zero Motor6D" in current default rigs and used Moon's "Old R15" instead [SRC: t/4527942, 2026-03-21]. Moon V34000 lists `AnimationConstraint` as an item type [STUDIO], and Moon2Cutscene added AnimationConstraint playback in 2026-07. Full rig-animation support for AnimationConstraint joints in Moon is **unverified**. **For tutorials, use Moon's Character Inserter R6 or R15 (Motor6D) rigs.**
- Bones: a `BoneTrack` class exists [STUDIO]. Moon2Cutscene added bone playback 2025-06-28.

---

## 4. Exporting from Moon Animator 2

### 4.1 Rig animation → KeyframeSequence (high confidence)
- **File › Export Rigs** (shortcut **5**) [STUDIO]. It writes a **KeyframeSequence into a Model named `AnimSaves` inside each exported rig**:
  - "Export the rig animations through file → export rigs. The animation will show up inside a model in the rig called 'AnimSaves'" [SRC: t/4320739 #8, 2026-02-13].
  - Same in t/1996677 #8 (2025-10-14), t/2968332 (2024-05-13) and t/4192857 (2026-01-03).
- Only items that are rigs are exportable this way. Part-only files report "No Items in the current Animation are exportable" [SRC: t/1898869, 2022-07-29].
- Older UI (2022–2023), now outdated: "Item › Export All" → `ServerStorage.MoonAnimatorExport` [SRC: t/1653708, 2022; t/2474065, 2023].
- **Settings that end up in the export:** **File › File Settings…** (key **8**, window "Animation Settings") holds Name, FPS (default 60), Priority (Action, Movement, Idle, Core, Action2, Action3, Action4), Timeline Size (default 5:00) and Stretch [STUDIO]. Priority is stored as `ExportedPriority` in the save JSON [SRC: Moonlite Types]. Looping is set with **File › Toggle Loop** (Tab).
- **Easing on export:** Roblox animations don't support Sine, Quad, Back and the rest, so Moon "manually add[s] extra in-between keyframes to imitate the easing style", which makes assets bigger [SRC: t/2397709, 2023-05-29]. Exports also don't keep a low FPS look (a 12 fps setting played back smoothly at 60). The workaround is Constant easing [SRC: t/3051738, 2024-07-03; t/2514524, 2023-08-08].
- **Scale caveat:** an exported animation that looks "different" was caused by model scaling. Re-export from the same scale [SRC: t/3804402 #4, 2026-04-12].
- **Events → markers:** "all the keyframe events you added in MoonAnimator will be in the animation", read in game with `AnimationTrack:GetMarkerReachedSignal(name)` [SRC: t/4020012 #6, 2025-10-29]. The marker fires only if an entry is added on the **Events** tab of the event editor. The track event's own name is not enough [SRC: t/1121774 #7, 2026-01-09].

### 4.2 Publishing
- Right-click the KeyframeSequence in `<Rig>.AnimSaves` → **Save/Export › Save to Roblox…**. Upload it as an Animation and copy the ID into an `Animation` instance (`rbxassetid://<id>`) [SRC: t/4320739 #8, 2026-02-13; t/1996677 #8, 2025-10-14].
- Alternative: open the rig in Roblox's Animation Editor. It detects Moon's AnimSaves and offers to **migrate** them, after which you use **Publish to Roblox** [SRC: t/1996677 #6, 2025-07-16].

### 4.3 Camera and other non-rig items
- **Camera menu:** Add, Toggle (Ctrl+Space), Rotation… (Shift+O), Reference…, Grid (C) [STUDIO]. "Camera Reference" offers "Set Selection as Reference" [STUDIO]. The camera is then animated relative to a part, such as the HumanoidRootPart for attack cams [SRC: t/1181691, 2021-04-22]. Track classes exist for `CameraCFrameTrack`, `CameraAttachToPartTrack` and `CameraLookAtPartTrack` [STUDIO], and FieldOfView is animatable.
- **Camera export:** produces a **Folder of per-frame values**, not an animation asset:
  - Under the camera: `FOV`, `Frames` (one CFrameValue per frame, named by frame index, at file FPS) and `Settings` [SRC: t/4214289 #2, 2026-01-04, via "Export Rigs"].
  - "moon animator 2 exports camera movements … if you click 'Export Files'" [SRC: t/2878483 #5, 2024-03-24].
  - Play it back with a RenderStepped loop: `Camera.CFrame = ref.CFrame * Frames[frame].Value` [SRC: t/1181691, 2021-04-22].
- **File › Export Files…** shows "N Files Found / Exporting will close without saving, continue?" [STUDIO]. Its exact output is **unverified**.
- Alternative: play the whole Moon file at runtime with Moonlite or Moon2Cutscene, which covers camera, parts, effects and events.
- **Nilo article warning:** it says camera export writes a KeyframeSequence you play through an AnimationController. That contradicts all the user reports above. The article is AI-generated (utm `ai-growth-agent`) and should not be cited [SRC: nilo.io, 2026-08-30].

---

## 5. Features relevant to combat animation

### 5.1 Menus and shortcuts in V34000 [STUDIO, 2026-10-21]

| Menu | Items `[shortcut]` |
|---|---|
| **File** | Save `[0]`, Save As..., Save and Close `[/]`, Close `[\]`, File Settings... `[8]`, **Export Rigs `[5]`**, **Import... `[Shift+I]`**, Export Files..., Toggle Loop `[Tab]`, Play `[Space]`, Hide UI `[Ctrl+H]` |
| **Edit** | Cut, Copy, Paste, Paste Into `[Shift+Ctrl+V]`, Delete, Select All `[Alt+F]`, Undo `[Ctrl+Z]`, Redo `[Shift+Ctrl+Z]` |
| **Item** | Rig ›, Add Effects ›, Add... `[9]`, View `[F]`, Toggle All `[Shift+Space]`, Collapse All `[2]`, Jump To... `[Shift+P]` |
| Item › **Rig** | Reflect `[Ctrl+R]` (mirror), Toggle Handles `[Ctrl+B]`, **Toggle Onion Skin `[B]`**, Apply Onion Skin `[N]`, Clear Onion Skin `[Alt+B]` |
| Item › **Add Effects** | Vignette, Letterboxing, Screen Cover, Subtitles, Scale Subtitles |
| **Keyframe** | Edit Selection... `[7]`, Add `[+]`, Add Default `[G]`, Previous Pose `[J]`, Next Pose `[K]`, Split › (Split Keyframe `[M]`, Stride... `[Shift+M]`), Group Selection `[Ctrl+G]`, Ungroup... `[Ctrl+U]`, Ungroup All `[Shift+Ctrl+U]` |
| **Frame** | Stretch... `[3]`, Repeat... `[Shift+L]`, Fill... `[Shift+K]`, Fit Timeline `[Shift+F]`, Offset..., Step..., Previous `[4]`, Next `[6]`, Frame 0 `[1]` |
| **Camera** | Add, Toggle `[Ctrl+Space]`, Rotation... `[Shift+O]`, Reference..., Grid `[C]` |
| **Options** | Handles ›, Gizmos ›, Use Last Ease, Easing Colors, Show Seconds `[Shift+T]`, Hide Columns, Other › (Edit Theme..., `!V34000`) |
| **Theme** | 14 themes |

### 5.2 Feature details
- **Easing:** the Edit Keyframes ease panel lists None, Linear, Quart, Quint, Sextic, Expo, Circ, Sine, Quad, Cubic, Back, Bounce and Elastic. Directions are In, Out, InOut and OutIn, with parameters such as overshoot, amplitude and period [STUDIO; Moonlite]. That is the main advantage over Roblox's editor, which offers 6 styles.
- **Events (markers):** turn on the "Animation Events" track per item, then press Enter at the playhead to add one and double-click it to edit. The editor has Name, Width, End Time, an Events tab (key/value pairs that export as KeyframeMarkers), and Code Begin/Code End (Studio-preview Lua) [SRC: t/1121774, 2024-05-30 / 2026-01-09; STUDIO window "Edit Events"].
- **Onion skin:** B toggles it, N applies it, Alt+B clears it. One report (t/3783897, 2025-06-26) says the ghost sometimes lands in Workspace instead of on the rig.
- **IK:** no IK posing solver appears in the V34000 menus or in the 93 internal classes [STUDIO]. Roblox's `IKControl` exists only as an **animatable item type** (its properties can be keyed). Community statements: "Moon … lacks IK (as far as I know)" (t/1270068, 2021). Competitors advertise IK as their selling point: Eclipse Animator, 2026-10-14; Apex Animator, 2026-10-06. Treat "Moon has IK" claims (t/1968932, 2022) as **unverified**.
- **Attaching a weapon to the hand (Easy Weld):** Moon's **Easy Weld** window has Cleaner, Model and Parts tabs. On Parts, select a Base Part in the Explorer, Ctrl-select the Target Part, tick **Animatable** (makes a Motor6D) and choose **Join** or **Join in Place** [STUDIO: labels]. Use Animatable, because a plain Weld can't be animated [SRC: t/3001411 #118, 2024-12-06]. In game, the **same Motor6D** (name, Part0/Part1, C0/C1) must exist on the character, or the weapon appears offset [SRC: DevForum weapon threads, summarized via search, 2020–2024]. RigEdit Lite or RigEdit Plus are alternatives.
- **Character Inserter:** inserts R6, R15 or Old R15 rigs, or a player's avatar by name or ID [STUDIO].
- **Retiming tools:** Stretch (3), Repeat, Fill, Offset, Step, Split/Stride, and Group keyframes. There is no separate "playback speed" slider. Speed comes from Stretch or the FPS setting [STUDIO].
- **Limits:** `DEFAULT_FPS=60`, `DEFAULT_FRAMES=300` (5 s), `MIN_FRAMES=60`, `MAX_FRAMES=216000` (1 h at 60 fps) [STUDIO, `_G.MoonGlobal`].
- **Multi-item scenes:** many rigs, parts, camera, lighting, sounds, particles (Emit/Clear tracks), Humanoid actions and UI effects in one file. This is the main reason animators pick Moon for cutscenes and combat "scenes" [STUDIO class list; t/4320739 #4, 2026-02-01].

### 5.3 Moon vs the default Animation Editor (2025–2026)
- **For Moon:** many easing styles, multiple rigs and props in one timeline, camera, effects and events in one file [SRC: t/4652703, 2026-05-25; t/4320739, 2026-02-01; t/1543433, 2021].
- **Against Moon:** the price ($30, or $19.99 on sale). "No new functional … overpriced", and Blender with IK/FK rigs is preferred by experienced animators [SRC: t/4151303, 2025-12-14; t/2874657, 2024-03-13]. The default editor gained a Clip Editor with glTF import and auto-save to RBX_ANIMSAVES [SRC: t/4260501, 2026-01-15 / 2026-03-31]. New competitors appeared in October 2026: Eclipse Animator (USD 19.99, IK) and Apex Animator (free, IK/FK).
- **Summary:** hobby and YouTube creators still use Moon for scenes and combat. Studio-level animators increasingly use Blender. No reliable survey exists.

---

## 6. Programmatic access (plugin "API")

- **No official API exists.**
- Moon keeps its internal state in the shared global **`_G.MoonGlobal`** (MoonPlus: `local _g = _G.MoonGlobal`). **It can be reached from the Studio MCP's `execute_luau` (Edit DataModel)**: the read-only probe on 2026-10-21 returned a table with 82 keys [STUDIO].
- Functions that exist (only their parameter counts were checked with `debug.info(f,"a")`; none were called) [STUDIO]:
  - `_G.MoonGlobal.Windows.MoonAnimator`: `.OpenFile(2)`, `.SaveFile(2)`, `.ExportRigs(1)`, `.CloseFile(0)`, `.PromptSave(0)`, `.RenameFile(1)`, `.refresh_files(2)`, `.find_template_file(0)`
  - `_G.MoonGlobal.Files`: `.GetRoot(0)`, `.NewFile(2)`, `.OpenFile(1)`, `.RefreshFiles(0)`
  - `_G.MoonGlobal.Windows.Import.SetKFSeq`, `_G.MoonGlobal.RobloxToBuffers(3)`, `RobloxToSimple(3)`, `MASConvert.ConvertMASFile(2)`, `ExportItemObject(1)`
- **Risk:** the functions are undocumented and their argument meanings are unknown. They can change with any update (the Store is already on V36000 while V34000 is loaded). Calling them could corrupt the open file.
- **Recommendation:** use them only for **read-only checks** (version, file list) or a future experiment. Don't build the tutorial on them.

---

## 7. Recommended pipeline for an AI that cannot rely on hand edits

**The most reliable route: Claude writes a standard Roblox `KeyframeSequence`, and Moon's built-in importer converts it to a native Moon 2 file.** The reasons:
1. KeyframeSequence/Keyframe/Pose is Roblox's documented, stable format. Claude can write it fully with `Instance.new`.
2. Moon converts KeyframeSequences itself. Its own bundled R6/R15 walk and idle animations are KeyframeSequences fed through `RobloxToBuffers` [STUDIO]. So Moon writes the native StringValue tree in its own current format, and no reverse-engineered schema is involved.
3. A local KeyframeSequence avoids the two known import failures: CurveAnimation input and missing asset permission.

**Steps (6 clicks for the user):**
1. Claude inserts or uses a **Motor6D** rig: Moon Character Inserter R6/R15, or a rig in Workspace. Give it a unique name and no numeric part names.
2. Claude writes `ServerStorage.RBX_ANIMSAVES.<RigName>.<AnimName>` (or any ServerStorage folder) as a **KeyframeSequence**:
   - Pose tree `HumanoidRootPart › LowerTorso/Torso › …` following the rig's Motor6D hierarchy, with `Pose.CFrame` equal to the joint Transform.
   - Keyframe `Time`s on the 1/60 s grid.
   - Easing limited to Linear, Constant or Cubic. For "Moon-only" eases, bake dense keys.
   - `Priority=Action`; `Loop` as needed.
   - Optional KeyframeMarkers.
3. User: open Moon › new file › **Item › Add… (9)**, then select the rig.
4. User: **File › Import… (Shift+I)** › click the KeyframeSequence in the Explorer ("Importing:" shows it) › **Replace Keyframes** (tick **Events** if markers were written) › **OK**.
5. User: **File › Save (0)**. The file now lives in `ServerStorage.MoonAnimator2Saves.<Name>`.
6. Claude verifies read-only. It decodes the StringValue JSON and checks `Information.Length`, `FPS`, `Items[i].Path.InstanceNames`, and that `"1".Rig` has the expected `_joint` count.
7. To ship: **File › Export Rigs (5)** › right-click `<Rig>.AnimSaves.<KFS>` › **Save/Export › Save to Roblox…**.

**Only when Moon-native features are needed** (Moon eases, camera, effects in one file), consider writing the native save directly, and use the template-clone method:
- The user saves one tiny Moon file on the target rig: 2 keyframes, one Sine ease, one event.
- Claude reads that exact tree and JSON in Studio and copies its structure byte for byte, changing only the values.
- Never write the schema in §2.3 from scratch. It is inferred from a 2024 third-party parser and may differ in V36000.

---

## 8. Open questions to test on camera (in the first tutorial session)
1. Does Import with `Events` turn KeyframeMarkers into Moon events, and does it work with named Keyframes?
2. How does Moon map Pose `Cubic`, `CubicV2`, `Elastic` and `Bounce` on import?
3. Do non-60-fps keyframe times get rounded or dropped?
4. Does Import work for AnimationConstraint-jointed (new default) R15 rigs in V36000?
5. Do the File menu labels change after Studio picks up V36000?

## 9. Read-only probe snippets used (safe to re-run via MCP)
```lua
-- version + menus (read-only)
local g = _G.MoonGlobal; print(g and g.ver)
for _, mi in ipairs(g.AllMenus.fileMain._MenuItems.Objects) do print(mi.name) end
-- list Moon saves
local f = game.ServerStorage:FindFirstChild("MoonAnimator2Saves")
if f then for _, s in f:GetChildren() do local d = game:GetService("HttpService"):JSONDecode(s.Value); print(s.Name, d.Information.Length, d.Information.FPS, #d.Items) end end
```

---

## Sources

| # | Source | Date | Used for |
|---|---|---|---|
| 1 | Roblox toolbox-service API: https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=4725618216 | fetched 2026-10-21 (asset updated 2026-10-21T04:14Z) | price USD 19.99, `!V36000`, votes |
| 2 | economy API https://economy.roblox.com/v2/assets/4725618216/details | fetched 2026-10-21 | creator xsixx, created 2020-02-23 |
| 3 | User's Roblox Studio via MCP (read-only Luau), plugin `cloud_4725618216.Moon Animator 2` | 2026-10-21 | menus, shortcuts, windows, item types, limits, bundled KFS, `_G.MoonGlobal` |
| 4 | Moonlite, https://github.com/MaximumADHD/Moonlite (init.lua, Types.lua, README; issues #1–#25) | last commit 2024-08-08; issues to 2026-07-05 | save JSON and tree format |
| 5 | MoonPlus, https://github.com/zildjibian/moon-plus (README, docs/data) | 2024-05-08 | `_G.MoonGlobal`, Path/Keyframe/Marker internals |
| 6 | Moon2Cutscene, https://devforum.roblox.com/t/3001411 | 2024-06-02 → 2026-07-09 | save location, items, AnimationConstraint/bones |
| 7 | FGController README, https://github.com/FogoEGelo/FGController | 2026-10-14 | MoonAnimator2Saves, numeric-name gotcha, Code Begin |
| 8 | Moon Animator Object Exporter, https://devforum.roblox.com/t/2515950 | 2023-08-09 / 2023-12-15 | real save path `…CutsceneCC3.2.MarkerTrack.281` |
| 9 | Simulation Baker thread, https://devforum.roblox.com/t/4684412 (#14) | 2026-08-07 | File › Import walkthrough |
| 10 | Convert animation editor anim into moon, https://devforum.roblox.com/t/4017097 | 2025-10-20 | KFS only, not CurveAnimation |
| 11 | Moon animator won't let me import, https://devforum.roblox.com/t/3877057 | 2025-08-13 / 2026-06-23 | silent import failure, permissions |
| 12 | How to duplicate keyframes…, https://devforum.roblox.com/t/2217524 | 2024-01-16 | File › Import › Roblox › paste |
| 13 | Animation ID → Moon Animator?, https://devforum.roblox.com/t/1318136 | 2021-06-28 | old "Item › Import to Rig" |
| 14 | How do people make animation games, https://devforum.roblox.com/t/4320739 (#4, #8) | 2026-02-01 / 2026-02-13 | Export Rigs → AnimSaves → Save to Roblox; camera folder |
| 15 | How to export moon animator animation…, https://devforum.roblox.com/t/1996677 | 2022-09-26 → 2025-10-14 | old Item › Export All; migration route |
| 16 | Moon Animator 2 (CanterCrow), https://devforum.roblox.com/t/1653708 | 2022-02-02 | StringValue isn't an animation |
| 17 | Moon animator not exporting, https://devforum.roblox.com/t/2968332 | 2024-05-13 | File › Export to Rigs |
| 18 | How do I export my animation…, https://devforum.roblox.com/t/4192857 | 2025-12-28 / 2026-01-03 | export rig in File |
| 19 | Frame animation function…, https://devforum.roblox.com/t/4214289 | 2026-01-04 | camera export folders FOV/Frames/Settings |
| 20 | Camera Animations for cutscenes…, https://devforum.roblox.com/t/1181691 | 2021-04-22 | camera Reference Part, per-frame playback |
| 21 | How do I play Moon 2 File's effects and camera…, https://devforum.roblox.com/t/2878483 | 2024-03-16/24 | Export Files exports camera |
| 22 | How do I add keyframe events in Moon Animator?, https://devforum.roblox.com/t/1121774 | 2021 → 2026-01-09 | events workflow, GetMarkerReachedSignal |
| 23 | MoonAnimator2 – Playing Particles in game, https://devforum.roblox.com/t/4020012 | 2025-10-22/29 | events export as markers |
| 24 | Add the missing Easing Styles, https://devforum.roblox.com/t/2397709 | 2023-05-29 | Moon bakes eases on export |
| 25 | Moon animator doesn't export at 12 fps, https://devforum.roblox.com/t/3051738 ; t/2514524 | 2024-07-03 ; 2023-08-08 | FPS not preserved |
| 26 | Exported Animation Is Way Different, https://devforum.roblox.com/t/3804402 | 2025-07-08 / 2026-04-12 | scale gotcha |
| 27 | Current R15 Rigs contain no Motor6Ds, https://devforum.roblox.com/t/4527942 | 2026-03-21/23 | AnimationConstraint rigs; Moon Old R15 |
| 28 | Can't open Moon 2 File, https://devforum.roblox.com/t/2833443 ; Moon 2 Error When Opening, t/3129906 | 2024-02-11 ; 2024-08-22 | open failures |
| 29 | Moon Animator – Is it worth it?, https://devforum.roblox.com/t/2874657 | 2024-03-13 | price 1,700 R$, hotkeys, xSIXx tutorial link |
| 30 | Roblox's Default Animator Needs a Serious Revamp, https://devforum.roblox.com/t/4652703 | 2026-05-25 | $30 / 1,700 R$, comparison |
| 31 | Animation Q switching between programs, https://devforum.roblox.com/t/4151303 | 2025-12-14 | Blender-vs-Moon opinion |
| 32 | [Full Release] Animation Clip Editor…, https://devforum.roblox.com/t/4260501 | 2026-01-15 (GA update 2026-03-31) | RBX_ANIMSAVES auto-save, glTF |
| 33 | Getting Started with Moon Animator 2 [Unofficial], https://devforum.roblox.com/t/476330 | 2020-03-07 | toolbar tools (Character Inserter, Easy Weld) |
| 34 | Moon2Cutscene weld answer (#118), https://devforum.roblox.com/t/3001411 | 2024-12-06 | Easy Weld "Animatable" |
| 35 | Apex Animator, https://devforum.roblox.com/t/4918289 | 2026-10-06 | can't import Moon files; KFS import |
| 36 | Get Eclipse Animator…, https://devforum.roblox.com/t/4934601 ; https://eclipseanimator.dev/vs-moon-animator/ | 2026-10-14 ; 2026-10-16/20 | competitor, IK, price check |
| 37 | Arc VFX plugin, https://devforum.roblox.com/t/4903133 | 2026-10-01 | Moon Sync |
| 38 | 2D Face Rig & Exporter, https://devforum.roblox.com/t/4818532 | 2026-08-18 | third-party writer into Moon files |
| 39 | How to use "Onioning" in Moon Animator 2, https://devforum.roblox.com/t/4875005 ; Onion Skin Not Working t/3783897 | 2026-09-16/18 ; 2025-06-26 | onion skin |
| 40 | Need help importing animations (Moon Animator), https://devforum.roblox.com/t/1178138 | 2021-04-20 | legacy save folders |
| 41 | nilo.io "How to Export Animations from Moon Animator 2" | 2026-08-30 | **not relied on** (AI-generated, contradicts user reports) |
| 42 | Roblox Studio FPS spikes, https://devforum.roblox.com/t/4851389 | 2026-09-05 | single report: RBX_ANIMSAVES + MoonAnimator2Saves caused stutter |
